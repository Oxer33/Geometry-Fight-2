import 'dart:math' as math;
import 'dart:ui';
import 'package:flame/components.dart';
import '../../../data/constants.dart';
import 'enemy_base.dart';

/// SWARM DRONE - Piccolo e debole ma spawna in gruppi enormi.
/// Forma: triangolino affilato (aspetto da mini-caccia)
/// Colore: rosa-rosso caldo (#FF3388) → rosso acceso quando enraged
/// Meccanica: si muovono in linea retta (dx/sx o su/giù) e rimbalzano sui muri.
/// Stile Geometry Wars "arrow": pattern cardinale, non inseguono il player.
/// Se uno viene ucciso gli altri accelerano per 1s ("furia").
///
/// Se spawnato dal border-line (wave_system), usa `forcedInitialDirection` per
/// forzare la marcia perpendicolare al bordo invece di scegliere un asse random.
/// La direzione viene consumata al primo tick, così il mob dopo un rimbalzo
/// torna a comportarsi come una SwarmDrone normale.
class SwarmDroneEnemy extends EnemyBase {
  late Vector2 _moveDir;
  Vector2? forcedInitialDirection;

  // Paint cache — evita allocazioni per frame × N swarm drones (spawn in centinaia).
  static final Paint _glowPaint = Paint();
  static final Paint _trailPaint = Paint();
  static final Paint _bodyPaint = Paint();
  static final Paint _edgePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.6;
  static final Paint _corePaint = Paint();
  static final Paint _eyePaint = Paint();
  static final Paint _thrusterPaint = Paint();

  // Path cache condiviso (trail). Con 50 drone a schermo risparmia ~150 Path
  // alloc/frame. Reset prima di ogni uso.
  static final Path _sharedTrailPath = Path();

  // Random statico condiviso (evita alloc per constructor + wall bounce).
  static final math.Random _rng = math.Random();

  SwarmDroneEnemy()
      : super(
          hp: 1,
          speed: 120,
          pointValue: 1,
          geomValue: 1,
          neonColor: const Color(0xFFFF3388),
          size: Vector2(10, 10),
        ) {
    // Direzione iniziale casuale: uno dei 4 assi cardinali
    _moveDir = _rng.nextBool()
        ? Vector2(_rng.nextBool() ? 1 : -1, 0)  // orizzontale
        : Vector2(0, _rng.nextBool() ? 1 : -1);  // verticale
  }

  /// Setta la direzione di marcia SUBITO (update+render primo frame
  /// coerenti). Usato da wave_system per spawn a schiera bordo.
  /// Fix: `forcedInitialDirection` si applicava al primo update, ma il
  /// render avveniva già a frame 0 con _moveDir random → triangoli
  /// ruotati a caso prima di allinearsi.
  void setMarchDirection(Vector2 dir) {
    _moveDir = dir.clone();
    forcedInitialDirection = null;
  }

  @override
  void updateBehavior(double dt) {
    // Consume la direzione forzata al primo update (se settata dal wave system).
    if (forcedInitialDirection != null) {
      _moveDir = forcedInitialDirection!.clone();
      forcedInitialDirection = null;
    }

    final currentSpeed = isGloballyEnraged ? speed * 1.8 : speed;

    position += _moveDir * currentSpeed * dt;

    // Rimbalza sui muri cambiando asse (dx/sx ↔ su/giù)
    if (game.isTunnelMode) {
      final camY = game.camera.viewfinder.position.y;
      final halfH = game.tunnelHeight / 2;
      if (position.y <= camY - halfH + 10 || position.y >= camY + halfH - 10) {
        _moveDir.y = -_moveDir.y;
        // Se stava andando in verticale, cambia ad orizzontale
        if (_moveDir.x == 0) {
          _moveDir = Vector2(_rng.nextBool() ? 1 : -1, _moveDir.y.sign * 0.3);
          _moveDir.normalize();
        }
        position.y = position.y.clamp(camY - halfH + 10, camY + halfH - 10);
      }
    } else {
      if (position.x <= 10 || position.x >= arenaWidth - 10) {
        _moveDir.x = -_moveDir.x;
        position.x = position.x.clamp(10, arenaWidth - 10);
      }
      if (position.y <= 10 || position.y >= arenaHeight - 10) {
        _moveDir.y = -_moveDir.y;
        position.y = position.y.clamp(10, arenaHeight - 10);
      }
    }
  }

  @override
  void onDeath() {
    // Enrage: tutti gli SwarmDrone si enragiano globalmente per 1.5s
    // (evita iterazione O(n²) che causa lag con 100+ nemici).
    // Usa max per non accorciare un enrage già in corso (es. due drone muoiono
    // a 0.5s di distanza → il secondo non deve troncare il timer del primo).
    if (_globalEnrageTimer < 1.5) _globalEnrageTimer = 1.5;
    super.onDeath();
  }

