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
  static const List<String> _introTracks = [
    'intro/intro_01.mp3',
    'intro/intro_02.mp3',
    'intro/intro_03.mp3',
  ];

  static final List<String> _bgmTracks = [
    for (int i = 1; i <= 40; i++)
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
  /// Idempotente: se già in modalità intro e player attivo, non fa nulla.
  static Future<void> playIntro() async {
    if (!_initialized) return;
    if (_mode == _Mode.intro && _isActuallyPlaying()) return;
    _mode = _Mode.intro;
    await _playFromIntroBag();
  }

  /// Avvia modalità BGM. Pesca dal shuffle bag dei 40 brani gameplay.
  /// Idempotente: se già in modalità bgm e player attivo, non fa nulla.
  static Future<void> playBgm() async {
    if (!_initialized) return;
    if (_mode == _Mode.bgm && _isActuallyPlaying()) return;
    _mode = _Mode.bgm;
    await _playFromBgmBag();
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
  static Future<void> stop() async {
    _mode = _Mode.idle;
    final stopFuture = FlameAudio.bgm.stop().catchError((Object _) {});
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

  /// true se BGM ha una sorgente attiva (playing o paused). iOS a volte
  /// riporta `playing` brevemente dopo `pause()` prima del callback nativo —
  /// trattare `paused` come "già attivo" evita double-trigger di `playBgm()`
  /// che lascerebbe la musica pausata invece di riprenderla.
  static bool _isActuallyPlaying() {
    final s = _player.state;
    return s == PlayerState.playing || s == PlayerState.paused;
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

  static Future<void> _playFromIntroBag() async {
    if (_introBag.isEmpty) _refillIntroBag();
    final track = _introBag.removeAt(0);
    final consumed = await _playTrack(track);
    // Track restituito se play è stato scartato (stale) → riaccoda in testa
    // al bag invece di perderlo dalla rotazione.
    if (!consumed) _introBag.insert(0, track);
  }

  static Future<void> _playFromBgmBag() async {
    if (_bgmBag.isEmpty) _refillBgmBag();
    final track = _bgmBag.removeAt(0);
    final consumed = await _playTrack(track);
    if (!consumed) _bgmBag.insert(0, track);
  }

  /// Returns `true` se il track è stato effettivamente consumato (play
  /// iniziato o schedulato), `false` se la call è stale e il track
  /// dovrebbe essere rimesso nel bag dal caller.
  static Future<bool> _playTrack(String relativePath) async {
    // Mutex: se un altro _playTrack è in volo, questa call diventa stale.
    // Il caller più recente aggiorna comunque `_playSeq` così il vecchio
    // in-flight rilascia il controllo senza applicare side-effect finali.
    if (_playInFlight) {
      _playSeq++; // invalida la call in corso
      _lastPlayed = relativePath;
      _lastManualPlayMs = DateTime.now().millisecondsSinceEpoch;
      // Stale: track non consumato → caller lo riaccoderà.
      return false;
    }
    _playInFlight = true;
    final seq = ++_playSeq;
    _lastManualPlayMs = DateTime.now().millisecondsSinceEpoch;
    _lastPlayed = relativePath;
    try {
      // Attendi eventuale stop() in volo: se stop.bgm.stop() termina DOPO
      // play.bgm.play(), cancella la nuova sorgente → silenzio. Aspettiamo
      // che il vecchio stop completi prima di chiamare play.
      if (_stopInFlight != null) {
        try { await _stopInFlight; } catch (_) {}
      }
      // NOTE: NO stop() esplicito prima del play. audioplayers `play()`
      // swappa la sorgente atomicamente, senza emettere onPlayerComplete
      // spuri. Un stop() intermedio può scatenare un completion spurio
      // → doppia pesca dal shuffle bag → music stuck.
      //
      // Il taglio comunque è pressoché istantaneo perché la nuova sorgente
      // parte appena il setup audio completa (latenza minima).
      await FlameAudio.bgm.play(relativePath, volume: AudioSystem.bgmVolume);

      // Se nel frattempo è arrivato un altro _playTrack (skip successivo),
      // questa call è superseded — non facciamo altro.
      if (seq != _playSeq) return true;

      await _player.setReleaseMode(ReleaseMode.release);
      return true;
    } catch (e) {
      debugPrint('MusicManager play error ($relativePath): $e');
      return true; // track consumato comunque — non riaccodare
    } finally {
      _playInFlight = false;
    }
  }

  /// Listener interno: su track end naturale, auto-advance al prossimo.
  ///
  /// DEBOUNCE: ignoriamo fires entro 500ms da un manual play. audioplayers
  /// può emettere completion spuri durante source swap (skip manuale),
  /// e senza il guard finiamo con due pesche dal bag in parallelo
  /// (una dal listener, una dal skip) → track finale muta o errata.
  static void _onTrackComplete() {
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - _lastManualPlayMs < 500) return;
    // unawaited + try/catch: `_playFromXBag` è async, il listener sync.
    // Senza guard, errori async vengono silenziosamente ingoiati dallo
    // scheduler di microtasks.
    Future<void> next() async {
      switch (_mode) {
        case _Mode.bgm:
          await _playFromBgmBag();
        case _Mode.intro:
          await _playFromIntroBag();
        case _Mode.idle:
          break;
      }
    }
    unawaited(next().catchError((Object e, StackTrace st) {
      debugPrint('MusicManager onTrackComplete error: $e\n$st');
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
