import 'dart:math' as math;
import 'dart:ui';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import '../../data/constants.dart';
import '../game_world.dart';
import '../systems/audio_system.dart';
import 'player.dart';

enum PowerUpType {
  rapidFire,
  spreadShot,
  shield,
  magnet,
  timeSlow,
  overdrive,
  smartBomb,
  scoreMultiplier,
  extraLife,
}

/// Rarità dei power-up: influenza probabilità di spawn e visual
enum PowerUpRarity {
  common,   // bordo singolo, spawna spesso
  rare,     // bordo doppio + glow, spawna meno
  epic,     // bordo triplo + particelle, spawna raramente
  legendary, // aura dorata + pulsazione forte, estremamente raro
}

class PowerUpRarityConfig {
  final PowerUpType type;
  final PowerUpRarity rarity;
  final double weight; // peso relativo per spawn

  const PowerUpRarityConfig(this.type, this.rarity, this.weight);

  static const List<PowerUpRarityConfig> configs = [
    // Common (peso alto — frequenti)
    PowerUpRarityConfig(PowerUpType.rapidFire, PowerUpRarity.common, 20),
    PowerUpRarityConfig(PowerUpType.magnet, PowerUpRarity.common, 20),
    PowerUpRarityConfig(PowerUpType.scoreMultiplier, PowerUpRarity.common, 18),
    // Rare
    PowerUpRarityConfig(PowerUpType.spreadShot, PowerUpRarity.rare, 14),
    PowerUpRarityConfig(PowerUpType.smartBomb, PowerUpRarity.rare, 12),
    // Epic
    PowerUpRarityConfig(PowerUpType.shield, PowerUpRarity.epic, 8),
    PowerUpRarityConfig(PowerUpType.timeSlow, PowerUpRarity.epic, 8),
    PowerUpRarityConfig(PowerUpType.overdrive, PowerUpRarity.epic, 6),
    // Legendary
    PowerUpRarityConfig(PowerUpType.extraLife, PowerUpRarity.legendary, 2),
  ];

  /// Total weight for weighted random
  static final double _totalWeight = configs.fold(0, (s, c) => s + c.weight);

  /// Seleziona un power-up casuale pesato per rarità
  static PowerUpType rollWeighted(math.Random rng) {
    double roll = rng.nextDouble() * _totalWeight;
    for (final config in configs) {
      roll -= config.weight;
      if (roll <= 0) return config.type;
    }
    return configs.last.type;
  }

  static PowerUpRarity rarityOf(PowerUpType type) {
    return configs.firstWhere((c) => c.type == type).rarity;
  }
}

