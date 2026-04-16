import 'dart:math' as math;
import 'dart:ui';
import 'package:flame/components.dart';
import '../../../data/constants.dart';
import 'enemy_base.dart';
import '../projectiles.dart';

/// BOUNCER → GATE / DUMBBELL enemy (Geometry Wars "Bouncer" style).
/// A rotating dumbbell: two endpoint spheres connected by a thin bar.
/// Bullets bounce off it. Player kills it by passing through the center (thin gap).
/// The endpoints kill the player on contact.
class BouncerEnemy extends EnemyBase {
  double _rotAngle = 0;
  late double _moveAngle;

  // Endpoint radius used for kill/damage logic
  static const double _endpointRadius = 12.0;
  static const double _centerKillRadius = 12.0; // aumentato: zona sicura più ampia
  static const double _playerKillRadius = 7.0;  // ridotto: non sovrappone la zona centrale

  // Paint cache statici — evita allocazioni ogni frame
  static final _barPaint = Paint()..style = PaintingStyle.stroke;
  static final _circlePaint = Paint()..style = PaintingStyle.fill;
  static final _glowPaint = Paint()..style = PaintingStyle.fill;
  static final _centerPaint = Paint()
    ..color = const Color(0xFFFFFFFF).withValues(alpha: 0.3)
    ..style = PaintingStyle.fill;

  BouncerEnemy()
      : super(
          hp: 999,
          speed: 30,
          pointValue: 5,
          geomValue: 3,
          neonColor: NeonColors.purple,
          size: Vector2(40, 40),
        ) {
    _moveAngle = math.Random().nextDouble() * math.pi * 2;
  }

  @override
  void takeDamage(double amount) {
    // Invulnerable to bullets — do nothing
  }

  @override
  void updateBehavior(double dt) {
    _rotAngle += dt * 1.5;

    // Slow drift
    position.x += math.cos(_moveAngle) * speed * dt;
    position.y += math.sin(_moveAngle) * speed * dt;

    // Wall bounce
    if (game.isTunnelMode) {
      final camY = game.camera.viewfinder.position.y;
      final halfH = game.tunnelHeight / 2;
      final minY = camY - halfH + 10;
      final maxY = camY + halfH - 10;
      if (position.y <= minY) {
        _moveAngle = -_moveAngle;
        position.y = minY;
      } else if (position.y >= maxY) {
        _moveAngle = -_moveAngle;
        position.y = maxY;
      }
    } else {
      if (position.x <= 10) {
        _moveAngle = math.pi - _moveAngle;
        position.x = 10;
      } else if (position.x >= arenaWidth - 10) {
        _moveAngle = math.pi - _moveAngle;
        position.x = arenaWidth - 10;
      }
      if (position.y <= 10) {
        _moveAngle = -_moveAngle;
        position.y = 10;
      } else if (position.y >= arenaHeight - 10) {
        _moveAngle = -_moveAngle;
        position.y = arenaHeight - 10;
      }
    }

    // Compute the two endpoint positions (world space)
    final ep1 = position + Vector2(math.cos(_rotAngle) * _endpointRadius, math.sin(_rotAngle) * _endpointRadius);
    final ep2 = position - Vector2(math.cos(_rotAngle) * _endpointRadius, math.sin(_rotAngle) * _endpointRadius);

    final playerPos = game.player.position;

    // Check if player touches an endpoint (kill player) — guard su isInvincible
    if (!game.player.isInvincible &&
        (playerPos.distanceTo(ep1) < _playerKillRadius || playerPos.distanceTo(ep2) < _playerKillRadius)) {
      game.player.takeDamage();
    }

    // Check if player passes through the center gap (kill bouncer + shockwave)
    final distToCenter = playerPos.distanceTo(position);
    if (distToCenter < _centerKillRadius) {
      // Make sure the player is NOT near the endpoints (i.e., near the center line)
      final nearEp1 = playerPos.distanceTo(ep1) < _endpointRadius + 4;
      final nearEp2 = playerPos.distanceTo(ep2) < _endpointRadius + 4;
      if (!nearEp1 && !nearEp2) {
        _triggerCenterKill();
      }
    }
  }

  void _triggerCenterKill() {
    // Shockwave: kill all enemies within radius 150
    final toKill = <EnemyBase>[];
    for (final child in game.world.children) {
      if (child is EnemyBase && child != this) {
        if (child.position.distanceTo(position) < 150) {
          toKill.add(child);
        }
      }
    }
    for (final enemy in toKill) {
      enemy.killSilently();
    }

    game.spawnExplosion(position, NeonColors.purple, radius: 150, particleCount: 25);
    game.triggerScreenShake(6, 0.3);

    onDeath();
  }

  @override
  void onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) {
    if (other is PlayerBullet) {
      // Reflect the bullet
      other.reflect();
    }
    super.onCollisionStart(intersectionPoints, other);
  }

  @override
  void renderShape(Canvas canvas, Paint paint, double scale) {
    final cx = size.x / 2;
    final cy = size.y / 2;

    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(_rotAngle);

    // Connecting bar (thin line between the two circles)
    _barPaint.color = paint.color;
    _barPaint.strokeWidth = 2 * scale;
    canvas.drawLine(
      Offset(-_endpointRadius, 0),
      Offset(_endpointRadius, 0),
      _barPaint,
    );

    // Two endpoint circles
    _circlePaint.color = paint.color;

    // Glow around endpoints
    if (scale <= 1.01) {
      _glowPaint.color = paint.color.withValues(alpha: 0.25);
      canvas.drawCircle(Offset(-_endpointRadius, 0), 7 * scale, _glowPaint);
      canvas.drawCircle(Offset(_endpointRadius, 0), 7 * scale, _glowPaint);
    }

    canvas.drawCircle(Offset(-_endpointRadius, 0), 5 * scale, _circlePaint);
    canvas.drawCircle(Offset(_endpointRadius, 0), 5 * scale, _circlePaint);

    // Center dot (shows the kill zone)
    if (scale <= 1.01) {
      canvas.drawCircle(Offset.zero, 2.5, _centerPaint);
    }

    canvas.restore();
  }
}
