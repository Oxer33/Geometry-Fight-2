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

    // Autodistruzione dopo troppe mutazioni — delega a super.onDeath() che ha
    // già il guard `_isDead` interno (EnemyBase), evita double-kill.
    if (_mutationsCount >= _maxMutations) {
      onDeath();
      return;
    }
  }

  @override
  void onDeath() {
    // EnemyBase.onDeath() ha già il guard `_isDead` → safe contro double-fire.
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
    // Fix ordine: bump maxHp PRIMA del clamp, altrimenti hp > maxHp
    // → HP bar mostra >100%. +50% HP relativo al vecchio maxHp.
    final bonusHp = enemy.maxHp * 0.5;
    enemy.maxHp = enemy.maxHp * 1.5;
    enemy.hp = (enemy.hp + bonusHp).clamp(0, enemy.maxHp);
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

    // Aura pulsante con archi rotanti (raggio di ricerca)
    if (scale <= 1.01) {
      final auraPulse = 0.05 + math.sin(_pulsePhase) * 0.03;
      EnemyBase.detailPaint.color = neonColor.withValues(alpha: auraPulse);
      EnemyBase.detailPaint.style = PaintingStyle.stroke;
      EnemyBase.detailPaint.strokeWidth = 0.8;
      // 3 archi rotanti invece di cerchio pieno
      final auraRect = Rect.fromCircle(center: Offset(cx, cy), radius: r * 2.5);
      for (int i = 0; i < 3; i++) {
        final arcStart = _pulsePhase * 0.8 + i * math.pi * 2 / 3;
        canvas.drawArc(auraRect, arcStart, math.pi * 0.5, false, EnemyBase.detailPaint);
      }
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
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);

    if (scale <= 1.01) {
      // Pentagramma interno (stella a 5 punte connettendo vertici non adiacenti)
      EnemyBase.detailPaint.color = paint.color.withValues(alpha: 0.25);
      EnemyBase.detailPaint.strokeWidth = 0.7;
      EnemyBase.detailPaint.style = PaintingStyle.stroke;
      for (int i = 0; i < 5; i++) {
        final angle1 = i * math.pi * 2 / 5 - math.pi / 2;
        final angle2 = ((i + 2) % 5) * math.pi * 2 / 5 - math.pi / 2;
        final x1 = r * 0.75 * math.cos(angle1);
        final y1 = r * 0.75 * math.sin(angle1);
        final x2 = r * 0.75 * math.cos(angle2);
        final y2 = r * 0.75 * math.sin(angle2);
        canvas.drawLine(Offset(x1, y1), Offset(x2, y2), EnemyBase.detailPaint);
      }

      // Pentagono interno piccolo (formato dall'intersezione del pentagramma)
      final innerPentPath = Path();
      for (int i = 0; i < 5; i++) {
        final angle = i * math.pi * 2 / 5 - math.pi / 2 + math.pi / 5;
        final x = r * 0.33 * math.cos(angle);
        final y = r * 0.33 * math.sin(angle);
        if (i == 0) {
          innerPentPath.moveTo(x, y);
        } else {
          innerPentPath.lineTo(x, y);
        }
      }
      innerPentPath.close();
      EnemyBase.detailPaint.color = paint.color.withValues(alpha: 0.2);
      EnemyBase.detailPaint.strokeWidth = 0.5;
      canvas.drawPath(innerPentPath, EnemyBase.detailPaint);
      EnemyBase.detailPaint.style = PaintingStyle.fill;

      // Nucleo pulsante
      final corePulse = 0.5 + math.sin(_pulsePhase * 2) * 0.3;
      EnemyBase.detailPaint.color = const Color(0xFFFFFFFF).withValues(alpha: corePulse);
      canvas.drawCircle(Offset.zero, r * 0.18, EnemyBase.detailPaint);

      // Counter mutazioni (puntini orbitanti con glow progressivo)
      for (int i = 0; i < _mutationsCount; i++) {
        final dotAngle = i * math.pi * 2 / _maxMutations + _pulsePhase * 0.3;
        final dx = r * 0.5 * math.cos(dotAngle);
        final dy = r * 0.5 * math.sin(dotAngle);
        final dotPulse = 0.5 + math.sin(_pulsePhase * 3 + i) * 0.3;
        EnemyBase.detailPaint.color = const Color(0xFFFFDD44).withValues(alpha: dotPulse);
        canvas.drawCircle(Offset(dx, dy), 1.5, EnemyBase.detailPaint);
      }

      // 5 nodi energetici sui vertici
      for (int i = 0; i < 5; i++) {
        final angle = i * math.pi * 2 / 5 - math.pi / 2;
        final nx = r * 0.75 * math.cos(angle);
        final ny = r * 0.75 * math.sin(angle);
        final nodePulse = 0.2 + math.sin(_pulsePhase * 4 + i * 1.2) * 0.2;
        EnemyBase.detailPaint.color = paint.color.withValues(alpha: nodePulse);
        canvas.drawCircle(Offset(nx, ny), 1.0, EnemyBase.detailPaint);
      }
    }

    canvas.restore();
  }
}
