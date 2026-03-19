import 'dart:ui';

// Arena (30% più piccola rispetto all'originale 3000x3000)
// Tunnel mode usa le dimensioni originali per il corridoio lungo
const double arenaWidth = 2100;
const double arenaHeight = 2100;
const double tunnelArenaWidth = 3000; // Solo per tunnel mode
const double tunnelArenaHeight = 3000;

// Player
const double playerSpeed = 400;
const double playerHurtboxRadius = 8;
const int playerStartLives = 3;
const int playerStartBombs = 1;
const double playerInvincibilityDuration = 5.0; // 5 secondi di invincibilità dopo perdita vita

// Projectiles
const double bulletSpeed = 700;
const double bulletWidth = 4;
const double bulletHeight = 8;
const double baseFireRate = 8; // shots per second
const int maxBounces = 2;
const double bulletLifetime = 2.0;

// Camera
const double cameraSmoothing = 0.08;

// Grid
const int gridCols = 50;
const int gridRows = 50;
const double gridSpringStiffness = 12.0; // Più rigida = ritorno più veloce (era 3.0)
const double gridDamping = 0.85; // Meno damping = più rimbalzo elastico (era 0.92)

// Spatial hash
const double spatialCellSize = 64;

// Particles
const int maxParticles = 300;
const int particlePoolSize = 500;
const int projectilePoolSize = 200;
const int geomPoolSize = 100;

// Geom
const double geomLifetime = 7.0; // Despawn dopo 7s, lampeggio dopo 5s
const double geomCollectRadius = 30;
const double magnetRadius = 400;
const int geomToGoldRatio = 10;

// Score
const double maxMultiplier = 20.0;
const double multiplierPerKill = 0.1;
const int comboThreshold = 5;
const double comboTimeWindow = 0.5;

// Power-ups
const double powerUpDuration = 15.0;

// Neon Colors
class NeonColors {
  static const Color cyan = Color(0xFF00FFFF);
  static const Color pink = Color(0xFFFF00AA);
  static const Color green = Color(0xFF00FF44);
  static const Color gray = Color(0xFF888888);
  static const Color orange = Color(0xFFFF8800);
  static const Color lightBlue = Color(0xFF00AAFF);
  static const Color yellow = Color(0xFFFFDD00);
  static const Color white = Color(0xFFFFFFFF);
  static const Color purple = Color(0xFF9900FF);
  static const Color darkRed = Color(0xFF660000);
  static const Color red = Color(0xFFFF2200);
  static const Color bulletYellow = Color(0xFFFFE500);
  static const Color laserRed = Color(0xFFFF0022);
  static const Color plasmaViolet = Color(0xFFCC00FF);
  static const Color ricochetGreen = Color(0xFF00FF88);
  static const Color spreadOrange = Color(0xFFFF6B00);
  static const Color gold = Color(0xFFFFD700);
  static const Color teal = Color(0xFF00E5CC);
  static const Color magenta = Color(0xFFFF00FF);
  static const Color electricBlue = Color(0xFF0066FF);
  static const Color lime = Color(0xFFAAFF00);
  static const Color crimson = Color(0xFFDC143C);
  static const Color deepPurple = Color(0xFF6600CC);
}
