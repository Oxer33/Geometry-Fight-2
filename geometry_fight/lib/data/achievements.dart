import 'package:hive/hive.dart';

/// Definizione di un achievement
class AchievementDef {
  final String id;
  final String name;
  final String description;
  final String icon;
  final String category; // 'combat', 'score', 'progress', 'mastery', 'special'
  final int target; // Valore target per completamento
  final int reward; // Gold reward

  const AchievementDef({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.category,
    required this.target,
    this.reward = 0,
  });
}

/// Tutti gli achievement del gioco
const List<AchievementDef> allAchievements = [
  // === COMBAT ===
  AchievementDef(id: 'kills_100', name: 'Primo Sangue', description: 'Uccidi 100 nemici in totale', icon: '⚔️', category: 'combat', target: 100, reward: 50),
  AchievementDef(id: 'kills_1000', name: 'Sterminatore', description: 'Uccidi 1.000 nemici in totale', icon: '💀', category: 'combat', target: 1000, reward: 200),
  AchievementDef(id: 'kills_10000', name: 'Genocida Geometrico', description: 'Uccidi 10.000 nemici in totale', icon: '☠️', category: 'combat', target: 10000, reward: 500),
  AchievementDef(id: 'kills_100000', name: 'Leggenda', description: 'Uccidi 100.000 nemici in totale', icon: '🏆', category: 'combat', target: 100000, reward: 2000),
  AchievementDef(id: 'kills_session_200', name: 'Furia Cieca', description: 'Uccidi 200 nemici in una partita', icon: '🔥', category: 'combat', target: 200, reward: 100),
  AchievementDef(id: 'kills_session_500', name: 'Massacro', description: 'Uccidi 500 nemici in una partita', icon: '💥', category: 'combat', target: 500, reward: 300),
  AchievementDef(id: 'bosses_10', name: 'Ammazza Boss', description: 'Sconfiggi 10 boss in totale', icon: '👑', category: 'combat', target: 10, reward: 200),
  AchievementDef(id: 'bosses_50', name: 'Regicida', description: 'Sconfiggi 50 boss in totale', icon: '⚡', category: 'combat', target: 50, reward: 500),
  AchievementDef(id: 'bombs_50', name: 'Artificiere', description: 'Usa 50 bombe in totale', icon: '💣', category: 'combat', target: 50, reward: 100),

  // === SCORE ===
  AchievementDef(id: 'score_100k', name: 'Sei Cifre', description: 'Raggiungi 100.000 punti', icon: '📊', category: 'score', target: 100000, reward: 100),
  AchievementDef(id: 'score_1m', name: 'Milionario', description: 'Raggiungi 1.000.000 punti', icon: '💰', category: 'score', target: 1000000, reward: 300),
  AchievementDef(id: 'score_10m', name: 'Re dei Punti', description: 'Raggiungi 10.000.000 punti', icon: '👑', category: 'score', target: 10000000, reward: 500),
  AchievementDef(id: 'score_100m', name: 'Centurione', description: 'Raggiungi 100.000.000 punti', icon: '🌟', category: 'score', target: 100000000, reward: 1000),
  AchievementDef(id: 'score_1b', name: 'Miliardario', description: 'Raggiungi 1.000.000.000 punti', icon: '💎', category: 'score', target: 1000000000, reward: 3000),
  AchievementDef(id: 'multiplier_100', name: 'Combo x100', description: 'Raggiungi un moltiplicatore di 100x', icon: '🔢', category: 'score', target: 100, reward: 100),
  AchievementDef(id: 'multiplier_500', name: 'Combo x500', description: 'Raggiungi un moltiplicatore di 500x', icon: '🔢', category: 'score', target: 500, reward: 300),
  AchievementDef(id: 'multiplier_1000', name: 'Combo x1000', description: 'Raggiungi un moltiplicatore di 1000x', icon: '🔢', category: 'score', target: 1000, reward: 500),
  AchievementDef(id: 'geoms_10000', name: 'Collezionista', description: 'Raccogli 10.000 geom in totale', icon: '💠', category: 'score', target: 10000, reward: 200),

  // === PROGRESS ===
  AchievementDef(id: 'wave_20', name: 'Persistente', description: 'Raggiungi wave 20', icon: '🌊', category: 'progress', target: 20, reward: 100),
  AchievementDef(id: 'wave_50', name: 'Veterano', description: 'Raggiungi wave 50', icon: '🌊', category: 'progress', target: 50, reward: 300),
  AchievementDef(id: 'wave_100', name: 'Centenario', description: 'Raggiungi wave 100', icon: '🌊', category: 'progress', target: 100, reward: 500),
  AchievementDef(id: 'perfect_waves_5', name: 'Intoccabile', description: 'Completa 5 wave perfette consecutive', icon: '✨', category: 'progress', target: 5, reward: 200),
  AchievementDef(id: 'perfect_waves_10', name: 'Fantasma', description: 'Completa 10 wave perfette consecutive', icon: '👻', category: 'progress', target: 10, reward: 500),
  AchievementDef(id: 'perfect_waves_20', name: 'Divinità', description: 'Completa 20 wave perfette consecutive', icon: '🌌', category: 'progress', target: 20, reward: 1000),

  // === MASTERY ===
  AchievementDef(id: 'classic_normal', name: 'Classicista', description: 'Completa Classica in Normale', icon: '🎮', category: 'mastery', target: 1, reward: 200),
  AchievementDef(id: 'classic_hard', name: 'Duro a Morire', description: 'Completa Classica in Difficile', icon: '💪', category: 'mastery', target: 1, reward: 500),
  AchievementDef(id: 'classic_nightmare', name: 'Incubo Vivente', description: 'Completa Classica in Incubo', icon: '😈', category: 'mastery', target: 1, reward: 1000),
  AchievementDef(id: 'all_modes', name: 'Tuttofare', description: 'Gioca in tutte le 6 modalità', icon: '🎯', category: 'mastery', target: 6, reward: 500),
  AchievementDef(id: 'boss_rush_10', name: 'Cacciatore di Boss', description: 'Raggiungi boss 10 in Boss Rush', icon: '🗡️', category: 'mastery', target: 10, reward: 500),

  // === SPECIAL ===
  AchievementDef(id: 'games_10', name: 'Giocatore', description: 'Gioca 10 partite', icon: '🕹️', category: 'special', target: 10, reward: 50),
  AchievementDef(id: 'games_100', name: 'Appassionato', description: 'Gioca 100 partite', icon: '❤️', category: 'special', target: 100, reward: 300),
  AchievementDef(id: 'games_500', name: 'Dipendente', description: 'Gioca 500 partite', icon: '🎮', category: 'special', target: 500, reward: 1000),
  AchievementDef(id: 'gold_10000', name: 'Paperone', description: 'Accumula 10.000 Gold Geom', icon: '🪙', category: 'special', target: 10000, reward: 500),
  AchievementDef(id: 'all_upgrades', name: 'Potenziato al Massimo', description: 'Compra tutti gli upgrade', icon: '⬆️', category: 'special', target: 1, reward: 1000),
  AchievementDef(id: 'powerups_100', name: 'Drogato di Power-Up', description: 'Raccogli 100 power-up', icon: '⚡', category: 'special', target: 100, reward: 200),
];

