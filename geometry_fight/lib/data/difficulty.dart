// Sistema di difficoltà per Geometry Fight 2.
// Ogni livello modifica HP nemici, velocità, spawn rate e drop rate.

enum Difficulty {
  easy,
  normal,
  hard,
  nightmare,
}

/// Configurazione per ogni livello di difficoltà
class DifficultyConfig {
  final String name;
  final String description;
  final double enemyHpMultiplier;
  final double enemySpeedMultiplier;
  final double enemyCountMultiplier;
  final double spawnDelayMultiplier; // < 1 = più veloce
  final double powerUpDropRate;
  final double geomDropMultiplier;
  final double geomValueMultiplier; // Quanto vale ogni geom per il moltiplicatore (1.0 = +1x, 1.5 = +1.5x)
  final double scoreMultiplier;
  final int startingLives;
  final int startingBombs;

  const DifficultyConfig({
    required this.name,
    required this.description,
    required this.enemyHpMultiplier,
    required this.enemySpeedMultiplier,
    required this.enemyCountMultiplier,
    required this.spawnDelayMultiplier,
    required this.powerUpDropRate,
    required this.geomDropMultiplier,
    required this.geomValueMultiplier,
    required this.scoreMultiplier,
    required this.startingLives,
    required this.startingBombs,
  });
}

/// Mappa delle configurazioni di difficoltà
const Map<Difficulty, DifficultyConfig> difficultyConfigs = {
  Difficulty.easy: DifficultyConfig(
    name: 'FACILE',
    description: 'Per chi inizia. Più vite, nemici deboli, drop power-up raddoppiati vs normale.',
    enemyHpMultiplier: 0.7,
    enemySpeedMultiplier: 0.8,
    enemyCountMultiplier: 0.7,
    spawnDelayMultiplier: 1.3,
    powerUpDropRate: 0.005, // /20 of legacy 0.10 — easy = 2x normal
    geomDropMultiplier: 1.5,
    geomValueMultiplier: 1.0, // ogni geom = +1x
    scoreMultiplier: 0.5,
    startingLives: 5,
    startingBombs: 3,
  ),
  Difficulty.normal: DifficultyConfig(
    name: 'NORMALE',
    description: 'L\'esperienza bilanciata. Come è stato pensato il gioco.',
    enemyHpMultiplier: 1.0,
    enemySpeedMultiplier: 1.0,
    enemyCountMultiplier: 1.0,
    spawnDelayMultiplier: 1.0,
    powerUpDropRate: 0.0025, // /20 of legacy 0.05 — baseline drop rate
    geomDropMultiplier: 1.0,
    geomValueMultiplier: 1.0, // ogni geom = +1x
    scoreMultiplier: 1.0,
    startingLives: 3,
    startingBombs: 1,
  ),
  Difficulty.hard: DifficultyConfig(
    name: 'DIFFICILE',
    description: 'Per i veterani. Nemici aggressivi, drop power-up dimezzati vs normale.',
    enemyHpMultiplier: 1.5,
    enemySpeedMultiplier: 1.25,
    enemyCountMultiplier: 1.3,
    spawnDelayMultiplier: 0.8,
    powerUpDropRate: 0.0015, // /20 of legacy 0.03 — hard = 0.6x normal
    geomDropMultiplier: 1.5,
    geomValueMultiplier: 1.25, // ogni geom = +1.25x
    scoreMultiplier: 2.0,
    startingLives: 2,
    startingBombs: 1,
  ),
  Difficulty.nightmare: DifficultyConfig(
    name: 'INCUBO',
    description: 'Impossibile? Forse. Drop power-up rarissimi, solo per i migliori.',
    enemyHpMultiplier: 2.0,
    enemySpeedMultiplier: 1.5,
    enemyCountMultiplier: 1.6,
    spawnDelayMultiplier: 0.6,
    powerUpDropRate: 0.001, // /20 of legacy 0.02 — nightmare = 0.4x normal
    geomDropMultiplier: 2.0,
    geomValueMultiplier: 1.5, // ogni geom = +1.5x
    scoreMultiplier: 4.0,
    startingLives: 1,
    startingBombs: 0,
  ),
};

/// Modalità di gioco disponibili
enum GameMode {
  classic,
  bossRush,
  survival,
  timeAttack,
  zenMode,
  tunnel,
  endlessBoss,
  dailyChallenge,
  pacifist,
  // GW2:RE Waves mode — solo kamikaze (triangoli rossi cardinali, movimento
  // sx/dx + su/giù), rare blackhole. Ondate crescenti, no boss, no other mob.
  waves,
}

