enum EnemyType {
  drone,
  snake,
  mine,
  spawner,
  weaver,
  splitter,
  shieldEnemy,
  blackHole,
  kamikaze,
  // New enemy types
  pulsar,
  mirror,
  phantom,
  vortex,
  leech,
  titan,
  glitch,
  healer,
  orbiter,
  siren,
  necro,
  tesla,
  gravityWell,
  swarmDrone,
  laserTurret,
  timeBomb,
  decoy,
  // GW:RE2 mechanics
  gate,     // Gate: due sfere + linea, player ci passa attraverso → esplosione
  proton,   // Proton: mini nemico veloce da esplosione buco nero
  mutator,  // Mutator: potenzia altri nemici al contatto
}

enum BossType {
  theGrid,
  hydra,
  singularity,
  swarmMother,
  // New bosses
  theArchitect,
  chronoWraith,
  nexusPrime,
  voidReaper,
  teslaLord,
  phantomKing,
  omegaCore,
  // Batch 3 bosses
  mirrorMaster,
  swarmQueen,
  graviton,
  inferno,
  eternityEngine,
  // Batch 4 — 4 nuovi boss (richiesta utente: "aggiungere 4 nuovi boss con
  // meccaniche uniche, FX spettacolari") per coprire i 20 slot boss della
  // modalità classica (ogni wave multipla di 5).
  crimsonCrown,    // wave 5   — orbi fuoco + lava mines
  prismHunter,     // wave 15  — laser sweeping + rainbow bullet hell
  voidKraken,      // wave 25  — gravity pull + ink cloud + proton spawn
  astralSentinel,  // wave 35  — poligono laser + star constellation gate
}

/// Formazione spawn per un gruppo di nemici. Mirror pubblico di `_Formation`
/// privato in `wave_system.dart` (single source of truth lì, ma esposto qui
/// così le wave config "signature" possono dichiarare il pattern desiderato).
///
/// WaveSystem traduce SpawnFormation → _Formation via switch in
/// `_spawnGroupWithFormation`. Se il `WaveSpawn.formation` è null, fallback
/// alla mappa per-wave `_classicFormation`.
enum SpawnFormation {
  ring,
  diamond,
  cross,
  triangle,
  flower,
  star5,
  pinwheel,
  comet,
  infinity8,
  doubleSpiral,
  honeycomb,
  wShape,
  hexagon,
  tripleRing,
  sineWave,
  cascade,
  squareRing,
  burst,
  arrowHead,
  scatter,
  doublering,
  vArrow,
  xShape,
  arc,
  zigzag,
  borderLine,
  playerRing,        // ring centrato sul player
  playerDoubleRing,  // 2 ring concentrici sul player
  playerEncircle,    // encircle 360° con offset
}

class WaveSpawn {
  final EnemyType type;
  final int count;
  final double delay; // seconds before this group spawns
  /// Override formation per questo gruppo (signature waves). Se null,
  /// WaveSystem usa `_classicFormation[wave][groupIdx]`.
  final SpawnFormation? formation;

  const WaveSpawn(this.type, this.count, {this.delay = 0, this.formation});
}

/// Modificatore globale per una wave classic.
///
/// Cambia stat/comportamento dei mob spawnati durante la wave per dare
/// varietà strategica e ridurre la "ripetitività" delle wave (richiesta
/// utente: "il sistema delle wave è ancora un pò banale").
///
/// Implementazione: ogni mob legge il modifier da [GeometryFightGame.spawnEnemy]
/// → applica multiplier su `hp`/`speed`/visual. Score+geom multiplier
/// applicati lato `ScoreSystem.addKill` / drop logic. Banner mostrato
/// in HUD a wave-start.
///
/// Solo modalità classica: tunnel/zen/boss-rush/time-attack restano
/// vanilla per non rompere il loro balancing.
enum WaveModifier {
  /// Nessun modifier (default). Wave normale.
  none,

  /// Mob più veloci (+35% speed). Aumenta pressione movimento.
  frenzy,

  /// Mob più resistenti (×1.6 HP). Più colpi per kill.
  tank,

  /// Mob fragili (×0.4 HP) ma punti ×1.6. High-risk/reward arcade.
  glass,

  /// Doppio drop geom (×2 geomValue). Wave "farm" rara.
  loot,

  /// +50% mob count. Più caos visivo, focus dodge.
  blitz,

  /// Spawn delay -40%. Ondate quasi simultanee, no respiro.
  haste,

  /// Magnete geom raddoppiato (radius ×2). Wave "loot vacuum".
  magnetic,

  /// HP ×1.3 + speed ×0.75. Tank lenti, easy hit ma drag-out.
  iron,
}

/// Display name + tag color per HUD banner.
extension WaveModifierUi on WaveModifier {
  String get displayName {
    switch (this) {
      case WaveModifier.none: return '';
      case WaveModifier.frenzy: return 'FRENZY';
      case WaveModifier.tank: return 'TANK';
      case WaveModifier.glass: return 'GLASS';
      case WaveModifier.loot: return 'LOOT';
      case WaveModifier.blitz: return 'BLITZ';
      case WaveModifier.haste: return 'HASTE';
      case WaveModifier.magnetic: return 'MAGNETIC';
      case WaveModifier.iron: return 'IRON';
    }
  }