/// Manager per gli achievement — persistenza con Hive
class AchievementManager {
  static late Box _box;

  static Future<void> init() async {
    _box = await Hive.openBox('geometry_fight_achievements');
  }

  /// Progresso corrente per un achievement
  static int getProgress(String achievementId) {
    return _box.get('progress_$achievementId', defaultValue: 0) as int;
  }

  /// Se un achievement è stato sbloccato
  static bool isUnlocked(String achievementId) {
    return _box.get('unlocked_$achievementId', defaultValue: false) as bool;
  }

  /// Aggiorna il progresso e restituisce la lista di achievement appena sbloccati
  static List<AchievementDef> updateProgress(String achievementId, int value) {
    final unlocked = <AchievementDef>[];
    final current = getProgress(achievementId);
    if (value > current) {
      _box.put('progress_$achievementId', value);
    }

    // Controlla tutti gli achievement che usano questo ID come trigger
    for (final achievement in allAchievements) {
      if (achievement.id == achievementId && !isUnlocked(achievementId)) {
        final progress = getProgress(achievementId);
        if (progress >= achievement.target) {
          _box.put('unlocked_$achievementId', true);
          unlocked.add(achievement);
        }
      }
    }
    return unlocked;
  }

  /// Incrementa il progresso (per contatori cumulativi)
  static List<AchievementDef> incrementProgress(String achievementId, int amount) {
    final current = getProgress(achievementId);
    return updateProgress(achievementId, current + amount);
  }

  /// Sblocca direttamente (per achievement binari)
  static List<AchievementDef> unlock(String achievementId) {
    return updateProgress(achievementId, allAchievements.firstWhere((a) => a.id == achievementId, orElse: () => const AchievementDef(id: '', name: '', description: '', icon: '', category: '', target: 1)).target);
  }

