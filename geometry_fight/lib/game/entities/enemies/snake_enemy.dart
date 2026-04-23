import 'dart:math' as math;
import 'dart:ui';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import '../../../data/constants.dart';
import '../projectiles.dart';
import 'enemy_base.dart';

// Random statico condiviso (evita alloc in onLoad per ogni snake).
final math.Random _snakeRng = math.Random();

// Paint cache riutilizzati — risparmiano migliaia di alloc/sec con molti snake
// a schermo (8 segmenti × ~5 paint × 60fps × N).
final Paint _snakeLinePaint = Paint();
final Paint _snakeSegPaint = Paint();
final Paint _snakeCorePaint = Paint();
final Paint _snakeEyePaint = Paint()
  ..color = const Color(0xFFFFFFFF).withValues(alpha: 0.8);

class SnakeEnemy extends EnemyBase {
  final int segmentCount;
  final List<Vector2> _segments = [];
  final List<Vector2> _segmentVelocities = [];
  final bool isFragment;
  // Sine wave homing (come GW originale), ampiezza aumentata per moto più "strisciante"
  double _sinePhase = 0;
  static const double _sineAmplitude = 90.0; // px (era 60)
  static const double _sineFrequency = 1.1; // Hz (era 0.8)
  // Colore testa: rosso fluo — unico punto dove prende danno
  static const Color _headColor = Color(0xFFFF2030);

  SnakeEnemy({this.segmentCount = 8, this.isFragment = false})
      : super(
          hp: 1,
          speed: 120,
          pointValue: 5,
          geomValue: 2,
          neonColor: NeonColors.green,
          size: Vector2(12, 12),
        ) {
    hp = segmentCount.toDouble();
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _segments.clear();
    // Orientamento iniziale random: prima spawnavano sempre con testa in giu
    // (segments ordinati verso l'alto) → ora i segments si srotolano in una
    // direzione casuale, così il serpente entra in scena con pose variate.
    final initAngle = _snakeRng.nextDouble() * math.pi * 2;
    final tailDir = Vector2(math.cos(initAngle), math.sin(initAngle));
    for (int i = 0; i < segmentCount; i++) {
      _segments.add(position + tailDir * (i * 14.0));
      _segmentVelocities.add(Vector2.zero());
    }
    // Body segments (index 1..N-1): bloccano i proiettili ma non fanno danno al snake.
    // Solo la testa (segment 0) prende danno dal CircleHitbox di EnemyBase.
    for (int i = 1; i < segmentCount; i++) {
      add(_SnakeBody(this, i));
    }
  }

  @override
  void updateBehavior(double dt) {
    _sinePhase += dt;

    // Direzione base verso il player
    final toPlayer = (playerPosition - position);
    if (toPlayer.length == 0) return;
    final baseDir = toPlayer.normalized();

    // Vettore perpendicolare per l'onda sinusoidale
    final perpDir = Vector2(-baseDir.y, baseDir.x);

    // Offset sinusoidale (come GW: traiettoria a serpentina)
    final sineOffset =
        math.sin(_sinePhase * _sineFrequency * math.pi * 2) * _sineAmplitude;
    final moveDir = baseDir * speed + perpDir * sineOffset;

    if (moveDir.length > 0) {
      position += moveDir.normalized() * speed * dt;
    }

    // Rimbalza sui muri (come GW)
    if (game.isTunnelMode) {
      // Tunnel mode: solo clamp Y (basato su tunnelHeight), niente X
      final camY = game.camera.viewfinder.position.y;
      final halfH = game.tunnelHeight / 2;
      position.y = position.y.clamp(camY - halfH + 10, camY + halfH - 10);
      // Despawn se la testa esce a sinistra del camera frame:
      // senza X-clamp il serpente poteva perdersi off-screen.
      final camX = game.camera.viewfinder.position.x;
      final halfW = game.size.x > 0 ? game.size.x / 2 : 400.0;
      if (position.x < camX - halfW - 100) {
        removeFromParent();
        return;
      }
    } else {
      if (position.x <= 10 || position.x >= arenaWidth - 10) {
        position.x = position.x.clamp(10, arenaWidth - 10);
      }
      if (position.y <= 10 || position.y >= arenaHeight - 10) {
        position.y = position.y.clamp(10, arenaHeight - 10);
      }
    }

    // Update segment positions (follow the leader)
    if (_segments.isNotEmpty) {
      _segments[0] = position.clone();
      for (int i = 1; i < _segments.length; i++) {
        final target = _segments[i - 1];
        final current = _segments[i];
        final toTarget = target - current;
        if (toTarget.length > 14) {
          _segments[i] =
              current + toTarget.normalized() * (toTarget.length - 14);
        }
      }
    }
  }

  @override
  void takeDamage(double amount, {bool isArea = false}) {
    // Se la testa sta per morire, prima spawna esplosioni su TUTTI i segmenti
    // (caratteristico del serpente: muore a pezzi). Poi delega a super così
    // il flash + HP-bar vanno normalmente tramite EnemyBase.takeDamage.
    if (isSpawnInvulnerable) return;
    if (isArea && isImmuneToAreaDamage) return;
    if (hp - amount <= 0) {
      for (final seg in _segments) {
        game.spawnExplosion(seg, neonColor, radius: 15, particleCount: 3);
      }
    }
    super.takeDamage(amount, isArea: isArea);
  }

