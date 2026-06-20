import 'dart:math' as math;
import 'dart:ui';
import 'package:flame/components.dart';
import '../../../data/wave_configs.dart';
import 'enemy_base.dart';

/// NECRO - Nemico necromante che resuscita i nemici morti vicini.
/// Forma: teschio stilizzato (cerchio con orbite oculari)
/// Colore: viola scuro (#8800AA)
/// Meccanica unica: quando un nemico muore nel suo raggio (200px),
/// dopo 3 secondi ne spawna uno nuovo dello stesso tipo ma con HP ridotti.
/// Va ucciso prima degli altri per evitare resurrezioni infinite!
class NecroEnemy extends EnemyBase {
  double _ritualPhase = 0;
  final List<_PendingResurrection> _pendingRes = [];
  // +50% raggio (richiesta utente: support mob 2× più efficaci). Era 200.
  static const double _resurrectionRadius = 300.0;

  // Paint caches: evita alloc per frame × N necro.
  static final Paint _ritualPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.5;
  static final Paint _cardinalPaint = Paint();
  static final Paint _eyePaint = Paint()..color = const Color(0xFF000000);
  static final Paint _mouthPaint = Paint()
    ..color = const Color(0xFF000000)
    ..strokeWidth = 1;

  @override
  void onDeath() {
    // Annulla resurrezioni pending e libera i dedupe key in modo che altri
    // necro possano ri-accodare se lo desiderano (anche se in pratica chi
    // ha la key è già morto).
    for (final r in _pendingRes) {
      _resurrectingIds.remove(r.dedupeKey);
    }
    _pendingRes.clear();
    super.onDeath();
  }

  NecroEnemy()
    : super(
        hp: 6,
        speed: 70,
        pointValue: 20,
        geomValue: 6,
        neonColor: const Color(0xFF8800AA),
        size: Vector2(24, 24),
      );

  @override
  void updateBehavior(double dt) {
    _ritualPhase += dt * 2;

    // Movimento lento - si mantiene a media distanza
    final dist = distanceToPlayer;
    if (dist > 350) {
      position += seekPlayer(speed) * dt;
    } else if (dist < 200 && dist > 0.001) {
      // NaN guard: se coincide col player, skip (evita NaN normalize).
      final awayDir = (position - playerPosition).normalized();
      position += awayDir * speed * 0.5 * dt;
    }

    // Processa resurrezioni pending
    for (int i = _pendingRes.length - 1; i >= 0; i--) {
      _pendingRes[i].timer -= dt;
      if (_pendingRes[i].timer <= 0) {
        // Resuscita il nemico — in-game spawn, no warning di 4s
        final resurrected = game.spawnEnemy(
          _pendingRes[i].type,
          _pendingRes[i].position,
        );
        resurrected?.clearSpawnInvulnerability();
        _resurrectingIds.remove(_pendingRes[i].dedupeKey);
        _pendingRes.removeAt(i);
      }
    }

    // Controlla nemici morti vicini (tramite il game world)
    // Questo viene gestito dal game_world.onEnemyKilled chiamando notifyNecros
  }

  // Dedupe globale: se due Necro vedono la stessa morte, solo il primo
  // accoda la resurrezione. Key = (type, posX rounded, posY rounded) — preciso
  // abbastanza per identificare una death (mob fermo nel frame della morte)
  // senza essere fragile a micro-jitter di Vector2.
  static final Set<int> _resurrectingIds = <int>{};

  /// Reset stato statico per nuova partita (chiamato da restartGame).
  /// Azzera il dedupe globale delle resurrezioni: senza questo, le key
  /// accodate da necro della run precedente sopravvivono al restart e
  /// possono bloccare resurrezioni legittime nella nuova sessione.
  static void resetStaticState() {
    _resurrectingIds.clear();
  }

  static int _deathKey(EnemyType type, Vector2 pos) {
    return Object.hash(type, pos.x.round(), pos.y.round());
  }