  /// Conta achievement sbloccati
  static int unlockedCount() {
    int count = 0;
    for (final a in allAchievements) {
      if (isUnlocked(a.id)) count++;
    }
    return count;
  }

  /// Totale achievement
  static int totalCount() => allAchievements.length;

  /// Pulisci tutto
  static Future<void> clear() async {
    await _box.clear();
  }

  /// Controlla tutti gli achievement dopo una sessione di gioco.
  /// Riceve le stats della sessione e quelle cumulative.
  /// Restituisce la lista completa di achievement appena sbloccati.
  static List<AchievementDef> checkAfterSession({
    required int totalKills,
    required int sessionKills,
    required int totalBosses,
    required int sessionScore,
    required int maxMultiplier,
    required int totalGeoms,
    required int waveReached,
    required int consecutivePerfectWaves,
    required int gamesPlayed,
    required int totalGold,
    required int totalPowerUps,
    required int totalBombs,
    required int modesPlayed,
    required bool allUpgradesBought,
    // Mastery
    required bool completedClassicNormal,
    required bool completedClassicHard,
    required bool completedClassicNightmare,
    required int bossRushWave,
  }) {
    final newlyUnlocked = <AchievementDef>[];

    // Reset session-based progress (questi achievement tracciano SOLO la sessione corrente)
    _box.put('progress_kills_session_200', 0);
    _box.put('progress_kills_session_500', 0);

    // Combat
    newlyUnlocked.addAll(updateProgress('kills_100', totalKills));
    newlyUnlocked.addAll(updateProgress('kills_1000', totalKills));
    newlyUnlocked.addAll(updateProgress('kills_10000', totalKills));
    newlyUnlocked.addAll(updateProgress('kills_100000', totalKills));
    newlyUnlocked.addAll(updateProgress('kills_session_200', sessionKills));
    newlyUnlocked.addAll(updateProgress('kills_session_500', sessionKills));
    newlyUnlocked.addAll(updateProgress('bosses_10', totalBosses));
    newlyUnlocked.addAll(updateProgress('bosses_50', totalBosses));
    newlyUnlocked.addAll(updateProgress('bombs_50', totalBombs));

    // Score
    newlyUnlocked.addAll(updateProgress('score_100k', sessionScore));
    newlyUnlocked.addAll(updateProgress('score_1m', sessionScore));
    newlyUnlocked.addAll(updateProgress('score_10m', sessionScore));
    newlyUnlocked.addAll(updateProgress('score_100m', sessionScore));
    newlyUnlocked.addAll(updateProgress('score_1b', sessionScore));
    newlyUnlocked.addAll(updateProgress('multiplier_100', maxMultiplier));
    newlyUnlocked.addAll(updateProgress('multiplier_500', maxMultiplier));
    newlyUnlocked.addAll(updateProgress('multiplier_1000', maxMultiplier));
    newlyUnlocked.addAll(updateProgress('geoms_10000', totalGeoms));

    // Progress
    newlyUnlocked.addAll(updateProgress('wave_20', waveReached));
    newlyUnlocked.addAll(updateProgress('wave_50', waveReached));
    newlyUnlocked.addAll(updateProgress('wave_100', waveReached));
    newlyUnlocked.addAll(updateProgress('perfect_waves_5', consecutivePerfectWaves));
    newlyUnlocked.addAll(updateProgress('perfect_waves_10', consecutivePerfectWaves));
    newlyUnlocked.addAll(updateProgress('perfect_waves_20', consecutivePerfectWaves));

    // Mastery
    if (completedClassicNormal) newlyUnlocked.addAll(unlock('classic_normal'));
    if (completedClassicHard) newlyUnlocked.addAll(unlock('classic_hard'));
    if (completedClassicNightmare) newlyUnlocked.addAll(unlock('classic_nightmare'));
    newlyUnlocked.addAll(updateProgress('all_modes', modesPlayed));
    newlyUnlocked.addAll(updateProgress('boss_rush_10', bossRushWave));

    // Special
    newlyUnlocked.addAll(updateProgress('games_10', gamesPlayed));
    newlyUnlocked.addAll(updateProgress('games_100', gamesPlayed));
    newlyUnlocked.addAll(updateProgress('games_500', gamesPlayed));
    newlyUnlocked.addAll(updateProgress('gold_10000', totalGold));
    if (allUpgradesBought) newlyUnlocked.addAll(unlock('all_upgrades'));
    newlyUnlocked.addAll(updateProgress('powerups_100', totalPowerUps));

    return newlyUnlocked;
  }
}
