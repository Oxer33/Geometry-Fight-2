// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'Geometry Fight 2';

  @override
  String get menuPlay => 'SPIELEN';

  @override
  String get menuShop => 'SHOP';

  @override
  String get menuStore => 'SHOP';

  @override
  String get menuSettings => 'EINSTELLUNGEN';

  @override
  String get menuStats => 'STATISTIKEN';

  @override
  String get menuAchievements => 'TROPHÄEN';

  @override
  String get menuAchievementsAlt => 'ERFOLGE';

  @override
  String get menuLeaderboard => 'BESTENLISTE';

  @override
  String get menuQuit => 'BEENDEN';

  @override
  String get diffEasy => 'LEICHT';

  @override
  String get diffNormal => 'NORMAL';

  @override
  String get diffHard => 'SCHWER';

  @override
  String get diffNightmare => 'ALPTRAUM';

  @override
  String get diffNext => 'WEITER';

  @override
  String get diffTitle => 'SCHWIERIGKEIT';

  @override
  String get diffScoreMultiplier => 'punkte';

  @override
  String get settingsTitle => 'EINSTELLUNGEN';

  @override
  String get settingsAudio => 'AUDIO';

  @override
  String get settingsGameplay => 'GAMEPLAY';

  @override
  String get settingsMusic => 'MUSIK';

  @override
  String get settingsSfx => 'SFX';

  @override
  String get settingsSfxLong => 'SOUND-EFFEKTE';

  @override
  String get settingsVibration => 'VIBRATION';

  @override
  String get settingsShowFps => 'FPS ANZEIGEN';

  @override
  String get settingsLanguage => 'SPRACHE';

  @override
  String get settingsCrashLogs => 'ABSTURZBERICHTE';

  @override
  String get settingsReset => 'DATEN ZURÜCKSETZEN';

  @override
  String get settingsDangerZone => 'GEFAHRENZONE';

  @override
  String get settingsTestDebug => 'TEST / DEBUG';

  @override
  String get settingsAddCredits => '+1000 KREDITS';

  @override
  String get settingsResetPurchases => 'KÄUFE ZURÜCKSETZEN';

  @override
  String get settingsPurchasesReset => 'Käufe zurückgesetzt!';

  @override
  String settingsCreditsAdded(int total) {
    return '+1000 Kredits! Gesamt: $total';
  }

  @override
  String settingsCrashLogsTitle(int count) {
    return 'ABSTÜRZE ($count)';
  }

  @override
  String get settingsNoCrash =>
      'Keine Abstürze protokolliert.\nBei Absturz erscheint er hier.';

  @override
  String get settingsCopy => 'KOPIEREN';

  @override
  String get settingsDelete => 'LÖSCHEN';

  @override
  String get settingsLogsCopied => 'Protokolle kopiert';

  @override
  String get shopTitle => 'SHOP';

  @override
  String get shopGoldInsufficient => 'Nicht genug Gold!';

  @override
  String get shopEquip => 'AUSRÜSTEN';

  @override
  String get shopEquipped => 'AUSGERÜSTET';

  @override
  String get shopBuy => 'KAUFEN';

  @override
  String get shopMaxLevel => 'MAX';

  @override
  String get shopTabWeapons => 'WAFFEN';

  @override
  String get shopTabSkins => 'SKINS';

  @override
  String get shopTabTrails => 'SPUREN';

  @override
  String get shopTabPets => 'GEFÄHRTEN';

  @override
  String get shopTabUpgrades => 'UPGRADES';

  @override
  String get shopTabModes => 'MODI';

  @override
  String get shopPurchased => 'Gekauft!';

  @override
  String get shopLocked => 'GESPERRT';

  @override
  String get shopCost => 'KOSTEN';

  @override
  String get shopLevel => 'STUFE';

  @override
  String get shopScrollMore => 'Scrollen für mehr';

  @override
  String get loadoutTitle => 'AUSRÜSTUNG';

  @override
  String get loadoutWeapon => 'WAFFE';

  @override
  String get loadoutPet => 'GEFÄHRTE';

  @override
  String get loadoutLocked => 'Schalte diese Waffe im SHOP frei';

  @override
  String get loadoutPetLocked => 'Schalte diesen Gefährten im SHOP frei';

  @override
  String get loadoutStart => 'SPIEL STARTEN';

  @override
  String get loadoutPetNone => 'KEINER';

  @override
  String shopAlreadyMax(String name) {
    return '$name bereits maximal!';
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
  String get shopBadgeNew => 'NEU';

  @override
  String get shopBadgeUnlocked => 'FREIGESCHALTET';

  @override
  String shopBuyWithCost(int cost) {
    return 'KAUFEN ${cost}g';
  }

  @override
  String get shopTapNodeForDetails => 'TIPPE EINEN KNOTEN AN FÜR DETAILS';

  @override
  String get modeTitle => 'MODUS';

  @override
  String get modeSelectTitle => 'MODUS WÄHLEN';

  @override
  String get modeEndless => 'ENDLOS';

  @override
  String get modeBossRush => 'BOSS RUSH';

  @override
  String get modeSurvival => 'ÜBERLEBEN';

  @override
  String get modeChallenge => 'HERAUSFORDERUNG';

  @override
  String get modeClassic => 'KLASSISCH';

  @override
  String get modePacifist => 'PAZIFIST';

  @override
  String get modeTimeAttack => 'ZEITANGRIFF';

  @override
  String get modeZen => 'ZEN';

  @override
  String get modeTunnel => 'TUNNEL';

  @override
  String get modeDailyChallenge => 'TÄGLICHE HERAUSFORDERUNG';

  @override
  String get modeWaves => 'WELLEN';

  @override
  String get modeGravityInferno => 'GRAVITATIONS-INFERNO';

  @override
  String get splashSkip => 'ÜBERSPRINGEN';

  @override
  String get splashTapToStart => 'TIPPE ZUM STARTEN';

  @override
  String get modifiersTitle => 'MODIFIKATOREN';

  @override
  String get modifiersConfirm => 'BESTÄTIGEN';

  @override
  String get back => 'ZURÜCK';

  @override
  String get play => 'SPIELEN';

  @override
  String get pause => 'PAUSE';

  @override
  String get resume => 'FORTSETZEN';

  @override
  String get restart => 'NEUSTART';

  @override
  String get retry => 'ERNEUT';

  @override
  String get quit => 'BEENDEN';

  @override
  String get close => 'SCHLIESSEN';

  @override
  String get next => 'WEITER';

  @override
  String get start => 'START';

  @override
  String get yes => 'JA';

  @override
  String get no => 'NEIN';

  @override
  String get confirm => 'BESTÄTIGEN';

  @override
  String get cancel => 'ABBRECHEN';

  @override
  String get continueAction => 'WEITER';

  @override
  String get score => 'PUNKTE';

  @override
  String get wave => 'WELLE';

  @override
  String get lives => 'LEBEN';

  @override
  String get level => 'STUFE';

  @override
  String get gold => 'GOLD';

  @override
  String get geoms => 'GEOMS';

  @override
  String get best => 'BEST';

  @override
  String get kills => 'KILLS';

  @override
  String get timeLabel => 'ZEIT';

  @override
  String get highScore => 'REKORD';

  @override
  String get newRun => 'NEUE RUNDE';

  @override
  String get gameOver => 'SPIEL VORBEI';

  @override
  String get newRecord => 'NEUER REKORD!';

  @override
  String get victory => 'SIEG';

  @override
  String get achievementsTitle => 'TROPHÄEN';

  @override
  String get achievementUnlocked => 'Trophäe freigeschaltet!';

  @override
  String get achievementCategoryCombat => 'KAMPF';

  @override
  String get achievementCategoryScore => 'PUNKTE';

  @override
  String get achievementCategoryProgress => 'FORTSCHRITT';

  @override
  String get achievementCategoryMastery => 'MEISTERSCHAFT';

  @override
  String get achievementCategorySpecial => 'SPEZIAL';

  @override
  String get leaderboardTitle => 'BESTENLISTE';

  @override
  String get leaderboardEmpty => 'Noch keine Punkte';

  @override
  String get statsTitle => 'STATISTIKEN';

  @override
  String get summaryTitle => 'ZUSAMMENFASSUNG';

  @override
  String get dailyRewardTitle => 'TÄGLICHE BELOHNUNG';

  @override
  String dailyRewardGeoms(int amount) {
    return '+$amount GEOM';
  }

  @override
  String dailyRewardStreakOne(int count) {
    return 'Serie: $count Tag';
  }

  @override
  String dailyRewardStreakMany(int count) {
    return 'Serie: $count Tage';
  }

  @override
  String get settingsResetTitle => 'ZURÜCKSETZEN';

  @override
  String get settingsResetWarning =>
      'Alle Fortschritte, Upgrades und Käufe werden gelöscht.';

  @override
  String get settingsResetButton => 'RESET';

  @override
  String get settingsResetAllData => 'ALLE DATEN LÖSCHEN';

  @override
  String get badgeKiller => 'KILLER';

  @override
  String get badgeMassacre => 'MASSAKER';

  @override
  String get badgePersistent => 'BEHARRLICH';

  @override
  String get badgeVeteran => 'VETERAN';

  @override
  String get badgeBossHunter => 'BOSS-JÄGER';

  @override
  String get badgeRegicide => 'KÖNIGSMÖRDER';

  @override
  String get newAchievementBanner => '★ NEUER ERFOLG! ★';

  @override
  String get columnDate => 'DATUM';

  @override
  String leaderboardRecords(int count) {
    return '$count REC';
  }

  @override
  String get leaderboardNoRecord => 'KEINE REKORDE';

  @override
  String get leaderboardEmptyHint =>
      'Spiele diesen Modus,\num in die Bestenliste zu kommen!';

  @override
  String get statsSectionGeneral => 'ALLGEMEIN';

  @override
  String get statsSectionCombat => 'KAMPF';

  @override
  String get statsSectionRecords => 'REKORDE';

  @override
  String get statsSectionAchievements => 'ERFOLGE';

  @override
  String get statsSectionScoresByMode => 'PUNKTE NACH MODUS';

  @override
  String get statsGamesPlayed => 'Gespielte Spiele';

  @override
  String get statsTotalPlaytime => 'Gesamtspielzeit';

  @override
  String get statsTotalGoldEarned => 'Gesamtes Gold verdient';

  @override
  String get statsCurrentGold => 'Aktuelles Gold';

  @override
  String get statsEnemiesKilled => 'Getötete Gegner';

  @override
  String get statsBossesDefeated => 'Besiegte Bosse';

  @override
  String get statsBombsUsed => 'Verwendete Bomben';

  @override
  String get statsPowerUpsCollected => 'Power-ups gesammelt';

  @override
  String get statsGeomsCollected => 'Geoms gesammelt';

  @override
  String get statsBestScore => 'Beste Punktzahl';

  @override
  String get statsHighestWave => 'Höchste Welle';

  @override
  String get statsMaxMultiplier => 'Max. Multiplikator';

  @override
  String get statsMaxSessionKills => 'Max. Kills pro Runde';

  @override
  String get statsMaxPerfectStreak => 'Max. perfekte Wellen';

  @override
  String get statsAchievementsUnlocked => 'Freigeschaltet';

  @override
  String get summaryNone => 'Keine';

  @override
  String get summaryScoreMultiplierTitle => 'PUNKTE-MULTIPLIKATOR';

  @override
  String get summaryDifficultyRow => 'Schwierigkeit';

  @override
  String get summaryModifiersRow => 'Modifikatoren';

  @override
  String get summaryTotal => 'GESAMT';

  @override
  String summaryActiveModifiers(int count, String mult) {
    return '$count aktiv · ×$mult score';
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
    return 'MAX $count MODIFIKATOREN';
  }

  @override
  String modifiersScoreLabel(String mult) {
    return 'Score x$mult';
  }

  @override
  String modifiersActiveCount(int count, int max) {
    return 'Aktiv: $count/$max';
  }

  @override
  String hudBossWave(int wave) {
    return 'BOSS WELLE $wave';
  }

  @override
  String hudWaveNumber(int wave) {
    return 'WELLE $wave';
  }

  @override
  String get hudPerfectWave => 'PERFEKTE WELLE!';

  @override
  String get hudPerfectBonus => '+10 GEOMS BONUS';

  @override
  String hudEnemiesRemaining(int count) {
    return '$count GEGNER';
  }

  @override
  String get hudBoost2x => '2x BOOST';

  @override
  String get powerUpRapidFire => 'SCHNELLFEUER';

  @override
  String get powerUpOverdrive => 'OVERDRIVE';

  @override
  String get powerUpMagnet => 'MAGNET';

  @override
  String get powerUpTimeSlow => 'ZEITLUPE';

  @override
  String get powerUpSpreadShot => 'STREUSCHUSS';

  @override
  String get powerUpFirePower => 'FEUERKRAFT';

  @override
  String get tutorialTitle => 'SO WIRD GESPIELT';

  @override
  String get tutorialLeftJoystick => 'LINKER JOYSTICK';

  @override
  String get tutorialLeftJoystickDesc => 'Bewege das Schiff';

  @override
  String get tutorialRightJoystick => 'RECHTER JOYSTICK';

  @override
  String get tutorialRightJoystickDesc => 'Ziele und schieße automatisch';

  @override
  String get tutorialBomb => 'BOMBE';

  @override
  String get tutorialBombDesc => 'Zerstört alle nahen Gegner';

  @override
  String get tutorialGeoms => 'GEOMS';

  @override
  String get tutorialGeomsDesc => 'Sammle sie für Punkte und Upgrades';

  @override
  String get tutorialPowerUp => 'POWER-UP';

  @override
  String get tutorialPowerUpDesc => 'Zeitlich begrenzte Boosts';

  @override
  String get tutorialTapToStart => 'TIPPEN ZUM STARTEN';
}