  String get tagline {
    switch (this) {
      case WaveModifier.none: return '';
      case WaveModifier.frenzy: return 'mob +35% velocità';
      case WaveModifier.tank: return 'mob ×1.6 HP';
      case WaveModifier.glass: return 'mob ×0.4 HP, punti ×1.6';
      case WaveModifier.loot: return 'doppi geom drop';
      case WaveModifier.blitz: return '+50% nemici';
      case WaveModifier.haste: return 'ondate ravvicinate';
      case WaveModifier.magnetic: return 'magnete geom ×2';
      case WaveModifier.iron: return 'tank lenti';
    }
  }

  /// Hex color per banner (ARGB 0xAARRGGBB).
  int get tagColorArgb {
    switch (this) {
      case WaveModifier.none: return 0xFFFFFFFF;
      case WaveModifier.frenzy: return 0xFFFF6633;
      case WaveModifier.tank: return 0xFF3388FF;
      case WaveModifier.glass: return 0xFFFF00AA;
      case WaveModifier.loot: return 0xFFFFD700;
      case WaveModifier.blitz: return 0xFFFFAA00;
      case WaveModifier.haste: return 0xFF00FFCC;
      case WaveModifier.magnetic: return 0xFF00FFFF;
      case WaveModifier.iron: return 0xFF888888;
    }
  }
}

class WaveConfig {
  final int waveNumber;
  final List<WaveSpawn> spawns;
  final BossType? boss;
  /// Modificatore globale (solo classic mode, non-boss). Default `none`.
  final WaveModifier modifier;

  const WaveConfig({
    required this.waveNumber,
    required this.spawns,
    this.boss,
    this.modifier = WaveModifier.none,
  });
}

// ═══════════════════════════════════════════════════════════════════════
// BOSS PLACEMENT — richiesta utente: un boss ad ogni wave multipla di 5.
// 100 waves / 5 = 20 slot boss. 16 boss esistenti + 4 nuovi = 20 esatti.
// Ordine scelto per escalation di difficoltà (boss più dinamici prima,
// boss "bullet hell" e finali nelle wave alte).
// ═══════════════════════════════════════════════════════════════════════
const Map<int, BossType> _classicBossSchedule = {
  5: BossType.crimsonCrown,    // NEW — primo boss "tutorial" meccanico
  10: BossType.theGrid,
  15: BossType.prismHunter,     // NEW — sweeping laser
  20: BossType.hydra,
  25: BossType.voidKraken,      // NEW — gravity pull
  30: BossType.singularity,
  35: BossType.astralSentinel,  // NEW — constellation gate
  40: BossType.swarmMother,
  45: BossType.theArchitect,
  50: BossType.chronoWraith,
  55: BossType.nexusPrime,
  60: BossType.voidReaper,
  65: BossType.teslaLord,
  70: BossType.phantomKing,
  75: BossType.omegaCore,
  80: BossType.mirrorMaster,
  85: BossType.swarmQueen,
  90: BossType.graviton,
  95: BossType.inferno,
  100: BossType.eternityEngine,
};

// Spawn "entourage" pre-boss. Wave bassi (5-50) = piccoli entourage leggeri
// per non lasciare l'arena sterile durante il boss fight. Wave alti (55+) =
// entourage pesanti già presenti.
const Map<int, List<WaveSpawn>> _bossEntourageSpawns = {
  // Early bosses entourage (leggero, per varietà).
  5: [WaveSpawn(EnemyType.drone, 8, delay: 3)],
  15: [WaveSpawn(EnemyType.kamikaze, 6, delay: 3)],
  25: [WaveSpawn(EnemyType.weaver, 6, delay: 3)],
  35: [WaveSpawn(EnemyType.swarmDrone, 20, delay: 3)],
  45: [WaveSpawn(EnemyType.shieldEnemy, 4, delay: 3)],
  50: [WaveSpawn(EnemyType.splitter, 4), WaveSpawn(EnemyType.snake, 4, delay: 3)],
  // Mid/late bosses entourage (preservati).
  55: [WaveSpawn(EnemyType.tesla, 6), WaveSpawn(EnemyType.orbiter, 8, delay: 2)],
  60: [WaveSpawn(EnemyType.healer, 4), WaveSpawn(EnemyType.siren, 6, delay: 2)],
  65: [WaveSpawn(EnemyType.tesla, 10), WaveSpawn(EnemyType.necro, 4, delay: 3)],
  70: [WaveSpawn(EnemyType.phantom, 8), WaveSpawn(EnemyType.glitch, 6, delay: 2)],
  75: [WaveSpawn(EnemyType.titan, 6), WaveSpawn(EnemyType.healer, 4, delay: 3)],
  80: [WaveSpawn(EnemyType.mirror, 8), WaveSpawn(EnemyType.decoy, 10, delay: 2)],
  85: [WaveSpawn(EnemyType.swarmDrone, 40), WaveSpawn(EnemyType.healer, 4, delay: 3)],
  90: [WaveSpawn(EnemyType.gravityWell, 4), WaveSpawn(EnemyType.blackHole, 2, delay: 4)],
  95: [WaveSpawn(EnemyType.kamikaze, 20), WaveSpawn(EnemyType.timeBomb, 6, delay: 3)],
  100: [
    WaveSpawn(EnemyType.titan, 8),
    WaveSpawn(EnemyType.tesla, 10, delay: 2),
    WaveSpawn(EnemyType.healer, 6, delay: 4)
  ],
};

