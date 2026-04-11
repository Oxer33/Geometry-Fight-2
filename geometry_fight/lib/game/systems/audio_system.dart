import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/services.dart';

/// Sistema audio con SFX procedurali + feedback aptico.
class AudioSystem {
  static bool _vibrationEnabled = true;
  static double _sfxVolume = 0.8;
  static bool _initialized = false;

  /// Inizializza il sistema audio: pre-carica tutti i file SFX
  static Future<void> init() async {
    try {
      await FlameAudio.audioCache.loadAll([
        'shoot.wav',
        'enemy_death.wav',
        'bomb.wav',
        'powerup.wav',
        'player_hit.wav',
        'boss_spawn.wav',
        'wave_complete.wav',
        'game_over.wav',
        'geom.wav',
        'extra_life.wav',
      ]);
      _initialized = true;
    } catch (_) {
      // Audio non disponibile (es. emulatore senza audio)
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

  /// Imposta il volume della musica di sottofondo (0.0–1.0).
  /// Pronto per quando verrà aggiunta la BGM.
  static void setBgmVolume(double volume) {
    _bgmVolume = volume.clamp(0.0, 1.0);
    // TODO: applicare a FlameAudio.bgm quando la BGM sarà implementata
  }

  static double get bgmVolume => _bgmVolume;

  static void _play(String file, {double volumeScale = 1.0}) {
    if (!_initialized || _sfxVolume <= 0) return;
    try {
      FlameAudio.play(file, volume: _sfxVolume * volumeScale);
    } catch (_) {
      // Ignora errori audio
    }
  }

  /// Sparo
  static void playShoot() {
    _play('shoot.wav', volumeScale: 0.4);
    if (_vibrationEnabled) HapticFeedback.selectionClick();
  }

  /// Nemico ucciso
  static void playEnemyDeath() {
    _play('enemy_death.wav', volumeScale: 0.6);
    if (_vibrationEnabled) HapticFeedback.lightImpact();
  }

  /// Esplosione bomba
  static void playBombExplosion() {
    _play('bomb.wav');
    if (_vibrationEnabled) HapticFeedback.heavyImpact();
  }

  /// Player colpito
  static void playPlayerHit() {
    _play('player_hit.wav');
    if (_vibrationEnabled) HapticFeedback.mediumImpact();
  }

  /// Power-up raccolto
  static void playPowerUp() {
    _play('powerup.wav');
    if (_vibrationEnabled) HapticFeedback.selectionClick();
  }

  /// Boss spawna
  static void playBossSpawn() {
    _play('boss_spawn.wav');
    if (_vibrationEnabled) HapticFeedback.heavyImpact();
  }

  /// Geom raccolto
  static void playGeomCollect() {
    _play('geom.wav', volumeScale: 0.25);
  }

  /// Wave completata
  static void playWaveComplete() {
    _play('wave_complete.wav');
    if (_vibrationEnabled) HapticFeedback.mediumImpact();
  }

  /// Perfect wave
  static void playPerfectWave() {
    _play('wave_complete.wav');
    if (_vibrationEnabled) HapticFeedback.heavyImpact();
  }

  /// Game over
  static void playGameOver() {
    _play('game_over.wav');
    if (_vibrationEnabled) HapticFeedback.heavyImpact();
  }

  /// Extra life
  static void playExtraLife() {
    _play('extra_life.wav');
    if (_vibrationEnabled) HapticFeedback.mediumImpact();
  }

  /// Ferma tutti i suoni in riproduzione (chiamato su game over / quit)
  static void stopAll() {
    try {
      FlameAudio.audioCache.clearAll();
      // Re-init al prossimo gioco
      _initialized = false;
    } catch (_) {}
  }
}