  /// Chiamato quando un nemico muore vicino al necro
  void onNearbyEnemyDeath(EnemyType type, Vector2 deathPos) {
    // Guard: se il necro è già morto (rimozione pendente, cache non ancora
    // aggiornata), ignora la richiesta per evitare leak in _resurrectingIds.
    if (isRemoved) return;
    final dist = position.distanceTo(deathPos);
    // 2× più efficace (richiesta utente): max pending 3→6, resurrezione 3s→1.5s.
    if (dist < _resurrectionRadius && _pendingRes.length < 6) {
      final key = _deathKey(type, deathPos);
      if (_resurrectingIds.contains(key)) return; // un altro necro già accodato
      _resurrectingIds.add(key);
      _pendingRes.add(
        _PendingResurrection(
          type: type,
          position: deathPos,
          timer: 1.5,
          dedupeKey: key,
        ),
      );
    }
  }

  @override
  void renderShape(Canvas canvas, Paint paint, double scale) {
    final cx = size.x / 2;
    final cy = size.y / 2;
    final r = size.x / 2 * scale;

    // Cerchio ritualistico esterno (solo principale)
    if (scale <= 1.01) {
      _ritualPaint.color = neonColor.withValues(alpha: 0.15);
      canvas.save();
      canvas.translate(cx, cy);
      canvas.rotate(_ritualPhase * 0.3);
      // Cerchio con simboli
      canvas.drawCircle(Offset.zero, r * 1.5, _ritualPaint);
      // Punti cardinali
      _cardinalPaint.color = neonColor.withValues(alpha: 0.3);
      for (int i = 0; i < 4; i++) {
        final angle = i * math.pi / 2;
        final px = r * 1.5 * math.cos(angle);
        final py = r * 1.5 * math.sin(angle);
        canvas.drawCircle(Offset(px, py), 1.5, _cardinalPaint);
      }
      canvas.restore();

      // Indicatori resurrezioni pending — senza blur
      for (int i = 0; i < _pendingRes.length; i++) {
        final offset = _pendingRes[i].position - position;
        EnemyBase.detailPaint.color = neonColor.withValues(alpha: 0.2);
        canvas.drawCircle(
          Offset(cx + offset.x, cy + offset.y),
          8,
          EnemyBase.detailPaint,
        );
        EnemyBase.detailPaint.color = neonColor.withValues(alpha: 0.5);
        canvas.drawCircle(
          Offset(cx + offset.x, cy + offset.y),
          5,
          EnemyBase.detailPaint,
        );
      }
    }

    // Teschio: cerchio principale
    canvas.drawCircle(Offset(cx, cy), r * 0.7, paint);

    // Dettagli teschio (solo layer principale)
    if (scale <= 1.01) {
      // Occhi
      canvas.drawCircle(
        Offset(cx - r * 0.25, cy - r * 0.1),
        r * 0.15,
        _eyePaint,
      );
      canvas.drawCircle(
        Offset(cx + r * 0.25, cy - r * 0.1),
        r * 0.15,
        _eyePaint,
      );
      // Pupille luminose
      final pupilGlow = 0.5 + math.sin(_ritualPhase * 3) * 0.5;
      EnemyBase.detailPaint.color = neonColor.withValues(alpha: pupilGlow);
      canvas.drawCircle(
        Offset(cx - r * 0.25, cy - r * 0.1),
        r * 0.08,
        EnemyBase.detailPaint,
      );
      canvas.drawCircle(
        Offset(cx + r * 0.25, cy - r * 0.1),
        r * 0.08,
        EnemyBase.detailPaint,
      );
      // Bocca (linea)
      canvas.drawLine(
        Offset(cx - r * 0.2, cy + r * 0.25),
        Offset(cx + r * 0.2, cy + r * 0.25),
        _mouthPaint,
      );
    }
  }
}

class _PendingResurrection {
  final EnemyType type;
  final Vector2 position;
  double timer;
  final int dedupeKey;

  _PendingResurrection({
    required this.type,
    required this.position,
    required this.timer,
    required this.dedupeKey,
  });
}
