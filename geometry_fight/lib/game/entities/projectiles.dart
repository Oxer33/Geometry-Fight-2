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

  int _bounces = 0;
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
    // Proiettili player NON affetti dal slow-motion: compensano il timeScale
    final realDt = game.timeScale > 0.01 ? dt / game.timeScale : dt;
    super.update(realDt);

    // Store trail position
    _trail.insert(0, position.clone());
    if (_trail.length > _maxTrailLength) _trail.removeLast();

    position += _velocity * realDt;

    // Distruggi / rimbalza quando tocca un muro
    if (game.isTunnelMode) {
      // Tunnel: distruggi se tocca i muri sinusoidali o va dietro la camera
      final cameraLeft = game.camera.viewfinder.position.x - (game.size.x > 0 ? game.size.x / 2 : 400) - 200;
      if (position.x < cameraLeft) {
        removeFromParent();
        return;
      }
      final (topWall, bottomWall) = game.tunnelWallsAtX(position.x);
      if (position.y <= topWall || position.y >= bottomWall) {
        removeFromParent();
        return;
      }
    } else {
      // Arena normale: rimbalza (ricochet) o distruggi esattamente al bordo
      bool destroyed = false;
      if (position.x <= 0) {
        position.x = 0;
        if (maxBounces > 0 && _bounces < maxBounces) { _velocity.x = _velocity.x.abs(); _bounces++; }
        else { destroyed = true; }
      } else if (position.x >= arenaWidth) {
        position.x = arenaWidth;
        if (maxBounces > 0 && _bounces < maxBounces) { _velocity.x = -_velocity.x.abs(); _bounces++; }
        else { destroyed = true; }
      }
      if (!destroyed) {
        if (position.y <= 0) {
          position.y = 0;
          if (maxBounces > 0 && _bounces < maxBounces) { _velocity.y = _velocity.y.abs(); _bounces++; }
          else { destroyed = true; }
        } else if (position.y >= arenaHeight) {
          position.y = arenaHeight;
          if (maxBounces > 0 && _bounces < maxBounces) { _velocity.y = -_velocity.y.abs(); _bounces++; }
          else { destroyed = true; }
        }
      }
      if (destroyed) { removeFromParent(); return; }
    }

    _lifetime -= realDt;
    if (_lifetime <= 0) removeFromParent();
  }

  // Paint cache statici per evitare allocazioni ogni frame
  // (con 50+ proiettili × 60fps = migliaia di allocazioni risparmiate)
  static final _trailPaint = Paint();
  static final _glowPaint = Paint();
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
      // GW:RE2: proiettili passano ATTRAVERSO nemici in fase di materializzazione
      if (other.isSpawnInvulnerable) return;

      other.takeDamage(damage);
      // Mini esplosione pixel luminosi al contatto
      game.spawnExplosion(position, color, radius: 8, particleCount: 4);

      // GW:RE2 Fear mechanic: nemici vicini si spaventano quando un proiettile colpisce
      _applyFearToNearby();

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

  /// GW:RE2 Fear: quando un proiettile colpisce, solo i nemici "fear-dodge"
  /// (attualmente i Weaver verdi) possono fare una micro-schivata.
  /// Max 5 nemici spaventati per impatto per limitare il costo O(n).
  void _applyFearToNearby() {
    const fearRadius = 80.0;
    int fearCount = 0;
    for (final child in game.world.children) {
      if (fearCount >= 5) break; // Limita a 5 per performance
      if (child is EnemyBase && child.canFearDodge) {
        final dist = child.position.distanceTo(position);
        if (dist < fearRadius && dist > 5) {
          child.applyFear(position);
          fearCount++;
        }
      }
    }
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
    if (_lifetime <= 0) { removeFromParent(); return; }

    if (game.isTunnelMode) {
      // Tunnel: distruggi se tocca i muri dinamici o va fuori range
      final (topWall, bottomWall) = game.tunnelWallsAtX(position.x);
      if (position.y <= topWall || position.y >= bottomWall ||
          (position - game.player.position).length > 1200) {
        removeFromParent();
      }
    } else {
      // Arena: distruggi esattamente al bordo (nessuna penetrazione)
      if (position.x < 0 || position.x > arenaWidth ||
          position.y < 0 || position.y > arenaHeight) {
        removeFromParent();
      }
    }
  }

  // Paint cache statico — evita 50+ allocazioni/frame con molti proiettili nemici
  static final _ebGlowPaint = Paint();
  static final _ebBodyPaint = Paint();
  static final _ebCorePaint = Paint()..color = const Color(0xFFFFFFFF).withValues(alpha: 0.6);

  @override
  void render(Canvas canvas) {
    final cx = size.x / 2;
    final cy = size.y / 2;
    // Glow esterno (SENZA blur per performance — con 50 proiettili = 50 blur)
    _ebGlowPaint.color = color.withValues(alpha: 0.3);
    _ebGlowPaint.maskFilter = null;
    canvas.drawCircle(Offset(cx, cy), 8, _ebGlowPaint);
    // Corpo principale
    _ebBodyPaint.color = color;
    canvas.drawCircle(Offset(cx, cy), 6, _ebBodyPaint);
    // Centro luminoso
    canvas.drawCircle(Offset(cx, cy), 3, _ebCorePaint);
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

  static final _laserGlowPaint = Paint()
    ..color = NeonColors.laserRed.withValues(alpha: 0.4);
  static final _laserCorePaint = Paint()..color = NeonColors.laserRed;

  @override
  void render(Canvas canvas) {
    final angle = math.atan2(direction.y, direction.x) - math.pi / 2;
    canvas.save();
    canvas.translate(size.x / 2, 0);
    canvas.rotate(angle);

    // Glow (no blur — troppo costoso con beam attivi)
    canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: 12, height: 800), _laserGlowPaint);
    // Core
    canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: 3, height: 800), _laserCorePaint);

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

    if (game.isTunnelMode) {
      final cameraLeft = game.camera.viewfinder.position.x - (game.size.x > 0 ? game.size.x / 2 : 400) - 200;
      final (topWall, bottomWall) = game.tunnelWallsAtX(position.x);
      if (position.x < cameraLeft || position.y <= topWall || position.y >= bottomWall ||
          (position - game.player.position).length > 1200) {
        removeFromParent();
      }
    } else {
      // Arena: distruggi al bordo esatto
      if (position.x < 0 || position.x > arenaWidth ||
          position.y < 0 || position.y > arenaHeight) {
        removeFromParent();
      }
    }
  }

  static final _plasmaGlowPaint = Paint();
  static final _plasmaBodyPaint = Paint();

  @override
  void render(Canvas canvas) {
    final radius = 10 + math.sin(_phase) * 2;
    final center = Offset(size.x / 2, size.y / 2);
    // Glow (no blur per performance)
    _plasmaGlowPaint.color = NeonColors.plasmaViolet.withValues(alpha: 0.4);
    canvas.drawCircle(center, radius * 1.5, _plasmaGlowPaint);
    // Core
    _plasmaBodyPaint.color = NeonColors.plasmaViolet;
    canvas.drawCircle(center, radius, _plasmaBodyPaint);
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
    // Passa attraverso nemici in materializzazione
    if (other is EnemyBase && other.isSpawnInvulnerable) return;
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
  PositionComponent? _cachedTarget;
  int _searchCooldown = 0;

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

    // Find nearest enemy or boss (throttled: every 5 frames)
    _searchCooldown--;
    if (_searchCooldown <= 0 || _cachedTarget == null || _cachedTarget!.isRemoved) {
      _searchCooldown = 5;
      _cachedTarget = null;
      double nearestDist = double.infinity;
      for (final child in game.world.children) {
        if (child is EnemyBase) {
          final dist = child.position.distanceTo(position);
          if (dist < nearestDist) {
            nearestDist = dist;
            _cachedTarget = child;
          }
        } else if (child is BossBase) {
          final dist = child.position.distanceTo(position);
          if (dist < nearestDist) {
            nearestDist = dist;
            _cachedTarget = child;
          }
        }
      }
    }

    // Steering
    if (_cachedTarget != null && !_cachedTarget!.isRemoved) {
      final desired = (_cachedTarget!.position - position).normalized() * 500;
      final steering = (desired - _velocity)..clampLength(0, 800 * dt);
      _velocity += steering;
      if (_velocity.length > 500) {
        _velocity = _velocity.normalized() * 500;
      }
    }

    position += _velocity * dt;
    _lifetime -= dt;
    if (_lifetime <= 0) { removeFromParent(); return; }
  }

  static final _homingBodyPaint = Paint();
  static final _homingTrailPaint = Paint();

  @override
  void render(Canvas canvas) {
    final center = Offset(size.x / 2, size.y / 2);
    _homingBodyPaint.color = NeonColors.cyan;
    canvas.drawRect(
      Rect.fromCenter(center: center, width: size.x, height: size.y),
      _homingBodyPaint,
    );
    // Red trail (no blur)
    _homingTrailPaint.color = NeonColors.red.withValues(alpha: 0.5);
    canvas.drawCircle(Offset(size.x / 2, size.y + 4), 3, _homingTrailPaint);
  }

  @override
  void onCollisionStart(
      Set<Vector2> intersectionPoints, PositionComponent other) {
    if (other is EnemyBase) {
      // Passa attraverso nemici in materializzazione
      if (other.isSpawnInvulnerable) return;
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
    final toRemove = <EnemyBullet>[];
    for (final child in game.world.children) {
      if (child is EnemyBase) {
        final toEnemy = child.position - position;
        final dot = toEnemy.dot(dir);
        if (dot > 0 && dot < 1200) {
          final perpDist = (toEnemy - dir * dot).length;
          if (perpDist < 30) {
            child.takeDamage(999);
          }
        }
      } else if (child is BossBase) {
        final toBoss = child.position - position;
        final dot = toBoss.dot(dir);
        if (dot > 0 && dot < 1200) {
          final perpDist = (toBoss - dir * dot).length;
          if (perpDist < 30) {
            child.takeDamage(10); // Danno boss dall'overdrive
          }
        }
      } else if (child is EnemyBullet) {
        final toB = child.position - position;
        final dot = toB.dot(dir);
        if (dot > 0 && dot < 1200) {
          final perpDist = (toB - dir * dot).length;
          if (perpDist < 30) {
            toRemove.add(child);
          }
        }
      }
    }
    for (final b in toRemove) {
      b.removeFromParent();
    }
  }

  static final _odGlowPaint = Paint();
  static final _odCorePaint = Paint();
  static final _odEdgePaint = Paint();

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

    // Glow (no blur — overdrive is rare but still saves GPU)
    _odGlowPaint.color = rainbowColor.withValues(alpha: 0.3);
    canvas.drawRect(
        Rect.fromCenter(center: Offset.zero, width: 60, height: 1200), _odGlowPaint);

    // Core - white
    _odCorePaint.color = const Color(0xFFFFFFFF);
    canvas.drawRect(
        Rect.fromCenter(center: Offset.zero, width: 20, height: 1200), _odCorePaint);

    // Colored edge
    _odEdgePaint.color = rainbowColor.withValues(alpha: 0.5);
    canvas.drawRect(
        Rect.fromCenter(center: Offset.zero, width: 40, height: 1200), _odEdgePaint);

    canvas.restore();
  }
}
