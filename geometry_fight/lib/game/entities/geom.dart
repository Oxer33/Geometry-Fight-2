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

  Geom({this.value = 1})
      : super(size: Vector2(10, 10), anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    _color = _getColorForValue(value);
    _rotationSpeed = (_random.nextDouble() - 0.5) * 5;
    add(CircleHitbox(radius: geomCollectRadius, anchor: Anchor.center, isSolid: true)
      ..position = size / 2);
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
      final cameraLeft = game.camera.viewfinder.position.x - (game.size.x > 0 ? game.size.x / 2 : 400) - 200;
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
    }

    if (_attracted) {
      final dir = (player.position - position);
      if (dir.length > 0) {
        dir.normalize();
        // Velocità attrazione: più vicino = più veloce
        final attractSpeed = player.hasMagnet ? 800.0 : 400.0 + (1.0 - dist / magnetRange).clamp(0.0, 1.0) * 300;
        position += dir * attractSpeed * dt;
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
    final gemSize = 4.0 + value * 1.5;

    final cx = size.x / 2;
    final cy = size.y / 2;

    // Diamond shape
    _geomBodyPaint.color = _color.withValues(alpha: alpha);
    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(_phase);

    final path = Path()
      ..moveTo(0, -gemSize)
      ..lineTo(gemSize * 0.6, 0)
      ..lineTo(0, gemSize)
      ..lineTo(-gemSize * 0.6, 0)
      ..close();
    canvas.drawPath(path, _geomBodyPaint);
    canvas.restore();
  }

  @override
  void onCollisionStart(
      Set<Vector2> intersectionPoints, PositionComponent other) {
    if (other is Player) {
      game.collectGeom(value);
      removeFromParent();
    }
    super.onCollisionStart(intersectionPoints, other);
  }
}