  @override
  void renderShape(Canvas canvas, Paint paint, double scale) {
    final cx = size.x / 2;
    final cy = size.y / 2;

    if (_segments.isEmpty) {
      canvas.drawCircle(Offset(cx, cy), 6 * scale, paint);
      return;
    }

    // === CONNESSIONI LUMINOSE TRA SEGMENTI ===
    if (scale <= 1.01 && _segments.length > 1) {
      for (int i = 0; i < _segments.length - 1; i++) {
        final seg1 = _segments[i] - position;
        final seg2 = _segments[i + 1] - position;
        final lineAlpha = (1.0 - i / _segments.length) * 0.3;
        _snakeLinePaint.color = paint.color.withValues(alpha: lineAlpha);
        _snakeLinePaint.strokeWidth = (2.5 - i * 0.2).clamp(0.5, 2.5);
        canvas.drawLine(
          Offset(cx + seg1.x, cy + seg1.y),
          Offset(cx + seg2.x, cy + seg2.y),
          _snakeLinePaint,
        );
      }
    }

    // === SEGMENTI con gradiente colore ===
    // Testa (i == 0) = ROSSO FLUO (unico punto vulnerabile)
    // Corpo (i >= 1) = verde sfumato (blocca proiettili, non prende danno)
    for (int i = _segments.length - 1; i >= 0; i--) {
      final seg = _segments[i] - position;
      final progress = i / _segments.length; // 0=testa, 1=coda
      final isHead = i == 0;
      // Testa più grande per essere riconoscibile come target
      final radius = (isHead ? 8.0 : (6 - i * 0.3).clamp(3.0, 6.0)) * scale;
      final segAlpha = (1.0 - progress * 0.5);

      final Color segColor;
      if (isHead) {
        segColor = _headColor;
      } else {
        segColor = Color.lerp(
              paint.color,
              paint.color.withValues(alpha: 0.4),
              progress,
            ) ??
            paint.color;
      }
      _snakeSegPaint.color = segColor.withValues(alpha: segAlpha);
      canvas.drawCircle(Offset(cx + seg.x, cy + seg.y), radius, _snakeSegPaint);

      // Nucleo pulsante: bianco sui body, più intenso sulla testa rossa
      if (scale <= 1.01) {
        if (isHead) {
          final pulse = 0.6 + math.sin(idlePhase * 8) * 0.3;
          _snakeCorePaint.color =
              const Color(0xFFFFFFFF).withValues(alpha: pulse);
          canvas.drawCircle(
              Offset(cx + seg.x, cy + seg.y), radius * 0.5, _snakeCorePaint);
        } else if (i % 2 == 0) {
          final pulse = 0.3 + math.sin(idlePhase * 4 + i * 0.5) * 0.2;
          _snakeCorePaint.color =
              const Color(0xFFFFFFFF).withValues(alpha: pulse);
          canvas.drawCircle(
              Offset(cx + seg.x, cy + seg.y), radius * 0.35, _snakeCorePaint);
        }
      }
    }

    // === TESTA: più grande con occhi ===
    if (scale <= 1.01 && _segments.isNotEmpty) {
      final head = _segments[0] - position;
      // Occhi (nella direzione di movimento)
      final moveDir = _segments.length > 1
          ? (_segments[0] - _segments[1]).normalized()
          : Vector2(0, -1);
      final eyeOffset = 2.5;
      final perpDir = Vector2(-moveDir.y, moveDir.x);

      final eyeL = Offset(
        cx + head.x + perpDir.x * eyeOffset + moveDir.x * 2,
        cy + head.y + perpDir.y * eyeOffset + moveDir.y * 2,
      );
      final eyeR = Offset(
        cx + head.x - perpDir.x * eyeOffset + moveDir.x * 2,
        cy + head.y - perpDir.y * eyeOffset + moveDir.y * 2,
      );
      canvas.drawCircle(eyeL, 1.2, _snakeEyePaint);
      canvas.drawCircle(eyeR, 1.2, _snakeEyePaint);
    }
  }
}

/// Body segment del serpente — blocca i proiettili (bullet rimosso senza danno)
/// ma non fa nulla al snake (solo la testa è vulnerabile).
class _SnakeBody extends PositionComponent with CollisionCallbacks {
  final SnakeEnemy snake;
  final int segmentIndex;

  _SnakeBody(this.snake, this.segmentIndex)
      : super(size: Vector2(12, 12), anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    add(CircleHitbox(radius: 5, anchor: Anchor.center)..position = size / 2);
  }

  @override
  void update(double dt) {
    super.update(dt);
    // Segui il segment corrispondente (world coord → parent-local).
    // Il parent (SnakeEnemy) ha anchor.center, ma le coord locali dei figli
    // usano il TOP-LEFT come origine → serve + snake.size/2 per allineare
    // la hitbox al segmento visualmente renderizzato.
    if (segmentIndex < snake._segments.length) {
      position = snake._segments[segmentIndex] - snake.position + snake.size / 2;
    }
  }

  @override
  void onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);
    if (other is PlayerBullet) {
      // Blocca il proiettile senza infliggere danno al serpente
      other.removeFromParent();
    }
  }
}
