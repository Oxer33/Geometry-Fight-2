# ARCHITETTURA - Geometry Fight 2

## Panoramica
Twin-stick shooter neon in stile Geometry Wars, sviluppato in Flutter con Flame Engine.
Arena 3000x3000 con camera che segue il player, dual joystick mobile, tastiera desktop.

## Stack Tecnologico
- **Engine**: Flame 1.36+ (FlameGame + GameWidget)
- **State Management**: Riverpod (predisposto, non ancora utilizzato ovunque)
- **Persistenza**: Hive + SharedPreferences
- **Audio**: flame_audio (predisposto)
- **Linguaggio**: Dart / Flutter

---

## Struttura Directory

```
lib/
├── main.dart                          # Entry point, navigazione, init Hive
├── data/
│   ├── constants.dart                 # Costanti di gioco (arena, player, armi, colori neon)
│   ├── save_data.dart                 # SaveData model + SaveManager con Hive
│   └── wave_configs.dart              # Enum nemici/boss, configurazioni wave 1-50+
├── game/
│   ├── game_world.dart                # FlameGame principale, spawn, input, game state
│   ├── effects/
│   │   ├── explosion.dart             # ExplosionEffect + FloatingText
│   │   ├── grid_distortion.dart       # Griglia deformabile con spring simulation
│   │   ├── screen_shake.dart          # Camera shake
│   │   └── space_background.dart      # Sfondo spaziale con stelle, nebulose, polvere cosmica
│   ├── entities/
│   │   ├── player.dart                # Player con 8 armi, power-up, shield, movimento
│   │   ├── projectiles.dart           # PlayerBullet, EnemyBullet, Laser, Plasma, Homing, Overdrive
│   │   ├── geom.dart                  # Cristalli raccoglibili (valuta)
│   │   ├── powerups.dart              # 8 tipi power-up con enum e logica
│   │   ├── enemies/
│   │   │   ├── enemy_base.dart        # Classe base astratta per tutti i nemici
│   │   │   ├── drone_enemy.dart       # Rombo rosa - seek diretto
│   │   │   ├── snake_enemy.dart       # Catena verde - segui testa
│   │   │   ├── mine_enemy.dart        # Stella grigia - esplode vicino
│   │   │   ├── spawner_enemy.dart     # Esagono arancione - genera Drone
│   │   │   ├── weaver_enemy.dart      # Rombo azzurro - zigzag sinusoidale
│   │   │   ├── bouncer_enemy.dart     # Cerchio giallo - rimbalza sui muri
│   │   │   ├── splitter_enemy.dart    # Triangolo bianco - si divide 3 volte
│   │   │   ├── shield_enemy.dart      # Cerchio viola - scudo frontale
│   │   │   ├── black_hole_enemy.dart  # Cerchio nero/rosso - attrae tutto
│   │   │   ├── kamikaze_enemy.dart    # Freccia rossa - rush velocissimo
│   │   │   ├── pulsar_enemy.dart      # Stella teal - emette onde
│   │   │   ├── mirror_enemy.dart      # Rombo magenta - riflette proiettili
│   │   │   ├── phantom_enemy.dart     # Cerchio blu - diventa invisibile
│   │   │   ├── vortex_enemy.dart      # Esagono viola - crea vortice
│   │   │   ├── leech_enemy.dart       # ✨ NUOVO - Parassita verde acido - si aggancia e rallenta
│   │   │   ├── titan_enemy.dart       # ✨ NUOVO - Tank bronzo - corazzato con onda d'urto
│   │   │   └── glitch_enemy.dart      # ✨ NUOVO - Quadrato ciano - si teletrasporta
│   │   └── bosses/
│   │       ├── boss_base.dart         # Classe base boss con fasi e barra HP
│   │       ├── the_grid_boss.dart     # Wave 10 - Quadrato con pattern proiettili
│   │       ├── hydra_boss.dart        # Wave 20 - Nucleo + 4 teste rigenerabili
│   │       ├── singularity_boss.dart  # Wave 30 - Gravità e cloni
│   │       ├── swarm_mother_boss.dart # Wave 40 - Si divide in 2
│   │       ├── the_architect_boss.dart# Wave 45 - Costruttore
│   │       └── chrono_wraith_boss.dart# Wave 50 - Manipolazione tempo
│   ├── systems/
│   │   ├── wave_system.dart           # Generazione ondate, boss ogni 10 wave, endless mode
│   │   ├── score_system.dart          # Score, moltiplicatore, combo, geomi
│   │   └── powerup_system.dart        # Spawn periodico power-up nell'arena
│   └── weapons/                       # (directory vuota - armi gestite in player.dart)
├── ui/
│   ├── hud.dart                       # HUD moderna glassmorphism con score, vite, bombe, wave
│   ├── widgets/
│   │   ├── animated_builder_widget.dart # NeonAnimatedBuilder riutilizzabile
│   │   └── virtual_joystick.dart      # Joystick visuale neon con thumb mobile
│   └── screens/
│       ├── main_menu.dart             # Menu principale con geometrie fluttuanti
│       ├── game_screen.dart           # Schermata gioco con dual joystick e bomba
│       ├── pause_screen.dart          # Overlay pausa semi-trasparente
│       ├── game_over_screen.dart      # Score finale + retry
│       ├── shop_screen.dart           # Shop con 5 categorie
│       └── settings_screen.dart       # Volume, vibrazione, reset
└── utils/
    ├── extensions.dart                # Helper Vector2 e Color
    └── spatial_hash.dart              # Collision detection ottimizzata O(n)
```

