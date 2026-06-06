import 'dart:async';

import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Pool custom di AudioPlayer in modalità `mediaPlayer` per riprodurre mp3
/// ad alta frequenza senza allocare un nuovo player ad ogni call.
///
/// Perché non usare `AudioPool` di flame_audio: AudioPool usa `lowLatency`
/// (SoundPool su Android), che droppa silenziosamente gli mp3.
/// Perché non usare `FlameAudio.play` diretto: ogni call crea un nuovo
/// AudioPlayer → su game con 100+ kill/min causa lag progressivo.
///
/// Implementazione: N player pre-caricati, round-robin. Ogni player
/// viene riavvolto con `seek(0)` + `resume()` → nessun re-setup di sorgente.
class _Mp3Pool {
  final String assetRelPath; // relativo a assets/audio/
  final List<AudioPlayer> _players;
  int _next = 0;
  bool _ready = false;

  /// True se almeno un player ha caricato la sorgente (preparato → `play()`
  /// fa solo seek+resume, niente prepare). I caller pool-first lo controllano
  /// per decidere se usare il pool o il fallback diretto.
  bool get isReady => _ready;

  _Mp3Pool(this.assetRelPath, {int size = 4})
      : _players = List.generate(size, (_) => AudioPlayer());

  Future<void> load() async {
    // `_ready = true` solo se almeno un player ha caricato con successo.
    // Prima lo flippavamo a true incondizionatamente anche quando tutti i
    // setSource fallivano silenziosamente → pool "ready" ma muto.
    int loaded = 0;
    for (final p in _players) {
      try {
        await p.setReleaseMode(ReleaseMode.stop);
        await p.setSource(AssetSource('audio/$assetRelPath'));
        loaded++;
      } catch (_) {}
    }
    _ready = loaded > 0;
  }

  Future<void> play({double volume = 1.0}) async {
    if (!_ready) return;
    final p = _players[_next];
    _next = (_next + 1) % _players.length;
    try {
      // Parallelize setVolume + seek (indipendenti) → ~halved latency.
      // Su megaswarm 100+ kill/s con 50ms cooldown → 20 play/s → ~6ms vs
      // 12ms per call. Risparmio ~120ms/sec di event-loop blocking.
      await Future.wait([
        p.setVolume(volume),
        p.seek(Duration.zero),
      ]);
      await p.resume();
    } catch (e) {
      debugPrint('_Mp3Pool play error ($assetRelPath): $e');
    }
  }

  /// Variante a LATENZA ZERO per i boom critici (player death, game over).
  ///
  /// `play()` fa `await Future.wait([setVolume, seek]); await resume()`: due
  /// round-trip sul platform-channel. Ogni `await` aspetta la reply nativa che
  /// torna sull'event-loop Dart — se l'event-loop è intasato (frame di morte:
  /// shockwave + centinaia di particelle) la continuation `resume()` parte
  /// tardi → boom in ritardo (utente: "non si sente subito, lagga").
  ///
  /// Qui invece i tre comandi vengono *dispatchati* senza attendere le reply:
  /// l'executor nativo di audioplayers li esegue in ordine (setVolume→seek→
  /// resume) sul suo thread, indipendente dalla congestione dell'event-loop
  /// Dart. Nessuna attesa Dart-side → il resume raggiunge il plugin subito.
  void playImmediate({double volume = 1.0}) {
    if (!_ready) return;
    final p = _players[_next];
    _next = (_next + 1) % _players.length;
    try {
      unawaited(p.setVolume(volume));
      unawaited(p.seek(Duration.zero));
      unawaited(p.resume());
    } catch (e) {
      debugPrint('_Mp3Pool playImmediate error ($assetRelPath): $e');
    }
  }

  Future<void> dispose() async {
    for (final p in _players) {
      // stop() prima di dispose: interrompe `resume()` in flight, evita
      // race dove player suona ancora dopo dispose. Prima dispose-only
      // → suoni MP3 (mob_killed/boss_killed/player_death) continuavano
      // nel menu post game-over (utente: "esplosioni nel menù").
      try {
        await p.stop();
      } catch (_) {}
      try {
        await p.dispose();
      } catch (_) {}
    }
  }
}

/// Sistema audio con SFX procedurali + feedback aptico.
/// Usa AudioPool per suoni frequenti (evita memory leak da AudioPlayer accumulati).
/// Cooldown per non sovrapporre lo stesso suono troppo rapidamente.
class AudioSystem {
  static bool _vibrationEnabled = true;
  static double _sfxVolume = 0.8;
  static bool _initialized = false;

