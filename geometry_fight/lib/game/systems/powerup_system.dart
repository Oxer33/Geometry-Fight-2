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
    final pos = Vector2(
      100 + _random.nextDouble() * (arenaWidth - 200),
      100 + _random.nextDouble() * (arenaHeight - 200),
    );
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
