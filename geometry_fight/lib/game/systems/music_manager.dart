import 'dart:async';
import 'dart:math';

import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/foundation.dart';

import 'audio_system.dart';

/// Gestione musica di sottofondo con **shuffle bag** pattern.
///
/// Track set:
///   - 3 brani **intro** (`assets/audio/intro/`) → menu / app start
///   - 40 brani **bgm** (`assets/audio/bgm/`) → durante il gameplay
///
/// **Shuffle bag**: ogni set ha una "borsa". Quando vuota, si riempie con
/// tutti i track e si mescola. Si pesca dal front. Garantisce che nessun
/// brano si ripeta finché non si è ascoltato l'intero set. Inoltre, al
/// refill della borsa, evitiamo che il primo brano sia uguale all'ultimo
/// appena suonato (no doppio consecutivo nemmeno al wrap-around).
///
/// **Lifecycle**:
///   - `init()` — chiamato una volta in main(), prepara player e bags.
///   - `playIntro()` — modalità intro (auto-advance su track end).
///   - `playBgm()` — modalità bgm (auto-advance su track end).
///   - `skipToNext()` — salta al prossimo (usato su player death).
///   - `stop()` — ferma tutto.
///   - `setVolume(v)` — slider settings live update.
class MusicManager {
  static final _rand = Random();
  static bool _initialized = false;
  static StreamSubscription<void>? _completeSub;

  /// Asset paths relativi a `assets/audio/` (prefix gestito da flame_audio).
  /// Intro: 4 track (era 3, +1 da Songs 2 — Intro Geometry Fight.mp3).
  static const List<String> _introTracks = [
    'intro/intro_01.mp3',
    'intro/intro_02.mp3',
    'intro/intro_03.mp3',
    'intro/intro_04.mp3',
  ];

  /// BGM: 93 track (era 40, +53 da Songs 2 — 52 numerati + 1 unnumbered).
  static final List<String> _bgmTracks = [
    for (int i = 1; i <= 93; i++)
      'bgm/bgm_${i.toString().padLeft(2, '0')}.mp3',
  ];

  static final List<String> _introBag = [];
  static final List<String> _bgmBag = [];

  static _Mode _mode = _Mode.idle;
  static String? _lastPlayed;

  /// Sequence counter per serializzare i `_playTrack`. Ogni call incrementa;
  /// se arriva un nuovo play prima che il precedente finisca, quello vecchio
  /// diventa "stale" e non deve emettere più side-effect.
  static int _playSeq = 0;

  /// Timestamp dell'ultimo skip manuale. `_onTrackComplete` ignora fires
  /// entro 500ms da un skip per evitare doppia pesca dal bag (stop() o
  /// source swap possono emettere completion spuri su alcune platform).
  static int _lastManualPlayMs = 0;

  /// Mutex: `_playTrack` è async, due caller concorrenti (es. `skipToNext`
  /// + `_onTrackComplete` che sfugge al debounce) possono entrare insieme.
  /// Questo flag gate il secondo finché il primo completa `FlameAudio.bgm.play`.
  static bool _playInFlight = false;

  /// Player BGM esposto da flame_audio. `Bgm` mantiene un singolo AudioPlayer
  /// ottimizzato per musica (vs SFX a bassa latenza).
  static AudioPlayer get _player => FlameAudio.bgm.audioPlayer;

  /// Inizializza il sistema. Idempotente. Chiamato una volta da main().
  static Future<void> init() async {
    if (_initialized) return;
    try {
      // Init flame_audio bgm subsystem. In flame_audio 2.x `initialize()` è
      // sync; `await` no-op qui ma protegge se future versioni lo rendono async.
      // ignore: await_only_futures
      await FlameAudio.bgm.initialize();
      // ReleaseMode.release: NON loop. Vogliamo l'evento onPlayerComplete
      // per pescare il prossimo dalla shuffle bag.
      await _player.setReleaseMode(ReleaseMode.release);
      await _completeSub?.cancel();
      _completeSub = _player.onPlayerComplete.listen((_) {
        _onTrackComplete();
      });
      // Pre-carica i track in audioCache per ridurre la latenza al primo play.
      // NOTA: caricare 43 mp3 in cache occupa memoria. Caricamento lazy:
      // li carichiamo on-demand al primo accesso (audioplayers cacha
      // automaticamente l'asset).
      _refillIntroBag();
      _refillBgmBag();
      // Flip `_initialized` SOLO a setup completato: se il try fallisce a
      // metà, la retry di init non risulta "già inizializzato" zombie.
      _initialized = true;
    } catch (e, st) {
      debugPrint('MusicManager init error: $e\n$st');
      // Cleanup parziale: evita listener dangling dal tentativo fallito
      await _completeSub?.cancel();
      _completeSub = null;
      _initialized = false;
    }
  }

