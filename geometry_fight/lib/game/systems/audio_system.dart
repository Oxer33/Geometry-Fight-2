import 'package:flutter/services.dart';

/// Sistema audio minimale con feedback aptico.
/// Usa vibrazioni del dispositivo per feedback tattile su eventi di gioco.
/// Struttura pronta per integrare file audio reali in futuro.
class AudioSystem {
  static bool _vibrationEnabled = true;

  /// Inizializza il sistema audio (placeholder per audio reale futuro)
  static Future<void> init() async {
    // Pronto per integrare flame_audio o audioplayers in futuro
  }

  /// Abilita/disabilita vibrazioni
  static void setVibration(bool enabled) {
    _vibrationEnabled = enabled;
  }

  /// Feedback aptico leggero (sparo)
  static void playShoot() {
    if (_vibrationEnabled) {
      HapticFeedback.selectionClick();
    }
  }

  /// Feedback aptico medio (nemico ucciso)
  static void playEnemyDeath() {
    if (_vibrationEnabled) {
      HapticFeedback.lightImpact();
    }
  }

  /// Feedback aptico forte (esplosione bomba)
  static void playBombExplosion() {
    if (_vibrationEnabled) {
      HapticFeedback.heavyImpact();
    }
  }

  /// Feedback aptico (player colpito)
  static void playPlayerHit() {
    if (_vibrationEnabled) {
      HapticFeedback.mediumImpact();
    }
  }

  /// Feedback aptico (power-up raccolto)
  static void playPowerUp() {
    if (_vibrationEnabled) {
      HapticFeedback.selectionClick();
    }
  }

  /// Feedback aptico (boss spawna)
  static void playBossSpawn() {
    if (_vibrationEnabled) {
      HapticFeedback.heavyImpact();
    }
  }

  /// Feedback aptico (geom raccolto)
  static void playGeomCollect() {
    // Nessuna vibrazione per geom (troppo frequente)
  }

  /// Feedback aptico (wave completata)
  static void playWaveComplete() {
    if (_vibrationEnabled) {
      HapticFeedback.mediumImpact();
    }
  }

  /// Feedback aptico (perfect wave)
  static void playPerfectWave() {
    if (_vibrationEnabled) {
      HapticFeedback.heavyImpact();
    }
  }

  /// Feedback aptico (game over)
  static void playGameOver() {
    if (_vibrationEnabled) {
      HapticFeedback.heavyImpact();
    }
  }
}
