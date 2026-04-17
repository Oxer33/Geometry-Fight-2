import 'dart:math' as math;
import 'dart:ui';
import 'package:flame/components.dart';
import '../../../data/constants.dart';
import 'enemy_base.dart';

enum SplitterSize { large, medium, small }

class SplitterEnemy extends EnemyBase {
  final SplitterSize splitterSize;

  SplitterEnemy({this.splitterSize = SplitterSize.large})
      : super(
          hp: 1,
          speed: _speedForSize(splitterSize),
          pointValue: _pointsForSize(splitterSize),
          geomValue: _geomsForSize(splitterSize),
          neonColor: NeonColors.white,
          size: _sizeForSize(splitterSize),
        );

  static double _speedForSize(SplitterSize s) {
    switch (s) {
      case SplitterSize.large:
        return 4;
      case SplitterSize.medium:
        return 120; // homing diretto verso player
      case SplitterSize.small:
        return 180; // homing diretto verso player
    }
  }

  static int _pointsForSize(SplitterSize s) {
    switch (s) {
      case SplitterSize.large:
        return 10;
      case SplitterSize.medium:
        return 4;
      case SplitterSize.small:
        return 2;
    }
  }

  static int _geomsForSize(SplitterSize s) {
    switch (s) {
      case SplitterSize.large:
        return 3;
      case SplitterSize.medium:
        return 2;
      case SplitterSize.small:
        return 1;
    }
  }

  static Vector2 _sizeForSize(SplitterSize s) {
    switch (s) {
      case SplitterSize.large:
        return Vector2(28, 28);
      case SplitterSize.medium:
        return Vector2(18, 18);
      case SplitterSize.small:
        return Vector2(10, 10);
    }
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
  }

  @override
  void updateBehavior(double dt) {
    // Tutti i splitter (large/medium/small): homing diretto verso il player.
    // La rotazione visiva (spin) è gestita in renderShape via idlePhase.
    final velocity = seekPlayer(speed);
    position += velocity * dt;
  }

  @override
  void onDeath() {
    // Split into smaller pieces
    SplitterSize? nextSize;
    switch (splitterSize) {
      case SplitterSize.large:
        nextSize = SplitterSize.medium;
      case SplitterSize.medium:
        nextSize = SplitterSize.small;
      case SplitterSize.small:
        nextSize = null;
    }

    if (nextSize != null) {
      // Ridotto da 3 a 2 figli per contenere la cascata di triangoli bianchi
      for (int i = 0; i < 2; i++) {
        final child = SplitterEnemy(splitterSize: nextSize);
        final angle = i * math.pi + math.pi / 4; // angoli 45° e 225° (opposti)
        child.position =
            position + Vector2(math.cos(angle), math.sin(angle)) * 20;
        // Figli generati in-game: killabili immediatamente (no spawn invulnerability)
        child.clearSpawnInvulnerability();
        game.world.add(child);
      }
    }

    super.onDeath();
  }

  @override
  void renderShape(Canvas canvas, Paint paint, double scale) {
    final cx = size.x / 2;
    final cy = size.y / 2;
    final r = size.x / 2 * scale;

    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(idlePhase * 2);

    // Triangolo principale
    final path = Path()
      ..moveTo(0, -r)
      ..lineTo(r * 0.87, r * 0.5)
      ..lineTo(-r * 0.87, r * 0.5)
      ..close();
    canvas.drawPath(path, paint);

    if (scale <= 1.01) {
      // Triangolo interno contro-rotante
      final innerR = r * 0.5;
      final innerPath = Path()
        ..moveTo(0, innerR * 0.7) // Invertito rispetto all'esterno
        ..lineTo(innerR * 0.6, -innerR * 0.35)
        ..lineTo(-innerR * 0.6, -innerR * 0.35)
        ..close();
      final innerPaint = Paint()
        ..color = paint.color.withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.7;
      canvas.drawPath(innerPath, innerPaint);

      // Linee di frattura luminose (dove si dividerà)
      if (splitterSize != SplitterSize.small) {
        final fractureAlpha = 0.15 + math.sin(idlePhase * 4) * 0.1;
        final fracturePaint = Paint()
          ..color = paint.color.withValues(alpha: fractureAlpha)
          ..strokeWidth = 0.8
          ..style = PaintingStyle.stroke;
        // 3 linee dal centro ai punti medi dei lati
        canvas.drawLine(Offset.zero, Offset(0, -r * 0.8), fracturePaint);
        canvas.drawLine(Offset.zero, Offset(r * 0.7, r * 0.4), fracturePaint);
        canvas.drawLine(Offset.zero, Offset(-r * 0.7, r * 0.4), fracturePaint);

        // Nodi sui punti medi dei lati (dove si staccheranno i pezzi)
        final vertices = [
          Offset(r * 0.43, -r * 0.25), // Punto medio lato dx
          Offset(0, r * 0.5),           // Punto medio lato basso
          Offset(-r * 0.43, -r * 0.25), // Punto medio lato sx
        ];
        for (int i = 0; i < vertices.length; i++) {
          final nodePulse = 0.3 + math.sin(idlePhase * 5 + i * 2.0) * 0.3;
          EnemyBase.detailPaint.color = paint.color.withValues(alpha: nodePulse);
          canvas.drawCircle(vertices[i], 1.2, EnemyBase.detailPaint);
        }
      }

      // Nucleo pulsante (colore diverso per dimensione)
      final coreColor = splitterSize == SplitterSize.large
          ? const Color(0xFFFFFFFF)
          : splitterSize == SplitterSize.medium
              ? const Color(0xFFDDDDFF)
              : const Color(0xFFAAAAFF);
      final pulse = 0.5 + math.sin(idlePhase * 5) * 0.3;
      EnemyBase.detailPaint.color = coreColor.withValues(alpha: pulse);
      canvas.drawCircle(Offset.zero, r * 0.18, EnemyBase.detailPaint);

      // Indicatore livello (puntini orbitanti)
      final dotsCount = splitterSize == SplitterSize.large
          ? 3
          : splitterSize == SplitterSize.medium
              ? 2
              : 0;
      for (int i = 0; i < dotsCount; i++) {
        final dotAngle = i * math.pi * 2 / 3 - math.pi / 2 + idlePhase * 3;
        EnemyBase.detailPaint.color = paint.color.withValues(alpha: 0.5);
        canvas.drawCircle(
          Offset(r * 0.35 * math.cos(dotAngle), r * 0.35 * math.sin(dotAngle)),
          1.0, EnemyBase.detailPaint,
        );
      }
    }

    canvas.restore();
  }
}
