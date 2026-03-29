import 'dart:math' as math;
import 'dart:ui';
import 'package:flame/components.dart';
import 'enemy_base.dart';

/// MUTATOR - Nemico che potenzia gli altri nemici al contatto.
/// Come in Geometry Wars: tocca i nemici e li rende pi aggressivi.
/// Forma: pentagono con aura pulsante
/// Colore: arancione/giallo (#FFAA00)
/// HP: 3 · Velocit media · NON attacca direttamente
/// Meccanica: si muove verso il nemico pi vicino (non il player).
///            Al contatto con un altro nemico: +80% speed, +50% HP, dimensione +20%.
///            Il nemico potenziato cambia colore (pi luminoso).
///            Priorit alta: va eliminato prima che potenzi l'intero sciame!
class MutatorEnemy extends EnemyBase {
  double _searchTimer = 0;
  EnemyBase? _target;
  double _pulsePhase = 0;
  int _mutationsCount = 0; // Quanti nemici ha potenziato
  bool _dead = false; // Guard per double-kill
  static const int _maxMutations = 8; // Si autodistrugge dopo 8 potenziamenti

  MutatorEnemy()
      : super(
          hp: 3,
          speed: 90,
          pointValue: 15,
          geomValue: 4,
          neonColor: const Color(0xFFFFAA00),
          size: Vector2(22, 22),
        );

  @override
  void updateBehavior(double dt) {
    _pulsePhase += dt * 5;
    _searchTimer -= dt;

    // Cerca il nemico pi vicino (non il player!) ogni 0.5s
    if (_searchTimer <= 0 || _target == null || _target!.isRemoved) {
      _searchTimer = 0.5;
      _target = _findNearestEnemy();
    }

    if (_target != null && !_target!.isRemoved) {
      // Muoviti verso il nemico target
      final toTarget = _target!.position - position;
      if (toTarget.length > 5) {
        position += toTarget.normalized() * speed * dt;
      }

      // Se vicino abbastanza, potenzia!
      if (toTarget.length < 25) {
        _mutateEnemy(_target!);
        _target = null;
        _searchTimer = 0; // Cerca subito il prossimo
      }
    } else {
      // Nessun nemico trovato: random walk lento
      final angle = math.sin(_pulsePhase * 0.3) * math.pi;
      position += Vector2(math.cos(angle), math.sin(angle)) * speed * 0.3 * dt;
    }

    // Autodistruzione dopo troppe mutazioni
    if (_mutationsCount >= _maxMutations && !_dead) {
      _dead = true;
      onDeath();
      return; // Non continuare dopo la morte
    }
  }

  @override
  void onDeath() {
    if (_dead) {
      // Già in fase di morte (autodistruzione) — evita double-kill
      super.onDeath();
      return;
    }
    _dead = true;
    super.onDeath();
  }

  EnemyBase? _findNearestEnemy() {
    EnemyBase? nearest;
    double nearestDist = double.infinity;
    for (final child in game.world.children) {
      if (child is EnemyBase && child != this && child is! MutatorEnemy) {
        // Non potenziare nemici già mutati (hanno colore giallo #FFDD44)
        if (child.neonColor == const Color(0xFFFFDD44)) continue;
        final dist = child.position.distanceTo(position);
        if (dist < 400 && dist < nearestDist) {
          nearestDist = dist;
          nearest = child;
        }
      }
    }
    return nearest;
  }

  void _mutateEnemy(EnemyBase enemy) {
    // Potenzia il nemico
    enemy.speed *= 1.8; // +80% velocit
    enemy.hp = (enemy.hp + enemy.maxHp * 0.5).clamp(0, enemy.maxHp * 3); // +50% HP
    enemy.maxHp = enemy.maxHp * 1.5;
    // Effetto visivo: colore più luminoso/giallo = "mutato"
    // (NO size change — in Flame il resize non aggiorna le hitbox a runtime)
    enemy.neonColor = const Color(0xFFFFDD44);

    // Effetto visivo esplosione piccola
    game.spawnExplosion(enemy.position, neonColor, radius: 20, particleCount: 6);

    _mutationsCount++;
  }

  @override
  void renderShape(Canvas canvas, Paint paint, double scale) {
    final cx = size.x / 2;
    final cy = size.y / 2;
    final r = size.x / 2 * scale;

    // Aura pulsante (raggio di ricerca)
    if (scale <= 1.01) {
      final auraPulse = 0.05 + math.sin(_pulsePhase) * 0.03;
      EnemyBase.detailPaint.color = neonColor.withValues(alpha: auraPulse);
      EnemyBase.detailPaint.style = PaintingStyle.stroke;
      EnemyBase.detailPaint.strokeWidth = 1;
      canvas.drawCircle(Offset(cx, cy), r * 3, EnemyBase.detailPaint);
      EnemyBase.detailPaint.style = PaintingStyle.fill;
    }

    // Pentagono rotante
    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(_pulsePhase * 0.5);

    final path = Path();
    for (int i = 0; i < 5; i++) {
      final angle = i * math.pi * 2 / 5 - math.pi / 2;
      final x = r * 0.85 * math.cos(angle);
      final y = r * 0.85 * math.sin(angle);
      if (i == 0) path.moveTo(x, y); else path.lineTo(x, y);
    }
    path.close();
    canvas.drawPath(path, paint);

    // Dettagli interni
    if (scale <= 1.01) {
      // Stella interna (linee dal centro ai vertici)
      final starPaint = Paint()
        ..color = paint.color.withValues(alpha: 0.3)
        ..strokeWidth = 0.8
        ..style = PaintingStyle.stroke;
      for (int i = 0; i < 5; i++) {
        final angle = i * math.pi * 2 / 5 - math.pi / 2;
        final x = r * 0.85 * math.cos(angle);
        final y = r * 0.85 * math.sin(angle);
        canvas.drawLine(Offset.zero, Offset(x, y), starPaint);
      }

      // Nucleo pulsante
      final corePulse = 0.5 + math.sin(_pulsePhase * 2) * 0.3;
      EnemyBase.detailPaint.color = const Color(0xFFFFFFFF).withValues(alpha: corePulse);
      canvas.drawCircle(Offset.zero, r * 0.25, EnemyBase.detailPaint);

      // Counter mutazioni (puntini attorno al nucleo)
      for (int i = 0; i < _mutationsCount; i++) {
        final dotAngle = i * math.pi * 2 / _maxMutations;
        final dx = r * 0.45 * math.cos(dotAngle);
        final dy = r * 0.45 * math.sin(dotAngle);
        EnemyBase.detailPaint.color = const Color(0xFFFFDD44).withValues(alpha: 0.7);
        canvas.drawCircle(Offset(dx, dy), 1.5, EnemyBase.detailPaint);
      }
    }

    canvas.restore();
  }
}