  // Pool per suoni ad alta frequenza WAV (lowLatency mode = SoundPool su Android,
  // limitato a wav/ogg corti).
  static AudioPool? _shootPool;
  static AudioPool? _geomPool;

  // Pool custom per mp3 ad alta frequenza (mob killed). AudioPool non usabile
  // con mp3 (SoundPool droppa). FlameAudio.play diretto crea AudioPlayer nuovi
  // ogni call → progressive alloc overhead → lag. Soluzione: 4 player riutilizzati.
  static _Mp3Pool? _enemyDeathMp3Pool;

  // Pool mp3 anche per eventi "rari ma critici" (player death, game over, boss
  // killed). Rari in assoluto, ma se si sovrappongono a un cambio di bgm
  // (es. death → skipToNext istantaneo) creare un AudioPlayer nuovo con
  // FlameAudio.play causa contention sul MediaPlayer Android → l'uno o
  // l'altro risulta "buggato". Pool = 1 player riutilizzato = zero alloc.
  static _Mp3Pool? _playerDeathMp3Pool;
  static _Mp3Pool? _bossKilledMp3Pool;
  static _Mp3Pool? _gameOverExplosionMp3Pool;

  // Path constants — tutti gli FX sotto fx/, music sotto bgm/ e intro/.
  // Centralizzati per facilitare future modifiche.
  static const _fxShoot = 'fx/shoot.wav';
  static const _fxEnemyDeath = 'fx/mob_killed.mp3';
  static const _fxBossKilled = 'fx/boss_killed.mp3';
  static const _fxPlayerDeath = 'fx/player_death.mp3';
  static const _fxGameOverExplosion = 'fx/gameover_explosion.mp3';
  static const _fxGeom = 'fx/geom.wav';
  static const _fxBomb = 'fx/bomb.wav';
  static const _fxPowerUp = 'fx/powerup.wav';
  static const _fxPlayerHit = 'fx/player_hit.wav';
  static const _fxBossSpawn = 'fx/boss_spawn.wav';
  static const _fxWaveComplete = 'fx/wave_complete.wav';
  static const _fxGameOver = 'fx/game_over.wav';
  static const _fxExtraLife = 'fx/extra_life.wav';

  // Cooldown: impedisce lo stesso suono di suonare troppo spesso.
  // Map has fixed keys (sound IDs) — bounded growth: one entry per sfx key.
  static final _lastPlayTime = <String, int>{};
  static const _minIntervalMs = 50; // ms minimo tra due riproduzioni dello stesso suono

  // Haptic ha il proprio throttle più lento (~8 Hz): HapticFeedback fa platform
  // channel call che su Android può causare frame hitch. Limitare riduce lag.
  static int _lastHapticMs = 0;
  static const _hapticMinIntervalMs = 120;

  // ─── Burst-aware throttle per playEnemyDeath ───
  // Megaswarm wave + boss minion (300+ mob simultanei) può scatenare 100+
  // kill/sec. Senza burst-detection: 8 vibrazioni/sec costanti per 30s →
  // affaticamento utente + drain batteria; suoni a 20/sec → audio mud
  // distorto. Con burst-detection: dopo soglia, haptic rallenta a ~3 Hz e
  // volume sound dimezzato per evitare clipping.
  // O(1) ring counter: reset quando finestra scade, no list/scan.
  static int _enemyDeathBurstCount = 0;
  static int _enemyDeathBurstStartMs = 0;
  static const _enemyDeathBurstWindowMs = 250;   // finestra rolling
  static const _enemyDeathBurstThreshold = 6;    // >6 in 250ms = burst
  static const _burstHapticMinIntervalMs = 300;  // ~3 Hz durante burst
  // Const cooldown key per playEnemyDeath — evita string-literal sparso
  // (review caveman-pass: "magic string in _canPlay").
  static const _enemyDeathCooldownKey = 'enemy_death';

