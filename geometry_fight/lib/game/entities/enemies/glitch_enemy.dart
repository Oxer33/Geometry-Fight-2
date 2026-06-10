import 'dart:math' as math;
import 'dart:ui';
import 'package:flame/components.dart';
import '../../../data/constants.dart';
import 'enemy_base.dart';

/// GLITCH - Nemico che si teletrasporta casualmente e corrompe lo schermo.
/// Forma: quadrato distorto che "sfarfalla" e cambia forma
/// Colore: ciano elettrico con artefatti (#00EEFF con glitch RGB)
/// Comportamento: si teletrasporta ogni 2-3 secondi in una posizione 
/// casuale vicino al player, lasciando una "scia glitch". 
/// Quando muore crea un flash di distorsione.
/// Spawn: dal wave 16, in gruppi di 1-3
class GlitchEnemy extends EnemyBase {
  double _teleportTimer = 2.0;
  double _glitchPhase = 0;
  double _flashTimer = 0; // Flash dopo teletrasporto
  bool _isTeleporting = false;
  double _teleportAnimTimer = 0;

  // Posizione precedente (per effetto scia)
  Vector2? _prevPosition;

  static final _random = math.Random();

  // Paint caches: evita alloc per frame × N glitch.
  static final Paint _ghostPaint = Paint();
  static final Paint _redPaint = Paint();
  static final Paint _bluePaint = Paint();
  static final Paint _scanPaint = Paint()..strokeWidth = 0.5;

  GlitchEnemy()
      : super(
          hp: 3,
          speed: 100, // Lento normalmente (si teletrasporta)
          pointValue: 10,
          geomValue: 4,
          neonColor: const Color(0xFF00EEFF), // Ciano elettrico
          size: Vector2(18, 18),
        );

  @override
  void updateBehavior(double dt) {
    _glitchPhase += dt * 12;

    // Animazione teletrasporto
    if (_isTeleporting) {
      _teleportAnimTimer -= dt;
      if (_teleportAnimTimer <= 0) {
        _isTeleporting = false;
      }
      return; // Non muoverti durante il teletrasporto
    }

    // Timer teletrasporto
    _teleportTimer -= dt;
    if (_teleportTimer <= 0) {
      _teleport();
      _teleportTimer = 1.5 + _random.nextDouble() * 2.0;
    }

    // Movimento lento verso il player tra un teletrasporto e l'altro
    final velocity = seekPlayer(speed);
    position += velocity * dt;

    if (_flashTimer > 0) _flashTimer -= dt;
  }

  void _teleport() {
    _prevPosition = position.clone();
    _isTeleporting = true;
    _teleportAnimTimer = 0.15;
    _flashTimer = 0.2;

    // Teletrasporto in posizione casuale vicino al player
    final angle = _random.nextDouble() * math.pi * 2;
    final dist = 100 + _random.nextDouble() * 200;
    final newPos = playerPosition + Vector2(
      math.cos(angle) * dist,
      math.sin(angle) * dist,
    );

    // Clamp all'arena
    if (game.isTunnelMode) {
      // Tunnel mode: clamp solo Y a tunnelHeight, X relativo alla camera
      final camX = game.camera.viewfinder.position.x;
      final camY = game.camera.viewfinder.position.y;
      final halfH = game.tunnelHeight / 2;
      final halfScreenW = game.size.x / 2;
      newPos.x = newPos.x.clamp(camX - halfScreenW, camX + halfScreenW + 200);
      newPos.y = newPos.y.clamp(camY - halfH + 20, camY + halfH - 20);
    } else {
      newPos.x = newPos.x.clamp(20, arenaWidth - 20);
      newPos.y = newPos.y.clamp(20, arenaHeight - 20);
    }

    position = newPos;

    // Grace post-teletrasporto (richiesta utente): per 2s il Glitch è
    // INATTACCABILE e NON danneggia il player. Riusa lo spawn-invuln di
    // EnemyBase → durante questi 2s il behavior è congelato (sta fermo dove si
    // materializza), `takeDamage` è no-op e `onCollisionStart` del player salta
    // il danno (isSpawnInvulnerable). Il render base lampeggia → telegrafo
    // chiaro che non è ancora "solido".
    setSpawnInvulnerability(2.0);

    // Distorci la griglia nel punto di arrivo
    if (!game.isTunnelMode) {
      game.grid.applyForce(position, 80, 300);
    }
    // E nel punto di partenza
    final prev = _prevPosition;
    if (prev != null && !game.isTunnelMode) {
      game.grid.applyForce(prev, 60, 200);
    }
  }

  @override
  void onDeath() {
    // Flash di distorsione alla morte
    if (!game.isTunnelMode) {
      game.grid.applyForce(position, 120, 600);
    }
    super.onDeath();
  }

  @override
  void renderShape(Canvas canvas, Paint paint, double scale) {
    final cx = size.x / 2;
    final cy = size.y / 2;
    final r = size.x / 2 * scale;

    // Effetto "scia glitch" dalla posizione precedente
    final prev = _prevPosition;
    if (prev != null && _flashTimer > 0) {
      final ghostAlpha = _flashTimer / 0.2;
      final ghostOffset = prev - position;
      _ghostPaint.color = neonColor.withValues(alpha: ghostAlpha * 0.15);
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset(cx + ghostOffset.x, cy + ghostOffset.y),
          width: r * 2,
          height: r * 2,
        ),
        _ghostPaint,
      );
    }

    // Effetto glitch: offset RGB casuali
    final glitchOffset = math.sin(_glitchPhase) * 2;

    // Canale rosso (spostato)
    if (_flashTimer > 0 || (_glitchPhase % 3).abs() < 0.3) {
      _redPaint.color = const Color(0xFFFF0000).withValues(alpha: 0.3);
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset(cx + glitchOffset, cy),
          width: r * 1.8,
          height: r * 1.8,
        ),
        _redPaint,
      );
    }

    // Canale blu (spostato dall'altra parte)
    if (_flashTimer > 0 || (_glitchPhase % 5).abs() < 0.3) {
      _bluePaint.color = const Color(0xFF0000FF).withValues(alpha: 0.3);
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset(cx - glitchOffset, cy),
          width: r * 1.8,
          height: r * 1.8,
        ),
        _bluePaint,
      );
    }

    // Forma principale: quadrato distorto
    final distortion = math.sin(_glitchPhase * 2) * 2;
    final path = Path()
      ..moveTo(cx - r + distortion, cy - r)
      ..lineTo(cx + r, cy - r + distortion)
      ..lineTo(cx + r - distortion, cy + r)
      ..lineTo(cx - r, cy + r - distortion)
      ..close();

    canvas.drawPath(path, paint);

    // Linee di "scan" orizzontali (effetto glitch)
    _scanPaint.color = const Color(0xFFFFFFFF).withValues(alpha: 0.15);
    final scanY = cy + ((_glitchPhase * 20) % (r * 2)) - r;
    canvas.drawLine(
      Offset(cx - r, scanY),
      Offset(cx + r, scanY),
      _scanPaint,
    );

    // Punto centrale luminoso
    if (_isTeleporting) {
      EnemyBase.detailPaint.color = const Color(0xFFFFFFFF).withValues(alpha: 0.4);
      canvas.drawCircle(Offset(cx, cy), r * 1.2, EnemyBase.detailPaint);
      EnemyBase.detailPaint.color = const Color(0xFFFFFFFF);
      canvas.drawCircle(Offset(cx, cy), r * 0.8, EnemyBase.detailPaint);
    }
  }
}
