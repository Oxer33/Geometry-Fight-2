# AUDIT MASSIVO — Tracking copertura review

**Totale file Dart:** 93
**Target:** 100% review + fix critical bugs

## Legenda
- ✅ = review completa + fix applicati
- 🟡 = review parziale / noti issue rimanenti / non-critical
- ❌ = non review deep
- ⏳ = agent in corso

## Data

| File | Status | Note |
|------|--------|------|
| lib/data/achievements.dart | ✅ | Hive late-init guards added |
| lib/data/constants.dart | 🟡 | Costanti, solo lettura — no bug |
| lib/data/crash_reporter.dart | ✅ | Serialized write chain |
| lib/data/difficulty.dart | 🟡 | powerUpDropRate description mismatch (0.5% easy) |
| lib/data/leaderboard.dart | ✅ | Late-init guards |
| lib/data/modifiers.dart | 🟡 | Data only |
| lib/data/save_data.dart | ✅ | Late-init guards |
| lib/data/wave_configs.dart | ✅ | Gate spawn fix |

## Effects

| File | Status | Note |
|------|--------|------|
| lib/game/effects/explosion.dart | ✅ | FR-damping fix + Paint cache |
| lib/game/effects/grid_distortion.dart | ✅ | NaN guards tightened |
| lib/game/effects/screen_shake.dart | ❌ | Non review deep |
| lib/game/effects/space_background.dart | ✅ | LRU shader cache |
| lib/game/effects/tunnel_renderer.dart | ✅ | Precompute strie/stars + wall clamp |

## Bosses

| File | Status | Note |
|------|--------|------|
| lib/game/entities/bosses/astral_sentinel_boss.dart | ✅ | Wind-up fade fix + queue safe |
| lib/game/entities/bosses/boss_base.dart | ✅ | Queue cap + Y osc fix + ListQueue |
| lib/game/entities/bosses/chrono_wraith_boss.dart | ✅ | Reverse iter + NaN guard |
| lib/game/entities/bosses/crimson_crown_boss.dart | 🟡 | Clean — minor review |
| lib/game/entities/bosses/eternity_engine_boss.dart | ✅ | NaN + rng cache |
| lib/game/entities/bosses/graviton_boss.dart | ✅ | Player clamp |
| lib/game/entities/bosses/hydra_boss.dart | ✅ | Rage timer + comment fix |
| lib/game/entities/bosses/inferno_boss.dart | ✅ | Trail cooldown |
| lib/game/entities/bosses/mirror_master_boss.dart | 🟡 | Review done, skip bullet-rain (intentional) |
| lib/game/entities/bosses/nexus_prime_boss.dart | ✅ | Satellite damage NaN guard |
| lib/game/entities/bosses/omega_core_boss.dart | ✅ | Rng consolidation |
| lib/game/entities/bosses/phantom_king_boss.dart | ✅ | Attack timer reset |
| lib/game/entities/bosses/prism_hunter_boss.dart | ❌ | Non review deep |
| lib/game/entities/bosses/singularity_boss.dart | ✅ | Player clamp + rng |
| lib/game/entities/bosses/swarm_mother_boss.dart | ✅ | Paint + rng |
| lib/game/entities/bosses/swarm_queen_boss.dart | ✅ | Shield paint cache |
| lib/game/entities/bosses/tesla_lord_boss.dart | ✅ | Rng consolidation |
| lib/game/entities/bosses/the_architect_boss.dart | ✅ | NaN guards + rng |
| lib/game/entities/bosses/the_grid_boss.dart | ✅ | NaN + Paint cache |
| lib/game/entities/bosses/void_kraken_boss.dart | ✅ | Player clamp |
| lib/game/entities/bosses/void_reaper_boss.dart | ✅ | Damage grace + rng |

## Enemies

| File | Status | Note |
|------|--------|------|
| lib/game/entities/enemies/black_hole_enemy.dart | ✅ | Exclude proton kill |
| lib/game/entities/enemies/decoy_enemy.dart | ✅ | Paint cache |
| lib/game/entities/enemies/drone_enemy.dart | ✅ | Paint cache |
| lib/game/entities/enemies/enemy_base.dart | 🟡 | Arena clamp review done — no critical |
| lib/game/entities/enemies/gate_enemy.dart | 🟡 | Review done — spawn-grace concerns noted |
| lib/game/entities/enemies/glitch_enemy.dart | ✅ | Paint cache |
| lib/game/entities/enemies/gravity_well_enemy.dart | 🟡 | Doc mismatch (control inversion missing) |
| lib/game/entities/enemies/healer_enemy.dart | ✅ | Paint cache + NaN |
| lib/game/entities/enemies/kamikaze_enemy.dart | 🟡 | Review done — arena clamp on rush missing |
| lib/game/entities/enemies/laser_turret_enemy.dart | ✅ | Paint cache |
| lib/game/entities/enemies/leech_enemy.dart | ✅ | Paint caches |
| lib/game/entities/enemies/mine_enemy.dart | 🟡 | Review — no double onEnemyKilled |
| lib/game/entities/enemies/mirror_enemy.dart | ✅ | Paint cache + NaN |
| lib/game/entities/enemies/mutator_enemy.dart | ✅ | HP clamp order |
| lib/game/entities/enemies/necro_enemy.dart | ✅ | Paint cache + NaN |
| lib/game/entities/enemies/orbiter_enemy.dart | ✅ | Paint cache + NaN |
| lib/game/entities/enemies/phantom_enemy.dart | 🟡 | Fade-in hitbox immune (skip, invasive) |
| lib/game/entities/enemies/proton_enemy.dart | ✅ | Paint cache + NaN |
| lib/game/entities/enemies/pulsar_enemy.dart | ✅ | Paint cache + NaN |
| lib/game/entities/enemies/shield_enemy.dart | ✅ | Paint cache |
| lib/game/entities/enemies/siren_enemy.dart | ✅ | Push 2x fix |
| lib/game/entities/enemies/snake_enemy.dart | ✅ | Tunnel X despawn |
| lib/game/entities/enemies/spawner_enemy.dart | ✅ | Paint + rng cache |
| lib/game/entities/enemies/splitter_enemy.dart | 🟡 | Review done — NaN guard already present |
| lib/game/entities/enemies/swarm_drone_enemy.dart | ✅ | setMarchDirection + rng |
| lib/game/entities/enemies/tesla_enemy.dart | ✅ | myIndex accumulator fix |
| lib/game/entities/enemies/time_bomb_enemy.dart | ✅ | TextPainter cache + double-call guard |
| lib/game/entities/enemies/titan_enemy.dart | ✅ | Player clamp |
| lib/game/entities/enemies/vortex_enemy.dart | ✅ | Paint style leak fix |
| lib/game/entities/enemies/weaver_enemy.dart | ✅ | NaN guards |

