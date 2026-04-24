import 'dart:math' show min;
import 'package:flame/components.dart' show Vector2;

/// Sistema di punteggio stile Geometry Wars RE2.
/// Moltiplicatore: +geomValueMultiplier per ogni geom raccolto, reset a 1x quando si muore.
/// Vite extra a: 10K, 100K, 1M, 10M, 100M, 1B punti.
class ScoreSystem {
  int score = 0;
  int geoms = 0;
  double multiplier = 1.0;
  double geomValueMultiplier = 1.0; // +Nx per geom (1.0 easy/normal, 1.25 hard, 1.5 nightmare)
  double scoreMultiplier = 1.0; // Moltiplicatore punti per difficoltà (0.5x easy → 4x nightmare)
  double modifierMultiplier = 1.0; // Moltiplicatore da modifier attivi (glass_cannon 3×, bullet_hell 2×, ecc.)

  static const double _maxMultiplier = 9999; // Cap ragionevole per evitare overflow

  // Soglie vite extra (potenze di 10 da 10K)
  final List<int> _extraLifeThresholds = [
    10000, 100000, 1000000, 10000000, 100000000, 1000000000,
  ];
  int _nextLifeIndex = 0;
  bool _extraLifeEarned = false;

  void update(double dt) {
    _extraLifeEarned = false;
    if (_nextLifeIndex < _extraLifeThresholds.length &&
        score >= _extraLifeThresholds[_nextLifeIndex]) {
      _extraLifeEarned = true;
      _nextLifeIndex++;
    }
  }

  /// True se il player ha guadagnato una vita extra in questo frame
  bool get earnedExtraLife => _extraLifeEarned;

  /// Multiplier arrotondato per il display
  int get multiplierDisplay => multiplier.round();

  void addKill(int points, Vector2 _) {
    // Punti = base × multiplier geom × scoreMultiplier difficoltà × modifierMultiplier.
    // Param position riservato a futuri floaty-text/combo emitter; placeholder
    // `_` silenzia lint unused_element senza rompere callsite esistenti.
    final earnedPoints = (points * multiplier * scoreMultiplier * modifierMultiplier).round();
    score += earnedPoints;
  }

  /// Chiamato quando si raccoglie un geom: aumenta il moltiplicatore
  void addGeoms(int amount) {
    geoms += amount;
    multiplier += amount * geomValueMultiplier;
    multiplier = min(multiplier, _maxMultiplier); // Cap al massimo
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
    // NOTA: geomValueMultiplier, scoreMultiplier e modifierMultiplier NON resettati qui
    // perché sono settati dalla difficoltà/modifier in game_world
  }
}