  /// Avvia modalità INTRO. Pesca un brano random tra i 3 intro.
  ///
  /// Lifecycle robust contro silent fail di Android MediaPlayer:
  /// dopo il primo play, verifica entro 200ms che il player sia
  /// `PlayerState.playing`; se NO, retry una volta dal bag. Senza
  /// questo, un fail silenzioso (setSource error, OOM, file lock) lasciava
  /// l'utente in silenzio fino al prossimo playIntro manuale.
  static Future<void> playIntro() async {
    if (!_initialized) return;
    if (_mode == _Mode.intro && _isActuallyPlaying()) return;
    await stop();
    _mode = _Mode.intro;
    await _playFromIntroBag();
    await _verifyPlayingOrRetry(_Mode.intro);
  }

  /// Avvia modalità BGM. Stessa lifecycle robusta di `playIntro`.
  static Future<void> playBgm() async {
    if (!_initialized) return;
    if (_mode == _Mode.bgm && _isActuallyPlaying()) return;
    await stop();
    _mode = _Mode.bgm;
    await _playFromBgmBag();
    await _verifyPlayingOrRetry(_Mode.bgm);
  }

  /// Post-play verify: aspetta 100ms (state transition Android) e se
  /// il player NON è in `playing`, fa retry singolo dal bag corrispondente.
  /// Defense contro silent failure di `bgm.play` (caught dentro `_playTrack`
  /// → return true ma senza music partita).
  ///
  /// Caveman-fix race-aware: se `_playInFlight` è ancora true al primo
  /// check, l'original _playTrack è ancora await su bgm.play (potrebbe
  /// partire a momenti). Retry prematuro causerebbe bag thrash +
  /// potenziale doppio-play. Grace period extra 200ms.
  ///
  /// SE dopo 300ms il mutex è ANCORA occupato → bgm.play sta hangando
  /// (verrà recovered dal `.timeout(2s)` in `_playTrack`). NON facciamo
  /// retry da qui — il timeout cleanup + `_onTrackComplete` listener
  /// gestiscono il recovery senza creare 2 _playTrack paralleli.
  static Future<void> _verifyPlayingOrRetry(_Mode expected) async {
    await Future.delayed(const Duration(milliseconds: 100));
    if (_mode != expected) return; // mode cambiato durante verify, abort
    if (_isActuallyPlaying()) return; // success

    // Mutex ancora occupato → original _playTrack non ancora completato.
    // Aspetta 200ms extra invece di retry-now (race protection).
    if (_playInFlight) {
      await Future.delayed(const Duration(milliseconds: 200));
      if (_mode != expected) return;
      if (_isActuallyPlaying()) return;
      // Se mutex ANCORA occupato dopo 300ms totali, original sta hangando.
      // Bail-out: il timeout 2s in `_playTrack` lo finalizzerà → cleanup
      // automatico via finally. Lanciare un retry da qui creerebbe
      // _playTrack parallelo (race su bgm.play simultanei).
      if (_playInFlight) return;
    }

    debugPrint('MusicManager: post-play verify FAIL ($expected) → retry');
    if (expected == _Mode.intro) {
      await _playFromIntroBag();
    } else if (expected == _Mode.bgm) {
      await _playFromBgmBag();
    }
  }

  /// Skip immediato al prossimo brano. Mantiene la modalità corrente.
  /// Usato su player death: la nuova canzone parte mentre il player respawn.
  static Future<void> skipToNext() async {
    if (!_initialized) return;
    switch (_mode) {
      case _Mode.bgm:
        await _playFromBgmBag();
        break;
      case _Mode.intro:
        await _playFromIntroBag();
        break;
      case _Mode.idle:
        break;
    }
  }

  /// Future della stop() corrente. `playIntro`/`playBgm`/`_playTrack` lo
  /// awaitano prima di iniziare il nuovo play → evita la race in cui
  /// stop.bgm.stop() completa DOPO play.bgm.play() e cancella la musica.
  static Future<void>? _stopInFlight;

