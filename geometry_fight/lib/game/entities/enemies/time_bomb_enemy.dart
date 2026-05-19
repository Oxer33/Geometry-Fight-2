import 'dart:math' as math;
import 'dart:ui';
import 'package:flame/components.dart';
import '../../../data/constants.dart';
import 'enemy_base.dart';

/// TIME BOMB - Nemico con countdown silenzioso (no numeri) che esplode in
/// area enorme.
/// Forma: cerchio con anelli di pericolo. Il countdown è comunicato solo da:
///   - Colore: arancio (#FF6600) → rosso (#FF0000) da 8s a 2s.
///   - <2s: alterna rosso vivo / giallo vivo + ampia oscillazione radiale.
///   - <1s: pulsazione radiale ±25%.
///   - <2s: outer ring più numerosi e luminosi.
/// Meccanica: ha un timer di 8 secondi. Quando esplode, danno area 200px.
/// Se il player lo uccide prima, dropa power-up.
/// Immune ai proiettili per i primi 2 secondi (scudo di attivazione).
///
/// Snake mode interaction (INTENT preservato): la fase immune blocca anche
/// il trail-kill (`SnakeTrailSegment.onCollisionStart` chiama `takeDamage`
/// che fa early-return finché `_activated == false`). Il giocatore deve
/// quindi aspettare ~2s prima che la propria scia possa demolire un
/// TimeBomb. Trade-off voluto: TimeBomb è il principale "filler" del pool
/// daily-challenge/snake e senza la finestra di immunità verrebbe annullato
/// dalla scia ancor prima di mostrare i suoi anelli di pericolo, perdendo
/// la sua identità visiva. Mantenuto come da design, NON un bug.
class TimeBombEnemy extends EnemyBase {
  double _countdown = 8.0;
  static const double _explosionRadius = 200.0;
  bool _activated = false;
  double _activationTimer = 2.0;
  bool _dead = false;

  // Paint caches: evita alloc per frame × N time-bomb.
  static final Paint _bodyPaint = Paint();
  static final Paint _ringPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1;
  static final Paint _lockPaint = Paint()
    ..color = const Color(0xFF4488FF).withValues(alpha: 0.6);

  TimeBombEnemy()
      : super(
          hp: 4,
          speed: 90,
          pointValue: 12,
          geomValue: 4,
          neonColor: const Color(0xFFFF6600),
          size: Vector2(24, 24),
        );

  @override
  void updateBehavior(double dt) {
    // Re-entry guard: removeFromParent() è deferred a end-of-frame, quindi
    // se Flame interna schedula un update prima del flush (raro ma possibile
    // su frame con removal queue grande), evitiamo doppio explode/movimento.
    if (_dead) return;

    // Fase attivazione (immune per 2s)
    if (!_activated) {
      _activationTimer -= dt;
      if (_activationTimer <= 0) _activated = true;
      // Si avvicina lentamente
      position += seekPlayer(speed * 0.5) * dt;
      return;
    }

    // Si avvicina al player
    position += seekPlayer(speed) * dt;

    // Countdown — clamp inferiore a 0 per evitare valori negativi visibili
    // in render (urgency lerp e ring math sono già clamped ma teniamo la
    // variabile stessa pulita per debug/log).
    _countdown -= dt;
    if (_countdown <= 0) {
      _countdown = 0;
      _explode();
    }
  }

  @override
  void takeDamage(double amount, {bool isArea = false}) {
    if (!_activated) return; // Immune durante attivazione
    super.takeDamage(amount, isArea: isArea);
  }

  void _explode() {
    if (_dead) return;
    _dead = true;
    // Danno area al player
    if (distanceToPlayer < _explosionRadius) {
      game.player.takeDamage();
    }
    // Esplosione enorme
    game.spawnExplosion(position, neonColor, radius: _explosionRadius, particleCount: 40);
    if (!game.isTunnelMode) {
      game.grid.applyForce(position, _explosionRadius * 1.5, 1500);
    }
    game.triggerScreenShake(8, 0.4);
    // Direct cleanup invece di super.onDeath() per evitare la seconda
    // esplosione standard di EnemyBase.onDeath() (abbiamo già spawnato la
    // mega-esplosione area sopra). Local `_dead` previene re-entry; chiamata
    // a `onEnemyKilled` + `removeFromParent()` replica gli effetti collaterali
    // critici di EnemyBase.onDeath senza il secondo spawnExplosion.
    game.onEnemyKilled(this);
    removeFromParent();
  }

