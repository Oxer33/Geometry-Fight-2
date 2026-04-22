import 'dart:math' as math;
import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flutter/painting.dart' show HSVColor;
import '../../../data/constants.dart';
import 'enemy_base.dart';
import 'proton_enemy.dart';

class BlackHoleEnemy extends EnemyBase {
  static final _ringPaint = Paint()..style = PaintingStyle.stroke;
  static final _darkPaint = Paint();

  double _rotAngle = 0;
  int _absorbedCount = 0;
  bool _dead = false;
  bool _activated = false;
  // Flag: true quando il black hole muore per "absorbimento eccessivo".
  // Consolida le due vecchie death path (proton burst + onDeath da bullet)
  // in un unico flusso via `onDeath()`, evitando double-fire di onEnemyKilled.
  bool _protonsPending = false;

  static const int _protonThreshold = 7;

  // HP alto: con baseFireRate 8 e damageMultiplier ~1.0, servono ~3-5s di fuoco diretto
  BlackHoleEnemy()
      : super(
          hp: 35,
          speed: 0,
          pointValue: 30,
          geomValue: 10,
          neonColor: NeonColors.darkRed,
          size: Vector2(40, 40),
        );

  @override
  void takeDamage(double amount, {bool isArea = false}) {
    if (_dead) return;
    // Il primo colpo attiva il black hole
    if (!_activated) {
      _activated = true;
    }
    // Danno reale — ci vogliono 3-5 secondi per ucciderlo
    super.takeDamage(amount, isArea: isArea);
  }

  @override
  void updateBehavior(double dt) {
    // Dormant: statico. Attivo: ruota aggressivo.
    // Era `_activated ? 4 : 2` → sempre in movimento. Ora ruota solo dopo il
    // primo colpo, così si capisce che la gravità non è ancora attiva.
    _rotAngle += dt * (_activated ? 4 : 0);

    if (!_activated) return;

    // Attract nearby enemies (NOT player, NOT player bullets)
    final toAbsorb = <EnemyBase>[];
    for (final child in game.world.children) {
      if (child is EnemyBase && child != this) {
        // Black holes cannot absorb other black holes
        if (child is BlackHoleEnemy) continue;
        final toHole = position - child.position;
        // Raggio +50% (250→375) e forza +50% (60→90) — richiesta utente.
        if (toHole.length > 0 && toHole.length < 375) {
          child.position += toHole.normalized() * 90 * dt;
          if (toHole.length < 15) {
            toAbsorb.add(child);
          }
        }
      }
    }

    // Remove absorbed enemies outside the loop
    for (final enemy in toAbsorb) {
      enemy.removeFromParent();
      _absorbedCount++;
    }

    // Proton explosion after absorbing enough enemies — delega a `onDeath`
    // (entry point unico) per evitare doppia chiamata di `onEnemyKilled`.
    if (_absorbedCount >= _protonThreshold && !_dead) {
      _protonsPending = true;
      onDeath();
    }
  }

  @override
  void onDeath() {
    if (_dead) return;
    _dead = true;

    // Se dovuto a absorbimento eccessivo: spawn protoni prima della shockwave
    if (_protonsPending) {
      final protonCount = 8 + _absorbedCount;
      for (int i = 0; i < protonCount; i++) {
        final angle = i * math.pi * 2 / protonCount;
        final dir = Vector2(math.cos(angle), math.sin(angle));
        final proton = ProtonEnemy(direction: dir);
        proton.position = position + dir * 20;
        game.world.add(proton);
      }
    }

    // Shockwave condivisa: uccide nemici vicini + respinge player + FX
    _deathExplosion();

    // super.onDeath() di EnemyBase: gestisce _isDead, onEnemyKilled, removeFromParent
    super.onDeath();
  }

  /// Shockwave alla morte: uccide nemici entro 200px e respinge il player
  void _deathExplosion() {
    const killRadius = 200.0;
    const pushForce = 400.0;

    // Uccidi nemici vicini (non altri black hole)
    for (final child in List.from(game.world.children)) {
      if (child is EnemyBase && child != this && child is! BlackHoleEnemy) {
        final dist = child.position.distanceTo(position);
        if (dist < killRadius) {
          child.killSilently();
        }
      }
    }

    // Respingi il player
    final toPlayer = game.player.position - position;
    if (toPlayer.length > 0 && toPlayer.length < killRadius * 1.5) {
      final pushDir = toPlayer.normalized();
      game.player.position += pushDir * pushForce * (1.0 - toPlayer.length / (killRadius * 1.5));
    }

    // Mega esplosione visiva
    game.spawnExplosion(position, NeonColors.red, radius: 150, particleCount: 25, epic: true);
    game.triggerScreenShake(6, 0.3);
    if (!game.isTunnelMode) {
      game.grid.applyForce(position, 300, 2500);
    }
  }

  /// Colore che cicla nello spettro HSV — molto appariscente.
  /// Cache per bucket di 6° (60 bucket): ogni renderShape chiama 25+ volte
  /// → con la cache ricomputiamo solo al bucket-step invece che ogni call.
  static final Map<int, Color> _chromaCache = <int, Color>{};
  Color _chromaColor(double hueOffset) {
    final rawHue = (_rotAngle * 40 + hueOffset) % 360;
    final bucket = (rawHue / 6).floor() % 60; // 60 bucket totali
    final cached = _chromaCache[bucket];
    if (cached != null) return cached;
    final color = HSVColor.fromAHSV(1.0, bucket * 6.0, 1.0, 1.0).toColor();
    _chromaCache[bucket] = color;
    return color;
  }