List<WaveConfig> generateWaveConfigs() {
  final configs = <WaveConfig>[];
  // Ring buffer ultimi 3 archetipi scelti → no ripetizione consecutiva.
  final history = <int>[];
  // Ring buffer modifier — unreached dopo disable auto-modifier (utente).
  // ignore: unused_local_variable
  final modHistory = <int>[];

  for (int wave = 1; wave <= 100; wave++) {
    // Boss wave: ogni wave multipla di 5.
    final bossType = _classicBossSchedule[wave];
    if (bossType != null) {
      configs.add(WaveConfig(
        waveNumber: wave,
        spawns: _bossEntourageSpawns[wave] ?? const [],
        boss: bossType,
      ));
      continue;
    }

    // ═══════════════════════════════════════════════════════════════
    // SIGNATURE WAVE OVERRIDE — wave hand-curated con tema/design unico
    // (richiesta utente: "il design di come dove e quali mob spawnano lo
    // rende unico"). 14 wave non-boss override l'archetype-pick:
    //   6  ENCIRCLE RUSH      cerchi drone attorno al player ogni 2.5s
    //   13 KAMIKAZE STORM     solo kamikaze, schiere alternate
    //   18 BLACKHOLE FIELD    solo black holes scattered
    //   27 DODGER STORM       solo phantom (mob "verdi" che dodgeano)
    //   33 MIRROR ARMY        solo mirror enemies (riflettono colpi)
    //   38 MINE FIELD         mine + qualche laser turret
    //   47 PINCER SIEGE       2 borderLine kamikaze simultanee
    //   53 TANK PARADE        titan + shield, advance lento
    //   58 PROTON STORM       proton + qualche black hole
    //   67 ENCIRCLE HARD      drone+weaver ring centrato player
    //   73 KAMIKAZE HELL      kamikaze ondate continue
    //   78 MIRROR FORTRESS    mirror+shield combo
    //   87 VOID FIELD         blackhole+proton field
    //   93 DODGER NIGHTMARE   phantom mass scaling
    // Modifier forzato a `none` per preservare il tema (no chaos da modifier
    // che cambia stat dei nemici signature).
    // ═══════════════════════════════════════════════════════════════
    final signature = _signatureWaveOverride(wave);
    if (signature != null) {
      configs.add(signature);
      continue;
    }

    // ═══════════════════════════════════════════════════════════════
    // ARCHETYPE SYSTEM (ispirato GW2:RE Sequence): 31 archetipi con 4
    // tier di difficoltà, random weighted per wave. Varietà massima
    // + escalation graduale + climax pre-boss (MEGASWARM tier 3+).
    // ═══════════════════════════════════════════════════════════════
    final archetype = _pickArchetype(wave, history);
    // Mob count × 2 (richiesta utente "almeno il doppio"). Post-process
    // del generator per non riscrivere tutti i 31 archetypi inline.
    // Cap a 300/spawn-group per evitare flood GC su MEGASWARM tier 3
    // (clamp pre-mult arrivava a 220 → ×2 = 440 in single batch).
    // Gate (1 unità) escluso dal moltiplicatore (aggiunto dopo).
    final spawns = archetype.generator(wave)
        .map((s) => WaveSpawn(
              s.type,
              (s.count * 2).clamp(1, 300),
              delay: s.delay,
            ))
        .toList();

    // ═══════════════════════════════════════════════════════════════
    // COMBO WAVE — wave 12+ (post-onboarding) hanno chance di chain di
    // un SECONDO archetipo. Riduce la sensazione "1 archetipo = 1 wave"
    // → più dinamica intra-wave (richiesta utente: "wave system banale").
    // Trigger deterministico (no RNG runtime): wave % 4 == 2 (12, 16, 22,
    // 26, ecc.) → 25% delle wave non-boss. Skip pre-boss (wave % 5 == 4)
    // perché già MEGASWARM-saturated.
    // ═══════════════════════════════════════════════════════════════
    final isPreBossWave = wave % 5 == 4;
    if (wave >= 12 && wave % 4 == 2 && !isPreBossWave) {
      final secondArchetype = _pickArchetype(wave + 1000, history);
      // Offset temporale: secondo archetipo arriva DOPO il primo —
      // somma del delay max del primo + 4s buffer per dare respiro.
      final firstMaxDelay = spawns.fold<double>(
          0.0, (m, s) => s.delay > m ? s.delay : m);
      final secondaryOffset = firstMaxDelay + 4.0;
      // Scala counts second archetype a 60% per evitare overflow caos.
      for (final s in secondArchetype.generator(wave)) {
        spawns.add(WaveSpawn(
          s.type,
          ((s.count * 2) * 0.6).round().clamp(1, 200),
          delay: s.delay + secondaryOffset,
        ));
      }
    }

    // Gate hazard raro: 1 ogni 10 wave non-boss (11, 21, 31, ...).
    if (wave >= 11 && wave % 10 == 1) {
      spawns.add(WaveSpawn(EnemyType.gate, 1, delay: 10));
    }

    // ═══════════════════════════════════════════════════════════════
    // WAVE MODIFIER — cambia regole della wave (FRENZY/TANK/GLASS/etc).
    // Picker: deterministico sul wave#, history-aware (no 2 consecutivi
    // uguali), skip wave 1-3 (onboarding pulito) e pre-boss (climax già
    // intenso). Probabilità ~50% → metà wave non-boss vanilla, metà
    // hanno una "regola speciale".
    // ═══════════════════════════════════════════════════════════════
    // AUTO-MODIFIER DISABILITATO (utente: "card modificatore tra un livello
    // e l'altro della modalità classica non va bene"). Solo i modificatori
    // SELEZIONATI manualmente pre-game si applicano. `_pickModifier` +
    // `modHistory` ora unreached ma kept in file.
    const modifier = WaveModifier.none;

    configs.add(WaveConfig(
      waveNumber: wave,
      spawns: spawns,
      modifier: modifier,
    ));
  }

  return configs;
}

