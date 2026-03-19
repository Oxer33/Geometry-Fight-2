import 'dart:math' as math;
import 'dart:ui';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/painting.dart' show HSVColor;
import '../../data/constants.dart';
import '../game_world.dart';
import 'enemies/enemy_base.dart';
import 'bosses/boss_base.dart';
import 'player.dart';

class PlayerBullet extends PositionComponent
    with HasGameReference<GeometryFightGame>, CollisionCallbacks {
  final Vector2 direction;
  final double speed;
  final double damage;
  final Color color;
  final int maxBounces;
  final bool pierce;

  // _bounces mantenuto per compatibilità con maxBounces parameter
  double _lifetime = bulletLifetime;
  late Vector2 _velocity;

  // Trail
  final List<Vector2> _trail = [];
  static const int _maxTrailLength = 8;

  PlayerBullet({
    required this.direction,
    this.speed = bulletSpeed,
    this.damage = 1,
    this.color = NeonColors.bulletYellow,
    this.maxBounces = 2,
    this.pierce = false,
  }) : super(size: Vector2(6, 6), anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    _velocity = direction.normalized() * speed;
    // Hitbox circolare per proiettili rotondi
    add(CircleHitbox(radius: 3, anchor: Anchor.center)
      ..position = size / 2);
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Store trail position
    _trail.insert(0, position.clone());
    if (_trail.length > _maxTrailLength) _trail.removeLast();

    position += _velocity * dt;

    // Distruggi quando esce dall'arena
    // Nel tunnel mode: NO limiti X (scroll infinito), solo Y + lifetime
    if (game.isTunnelMode) {
      if (position.y < -50 || position.y > arenaHeight + 50) {
        removeFromParent();
        return;
      }
      // Nel tunnel distruggi solo se troppo lontano dal player (>1500px)
      if ((position - game.player.position).length > 1500) {
        removeFromParent();
        return;
      }
    } else {
      if (position.x < -20 || position.x > arenaWidth + 20 ||
          position.y < -20 || position.y > arenaHeight + 20) {
        removeFromParent();
        return;
      }
    }

    _lifetime -= dt;
    if (_lifetime <= 0) removeFromParent();
  }

  // Paint cache statici per evitare allocazioni ogni frame
  // (con 50+ proiettili × 60fps = migliaia di allocazioni risparmiate)
  static final _trailPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
  static final _glowPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
  static final _bodyPaint = Paint();
  static final _corePaint = Paint()
    ..color = const Color(0xFFFFFFFF).withValues(alpha: 0.7);

  @override
  void render(Canvas canvas) {
    final cx = size.x / 2;
    final cy = size.y / 2;

    // Trail (scia luminosa - solo ultimi 4 punti per performance)
    final trailLen = _trail.length.clamp(0, 4);
    for (int i = 0; i < trailLen; i++) {
      final alpha = 1.0 - (i / 4);
      _trailPaint.color = color.withValues(alpha: alpha * 0.3);
      final offset = _trail[i] - position;
      canvas.drawCircle(
        Offset(cx + offset.x, cy + offset.y), 1.5, _trailPaint,
      );
    }

    // Glow esterno
    _glowPaint.color = color.withValues(alpha: 0.35);
    canvas.drawCircle(Offset(cx, cy), 4, _glowPaint);

    // Proiettile principale (cerchio pieno)
    _bodyPaint.color = color;
    canvas.drawCircle(Offset(cx, cy), 3, _bodyPaint);

    // Centro luminoso bianco
    canvas.drawCircle(Offset(cx, cy), 1.2, _corePaint);
  }

  @override
  void onCollisionStart(
      Set<Vector2> intersectionPoints, PositionComponent other) {
    if (other is EnemyBase) {
      other.takeDamage(damage);
      // Mini esplosione pixel luminosi al contatto
      game.spawnExplosion(position, color, radius: 8, particleCount: 4);
      if (!pierce) {
        removeFromParent();
      }
    }
    if (other is BossBase) {
      other.takeDamage(damage);
      game.spawnExplosion(position, color, radius: 10, particleCount: 5);
      if (!pierce) {
        removeFromParent();
      }
    }
    super.onCollisionStart(intersectionPoints, other);
  }
}

