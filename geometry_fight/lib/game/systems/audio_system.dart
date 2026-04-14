import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/services.dart';

/// Sistema audio con SFX procedurali + feedback aptico.
/// Usa AudioPool per suoni frequenti (evita memory leak da AudioPlayer accumulati).
/// Cooldown per non sovrapporre lo stesso suono troppo rapidamente.
class AudioSystem {
  static bool _vibrationEnabled = true;
  static double _sfxVolume = 0.8;
  static bool _initialized = false;

  // Pool per suoni ad alta frequenza (riutilizzano gli AudioPlayer)
  static AudioPool? _shootPool;
  static AudioPool? _enemyDeathPool;
  static AudioPool? _geomPool;

  // Cooldown: impedisce lo stesso suono di suonare troppo spesso
  static final _lastPlayTime = <String, int>{};
  static const _minIntervalMs = 50; // ms minimo tra due riproduzioni dello stesso suono

  /// Inizializza il sistema audio: crea pool per suoni frequenti e pre-carica il resto
  static Future<void> init() async {
    if (_initialized) return;
    try {
      // Pool per suoni ad alta frequenza (max 4 player simultanei ciascuno)
      _shootPool = await FlameAudio.createPool('shoot.wav', maxPlayers: 4);
      _enemyDeathPool = await FlameAudio.createPool('enemy_death.wav', maxPlayers: 4);
      _geomPool = await FlameAudio.createPool('geom.wav', maxPlayers: 3);

      // Pre-carica suoni rari (usati con FlameAudio.play — OK perché rarissimi)
      await FlameAudio.audioCache.loadAll([
        'bomb.wav',
        'powerup.wav',
        'player_hit.wav',
        'boss_spawn.wav',
        'wave_complete.wav',
        'game_over.wav',
        'extra_life.wav',
      ]);
      _initialized = true;
    } catch (_) {
      _initialized = false;
    }
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

  /// Suono raro via FlameAudio.play (OK perché chiamato poche volte per partita)
  static void _playRare(String file, {double volumeScale = 1.0}) {
    if (!_initialized || _sfxVolume <= 0) return;
    if (!_canPlay(file)) return;
    try {
      FlameAudio.play(file, volume: _sfxVolume * volumeScale);
    } catch (_) {}
  }

  /// Sparo — pool (alta frequenza)
  static void playShoot() {
    if (!_initialized || _sfxVolume <= 0) return;
    if (!_canPlay('shoot')) return;
    try {
      _shootPool?.start(volume: _sfxVolume * 0.4);
    } catch (_) {}
    if (_vibrationEnabled) HapticFeedback.selectionClick();
  }

  /// Nemico ucciso — pool (altissima frequenza)
  static void playEnemyDeath() {
    if (!_initialized || _sfxVolume <= 0) return;
    if (!_canPlay('enemy_death')) return;
    try {
      _enemyDeathPool?.start(volume: _sfxVolume * 0.6);
    } catch (_) {}
    if (_vibrationEnabled) HapticFeedback.lightImpact();
  }

  /// Geom raccolto — pool (alta frequenza)
  static void playGeomCollect() {
    if (!_initialized || _sfxVolume <= 0) return;
    if (!_canPlay('geom')) return;
    try {
      _geomPool?.start(volume: _sfxVolume * 0.25);
    } catch (_) {}
  }

  /// Esplosione bomba (raro)
  static void playBombExplosion() {
    _playRare('bomb.wav');
    if (_vibrationEnabled) HapticFeedback.heavyImpact();
  }

  /// Player colpito (raro)
  static void playPlayerHit() {
    _playRare('player_hit.wav');
    if (_vibrationEnabled) HapticFeedback.mediumImpact();
  }

  /// Power-up raccolto (raro)
  static void playPowerUp() {
    _playRare('powerup.wav');
    if (_vibrationEnabled) HapticFeedback.selectionClick();
  }

  /// Boss spawna (raro)
  static void playBossSpawn() {
    _playRare('boss_spawn.wav');
    if (_vibrationEnabled) HapticFeedback.heavyImpact();
  }

  /// Wave completata (raro)
  static void playWaveComplete() {
    _playRare('wave_complete.wav');
    if (_vibrationEnabled) HapticFeedback.mediumImpact();
  }

  /// Perfect wave (raro)
  static void playPerfectWave() {
    _playRare('wave_complete.wav');
    if (_vibrationEnabled) HapticFeedback.heavyImpact();
  }

  /// Game over (raro)
  static void playGameOver() {
    _playRare('game_over.wav');
    if (_vibrationEnabled) HapticFeedback.heavyImpact();
  }

  /// Extra life (raro)
  static void playExtraLife() {
    _playRare('extra_life.wav');
    if (_vibrationEnabled) HapticFeedback.mediumImpact();
  }

  /// Ferma tutti i suoni e rilascia risorse
  static void stopAll() {
    try {
      _shootPool?.dispose();
      _enemyDeathPool?.dispose();
      _geomPool?.dispose();
      _shootPool = null;
      _enemyDeathPool = null;
      _geomPool = null;
      FlameAudio.audioCache.clearAll();
      _lastPlayTime.clear();
      _initialized = false;
    } catch (_) {}
  }
}
