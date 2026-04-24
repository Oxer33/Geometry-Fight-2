import 'dart:ui';

// Arena 16:9 — larghezza adattata all'aspect ratio dello schermo.
// Tunnel mode usa dimensioni separate per il corridoio lungo.
// Arena -30% (richiesta utente): era 1334x750, ora 934x525 per tutte le
// modalità rettangolari (classic, zen, boss rush, arcade). Tunnel invariato.
const double arenaWidth = 934;
const double arenaHeight = 525;
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

// Weapon tuning
const double homingTrackRadius = 150.0;  // Raggio inseguimento missili (era 70, +114% richiesta utente)
const double laserBeamLength = 1200.0;   // Lunghezza raggio laser (50% più lungo del vecchio 800)
const double overdriveBeamLength = 1200.0;
const double overdriveBeamWidth = 40.0;
const double plasmaExplosionRadius = 80.0;

// Boss fight tuning
const int bossMinionEnemyCap = 15;          // Max nemici attivi prima di skippare spawn minion
// Cap più alto per big wave color-matched (richiesta utente 10/30/50 mob).
// Separato dal cap regolare così le ondate non vengono clippate dal pool
// di minion regolari già a schermo.
const int bossBigWaveCap = 60;
const double bossMinionSpawnInterval = 3.5; // Secondi tra ondate minion base

// Camera
const double cameraSmoothing = 0.12;

// Waves
// Delay tra gruppi di spawn in modalità classica.
// Ridotto 2.5→1.2 (richiesta utente: "mob dei vari gruppi compaiono troppo
// distanti temporalmente").
// NB: la warning/spawn-invuln del singolo nemico (`_spawnInvulnTimer` in
// enemy_base.dart, attualmente 4s) non è accoppiata a questo delay — il
// flash copre il proprio spawn, non l'intervallo fra gruppi.
const double classicWaveGroupDelaySeconds = 1.2;
// Timeout massimo per il completamento di una wave classica DOPO l'ultimo
// spawn: anche se restano nemici vivi, la wave successiva parte comunque.
const double classicWaveTimeoutSeconds = 20.0;

// Grid
const int gridCols = 50;
const int gridRows = 50;
const double gridSpringStiffness = 12.0; // Più rigida = ritorno più veloce (era 3.0)
const double gridDamping = 0.85; // Meno damping = più rimbalzo elastico (era 0.92)

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

// Power-ups
const double powerUpDuration = 15.0;

// Neon Colors
abstract final class NeonColors {
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
