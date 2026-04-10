import 'dart:math' as math;
import 'dart:ui';
import 'package:flame/components.dart';
import '../../../data/constants.dart';
import '../../../data/wave_configs.dart';
import 'enemy_base.dart';
import 'proton_enemy.dart';
import '../projectiles.dart';

class BlackHoleEnemy extends EnemyBase {
  static final _ringPaint = Paint()..style = PaintingStyle.stroke;
  static final _darkPaint = Paint();

  double _rotAngle = 0;
  double _spawnTimer = 5.0;
  int _absorbedCount = 0; // Conta nemici assorbiti (per Proton explosion come GW)
  bool _dead = false; // Guard per double-kill (proton explosion + takeDamage nello stesso frame)
  static const int _protonThreshold = 5; // Dopo 5 nemici assorbiti → BOOM!

  BlackHoleEnemy()
      : super(
          hp: 20,
          speed: 0,
          pointValue: 30,
          geomValue: 10,
          neonColor: NeonColors.darkRed,
          size: Vector2(40, 40),
        );

  @override
  void updateBehavior(double dt) {
    _rotAngle += dt * 2;

    // Attract player (weak force)
    final toHole = position - game.player.position;
    if (toHole.length > 0 && toHole.length < 300) {
      final force = toHole.normalized() * 50 * dt;
      game.player.position += force;
    }

    // Attract nearby enemies + curve player projectiles
    // Prima fase: attrazione + colleziona nemici assorbiti (senza rimuoverli)
    final toAbsorb = <EnemyBase>[];
    for (final child in game.world.children) {
      if (child is EnemyBase && child != this) {
        final toHole2 = position - child.position;
        if (toHole2.length > 0 && toHole2.length < 200) {
          child.position += toHole2.normalized() * 30 * dt;
          if (toHole2.length < 15) {
            toAbsorb.add(child);
          }
        }
      } else if (child is PlayerBullet) {
        final toBH = position - child.position;
        if (toBH.length > 0 && toBH.length < 200) {
          child.position += toBH.normalized() * 80 * dt;
        }
      }
    }
    // Seconda fase: rimuovi i nemici assorbiti (fuori dal loop)
    for (final enemy in toAbsorb) {
      enemy.removeFromParent();
      _absorbedCount++;
    }
    // GW Proton mechanic: troppi assorbiti → ESPLODE in Proton!
    if (_absorbedCount >= _protonThreshold) {
      _explodeIntoProtons();
      return;
    }

    // Spawn bonus enemies
    _spawnTimer -= dt;
    if (_spawnTimer <= 0) {
      _spawnTimer = 5.0;
      game.spawnEnemy(
          EnemyType.drone,
          position +
              Vector2(
                (math.Random().nextDouble() - 0.5) * 60,
                (math.Random().nextDouble() - 0.5) * 60,
              ));
    }
  }

  /// GW:RE2 Proton mechanic: il buco nero esplode in una pioggia di mini-nemici velocissimi.
  /// Risk/reward: lasciar assorbire nemici al buco nero è pericoloso!
  void _explodeIntoProtons() {
    if (_dead) return;
    _dead = true;
    final protonCount = 6 + _absorbedCount; // Più ha assorbito, più Proton genera
    for (int i = 0; i < protonCount; i++) {
      final angle = i * math.pi * 2 / protonCount;
      final dir = Vector2(math.cos(angle), math.sin(angle));
      final proton = ProtonEnemy(direction: dir);
      proton.position = position + dir * 20;
      game.world.add(proton);
    }

    // Mega esplosione visiva
    game.spawnExplosion(position, NeonColors.red, radius: 120, particleCount: 30);
    game.triggerScreenShake(8, 0.4);
    if (!game.isTunnelMode) {
      game.grid.applyForce(position, 250, 2000);
    }

    // Il buco nero muore
    game.onEnemyKilled(this);
    removeFromParent();
  }

  @override
  void takeDamage(double amount) {
    if (_dead) return; // Già esploso in proton
    // Immune to normal bullets - only plasma, bomb, laser do damage
    // This is handled by checking weapon type in the bullet collision
    // For simplicity, all damage works but normal bullets do reduced
    super.takeDamage(amount * 0.3);
  }