  @override
  void onDeath() {
    if (_dead) return;
    _dead = true;
    // Ucciso dal player: no esplosione area, drop power-up garantito
    game.spawnPowerUp(position);
    game.spawnExplosion(position, NeonColors.green, radius: 30, particleCount: 15);
    // super.onDeath gestisce _isDead + game.onEnemyKilled(this) + removeFromParent.
    super.onDeath();
  }

  @override
  void renderShape(Canvas canvas, Paint paint, double scale) {
    final cx = size.x / 2;
    final cy = size.y / 2;
    final baseR = size.x / 2 * scale;

    // urgency 0→1 mentre il countdown va da 8 → 0.
    final urgency = 1.0 - (_countdown / 8.0).clamp(0.0, 1.0);

    // === Color logic ===
    // [8..2]s: lerp arancio → rosso (mappato su 0..1 sul range 8-2 = 6s).
    // [2..0]s: alterna rosso vivo + giallo vivo a frequenza alta.
    Color bodyColor;
    if (_countdown > 2) {
      // Mappa 8→0 e 2→1 nel sotto-intervallo lerp (6s di range).
      final t = ((8.0 - _countdown) / 6.0).clamp(0.0, 1.0);
      bodyColor = Color.lerp(
        const Color(0xFFFF6600),
        const Color(0xFFFF0000),
        t,
      )!;
    } else {
      // Pulsing brillante: rosso vivo ↔ giallo vivo. Frequenza alta (~8Hz).
      final flash = (idlePhase * 8).toInt() % 2 == 0;
      bodyColor = flash ? const Color(0xFFFF0000) : const Color(0xFFFFEE00);
    }

    // === Radius pulse ===
    // Sotto 1s: ±25% body radius pulse (sin a ~10Hz tramite idlePhase).
    double r = baseR;
    if (_countdown < 1.0 && _activated) {
      final pulse = math.sin(idlePhase * 10 * math.pi);
      r = baseR * (1.0 + 0.25 * pulse);
    }

    // Cerchio principale
    _bodyPaint.color = bodyColor;
    canvas.drawCircle(Offset(cx, cy), r, _bodyPaint);

    if (scale <= 1.01) {
      // Scudo attivazione (se non ancora attivato) — INVARIATO.
      if (!_activated) {
        final shieldAlpha = (_activationTimer / 2.0).clamp(0.0, 1.0);
        EnemyBase.detailPaint.color = const Color(0xFF4488FF).withValues(alpha: shieldAlpha * 0.4);
        EnemyBase.detailPaint.style = PaintingStyle.stroke;
        EnemyBase.detailPaint.strokeWidth = 2;
        canvas.drawCircle(Offset(cx, cy), baseR * 1.3, EnemyBase.detailPaint);

        // Icona scudo durante attivazione (piccolo disco ciano centrale).
        canvas.drawCircle(Offset(cx, cy), baseR * 0.3, _lockPaint);
      }

      // Anelli di pericolo (appaiono quando countdown < 4s).
      // <2s: ring count raddoppia (4 invece di 2), ampiezza oscillazione
      // raddoppia (0.6 vs 0.3) e alpha aumenta (0.7 vs 0.3 base brightness).
      if (_activated && _countdown < 4) {
        final lateStage = _countdown < 2.0;
        final ringCount = lateStage ? 4 : 2;
        final ampMul = lateStage ? 0.6 : 0.3;
        final brightnessBoost = lateStage ? 0.7 : 0.3;
        for (int i = 0; i < ringCount; i++) {
          final ringProgress = ((idlePhase * 2 + i / ringCount) % 1.0);
          final ringR = r * 1.5 + ringProgress * _explosionRadius * ampMul;
          final ringAlpha =
              ((1 - ringProgress) * urgency * brightnessBoost).clamp(0.0, 1.0);
          _ringPaint.color = const Color(0xFFFF0000).withValues(alpha: ringAlpha);
          canvas.drawCircle(Offset(cx, cy), ringR, _ringPaint);
        }
      }
    }
  }
}