class PowerUp extends PositionComponent
    with HasGameReference<GeometryFightGame>, CollisionCallbacks {
  final PowerUpType type;
  late final PowerUpRarity rarity;
  double _lifetime = 10.0;
  double _phase = 0;
  double _pulsePhase = 0;

  PowerUp({required this.type})
      : super(size: Vector2(24, 24), anchor: Anchor.center) {
    rarity = PowerUpRarityConfig.rarityOf(type);
  }

  Color get color {
    switch (type) {
      case PowerUpType.rapidFire:
        return const Color(0xFFFF4400);
      case PowerUpType.spreadShot:
        return NeonColors.spreadOrange;
      case PowerUpType.shield:
        return NeonColors.cyan;
      case PowerUpType.magnet:
        return const Color(0xFFFFEE00);
      case PowerUpType.timeSlow:
        return const Color(0xFFAA00FF);
      case PowerUpType.overdrive:
        return NeonColors.white;
      case PowerUpType.smartBomb:
        return NeonColors.green;
      case PowerUpType.scoreMultiplier:
        return NeonColors.gold;
      case PowerUpType.extraLife:
        return const Color(0xFFFF4466);
    }
  }

  @override
  Future<void> onLoad() async {
    add(CircleHitbox(radius: 15, anchor: Anchor.center)
      ..position = size / 2);
  }

  @override
  void update(double dt) {
    super.update(dt);
    // Usa dt reale per lifetime (non affetto da slow-mo)
    final realDt = game.timeScale > 0.01 ? dt / game.timeScale : dt;
    _phase += dt * 3;
    _pulsePhase += dt * 6;
    _lifetime -= realDt;
    if (_lifetime <= 0) {
      removeFromParent();
      return;
    }
    // Tunnel mode: despawn power-up dietro la camera
    if (game.isTunnelMode) {
      final cameraLeft = game.camera.viewfinder.position.x - (game.size.x > 0 ? game.size.x / 2 : 400) - 100;
      if (position.x < cameraLeft) {
        removeFromParent();
        return;
      }
    }

    // Attrazione verso il player (come i geomi, raggio 120px)
    final player = game.player;
    final dist = position.distanceTo(player.position);
    if (dist < 120) {
      final dir = (player.position - position);
      if (dir.length > 0) {
        dir.normalize();
        final attractSpeed = 300.0 + (1.0 - dist / 120) * 200;
        position += dir * attractSpeed * dt;
      }
    }
  }

  void applyTo(Player player) {
    switch (type) {
      case PowerUpType.rapidFire:
        player.rapidFireTimer = powerUpDuration;
      case PowerUpType.spreadShot:
        player.temporaryWeapon = WeaponType.spread;
        player.weaponTimer = powerUpDuration;
      case PowerUpType.shield:
        // Scudo salvavita: dura 60s, assorbe 1 colpo
        player.applyShield(1, duration: 60.0);
      case PowerUpType.magnet:
        player.magnetTimer = powerUpDuration;
      case PowerUpType.timeSlow:
        player.timeSlowTimer = powerUpDuration;
        player.game.timeScale = 0.4;
      case PowerUpType.overdrive:
        player.overdriveTimer = powerUpDuration;
      case PowerUpType.smartBomb:
        if (player.bombs < player.game.saveData.bombCapacity) {
          player.bombs++;
        }
      case PowerUpType.scoreMultiplier:
        player.game.scoreSystem.addGeoms(10);
      case PowerUpType.extraLife:
        player.lives++;
        AudioSystem.playExtraLife();
    }
  }

  @override
  void render(Canvas canvas) {
    final alpha = _lifetime < 2 ? _lifetime / 2 : 1.0;
    final pulse = 1.0 + math.sin(_pulsePhase) * 0.15;
    final cx = size.x / 2;
    final cy = size.y / 2;

    // === RARITY VISUALS ===
    switch (rarity) {
      case PowerUpRarity.legendary:
        // Aura dorata grande pulsante
        final legendPulse = 1.0 + math.sin(_pulsePhase * 1.5) * 0.3;
        final auraPaint = Paint()
          ..color = const Color(0xFFFFD700).withValues(alpha: alpha * 0.25)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);
        canvas.drawCircle(Offset(cx, cy), 22 * legendPulse, auraPaint);
        // Anello esterno dorato
        final ringPaint = Paint()
          ..color = const Color(0xFFFFD700).withValues(alpha: alpha * 0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5;
        canvas.drawCircle(Offset(cx, cy), 18 * legendPulse, ringPaint);
      case PowerUpRarity.epic:
        // Particelle orbitanti
        for (int i = 0; i < 4; i++) {
          final angle = _phase * 2 + i * math.pi / 2;
          final px = cx + math.cos(angle) * 16;
          final py = cy + math.sin(angle) * 16;
          final pPaint = Paint()
            ..color = color.withValues(alpha: alpha * 0.5)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
          canvas.drawCircle(Offset(px, py), 1.5, pPaint);
        }
        // Glow forte
        final epicGlow = Paint()
          ..color = color.withValues(alpha: alpha * 0.5)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16);
        canvas.drawCircle(Offset(cx, cy), 18 * pulse, epicGlow);
      case PowerUpRarity.rare:
        // Doppio anello glow
        final rareGlow = Paint()
          ..color = color.withValues(alpha: alpha * 0.35)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14);
        canvas.drawCircle(Offset(cx, cy), 17 * pulse, rareGlow);
      case PowerUpRarity.common:
        break; // Solo glow base
    }

    // Glow base (tutti)
    final glowPaint = Paint()
      ..color = color.withValues(alpha: alpha * 0.4)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawCircle(Offset(cx, cy), 16 * pulse, glowPaint);

    // Shape (rotating hexagon)
    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(_phase);

    final paint = Paint()..color = color.withValues(alpha: alpha);
    final path = Path();
    for (int i = 0; i < 6; i++) {
      final angle = i * math.pi / 3;
      final r = 10 * pulse;
      final x = r * math.cos(angle);
      final y = r * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);

    // Bordo based on rarity
    if (rarity != PowerUpRarity.common) {
      final borderPaint = Paint()
        ..color = (rarity == PowerUpRarity.legendary
            ? const Color(0xFFFFD700)
            : color).withValues(alpha: alpha * 0.7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = rarity == PowerUpRarity.legendary ? 1.5 : 1.0;
      canvas.drawPath(path, borderPaint);
    }

    // Inner icon (cuore per extraLife, cerchio per il resto)
    if (type == PowerUpType.extraLife) {
      paint.color = const Color(0xFFFFFFFF).withValues(alpha: alpha * 0.9);
      // Cuoricino semplificato
      final heartPath = Path()
        ..moveTo(0, 2)
        ..cubicTo(-4, -2, -4, -5, 0, -3)
        ..cubicTo(4, -5, 4, -2, 0, 2);
      canvas.drawPath(heartPath, paint);
    } else {
      paint.color = const Color(0xFFFFFFFF).withValues(alpha: alpha * 0.8);
      canvas.drawCircle(Offset.zero, 3, paint);
    }

    canvas.restore();
  }

  @override
  void onCollisionStart(
      Set<Vector2> intersectionPoints, PositionComponent other) {
    if (other is Player) {
      applyTo(other);
      removeFromParent();
    }
    super.onCollisionStart(intersectionPoints, other);
  }
}