/// Configurazione per ogni modalità di gioco
class GameModeConfig {
  final String name;
  final String description;
  final String icon;
  final int unlockCost; // 0 = sbloccata di default
  final bool hasBosses;
  final bool hasWaves;
  final bool hasTimeLimit;
  final double timeLimitSeconds;
  final bool infiniteWaves;
  final bool pauseBetweenWaves;

  const GameModeConfig({
    required this.name,
    required this.description,
    required this.icon,
    this.unlockCost = 0,
    this.hasBosses = true,
    this.hasWaves = true,
    this.hasTimeLimit = false,
    this.timeLimitSeconds = 0,
    this.infiniteWaves = false,
    this.pauseBetweenWaves = true,
  });
}

/// Mappa delle configurazioni delle modalità
const Map<GameMode, GameModeConfig> gameModeConfigs = {
  GameMode.classic: GameModeConfig(
    name: 'CLASSICA',
    description: '100 wave con boss crescenti. L\'esperienza completa.',
    icon: '⚔️',
    unlockCost: 0,
  ),
  GameMode.bossRush: GameModeConfig(
    name: 'BOSS RUSH',
    description: 'Solo boss in sequenza. 3 vite totali. Quanto resisti?',
    icon: '👑',
    unlockCost: 2000,
    hasBosses: true,
    hasWaves: false,
    pauseBetweenWaves: false,
  ),
  GameMode.survival: GameModeConfig(
    name: 'SOPRAVVIVENZA',
    description: 'Ondate infinite sempre più veloci. Nessuna pausa.',
    icon: '♾️',
    unlockCost: 2500,
    infiniteWaves: true,
    pauseBetweenWaves: false,
  ),
  GameMode.timeAttack: GameModeConfig(
    name: 'ATTACCO A TEMPO',
    description: 'Fai più punti possibile in 3 minuti!',
    icon: '⏱️',
    unlockCost: 1500,
    hasTimeLimit: true,
    timeLimitSeconds: 180,
    hasBosses: false,
  ),
  GameMode.zenMode: GameModeConfig(
    name: 'ZEN',
    description: 'Come classica ma immortale. Conta le morti, non le vite.',
    icon: '🧘',
    unlockCost: 1000,
    // Stessa struttura di classica: boss + 100 wave.
    hasBosses: true,
  ),
  GameMode.tunnel: GameModeConfig(
    name: 'TUNNEL',
    description: 'Tunnel infinito che si allarga per le boss fight. Unico!',
    icon: '🌀',
    unlockCost: 3000,
    hasBosses: true,
    hasWaves: true,
    infiniteWaves: true,
    pauseBetweenWaves: false,
  ),
  GameMode.endlessBoss: GameModeConfig(
    name: 'BOSS INFINITI',
    description: 'Boss dopo boss, sempre più forti. Quanti ne riesci a battere?',
    icon: '💀',
    unlockCost: 3500,
    hasBosses: true,
    hasWaves: false,
    infiniteWaves: true,
    pauseBetweenWaves: false,
  ),
  GameMode.dailyChallenge: GameModeConfig(
    name: 'SFIDA GIORNALIERA',
    description: 'Stessa sfida per tutti. Seed giornaliero. Chi fa più punti?',
    icon: '📅',
    unlockCost: 0,
    hasBosses: true,
    hasWaves: true,
    infiniteWaves: false,
  ),
  // Pacifism iconica di Geometry Wars: Retro Evolved 2.
  // No spari, 1 vita, 0 bombe. Solo grunt blu lenti. Sopravvivi attraversando
  // i Gate per esplosioni a catena. Combo successive = punti × moltiplicatore.
  GameMode.pacifist: GameModeConfig(
    name: 'PACIFISTA',
    description: 'Niente colpi, niente bombe. Sopravvivi attraversando i Gate per esplosioni a catena.',
    icon: '🕊️',
    unlockCost: 1500,
    hasBosses: false,
    hasWaves: true,
    infiniteWaves: true,
    pauseBetweenWaves: false,
  ),
  // Waves: ispirata GW2:RE Waves mode. Solo kamikaze (triangoli rossi
  // cardinali, sx/dx + su/giù). Rare blackhole ogni 5 wave. No boss.
  // Wave count crescente → mastery del dodge cardinale.
  GameMode.waves: GameModeConfig(
    name: 'WAVES',
    description: 'Solo triangoli rossi cardinali. Rari buchi neri. Test puro di dodge.',
    icon: '🔻',
    // 800g: progressione coerente. Pacifist=1500 più punitive (no spari);
    // Waves più diretto (spari + dodge) → 800 entry-level dopo TimeAttack.
    unlockCost: 800,
    hasBosses: false,
    hasWaves: true,
    infiniteWaves: true,
    pauseBetweenWaves: false,
  ),
};
