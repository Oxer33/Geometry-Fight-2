import 'package:flame/components.dart' show Vector2;

/// Sistema di punteggio stile Geometry Wars RE2.
/// Moltiplicatore: +geomValueMultiplier per ogni geom raccolto, reset a 1x quando si muore.
/// Vite extra a: 10K, 100K, 1M, 10M, 100M, 1B punti.
class ScoreSystem {
  int score = 0;
  int geoms = 0;
  double multiplier = 1.0; // Double per supportare incrementi frazionari (+1.25x, +1.5x)
  double geomValueMultiplier = 1.0; // Quanto vale ogni geom per il moltiplicatore (da difficulty)

  // Soglie vite extra (potenze di 10 da 10K)
  final List<int> _extraLifeThresholds = [
    10000, 100000, 1000000, 10000000, 100000000, 1000000000,
  ];
  int _nextLifeIndex = 0;
  bool _extraLifeEarned = false; // Flag per il game_world

  void update(double dt) {
    // Check vite extra
    _extraLifeEarned = false;
    if (_nextLifeIndex < _extraLifeThresholds.length &&
        score >= _extraLifeThresholds[_nextLifeIndex]) {
      _extraLifeEarned = true;
      _nextLifeIndex++;
    }
  }

  /// True se il player ha guadagnato una vita extra in questo frame
  bool get earnedExtraLife => _extraLifeEarned;

  /// Multiplier troncato a intero per il display
  int get multiplierDisplay => multiplier.toInt();

  void addKill(int points, Vector2 position) {
    final earnedPoints = (points * multiplier).round();
    score += earnedPoints;
  }

  /// Chiamato quando si raccoglie un geom: aumenta il moltiplicatore
  void addGeoms(int amount) {
    geoms += amount;
    multiplier += amount * geomValueMultiplier; // +Nx per geom raccolto (scala con difficoltà)
  }

  /// Reset moltiplicatore a 1x (quando il player muore)
  void resetMultiplier() {
    multiplier = 1.0;
  }

  void reset() {
    score = 0;
    geoms = 0;
    multiplier = 1.0;
    _nextLifeIndex = 0;
    _extraLifeEarned = false;
  }

  // Combo rimossa (non più necessaria)
  int comboCount = 0;
  bool get showingCombo => false;
}