## Entities core

| File | Status | Note |
|------|--------|------|
| lib/game/entities/geom.dart | 🟡 | Review done — minor |
| lib/game/entities/player.dart | ✅ | TimeScale clamp |
| lib/game/entities/powerups.dart | 🟡 | smartBomb capacity already guarded |
| lib/game/entities/projectiles.dart | ✅ | NaN guards + realDt clamp |

## Game world + systems

| File | Status | Note |
|------|--------|------|
| lib/game/game_world.dart | ✅ | Restart fixes + session guard |
| lib/game/systems/audio_system.dart | ✅ | Init double-check |
| lib/game/systems/music_manager.dart | ✅ | Seq-owned mutex |
| lib/game/systems/powerup_system.dart | ✅ | Reset consistency |
| lib/game/systems/score_system.dart | 🟡 | Position param unused (nit) |
| lib/game/systems/wave_system.dart | ✅ | Pending boss + effectiveArena |

## Main

| File | Status | Note |
|------|--------|------|
| lib/main.dart | 🟡 | Review done — Hive wipe concern noted |

## UI HUD

| File | Status | Note |
|------|--------|------|
| lib/ui/hud.dart | ✅ | Timer.periodic + Paint caches (BossHp/Arrow/Life/Geom/NeonBar) |

## UI Screens

| File | Status | Note |
|------|--------|------|
| lib/ui/screens/achievements_screen.dart | ✅ | Cache initState |
| lib/ui/screens/game_over_screen.dart | ❌ | Paint churn noted, non fixato |
| lib/ui/screens/game_screen.dart | 🟡 | Retry race + Future.delayed noted |
| lib/ui/screens/leaderboard_screen.dart | ✅ | Cached entries |
| lib/ui/screens/main_menu.dart | ❌ | Paint storm (5+ painters) — mega refactor |
| lib/ui/screens/mode_select_screen.dart | 🟡 | SaveManager.save unawaited noted |
| lib/ui/screens/modifiers_screen.dart | ❌ | Non review deep |
| lib/ui/screens/pause_screen.dart | ❌ | Particles paint churn noted |
| lib/ui/screens/settings_screen.dart | 🟡 | Prefs batch concern noted |
| lib/ui/screens/shop_screen.dart | ❌ | Paint alloc storm (3000/sec) — MEGA refactor |
| lib/ui/screens/splash_screen.dart | ✅ | Double-fire guard |
| lib/ui/screens/stats_screen.dart | ✅ | Cached counters |

## UI Widgets

| File | Status | Note |
|------|--------|------|
| lib/ui/widgets/animated_builder_widget.dart | ✅ | Clean |
| lib/ui/widgets/neon_back_button.dart | ❌ | Non review deep |
| lib/ui/widgets/shared_painters.dart | ✅ | Paint cache |
| lib/ui/widgets/tutorial_overlay.dart | ❌ | Non review deep |
| lib/ui/widgets/virtual_joystick.dart | 🟡 | Review — no race (Flutter single-thread) |

## Utils

| File | Status | Note |
|------|--------|------|
| lib/utils/extensions.dart | 🟡 | Clean |

## Conteggio

- ✅ Full review + fix: 57 files
- 🟡 Review done, minor/intentional: 22 files
- ❌ Non review deep: 14 files

## TODO priorità

1. ❌ shop_screen.dart — Paint storm (3000 alloc/sec)
2. ❌ main_menu.dart — 5+ painters Paint/Path/Shader allocs
3. ❌ splash_screen.dart — nebula/explosion Paint allocs (parziale)
4. ❌ game_over_screen.dart — particles painter
5. ❌ pause_screen.dart — particles painter
6. ❌ prism_hunter_boss.dart — deep review
7. ❌ modifiers_screen.dart + mode_select + neon_back_button + tutorial_overlay — review
8. ❌ screen_shake.dart — edge cases parent swap
