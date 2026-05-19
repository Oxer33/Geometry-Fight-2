import 'dart:math' as math;
import 'package:flame/components.dart';
import '../../data/constants.dart';
import '../../data/difficulty.dart';
import '../game_world.dart';
import '../entities/powerups.dart';

class PowerUpSystem {
  final GeometryFightGame game;
  // Spawn timer iniziale più lungo (era 20).
  // Boost ×1.5 (richiesta utente): timer iniziale 60 → 40s, cadenza 60-120s →
  // 40-80s. Snake mode: spawn powerup totalmente disabilitato (vedi
  // `spawnRandomPowerUp` early-return).
  double _spawnTimer = 40;
  final _random = math.Random();

  PowerUpSystem(this.game);

  void update(double dt) {
    // Snake mode: nessun powerup mai (regola design: trail-kill puro).
    if (game.gameMode == GameMode.snake) return;
    _spawnTimer -= dt;
    if (_spawnTimer <= 0) {
      // Cadenza accelerata ×1.5 (richiesta utente): era 60-120s, ora 40-80s.
      // I drop da kill restano scalati da `powerUpDropRate` (difficulty) +
      // boost ×1.5 applicato in game_world `onEnemyKilled`.
      _spawnTimer = 40 + _random.nextDouble() * 40;
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
    // Match constructor default (40s) per consistency post-restart.
    _spawnTimer = 40;
  }

  void spawnRandomPowerUp(Vector2 position) {
    // Pacifist: nessun powerup (regola GW2 Pacifism — sopravvivenza pura).
    if (game.isPacifistMode) return;
    // Snake mode: nessun powerup (no spari, no armi → powerup irrilevanti).
    if (game.gameMode == GameMode.snake) return;
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
