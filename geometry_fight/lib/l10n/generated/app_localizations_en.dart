// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Geometry Fight 2';

  @override
  String get menuPlay => 'PLAY';

  @override
  String get menuShop => 'SHOP';

  @override
  String get menuStore => 'STORE';

  @override
  String get menuSettings => 'SETTINGS';

  @override
  String get menuStats => 'STATS';

  @override
  String get menuAchievements => 'TROPHIES';

  @override
  String get menuAchievementsAlt => 'ACHIEVEMENTS';

  @override
  String get menuLeaderboard => 'LEADERBOARD';

  @override
  String get menuQuit => 'QUIT';

  @override
  String get diffEasy => 'EASY';

  @override
  String get diffNormal => 'NORMAL';

  @override
  String get diffHard => 'HARD';

  @override
  String get diffNightmare => 'NIGHTMARE';

  @override
  String get diffNext => 'NEXT';

  @override
  String get diffTitle => 'DIFFICULTY';

  @override
  String get diffScoreMultiplier => 'score';

  @override
  String get settingsTitle => 'SETTINGS';

  @override
  String get settingsAudio => 'AUDIO';

  @override
  String get settingsGameplay => 'GAMEPLAY';

  @override
  String get settingsMusic => 'MUSIC';

  @override
  String get settingsSfx => 'SFX';

  @override
  String get settingsSfxLong => 'SOUND EFFECTS';

  @override
  String get settingsVibration => 'VIBRATION';

  @override
  String get settingsShowFps => 'SHOW FPS';

  @override
  String get settingsLanguage => 'LANGUAGE';

  @override
  String get settingsCrashLogs => 'CRASH LOGS';

  @override
  String get settingsReset => 'RESET DATA';

  @override
  String get settingsDangerZone => 'DANGER ZONE';

  @override
  String get settingsTestDebug => 'TEST / DEBUG';

  @override
  String get settingsAddCredits => '+1000 CREDITS';

  @override
  String get settingsResetPurchases => 'RESET PURCHASES';

  @override
  String get settingsPurchasesReset => 'Purchases reset!';

  @override
  String settingsCreditsAdded(int total) {
    return '+1000 credits! Total: $total';
  }

  @override
  String settingsCrashLogsTitle(int count) {
    return 'CRASH LOGS ($count)';
  }

  @override
  String get settingsNoCrash =>
      'No crash logged.\nIf the game crashes, it will appear here.';

  @override
  String get settingsCopy => 'COPY';

  @override
  String get settingsDelete => 'DELETE';

  @override
  String get settingsLogsCopied => 'Logs copied';

  @override
  String get shopTitle => 'SHOP';

  @override
  String get shopGoldInsufficient => 'Not enough gold!';

  @override
  String get shopEquip => 'EQUIP';

  @override
  String get shopEquipped => 'EQUIPPED';

  @override
  String get shopBuy => 'BUY';

  @override
  String get shopMaxLevel => 'MAX';

  @override
  String get shopTabWeapons => 'WEAPONS';

  @override
  String get shopTabSkins => 'SKINS';

  @override
  String get shopTabTrails => 'TRAILS';

  @override
  String get shopTabPets => 'PETS';

  @override
  String get shopTabUpgrades => 'UPGRADES';

  @override
  String get shopTabModes => 'MODES';

  @override
  String get shopPurchased => 'Purchased!';

  @override
  String get shopLocked => 'LOCKED';

  @override
  String get shopCost => 'COST';

  @override
  String get shopLevel => 'LEVEL';

  @override
  String get shopScrollMore => 'Scroll for more';

  @override
  String get loadoutTitle => 'LOADOUT';

  @override
  String get loadoutWeapon => 'WEAPON';

  @override
  String get loadoutPet => 'PET';

  @override
  String get loadoutLocked => 'Unlock this weapon in the SHOP';

  @override
  String get loadoutPetLocked => 'Unlock this pet in the SHOP';

  @override
  String get loadoutStart => 'START GAME';

  @override
  String get loadoutPetNone => 'NONE';

  @override
  String shopAlreadyMax(String name) {
    return '$name already maxed!';
  }

  @override
  String shopUpgradedToLevel(String name, int level) {
    return '$name LV $level';
  }

  @override
  String shopLevelOf(int current, int max) {
    return 'LV $current / $max';
  }

  @override
  String get shopBadgeNew => 'NEW';

  @override
  String get shopBadgeUnlocked => 'UNLOCKED';

  @override
  String shopBuyWithCost(int cost) {
    return 'BUY ${cost}g';
  }

  @override
  String get shopTapNodeForDetails => 'TAP A NODE TO SEE DETAILS';

  @override
  String get modeTitle => 'MODE';

  @override
  String get modeSelectTitle => 'SELECT MODE';

  @override
  String get modeEndless => 'ENDLESS';

  @override
  String get modeBossRush => 'BOSS RUSH';

  @override
  String get modeSurvival => 'SURVIVAL';

  @override
  String get modeChallenge => 'CHALLENGE';

  @override
  String get modeClassic => 'CLASSIC';

  @override
  String get modePacifist => 'PACIFIST';

  @override
  String get modeTimeAttack => 'TIME ATTACK';

  @override
  String get modeZen => 'ZEN';

  @override
  String get modeTunnel => 'TUNNEL';

  @override
  String get modeDailyChallenge => 'DAILY CHALLENGE';

  @override
  String get modeWaves => 'WAVES';

  @override
  String get modeGravityInferno => 'GRAVITY INFERNO';

  @override
  String get splashSkip => 'SKIP';

  @override
  String get splashTapToStart => 'TAP TO START';

  @override
  String get modifiersTitle => 'MODIFIERS';

  @override
  String get modifiersConfirm => 'CONFIRM';

  @override
  String get back => 'BACK';

  @override
  String get play => 'PLAY';

  @override
  String get pause => 'PAUSE';

  @override
  String get resume => 'RESUME';

  @override
  String get restart => 'RESTART';

  @override
  String get retry => 'RETRY';

  @override
  String get quit => 'QUIT';

  @override
  String get close => 'CLOSE';

  @override
  String get next => 'NEXT';

  @override
  String get start => 'START';

  @override
  String get yes => 'YES';

  @override
  String get no => 'NO';

  @override
  String get confirm => 'CONFIRM';

  @override
  String get cancel => 'CANCEL';

  @override
  String get continueAction => 'CONTINUE';

  @override
  String get score => 'SCORE';

  @override
  String get wave => 'WAVE';

  @override
  String get lives => 'LIVES';

  @override
  String get level => 'LEVEL';

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
  String get highScore => 'HIGH SCORE';

  @override
  String get newRun => 'NEW RUN';

  @override
  String get gameOver => 'GAME OVER';

  @override
  String get newRecord => 'NEW RECORD!';

  @override
  String get victory => 'VICTORY';

  @override
  String get achievementsTitle => 'TROPHIES';

  @override
  String get achievementUnlocked => 'Trophy Unlocked!';

  @override
  String get achievementCategoryCombat => 'COMBAT';

  @override
  String get achievementCategoryScore => 'SCORE';

  @override
  String get achievementCategoryProgress => 'PROGRESS';

  @override
  String get achievementCategoryMastery => 'MASTERY';

  @override
  String get achievementCategorySpecial => 'SPECIAL';

  @override
  String get leaderboardTitle => 'LEADERBOARD';

  @override
  String get leaderboardEmpty => 'No scores yet';

  @override
  String get statsTitle => 'STATS';

  @override
  String get summaryTitle => 'SUMMARY';

  @override
  String get dailyRewardTitle => 'DAILY REWARD';

  @override
  String dailyRewardGeoms(int amount) {
    return '+$amount GEOM';
  }

  @override
  String dailyRewardStreakOne(int count) {
    return 'Streak: $count day';
  }

  @override
  String dailyRewardStreakMany(int count) {
    return 'Streak: $count days';
  }

  @override
  String get settingsResetTitle => 'RESET DATA';

  @override
  String get settingsResetWarning =>
      'All progress, upgrades and purchases will be erased.';

  @override
  String get settingsResetButton => 'RESET';

  @override
  String get settingsResetAllData => 'RESET ALL DATA';

  @override
  String get badgeKiller => 'KILLER';

  @override
  String get badgeMassacre => 'MASSACRE';

  @override
  String get badgePersistent => 'PERSISTENT';

  @override
  String get badgeVeteran => 'VETERAN';

  @override
  String get badgeBossHunter => 'BOSS HUNTER';

  @override
  String get badgeRegicide => 'REGICIDE';

  @override
  String get newAchievementBanner => '★ NEW ACHIEVEMENT! ★';

  @override
  String get columnDate => 'DATE';

  @override
  String leaderboardRecords(int count) {
    return '$count REC';
  }

  @override
  String get leaderboardNoRecord => 'NO RECORDS';

  @override
  String get leaderboardEmptyHint =>
      'Play this mode\nto enter the leaderboard!';

  @override
  String get statsSectionGeneral => 'GENERAL';

  @override
  String get statsSectionCombat => 'COMBAT';

  @override
  String get statsSectionRecords => 'RECORDS';

  @override
  String get statsSectionAchievements => 'ACHIEVEMENTS';

  @override
  String get statsSectionScoresByMode => 'SCORES BY MODE';

  @override
  String get statsGamesPlayed => 'Games played';

  @override
  String get statsTotalPlaytime => 'Total playtime';

  @override
  String get statsTotalGoldEarned => 'Total gold earned';

  @override
  String get statsCurrentGold => 'Current gold';

  @override
  String get statsEnemiesKilled => 'Enemies killed';

  @override
  String get statsBossesDefeated => 'Bosses defeated';

  @override
  String get statsBombsUsed => 'Bombs used';

  @override
  String get statsPowerUpsCollected => 'Power-ups collected';

  @override
  String get statsGeomsCollected => 'Geoms collected';

  @override
  String get statsBestScore => 'Best score';

  @override
  String get statsHighestWave => 'Highest wave';

  @override
  String get statsMaxMultiplier => 'Max multiplier';

  @override
  String get statsMaxSessionKills => 'Max kills in a run';

  @override
  String get statsMaxPerfectStreak => 'Max perfect waves';

  @override
  String get statsAchievementsUnlocked => 'Unlocked';

  @override
  String get summaryNone => 'None';

  @override
  String get summaryScoreMultiplierTitle => 'SCORE MULTIPLIER';

  @override
  String get summaryDifficultyRow => 'Difficulty';

  @override
  String get summaryModifiersRow => 'Modifiers';

  @override
  String get summaryTotal => 'TOTAL';

  @override
  String summaryActiveModifiers(int count, String mult) {
    return '$count active · ×$mult score';
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
    return 'MAX $count MODIFIERS';
  }

  @override
  String modifiersScoreLabel(String mult) {
    return 'Score x$mult';
  }

  @override
  String modifiersActiveCount(int count, int max) {
    return 'Active: $count/$max';
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
  String get hudPerfectWave => 'PERFECT WAVE!';

  @override
  String get hudPerfectBonus => '+10 GEOMS BONUS';

  @override
  String hudEnemiesRemaining(int count) {
    return '$count ENEMIES';
  }

  @override
  String get hudBoost2x => '2x BOOST';

  @override
  String get powerUpRapidFire => 'RAPID FIRE';

  @override
  String get powerUpOverdrive => 'OVERDRIVE';

  @override
  String get powerUpMagnet => 'MAGNET';

  @override
  String get powerUpTimeSlow => 'TIME SLOW';

  @override
  String get powerUpSpreadShot => 'SPREAD SHOT';

  @override
  String get powerUpFirePower => 'FIRE POWER';

  @override
  String get tutorialTitle => 'HOW TO PLAY';

  @override
  String get tutorialLeftJoystick => 'LEFT JOYSTICK';

  @override
  String get tutorialLeftJoystickDesc => 'Move the ship';

  @override
  String get tutorialRightJoystick => 'RIGHT JOYSTICK';

  @override
  String get tutorialRightJoystickDesc => 'Aim and shoot automatically';

  @override
  String get tutorialBomb => 'BOMB';

  @override
  String get tutorialBombDesc => 'Destroys all nearby enemies';

  @override
  String get tutorialGeoms => 'GEOMS';

  @override
  String get tutorialGeomsDesc => 'Collect for points and upgrades';

  @override
  String get tutorialPowerUp => 'POWER-UP';

  @override
  String get tutorialPowerUpDesc => 'Temporary boosts';

  @override
  String get tutorialTapToStart => 'TAP TO START';

  @override
  String get skinNameClassic => 'Classic';

  @override
  String get skinDescClassic => 'The original cyan ship';

  @override
  String get skinNameStealth => 'Stealth';

  @override
  String get skinDescStealth => 'Black with red edges — stealthy style';

  @override
  String get skinNameCrystal => 'Crystal';

  @override
  String get skinDescCrystal => 'Prismatic diamond — rainbow reflections';

  @override
  String get skinNameGhost => 'Ghost';

  @override
  String get skinDescGhost => 'Semi-transparent with particle trail';

  @override
  String get skinNameOmega => 'Omega';

  @override
  String get skinDescOmega => 'Golden 4-point star — unique shape';

  @override
  String get skinNamePhoenix => 'Phoenix';

  @override
  String get skinDescPhoenix =>
      'Fire wings with ember feathers — reborn from ashes';

  @override
  String get skinNameCyber => 'Cyber';

  @override
  String get skinDescCyber =>
      'Neon green circuit mesh — animated digital overlay';

  @override
  String get skinNameVoidwalker => 'Voidwalker';

  @override
  String get skinDescVoidwalker =>
      'Violet core suspended in the void — ethereal halo';

  @override
  String get skinNameAurora => 'Aurora';

  @override
  String get skinDescAurora => 'Borealis: flowing cyan/pink/green';

  @override
  String get skinNameTactical => 'Tactical';

  @override
  String get skinDescTactical => 'Gray/blue military armor — armored plates';

  @override
  String get skinNamePrism => 'Prism';

  @override
  String get skinDescPrism => 'Polygonal crystal — multi-rainbow refraction';

  @override
  String get skinNameTron => 'Tron';

  @override
  String get skinDescTron =>
      'Black body with neon cyan lines — digital circuit grid';

  @override
  String get skinNameSamurai => 'Samurai';

  @override
  String get skinDescSamurai =>
      'Black armor with gold/red details — honor and battle';

  @override
  String get skinNameRosegold => 'RoseGold';

  @override
  String get skinDescRosegold => 'Metallic rose-gold — modern elegance';

  @override
  String get skinNameNinja => 'Ninja';

  @override
  String get skinDescNinja =>
      'Shadow gray with shuriken accents — silent and lethal';

  @override
  String get skinNameGlitch => 'Glitch';

  @override
  String get skinDescGlitch => 'RGB chromatic shift — animated aberration';

  @override
  String get trailNameNormal => 'Normal';

  @override
  String get trailDescNormal => 'Standard cyan trail';

  @override
  String get trailNameFire => 'Fire';

  @override
  String get trailDescFire => 'Fire particles behind the ship';

  @override
  String get trailNameIce => 'Ice';

  @override
  String get trailDescIce => 'Glittering ice crystals';

  @override
  String get trailNamePlasma => 'Plasma';

  @override
  String get trailDescPlasma => 'Pulsing purple plasma energy';

  @override
  String get trailNameRainbow => 'Rainbow';

  @override
  String get trailDescRainbow => 'Continuously shifting colors';

  @override
  String get trailNameComet => 'Comet';

  @override
  String get trailDescComet => 'Bright head with slowly fading tail';

  @override
  String get trailNameInferno => 'Inferno';

  @override
  String get trailDescInferno => 'Multi-layer fire with splashing embers';

  @override
  String get trailNameVoid => 'Void';

  @override
  String get trailDescVoid => 'Dark vortex sucking in purple particles';

  @override
  String get trailNameQuantum => 'Quantum';

  @override
  String get trailDescQuantum => 'Paired particles in chromatic superposition';

  @override
  String get trailNameGalaxy => 'Galaxy';

  @override
  String get trailDescGalaxy => 'Spiraling stars with cosmic dust';

  @override
  String get trailNameLightning => 'Lightning';

  @override
  String get trailDescLightning => 'Zigzag electric arcs between trail points';

  @override
  String get trailNameNebula => 'Nebula';

  @override
  String get trailDescNebula => 'Pulsing cyan/magenta space cloud';

  @override
  String get trailNamePrism => 'Prism';

  @override
  String get trailDescPrism => 'Full spectrum flowing along the trail';

  @override
  String get trailNameHologram => 'Hologram';

  @override
  String get trailDescHologram => 'RGB chromatic aberration glitch style';

  @override
  String get trailNameBiolume => 'Biolumin';

  @override
  String get trailDescBiolume => 'Green/cyan aquatic bioluminescence';

  @override
  String get trailNameNeonpulse => 'NeonPulse';

  @override
  String get trailDescNeonpulse => 'Expanding white-cyan neon rings';

  @override
  String get weaponNameBasic => 'Basic Gun';

  @override
  String get weaponDescBasic =>
      'Double row of parallel yellow bullets — reliable and precise.';

  @override
  String get weaponNameTriple => 'Triple Shot';

  @override
  String get weaponDescTriple => '3 tight white bullets — concentrated fire.';

  @override
  String get weaponNameSpread => 'Spread Shot';

  @override
  String get weaponDescSpread =>
      '5 orange bullets in tight fan — great vs groups.';

  @override
  String get weaponNameRicochet => 'Ricochet';

  @override
  String get weaponDescRicochet =>
      'Fan of 3 high-damage green shots that bounce 2 times off walls.';

  @override
  String get weaponNameHoming => 'Homing';

  @override
  String get weaponDescHoming =>
      '5 missiles tracking distinct targets — explode on walls.';

  @override
  String get weaponNamePlasma => 'Plasma';

  @override
  String get weaponDescPlasma =>
      'Slow violet orb with explosive AoE — devastates bosses and groups.';

  @override
  String get weaponNameLaser => 'Laser';

  @override
  String get weaponDescLaser =>
      'Continuous red beam — cuts everything it touches.';

  @override
  String get weaponNameGauss => 'Gauss Cannon';

  @override
  String get weaponDescGauss =>
      'Violet shot with 1s gravitational pull — clusters enemies for full damage.';

  @override
  String get weaponNameChain => 'Chain Lightning';

  @override
  String get weaponDescChain =>
      'Electric bolt bounces between 5 enemies — perfect vs groups.';

  @override
  String get modeDescClassic =>
      '100 waves with a boss every 10 — the standard mode';

  @override
  String get modeDescBossRush => 'Bosses only, one after another — no mobs';

  @override
  String get modeDescSurvival =>
      'Endless waves, ever harder — how long can you last?';

  @override
  String get modeDescTimeAttack =>
      '3 minutes: score as much as you can before time runs out';

  @override
  String get modeDescZenMode =>
      'Infinite lives — play stress-free, explore everything';

  @override
  String get modeDescTunnel => 'Side-scrolling in an endless tunnel';

  @override
  String get modeDescPacifist =>
      'No shooting! Survive using Gates (GW Pacifism)';

  @override
  String get modeDescWaves =>
      'Only cardinal red triangles. Rare black holes. Pure dodge.';

  @override
  String get modeDescGravityInferno =>
      'Many black holes + few mixed mobs. No bosses. Gravitational chaos.';

  @override
  String get upgradeFirepower => 'FIREPOWER';

  @override
  String get upgradeFirepowerDesc => '+5% damage per level (max +25%)';

  @override
  String get upgradeFireRate => 'FIRE RATE';

  @override
  String get upgradeFireRateDesc => '+5% fire rate per level (max +25%)';

  @override
  String get upgradeSpeed => 'SPEED';

  @override
  String get upgradeSpeedDesc => '+5% speed per level (max +25%)';

  @override
  String get upgradeShield => 'SHIELD';

  @override
  String get upgradeShieldDesc =>
      'Post-death shield: 5s → 10s → 15s → 20s → 25s';

  @override
  String get upgradeLives => 'LIVES';

  @override
  String get upgradeLivesDesc => 'Starting lives: 3 → 4 → 5';

  @override
  String get upgradeBombs => 'BOMB RANGE';

  @override
  String get upgradeBombsDesc =>
      '+explosion radius per level (L0 half arena, L10 full arena)';

  @override
  String get upgradeMagnet => 'MAGNET';

  @override
  String get upgradeMagnetDesc => '+10px magnet range per level (max +50px)';

  @override
  String get upgradeXpBoost => 'XP BOOST';

  @override
  String get upgradeXpBoostDesc => '+10% GoldGeom per level (max +50%)';
}