  /// Ferma completamente. Resetta la modalità a idle.
  ///
  /// Caveman-review fix: NON resettiamo più `_playInFlight = false`. Era
  /// "circuit breaker" per _playTrack stuck, ma rilasciava il mutex mentre
  /// un _playTrack legittimo era in flight → race con NUOVO playIntro che
  /// entrava prima del finally del vecchio _playTrack. Sostituito da
  /// `.timeout(2s)` su `bgm.play` dentro `_playTrack`: timeout genera
  /// TimeoutException → catch → finally rilascia mutex correttamente.
  ///
  /// `_playSeq++` mantiene la semantica di invalidazione del play in volo:
  /// la check `if (seq != _playSeq) return true;` dopo bgm.play marca il
  /// vecchio come superseded senza side-effect.
  static Future<void> stop() async {
    _mode = _Mode.idle;
    _playSeq++;
    final stopFuture = FlameAudio.bgm.stop().catchError((Object e) {
      debugPrint('MusicManager: bgm.stop error: $e');
    });
    _stopInFlight = stopFuture;
    try {
      await stopFuture;
    } catch (_) {}
    if (identical(_stopInFlight, stopFuture)) {
      _stopInFlight = null;
    }
  }

  /// Pause: mantiene posizione, riprendibile con resume().
  static Future<void> pause() async {
    try {
      await FlameAudio.bgm.pause();
    } catch (_) {}
  }

  static Future<void> resume() async {
    try {
      await FlameAudio.bgm.resume();
    } catch (_) {}
  }

  /// Aggiorna volume in tempo reale (chiamato dallo slider Settings).
  static Future<void> setVolume(double volume) async {
    try {
      await _player.setVolume(volume.clamp(0.0, 1.0));
    } catch (_) {}
  }

  // ─── INTERNAL ──────────────────────────────────────────────────────────────

  /// true SOLO se la sorgente BGM sta effettivamente suonando.
  /// NB: paused è gestito separatamente da `_isPaused` → i caller (playIntro/
  /// playBgm) fanno resume() invece di ripartire.
  /// Bug precedente: trattare `paused` come "già attivo" faceva sì che
  /// `playIntro()` fosse no-op al rientro menu con player paused → nessuna
  /// canzone partiva finché l'utente non cambiava mode.
  static bool _isActuallyPlaying() {
    return _player.state == PlayerState.playing;
  }

  static void _refillIntroBag() {
    _introBag
      ..clear()
      ..addAll(_introTracks)
      ..shuffle(_rand);
    _avoidConsecutiveRepeat(_introBag);
  }

  static void _refillBgmBag() {
    _bgmBag
      ..clear()
      ..addAll(_bgmTracks)
      ..shuffle(_rand);
    _avoidConsecutiveRepeat(_bgmBag);
  }

  /// Se la prima track del bag (appena rimescolato) è la stessa appena
  /// suonata, swap con un'altra random per evitare doppio consecutivo.
  static void _avoidConsecutiveRepeat(List<String> bag) {
    if (_lastPlayed == null || bag.length <= 1) return;
    if (bag.first != _lastPlayed) return;
    final swapIdx = 1 + _rand.nextInt(bag.length - 1);
    final tmp = bag[0];
    bag[0] = bag[swapIdx];
    bag[swapIdx] = tmp;
  }

  /// Ritorna `true` se il play è stato avviato (track consumato dal bag),
  /// `false` se stale (mutex `_playInFlight` occupato → track riaccodato).
  /// I caller usano il return per decidere se fare retry.
  static Future<bool> _playFromIntroBag() async {
    if (_introBag.isEmpty) _refillIntroBag();
    final track = _introBag.removeAt(0);
    final consumed = await _playTrack(track);
    if (!consumed) _introBag.insert(0, track);
    return consumed;
  }

  static Future<bool> _playFromBgmBag() async {
    if (_bgmBag.isEmpty) _refillBgmBag();
    final track = _bgmBag.removeAt(0);
    final consumed = await _playTrack(track);
    if (!consumed) _bgmBag.insert(0, track);
    return consumed;
  }