/// Picker modifier deterministico. Fattori:
/// - Wave 1-3: sempre `none` (onboarding senza distrazioni).
/// - Pre-boss (wave % 5 == 4): sempre `none` (climax già intenso).
/// - Wave % 2 == 1: sempre `none` (alternanza vanilla / modificata →
///   ritmo "easy / spice / easy / spice" più digeribile).
/// - Resto: pick weighted dal pool [frenzy/tank/glass/loot/blitz/haste/
///   shadow/iron] usando hash deterministico, skip ultimi 2 in history.
// Auto-modifier disabilitato in classic (utente). Funzione mantenuta per
// futuro re-enable o modalità che la richiedano.
// ignore: unused_element
WaveModifier _pickModifier(
    int wave, List<int> history, bool isPreBoss) {
  if (wave <= 3) return WaveModifier.none;
  if (isPreBoss) return WaveModifier.none;
  if (wave % 2 == 1) return WaveModifier.none;

  // Pool indices su WaveModifier.values, escluso `none` (idx 0).
  const total = 8; // 8 modifier non-none
  final pool = <int>[];
  for (int i = 1; i <= total; i++) {
    if (history.contains(i)) continue;
    pool.add(i);
  }
  if (pool.isEmpty) {
    history.clear();
    for (int i = 1; i <= total; i++) {
      pool.add(i);
    }
  }

  // Hash deterministico → riproducibile (replay safe), variabile per
  // wave#. Stesso seed Knuth multiplier usato in `_pickArchetype`.
  final pickIdx = pool[(wave * 2654435761) % pool.length];
  history.add(pickIdx);
  if (history.length > 2) history.removeAt(0);
  return WaveModifier.values[pickIdx];
}

