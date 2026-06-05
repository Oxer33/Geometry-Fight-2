import 'dart:math' as math;
import 'dart:ui';
import 'package:flame/collisions.dart';
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

  TimeBombEnemy()
      : super(
          hp: 4,
          speed: 90,
          pointValue: 12,
          geomValue: 4,
          neonColor: const Color(0xFFFF6600),
          // Bump 24→30: bomba più massiccia e leggibile (richiesta utente
          // "disegnamolo molto più figo"). Component = size*2 = 60px, raggio
          // scocca/hitbox = 30px.
          size: Vector2(30, 30),
        );

  @override
  Future<void> onLoad() async {
    // Hitbox = corpo visibile (scocca), così "coincide con la grandezza del
    // corpo" (richiesta utente). Sostituisce la hitbox base di EnemyBase: il
    // bug era che il glow-pass ridisegnava il body OPACO a scale 1.3 → disco
    // visibile (~r39) più grande della hitbox (r24). Ora il body solido è
    // disegnato a r=size/2 e la hitbox lo ricalca (*1.05 copre la base delle
    // punte → tutta la silhouette è colpibile).
    add(
      CircleHitbox(radius: size.x / 2 * 1.05, anchor: Anchor.center)
        ..position = size / 2,
    );
  }

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

  // Colori scocca metallica (riusati, niente alloc per frame).
  static const Color _spikeMetal = Color(0xFF6B7280); // acciaio grigio
  static const Color _casingDark = Color(0xFF14161F); // scocca scura
  static const Color _white = Color(0xFFFFFFFF);

  @override
  void renderShape(Canvas canvas, Paint paint, double scale) {
    final cx = size.x / 2;
    final cy = size.y / 2;
    final baseR = size.x / 2 * scale;

    // urgency 0→1 mentre il countdown va da 8 → 0.
    final urgency = 1.0 - (_countdown / 8.0).clamp(0.0, 1.0);

    // === Color logic (countdown) ===
    // [8..2]s: lerp arancio → rosso. [2..0]s: lampeggio rosso ↔ giallo.
    final Color bodyColor;
    if (_countdown > 2) {
      final t = ((8.0 - _countdown) / 6.0).clamp(0.0, 1.0);
      bodyColor =
          Color.lerp(const Color(0xFFFF6600), const Color(0xFFFF0000), t)!;
    } else {
      final flash = (idlePhase * 8).toInt() % 2 == 0;
      bodyColor = flash ? const Color(0xFFFF0000) : const Color(0xFFFFEE00);
    }

    // === GLOW PASS (scale ~1.3): alone morbido TRASPARENTE ===
    // FIX hitbox-mismatch: prima qui il corpo veniva ridisegnato OPACO a
    // scale 1.3 → disco visibile più grande della hitbox. Ora è solo un alone
    // fioco; il corpo solido (main pass) coincide con la hitbox.
    if (scale > 1.1) {
      _bodyPaint
        ..color = bodyColor.withValues(alpha: 0.16)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(cx, cy), baseR * 0.92, _bodyPaint);
      return;
    }

    // === Radius pulse (<1s): oscillazione radiale ±18% ===
    var r = baseR;
    if (_countdown < 1.0 && _activated) {
      r = baseR * (1.0 + 0.18 * math.sin(idlePhase * 10 * math.pi));
    }

    // === PUNTE (mina navale): unica Path per 8 spine, un solo drawPath ===
    const spikeCount = 8;
    final spikeBase = r * 0.86;
    final spikeTip = r * 1.34;
    const halfW = 0.18; // mezza ampiezza angolare base punta (rad)
    final spin = idlePhase * 0.5; // lenta rotazione → look "armato"
    final spikes = Path();
    for (var i = 0; i < spikeCount; i++) {
      final a = (i / spikeCount) * math.pi * 2 + spin;
      spikes
        ..moveTo(cx + math.cos(a - halfW) * spikeBase,
            cy + math.sin(a - halfW) * spikeBase)
        ..lineTo(cx + math.cos(a) * spikeTip, cy + math.sin(a) * spikeTip)
        ..lineTo(cx + math.cos(a + halfW) * spikeBase,
            cy + math.sin(a + halfW) * spikeBase)
        ..close();
    }
    _bodyPaint
      ..color = _spikeMetal
      ..style = PaintingStyle.fill;
    canvas.drawPath(spikes, _bodyPaint);
    _ringPaint
      ..color = bodyColor.withValues(alpha: 0.9)
      ..strokeWidth = 1.2;
    canvas.drawPath(spikes, _ringPaint); // bordo neon sulle punte

    // === SCOCCA (corpo solido = hitbox) ===
    _bodyPaint
      ..color = _casingDark
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx, cy), r, _bodyPaint);
    _ringPaint
      ..color = bodyColor
      ..strokeWidth = 2.5;
    canvas.drawCircle(Offset(cx, cy), r, _ringPaint); // anello neon di bordo

    // === CORE pulsante (innesco) ===
    final corePulse = 1.0 + 0.15 * math.sin(idlePhase * 6 + urgency * 6);
    final coreR = r * (0.34 + 0.10 * urgency) * corePulse;
    _bodyPaint.color = bodyColor;
    canvas.drawCircle(Offset(cx, cy), coreR, _bodyPaint);
    _bodyPaint.color = Color.lerp(_white, bodyColor, 0.25)!;
    canvas.drawCircle(Offset(cx, cy), coreR * 0.45, _bodyPaint); // punto caldo

    // === Dettagli costosi: solo high-detail (swarm li salta per perf) ===
    if (scale <= 1.01) {
      // Rivetti (4) sulla scocca.
      _bodyPaint.color = bodyColor.withValues(alpha: 0.85);
      for (var i = 0; i < 4; i++) {
        final a = (i / 4) * math.pi * 2 + math.pi / 4 + spin;
        canvas.drawCircle(
          Offset(cx + math.cos(a) * r * 0.66, cy + math.sin(a) * r * 0.66),
          1.6,
          _bodyPaint,
        );
      }

      // Scudo attivazione (immune 2s): anello ciano che si dissolve.
      if (!_activated) {
        final shieldAlpha = (_activationTimer / 2.0).clamp(0.0, 1.0);
        EnemyBase.detailPaint
          ..color = const Color(0xFF4488FF).withValues(alpha: shieldAlpha * 0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;
        canvas.drawCircle(Offset(cx, cy), r * 1.45, EnemyBase.detailPaint);
      }

      // Anelli di pericolo (countdown < 4s). <2s: più anelli, più ampi e vivi.
      if (_activated && _countdown < 4) {
        final lateStage = _countdown < 2.0;
        final ringCount = lateStage ? 4 : 2;
        final ampMul = lateStage ? 0.6 : 0.3;
        final brightnessBoost = lateStage ? 0.7 : 0.3;
        _ringPaint.strokeWidth = 1;
        for (var i = 0; i < ringCount; i++) {
          final ringProgress = (idlePhase * 2 + i / ringCount) % 1.0;
          final ringR = r * 1.5 + ringProgress * _explosionRadius * ampMul;
          final ringAlpha =
              ((1 - ringProgress) * urgency * brightnessBoost).clamp(0.0, 1.0);
          _ringPaint.color =
              const Color(0xFFFF0000).withValues(alpha: ringAlpha);
          canvas.drawCircle(Offset(cx, cy), ringR, _ringPaint);
        }
      }
    }
  }
}