  /// Returns `true` se il track è stato effettivamente consumato (play
  /// iniziato o schedulato), `false` se la call è stale e il track
  /// dovrebbe essere rimesso nel bag dal caller.
  static Future<bool> _playTrack(String relativePath) async {
    // Mutex: se un altro _playTrack è in volo, questa call diventa stale.
    // Il caller più recente aggiorna `_playSeq` così il vecchio in-flight
    // rilascia il controllo senza applicare side-effect finali.
    // NB: NON aggiorniamo `_lastPlayed` qui (bug: avrebbe marcato come
    // "appena suonato" un track mai partito, impattando avoidRepeat).
    if (_playInFlight) {
      _playSeq++;
      _lastManualPlayMs = DateTime.now().millisecondsSinceEpoch;
      return false;
    }
    _playInFlight = true;
    final seq = ++_playSeq;
    _lastManualPlayMs = DateTime.now().millisecondsSinceEpoch;
    try {
      // Attendi stop() in volo con timeout 2s.
      final localStop = _stopInFlight;
      if (localStop != null) {
        try {
          await localStop.timeout(const Duration(seconds: 2));
        } catch (_) {}
        if (identical(_stopInFlight, localStop)) {
          _stopInFlight = null;
        }
        // Settle delay 80ms: Android MediaPlayer può essere ancora in stato
        // "stopping" anche dopo che Future.stop() completa → se play() fira
        // in quella finestra, viene droppato silenziosamente. 80ms è
        // abbastanza per il state transition senza percepire il gap.
        await Future.delayed(const Duration(milliseconds: 80));
      }

      // NO stop() esplicito prima del play: audioplayers.play() swappa la
      // sorgente atomicamente. Un stop() intermedio scatena completion spuri
      // → doppia pesca dal bag → music stuck.
      //
      // Timeout 2s su `bgm.play`: circuit breaker per Android MediaPlayer
      // hang (raro ma possibile su low-end devices o filesystem slow).
      // Ridotto 5→2s: recovery più veloce (verify-retry parte ~100ms dopo,
      // se il primo play non parte la retry kick-in entro 2.1s totale invece
      // di 5.1s).
      await FlameAudio.bgm
          .play(relativePath, volume: AudioSystem.bgmVolume)
          .timeout(const Duration(seconds: 2));

      // Superseded: un altro _playTrack è arrivato nel frattempo.
      if (seq != _playSeq) return true;

      // Success → marca track come appena suonato (per avoidRepeat).
      // setReleaseMode è già impostato in init() → non ripeterlo ogni play.
      _lastPlayed = relativePath;
      return true;
    } catch (e) {
      debugPrint('MusicManager play error ($relativePath): $e');
      return true; // track consumato comunque — non riaccodare
    } finally {
      // Mutex ownership: this call set `_playInFlight = true`, so this call
      // must release it. Concurrent callers that hit the early-return branch
      // DO NOT set `_playInFlight`; they only bump `_playSeq` to invalidate
      // our late side-effects. A seq-gated release deadlocked the mutex when
      // a superseding caller returned stale without ever taking ownership.
      _playInFlight = false;
    }
  }

  /// Listener interno: su track end naturale, auto-advance al prossimo.
  ///
  /// DEBOUNCE: ignoriamo fires entro 500ms da un manual play. audioplayers
  /// può emettere completion spuri durante source swap (skip manuale),
  /// e senza il guard finiamo con due pesche dal bag in parallelo
  /// (una dal listener, una dal skip) → track finale muta o errata.
  /// Counter diagnostic di retry esauriti in `_onTrackComplete`.
  /// Esposto via `onTrackCompleteFailures` per debug UI/telemetry.
  static int _onTrackCompleteFailures = 0;
  static int get onTrackCompleteFailures => _onTrackCompleteFailures;

  static void _onTrackComplete() {
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - _lastManualPlayMs < 500) return;
    // Idle short-circuit: no retry loop quando mode è idle.
    if (_mode == _Mode.idle) return;

    // Retry fino a 3 volte se il play fallisce o ritorna stale.
    // Failure modes coperti:
    //   - Async error da `_playTrack` (MediaPlayer degenerato)
    //   - Stale (mutex `_playInFlight` occupato) → bag rewinded
    //   - `_stopInFlight` ancora in volo → timeout 2s dentro _playTrack
    Future<void> next() async {
      for (int attempt = 0; attempt < 3; attempt++) {
        try {
          bool consumed;
          switch (_mode) {
            case _Mode.bgm:
              consumed = await _playFromBgmBag();
            case _Mode.intro:
              consumed = await _playFromIntroBag();
            case _Mode.idle:
              return; // mode cambiato a idle durante retry
          }
          if (consumed) return; // success
          // Stale: mutex `_playInFlight` occupato. Attesa prima del retry.
          await Future.delayed(const Duration(milliseconds: 250));
        } catch (e) {
          debugPrint('MusicManager onTrackComplete attempt $attempt error: $e');
          await Future.delayed(const Duration(milliseconds: 250));
        }
      }
      _onTrackCompleteFailures++;
      debugPrint(
          'MusicManager onTrackComplete giving up after 3 attempts '
          '(total failures: $_onTrackCompleteFailures)');
    }
    unawaited(next().catchError((Object e, StackTrace st) {
      _onTrackCompleteFailures++;
      debugPrint('MusicManager onTrackComplete fatal: $e\n$st');
    }));
  }

  /// Cleanup risorse. Chiamato a dispose dell'app (raro: app vive in memory).
  static Future<void> dispose() async {
    await _completeSub?.cancel();
    _completeSub = null;
    try {
      await FlameAudio.bgm.dispose();
    } catch (_) {}
    _initialized = false;
    _mode = _Mode.idle;
  }
}

enum _Mode { idle, intro, bgm }