/// Signature wave: wave hand-curated con tema/pattern unico.
///
/// Ritorna `WaveConfig?` — null se la wave non è signature, in tal caso
/// `generateWaveConfigs` cade sul flow archetype-driven.
///
/// Design pattern (richiesta utente "il design di come dove e quali mob
/// spawnano lo rende unico"):
/// - 1 solo tipo di mob (o pochi) per "tema" riconoscibile.
/// - Formation specifica per group (es. playerRing per cerchi attorno).
/// - Delay scandito (2.5-4s) per dare ritmo "ondata-pausa-ondata".
/// - Modifier=none per non contaminare il tema con regole speciali.
WaveConfig? _signatureWaveOverride(int wave) {
  switch (wave) {
    // ── WAVE 6 — ENCIRCLE RUSH ──────────────────────────────────────────
    // Cerchi di drone attorno al player ogni 2.5s. Delays sono BETWEEN-GROUPS
    // (gap dal precedente), non absolute-from-start. Vedi
    // `_delayBeforeNextGroup` in wave_system.dart.
    case 6:
      return const WaveConfig(
        waveNumber: 6,
        spawns: [
          WaveSpawn(EnemyType.drone, 16,
              formation: SpawnFormation.playerRing, delay: 0),
          WaveSpawn(EnemyType.drone, 16,
              formation: SpawnFormation.playerRing, delay: 2.5),
          WaveSpawn(EnemyType.drone, 18,
              formation: SpawnFormation.playerRing, delay: 2.5),
          WaveSpawn(EnemyType.drone, 20,
              formation: SpawnFormation.playerDoubleRing, delay: 2.5),
        ],
      );

    // ── WAVE 13 — KAMIKAZE STORM ────────────────────────────────────────
    // Ondate kamikaze borderLine ogni 3s.
    case 13:
      return const WaveConfig(
        waveNumber: 13,
        spawns: [
          WaveSpawn(EnemyType.kamikaze, 18,
              formation: SpawnFormation.borderLine, delay: 0),
          WaveSpawn(EnemyType.kamikaze, 20,
              formation: SpawnFormation.borderLine, delay: 3.0),
          WaveSpawn(EnemyType.kamikaze, 22,
              formation: SpawnFormation.borderLine, delay: 3.0),
          WaveSpawn(EnemyType.kamikaze, 24,
              formation: SpawnFormation.scatter, delay: 3.0),
        ],
      );

    // ── WAVE 18 — BLACKHOLE FIELD ───────────────────────────────────────
    // Black holes 4s + 4s gap, poi drone scatter 3s dopo.
    case 18:
      return const WaveConfig(
        waveNumber: 18,
        spawns: [
          WaveSpawn(EnemyType.blackHole, 4,
              formation: SpawnFormation.cross, delay: 0),
          WaveSpawn(EnemyType.blackHole, 4,
              formation: SpawnFormation.diamond, delay: 4.0),
          WaveSpawn(EnemyType.drone, 30,
              formation: SpawnFormation.scatter, delay: 3.0),
        ],
      );

    // ── WAVE 27 — DODGER STORM ──────────────────────────────────────────
    // Phantom hexagon + doublering + scatter ogni 4s.
    case 27:
      return const WaveConfig(
        waveNumber: 27,
        spawns: [
          WaveSpawn(EnemyType.phantom, 24,
              formation: SpawnFormation.hexagon, delay: 0),
          WaveSpawn(EnemyType.phantom, 30,
              formation: SpawnFormation.doublering, delay: 4.0),
          WaveSpawn(EnemyType.phantom, 36,
              formation: SpawnFormation.scatter, delay: 4.0),
        ],
      );

    // ── WAVE 33 — MIRROR ARMY ───────────────────────────────────────────
    // Mirror cross + squareRing + hexagon ogni 4s.
    case 33:
      return const WaveConfig(
        waveNumber: 33,
        spawns: [
          WaveSpawn(EnemyType.mirror, 12,
              formation: SpawnFormation.cross, delay: 0),
          WaveSpawn(EnemyType.mirror, 14,
              formation: SpawnFormation.squareRing, delay: 4.0),
          WaveSpawn(EnemyType.mirror, 16,
              formation: SpawnFormation.hexagon, delay: 4.0),
        ],
      );

    // ── WAVE 38 — MINE FIELD ────────────────────────────────────────────
    // Mine scatter + honeycomb 3.5s gap + laser turret cross 3s gap.
    case 38:
      return const WaveConfig(
        waveNumber: 38,
        spawns: [
          WaveSpawn(EnemyType.mine, 30,
              formation: SpawnFormation.scatter, delay: 0),
          WaveSpawn(EnemyType.mine, 35,
              formation: SpawnFormation.honeycomb, delay: 3.5),
          WaveSpawn(EnemyType.laserTurret, 6,
              formation: SpawnFormation.cross, delay: 3.0),
        ],
      );

    // ── WAVE 47 — PINCER SIEGE ──────────────────────────────────────────
    // 2 ondate kamikaze borderLine ravvicinate (0.1s) → pincer simultaneo
    // da 2 lati. Poi 3.9s gap + secondo pincer + 3.9s + finale scatter.
    case 47:
      return const WaveConfig(
        waveNumber: 47,
        spawns: [
          WaveSpawn(EnemyType.kamikaze, 24,
              formation: SpawnFormation.borderLine, delay: 0),
          WaveSpawn(EnemyType.kamikaze, 24,
              formation: SpawnFormation.borderLine, delay: 0.1),
          WaveSpawn(EnemyType.kamikaze, 28,
              formation: SpawnFormation.borderLine, delay: 3.9),
          WaveSpawn(EnemyType.kamikaze, 28,
              formation: SpawnFormation.borderLine, delay: 0.1),
          WaveSpawn(EnemyType.kamikaze, 32,
              formation: SpawnFormation.scatter, delay: 3.9),
        ],
      );

    // ── WAVE 53 — TANK PARADE ───────────────────────────────────────────
    // Titan ring + shield cross + titan triangle ogni 3.5s.
    case 53:
      return const WaveConfig(
        waveNumber: 53,
        spawns: [
          WaveSpawn(EnemyType.titan, 8,
              formation: SpawnFormation.ring, delay: 0),
          WaveSpawn(EnemyType.shieldEnemy, 12,
              formation: SpawnFormation.cross, delay: 3.5),
          WaveSpawn(EnemyType.titan, 10,
              formation: SpawnFormation.triangle, delay: 3.5),
        ],
      );

    // ── WAVE 58 — PROTON STORM ──────────────────────────────────────────
    // Proton scatter + black hole hazard 3s gap + proton tripleRing 3s gap.
    case 58:
      return const WaveConfig(
        waveNumber: 58,
        spawns: [
          WaveSpawn(EnemyType.proton, 40,
              formation: SpawnFormation.scatter, delay: 0),
          WaveSpawn(EnemyType.blackHole, 3,
              formation: SpawnFormation.triangle, delay: 3.0),
          WaveSpawn(EnemyType.proton, 50,
              formation: SpawnFormation.tripleRing, delay: 3.0),
        ],
      );

    // ── WAVE 67 — ENCIRCLE HARD ─────────────────────────────────────────
    // Variante hardcore di wave 6: drone+weaver ring/encircle ogni 2.5s.
    case 67:
      return const WaveConfig(
        waveNumber: 67,
        spawns: [
          WaveSpawn(EnemyType.drone, 20,
              formation: SpawnFormation.playerRing, delay: 0),
          WaveSpawn(EnemyType.weaver, 12,
              formation: SpawnFormation.playerRing, delay: 2.5),
          WaveSpawn(EnemyType.drone, 20,
              formation: SpawnFormation.playerRing, delay: 2.5),
          WaveSpawn(EnemyType.weaver, 14,
              formation: SpawnFormation.playerDoubleRing, delay: 2.5),
          WaveSpawn(EnemyType.drone, 24,
              formation: SpawnFormation.playerEncircle, delay: 2.5),
        ],
      );

    // ── WAVE 73 — KAMIKAZE HELL ─────────────────────────────────────────
    // Ondate kamikaze relentless ogni 2.5s, count crescente.
    case 73:
      return const WaveConfig(
        waveNumber: 73,
        spawns: [
          WaveSpawn(EnemyType.kamikaze, 30,
              formation: SpawnFormation.borderLine, delay: 0),
          WaveSpawn(EnemyType.kamikaze, 32,
              formation: SpawnFormation.borderLine, delay: 2.5),
          WaveSpawn(EnemyType.kamikaze, 34,
              formation: SpawnFormation.borderLine, delay: 2.5),
          WaveSpawn(EnemyType.kamikaze, 36,
              formation: SpawnFormation.scatter, delay: 2.5),
          WaveSpawn(EnemyType.kamikaze, 40,
              formation: SpawnFormation.vArrow, delay: 2.5),
        ],
      );

    // ── WAVE 78 — MIRROR FORTRESS ───────────────────────────────────────
    // Mirror multi-form ogni 3.5s + shield finale 3s.
    case 78:
      return const WaveConfig(
        waveNumber: 78,
        spawns: [
          WaveSpawn(EnemyType.mirror, 16,
              formation: SpawnFormation.hexagon, delay: 0),
          WaveSpawn(EnemyType.mirror, 18,
              formation: SpawnFormation.squareRing, delay: 3.5),
          WaveSpawn(EnemyType.mirror, 20,
              formation: SpawnFormation.cross, delay: 3.5),
          WaveSpawn(EnemyType.shieldEnemy, 8,
              formation: SpawnFormation.cross, delay: 3.0),
        ],
      );

    // ── WAVE 87 — VOID FIELD ────────────────────────────────────────────
    // Blackhole hexagon + proton scatter 4s + blackhole cross 4s + proton 3s.
    case 87:
      return const WaveConfig(
        waveNumber: 87,
        spawns: [
          WaveSpawn(EnemyType.blackHole, 6,
              formation: SpawnFormation.hexagon, delay: 0),
          WaveSpawn(EnemyType.proton, 30,
              formation: SpawnFormation.scatter, delay: 4.0),
          WaveSpawn(EnemyType.blackHole, 4,
              formation: SpawnFormation.cross, delay: 4.0),
          WaveSpawn(EnemyType.proton, 40,
              formation: SpawnFormation.tripleRing, delay: 3.0),
        ],
      );

    // ── WAVE 93 — DODGER NIGHTMARE ──────────────────────────────────────
    // Phantom mass scaling 30→45 ogni 3.5s.
    case 93:
      return const WaveConfig(
        waveNumber: 93,
        spawns: [
          WaveSpawn(EnemyType.phantom, 30,
              formation: SpawnFormation.hexagon, delay: 0),
          WaveSpawn(EnemyType.phantom, 35,
              formation: SpawnFormation.doublering, delay: 3.5),
          WaveSpawn(EnemyType.phantom, 40,
              formation: SpawnFormation.scatter, delay: 3.5),
          WaveSpawn(EnemyType.phantom, 45,
              formation: SpawnFormation.tripleRing, delay: 3.5),
        ],
      );

    default:
      return null;
  }
}

