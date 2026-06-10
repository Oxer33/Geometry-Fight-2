import 'dart:ui';
import 'package:flame/components.dart';
import '../game_world.dart';

/// Modifier `fog_of_war` (NEBBIA DI GUERRA): oscura l'arena lasciando visibile
/// solo un cerchio attorno al player (richiesta utente: il modifier non era
/// implementato, non faceva nulla).
///
/// Componente world-space ad alta priorità che segue il player e disegna un
/// gradiente radiale (centro trasparente → nero quasi opaco) con TileMode.clamp
/// → oltre il raggio tutto resta buio fino ai bordi dello schermo. Player e
/// nemici dentro al cerchio restano visibili; quelli fuori spariscono nel buio.
class FogOfWar extends PositionComponent
    with HasGameReference<GeometryFightGame> {
  FogOfWar() : super(priority: 1000);

  // Raggio completamente visibile e raggio in cui il buio è pieno.
  static const double _clearRadius = 150;
  static const double _darkRadius = 340;
  static final Paint _paint = Paint();

  @override
  void update(double dt) {
    // Segue il player (copia il valore, non la reference NotifyingVector2).
    position.setFrom(game.player.position);
  }

  @override
  void render(Canvas canvas) {
    _paint.shader = Gradient.radial(
      Offset.zero,
      _darkRadius,
      const [Color(0x00000000), Color(0x00000000), Color(0xF2000000)],
      [0.0, _clearRadius / _darkRadius, 1.0],
    );
    // Rettangolo grande abbastanza da coprire lo schermo qualunque sia la
    // posizione del player nel viewport (la camera lo segue ~centrato). Oltre
    // `_darkRadius` il gradiente è clampato all'ultimo colore (buio pieno).
    final reach = (game.size.x + game.size.y) * 1.5 + _darkRadius;
    canvas.drawRect(
      Rect.fromCenter(center: Offset.zero, width: reach, height: reach),
      _paint,
    );
  }
}
