import 'dart:math' as math;
import 'package:flame/components.dart';
import '../../data/constants.dart';
import '../game_world.dart';
import '../entities/powerups.dart';

class PowerUpSystem {
  final GeometryFightGame game;
  // Spawn timer iniziale più lungo (era 20)
  double _spawnTimer = 60;
  final _random = math.Random();

  PowerUpSystem(this.game);

  void update(double dt) {
    _spawnTimer -= dt;
    if (_spawnTimer <= 0) {
      // Timer-based spawn: era 15-30s, ora 60-120s (4x meno frequente).
      // I drop da kill sono già /20 via powerUpDropRate; il timer resta safety net.
      _spawnTimer = 60 + _random.nextDouble() * 60;
      _spawnRandomInArena();
    }
  }

  void _spawnRandomInArena() {
    final Vector2 pos;
    if (game.isTunnelMode) {
      final cam = game.camera.viewfinder.position;
      final halfW = game.size.x > 0 ? game.size.x / 2 : 400.0;
      final halfH = game.size.y > 0 ? game.size.y / 2 : 300.0;
      pos = Vector2(
        cam.x + (_random.nextDouble() - 0.3) * halfW * 1.5,
        cam.y + (_random.nextDouble() - 0.5) * halfH * 1.2,
      );
    } else {
      pos = Vector2(
        100 + _random.nextDouble() * (arenaWidth - 200),
        100 + _random.nextDouble() * (arenaHeight - 200),
      );
    }
    spawnRandomPowerUp(pos);
  }

  void reset() {
    // Match constructor default (60s) per consistency post-restart.
    _spawnTimer = 60;
  }

  void spawnRandomPowerUp(Vector2 position) {
    // Modifier no_powerups (PURISTA): skip ogni spawn powerup. Effettivo
    // sia per timer-based sia per drop da kill (entrambi passano qui).
    if (game.hasModifier('no_powerups')) return;
    // Selezione pesata per rarità
    final type = PowerUpRarityConfig.rollWeighted(_random);
    final powerUp = PowerUp(type: type);
    powerUp.position = position;
    game.world.add(powerUp);
  }
}