  @override
  void renderShape(Canvas canvas, Paint paint, double scale) {
    final cx = size.x / 2;
    final cy = size.y / 2;
    final r = 18 * scale;
    final active = _activated;
    final pulse = math.sin(_rotAngle * 3);
    // Flash strobe quando attivo: on/off veloce sulle alpha dei layer esterni,
    // così il black hole "lampeggia" (richiesta user). Dormant = 1.0 fisso.
    final flashStrobe = active ? (math.sin(_rotAngle * 18) > 0 ? 1.0 : 0.35) : 1.0;

    // === ALONE CROMATICO ESTERNO (molto grande e luminoso) ===
    // 3 strati sovrapposti con hue sfasato → effetto arcobaleno rotante
    for (int layer = 0; layer < 3; layer++) {
      final layerR = r * (2.8 - layer * 0.4);
      final baseAlpha = active ? (0.20 - layer * 0.05 + pulse * 0.05) : (0.08 - layer * 0.02);
      final alpha = baseAlpha * flashStrobe;
      final c = _chromaColor(layer * 120.0);
      EnemyBase.detailPaint.color = c.withValues(alpha: alpha.clamp(0.0, 1.0));
      canvas.drawCircle(Offset(cx, cy), layerR, EnemyBase.detailPaint);
    }

    // === INDICATORE RAGGIO GRAVITAZIONALE (cerchio sottile, colore che cicla) ===
    if (scale <= 1.01 && active) {
      final indColor = _chromaColor(0);
      EnemyBase.detailPaint.color = indColor.withValues(alpha: 0.10);
      EnemyBase.detailPaint.style = PaintingStyle.stroke;
      EnemyBase.detailPaint.strokeWidth = 1.0;
      canvas.drawCircle(Offset(cx, cy), 150, EnemyBase.detailPaint);
      EnemyBase.detailPaint.style = PaintingStyle.fill;
    }

    // === ANELLI GRAVITAZIONALI ROTANTI (colore cromatico) ===
    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(_rotAngle);
    for (int i = 0; i < 6; i++) {
      final arcColor = _chromaColor(i * 60.0);
      _ringPaint.color = arcColor.withValues(alpha: active ? 0.7 : 0.3);
      _ringPaint.strokeWidth = (active ? 2.5 : 1.5) * scale;
      final angle = i * math.pi / 3;
      canvas.drawArc(
        Rect.fromCircle(center: Offset.zero, radius: r),
        angle, math.pi / 4, false, _ringPaint,
      );
    }
    canvas.restore();

    // === ANELLO INTERNO CONTRO-ROTANTE ===
    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(-_rotAngle * 1.8);
    for (int i = 0; i < 4; i++) {
      final arcColor = _chromaColor(i * 90.0 + 45);
      _ringPaint.color = arcColor.withValues(alpha: active ? 0.5 : 0.2);
      _ringPaint.strokeWidth = 1.5 * scale;
      final angle = i * math.pi / 2;
      canvas.drawArc(
        Rect.fromCircle(center: Offset.zero, radius: r * 0.65),
        angle, math.pi / 5, false, _ringPaint,
      );
    }
    canvas.restore();

    // === NUCLEO NERO con bordo cromatico pulsante ===
    _darkPaint.color = const Color(0xFF000000);
    canvas.drawCircle(Offset(cx, cy), r * 0.5, _darkPaint);
    final borderColor = _chromaColor(0);
    final borderAlpha = (0.6 + pulse * 0.3).clamp(0.0, 1.0);
    _ringPaint.color = borderColor.withValues(alpha: borderAlpha);
    _ringPaint.strokeWidth = active ? 2.5 : 1.5;
    canvas.drawCircle(Offset(cx, cy), r * 0.5, _ringPaint);

    // === PARTICELLE SPIRALANTI CROMATICHE ===
    if (scale <= 1.01) {
      final particleCount = active ? 12 : 6;
      for (int i = 0; i < particleCount; i++) {
        final pAngle = _rotAngle * 2.5 + i * math.pi * 2 / particleCount;
        final pDist = r * (0.6 + 0.4 * math.sin(_rotAngle * 1.5 + i * 0.7));
        final px = cx + pDist * math.cos(pAngle);
        final py = cy + pDist * math.sin(pAngle);
        final pColor = _chromaColor(i * (360.0 / particleCount));
        final pAlpha = active ? (0.4 + math.sin(_rotAngle * 4 + i) * 0.2) : 0.15;
        EnemyBase.detailPaint.color = pColor.withValues(alpha: pAlpha.clamp(0.0, 1.0));
        canvas.drawCircle(Offset(px, py), active ? 2.0 : 1.2, EnemyBase.detailPaint);
      }

      // Punto luminoso centrale — bianco brillante pulsante
      final coreAlpha = (0.7 + pulse * 0.3).clamp(0.0, 1.0);
      EnemyBase.detailPaint.color = Color.fromARGB((coreAlpha * 255).round(), 255, 255, 255);
      canvas.drawCircle(Offset(cx, cy), r * 0.2, EnemyBase.detailPaint);

      // Dormant: anello sottile che pulsa lentamente per segnalare pericolo latente
      if (!active) {
        final dormantColor = _chromaColor(0);
        EnemyBase.detailPaint.color = dormantColor.withValues(alpha: 0.12 + math.sin(_rotAngle * 2) * 0.06);
        EnemyBase.detailPaint.style = PaintingStyle.stroke;
        EnemyBase.detailPaint.strokeWidth = 1.0;
        canvas.drawCircle(Offset(cx, cy), r * 1.3, EnemyBase.detailPaint);
        EnemyBase.detailPaint.style = PaintingStyle.fill;
      }
    }

    paint.style = PaintingStyle.fill;
  }
}