  @override
  void onDeath() {
    if (_dead) return; // Evita double-kill se esplode in proton e viene ucciso nello stesso frame
    _dead = true;
    super.onDeath();
  }

  @override
  void renderShape(Canvas canvas, Paint paint, double scale) {
    final cx = size.x / 2;
    final cy = size.y / 2;
    final r = 18 * scale;

    // === INDICATORE RAGGIO GRAVITAZIONALE (cerchio sottile) ===
    if (scale <= 1.01) {
      EnemyBase.detailPaint.color = NeonColors.darkRed.withValues(alpha: 0.06);
      EnemyBase.detailPaint.style = PaintingStyle.stroke;
      EnemyBase.detailPaint.strokeWidth = 0.5;
      canvas.drawCircle(Offset(cx, cy), 150, EnemyBase.detailPaint);
      EnemyBase.detailPaint.style = PaintingStyle.fill;
    }

    // === GLOW ESTERNO ROSSO (ampio, pulsante — no blur per performance) ===
    final glowPulse = 0.15 + math.sin(_rotAngle * 1.5) * 0.05;
    EnemyBase.detailPaint.color = NeonColors.red.withValues(alpha: glowPulse);
    canvas.drawCircle(Offset(cx, cy), r * 2, EnemyBase.detailPaint);

    // === ANELLI GRAVITAZIONALI ROTANTI ===
    // Anello 1: esterno, rotazione oraria
    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(_rotAngle);
    _ringPaint.color = NeonColors.red.withValues(alpha: 0.4);
    _ringPaint.strokeWidth = 2 * scale;
    for (int i = 0; i < 4; i++) {
      final angle = i * math.pi / 2;
      canvas.drawArc(
        Rect.fromCircle(center: Offset.zero, radius: r),
        angle, math.pi / 3, false, _ringPaint,
      );
    }
    canvas.restore();

    // Anello 2: interno, rotazione antioraria
    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(-_rotAngle * 1.3);
    _ringPaint.color = NeonColors.red.withValues(alpha: 0.25);
    _ringPaint.strokeWidth = 1.5 * scale;
    for (int i = 0; i < 3; i++) {
      final angle = i * math.pi * 2 / 3;
      canvas.drawArc(
        Rect.fromCircle(center: Offset.zero, radius: r * 0.7),
        angle, math.pi / 4, false, _ringPaint,
      );
    }
    canvas.restore();

    // === NUCLEO NERO con bordo rosso ===
    _darkPaint.color = const Color(0xFF000000);
    canvas.drawCircle(Offset(cx, cy), r * 0.5, _darkPaint);
    // Bordo rosso pulsante del nucleo
    final borderPulse = 0.5 + math.sin(_rotAngle * 3) * 0.3;
    _ringPaint.color = NeonColors.red.withValues(alpha: borderPulse);
    _ringPaint.strokeWidth = 1.5;
    canvas.drawCircle(Offset(cx, cy), r * 0.5, _ringPaint);

    // === PARTICELLE SPIRALANTI (solo layer principale, no blur) ===
    if (scale <= 1.01) {
      for (int i = 0; i < 8; i++) {
        final pAngle = _rotAngle * 2 + i * math.pi / 4;
        final pDist = r * (0.6 + 0.4 * math.sin(_rotAngle + i * 0.5));
        final px = cx + pDist * math.cos(pAngle);
        final py = cy + pDist * math.sin(pAngle);
        final pAlpha = 0.2 + math.sin(_rotAngle * 3 + i) * 0.15;
        EnemyBase.detailPaint.color = NeonColors.red.withValues(alpha: pAlpha);
        canvas.drawCircle(Offset(px, py), 1.5, EnemyBase.detailPaint);
      }

      // Punto luminoso centrale
      EnemyBase.detailPaint.color = const Color(0xFFFF4400).withValues(alpha: 0.5 + math.sin(_rotAngle * 4) * 0.3);
      canvas.drawCircle(Offset(cx, cy), r * 0.15, EnemyBase.detailPaint);
    }

    paint.style = PaintingStyle.fill;
  }
}
