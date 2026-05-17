// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get appTitle => 'Geometry Fight 2';

  @override
  String get menuPlay => 'GIOCA';

  @override
  String get menuShop => 'SHOP';

  @override
  String get menuStore => 'NEGOZIO';

  @override
  String get menuSettings => 'IMPOSTAZIONI';

  @override
  String get menuStats => 'STATISTICHE';

  @override
  String get menuAchievements => 'TROFEI';

  @override
  String get menuAchievementsAlt => 'ACHIEVEMENT';

  @override
  String get menuLeaderboard => 'CLASSIFICA';

  @override
  String get menuQuit => 'ESCI';

  @override
  String get diffEasy => 'FACILE';

  @override
  String get diffNormal => 'NORMALE';

  @override
  String get diffHard => 'DIFFICILE';

  @override
  String get diffNightmare => 'INCUBO';

  @override
  String get diffNext => 'AVANTI';

  @override
  String get diffTitle => 'DIFFICOLTÀ';

  @override
  String get diffScoreMultiplier => 'score';

  @override
  String get settingsTitle => 'IMPOSTAZIONI';

  @override
  String get settingsAudio => 'AUDIO';

  @override
  String get settingsGameplay => 'GAMEPLAY';

  @override
  String get settingsMusic => 'MUSICA';

  @override
  String get settingsSfx => 'EFFETTI';

  @override
  String get settingsSfxLong => 'EFFETTI SONORI';

  @override
  String get settingsVibration => 'VIBRAZIONE';

  @override
  String get settingsShowFps => 'MOSTRA FPS';

  @override
  String get settingsLanguage => 'LINGUA';

  @override
  String get settingsCrashLogs => 'CRASH LOGS';

  @override
  String get settingsReset => 'RESET DATI';

  @override
  String get settingsDangerZone => 'ZONA PERICOLOSA';

  @override
  String get settingsTestDebug => 'TEST / DEBUG';

  @override
  String get settingsAddCredits => '+1000 CREDITI';

  @override
  String get settingsResetPurchases => 'RESET ACQUISTI';

  @override
  String get settingsPurchasesReset => 'Acquisti resettati!';

  @override
  String settingsCreditsAdded(int total) {
    return '+1000 crediti! Totale: $total';
  }

  @override
  String settingsCrashLogsTitle(int count) {
    return 'CRASH LOGS ($count)';
  }

  @override
  String get settingsNoCrash =>
      'Nessun crash registrato.\nSe il gioco crasha, apparirà qui.';

  @override
  String get settingsCopy => 'COPIA';

  @override
  String get settingsDelete => 'CANCELLA';

  @override
  String get settingsLogsCopied => 'Logs copiati';

  @override
  String get shopTitle => 'SHOP';

  @override
  String get shopGoldInsufficient => 'Gold insufficiente!';

  @override
  String get shopEquip => 'EQUIPAGGIA';

  @override
  String get shopEquipped => 'EQUIPAGGIATO';

  @override
  String get shopBuy => 'ACQUISTA';

  @override
  String get shopMaxLevel => 'MAX';

  @override
  String get shopTabWeapons => 'ARMI';

  @override
  String get shopTabSkins => 'SKIN';

  @override
  String get shopTabTrails => 'SCIE';

  @override
  String get shopTabPets => 'PET';

  @override
  String get shopTabUpgrades => 'UPGRADE';

  @override
  String get shopTabModes => 'MODALITÀ';

  @override
  String get shopPurchased => 'Acquistato!';

  @override
  String get shopLocked => 'BLOCCATO';

  @override
  String get shopCost => 'COSTO';

  @override
  String get shopLevel => 'LIVELLO';

  @override
  String get shopScrollMore => 'Scorri per altro';

  @override
  String get loadoutTitle => 'PREPARAZIONE';

  @override
  String get loadoutWeapon => 'ARMA';

  @override
  String get loadoutPet => 'PET';

  @override
  String get loadoutLocked => 'Sblocca questa arma nello SHOP';

  @override
  String get loadoutPetLocked => 'Sblocca questo pet nello SHOP';

  @override
  String get loadoutStart => 'AVVIA PARTITA';

  @override
  String get loadoutPetNone => 'NESSUNO';

  @override
  String shopAlreadyMax(String name) {
    return '$name già al massimo!';
  }

  @override
  String shopUpgradedToLevel(String name, int level) {
    return '$name LIV $level';
  }

  @override
  String shopLevelOf(int current, int max) {
    return 'LIV $current / $max';
  }

  @override
  String get shopBadgeNew => 'NEW';

  @override
  String get shopBadgeUnlocked => 'SBLOCCATO';

  @override
  String shopBuyWithCost(int cost) {
    return 'ACQUISTA ${cost}g';
  }

  @override
  String get shopTapNodeForDetails => 'TOCCA UN NODO PER VEDERE I DETTAGLI';

  @override
  String get modeTitle => 'MODALITÀ';

  @override
  String get modeSelectTitle => 'SELEZIONA MODALITÀ';

  @override
  String get modeEndless => 'INFINITO';

  @override
  String get modeBossRush => 'BOSS RUSH';

  @override
  String get modeSurvival => 'SOPRAVVIVENZA';

  @override
  String get modeChallenge => 'SFIDA';

  @override
  String get modeClassic => 'CLASSICA';

  @override
  String get modePacifist => 'PACIFISTA';

  @override
  String get modeTimeAttack => 'ATTACCO A TEMPO';

  @override
  String get modeZen => 'ZEN';

  @override
  String get modeTunnel => 'TUNNEL';

  @override
  String get modeDailyChallenge => 'SFIDA GIORNALIERA';

  @override
  String get modeWaves => 'WAVES';

  @override
  String get modeGravityInferno => 'GRAVITY INFERNO';

  @override
  String get splashSkip => 'SKIP';

  @override
  String get splashTapToStart => 'TOCCA PER INIZIARE';

  @override
  String get modifiersTitle => 'MODIFICATORI';

  @override
  String get modifiersConfirm => 'CONFERMA';

  @override
  String get back => 'INDIETRO';

  @override
  String get play => 'GIOCA';

  @override
  String get pause => 'PAUSA';

  @override
  String get resume => 'RIPRENDI';

  @override
  String get restart => 'RICOMINCIA';

  @override
  String get retry => 'RIPROVA';

  @override
  String get quit => 'ESCI';

  @override
  String get close => 'CHIUDI';

  @override
  String get next => 'AVANTI';

  @override
  String get start => 'START';

  @override
  String get yes => 'SÌ';

  @override
  String get no => 'NO';

  @override
  String get confirm => 'CONFERMA';

  @override
  String get cancel => 'ANNULLA';

  @override
  String get continueAction => 'CONTINUA';

  @override
  String get score => 'PUNTEGGIO';

  @override
  String get wave => 'ONDATA';

  @override
  String get lives => 'VITE';

  @override
  String get level => 'LIVELLO';

  @override
  String get gold => 'GOLD';

  @override
  String get geoms => 'GEOMS';

  @override
  String get best => 'BEST';

  @override
  String get kills => 'KILLS';

  @override
  String get timeLabel => 'TIME';

  @override
  String get highScore => 'RECORD';

  @override
  String get newRun => 'NUOVO RUN';

  @override
  String get gameOver => 'GAME OVER';

  @override
  String get newRecord => 'NUOVO RECORD!';

  @override
  String get victory => 'VITTORIA';

  @override
  String get achievementsTitle => 'TROFEI';

  @override
  String get achievementUnlocked => 'Trofeo Sbloccato!';

  @override
  String get achievementCategoryCombat => 'COMBATTIMENTO';

  @override
  String get achievementCategoryScore => 'PUNTEGGIO';

  @override
  String get achievementCategoryProgress => 'PROGRESSO';

  @override
  String get achievementCategoryMastery => 'MAESTRIA';

  @override
  String get achievementCategorySpecial => 'SPECIALI';

  @override
  String get leaderboardTitle => 'CLASSIFICA';

  @override
  String get leaderboardEmpty => 'Nessun punteggio ancora';

  @override
  String get statsTitle => 'STATISTICHE';

  @override
  String get summaryTitle => 'RIEPILOGO';

  @override
  String get dailyRewardTitle => 'DAILY REWARD';

  @override
  String dailyRewardGeoms(int amount) {
    return '+$amount GEOM';
  }

  @override
  String dailyRewardStreakOne(int count) {
    return 'Streak: $count giorno';
  }

  @override
  String dailyRewardStreakMany(int count) {
    return 'Streak: $count giorni';
  }

  @override
  String get settingsResetTitle => 'RESET DATI';

  @override
  String get settingsResetWarning =>
      'Tutti i progressi, upgrade e acquisti verranno cancellati.';

  @override
  String get settingsResetButton => 'RESET';

  @override
  String get settingsResetAllData => 'RESET ALL DATA';

  @override
  String get badgeKiller => 'KILLER';

  @override
  String get badgeMassacre => 'MASSACRO';

  @override
  String get badgePersistent => 'PERSISTENTE';

  @override
  String get badgeVeteran => 'VETERANO';

  @override
  String get badgeBossHunter => 'BOSS HUNTER';

  @override
  String get badgeRegicide => 'REGICIDA';

  @override
  String get newAchievementBanner => '★ NUOVO ACHIEVEMENT! ★';

  @override
  String get columnDate => 'DATA';

  @override
  String leaderboardRecords(int count) {
    return '$count REC';
  }

  @override
  String get leaderboardNoRecord => 'NESSUN RECORD';

  @override
  String get leaderboardEmptyHint =>
      'Gioca in questa modalità\nper entrare in classifica!';

  @override
  String get statsSectionGeneral => 'GENERALE';

  @override
  String get statsSectionCombat => 'COMBATTIMENTO';

  @override
  String get statsSectionRecords => 'RECORD';

  @override
  String get statsSectionAchievements => 'ACHIEVEMENT';

  @override
  String get statsSectionScoresByMode => 'PUNTEGGI PER MODALITÀ';

  @override
  String get statsGamesPlayed => 'Partite giocate';

  @override
  String get statsTotalPlaytime => 'Tempo totale';

  @override
  String get statsTotalGoldEarned => 'Gold totale guadagnato';

  @override
  String get statsCurrentGold => 'Gold attuale';

  @override
  String get statsEnemiesKilled => 'Nemici uccisi';

  @override
  String get statsBossesDefeated => 'Boss sconfitti';

  @override
  String get statsBombsUsed => 'Bombe usate';

  @override
  String get statsPowerUpsCollected => 'Power-up raccolti';

  @override
  String get statsGeomsCollected => 'Geom raccolti';

  @override
  String get statsBestScore => 'Punteggio migliore';

  @override
  String get statsHighestWave => 'Wave più alta';

  @override
  String get statsMaxMultiplier => 'Moltiplicatore massimo';

  @override
  String get statsMaxSessionKills => 'Max kill in una partita';

  @override
  String get statsMaxPerfectStreak => 'Max wave perfette';

  @override
  String get statsAchievementsUnlocked => 'Sbloccati';

  @override
  String get summaryNone => 'Nessuno';

  @override
  String get summaryScoreMultiplierTitle => 'MOLTIPLICATORE PUNTEGGIO';

  @override
  String get summaryDifficultyRow => 'Difficoltà';

  @override
  String get summaryModifiersRow => 'Modificatori';

  @override
  String get summaryTotal => 'TOTALE';

  @override
  String summaryActiveModifiers(int count, String mult) {
    return '$count attivi · ×$mult score';
  }

  @override
  String get languageItalian => 'Italiano';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageSpanish => 'Español';

  @override
  String get languageFrench => 'Français';

  @override
  String get languageGerman => 'Deutsch';

  @override
  String get languagePortuguese => 'Português';

  @override
  String get languageChinese => '中文';

  @override
  String get languageJapanese => '日本語';

  @override
  String get languageRussian => 'Русский';

  @override
  String modifiersMaxActive(int count) {
    return 'MAX $count MODIFICATORI';
  }

  @override
  String modifiersScoreLabel(String mult) {
    return 'Score x$mult';
  }

  @override
  String modifiersActiveCount(int count, int max) {
    return 'Attivi: $count/$max';
  }

  @override
  String hudBossWave(int wave) {
    return 'BOSS WAVE $wave';
  }

  @override
  String hudWaveNumber(int wave) {
    return 'WAVE $wave';
  }

  @override
  String get hudPerfectWave => 'WAVE PERFETTA!';

  @override
  String get hudPerfectBonus => '+10 GEOMI BONUS';

  @override
  String hudEnemiesRemaining(int count) {
    return '$count NEMICI';
  }

  @override
  String get hudBoost2x => '2x BOOST';

  @override
  String get powerUpRapidFire => 'RAPID FIRE';

  @override
  String get powerUpOverdrive => 'OVERDRIVE';

  @override
  String get powerUpMagnet => 'MAGNETE';

  @override
  String get powerUpTimeSlow => 'TIME SLOW';

  @override
  String get powerUpSpreadShot => 'SPREAD SHOT';

  @override
  String get powerUpFirePower => 'FIRE POWER';

  @override
  String get tutorialTitle => 'COME GIOCARE';

  @override
  String get tutorialLeftJoystick => 'JOYSTICK SINISTRO';

  @override
  String get tutorialLeftJoystickDesc => 'Muovi la navicella';

  @override
  String get tutorialRightJoystick => 'JOYSTICK DESTRO';

  @override
  String get tutorialRightJoystickDesc => 'Mira e spara automaticamente';

  @override
  String get tutorialBomb => 'BOMBA';

  @override
  String get tutorialBombDesc => 'Distrugge tutti i nemici vicini';

  @override
  String get tutorialGeoms => 'GEOMI';

  @override
  String get tutorialGeomsDesc => 'Raccoglili per punti e upgrade';

  @override
  String get tutorialPowerUp => 'POWER-UP';

  @override
  String get tutorialPowerUpDesc => 'Potenziamenti temporanei';

  @override
  String get tutorialTapToStart => 'TOCCA PER INIZIARE';
}