/// Archetype: blueprint per generare gli spawn di una wave non-boss.
class _Archetype {
  final String name;
  final int tier; // 1=facile, 4=nightmare
  final List<WaveSpawn> Function(int wave) generator;
  const _Archetype(this.name, this.tier, this.generator);
}

/// Picker weighted per tier. Regole:
/// - Wave 1 = CARDINAL QUARTET fisso (onboarding).
/// - Wave %5 == 4 (pre-boss) = forced MEGASWARM/STORM/HELL (climax).
/// - Tier range scala col wave: 1-10 → t1-2; 11-25 → t1-2;
///   26-45 → t2-3; 46+ → t2-4.
/// - No ripetizione ultimi 3 archetipi (history ring buffer).
_Archetype _pickArchetype(int wave, List<int> history) {
  if (wave == 1) {
    final idx = _archetypes.indexWhere((a) => a.name == 'CARDINAL QUARTET');
    _pushHistory(history, idx);
    return _archetypes[idx];
  }

  final maxTier = wave <= 10
      ? 2
      : wave <= 25
          ? 2
          : wave <= 45
              ? 3
              : 4;
  // Pre-boss climax (MEGASWARM forzato) solo se maxTier ≥ 3 (wave > 25).
  // BUG CRITICO: prima wave 4 (pre-boss boss 5) forzava minTier=3 ma
  // maxTier=2 → pool vuoto → pool[% 0] IntegerDivisionByZeroException
  // durante generateWaveConfigs() → game crash → schermo bianco.
  final isPreBoss = wave % 5 == 4 && maxTier >= 3;
  final minTier = isPreBoss ? 3 : (wave <= 25 ? 1 : 2);

  final pool = <int>[];
  for (int i = 0; i < _archetypes.length; i++) {
    final a = _archetypes[i];
    if (a.tier < minTier || a.tier > maxTier) continue;
    if (history.contains(i)) continue;
    if (isPreBoss &&
        !(a.name.contains('MEGASWARM') ||
            a.name.contains('STORM') ||
            a.name.contains('HELL'))) {
      continue;
    }
    pool.add(i);
  }
  if (pool.isEmpty) {
    history.clear();
    for (int i = 0; i < _archetypes.length; i++) {
      final a = _archetypes[i];
      if (a.tier >= minTier && a.tier <= maxTier) pool.add(i);
    }
  }
  // Emergency fallback: se ancora vuoto (configurazione degenere),
  // usa CARDINAL QUARTET invece di crashare con % 0.
  if (pool.isEmpty) {
    final idx = _archetypes.indexWhere((a) => a.name == 'CARDINAL QUARTET');
    _pushHistory(history, idx);
    return _archetypes[idx];
  }

  // Pseudo-random deterministico sul wave number: riproducibile,
  // varia per-wave, history previene ripetizioni.
  final pickIdx = pool[(wave * 2654435761) % pool.length];
  _pushHistory(history, pickIdx);
  return _archetypes[pickIdx];
}

void _pushHistory(List<int> h, int idx) {
  h.add(idx);
  if (h.length > 3) h.removeAt(0);
}