class EnemyBullet extends PositionComponent
    with HasGameReference<GeometryFightGame>, CollisionCallbacks {
  final Vector2 direction;
  final double speed;
  final Color color;

  late Vector2 _velocity;
  double _lifetime = 4.0;

  EnemyBullet({
    required this.direction,
    this.speed = 300,
    this.color = NeonColors.red,
  }) : super(size: Vector2(18, 18), anchor: Anchor.center); // 3x più grandi

  @override
  Future<void> onLoad() async {
    _velocity = direction.normalized() * speed;
    add(CircleHitbox(radius: 9, anchor: Anchor.center)
      ..position = size / 2);
  }

  @override
  void update(double dt) {
    super.update(dt);
    position += _velocity * dt;

    _lifetime -= dt;
    // Nel tunnel mode: NO limiti X, solo lifetime e distanza dal player
    if (game.isTunnelMode) {
      if (_lifetime <= 0 || position.y < -50 || position.y > arenaHeight + 50) {
        removeFromParent();
      }
      if ((position - game.player.position).length > 1200) {
        removeFromParent();
      }
    } else {
      if (_lifetime <= 0 ||
          position.x < -50 ||
          position.x > arenaWidth + 50 ||
          position.y < -50 ||
          position.y > arenaHeight + 50) {
        removeFromParent();
      }
    }
  }

  @override
  void render(Canvas canvas) {
    final cx = size.x / 2;
    final cy = size.y / 2;
    // Glow esterno (proporzionato al size 18x18)
    final glowPaint = Paint()
      ..color = color.withValues(alpha: 0.4)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawCircle(Offset(cx, cy), 8, glowPaint);
    // Corpo principale
    final paint = Paint()..color = color;
    canvas.drawCircle(Offset(cx, cy), 6, paint);
    // Centro luminoso
    final corePaint = Paint()
      ..color = const Color(0xFFFFFFFF).withValues(alpha: 0.6);
    canvas.drawCircle(Offset(cx, cy), 3, corePaint);
  }

  @override
  void onCollisionStart(
      Set<Vector2> intersectionPoints, PositionComponent other) {
    if (other is Player) {
      other.takeDamage();
      removeFromParent();
    }
    super.onCollisionStart(intersectionPoints, other);
  }
}

class LaserBeam extends PositionComponent
    with HasGameReference<GeometryFightGame> {
  final Vector2 direction;
  final double damage;
  double _lifetime = 0.1;

  LaserBeam({required this.direction, this.damage = 1})
      : super(size: Vector2(3, 800), anchor: Anchor.topCenter);

  @override
  void update(double dt) {
    super.update(dt);
    _lifetime -= dt;
    if (_lifetime <= 0) removeFromParent();

    // Damage enemies AND bosses along the beam
    final dir = direction.normalized();
    for (final child in game.world.children) {
      if (child is EnemyBase) {
        final toEnemy = child.position - position;
        final dot = toEnemy.dot(dir);
        if (dot > 0 && dot < 800) {
          final perpDist = (toEnemy - dir * dot).length;
          if (perpDist < 20) {
            child.takeDamage(damage * dt * 60);
          }
        }
      }
      if (child is BossBase) {
        final toBoss = child.position - position;
        final dot = toBoss.dot(dir);
        if (dot > 0 && dot < 800) {
          final perpDist = (toBoss - dir * dot).length;
          if (perpDist < 30) {
            child.takeDamage(damage * dt * 60);
          }
        }
      }
    }
  }

  @override
  void render(Canvas canvas) {
    final angle = math.atan2(direction.y, direction.x) - math.pi / 2;
    canvas.save();
    canvas.translate(size.x / 2, 0);
    canvas.rotate(angle);

    // Glow
    final glowPaint = Paint()
      ..color = NeonColors.laserRed.withValues(alpha: 0.4)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: 12, height: 800), glowPaint);

    // Core
    final paint = Paint()..color = NeonColors.laserRed;
    canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: 3, height: 800), paint);

    canvas.restore();
  }
}

class PlasmaBullet extends PositionComponent
    with HasGameReference<GeometryFightGame>, CollisionCallbacks {
  final Vector2 direction;
  final double damage;

  late Vector2 _velocity;
  double _phase = 0;

  PlasmaBullet({required this.direction, this.damage = 3})
      : super(size: Vector2(20, 20), anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    _velocity = direction.normalized() * 350;
    add(CircleHitbox());
  }

  @override
  void update(double dt) {
    super.update(dt);
    position += _velocity * dt;
    _phase += dt * 10;

    // Nel tunnel mode: NO limiti X, solo Y + distanza dal player
    if (game.isTunnelMode) {
      if (position.y < -50 || position.y > arenaHeight + 50 ||
          (position - game.player.position).length > 1500) {
        removeFromParent();
      }
    } else {
      if (position.x < -50 || position.x > arenaWidth + 50 ||
          position.y < -50 || position.y > arenaHeight + 50) {
        removeFromParent();
      }
    }
  }

  @override
  void render(Canvas canvas) {
    final radius = 10 + math.sin(_phase) * 2;
    final paint = Paint()
      ..color = NeonColors.plasmaViolet.withValues(alpha: 0.4)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawCircle(Offset(size.x / 2, size.y / 2), radius * 1.5, paint);

    paint
      ..color = NeonColors.plasmaViolet
      ..maskFilter = null;
    canvas.drawCircle(Offset(size.x / 2, size.y / 2), radius, paint);
  }

  void _explode() {
    // Damage all enemies AND bosses in radius
    for (final child in game.world.children) {
      if (child is EnemyBase) {
        final dist = child.position.distanceTo(position);
        if (dist < 80) {
          child.takeDamage(damage);
        }
      }
      if (child is BossBase) {
        final dist = child.position.distanceTo(position);
        if (dist < 80) {
          child.takeDamage(damage);
        }
      }
    }
    game.spawnExplosion(position, NeonColors.plasmaViolet, radius: 80);
  }

  @override
  void onCollisionStart(
      Set<Vector2> intersectionPoints, PositionComponent other) {
    if (other is EnemyBase || other is BossBase) {
      _explode();
      removeFromParent();
    }
    super.onCollisionStart(intersectionPoints, other);
  }
}

