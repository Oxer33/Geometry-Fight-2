import 'dart:ui';
import 'package:flame/components.dart';
import '../../data/constants.dart';
import '../effects/explosion.dart';

class ScoreSystem {
  int score = 0;
  int geoms = 0;
  double multiplier = 1.0;
  double _doubleMultiplierTimer = 0;
  bool get hasDoubleMultiplier => _doubleMultiplierTimer > 0;

  // Combo tracking
  final List<double> _recentKillTimes = [];
  int comboCount = 0;
  double _comboDisplayTimer = 0;

  double _gameTime = 0;

  void update(double dt) {
    _gameTime += dt;

    if (_doubleMultiplierTimer > 0) {
      _doubleMultiplierTimer -= dt;
    }

    if (_comboDisplayTimer > 0) {
      _comboDisplayTimer -= dt;
    }

    // Clean old kill times
    _recentKillTimes.removeWhere((t) => _gameTime - t > comboTimeWindow);
  }

  void addKill(int points, Vector2 position) {
    final effectiveMultiplier =
        multiplier * (hasDoubleMultiplier ? 2.0 : 1.0);
    final earnedPoints = (points * effectiveMultiplier).round();
    score += earnedPoints;

    // Increase multiplier
    multiplier = (multiplier + multiplierPerKill).clamp(1.0, maxMultiplier);

    // Track combo
    _recentKillTimes.add(_gameTime);
    if (_recentKillTimes.length >= comboThreshold) {
      comboCount = _recentKillTimes.length;
      _comboDisplayTimer = 1.5;
      score += comboCount * 100; // Bonus combo points
    }
  }

  void addGeoms(int amount) {
    geoms += amount;
  }

  void resetMultiplier() {
    multiplier = 1.0;
    comboCount = 0;
    _recentKillTimes.clear();
  }

  void activateDoubleMultiplier(double seconds) {
    _doubleMultiplierTimer = seconds;
  }

  void reset() {
    score = 0;
    geoms = 0;
    multiplier = 1.0;
    _doubleMultiplierTimer = 0;
    comboCount = 0;
    _recentKillTimes.clear();
    _gameTime = 0;
  }

  bool get showingCombo => _comboDisplayTimer > 0;
}
