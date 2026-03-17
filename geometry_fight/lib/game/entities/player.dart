import 'dart:math' as math;
import 'dart:ui';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import '../../data/constants.dart';
import '../game_world.dart';
import '../effects/explosion.dart';
import 'enemies/enemy_base.dart';
import 'projectiles.dart';

enum WeaponType {
  basic,
  spread,
  laser,
  plasma,
  ricochet,
  homing,
  twin,
  overdrive,
}

class Player extends PositionComponent with HasGameReference<GeometryFightGame>, CollisionCallbacks {
  int lives = playerStartLives;
  int bombs = playerStartBombs;
  double speed = playerSpeed;
  WeaponType currentWeapon = WeaponType.basic;
  WeaponType? temporaryWeapon;
  double weaponTimer = 0;

  double _fireTimer = 0;
  double _invincibleTimer = 0;
  bool get isInvincible => _invincibleTimer > 0;

  // Shield
  int shieldHits = 0;
  bool hasShield = false;

  // Power-up states
  double rapidFireTimer = 0;
  double overdriveTimer = 0;
  double magnetTimer = 0;
  double timeSlowTimer = 0;
  bool get hasRapidFire => rapidFireTimer > 0;
  bool get hasOverdrive => overdriveTimer > 0;
  bool get hasMagnet => magnetTimer > 0;

  // Visual
  double _thrusterPhase = 0;
  double _rotation = 0;

  Player() : super(size: Vector2(24, 28), anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    add(CircleHitbox(radius: playerHurtboxRadius, anchor: Anchor.center)
      ..position = size / 2);
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Movement
    final moveDir = game.moveInput;
    if (moveDir.length > 0) {
      final actualSpeed = speed * (hasOverdrive ? 1.5 : 1.0) *
          game.saveData.speedMultiplier;
      position += moveDir * actualSpeed * dt;
    }

    // Clamp to arena
    position.x = position.x.clamp(15, arenaWidth - 15);
    position.y = position.y.clamp(15, arenaHeight - 15);

    // Aim direction
    final aimDir = game.aimInput;
    if (aimDir.length > 0) {
      _rotation = math.atan2(aimDir.y, aimDir.x) + math.pi / 2;
    }

    // Shooting
    _fireTimer -= dt;
    if ((game.isShooting || aimDir.length > 0.3) && _fireTimer <= 0) {
      _shoot(aimDir.length > 0.3 ? aimDir : Vector2(0, -1));
    }

    // Timers
    if (_invincibleTimer > 0) _invincibleTimer -= dt;
    if (rapidFireTimer > 0) rapidFireTimer -= dt;
    if (overdriveTimer > 0) overdriveTimer -= dt;
    if (magnetTimer > 0) magnetTimer -= dt;
    if (timeSlowTimer > 0) {
      timeSlowTimer -= dt;
      if (timeSlowTimer <= 0) {
        game.timeScale = 1.0;
      }
    }
    if (weaponTimer > 0) {
      weaponTimer -= dt;
      if (weaponTimer <= 0) {
        temporaryWeapon = null;
      }
    }

    // Bomb
    if (game.bombPressed) {
      game.bombPressed = false;
      game.useBomb();
    }

    // Magnet - attract geoms
    if (hasMagnet || game.saveData.magnetRange > 0) {
      _attractGeoms();
    }

    // Thruster animation
    _thrusterPhase += dt * 15;
  }

  void _shoot(Vector2 direction) {
    final weapon = temporaryWeapon ?? currentWeapon;
    final fireRateMultiplier = game.saveData.fireRateMultiplier *
        (hasRapidFire ? 2.5 : 1.0) *
        (hasOverdrive ? 2.0 : 1.0);

    double fireInterval = 1.0 / (baseFireRate * fireRateMultiplier);
    _fireTimer = fireInterval;

    final dir = direction.normalized();
    final damageMultiplier =
        game.saveData.damageMultiplier * (hasOverdrive ? 3.0 : 1.0);
    final pierce = hasOverdrive;

    switch (weapon) {
      case WeaponType.basic:
        _spawnBullet(dir, damageMultiplier, NeonColors.bulletYellow, pierce: pierce);
      case WeaponType.spread:
        for (final angle in [-0.52, -0.26, 0.0, 0.26, 0.52]) {
          final rotDir = _rotateVector(dir, angle);
          _spawnBullet(rotDir, damageMultiplier * 0.7, NeonColors.spreadOrange,
              speed: bulletSpeed * 1.2, pierce: pierce);
        }
      case WeaponType.laser:
        _spawnLaser(dir, damageMultiplier);
      case WeaponType.plasma:
        _spawnPlasma(dir, damageMultiplier);
        _fireTimer = 0.4; // Slower fire rate
      case WeaponType.ricochet:
        _spawnBullet(dir, damageMultiplier, NeonColors.ricochetGreen,
            maxBounces: 5, pierce: pierce);
      case WeaponType.homing:
        for (int i = 0; i < 3; i++) {
          final offset = _rotateVector(dir, (i - 1) * 0.2);
          _spawnHomingMissile(offset, damageMultiplier);
        }
        _fireTimer = 0.5;
      case WeaponType.twin:
        final perpendicular = Vector2(-dir.y, dir.x) * 12;
        _spawnBullet(dir, damageMultiplier, NeonColors.white,
            offset: perpendicular, pierce: pierce);
        _spawnBullet(dir, damageMultiplier, NeonColors.white,
            offset: -perpendicular, pierce: pierce);
        _fireTimer = fireInterval * 0.5;
      case WeaponType.overdrive:
        _spawnOverdriveBeam(dir);
        _fireTimer = 3.0;
    }
  }

