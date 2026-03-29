# Geometry Fight 2 — Architecture Document

> Twin-stick neon shooter ispirato a Geometry Wars: Retro Evolved 2
> Built with Flutter + Flame Engine

---

## Indice

1. [Overview](#overview)
2. [Tech Stack](#tech-stack)
3. [Struttura del Progetto](#struttura-del-progetto)
4. [Architettura a Layer](#architettura-a-layer)
5. [Data Layer](#data-layer)
6. [Game Engine Layer](#game-engine-layer)
7. [Entity System](#entity-system)
8. [Enemy System](#enemy-system)
9. [Boss System](#boss-system)
10. [Effects System](#effects-system)
11. [Systems Layer](#systems-layer)
12. [UI Layer](#ui-layer)
13. [Performance & Ottimizzazioni](#performance--ottimizzazioni)
14. [Pattern Architetturali](#pattern-architetturali)
15. [Game Modes](#game-modes)
16. [Flusso di Gioco](#flusso-di-gioco)

---

## Overview

Geometry Fight 2 è un twin-stick shooter 2D con estetica neon, 30 tipi di nemici, 15 boss, 8 modalità di gioco, sistema di progressione con shop/achievement/modifier, e 100 wave procedurali.

Il gioco gira su **Flutter** per la UI nativa (menu, HUD, shop) e **Flame** per il game loop (60fps rendering, collision detection, entity management).

---

## Tech Stack

| Componente | Tecnologia |
|---|---|
| Framework UI | Flutter |
| Game Engine | Flame (FlameGame, Component system) |
| Persistence | Hive Flutter (save data, leaderboard, achievements) |
| Input | Virtual Joystick (touch), Keyboard (desktop) |
| Audio/Haptics | Flutter Services (HapticFeedback) |
| Build Target | Android (APK), iOS, macOS |

---

## Struttura del Progetto

```
geometry_fight/lib/
├── main.dart                          # Entry point, navigazione schermate
├── data/                              # Configurazioni, persistenza, costanti
│   ├── constants.dart                 # Arena, player, colori neon, fisica
│   ├── difficulty.dart                # 4 difficoltà, 8 game modes
│   ├── wave_configs.dart              # 100 wave procedurali, 32 enemy types
│   ├── save_data.dart                 # Progressione, gold, upgrades, skins
│   ├── leaderboard.dart              # Top 10 per mode/difficulty
│   ├── achievements.dart             # 40+ achievement in 5 categorie
│   └── modifiers.dart                # 12 modificatori gameplay
├── game/                              # Core game engine
│   ├── game_world.dart               # FlameGame principale, stato di gioco
│   ├── entities/                     # Tutte le entità di gioco
│   │   ├── player.dart               # Player (8 armi, powerup, vite)
│   │   ├── projectiles.dart          # PlayerBullet, PlasmaBullet, HomingMissile
│   │   ├── powerups.dart             # 8 tipi di power-up
│   │   ├── geom.dart                 # Collezionabili (score multiplier)
│   │   ├── enemies/                  # 30 tipi di nemici
│   │   │   ├── enemy_base.dart       # Classe base astratta
│   │   │   ├── drone_enemy.dart      # Homing base
│   │   │   ├── bouncer_enemy.dart    # Random walk
│   │   │   ├── swarm_drone_enemy.dart # Griglia + movimento fluido
│   │   │   ├── snake_enemy.dart      # Onda sinusoidale + corpo
│   │   │   ├── shield_enemy.dart     # Scudo + repulsor
│   │   │   ├── black_hole_enemy.dart # Gravità + esplosione proton
│   │   │   ├── gate_enemy.dart       # Risk/reward traversal
│   │   │   ├── proton_enemy.dart     # Mini-nemico veloce (da BlackHole)
│   │   │   ├── mutator_enemy.dart    # Potenzia altri nemici
│   │   │   ├── splitter_enemy.dart   # Si divide alla morte
│   │   │   ├── kamikaze_enemy.dart   # Carica veloce
│   │   │   ├── orbiter_enemy.dart   # Orbita circolare
│   │   │   ├── leech_enemy.dart     # Parassita veloce
│   │   │   ├── time_bomb_enemy.dart # Esplosione ritardata
│   │   │   ├── pulsar_enemy.dart    # Shockwave periodica
│   │   │   ├── mirror_enemy.dart    # Strafing con riflesso
│   │   │   ├── gravity_well_enemy.dart # Distorsione gravità
│   │   │   └── ... (altri 14 tipi)
│   │   └── bosses/                   # 15 boss
│   │       ├── boss_base.dart        # Classe base, fasi, pattern
│   │       ├── the_grid_boss.dart    # Wave 10
│   │       ├── hydra_boss.dart       # Wave 20
│   │       ├── void_reaper_boss.dart # Wave 60
│   │       └── ... (altri 11 boss)
│   ├── effects/                      # Effetti visivi
│   │   ├── explosion.dart            # Particelle esplosione
│   │   ├── grid_distortion.dart      # Griglia con spring physics
│   │   ├── screen_shake.dart         # Camera shake
│   │   ├── space_background.dart     # Parallax stelle + nebulose
│   │   └── tunnel_renderer.dart      # Arena tunnel sinusoidale
│   └── systems/                      # Sistemi di gioco
│       ├── wave_system.dart          # Progressione wave, spawn
│       ├── score_system.dart         # Punteggio, multiplier, extra vite
│       ├── powerup_system.dart       # Spawn power-up random
│       └── audio_system.dart         # Haptic feedback
├── ui/                                # Interfaccia utente Flutter
│   ├── hud.dart                      # Punteggio, vite, bombe, wave
│   ├── screens/                      # 12 schermate
│   │   ├── main_menu.dart
│   │   ├── game_screen.dart          # GameWidget + joystick overlay
│   │   ├── game_over_screen.dart
│   │   ├── shop_screen.dart
│   │   ├── mode_select_screen.dart
│   │   ├── settings_screen.dart
│   │   ├── leaderboard_screen.dart
│   │   ├── stats_screen.dart
│   │   ├── achievements_screen.dart
│   │   ├── modifiers_screen.dart
│   │   ├── pause_screen.dart
│   │   └── splash_screen.dart
│   └── widgets/                      # Widget riutilizzabili
│       ├── virtual_joystick.dart
│       ├── animated_builder_widget.dart
│       └── tutorial_overlay.dart
└── utils/                             # Utility
    ├── extensions.dart               # Vector2 extensions
    └── spatial_hash.dart             # Spatial partitioning
```

---

## Architettura a Layer

```
┌─────────────────────────────────────────────┐
│                  UI LAYER                    │
│  Flutter Screens, HUD, Virtual Joystick     │
├─────────────────────────────────────────────┤
│              SYSTEMS LAYER                   │
│  WaveSystem, ScoreSystem, PowerUpSystem     │
├─────────────────────────────────────────────┤
│             ENTITY LAYER                     │
│  Player, Enemies (32), Bosses (15),         │
│  Projectiles, Geoms, PowerUps              │
├─────────────────────────────────────────────┤
│            EFFECTS LAYER                     │
│  Explosion, GridDistortion, ScreenShake,    │
│  SpaceBackground, TunnelRenderer            │
├─────────────────────────────────────────────┤
│          GAME ENGINE LAYER                   │
│  GeometryFightGame (FlameGame)              │
│  Collision Detection, Game Loop             │
├─────────────────────────────────────────────┤
│             DATA LAYER                       │
│  Constants, WaveConfigs, SaveData,          │
│  Leaderboard, Achievements, Modifiers       │
└─────────────────────────────────────────────┘
```

---

## Data Layer

### Constants (`constants.dart`)

Valori chiave del gioco:

| Costante | Valore | Note |
|---|---|---|
| Arena Standard | 750×750 px | Quadrata |
| Arena Tunnel | 3000×3000 px | Side-scroller |
| Grid Nodes | 50×50 | Spring physics |
| Player Speed | 400 px/s | Base, upgradable |
| Bullet Speed | 700 px/s | Base |
| Colori | 18 neon colors | `NeonColors` abstract class |

### Difficulty (`difficulty.dart`)

4 livelli di difficoltà con scaling multiplicativo:

| Parametro | Easy | Normal | Hard | Nightmare |
|---|---|---|---|---|
| Enemy HP | 0.7x | 1.0x | 1.5x | 2.0x |
| Enemy Speed | 0.8x | 1.0x | 1.3x | 1.6x |
| Enemy Count | 0.7x | 1.0x | 1.4x | 1.8x |
| Spawn Rate | 0.8x | 1.0x | 1.3x | 1.6x |
| Geom Value | 1.5x | 1.0x | 0.8x | 0.6x |

### Wave Configs (`wave_configs.dart`)

100 wave procedurali con 16 boss fight a intervalli regolari.

**Generazione wave:**
- 70% mob "stupidi" (drone, bouncer, swarm) → caos visivo, bassa minaccia individuale
- 30% nemici pericolosi (kamikaze, shield, black_hole, etc.) → minaccia strategica

**Enemy Types:** 30 tipi nell'enum `EnemyType`
**Boss Schedule:** Wave 10, 20, 30, 40, 45, 50, 55, 60, 65, 70, 75, 80, 85, 90, 95, 100

### Save Data (`save_data.dart`)

Persistenza Hive con `SaveManager`:

```dart
// Dati tracciati:
- goldGeoms          // Valuta di gioco
- upgrades           // Damage, speed, fireRate, shield, magnetRange, xpBoost
- unlockedSkins      // Skin cosmetiche
- unlockedTrails     // Trail effects
- unlockedModes      // Game modes sbloccati
- unlockedWeapons    // 8 armi
- highScores         // Per mode/difficulty
- totalPlaytime      // Tempo totale
- stats              // Kills, deaths, waves, etc.
- activeModifiers    // Modificatori attivi
```

### Achievements (`achievements.dart`)

40+ achievement in 5 categorie:
- **Combat** — Kill counts, combo, boss kills
- **Score** — Milestones di punteggio
- **Progress** — Wave raggiunte, modalità completate
- **Mastery** — Sfide speciali (no damage, speed run)
- **Special** — Easter eggs, obiettivi nascosti

Ricompensa: Gold geoms per ogni achievement sbloccato.

### Modifiers (`modifiers.dart`)

12 modificatori opzionali con score multiplier:

| Modifier | Effetto | Multiplier |
|---|---|---|
| Glass Cannon | 3x danno, 1 HP | 1.5x |
| Bullet Hell | Nemici sparano il doppio | 1.8x |
| Speed Demon | Tutto 50% più veloce | 1.4x |
| No Powerups | Nessun power-up | 1.6x |
| Fog of War | Visibilità ridotta | 1.3x |
| Tiny Arena | Arena 50% più piccola | 1.5x |
| One Shot | Un colpo, un kill (entrambi) | 2.0x |
| Chaos | Spawn casuali continui | 1.7x |
| Giant Mode | Nemici 2x più grandi | 0.8x |
| Ricochet World | Proiettili rimbalzano ovunque | 1.2x |
| Infinite Bombs | Bombe illimitate | 0.5x |
| Magnet King | Raggio magnetico 3x | 0.7x |

---

## Game Engine Layer

### GeometryFightGame (`game_world.dart`)

Classe centrale che estende `FlameGame` con `HasCollisionDetection` e `KeyboardEvents`.

**Responsabilità:**
- Gestione stato di gioco (`playing`, `paused`, `gameOver`, `bossIntro`, `waveIntro`)
- Spawn e gestione di tutte le entità
- Coordinamento tra i sistemi (wave, score, powerup, audio)
- Camera e viewport management
- Input routing (keyboard → player)

**Componenti inizializzati in `onLoad()`:**
1. `SpaceBackground` — Sfondo parallax
2. `GridDistortion` — Griglia con spring physics
3. `Player` — Entità giocatore
4. `WaveSystem` — Gestione wave
5. `ScoreSystem` — Punteggio e multiplier
6. `PowerUpSystem` — Spawn power-up
7. `AudioSystem` — Haptic feedback
8. `ScreenShakeEffect` — Camera shake
9. `TunnelRenderer` — (solo in tunnel mode)

**Metodi chiave:**
```dart
void spawnEnemy(EnemyType type, {Vector2? position})  // Spawn con difficulty scaling
void spawnExplosion(Vector2 pos, Color color, {double radius, int particleCount})
void spawnGeom(Vector2 pos, int value)
void spawnBoss(BossType type)
void gameOver()
```

---

## Entity System

### Gerarchia delle Entità

```
PositionComponent (Flame)
├── Player
│   ├── 8 weapon types
│   ├── Power-up state machine
│   ├── Lives + bombs + shield
│   └── Movement trail rendering
├── EnemyBase (abstract)
│   ├── 29 enemy subclasses (+ GateEnemy separato)
│   ├── Spawn invulnerability (0.8s)
│   ├── Fear mechanic
│   └── Flash on damage
├── BossBase (abstract)
│   ├── 15 boss subclasses
│   ├── Multi-phase patterns
│   └── Intro animation
├── GateEnemy (NOT EnemyBase)
│   └── Risk/reward traversal object
├── PlayerBullet / PlasmaBullet / HomingMissile
├── PowerUp (8 types)
├── Geom (score collectible)
└── Effects (Explosion, Grid, etc.)
```

### Player (`player.dart`)

**Armi (8 tipi):**
| Arma | Comportamento |
|---|---|
| Basic | Singolo proiettile direzionale |
| Spread | 3 proiettili a ventaglio |
| Laser | Raggio continuo |
| Plasma | Esplosione ad area |
| Ricochet | Rimbalza sui muri |
| Homing | Insegue i nemici |
| Twin | Due proiettili paralleli |
| Overdrive | Fuoco rapido potenziato |

**Power-up States:**
- `rapidFire` — Frequenza di fuoco raddoppiata
- `overdrive` — Danno e velocità potenziati
- `magnet` — Raggio raccolta geom aumentato
- `timeSlow` — Rallenta il tempo per i nemici

### Projectiles (`projectiles.dart`)

**PlayerBullet:**
- Collision callbacks con `EnemyBase` e `BossBase`
- Check `isSpawnInvulnerable` prima di consumarsi
- `_applyFearToNearby()` su impatto (max 5 nemici, 80px raggio)
- Supporta pierce (attraversa nemici) e bounce (rimbalza sui muri)

**PlasmaBullet:** Esplosione ad area con raggio configurabile
**HomingMissile:** Target-seeking con rotazione graduale

### Geom (`geom.dart`)

Collezionabili che alimentano il moltiplicatore di punteggio:

| Valore | Colore | Drop |
|---|---|---|
| 1-2 | Cyan | Nemici base |
| 3-4 | Verde | Nemici medi |
| 5-9 | Viola | Nemici avanzati |
| 10+ | Oro | Boss, sfide |

Magnetismo progressivo: attrazione automatica entro raggio configurabile.

---

## Enemy System

### EnemyBase (`enemy_base.dart`)

Classe astratta che fornisce:

```dart
abstract class EnemyBase extends PositionComponent
    with HasGameReference<GeometryFightGame>, CollisionCallbacks {

  double hp;
  double maxHp;
  double speed;          // Scalato dalla difficulty
  int pointValue;
  int geomValue;
  Color neonColor;

  // === Spawn Invulnerability ===
  double _spawnInvulnTimer = 0.8;  // 0.8s materializzazione
  bool get isSpawnInvulnerable => _spawnInvulnTimer > 0;
  void clearSpawnInvulnerability() => _spawnInvulnTimer = 0;

  // === Fear Mechanic ===
  double _fearTimer = 0;
  Vector2? _fearDirection;
  void applyFear(Vector2 bulletPos);  // Solo nemici con maxHp <= 2

  // === Rendering ===
  // Flash skip-frame (NO saveLayer) per spawn invulnerability
  // Static Paint cache condiviso tra subclassi
  static final detailPaint = Paint()..color = Colors.white.withValues(alpha: 0.3);

  // === Template Method Pattern ===
  void updateBehavior(double dt);       // Override nelle subclassi
  void renderShape(Canvas, Paint, double scale);  // Override per forma
}
```

**Ciclo di update:**
1. Decrementa `_spawnInvulnTimer`
2. Se `_fearTimer > 0`: muovi in `_fearDirection` a 2.5x speed
3. Altrimenti: chiama `updateBehavior(dt)` (logica specifica)
4. Clamp posizione nell'arena (DOPO fear + behavior)

**Spawn Invulnerability:**
- Nemici da wave: 0.8s di invulnerabilità, flash visivo
- Nemici generati in-game (Proton, Splitter children, Snake tail): `clearSpawnInvulnerability()` nel costruttore → immediatamente killabili
- Tutti i proiettili (PlayerBullet, PlasmaBullet, HomingMissile) e il Player checkano `isSpawnInvulnerable` prima di interagire

**Fear Mechanic:**
- Quando un proiettile colpisce un nemico, `_applyFearToNearby()` cerca max 5 nemici entro 80px
- Solo nemici deboli (maxHp <= 2) reagiscono
- 0.3s di fuga a 2.5x velocità nella direzione opposta al proiettile

### Categorie Nemici

#### Tier 1 — Mob Semplici (70% degli spawn)

| Nemico | Movimento | HP | Minaccia |
|---|---|---|---|
| Drone | Homing diretto | 1 | Bassa |
| Bouncer | Random walk | 1 | Bassa |
| SwarmDrone | Griglia + flock | 1 | Massa |

**SwarmDrone — Implementazione Griglia:**
```
Formazione iniziale in griglia → dissolve in movimento fluido dopo 2s
Fase griglia: posizionamento con offset (row, col) dalla posizione target
Fase sciame: flock behavior con separation + cohesion + alignment
```

#### Tier 2 — Nemici Tattici

| Nemico | Meccanica | HP | Note |
|---|---|---|---|
| Mine | Stazionario, esplode al contatto | 1 | Danno ad area |
| Spawner | Genera mini-nemici | 3 | Priorità alta |
| Weaver | Schiva proiettili | 2 | Evasivo |
| Splitter | Si divide alla morte | 2 | `clearSpawnInvulnerability()` sui figli |
| Kamikaze | Carica veloce | 1 | 400+ px/s |
| Snake | Onda sinusoidale | 3 (testa) | Corpo invulnerabile |
| Orbiter | Orbita circolare attorno al player | 2 | Strafing |
| Leech | Parassita veloce | 1 | Fast, aggressivo |
| TimeBomb | Esplosione ritardata | 2 | Timer → area damage |

#### Tier 3 — Nemici Avanzati (meccaniche GW:RE2)

| Nemico | Meccanica | HP | Ispirazione GW:RE2 |
|---|---|---|---|
| **ShieldEnemy** | Scudo frontale + repulsor push-back | 4 | Repulsor |
| **BlackHole** | Gravità, assorbe nemici → esplosione proton | 5 | Gravity Well → Proton swarm |
| **GateEnemy** | Risk/reward: passa tra sfere = kill area, tocca = danno | — | Gate traversal |
| **ProtonEnemy** | Veloce (280px/s), bounce, slight homing | 1 | Proton post-explosion |
| **MutatorEnemy** | Potenzia altri nemici (+80% speed, +50% HP) | 2 | Mutator buff |

#### Tier 4 — Nemici Speciali

| Nemico | Meccanica | HP |
|---|---|---|
| Phantom | Invisibilità + flanking | 2 |
| Glitch | Teleportazione | 2 |
| Titan | Tank pesante | 8 |
| Healer | Ripara altri nemici | 2 |
| Necro | Resuscita nemici morti | 3 |
| Tesla | Arco elettrico | 3 |
| LaserTurret | Laser direzionale | 3 |
| Siren | Rallenta proiettili | 2 |
| Vortex | Vortice | 3 |
| Decoy | Falso bersaglio | 1 |
| Pulsar | Emissione shockwave periodica | 3 |
| Mirror | Strafing orbitale con riflesso | 2 |
| GravityWell | Distorsione gravitazionale | 3 |

### Dettaglio Meccaniche Chiave

#### GateEnemy — Risk/Reward

```dart
// GateEnemy è PositionComponent, NON EnemyBase
// → Immune ai proiettili, non è un "nemico" tradizionale

class GateEnemy extends PositionComponent {
  // Due sfere neon connesse da una linea
  // Cooldown 0.5s allo spawn, lifetime 30s auto-despawn

  // RISK: tocca una sfera → takeDamage()
  if (d1 < 10 || d2 < 10) { game.player.takeDamage(); }

  // REWARD: passa tra le sfere → esplosione kill area (180px)
  if (distToCenter < gateWidth * 0.8 && d1 > 10 && d2 > 10) {
    _triggerExplosion();  // Uccide tutti i nemici nel raggio
  }
}
```

#### BlackHole → Proton Explosion

```dart
// BlackHole attrae nemici vicini (200px raggio)
// Dopo 5 nemici assorbiti → esplode in sciame di Proton

void _explodeIntoProtons() {
  final count = 6 + _absorbedCount;  // Più assorbe, più Proton
  for (int i = 0; i < count; i++) {
    final angle = (i / count) * 2 * pi;
    game.world.add(ProtonEnemy(
      direction: Vector2(cos(angle), sin(angle)),
    )..position = position.clone());
  }
  removeFromParent();
}
```

#### MutatorEnemy — Buff Chain

```dart
// Cerca il nemico NON-player più vicino e lo potenzia
void _mutateEnemy(EnemyBase enemy) {
  enemy.speed *= 1.8;          // +80% velocità
  enemy.hp += enemy.maxHp * 0.5;  // +50% HP
  enemy.maxHp *= 1.5;
  enemy.neonColor = Color(0xFFFFDD44);  // Indicatore visivo giallo
  _mutationsCount++;
  if (_mutationsCount >= 8) onDeath();  // Auto-distrugge dopo 8
}
// Skip nemici già mutati (check neonColor == giallo)
// NO size change (hitbox non si aggiorna in Flame)
```

---

## Boss System

### BossBase (`boss_base.dart`)

```dart
abstract class BossBase extends PositionComponent {
  double hp, maxHp;
  int patternIndex;
  int phase;           // Fasi progressive (più pattern ad HP basso)
  bool isIntro;        // Animazione d'ingresso

  void updatePattern(double dt);   // Override per pattern di attacco
  void nextPattern();              // Avanza al prossimo pattern
  void spawnProjectile(...);       // Spawn proiettili boss
  void createShockwave(...);       // Onda d'urto ad area
}
```

### Boss Schedule

| Wave | Boss | Meccanica Principale |
|---|---|---|
| 10 | The Grid | Pattern geometrici |
| 20 | Hydra | Multi-testa |
| 30 | Singularity | Buco nero |
| 40 | Swarm Mother | Generazione sciami |
| 45 | The Architect | Costruzione pattern |
| 50 | Chrono Wraith | Manipolazione tempo |
| 55 | Nexus Prime | Numeri primi |
| 60 | Void Reaper | Attacchi void |
| 65 | Tesla Lord | Scariche elettriche |
| 70 | Phantom King | Invisibilità a fasi |
| 75 | Omega Core | Distruzione core |
| 80 | Mirror Master | Riflesso |
| 85 | Swarm Queen | Sciami infiniti |
| 90 | Graviton | Gravità |
| 95 | Inferno | Fuoco ed esplosioni |
| 100 | Eternity Engine | Boss finale combinato |

---

## Effects System

### Grid Distortion (`grid_distortion.dart`)

Griglia 50×50 nodi con spring physics:
- Ogni impatto (proiettile, esplosione) distorce i nodi vicini
- I nodi tornano alla posizione originale con molla smorzata
- **Ottimizzazione:** Path caching, Paint pooling, no render se distorsione < threshold

### Explosion (`explosion.dart`)

Particelle con:
- Direzione radiale randomizzata
- Velocità con decay
- Colore neon configurabile
- Conteggio particelle variabile (4 per bullet hit, 20+ per boss kill)

### Screen Shake (`screen_shake.dart`)

Camera shake basato su intensità:
- `intensity` → ampiezza pixel
- `duration` → durata con decay lineare
- Offset random per frame
- Si accumula per esplosioni multiple

### Space Background (`space_background.dart`)

3 layer parallax:
1. Stelle lontane (piccole, lente)
2. Stelle medie
3. Stelle vicine (grandi, veloci)
+ Nebulose con gradiente generato da Perlin noise

---

## Systems Layer

### Wave System (`wave_system.dart`)

**Flusso:**
1. Wave intro (countdown visivo)
2. Spawn nemici con delay configurabile per tipo
3. Monitoraggio completamento (tutti i nemici morti)
4. Transizione → wave successiva o boss intro

**Mode-specific behavior:**
- **Classic:** 100 wave standard
- **Boss Rush:** Solo boss, uno dopo l'altro
- **Survival:** Spawn continuo senza pause
- **Time Attack:** Timer con wave accelerate
- **Zen Mode:** Spawn rilassato, no game over
- **Tunnel:** Arena side-scroller con ostacoli
- **Endless Boss:** Boss random infiniti
- **Daily Challenge:** Seed giornaliero, wave fisse

### Score System (`score_system.dart`)

```
Score = base_points × multiplier × difficulty_modifier

Multiplier:
  - +1 per geom raccolto
  - Cap: 9999x
  - Reset a 1x alla morte del player

Extra vite a milestone:
  10K, 100K, 1M, 10M, 100M, 1B punti
```

### PowerUp System (`powerup_system.dart`)

Spawn random ogni 15-30 secondi nell'arena.
8 tipi con colori distinti e durata limitata.

### Audio System (`audio_system.dart`)

Attualmente solo haptic feedback (vibrazione):
- Light: raccolta geom, sparo
- Medium: nemico morto, power-up
- Heavy: bomba, boss kill, player hit

Predisposto per file audio futuri.

---

## UI Layer

### Navigazione Schermate

```
SplashScreen → MainMenu
                  ├── ModeSelectScreen → GameScreen → PauseScreen
                  │                          └── GameOverScreen
                  ├── ShopScreen
                  ├── LeaderboardScreen
                  ├── StatsScreen
                  ├── AchievementsScreen
                  ├── ModifiersScreen
                  └── SettingsScreen
```

### GameScreen (`game_screen.dart`)

Integrazione Flutter + Flame:
```dart
Stack(
  children: [
    GameWidget(game: geometryFightGame),  // Flame engine
    GameHud(game: geometryFightGame),     // Flutter overlay
    VirtualJoystick(side: left),          // Movimento
    VirtualJoystick(side: right),         // Mira/sparo
  ],
)
```

### HUD (`hud.dart`)

Display in-game:
- Score con multiplier animato
- Wave counter
- Lives (icone cuore)
- Bombs counter
- Geom count
- Power-up attivi con timer
- Boss HP bar (durante boss fight)

---

## Performance & Ottimizzazioni

### Rendering

| Tecnica | Dove | Impatto |
|---|---|---|
| **Skip-frame flash** | Spawn invulnerability | Evita `saveLayer` (catastrofico con 100+ nemici) |
| **LOD system** | `renderShape(canvas, paint, scale)` | `scale=1.0` skip dettagli, `scale=1.02` li mostra |
| **Static Paint cache** | `EnemyBase.detailPaint` | Un Paint condiviso vs allocazione per-frame |
| **Path caching** | GridDistortion | Riusa Path tra frame se nodi non cambiano |
| **Paint pooling** | GridDistortion | Pool di Paint objects pre-allocati |

### Iterazione Entità

| Pattern | Dove | Perché |
|---|---|---|
| **Deferred removal** | BlackHole absorb, Shield repel | `removeFromParent()` durante `for...in` → `ConcurrentModificationError` |
| **Throttling (ogni 3 frame)** | Shield `_repelNearbyBullets()` | Iterazione world children ogni frame troppo costosa |
| **Cap max entità** | Fear (max 5 nemici per impatto) | Limita iterazione per bullet hit |
| **Spatial Hash** | Query di raggio generiche | O(1) lookup vs O(n) iteration |

### Memory

| Tecnica | Dove |
|---|---|
| Evitato `.toList()` su world.children | BlackHole (alloca copia di TUTTI i children ogni frame) |
| Lifetime auto-despawn | Proton (5s), Gate (30s), effetti particella |
| `removeFromParent()` su fuori-arena | Proiettili, geom in tunnel mode |

---

## Pattern Architetturali

### 1. Template Method Pattern
`EnemyBase.update()` definisce il flusso (spawn invuln → fear → behavior → clamp), le subclassi override solo `updateBehavior()`.

### 2. Deferred Removal Pattern
```dart
// SBAGLIATO: ConcurrentModificationError
for (final child in game.world.children) {
  if (shouldRemove(child)) child.removeFromParent();  // 💥
}

// CORRETTO: Collect then remove
final toRemove = <Component>[];
for (final child in game.world.children) {
  if (shouldRemove(child)) toRemove.add(child);
}
for (final c in toRemove) c.removeFromParent();  // ✅
```

### 3. Double-Kill Guard
```dart
bool _dead = false;

void onDeath() {
  if (_dead) return;  // Guard
  _dead = true;
  // ... spawn geoms, explosion, etc.
  removeFromParent();
}
```
Necessario quando un nemico può morire da più fonti nello stesso frame (es. BlackHole: takeDamage + _explodeIntoProtons).

### 4. Spawn Invulnerability Cascade
Aggiungere spawn invulnerability a EnemyBase richiede check in TUTTI i punti di collisione:
- `PlayerBullet.onCollisionStart` → check prima di consumarsi
- `PlasmaBullet.onCollisionStart` → check prima dell'esplosione
- `HomingMissile.onCollisionStart` → check prima di consumarsi
- `Player.onCollisionStart` → check prima di takeDamage
- Nemici in-game (Proton, Splitter figli, Snake coda) → `clearSpawnInvulnerability()`

### 5. Component vs EnemyBase Decision
**GateEnemy estende PositionComponent**, non EnemyBase, perché:
- Non deve essere uccidibile dai proiettili
- Non ha HP nel senso tradizionale
- È un oggetto interattivo, non un nemico combattibile
- Richiede gestione speciale nello spawn (bypass difficulty scaling)

---

## Game Modes

| Modalità | Descrizione | Wave | Spawn |
|---|---|---|---|
| **Classic** | 100 wave + 15 boss | 100 | Standard |
| **Boss Rush** | Solo boss consecutivi | ∞ | Solo boss |
| **Survival** | Spawn infinito crescente | ∞ | Continuo |
| **Time Attack** | Timer con wave veloci | Limitate | Accelerato |
| **Zen Mode** | Rilassante, no game over | ∞ | Lento |
| **Tunnel** | Side-scroller con ostacoli | ∞ | Laterale |
| **Endless Boss** | Boss random infiniti | ∞ | Solo boss |
| **Daily Challenge** | Seed giornaliero | Fisse | Deterministic |

---

## Flusso di Gioco

```
App Start
  └→ Hive init (save, leaderboard, achievements)
  └→ SplashScreen
  └→ MainMenu
      └→ ModeSelect (mode + difficulty + modifiers)
          └→ GameScreen
              └→ GeometryFightGame.onLoad()
                  ├→ SpaceBackground
                  ├→ GridDistortion (50×50)
                  ├→ Player (centro arena)
                  └→ WaveSystem.start()
                      └→ GAME LOOP:
                          ├→ Wave Intro (countdown)
                          ├→ Spawn nemici (con delay)
                          │   ├→ 70% mob → caos
                          │   └→ 30% pericolosi → strategia
                          ├→ Player spara → proiettili
                          │   └→ Hit nemico → fear nearby
                          │   └→ Kill nemico → geom + explosion
                          │       └→ Player raccoglie geom → multiplier++
                          ├→ Check wave completata
                          │   ├→ YES → next wave / boss intro
                          │   └→ NO → continua spawn
                          ├→ Boss wave:
                          │   ├→ Boss intro animation
                          │   ├→ Multi-phase fight
                          │   └→ Boss kill → loot + next wave
                          ├→ Player muore:
                          │   ├→ Lives > 0 → respawn + invincibility
                          │   └→ Lives == 0 → Game Over
                          └→ Game Over:
                              ├→ Save score to leaderboard
                              ├→ Check achievements
                              ├→ Award gold geoms
                              └→ GameOverScreen (stats, retry)
```

---

## Dipendenze

```yaml
dependencies:
  flutter: sdk
  flame: ^1.x          # Game engine
  hive_flutter: ^1.x   # Local storage
  shared_preferences    # Settings
```

---

> Documento generato il 29/03/2026
> Geometry Fight 2 v2.0 — Flutter + Flame Engine
