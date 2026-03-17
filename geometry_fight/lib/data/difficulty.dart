/// Sistema di difficoltà per Geometry Fight 2.
/// Ogni livello modifica HP nemici, velocità, spawn rate e drop rate.

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
    required this.scoreMultiplier,
    required this.startingLives,
    required this.startingBombs,
  });
}

/// Mappa delle configurazioni di difficoltà
const Map<Difficulty, DifficultyConfig> difficultyConfigs = {
  Difficulty.easy: DifficultyConfig(
    name: 'FACILE',
    description: 'Per chi inizia. Più vite, nemici deboli, tanti power-up.',
    enemyHpMultiplier: 0.7,
    enemySpeedMultiplier: 0.8,
    enemyCountMultiplier: 0.7,
    spawnDelayMultiplier: 1.3,
    powerUpDropRate: 0.10,
    geomDropMultiplier: 1.5,
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
    powerUpDropRate: 0.05,
    geomDropMultiplier: 1.0,
    scoreMultiplier: 1.0,
    startingLives: 3,
    startingBombs: 1,
  ),
  Difficulty.hard: DifficultyConfig(
    name: 'DIFFICILE',
    description: 'Per i veterani. Nemici aggressivi e resistenti.',
    enemyHpMultiplier: 1.5,
    enemySpeedMultiplier: 1.2,
    enemyCountMultiplier: 1.3,
    spawnDelayMultiplier: 0.8,
    powerUpDropRate: 0.03,
    geomDropMultiplier: 1.5,
    scoreMultiplier: 2.0,
    startingLives: 2,
    startingBombs: 1,
  ),
  Difficulty.nightmare: DifficultyConfig(
    name: 'INCUBO',
    description: 'Impossibile? Forse. Solo per i migliori.',
    enemyHpMultiplier: 2.0,
    enemySpeedMultiplier: 1.4,
    enemyCountMultiplier: 1.6,
    spawnDelayMultiplier: 0.6,
    powerUpDropRate: 0.02,
    geomDropMultiplier: 2.0,
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
    description: '50 wave + boss ogni 10. L\'esperienza completa.',
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
    description: 'Rilassati. Vite infinite, nemici lenti, solo punteggio.',
    icon: '🧘',
    unlockCost: 1000,
    hasBosses: false,
    infiniteWaves: true,
  ),
};
