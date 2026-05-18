import 'dart:math' as math;
import 'dart:ui';
import 'package:flame/components.dart';
import '../game_world.dart';
import '../entities/enemies/enemy_base.dart';

/// Iter 14 (utente): Gauss Implosion — esplosione "imploding" applicata sul
/// punto di impatto del proiettile Gauss. Dura 2s, attira tutti i nemici
/// (non boss) entro 250px verso l'epicentro e applica tick damage ai nemici
/// vicinissimi all'epicentro.
///
/// Sostituisce il vecchio `_gaussPull` player-centric: la trazione ora
/// appartiene al punto di impatto, non al player. Mantiene boss esclusi
/// dal pull (caveman: pull disturbava AI pattern boss).
class GaussImplosion extends PositionComponent
    with HasGameReference<GeometryFightGame> {
  static const double duration = 2.0;
  // Iter 15 (utente: "esplosione 1/4 size"): scaled da 250/60 → 62.5/15.
  // Stessa intensità DoT (5/tick × 0.1s × 2s = 100 max) ma in area
  // più concentrata (706px² vs 11310px²) → premia mira precisa.
  static const double pullRadius = 62.5;
  static const double pullSpeed = 400.0;
  static const double damageRadius = 15.0;
  static const double damageTickInterval = 0.1;
  static const double damagePerTick = 5.0;

  final Vector2 epicenter;
  double _age = 0;
  double _tickTimer = 0;

  final Paint _ringGlowPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 6;
  final Paint _ringBodyPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.5;
  final Paint _corePaint = Paint();

  GaussImplosion({required this.epicenter})
      : super(position: epicenter.clone(), anchor: Anchor.center);

  @override
  void update(double dt) {
    super.update(dt);
    // Implosion NON affetta dal slow-motion: compensa il timeScale per
    // mantenere durata reale di 2s indipendentemente da bomb-freeze.
    final realDt = dt / game.timeScale.clamp(0.3, 1.0);
    _age += realDt;
    if (_age >= duration) {
      removeFromParent();
      return;
    }

    // Pull tutti i nemici (no boss) entro pullRadius verso epicentro.
    // Skip nemici già morti (`isRemoved`): Flame può tenerli in `children`
    // per un frame dopo `removeFromParent()` → evitiamo di muoverli/danneggiarli.
    for (final child in game.world.children) {
      if (child is! EnemyBase) continue;
      if (child.isRemoved) continue;
      if (child.isSpawnInvulnerable) continue;
      final delta = epicenter - child.position;
      final d = delta.length;
      if (d > 1 && d < pullRadius) {
        child.position += delta.normalized() * pullSpeed * realDt;
      }
    }

    // Tick damage ogni 0.1s ai nemici entro damageRadius dall'epicentro.
    _tickTimer += realDt;
    if (_tickTimer >= damageTickInterval) {
      _tickTimer -= damageTickInterval;
      for (final child in game.world.children) {
        if (child is! EnemyBase) continue;
        if (child.isRemoved) continue;
        if (child.isSpawnInvulnerable) continue;
        if (child.position.distanceTo(epicenter) < damageRadius) {
          child.takeDamage(damagePerTick, isArea: true);
        }
      }
    }
  }

  @override
  void render(Canvas canvas) {
    final t = (_age / duration).clamp(0.0, 1.0);
    // Alpha curva: forte all'inizio, fade a fine.
    final alpha = (1.0 - t * 0.6).clamp(0.0, 1.0);

    // Core "nucleo" pulsante al centro: gradient cyan→viola luminoso.
    final pulse = 0.7 + math.sin(_age * 18) * 0.3;
    // Iter 15: base 28→7, ampiezza oscillazione 6→1.5 (scale 0.25).
    // Moltiplicatori `* 1.8` e `* 0.4` (sotto) restano invariati.
    final coreR = (7 + math.sin(_age * 10) * 1.5) * (0.6 + 0.4 * (1 - t));
    _corePaint.color =
        const Color(0xFF66DDFF).withValues(alpha: 0.45 * alpha * pulse);
    canvas.drawCircle(Offset.zero, coreR * 1.8, _corePaint);
    _corePaint.color =
        const Color(0xFFCC66FF).withValues(alpha: 0.75 * alpha * pulse);
    canvas.drawCircle(Offset.zero, coreR, _corePaint);
    _corePaint.color =
        const Color(0xFFFFFFFF).withValues(alpha: 0.9 * alpha * pulse);
    canvas.drawCircle(Offset.zero, coreR * 0.4, _corePaint);

    // 4 anelli concentrici che si rimpiccioliscono verso il centro durante
    // i 2s. Ogni anello ha un offset di fase → wave continua di anelli che
    // implodono. Colore gradient cyan→purple a seconda del raggio.
    const ringCount = 4;
    for (int i = 0; i < ringCount; i++) {
      // Phase offset: ogni anello parte sfasato, ciclo continuo.
      final phase = ((_age + i * (duration / ringCount)) / duration) % 1.0;
      // Raggio shrink: parte da pullRadius e va a 0 lungo la durata del ciclo.
      final ringR = pullRadius * (1.0 - phase);
      if (ringR < 4) continue;
      // Colore: outer = cyan, inner = purple. Lerp manuale.
      const cyanCol = Color(0xFF44DDFF);
      const purpleCol = Color(0xFFCC66FF);
      final ringT = (1 - phase).clamp(0.0, 1.0);
      final col = Color.lerp(cyanCol, purpleCol, ringT) ?? cyanCol;
      final ringAlpha = (alpha * (0.9 - phase * 0.4)).clamp(0.0, 1.0);

      _ringGlowPaint.color = col.withValues(alpha: 0.35 * ringAlpha);
      _ringGlowPaint.strokeWidth = 6 + (1 - phase) * 4;
      canvas.drawCircle(Offset.zero, ringR, _ringGlowPaint);
      _ringBodyPaint.color = col.withValues(alpha: 0.95 * ringAlpha);
      _ringBodyPaint.strokeWidth = 2 + (1 - phase) * 1.5;
      canvas.drawCircle(Offset.zero, ringR, _ringBodyPaint);
    }
  }
}
