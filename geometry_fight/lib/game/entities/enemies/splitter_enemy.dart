import 'dart:math' as math;
import 'dart:ui';
import 'package:flame/components.dart';
import '../../../data/constants.dart';
import 'enemy_base.dart';

enum SplitterSize { large, medium, small }

// Paint cache per renderShape: con fino a 7 splitter a schermo post-split,
// evita 14+ alloc/frame.
final Paint _splInnerPaint = Paint()
  ..style = PaintingStyle.stroke
  ..strokeWidth = 0.7;
final Paint _splFracturePaint = Paint()
  ..style = PaintingStyle.stroke
  ..strokeWidth = 0.8;

class SplitterEnemy extends EnemyBase {
  final SplitterSize splitterSize;

  // Parametri di wobble orbitale/caotico per i figli (medium/small). Il large
  // resta in homing diretto come prima — si muove già pochissimo (speed 4).
  // I figli invece seguono il player ma con una componente perpendicolare
  // sinusoidale che crea una rotazione evidente + un secondo termine a freq
  // diversa che aggiunge caos (senza diventare puro random).
  static final math.Random _rng = math.Random();
  double _orbitalPhase = 0;
  late double _orbitalPhaseOffset;
  late double _orbitalFreq; // Hz
  late double _orbitalAmp;  // px/s di velocità perpendicolare
  late double _chaosFreq;   // freq secondaria (0 = solo orbita pulita)

  SplitterEnemy({this.splitterSize = SplitterSize.large})
      : super(
          hp: 1,
          speed: _speedForSize(splitterSize),
          pointValue: _pointsForSize(splitterSize),
          geomValue: _geomsForSize(splitterSize),
          neonColor: NeonColors.white,
          size: _sizeForSize(splitterSize),
        ) {
    _orbitalPhaseOffset = _rng.nextDouble() * math.pi * 2;
    switch (splitterSize) {
      case SplitterSize.large:
        // Large: homing puro, nessun wobble (era già così)
        _orbitalFreq = 0;
        _orbitalAmp = 0;
        _chaosFreq = 0;
      case SplitterSize.medium:
        // Medium: orbita marcata + leggero caos
        _orbitalFreq = 0.7 + _rng.nextDouble() * 0.3;  // 0.7-1.0 Hz
        _orbitalAmp = 110;
        _chaosFreq = 1.6 + _rng.nextDouble() * 0.4;   // 1.6-2.0 Hz
      case SplitterSize.small:
        // Small: rotazione aggressiva, caotica
        _orbitalFreq = 1.1 + _rng.nextDouble() * 0.5;  // 1.1-1.6 Hz
        _orbitalAmp = 170;
        _chaosFreq = 2.2 + _rng.nextDouble() * 0.6;   // 2.2-2.8 Hz
    }
  }

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

  /// Splitter NON più completamente immuni al danno ad area.
  ///   - Laser / plasma / overdrive → danno normale
  ///   - Bomba globale da `useBomb` → usa `killSilently` che ha guard separato
  /// Cascata controllata via `_splitBudget`: max N split per frame
  /// → figli in eccesso NON spawnano invece di saturare world.children.
  @override
  bool get isImmuneToAreaDamage => false;

  /// Budget globale di split per frame. Reset in `game_world.update()`
  /// via `SplitterEnemy.resetFrameBudget()`. Se exhausted, split skippato
  /// per questo frame — il splitter muore senza generare figli.
  static int _splitBudget = _maxSplitsPerFrame;
  static const int _maxSplitsPerFrame = 3;
  static void resetFrameBudget() {
    _splitBudget = _maxSplitsPerFrame;
  }

  @override
  void updateBehavior(double dt) {
    // Large: homing diretto (invariato). La rotazione visiva (spin) è sempre
    // gestita in renderShape via idlePhase.
    // Medium/Small: homing + componente perpendicolare sinusoidale, così
    // i figli generati dopo lo split orbitano attorno alla traiettoria invece
    // di puntare il player in linea retta — riporta la sensazione rotatoria
    // del comportamento originale pre-refactor.
    final velocity = seekPlayer(speed);
    // Threshold più severa (1.0 invece di 0.001): sotto 1.0 di length² il
    // perp-normalized può produrre NaN (divisione per ~0). Fallback a homing
    // dritto senza wobble in quei casi.
    if (_orbitalAmp <= 0 || velocity.length2 < 1.0) {
      position += velocity * dt;
      return;
    }

    _orbitalPhase += dt;
    final perp = Vector2(-velocity.y, velocity.x).normalized();
    // Combinazione di due sinusoidi a frequenze diverse → Lissajous-like:
    // dà una rotazione che non è mai identica tra un istante e l'altro,
    // senza essere puramente random (quindi leggibile).
    final primary = math.sin(
        _orbitalPhase * _orbitalFreq * math.pi * 2 + _orbitalPhaseOffset);
    final secondary = _chaosFreq > 0
        ? math.sin(_orbitalPhase * _chaosFreq * math.pi * 2 +
                _orbitalPhaseOffset * 1.7) *
            0.5
        : 0.0;
    final wobbleSpeed = (primary + secondary) * _orbitalAmp;
    position += (velocity + perp * wobbleSpeed) * dt;
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

    // Split gate-eato da budget globale: se il frame corrente ha già
    // splittato `_maxSplitsPerFrame` volte, skippa lo spawn di figli per
    // questo tick — evita cascata simultanea (es. laser che investe 10
    // splitter large → senza budget si avrebbero 20 medium × 2 small = 60
    // triangoli spawnati nello stesso frame).
    if (nextSize != null && _splitBudget > 0) {
      _splitBudget--;
      for (int i = 0; i < 2; i++) {
        final child = SplitterEnemy(splitterSize: nextSize);
        final angle = i * math.pi + math.pi / 4; // 45° / 225°
        final jitter = Vector2(
          (_rng.nextDouble() - 0.5) * 8,
          (_rng.nextDouble() - 0.5) * 8,
        );
        child.position =
            position + Vector2(math.cos(angle), math.sin(angle)) * 20 + jitter;
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
      _splInnerPaint.color = paint.color.withValues(alpha: 0.3);
      canvas.drawPath(innerPath, _splInnerPaint);

      // Linee di frattura luminose (dove si dividerà)
      if (splitterSize != SplitterSize.small) {
        final fractureAlpha = 0.15 + math.sin(idlePhase * 4) * 0.1;
        _splFracturePaint.color =
            paint.color.withValues(alpha: fractureAlpha);
        // 3 linee dal centro ai punti medi dei lati
        canvas.drawLine(Offset.zero, Offset(0, -r * 0.8), _splFracturePaint);
        canvas.drawLine(Offset.zero, Offset(r * 0.7, r * 0.4), _splFracturePaint);
        canvas.drawLine(Offset.zero, Offset(-r * 0.7, r * 0.4), _splFracturePaint);

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