// ═══════════════════════════════════════════════════════════════════════
// ARCHETYPE LIBRARY — 31 archetipi (tier 1-4) ispirati GW2:RE Sequence.
// Tier 1: onboarding/easy (wave 1-15).
// Tier 2: mix mid, posizionamento richiesto (wave 10-35).
// Tier 3: MEGASWARM/climax, 1 tipo in massa + contorno (wave 25-55).
// Tier 4: nightmare, meccaniche ostili combinate (wave 45+).
// ═══════════════════════════════════════════════════════════════════════
final List<_Archetype> _archetypes = [
  // ─── TIER 1 ─────────────────────────────────────────────────────────
  _Archetype('CARDINAL QUARTET', 1, (w) => [
        WaveSpawn(EnemyType.drone, 4, delay: 0),
        WaveSpawn(EnemyType.drone, (12 + w).clamp(12, 30), delay: 3.0),
      ]),
  _Archetype('INCOMING RUSH', 1, (w) => [
        WaveSpawn(EnemyType.drone, (20 + w * 2).clamp(20, 50), delay: 0.3),
        WaveSpawn(EnemyType.kamikaze, (6 + w).clamp(6, 20), delay: 2.0),
      ]),
  _Archetype('GENTLE SWEEP', 1, (w) => [
        WaveSpawn(EnemyType.weaver, (10 + w).clamp(10, 25), delay: 0.2),
        WaveSpawn(EnemyType.drone, (15 + w * 2).clamp(15, 40), delay: 1.5),
      ]),
  _Archetype('BORDER RAIN', 1, (w) => [
        WaveSpawn(EnemyType.swarmDrone,
            (40 + w * 4).clamp(40, 120), delay: 0.2),
        WaveSpawn(EnemyType.drone, (15 + w).clamp(15, 35), delay: 2.0),
      ]),
  _Archetype('PAIR ESCALATION', 1, (w) => [
        WaveSpawn(EnemyType.shieldEnemy, 2, delay: 0),
        WaveSpawn(EnemyType.weaver, 2, delay: 0.5),
        WaveSpawn(EnemyType.drone, (25 + w * 2).clamp(25, 60), delay: 3.0),
      ]),

  // ─── TIER 2 ─────────────────────────────────────────────────────────
  _Archetype('SPAWNER SIEGE', 2, (w) => [
        WaveSpawn(EnemyType.spawner, (2 + w ~/ 15).clamp(2, 4), delay: 0.5),
        WaveSpawn(EnemyType.drone, (20 + w).clamp(20, 40), delay: 2.5),
      ]),
  _Archetype('SNAKE PARADE', 2, (w) => [
        WaveSpawn(EnemyType.snake, (4 + w ~/ 3).clamp(4, 12), delay: 0.3),
        WaveSpawn(EnemyType.drone, (20 + w * 2).clamp(20, 50), delay: 2.5),
      ]),
  _Archetype('MIRROR WALL', 2, (w) => [
        WaveSpawn(EnemyType.mirror, (5 + w ~/ 5).clamp(5, 10), delay: 0.3),
        WaveSpawn(EnemyType.kamikaze, (20 + w).clamp(20, 45), delay: 2.0),
      ]),
  _Archetype('DIAGONAL STORM', 2, (w) => [
        WaveSpawn(EnemyType.weaver, (30 + w * 3).clamp(30, 70), delay: 0.3),
        WaveSpawn(EnemyType.drone, (10 + w).clamp(10, 30), delay: 2.5),
      ]),
  _Archetype('PULSAR RING', 2, (w) => [
        WaveSpawn(EnemyType.pulsar, (6 + w ~/ 5).clamp(6, 12), delay: 0.3),
        WaveSpawn(EnemyType.drone, (15 + w * 2).clamp(15, 40), delay: 2.0),
      ]),
  _Archetype('TESLA NETWORK', 2, (w) => [
        WaveSpawn(EnemyType.tesla, (4 + w ~/ 6).clamp(4, 8), delay: 0.3),
        WaveSpawn(EnemyType.shieldEnemy,
            (5 + w ~/ 4).clamp(5, 12), delay: 2.0),
        WaveSpawn(EnemyType.drone, (15 + w).clamp(15, 35), delay: 3.5),
      ]),
  _Archetype('PHANTOM HUNT', 2, (w) => [
        WaveSpawn(EnemyType.phantom, (6 + w ~/ 4).clamp(6, 12), delay: 0.3),
        WaveSpawn(EnemyType.weaver, (20 + w * 2).clamp(20, 45), delay: 2.0),
      ]),
  _Archetype('HAZARD MAZE', 2, (w) => [
        WaveSpawn(EnemyType.mine, (8 + w ~/ 3).clamp(8, 16), delay: 0.3),
        WaveSpawn(EnemyType.laserTurret,
            (3 + w ~/ 8).clamp(3, 6), delay: 1.5),
        WaveSpawn(EnemyType.snake, (8 + w ~/ 2).clamp(8, 20), delay: 3.0),
      ]),
  _Archetype('ORBITER CAGE', 2, (w) => [
        WaveSpawn(EnemyType.orbiter, (5 + w ~/ 5).clamp(5, 10), delay: 0.3),
        WaveSpawn(EnemyType.drone, (20 + w * 2).clamp(20, 50), delay: 2.5),
      ]),
  _Archetype('LEECH SWARM', 2, (w) => [
        WaveSpawn(EnemyType.leech, (10 + w).clamp(10, 25), delay: 0.3),
        WaveSpawn(EnemyType.drone, (25 + w * 2).clamp(25, 55), delay: 2.0),
      ]),

  // ─── TIER 3 — MEGASWARM (climax pre-boss) ───────────────────────────
  _Archetype('MEGASWARM DRONES', 3, (w) => [
        WaveSpawn(EnemyType.drone, (70 + w * 3).clamp(70, 160), delay: 0.3),
        WaveSpawn(EnemyType.weaver, (5 + w ~/ 8).clamp(5, 12), delay: 2.0),
      ]),
  _Archetype('MEGASWARM KAMIKAZE', 3, (w) => [
        WaveSpawn(EnemyType.kamikaze, (40 + w * 2).clamp(40, 90), delay: 0.3),
        WaveSpawn(EnemyType.shieldEnemy,
            (6 + w ~/ 6).clamp(6, 14), delay: 2.5),
      ]),
  _Archetype('MEGASWARM SNAKES', 3, (w) => [
        WaveSpawn(EnemyType.snake, (8 + w ~/ 2).clamp(8, 24), delay: 0.3),
        WaveSpawn(EnemyType.weaver, (25 + w * 2).clamp(25, 55), delay: 2.5),
      ]),
  _Archetype('MEGASWARM LEECHES', 3, (w) => [
        WaveSpawn(EnemyType.leech, (20 + w).clamp(20, 40), delay: 0.3),
        WaveSpawn(EnemyType.drone, (20 + w * 2).clamp(20, 50), delay: 2.0),
      ]),
  _Archetype('MEGASWARM SWARM', 3, (w) => [
        WaveSpawn(EnemyType.swarmDrone,
            (100 + w * 5).clamp(100, 220), delay: 0.2),
        WaveSpawn(EnemyType.kamikaze, (15 + w).clamp(15, 40), delay: 2.5),
      ]),
  _Archetype('CONCENTRIC STORM', 3, (w) => [
        // Ondate ring successive che circondano player.
        WaveSpawn(EnemyType.drone, (15 + w).clamp(15, 35), delay: 0.3),
        WaveSpawn(EnemyType.drone, (15 + w).clamp(15, 35), delay: 2.5),
        WaveSpawn(EnemyType.drone, (15 + w).clamp(15, 35), delay: 4.5),
        WaveSpawn(EnemyType.weaver, (5 + w ~/ 6).clamp(5, 12), delay: 5.5),
      ]),
  _Archetype('QUADRANT STORM', 3, (w) => [
        WaveSpawn(EnemyType.weaver, (12 + w ~/ 2).clamp(12, 25), delay: 0.3),
        WaveSpawn(EnemyType.pulsar, (6 + w ~/ 5).clamp(6, 12), delay: 1.2),
        WaveSpawn(EnemyType.shieldEnemy,
            (8 + w ~/ 4).clamp(8, 16), delay: 2.2),
        WaveSpawn(EnemyType.drone, (20 + w).clamp(20, 45), delay: 3.5),
      ]),
  _Archetype('MEGASWARM GATES', 3, (w) => [
        WaveSpawn(EnemyType.gate, (2 + w ~/ 30).clamp(2, 3), delay: 0.5),
        WaveSpawn(EnemyType.drone, (40 + w * 2).clamp(40, 90), delay: 2.5),
      ]),
  _Archetype('MUTATOR STORM', 3, (w) => [
        WaveSpawn(EnemyType.mutator, (2 + w ~/ 20).clamp(2, 4), delay: 0.3),
        WaveSpawn(EnemyType.drone, (30 + w * 2).clamp(30, 70), delay: 2.0),
      ]),
  _Archetype('MEGASWARM TITANS', 3, (w) => [
        WaveSpawn(EnemyType.titan, (4 + w ~/ 10).clamp(4, 8), delay: 0.3),
        WaveSpawn(EnemyType.drone, (25 + w * 2).clamp(25, 55), delay: 2.5),
      ]),

  // ─── TIER 4 — NIGHTMARE (wave 45+) ──────────────────────────────────
  _Archetype('VOID STORM', 4, (w) => [
        WaveSpawn(EnemyType.blackHole, 2, delay: 0.5),
        WaveSpawn(EnemyType.drone, (35 + w).clamp(35, 70), delay: 2.5),
        WaveSpawn(EnemyType.proton, (8 + w ~/ 5).clamp(8, 20), delay: 4.0),
      ]),
  _Archetype('NECRO STORM', 4, (w) => [
        WaveSpawn(EnemyType.necro, (3 + w ~/ 15).clamp(3, 6), delay: 0.3),
        WaveSpawn(EnemyType.drone, (30 + w).clamp(30, 65), delay: 2.0),
        WaveSpawn(EnemyType.weaver, (6 + w ~/ 8).clamp(6, 14), delay: 3.5),
      ]),
  _Archetype('MEGASWARM TIMEBOMBS', 4, (w) => [
        WaveSpawn(EnemyType.timeBomb,
            (12 + w ~/ 3).clamp(12, 25), delay: 0.3),
        WaveSpawn(EnemyType.drone, (20 + w).clamp(20, 45), delay: 2.5),
      ]),
  _Archetype('GLITCH STORM', 4, (w) => [
        WaveSpawn(EnemyType.glitch, (8 + w ~/ 4).clamp(8, 16), delay: 0.3),
        WaveSpawn(EnemyType.kamikaze, (30 + w * 2).clamp(30, 70), delay: 2.0),
      ]),
  _Archetype('SIREN STORM', 4, (w) => [
        WaveSpawn(EnemyType.siren, (6 + w ~/ 6).clamp(6, 12), delay: 0.3),
        WaveSpawn(EnemyType.drone, (40 + w * 2).clamp(40, 80), delay: 2.0),
        WaveSpawn(EnemyType.weaver, (8 + w ~/ 5).clamp(8, 20), delay: 3.5),
      ]),
  _Archetype('HELL SPAWN', 4, (w) => [
        WaveSpawn(EnemyType.spawner, (3 + w ~/ 20).clamp(3, 5), delay: 0.5),
        WaveSpawn(EnemyType.necro, (2 + w ~/ 25).clamp(2, 4), delay: 2.0),
        WaveSpawn(EnemyType.kamikaze, (15 + w).clamp(15, 35), delay: 3.5),
      ]),
];

// Obsolete themed-wave helpers rimossi — sostituiti da archetype system.
