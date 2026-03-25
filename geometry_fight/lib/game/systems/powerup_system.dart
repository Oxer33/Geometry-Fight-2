import 'dart:math' as math;
import 'package:flame/components.dart';
import '../../data/constants.dart';
import '../game_world.dart';
import '../entities/powerups.dart';

class PowerUpSystem {
  final GeometryFightGame game;
  double _spawnTimer = 20;
  final _random = math.Random();

  PowerUpSystem(this.game);

  void update(double dt) {
    _spawnTimer -= dt;
    if (_spawnTimer <= 0) {
      _spawnTimer = 15 + _random.nextDouble() * 15;
      _spawnRandomInArena();
    }
  }

  void _spawnRandomInArena() {
    final Vector2 pos;
    if (game.isTunnelMode) {
      // Tunnel: spawna nella zona visibile della camera
      final cam = game.camera.viewfinder.position;
      final halfW = game.size.x > 0 ? game.size.x / 2 : 400.0;
      final halfH = game.size.y > 0 ? game.size.y / 2 : 300.0;
      pos = Vector2(
        cam.x + (_random.nextDouble() - 0.3) * halfW * 1.5, // Leggermente avanti
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

  void spawnRandomPowerUp(Vector2 position) {
    final types = PowerUpType.values;
    final type = types[_random.nextInt(types.length)];
    final powerUp = PowerUp(type: type);
    powerUp.position = position;
    game.world.add(powerUp);
  }
}
