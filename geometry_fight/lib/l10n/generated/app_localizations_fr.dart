// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'Geometry Fight 2';

  @override
  String get menuPlay => 'JOUER';

  @override
  String get menuShop => 'BOUTIQUE';

  @override
  String get menuStore => 'BOUTIQUE';

  @override
  String get menuSettings => 'PARAMÈTRES';

  @override
  String get menuStats => 'STATISTIQUES';

  @override
  String get menuAchievements => 'TROPHÉES';

  @override
  String get menuAchievementsAlt => 'SUCCÈS';

  @override
  String get menuLeaderboard => 'CLASSEMENT';

  @override
  String get menuQuit => 'QUITTER';

  @override
  String get diffEasy => 'FACILE';

  @override
  String get diffNormal => 'NORMAL';

  @override
  String get diffHard => 'DIFFICILE';

  @override
  String get diffNightmare => 'CAUCHEMAR';

  @override
  String get diffNext => 'SUIVANT';

  @override
  String get diffTitle => 'DIFFICULTÉ';

  @override
  String get diffScoreMultiplier => 'score';

  @override
  String get settingsTitle => 'PARAMÈTRES';

  @override
  String get settingsAudio => 'AUDIO';

  @override
  String get settingsGameplay => 'JEU';

  @override
  String get settingsMusic => 'MUSIQUE';

  @override
  String get settingsSfx => 'SFX';

  @override
  String get settingsSfxLong => 'EFFETS SONORES';

  @override
  String get settingsVibration => 'VIBRATION';

  @override
  String get settingsShowFps => 'AFFICHER FPS';

  @override
  String get settingsLanguage => 'LANGUE';

  @override
  String get settingsCrashLogs => 'JOURNAUX DE PLANTAGE';

  @override
  String get settingsReset => 'RÉINITIALISER';

  @override
  String get settingsDangerZone => 'ZONE DANGEREUSE';

  @override
  String get settingsTestDebug => 'TEST / DEBUG';

  @override
  String get settingsAddCredits => '+1000 CRÉDITS';

  @override
  String get settingsResetPurchases => 'RÉINIT. ACHATS';

  @override
  String get settingsPurchasesReset => 'Achats réinitialisés !';

  @override
  String settingsCreditsAdded(int total) {
    return '+1000 crédits ! Total : $total';
  }

  @override
  String settingsCrashLogsTitle(int count) {
    return 'PLANTAGES ($count)';
  }

  @override
  String get settingsNoCrash =>
      'Aucun plantage enregistré.\nEn cas de crash, il apparaîtra ici.';

  @override
  String get settingsCopy => 'COPIER';

  @override
  String get settingsDelete => 'EFFACER';

  @override
  String get settingsLogsCopied => 'Journaux copiés';

  @override
  String get shopTitle => 'BOUTIQUE';

  @override
  String get shopGoldInsufficient => 'Or insuffisant !';

  @override
  String get shopEquip => 'ÉQUIPER';

  @override
  String get shopEquipped => 'ÉQUIPÉ';

  @override
  String get shopBuy => 'ACHETER';

  @override
  String get shopMaxLevel => 'MAX';

  @override
  String get shopTabWeapons => 'ARMES';

  @override
  String get shopTabSkins => 'SKINS';

  @override
  String get shopTabTrails => 'TRAÎNÉES';

  @override
  String get shopTabPets => 'COMPAGNONS';

  @override
  String get shopTabUpgrades => 'AMÉLIORATIONS';

  @override
  String get shopTabModes => 'MODES';

  @override
  String get shopPurchased => 'Acheté !';

  @override
  String get shopLocked => 'VERROUILLÉ';

  @override
  String get shopCost => 'COÛT';

  @override
  String get shopLevel => 'NIVEAU';

  @override
  String get shopScrollMore => 'Faire défiler';

  @override
  String get loadoutTitle => 'ÉQUIPEMENT';

  @override
  String get loadoutWeapon => 'ARME';

  @override
  String get loadoutPet => 'COMPAGNON';

  @override
  String get loadoutLocked => 'Débloquez cette arme dans la BOUTIQUE';

  @override
  String get loadoutPetLocked => 'Débloquez ce compagnon dans la BOUTIQUE';

  @override
  String get loadoutStart => 'LANCER LA PARTIE';

  @override
  String get loadoutPetNone => 'AUCUN';

  @override
  String shopAlreadyMax(String name) {
    return '$name déjà au maximum !';
  }

  @override
  String shopUpgradedToLevel(String name, int level) {
    return '$name NIV $level';
  }

  @override
  String shopLevelOf(int current, int max) {
    return 'NIV $current / $max';
  }

  @override
  String get shopBadgeNew => 'NOUVEAU';

  @override
  String get shopBadgeUnlocked => 'DÉBLOQUÉ';

  @override
  String shopBuyWithCost(int cost) {
    return 'ACHETER ${cost}g';
  }

  @override
  String get shopTapNodeForDetails => 'TOUCHEZ UN NŒUD POUR LES DÉTAILS';

  @override
  String get modeTitle => 'MODE';

  @override
  String get modeSelectTitle => 'CHOISIR MODE';

  @override
  String get modeEndless => 'INFINI';

  @override
  String get modeBossRush => 'BOSS RUSH';

  @override
  String get modeSurvival => 'SURVIE';

  @override
  String get modeChallenge => 'DÉFI';

  @override
  String get modeClassic => 'CLASSIQUE';

  @override
  String get modePacifist => 'PACIFISTE';

  @override
  String get modeTimeAttack => 'CONTRE LA MONTRE';

  @override
  String get modeZen => 'ZEN';

  @override
  String get modeTunnel => 'TUNNEL';

  @override
  String get modeDailyChallenge => 'DÉFI QUOTIDIEN';

  @override
  String get modeWaves => 'VAGUES';

  @override
  String get modeGravityInferno => 'ENFER GRAVITATIONNEL';

  @override
  String get splashSkip => 'PASSER';

  @override
  String get splashTapToStart => 'APPUYEZ POUR COMMENCER';

  @override
  String get modifiersTitle => 'MODIFICATEURS';

  @override
  String get modifiersConfirm => 'CONFIRMER';

  @override
  String get back => 'RETOUR';

  @override
  String get play => 'JOUER';

  @override
  String get pause => 'PAUSE';

  @override
  String get resume => 'REPRENDRE';

  @override
  String get restart => 'REDÉMARRER';

  @override
  String get retry => 'RÉESSAYER';

  @override
  String get quit => 'QUITTER';

  @override
  String get close => 'FERMER';

  @override
  String get next => 'SUIVANT';

  @override
  String get start => 'DÉMARRER';

  @override
  String get yes => 'OUI';

  @override
  String get no => 'NON';

  @override
  String get confirm => 'CONFIRMER';

  @override
  String get cancel => 'ANNULER';

  @override
  String get continueAction => 'CONTINUER';

  @override
  String get score => 'SCORE';

  @override
  String get wave => 'VAGUE';

  @override
  String get lives => 'VIES';

  @override
  String get level => 'NIVEAU';

  @override
  String get gold => 'OR';

  @override
  String get geoms => 'GEOMS';

  @override
  String get best => 'MEILLEUR';

  @override
  String get kills => 'ÉLIMS';

  @override
  String get timeLabel => 'TEMPS';

  @override
  String get highScore => 'RECORD';

  @override
  String get newRun => 'NOUVELLE PARTIE';

  @override
  String get gameOver => 'PARTIE TERMINÉE';

  @override
  String get newRecord => 'NOUVEAU RECORD !';

  @override
  String get victory => 'VICTOIRE';

  @override
  String get achievementsTitle => 'TROPHÉES';

  @override
  String get achievementUnlocked => 'Trophée Débloqué !';

  @override
  String get achievementCategoryCombat => 'COMBAT';

  @override
  String get achievementCategoryScore => 'SCORE';

  @override
  String get achievementCategoryProgress => 'PROGRÈS';

  @override
  String get achievementCategoryMastery => 'MAÎTRISE';

  @override
  String get achievementCategorySpecial => 'SPÉCIAL';

  @override
  String get leaderboardTitle => 'CLASSEMENT';

  @override
  String get leaderboardEmpty => 'Aucun score pour l\'instant';

  @override
  String get statsTitle => 'STATISTIQUES';

  @override
  String get summaryTitle => 'RÉSUMÉ';

  @override
  String get dailyRewardTitle => 'RÉCOMPENSE QUOTIDIENNE';

  @override
  String dailyRewardGeoms(int amount) {
    return '+$amount GEOM';
  }

  @override
  String dailyRewardStreakOne(int count) {
    return 'Série : $count jour';
  }

  @override
  String dailyRewardStreakMany(int count) {
    return 'Série : $count jours';
  }

  @override
  String get settingsResetTitle => 'RÉINITIALISER';

  @override
  String get settingsResetWarning =>
      'Toute la progression, les améliorations et les achats seront effacés.';

  @override
  String get settingsResetButton => 'RESET';

  @override
  String get settingsResetAllData => 'RÉINITIALISER TOUT';

  @override
  String get badgeKiller => 'TUEUR';

  @override
  String get badgeMassacre => 'MASSACRE';

  @override
  String get badgePersistent => 'PERSÉVÉRANT';

  @override
  String get badgeVeteran => 'VÉTÉRAN';

  @override
  String get badgeBossHunter => 'CHASSEUR DE BOSS';

  @override
  String get badgeRegicide => 'RÉGICIDE';

  @override
  String get newAchievementBanner => '★ NOUVEAU SUCCÈS ! ★';

  @override
  String get columnDate => 'DATE';

  @override
  String leaderboardRecords(int count) {
    return '$count REC';
  }

  @override
  String get leaderboardNoRecord => 'AUCUN RECORD';

  @override
  String get leaderboardEmptyHint =>
      'Jouez à ce mode\npour entrer au classement !';

  @override
  String get statsSectionGeneral => 'GÉNÉRAL';

  @override
  String get statsSectionCombat => 'COMBAT';

  @override
  String get statsSectionRecords => 'RECORDS';

  @override
  String get statsSectionAchievements => 'SUCCÈS';

  @override
  String get statsSectionScoresByMode => 'SCORES PAR MODE';

  @override
  String get statsGamesPlayed => 'Parties jouées';

  @override
  String get statsTotalPlaytime => 'Temps total';

  @override
  String get statsTotalGoldEarned => 'Or total gagné';

  @override
  String get statsCurrentGold => 'Or actuel';

  @override
  String get statsEnemiesKilled => 'Ennemis tués';

  @override
  String get statsBossesDefeated => 'Boss vaincus';

  @override
  String get statsBombsUsed => 'Bombes utilisées';

  @override
  String get statsPowerUpsCollected => 'Power-ups collectés';

  @override
  String get statsGeomsCollected => 'Geoms collectés';

  @override
  String get statsBestScore => 'Meilleur score';

  @override
  String get statsHighestWave => 'Vague la plus haute';

  @override
  String get statsMaxMultiplier => 'Multiplicateur max';

  @override
  String get statsMaxSessionKills => 'Max kills en partie';

  @override
  String get statsMaxPerfectStreak => 'Max vagues parfaites';

  @override
  String get statsAchievementsUnlocked => 'Débloqués';

  @override
  String get summaryNone => 'Aucun';

  @override
  String get summaryScoreMultiplierTitle => 'MULTIPLICATEUR DE SCORE';

  @override
  String get summaryDifficultyRow => 'Difficulté';

  @override
  String get summaryModifiersRow => 'Modificateurs';

  @override
  String get summaryTotal => 'TOTAL';

  @override
  String summaryActiveModifiers(int count, String mult) {
    return '$count actifs · ×$mult score';
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
    return 'MAX $count MODIFICATEURS';
  }

  @override
  String modifiersScoreLabel(String mult) {
    return 'Score x$mult';
  }

  @override
  String modifiersActiveCount(int count, int max) {
    return 'Actifs : $count/$max';
  }

  @override
  String hudBossWave(int wave) {
    return 'BOSS VAGUE $wave';
  }

  @override
  String hudWaveNumber(int wave) {
    return 'VAGUE $wave';
  }

  @override
  String get hudPerfectWave => 'VAGUE PARFAITE !';

  @override
  String get hudPerfectBonus => '+10 GEOMS BONUS';

  @override
  String hudEnemiesRemaining(int count) {
    return '$count ENNEMIS';
  }

  @override
  String get hudBoost2x => '2x BOOST';

  @override
  String get powerUpRapidFire => 'TIR RAPIDE';

  @override
  String get powerUpOverdrive => 'OVERDRIVE';

  @override
  String get powerUpMagnet => 'AIMANT';

  @override
  String get powerUpTimeSlow => 'RALENTI';

  @override
  String get powerUpSpreadShot => 'TIR DISPERSÉ';

  @override
  String get powerUpFirePower => 'PUISSANCE DE FEU';

  @override
  String get tutorialTitle => 'COMMENT JOUER';

  @override
  String get tutorialLeftJoystick => 'JOYSTICK GAUCHE';

  @override
  String get tutorialLeftJoystickDesc => 'Déplace le vaisseau';

  @override
  String get tutorialRightJoystick => 'JOYSTICK DROIT';

  @override
  String get tutorialRightJoystickDesc => 'Vise et tire automatiquement';

  @override
  String get tutorialBomb => 'BOMBE';

  @override
  String get tutorialBombDesc => 'Détruit tous les ennemis proches';

  @override
  String get tutorialGeoms => 'GEOMS';

  @override
  String get tutorialGeomsDesc =>
      'Collecte-les pour des points et améliorations';

  @override
  String get tutorialPowerUp => 'POWER-UP';

  @override
  String get tutorialPowerUpDesc => 'Boosts temporaires';

  @override
  String get tutorialTapToStart => 'APPUIE POUR COMMENCER';

  @override
  String get skinNameClassic => 'Classic';

  @override
  String get skinDescClassic => 'Le vaisseau original cyan';

  @override
  String get skinNameStealth => 'Stealth';

  @override
  String get skinDescStealth => 'Noir avec bords rouges — style furtif';

  @override
  String get skinNameCrystal => 'Crystal';

  @override
  String get skinDescCrystal => 'Diamant prismatique — reflets arc-en-ciel';

  @override
  String get skinNameGhost => 'Ghost';

  @override
  String get skinDescGhost => 'Semi-transparent avec traînée de particules';

  @override
  String get skinNameOmega => 'Omega';

  @override
  String get skinDescOmega => 'Étoile dorée à 4 branches — forme unique';

  @override
  String get skinNamePhoenix => 'Phoenix';

  @override
  String get skinDescPhoenix =>
      'Ailes de feu avec plumes de braise — renaît de ses cendres';

  @override
  String get skinNameCyber => 'Cyber';

  @override
  String get skinDescCyber =>
      'Maillage de circuits vert néon — overlay numérique animé';

  @override
  String get skinNameVoidwalker => 'Voidwalker';

  @override
  String get skinDescVoidwalker =>
      'Noyau violet suspendu dans le vide — halo éthéré';

  @override
  String get skinNameAurora => 'Aurora';

  @override
  String get skinDescAurora => 'Boréale : cyan/rose/vert qui fluent';

  @override
  String get skinNameTactical => 'Tactical';

  @override
  String get skinDescTactical =>
      'Armure militaire gris/bleu — plaques blindées';

  @override
  String get skinNamePrism => 'Prism';

  @override
  String get skinDescPrism =>
      'Cristal polygonal — réfraction multi-arc-en-ciel';

  @override
  String get skinNameTron => 'Tron';

  @override
  String get skinDescTron =>
      'Corps noir avec lignes cyan néon — grille numérique';

  @override
  String get skinNameSamurai => 'Samurai';

  @override
  String get skinDescSamurai =>
      'Armure noire avec détails or/rouge — honneur et bataille';

  @override
  String get skinNameRosegold => 'RoseGold';

  @override
  String get skinDescRosegold => 'Rose-or métallique — élégance moderne';

  @override
  String get skinNameNinja => 'Ninja';

  @override
  String get skinDescNinja =>
      'Gris ombre avec accents shuriken — silencieux et létal';

  @override
  String get skinNameGlitch => 'Glitch';

  @override
  String get skinDescGlitch => 'Décalage chromatique RGB — aberration animée';

  @override
  String get trailNameNormal => 'Normal';

  @override
  String get trailDescNormal => 'Traînée cyan standard';

  @override
  String get trailNameFire => 'Fire';

  @override
  String get trailDescFire => 'Particules de feu derrière le vaisseau';

  @override
  String get trailNameIce => 'Ice';

  @override
  String get trailDescIce => 'Cristaux de glace scintillants';

  @override
  String get trailNamePlasma => 'Plasma';

  @override
  String get trailDescPlasma => 'Énergie plasma violette pulsante';

  @override
  String get trailNameRainbow => 'Rainbow';

  @override
  String get trailDescRainbow => 'Couleurs changeant continuellement';

  @override
  String get trailNameComet => 'Comet';

  @override
  String get trailDescComet =>
      'Tête lumineuse avec queue s\'éteignant lentement';

  @override
  String get trailNameInferno => 'Inferno';

  @override
  String get trailDescInferno => 'Feu multi-couche avec braises jaillissantes';

  @override
  String get trailNameVoid => 'Void';

  @override
  String get trailDescVoid => 'Vortex sombre aspirant des particules violettes';

  @override
  String get trailNameQuantum => 'Quantum';

  @override
  String get trailDescQuantum =>
      'Particules couplées en superposition chromatique';

  @override
  String get trailNameGalaxy => 'Galaxy';

  @override
  String get trailDescGalaxy => 'Étoiles en spirale avec poussière cosmique';

  @override
  String get trailNameLightning => 'Lightning';

  @override
  String get trailDescLightning =>
      'Arcs électriques zigzaguant entre les points';

  @override
  String get trailNameNebula => 'Nebula';

  @override
  String get trailDescNebula => 'Nuage spatial cyan/magenta pulsant';

  @override
  String get trailNamePrism => 'Prism';

  @override
  String get trailDescPrism =>
      'Spectre complet circulant le long de la traînée';

  @override
  String get trailNameHologram => 'Hologram';

  @override
  String get trailDescHologram => 'Aberration chromatique RGB style glitch';

  @override
  String get trailNameBiolume => 'Biolumin';

  @override
  String get trailDescBiolume => 'Bioluminescence aquatique verte/cyan';

  @override
  String get trailNameNeonpulse => 'NeonPulse';

  @override
  String get trailDescNeonpulse => 'Anneaux néon blanc-cyan en expansion';

  @override
  String get weaponNameBasic => 'Basic Gun';

  @override
  String get weaponDescBasic =>
      'Double rangée de balles jaunes parallèles — fiable et précis.';

  @override
  String get weaponNameTriple => 'Triple Shot';

  @override
  String get weaponDescTriple => '3 balles blanches serrées — feu concentré.';

  @override
  String get weaponNameSpread => 'Spread Shot';

  @override
  String get weaponDescSpread =>
      '5 balles oranges en éventail serré — idéal vs groupes.';

  @override
  String get weaponNameRicochet => 'Ricochet';

  @override
  String get weaponDescRicochet =>
      'Éventail de 3 tirs verts haut dégât rebondissant 2 fois sur les murs.';

  @override
  String get weaponNameHoming => 'Homing';

  @override
  String get weaponDescHoming =>
      '5 missiles traquant des cibles distinctes — explosent au mur.';

  @override
  String get weaponNamePlasma => 'Plasma';

  @override
  String get weaponDescPlasma =>
      'Orbe violet lent avec AoE explosive — dévaste boss et groupes.';

  @override
  String get weaponNameLaser => 'Laser';

  @override
  String get weaponDescLaser =>
      'Rayon rouge continu — coupe tout ce qu\'il touche.';

  @override
  String get weaponNameGauss => 'Gauss Cannon';

  @override
  String get weaponDescGauss =>
      'Tir violet avec aspiration gravitationnelle 1s — regroupe les ennemis pour les frapper tous.';

  @override
  String get weaponNameChain => 'Chain Lightning';

  @override
  String get weaponDescChain =>
      'Foudre électrique rebondit entre 5 ennemis — parfait vs groupes.';

  @override
  String get modeDescClassic =>
      '100 vagues avec boss tous les 10 — le mode standard';

  @override
  String get modeDescBossRush =>
      'Que des boss, l\'un après l\'autre — pas de mobs';

  @override
  String get modeDescSurvival =>
      'Vagues infinies de plus en plus dures — combien de temps tiens-tu ?';

  @override
  String get modeDescTimeAttack =>
      '3 minutes : fais le plus de points possible avant la fin';

  @override
  String get modeDescZenMode =>
      'Vies infinies — joue sans stress, explore tout';

  @override
  String get modeDescTunnel => 'Défilement latéral dans un tunnel infini';

  @override
  String get modeDescPacifist =>
      'Pas de tirs ! Survis avec les Portes (GW Pacifism)';

  @override
  String get modeDescWaves =>
      'Que des triangles rouges cardinaux. Rares trous noirs. Esquive pure.';

  @override
  String get modeDescGravityInferno =>
      'Beaucoup de trous noirs + peu de mobs mixtes. Pas de boss. Chaos gravitationnel.';

  @override
  String get upgradeFirepower => 'PUISSANCE';

  @override
  String get upgradeFirepowerDesc => '+5% dégâts par niveau (max +25%)';

  @override
  String get upgradeFireRate => 'CADENCE';

  @override
  String get upgradeFireRateDesc => '+5% cadence par niveau (max +25%)';

  @override
  String get upgradeSpeed => 'VITESSE';

  @override
  String get upgradeSpeedDesc => '+5% vitesse par niveau (max +25%)';

  @override
  String get upgradeShield => 'BOUCLIER';

  @override
  String get upgradeShieldDesc =>
      'Bouclier post-mort : 5s → 10s → 15s → 20s → 25s';

  @override
  String get upgradeLives => 'VIES';

  @override
  String get upgradeLivesDesc => 'Vies de départ : 3 → 4 → 5';

  @override
  String get upgradeBombs => 'BOMBES';

  @override
  String get upgradeBombsDesc => 'Bombes disponibles : 3 → 4 → 5';

  @override
  String get upgradeMagnet => 'AIMANT';

  @override
  String get upgradeMagnetDesc =>
      '+10px de portée aimant par niveau (max +50px)';

  @override
  String get upgradeXpBoost => 'BONUS XP';

  @override
  String get upgradeXpBoostDesc => '+10% GoldGeom par niveau (max +50%)';
}