---

## Flusso di Gioco
1. `main.dart` → init Hive → NavigationWrapper
2. MainMenuScreen → seleziona PLAY
3. GameScreen crea GeometryFightGame (FlameGame)
4. onLoad: SpaceBackground → GridDistortion → Player → WaveSystem.startWave(1)
5. update loop: input → spatial hash → systems → camera follow → super.update
6. WaveSystem spawna nemici progressivamente, boss ogni 10 wave
7. Game Over → salva score/geomi → GameOverScreen

## Sistema Input (Dual-Stick)
- **Mobile**: VirtualJoystick (sinistro=MOVE, destro=AIM+SHOOT)
- **Desktop**: WASD/frecce per movimento, frecce per aim
- **Flag**: `usingTouchMove`/`usingTouchAim` impediscono conflitti touch/keyboard

## Nemici: 17 Tipi
| # | Nome | Colore | Wave | HP | Comportamento |
|---|------|--------|------|----|---------------|
| 1 | Drone | Rosa | 1 | 1 | Seek diretto |
| 2 | Snake | Verde | 3 | 1/seg | Catena che segue |
| 3 | Mine | Grigio | 2 | 2 | Esplode vicino |
| 4 | Spawner | Arancione | 5 | 15 | Genera Drone |
| 5 | Weaver | Azzurro | 4 | 2 | Zigzag sinusoidale |
| 6 | Bouncer | Giallo | 4 | 3 | Rimbalza sui muri |
| 7 | Splitter | Bianco | 6 | 1 | Si divide x3 |
| 8 | Shield | Viola | 7 | 3+5 | Scudo frontale |
| 9 | Black Hole | Rosso scuro | 8 | 20 | Attrae tutto |
| 10 | Kamikaze | Rosso | 5 | 1 | Rush veloce |
| 11 | Pulsar | Teal | 9 | 4 | Emette onde |
| 12 | Mirror | Magenta | 11 | 3 | Riflette proiettili |
| 13 | Phantom | Blu | 13 | 3 | Invisibile |
| 14 | Vortex | Viola scuro | 15 | 6 | Crea vortice |
| 15 | Leech | Verde acido | 12 | 2 | Si aggancia, rallenta |
| 16 | Titan | Bronzo | 14 | 25 | Tank con onda d'urto |
| 17 | Glitch | Ciano | 16 | 3 | Si teletrasporta |

## Boss: 6 Tipi
| Boss | Wave | HP | Meccanica principale |
|------|------|----|---------------------|
| The Grid | 10 | 500 | Pattern proiettili + fasi |
| Hydra | 20 | 800 | 4 teste rigenerabili |
| Singularity | 30 | 1200 | Gravità + cloni |
| Swarm Mother | 40 | 2000 | Si divide in 2 metà |
| The Architect | 45 | 1500 | Costruisce strutture |
| Chrono Wraith | 50 | 1800 | Manipola il tempo |

---

## Sistema Difficoltà
| Livello | HP Nemici | Velocità | Spawn | Power-up Drop | Score | Vite |
|---------|-----------|----------|-------|---------------|-------|------|
| Facile | x0.7 | x0.8 | x0.7 | 10% | x0.5 | 5 |
| Normale | x1.0 | x1.0 | x1.0 | 5% | x1.0 | 3 |
| Difficile | x1.5 | x1.2 | x1.3 | 3% | x2.0 | 2 |
| Incubo | x2.0 | x1.4 | x1.6 | 2% | x4.0 | 1 |

## Modalità di Gioco
| Modalità | Costo | Descrizione |
|----------|-------|-------------|
| Classica | Free | 50 wave + boss ogni 10 |
| Boss Rush | 2000 GG | Solo boss in sequenza |
| Sopravvivenza | 2500 GG | Ondate infinite, no pausa |
| Attacco a Tempo | 1500 GG | Max punti in 3 minuti |
| Zen | 1000 GG | Vite infinite, relax |

## Nuove Schermate (v2)
- `splash_screen.dart` - Splash di avvio con logo animato
- `mode_select_screen.dart` - Selezione modalità + difficoltà
- `leaderboard_screen.dart` - Classifica locale top 10

## Ultimo aggiornamento: Marzo 2026