  void _spawnBullet(Vector2 dir, double damage, Color color,
      {double speed = bulletSpeed,
      int maxBounces = maxBounces,
      Vector2? offset,
      bool pierce = false}) {
    final bullet = PlayerBullet(
      direction: dir,
      speed: speed,
      damage: damage,
      color: color,
      maxBounces: maxBounces,
      pierce: pierce,
    );
    bullet.position = position + (offset ?? Vector2.zero());
    game.world.add(bullet);
  }

  void _spawnLaser(Vector2 dir, double damage) {
    final laser = LaserBeam(direction: dir, damage: damage * 0.5);
    laser.position = position.clone();
    game.world.add(laser);
  }

  void _spawnPlasma(Vector2 dir, double damage) {
    final plasma = PlasmaBullet(direction: dir, damage: damage * 3);
    plasma.position = position.clone();
    game.world.add(plasma);
  }

  void _spawnHomingMissile(Vector2 dir, double damage) {
    final missile = HomingMissile(direction: dir, damage: damage * 1.5);
    missile.position = position.clone();
    game.world.add(missile);
  }

  void _spawnOverdriveBeam(Vector2 dir) {
    final beam = OverdriveBeam(direction: dir);
    beam.position = position.clone();
    game.world.add(beam);
  }

  Vector2 _rotateVector(Vector2 v, double angle) {
    final c = math.cos(angle);
    final s = math.sin(angle);
    return Vector2(v.x * c - v.y * s, v.x * s + v.y * c);
  }

  void _attractGeoms() {
    final range = hasMagnet ? magnetRadius : game.saveData.magnetRange;
    // Geom attraction is handled in Geom.update
  }

  void takeDamage() {
    if (isInvincible) return;

    if (hasShield) {
      shieldHits--;
      if (shieldHits <= 0) {
        hasShield = false;
      }
      game.spawnExplosion(position, NeonColors.cyan, radius: 30);
      return;
    }

    lives--;
    _invincibleTimer = playerInvincibilityDuration;
    game.onPlayerHit();

    if (lives <= 0) {
      game.onPlayerDeath();
    }
  }

  void applyShield(int hits) {
    hasShield = true;
    shieldHits = hits;
  }

  @override
  void render(Canvas canvas) {
    final paint = Paint();

    // Glow
    paint.color = NeonColors.cyan.withValues(alpha: 0.3);
    paint.maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    _drawTriangle(canvas, paint, 1.3);

    // Main body
    paint.maskFilter = null;
    paint.color = isInvincible
        ? ((_invincibleTimer * 10).toInt() % 2 == 0
            ? NeonColors.cyan
            : NeonColors.cyan.withValues(alpha: 0.3))
        : NeonColors.cyan;
    _drawTriangle(canvas, paint, 1.0);

    // Thruster
    final thrusterSize = 4 + math.sin(_thrusterPhase) * 2;
    paint.color = NeonColors.spreadOrange;
    paint.maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawCircle(
        Offset(size.x / 2, size.y - 2), thrusterSize, paint);

    // Shield
    if (hasShield) {
      paint.color = NeonColors.cyan.withValues(alpha: 0.3);
      paint.style = PaintingStyle.stroke;
      paint.strokeWidth = 2;
      paint.maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      _drawHexagon(canvas, paint, 22);
      paint.style = PaintingStyle.fill;
    }
  }

  void _drawTriangle(Canvas canvas, Paint paint, double scale) {
    final cx = size.x / 2;
    final cy = size.y / 2;
    final w = size.x / 2 * scale;
    final h = size.y / 2 * scale;

    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(_rotation);
    canvas.translate(-cx, -cy);

    final path = Path()
      ..moveTo(cx, cy - h)
      ..lineTo(cx - w, cy + h)
      ..lineTo(cx + w, cy + h)
      ..close();
    canvas.drawPath(path, paint);
    canvas.restore();
  }

  void _drawHexagon(Canvas canvas, Paint paint, double radius) {
    final cx = size.x / 2;
    final cy = size.y / 2;
    final path = Path();
    for (int i = 0; i < 6; i++) {
      final angle = i * math.pi / 3 - math.pi / 6;
      final x = cx + radius * math.cos(angle);
      final y = cy + radius * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  void onCollisionStart(
      Set<Vector2> intersectionPoints, PositionComponent other) {
    if (other is EnemyBase) {
      takeDamage();
    }
    super.onCollisionStart(intersectionPoints, other);
  }
}