class HomingMissile extends PositionComponent
    with HasGameReference<GeometryFightGame>, CollisionCallbacks {
  final Vector2 direction;
  final double damage;

  late Vector2 _velocity;
  double _lifetime = 3.0;

  HomingMissile({required this.direction, this.damage = 1.5})
      : super(size: Vector2(8, 12), anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    _velocity = direction.normalized() * 500;
    add(RectangleHitbox());
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Find nearest enemy or boss
    PositionComponent? nearest;
    double nearestDist = double.infinity;
    for (final child in game.world.children) {
      if (child is EnemyBase) {
        final dist = child.position.distanceTo(position);
        if (dist < nearestDist) {
          nearestDist = dist;
          nearest = child;
        }
      }
      if (child is BossBase) {
        final dist = child.position.distanceTo(position);
        if (dist < nearestDist) {
          nearestDist = dist;
          nearest = child;
        }
      }
    }

    // Steering
    if (nearest != null) {
      final desired = (nearest.position - position).normalized() * 500;
      final steering = (desired - _velocity)..clampLength(0, 800 * dt);
      _velocity += steering;
      if (_velocity.length > 500) {
        _velocity = _velocity.normalized() * 500;
      }
    }

    position += _velocity * dt;
    _lifetime -= dt;
    if (_lifetime <= 0) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final paint = Paint()
      ..color = NeonColors.cyan
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawRect(
      Rect.fromCenter(
          center: Offset(size.x / 2, size.y / 2),
          width: size.x,
          height: size.y),
      paint,
    );

    // Red trail
    paint.color = NeonColors.red.withValues(alpha: 0.5);
    canvas.drawCircle(Offset(size.x / 2, size.y + 4), 3, paint);
  }

  @override
  void onCollisionStart(
      Set<Vector2> intersectionPoints, PositionComponent other) {
    if (other is EnemyBase) {
      other.takeDamage(damage);
      game.spawnExplosion(position, NeonColors.cyan, radius: 20, particleCount: 8);
      removeFromParent();
    }
    if (other is BossBase) {
      other.takeDamage(damage);
      game.spawnExplosion(position, NeonColors.cyan, radius: 20, particleCount: 8);
      removeFromParent();
    }
    super.onCollisionStart(intersectionPoints, other);
  }
}

class OverdriveBeam extends PositionComponent
    with HasGameReference<GeometryFightGame> {
  final Vector2 direction;
  double _lifetime = 3.0;
  double _phase = 0;

  OverdriveBeam({required this.direction})
      : super(size: Vector2(40, 1200), anchor: Anchor.topCenter);

  @override
  void update(double dt) {
    super.update(dt);
    _lifetime -= dt;
    _phase += dt * 20;
    if (_lifetime <= 0) removeFromParent();

    // Kill everything in path (enemies AND bosses)
    final dir = direction.normalized();
    for (final child in game.world.children.toList()) {
      if (child is EnemyBase) {
        final toEnemy = child.position - position;
        final dot = toEnemy.dot(dir);
        if (dot > 0 && dot < 1200) {
          final perpDist = (toEnemy - dir * dot).length;
          if (perpDist < 30) {
            child.takeDamage(999);
          }
        }
      }
      if (child is BossBase) {
        final toBoss = child.position - position;
        final dot = toBoss.dot(dir);
        if (dot > 0 && dot < 1200) {
          final perpDist = (toBoss - dir * dot).length;
          if (perpDist < 30) {
            child.takeDamage(10); // Danno boss dall'overdrive
          }
        }
      }
      if (child is EnemyBullet) {
        final toB = child.position - position;
        final dot = toB.dot(dir);
        if (dot > 0 && dot < 1200) {
          final perpDist = (toB - dir * dot).length;
          if (perpDist < 30) {
            child.removeFromParent();
          }
        }
      }
    }
  }

  @override
  void render(Canvas canvas) {
    final angle = math.atan2(direction.y, direction.x) - math.pi / 2;
    canvas.save();
    canvas.translate(size.x / 2, 0);
    canvas.rotate(angle);

    // Rainbow effect
    final hue = (_phase * 30) % 360;
    final rainbowColor =
        HSVColor.fromAHSV(1.0, hue, 1.0, 1.0).toColor();

    // Glow
    final glowPaint = Paint()
      ..color = rainbowColor.withValues(alpha: 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);
    canvas.drawRect(
        Rect.fromCenter(center: Offset.zero, width: 60, height: 1200), glowPaint);

    // Core - white
    final paint = Paint()..color = const Color(0xFFFFFFFF);
    canvas.drawRect(
        Rect.fromCenter(center: Offset.zero, width: 20, height: 1200), paint);

    // Colored edge
    paint.color = rainbowColor;
    canvas.drawRect(
        Rect.fromCenter(center: Offset.zero, width: 40, height: 1200), paint..color = rainbowColor.withValues(alpha: 0.5));

    canvas.restore();
  }
}
