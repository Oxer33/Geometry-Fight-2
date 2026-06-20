import 'dart:math' as math;
import 'dart:ui';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import '../../data/constants.dart';
import '../../data/wave_configs.dart';
import '../game_world.dart';
import 'player.dart';

class Geom extends PositionComponent
    with HasGameReference<GeometryFightGame>, CollisionCallbacks {
  final int value;
  double _lifetime = geomLifetime;
  double _phase = 0;
  bool _attracted = false;

  static final _random = math.Random();
  late Color _color;
  late double _rotationSpeed;
  // Per-instance alpha→color cache for the diamond body. `_color` is fixed for
  // the life of the geom (depends only on `value`), so the rendered color is a
  // pure function of the quantized alpha. Cache (lastAlphaKey, lastColor) and
  // recompute withValues only when the quantized key changes; during the steady
  // alpha==1.0 phase reuse the already-opaque `_color` directly (NeonColors are
  // 0xFF.. so withValues(alpha:1.0) is bit-identical). Quantized to 256 steps
  // → max delta 1/256, visually imperceptible.
  static const int _alphaSteps = 256;
  int _lastAlphaKey = -1;
  Color _cachedBodyColor = const Color(0x00000000);
  // Cached diamond path — gemSize depends only on `value` (final), so the
  // path never changes after onLoad(). Avoids one Path allocation per frame.
  late Path _diamondPath;
  // Scratch Vector2 riusato nel calcolo dell'attrazione per frame — evita
  // di allocare i temporanei `player.position - position` e `dir * speed * dt`.
  final Vector2 _attractDir = Vector2.zero();

  Geom({this.value = 1}) : super(size: Vector2(10, 10), anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    _color = _getColorForValue(value);
    _rotationSpeed = (_random.nextDouble() - 0.5) * 5;
    add(
      CircleHitbox(
        radius: geomCollectRadius,
        anchor: Anchor.center,
        isSolid: true,
      )..position = size / 2,
    );
    // Build diamond path once — gemSize is constant for the life of this geom.
    final gemSize = 4.0 + value * 1.5;
    _diamondPath = Path()
      ..moveTo(0, -gemSize)
      ..lineTo(gemSize * 0.6, 0)
      ..lineTo(0, gemSize)
      ..lineTo(-gemSize * 0.6, 0)
      ..close();
  }

  @override
  void onMount() {
    super.onMount();
    // Registry game-level: evita scan di world.children ogni frame.
    game.activeGeoms.add(this);
  }

  @override
  void onRemove() {
    game.activeGeoms.remove(this);
    super.onRemove();
  }

  Color _getColorForValue(int v) {
    if (v >= 10) return NeonColors.gold;
    if (v >= 5) return NeonColors.purple;
    if (v >= 3) return NeonColors.green;
    return NeonColors.cyan;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _phase += dt * _rotationSpeed;
    _lifetime -= dt;

    // Fade out when almost expired
    if (_lifetime <= 0) {
      removeFromParent();
      return;
    }

    // Tunnel mode: despawn geom dietro la camera (evita accumulo infinito)
    if (game.isTunnelMode) {
      final cameraLeft =
          game.camera.viewfinder.position.x -
          (game.size.x > 0 ? game.size.x / 2 : 400) -
          200;
      if (position.x < cameraLeft) {
        removeFromParent();
        return;
      }
    }

    // Attrazione geomi: sempre attiva con raggio base 80px
    // Power-up Magnet aumenta il raggio a 400px
    // Upgrade magnetRange aggiunge raggio extra
    final player = game.player;
    final dist = position.distanceTo(player.position);

    // Raggio base passivo (80px) + upgrade + power-up (stackano)
    const double baseAttractionRange = 80.0;
    final upgradeRange = game.saveData.magnetRange;
    var magnetRange =
        (player.hasMagnet ? magnetRadius : baseAttractionRange) + upgradeRange;
    // MAGNETIC modifier (vedi WaveModifier.magnetic): radius ×2 → wave
    // "loot vacuum". Stacka sopra magnet power-up + upgrade.
    if (game.waveSystem.activeModifier == WaveModifier.magnetic) {
      magnetRange *= 2.0;
    }
    // Pre-game modifier `magnet_king` (RE MAGNETE): raggio enorme +600px
    // assoluto (richiesta utente: "geom volano verso di te"). Stacka sopra
    // wave-modifier + power-up.
    if (game.hasModifier('magnet_king')) {
      magnetRange += 600.0;
    }
    // CollectPet (richiesta utente iter 7): rimosso magnet boost +250
    // verso il player. Il pet deve fisicamente girare per raccogliere
    // (logica in pet_base.dart `CollectPet.onPetUpdate` → physical pickup
    // entro 25px). Niente più aspirazione passiva via player.

    if (dist < magnetRange) {
      _attracted = true;
    } else {
      _attracted = false;
    }

    if (_attracted) {
      // Reuse scratch Vector2 invece di allocare `player.position - position`
      // e `dir * speed * dt` per frame (con 100 geomi → 200 alloc/frame).
      _attractDir
        ..setFrom(player.position)
        ..sub(position);
      if (_attractDir.length2 > 1e-6) {
        _attractDir.normalize();
        // Velocità attrazione: più vicino = più veloce.
        // Guard divisione: se magnetRange<=0 (edge case shop/data), skip
        // il termine proporzionale invece di NaN/Infinity.
        final proximity = magnetRange > 0
            ? (1.0 - dist / magnetRange).clamp(0.0, 1.0)
            : 0.0;
        final attractSpeed = player.hasMagnet ? 800.0 : 400.0 + proximity * 300;
        // Due scale separate per preservare il raggruppamento del prodotto
        // originale `dir * attractSpeed * dt` = `(dir * attractSpeed) * dt`
        // (la moltiplicazione float non è associativa → output bit-identico).
        _attractDir.scale(attractSpeed);
        _attractDir.scale(dt);
        position.add(_attractDir);
      }
    }
  }

  // Paint cache — con 100 geomi sullo schermo, risparmia allocazioni/frame
  static final _geomBodyPaint = Paint();

  @override
  void render(Canvas canvas) {
    // Lampeggio dopo 5s (quando _lifetime < 2, cioè 7-5=2s rimanenti)
    final blinkActive = _lifetime < 2.0;
    final blinkVisible = !blinkActive || ((_lifetime * 8).toInt() % 2 == 0);
    if (!blinkVisible) return; // Non renderizzare durante il blink off
    final alpha = _lifetime < 2 ? (_lifetime / 2).clamp(0.2, 1.0) : 1.0;

    final cx = size.x / 2;
    final cy = size.y / 2;

    // Diamond shape (uses _diamondPath cached in onLoad — no per-frame allocation)
    // Resolve body color via per-instance quantized-alpha cache: reuse the
    // opaque `_color` directly when alpha==1.0, else recompute withValues only
    // when the quantized key changes (same formula, delta <= 1/256).
    final alphaKey = (alpha * (_alphaSteps - 1)).round().clamp(
      0,
      _alphaSteps - 1,
    );
    if (alphaKey != _lastAlphaKey) {
      _cachedBodyColor = alphaKey == _alphaSteps - 1
          ? _color
          : _color.withValues(alpha: alpha);
      _lastAlphaKey = alphaKey;
    }
    _geomBodyPaint.color = _cachedBodyColor;
    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(_phase);
    canvas.drawPath(_diamondPath, _geomBodyPaint);
    canvas.restore();
  }

  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    if (other is Player) {
      game.collectGeom(value);
      removeFromParent();
    }
    super.onCollisionStart(intersectionPoints, other);
  }
}