  // Timer globale condiviso: quando uno muore, tutti si enragiano
  static double _globalEnrageTimer = 0;
  static void updateGlobalEnrage(double dt) {
    if (_globalEnrageTimer > 0) _globalEnrageTimer -= dt;
  }
  static void resetGlobalEnrage() => _globalEnrageTimer = 0;
  bool get isGloballyEnraged => _globalEnrageTimer > 0;

  @override
  void renderShape(Canvas canvas, Paint paint, double scale) {
    final cx = size.x / 2;
    final cy = size.y / 2;
    final s = size.x / 2 * scale;

    canvas.save();
    canvas.translate(cx, cy);
    final angle = math.atan2(_moveDir.y, _moveDir.x) + math.pi / 2;
    canvas.rotate(angle);

    final baseColor = isGloballyEnraged
        ? const Color(0xFFFF0022)
        : paint.color;

    // === HALO ROSSO DIETRO (solo layer principale) ===
    // Glow alone (no blur) che suggerisce il motore incandescente.
    if (scale <= 1.01) {
      _glowPaint.color = baseColor.withValues(alpha: isGloballyEnraged ? 0.35 : 0.22);
      canvas.drawCircle(Offset(0, s * 0.3), s * 1.1, _glowPaint);
    }

    // === SCIA PROPULSORE (solo layer principale) ===
    if (scale <= 1.01) {
      // Due striature a V dietro al corpo, come mini turbine.
      for (int i = 1; i <= 3; i++) {
        final trailAlpha = (isGloballyEnraged ? 0.45 : 0.25) - i * 0.08;
        if (trailAlpha > 0) {
          _trailPaint.color = baseColor.withValues(alpha: trailAlpha);
          // Reset + riempi il path condiviso invece di allocarne uno nuovo.
          _sharedTrailPath.reset();
          _sharedTrailPath
            ..moveTo(s * 0.35, s * 0.45 + i * 3.0)
            ..lineTo(0, s * 0.55 + i * 4.0)
            ..lineTo(-s * 0.35, s * 0.45 + i * 3.0);
          canvas.drawPath(_sharedTrailPath, _trailPaint);
        }
      }
    }

    // === CORPO PRINCIPALE — triangolo affilato (più slanciato di prima) ===
    // Punta più lunga, ali più ravvicinate → aspetto da "freccia".
    _bodyPaint.color = baseColor;
    final path = Path()
      ..moveTo(0, -s * 1.15)          // punta affilata in avanti
      ..lineTo(s * 0.55, s * 0.15)
      ..lineTo(s * 0.65, s * 0.55)    // ala destra
      ..lineTo(0, s * 0.3)            // notch posteriore
      ..lineTo(-s * 0.65, s * 0.55)   // ala sinistra
      ..lineTo(-s * 0.55, s * 0.15)
      ..close();
    canvas.drawPath(path, _bodyPaint);

    if (scale <= 1.01) {
      // === BORDO LUMINOSO sul profilo leader ===
      _edgePaint.color = const Color(0xFFFFFFFF).withValues(alpha: 0.55);
      canvas.drawLine(Offset(0, -s * 1.15), Offset(s * 0.55, s * 0.15), _edgePaint);
      canvas.drawLine(Offset(0, -s * 1.15), Offset(-s * 0.55, s * 0.15), _edgePaint);

      // === NUCLEO / OCCHIO rosso minaccioso ===
      final corePulse = isGloballyEnraged
          ? 0.75 + math.sin(idlePhase * 10) * 0.25
          : 0.45 + math.sin(idlePhase * 5) * 0.25;
      final coreColor = isGloballyEnraged
          ? const Color(0xFFFF4400)
          : const Color(0xFFFFFFFF);
      _corePaint.color = coreColor.withValues(alpha: corePulse);
      canvas.drawCircle(Offset(0, -s * 0.1), s * 0.2, _corePaint);

      // Punto rosso centrale (iride)
      _eyePaint.color = const Color(0xFFFF2200).withValues(alpha: 0.9);
      canvas.drawCircle(Offset(0, -s * 0.1), s * 0.09, _eyePaint);

      // === THRUSTERS alla base (due micro-circoli) ===
      final thrusterAlpha = isGloballyEnraged ? 0.85 : 0.55;
      final thrusterColor = isGloballyEnraged
          ? const Color(0xFFFFAA00)
          : const Color(0xFFFF6600);
      _thrusterPaint.color = thrusterColor.withValues(alpha: thrusterAlpha);
      canvas.drawCircle(Offset(s * 0.3, s * 0.35), 0.9, _thrusterPaint);
      canvas.drawCircle(Offset(-s * 0.3, s * 0.35), 0.9, _thrusterPaint);
    }

    canvas.restore();
  }
}