  /// Throttle haptic con intervallo arbitrario (ms). Centralizza l'accesso
  /// a `_lastHapticMs` così i caller (default `_canHaptic()` o burst-mode
  /// in `playEnemyDeath`) condividono lo stesso state e qualunque logica
  /// futura (telemetry, frame-budget guard) si applica uniformemente.
  static bool _canHapticAt(int minMs) {
    if (!_vibrationEnabled) return false;
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - _lastHapticMs < minMs) return false;
    _lastHapticMs = now;
    return true;
  }

  static bool _canHaptic() => _canHapticAt(_hapticMinIntervalMs);

  /// Inizializza il sistema audio: crea pool per suoni frequenti WAV e
  /// pre-carica gli altri (inclusi i nuovi mp3 dell'utente).
  static Future<void> init() async {
    if (_initialized) return;
    // Attendi la dispose dei vecchi player (se `stopAll()` è stato chiamato
    // poco prima) per evitare contention sul handle MediaPlayer nativo.
    if (_disposeInFlight != null) {
      try { await _disposeInFlight; } catch (_) {}
      _disposeInFlight = null;
    }
    // Double-check post-await: se init() concurrente ha già finito,
    // skip setup (evita pool duplicate/leak).
    if (_initialized) return;
    // Ogni pool ha il proprio try/catch: se uno fallisce non deve killare
    // l'intero sistema audio. `_initialized=true` anche con pool parziali →
    // gli SFX non-falliti funzionano comunque.
    try {
      _shootPool = await FlameAudio.createPool(_fxShoot, maxPlayers: 4);
    } catch (_) {}
    try {
      _geomPool = await FlameAudio.createPool(_fxGeom, maxPlayers: 3);
    } catch (_) {}
    try {
      _enemyDeathMp3Pool = _Mp3Pool(_fxEnemyDeath, size: 4);
      await _enemyDeathMp3Pool!.load();
    } catch (_) {
      _enemyDeathMp3Pool = null;
    }
    try {
      _playerDeathMp3Pool = _Mp3Pool(_fxPlayerDeath, size: 1);
      await _playerDeathMp3Pool!.load();
    } catch (_) {
      _playerDeathMp3Pool = null;
    }
    try {
      _bossKilledMp3Pool = _Mp3Pool(_fxBossKilled, size: 1);
      await _bossKilledMp3Pool!.load();
    } catch (_) {
      _bossKilledMp3Pool = null;
    }
    try {
      _gameOverExplosionMp3Pool = _Mp3Pool(_fxGameOverExplosion, size: 1);
      await _gameOverExplosionMp3Pool!.load();
    } catch (_) {
      _gameOverExplosionMp3Pool = null;
    }
    try {
      // Parallel load via Future.wait invece di loadAll (sequenziale interno).
      // 7 file × ~50ms IO = 350ms sequential vs ~80ms parallel su disk SSD.
      // Riduce significativamente la latenza di init audio al cold-start.
      await Future.wait([
        FlameAudio.audioCache.load(_fxBomb),
        FlameAudio.audioCache.load(_fxPowerUp),
        FlameAudio.audioCache.load(_fxPlayerHit),
        FlameAudio.audioCache.load(_fxBossSpawn),
        FlameAudio.audioCache.load(_fxWaveComplete),
        FlameAudio.audioCache.load(_fxGameOver),
        FlameAudio.audioCache.load(_fxExtraLife),
      ]);
    } catch (_) {}
    // Flag sempre true se arriviamo qui: _canPlay/_playRare hanno già
    // null-check sui pool, suoni falliti restano muti ma quelli ok partono.
    _initialized = true;
  }

  static void setVibration(bool enabled) {
    _vibrationEnabled = enabled;
  }

  static void setSfxVolume(double volume) {
    _sfxVolume = volume.clamp(0.0, 1.0);
  }

  static double _bgmVolume = 0.7;

  static void setBgmVolume(double volume) {
    _bgmVolume = volume.clamp(0.0, 1.0);
  }

  static double get bgmVolume => _bgmVolume;

  /// Controlla il cooldown per evitare spam dello stesso suono
  static bool _canPlay(String key) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final last = _lastPlayTime[key] ?? 0;
    if (now - last < _minIntervalMs) return false;
    _lastPlayTime[key] = now;
    return true;
  }

  /// Lista dei player creati da `FlameAudio.play` (rari): tracciati per poter
  /// essere stoppati in `stopAll`, altrimenti continuano a suonare nel menu
  /// dopo l'uscita dalla partita (utente: "esplosioni nel menù"). Auto-purge
  /// post `onPlayerComplete` per evitare memory growth.
  static final List<AudioPlayer> _trackedRarePlayers = [];

  /// Wrapper per FlameAudio.play che tracka il player. Usato da `_playRare` e
  /// `_tryDirectThenPool`.
  ///
  /// Race-safe: se `stopAll()` ha flippato `_initialized=false` mentre la
  /// `FlameAudio.play(...)` Future era in flight, il player risolto viene
  /// stopped+disposed immediatamente (senza essere aggiunto alla lista, che
  /// è già stata svuotata). Senza questa guard, player orphan persistevano
  /// nel menù post game-exit.
  static void _playTracked(String asset, double volume) {
    try {
      FlameAudio.play(asset, volume: volume).then<void>((player) {
        if (!_initialized) {
          // stopAll() chiamato durante FlameAudio.play in flight → kill subito.
          try { player.stop(); } catch (_) {}
          try { player.dispose(); } catch (_) {}
          return;
        }
        _trackedRarePlayers.add(player);
        // Auto-cleanup quando il track finisce naturalmente.
        player.onPlayerComplete.first.then((_) {
          _trackedRarePlayers.remove(player);
        }).catchError((Object _) {});
      }, onError: (Object _, StackTrace _) {});
    } catch (_) {}
  }

  /// Suono raro via FlameAudio.play (OK perché chiamato poche volte per partita)
  static void _playRare(String file, {double volumeScale = 1.0}) {
    if (!_initialized || _sfxVolume <= 0) return;
    if (!_canPlay(file)) return;
    _playTracked(file, _sfxVolume * volumeScale);
  }

  /// Sparo — pool (alta frequenza)
  static void playShoot() {
    if (!_initialized || _sfxVolume <= 0) return;
    if (!_canPlay('shoot')) return;
    try {
      _shootPool?.start(volume: _sfxVolume * 0.4);
    } catch (_) {}
    if (_canHaptic()) HapticFeedback.selectionClick();
  }

  /// Nemico ucciso — pool mp3 custom (4 AudioPlayer round-robin) per
  /// evitare alloc nuovi player ad ogni kill (lag progressivo a 100+
  /// kill/min). Cooldown 50ms gates spam sound; burst-detection
  /// (vedi `_enemyDeathBurstThreshold`) rallenta haptic a 3Hz e dimezza
  /// volume durante megaswarm/spawn boss simultanei → no audio mud, no
  /// vibration fatigue, no battery drain.
  static void playEnemyDeath() {
    final canPlaySound = _initialized && _sfxVolume > 0;
    final canVibrate = _vibrationEnabled;
    if (!canPlaySound && !canVibrate) return;

    final now = DateTime.now().millisecondsSinceEpoch;
    // Reset finestra burst quando scade (O(1), no list).
    if (now - _enemyDeathBurstStartMs > _enemyDeathBurstWindowMs) {
      _enemyDeathBurstStartMs = now;
      _enemyDeathBurstCount = 0;
    }
    _enemyDeathBurstCount++;
    final inBurst = _enemyDeathBurstCount > _enemyDeathBurstThreshold;

    // Suono: gate cooldown + volume ridotto in burst (clipping protection).
    if (_initialized && _sfxVolume > 0 && _canPlay(_enemyDeathCooldownKey)) {
      final volScale = inBurst ? 0.35 : 0.6;
      _enemyDeathMp3Pool?.play(volume: _sfxVolume * volScale);
    }

    // Haptic: throttle adattivo via helper centralizzato. Idle=120ms (8Hz),
    // burst=300ms (3Hz). `_canHapticAt` aggiorna `_lastHapticMs` solo se
    // passa il gate → resta source-of-truth per chiunque legga lo state.
    final hapticMinMs = inBurst ? _burstHapticMinIntervalMs : _hapticMinIntervalMs;
    if (_canHapticAt(hapticMinMs)) HapticFeedback.lightImpact();
  }

  /// Geom raccolto — pool (alta frequenza)
  static void playGeomCollect() {
    if (!_initialized || _sfxVolume <= 0) return;
    if (!_canPlay('geom')) return;
    try {
      _geomPool?.start(volume: _sfxVolume * 0.25);
    } catch (_) {}
  }

  /// Esplosione bomba (raro). Haptic con throttle 200ms (era bypass) →
  /// evita doppia vibrazione se bomba + player-hit ravvicinati.
  static void playBombExplosion() {
    _playRare(_fxBomb);
    if (_canHapticAt(200)) HapticFeedback.heavyImpact();
  }

  /// Player colpito (raro). Haptic throttle 200ms.
  static void playPlayerHit() {
    _playRare(_fxPlayerHit);
    if (_canHapticAt(200)) HapticFeedback.mediumImpact();
  }

  /// Power-up raccolto (raro)
  static void playPowerUp() {
    _playRare(_fxPowerUp);
    if (_canHaptic()) HapticFeedback.selectionClick();
  }

  /// Boss spawna (raro). Haptic throttle 200ms.
  static void playBossSpawn() {
    _playRare(_fxBossSpawn);
    if (_canHapticAt(200)) HapticFeedback.heavyImpact();
  }

  /// Wave completata (raro). Haptic throttle 200ms.
  static void playWaveComplete() {
    _playRare(_fxWaveComplete);
    if (_canHapticAt(200)) HapticFeedback.mediumImpact();
  }

  /// Perfect wave (raro) — chiave cooldown separata da playWaveComplete
  static void playPerfectWave() {
    if (!_initialized || _sfxVolume <= 0) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - (_lastPlayTime['perfect_wave'] ?? 0) < _minIntervalMs) return;
    _lastPlayTime['perfect_wave'] = now;
    _playTracked(_fxWaveComplete, _sfxVolume);
    if (_canHapticAt(200)) HapticFeedback.heavyImpact();
  }

  /// Helper: prova direct `FlameAudio.play`, su failure (sync O async)
  /// fallback al pool fornito. `FlameAudio.play` è async → sync try/catch
  /// non intercetta errori post-return del Future. `.then`+onError li cattura.
  ///
  /// Fix: il precedente `catchError` ritornava `Future<AudioPlayer>.error(...)`
  /// lasciando un error future dangling nella root zone → unhandled error log
  /// su alcuni device. Ora `.then` con `onError` consuma l'errore senza
  /// propagarlo.
  static void _tryDirectThenPool(
      String asset, double volume, _Mp3Pool? fallbackPool) {
    void poolFallback() {
      if (_initialized && fallbackPool != null) {
        fallbackPool.play(volume: volume);
      }
    }
    try {
      FlameAudio.play(asset, volume: volume).then<void>(
        (player) {
          // Race-safe: stopAll() durante FlameAudio.play in flight → kill.
          if (!_initialized) {
            try { player.stop(); } catch (_) {}
            try { player.dispose(); } catch (_) {}
            return;
          }
          _trackedRarePlayers.add(player);
          player.onPlayerComplete.first.then((_) {
            _trackedRarePlayers.remove(player);
          }).catchError((Object _) {});
        },
        onError: (Object _, StackTrace _) {
          poolFallback();
        },
      );
    } catch (_) {
      poolFallback();
    }
  }

  /// Inverso di `_tryDirectThenPool`: usa PRIMA il pool preloaded (player già
  /// preparato in `init` → `seek(0)+resume` parte subito, nessun prepare),
  /// `FlameAudio.play` solo come fallback se il pool non ha caricato.
  ///
  /// Per gli FX "boom" critici dove la LATENZA conta (player death, game over):
  /// sotto carico — death shockwave (kill 600px + 70+ particelle + grid
  /// distortion) e "troppa roba a schermo" — la UI thread è satura. Creare e
  /// preparare un MediaPlayer nuovo via `FlameAudio.play` accoda diverse call
  /// pesanti sul platform channel → il suono arriva in ritardo. Il pool fa una
  /// sola call leggera (resume) → boom immediato.
  static void _tryPoolThenDirect(String asset, double volume, _Mp3Pool? pool,
      {bool immediate = false}) {
    if (pool != null && pool.isReady) {
      // `immediate`: dispatch senza await reply (vedi `playImmediate`) → boom
      // non affogato dalla congestione event-loop del frame di morte.
      if (immediate) {
        pool.playImmediate(volume: volume);
      } else {
        pool.play(volume: volume);
      }
    } else {
      // Pool assente o non pronto → best effort diretto (pool come 2° fallback).
      _tryDirectThenPool(asset, volume, pool);
    }
  }

  /// Game over (raro) — esplosione drammatica gameover_explosion.mp3
  /// + tono game_over.wav legacy in coda. Haptic throttle 200ms.
  static void playGameOver() {
    if (_initialized && _sfxVolume > 0 && _canPlay(_fxGameOverExplosion)) {
      final boosted = (_sfxVolume * 1.1).clamp(0.0, 1.0);
      // Pool-first + immediate per la stessa ragione di playerDeath: il game
      // over arriva su un frame pesantissimo (mega esplosione finale) → niente
      // latenza, dispatch senza await reply.
      _tryPoolThenDirect(_fxGameOverExplosion, boosted,
          _gameOverExplosionMp3Pool, immediate: true);
    }
    _playRare(_fxGameOver, volumeScale: 0.6);
    if (_canHapticAt(200)) HapticFeedback.heavyImpact();
  }

  /// Player death — direct play. Haptic throttle 200ms (evita doppia
  /// vibrazione se player muore + boss/bomb in stesso frame).
  static void playPlayerDeath() {
    if (_initialized && _sfxVolume > 0 && _canPlay(_fxPlayerDeath)) {
      // Pool-first + immediate: il BOOM deve partire SUBITO anche col frame
      // intasato dalla death shockwave + tanti entity a schermo (utente:
      // "arriva in ritardo se c'è troppa roba sullo schermo"). `immediate`
      // dispatcha seek+resume senza attendere le reply → nessun ritardo
      // event-loop Dart-side.
      _tryPoolThenDirect(_fxPlayerDeath, _sfxVolume, _playerDeathMp3Pool,
          immediate: true);
    }
    if (_canHapticAt(200)) HapticFeedback.heavyImpact();
  }

  /// Boss killed — fanfara di vittoria. Haptic throttle 200ms.
  static void playBossKilled() {
    if (_initialized && _sfxVolume > 0 && _canPlay(_fxBossKilled)) {
      _tryDirectThenPool(_fxBossKilled, _sfxVolume, _bossKilledMp3Pool);
    }
    if (_canHapticAt(200)) HapticFeedback.heavyImpact();
  }

  /// Extra life (raro). Haptic throttle 200ms.
  static void playExtraLife() {
    _playRare(_fxExtraLife);
    if (_canHapticAt(200)) HapticFeedback.mediumImpact();
  }

  /// Ferma tutti i suoni e rilascia risorse.
  /// Flippa `_initialized=false` sincrono così le call successive ritornano
  /// subito; la disposizione effettiva dei pool avviene async in background.
  /// Una `init()` chiamata immediatamente dopo attende la disposizione dei
  /// vecchi player via `_disposeInFlight` per evitare contention native.
  static void stopAll() {
    _initialized = false;
    _lastPlayTime.clear();
    // Reset burst counter + last haptic ts: evita stato stale cross-session
    // (ad es. burst attivo a fine partita → menù → nuova partita con
    // throttle ancora aggressivo per i primi 250ms).
    _enemyDeathBurstCount = 0;
    _enemyDeathBurstStartMs = 0;
    _lastHapticMs = 0;

    // Stop + dispose dei FlameAudio.play orphan players (utente: "esplosioni
    // nel menù"). Senza questo, suoni gameOver/bossKilled/playerDeath/bomb/
    // bossSpawn che erano in flight quando user esce dalla partita
    // continuavano a suonare in background.
    final rareSnapshot = List<AudioPlayer>.from(_trackedRarePlayers);
    _trackedRarePlayers.clear();
    for (final p in rareSnapshot) {
      try { p.stop(); } catch (_) {}
      try { p.dispose(); } catch (_) {}
    }

    final toDispose = <Future<void>>[];
    // Flame AudioPool.dispose() returns Future<void> — accodalo a toDispose
    // così l'attesa successiva (Future.wait) include anche questi pool.
    if (_shootPool != null) {
      toDispose.add(_shootPool!.dispose().catchError((_) {}));
    }
    if (_geomPool != null) {
      toDispose.add(_geomPool!.dispose().catchError((_) {}));
    }
    _shootPool = null;
    _geomPool = null;
    final pools = [
      _enemyDeathMp3Pool,
      _playerDeathMp3Pool,
      _bossKilledMp3Pool,
      _gameOverExplosionMp3Pool,
    ];
    for (final pool in pools) {
      if (pool != null) {
        toDispose.add(pool.dispose().catchError((_) {}));
      }
    }
    _enemyDeathMp3Pool = null;
    _playerDeathMp3Pool = null;
    _bossKilledMp3Pool = null;
    _gameOverExplosionMp3Pool = null;
    // NB: NON chiamiamo audioCache.clearAll() — la cache è condivisa con la
    // bgm (music_manager) e clear aggressivo invalida asset usati dal
    // playIntro/playBgm del prossimo screen → latenza/fallimento del play.
    _disposeInFlight = Future.wait(toDispose);
  }

  /// Attesa sulla dispose dei player precedenti. `init()` await questo
  /// prima di creare nuovi pool → niente race sul handle MediaPlayer nativo.
  static Future<void>? _disposeInFlight;
}
