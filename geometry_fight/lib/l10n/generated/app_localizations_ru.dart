// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appTitle => 'Geometry Fight 2';

  @override
  String get menuPlay => 'ИГРАТЬ';

  @override
  String get menuShop => 'МАГАЗИН';

  @override
  String get menuStore => 'МАГАЗИН';

  @override
  String get menuSettings => 'НАСТРОЙКИ';

  @override
  String get menuStats => 'СТАТИСТИКА';

  @override
  String get menuAchievements => 'ТРОФЕИ';

  @override
  String get menuAchievementsAlt => 'ДОСТИЖЕНИЯ';

  @override
  String get menuLeaderboard => 'ТАБЛИЦА ЛИДЕРОВ';

  @override
  String get menuQuit => 'ВЫЙТИ';

  @override
  String get diffEasy => 'ЛЕГКО';

  @override
  String get diffNormal => 'НОРМАЛЬНО';

  @override
  String get diffHard => 'СЛОЖНО';

  @override
  String get diffNightmare => 'КОШМАР';

  @override
  String get diffNext => 'ДАЛЕЕ';

  @override
  String get diffTitle => 'СЛОЖНОСТЬ';

  @override
  String get diffScoreMultiplier => 'очки';

  @override
  String get settingsTitle => 'НАСТРОЙКИ';

  @override
  String get settingsAudio => 'ЗВУК';

  @override
  String get settingsGameplay => 'ИГРА';

  @override
  String get settingsMusic => 'МУЗЫКА';

  @override
  String get settingsSfx => 'SFX';

  @override
  String get settingsSfxLong => 'ЗВУКОВЫЕ ЭФФЕКТЫ';

  @override
  String get settingsVibration => 'ВИБРАЦИЯ';

  @override
  String get settingsShowFps => 'ПОКАЗЫВАТЬ FPS';

  @override
  String get settingsLanguage => 'ЯЗЫК';

  @override
  String get settingsCrashLogs => 'ЛОГИ СБОЕВ';

  @override
  String get settingsReset => 'СБРОС ДАННЫХ';

  @override
  String get settingsDangerZone => 'ОПАСНАЯ ЗОНА';

  @override
  String get settingsTestDebug => 'TEST / DEBUG';

  @override
  String get settingsAddCredits => '+1000 КРЕДИТОВ';

  @override
  String get settingsResetPurchases => 'СБРОС ПОКУПОК';

  @override
  String get settingsPurchasesReset => 'Покупки сброшены!';

  @override
  String settingsCreditsAdded(int total) {
    return '+1000 кредитов! Всего: $total';
  }

  @override
  String settingsCrashLogsTitle(int count) {
    return 'СБОИ ($count)';
  }

  @override
  String get settingsNoCrash =>
      'Сбоев не зарегистрировано.\nЕсли игра упадёт, появится здесь.';

  @override
  String get settingsCopy => 'КОПИРОВАТЬ';

  @override
  String get settingsDelete => 'УДАЛИТЬ';

  @override
  String get settingsLogsCopied => 'Логи скопированы';

  @override
  String get shopTitle => 'МАГАЗИН';

  @override
  String get shopGoldInsufficient => 'Недостаточно золота!';

  @override
  String get shopEquip => 'НАДЕТЬ';

  @override
  String get shopEquipped => 'ЭКИПИРОВАНО';

  @override
  String get shopBuy => 'КУПИТЬ';

  @override
  String get shopMaxLevel => 'MAX';

  @override
  String get shopTabWeapons => 'ОРУЖИЕ';

  @override
  String get shopTabSkins => 'СКИНЫ';

  @override
  String get shopTabTrails => 'СЛЕДЫ';

  @override
  String get shopTabPets => 'ПИТОМЦЫ';

  @override
  String get shopTabUpgrades => 'УЛУЧШЕНИЯ';

  @override
  String get shopTabModes => 'РЕЖИМЫ';

  @override
  String get shopPurchased => 'Куплено!';

  @override
  String get shopLocked => 'ЗАБЛОКИРОВАНО';

  @override
  String get shopCost => 'ЦЕНА';

  @override
  String get shopLevel => 'УРОВЕНЬ';

  @override
  String get shopScrollMore => 'Прокрути ещё';

  @override
  String get loadoutTitle => 'СНАРЯЖЕНИЕ';

  @override
  String get loadoutWeapon => 'ОРУЖИЕ';

  @override
  String get loadoutPet => 'ПИТОМЕЦ';

  @override
  String get loadoutLocked => 'Открой это оружие в МАГАЗИНЕ';

  @override
  String get loadoutPetLocked => 'Открой этого питомца в МАГАЗИНЕ';

  @override
  String get loadoutStart => 'НАЧАТЬ ИГРУ';

  @override
  String get loadoutPetNone => 'НЕТ';

  @override
  String shopAlreadyMax(String name) {
    return '$name уже максимум!';
  }

  @override
  String shopUpgradedToLevel(String name, int level) {
    return '$name УР $level';
  }

  @override
  String shopLevelOf(int current, int max) {
    return 'УР $current / $max';
  }

  @override
  String get shopBadgeNew => 'НОВОЕ';

  @override
  String get shopBadgeUnlocked => 'ОТКРЫТО';

  @override
  String shopBuyWithCost(int cost) {
    return 'КУПИТЬ ${cost}g';
  }

  @override
  String get shopTapNodeForDetails => 'НАЖМИ НА УЗЕЛ ДЛЯ ПОДРОБНОСТЕЙ';

  @override
  String get modeTitle => 'РЕЖИМ';

  @override
  String get modeSelectTitle => 'ВЫБРАТЬ РЕЖИМ';

  @override
  String get modeEndless => 'БЕСКОНЕЧНЫЙ';

  @override
  String get modeBossRush => 'BOSS RUSH';

  @override
  String get modeSurvival => 'ВЫЖИВАНИЕ';

  @override
  String get modeChallenge => 'ВЫЗОВ';

  @override
  String get modeClassic => 'КЛАССИКА';

  @override
  String get modePacifist => 'ПАЦИФИСТ';

  @override
  String get modeTimeAttack => 'НА ВРЕМЯ';

  @override
  String get modeZen => 'ДЗЕН';

  @override
  String get modeTunnel => 'ТОННЕЛЬ';

  @override
  String get modeDailyChallenge => 'ЕЖЕДНЕВНЫЙ ВЫЗОВ';

  @override
  String get modeWaves => 'ВОЛНЫ';

  @override
  String get modeGravityInferno => 'ГРАВИТАЦИОННЫЙ АД';

  @override
  String get splashSkip => 'ПРОПУСТИТЬ';

  @override
  String get splashTapToStart => 'НАЖМИТЕ, ЧТОБЫ НАЧАТЬ';

  @override
  String get modifiersTitle => 'МОДИФИКАТОРЫ';

  @override
  String get modifiersConfirm => 'ПОДТВЕРДИТЬ';

  @override
  String get back => 'НАЗАД';

  @override
  String get play => 'ИГРАТЬ';

  @override
  String get pause => 'ПАУЗА';

  @override
  String get resume => 'ПРОДОЛЖИТЬ';

  @override
  String get restart => 'ЗАНОВО';

  @override
  String get retry => 'ПОВТОРИТЬ';

  @override
  String get quit => 'ВЫЙТИ';

  @override
  String get close => 'ЗАКРЫТЬ';

  @override
  String get next => 'ДАЛЕЕ';

  @override
  String get start => 'СТАРТ';

  @override
  String get yes => 'ДА';

  @override
  String get no => 'НЕТ';

  @override
  String get confirm => 'ПОДТВЕРДИТЬ';

  @override
  String get cancel => 'ОТМЕНА';

  @override
  String get continueAction => 'ПРОДОЛЖИТЬ';

  @override
  String get score => 'ОЧКИ';

  @override
  String get wave => 'ВОЛНА';

  @override
  String get lives => 'ЖИЗНИ';

  @override
  String get level => 'УРОВЕНЬ';

  @override
  String get gold => 'ЗОЛОТО';

  @override
  String get geoms => 'GEOMS';

  @override
  String get best => 'ЛУЧШИЙ';

  @override
  String get kills => 'УБИЙСТВА';

  @override
  String get timeLabel => 'ВРЕМЯ';

  @override
  String get highScore => 'РЕКОРД';

  @override
  String get newRun => 'НОВЫЙ ЗАБЕГ';

  @override
  String get gameOver => 'КОНЕЦ ИГРЫ';

  @override
  String get newRecord => 'НОВЫЙ РЕКОРД!';

  @override
  String get victory => 'ПОБЕДА';

  @override
  String get achievementsTitle => 'ТРОФЕИ';

  @override
  String get achievementUnlocked => 'Трофей получен!';

  @override
  String get achievementCategoryCombat => 'БОЙ';

  @override
  String get achievementCategoryScore => 'ОЧКИ';

  @override
  String get achievementCategoryProgress => 'ПРОГРЕСС';

  @override
  String get achievementCategoryMastery => 'МАСТЕРСТВО';

  @override
  String get achievementCategorySpecial => 'ОСОБЫЕ';

  @override
  String get leaderboardTitle => 'ТАБЛИЦА ЛИДЕРОВ';

  @override
  String get leaderboardEmpty => 'Пока нет результатов';

  @override
  String get statsTitle => 'СТАТИСТИКА';

  @override
  String get summaryTitle => 'ИТОГ';

  @override
  String get dailyRewardTitle => 'ЕЖЕДНЕВНАЯ НАГРАДА';

  @override
  String dailyRewardGeoms(int amount) {
    return '+$amount GEOM';
  }

  @override
  String dailyRewardStreakOne(int count) {
    return 'Серия: $count день';
  }

  @override
  String dailyRewardStreakMany(int count) {
    return 'Серия: $count дней';
  }

  @override
  String get settingsResetTitle => 'СБРОС ДАННЫХ';

  @override
  String get settingsResetWarning =>
      'Весь прогресс, улучшения и покупки будут удалены.';

  @override
  String get settingsResetButton => 'СБРОС';

  @override
  String get settingsResetAllData => 'СБРОСИТЬ ВСЕ ДАННЫЕ';

  @override
  String get badgeKiller => 'УБИЙЦА';

  @override
  String get badgeMassacre => 'БОЙНЯ';

  @override
  String get badgePersistent => 'УПОРНЫЙ';

  @override
  String get badgeVeteran => 'ВЕТЕРАН';

  @override
  String get badgeBossHunter => 'ОХОТНИК НА БОССОВ';

  @override
  String get badgeRegicide => 'ЦАРЕУБИЙЦА';

  @override
  String get newAchievementBanner => '★ НОВОЕ ДОСТИЖЕНИЕ! ★';

  @override
  String get columnDate => 'ДАТА';

  @override
  String leaderboardRecords(int count) {
    return '$count REC';
  }

  @override
  String get leaderboardNoRecord => 'НЕТ РЕКОРДОВ';

  @override
  String get leaderboardEmptyHint =>
      'Сыграйте в этом режиме,\nчтобы попасть в таблицу!';

  @override
  String get statsSectionGeneral => 'ОБЩЕЕ';

  @override
  String get statsSectionCombat => 'БОЙ';

  @override
  String get statsSectionRecords => 'РЕКОРДЫ';

  @override
  String get statsSectionAchievements => 'ДОСТИЖЕНИЯ';

  @override
  String get statsSectionScoresByMode => 'ОЧКИ ПО РЕЖИМАМ';

  @override
  String get statsGamesPlayed => 'Сыграно игр';

  @override
  String get statsTotalPlaytime => 'Общее время';

  @override
  String get statsTotalGoldEarned => 'Всего золота';

  @override
  String get statsCurrentGold => 'Текущее золото';

  @override
  String get statsEnemiesKilled => 'Убито врагов';

  @override
  String get statsBossesDefeated => 'Побеждено боссов';

  @override
  String get statsBombsUsed => 'Использовано бомб';

  @override
  String get statsPowerUpsCollected => 'Собрано усилений';

  @override
  String get statsGeomsCollected => 'Собрано геомов';

  @override
  String get statsBestScore => 'Лучший счёт';

  @override
  String get statsHighestWave => 'Высшая волна';

  @override
  String get statsMaxMultiplier => 'Макс. множитель';

  @override
  String get statsMaxSessionKills => 'Макс. убийств за игру';

  @override
  String get statsMaxPerfectStreak => 'Макс. идеальных волн';

  @override
  String get statsAchievementsUnlocked => 'Открыто';

  @override
  String get summaryNone => 'Нет';

  @override
  String get summaryScoreMultiplierTitle => 'МНОЖИТЕЛЬ ОЧКОВ';

  @override
  String get summaryDifficultyRow => 'Сложность';

  @override
  String get summaryModifiersRow => 'Модификаторы';

  @override
  String get summaryTotal => 'ИТОГО';

  @override
  String summaryActiveModifiers(int count, String mult) {
    return '$count активно · ×$mult score';
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
    return 'МАКС $count МОДИФИКАТОРОВ';
  }

  @override
  String modifiersScoreLabel(String mult) {
    return 'Score x$mult';
  }

  @override
  String modifiersActiveCount(int count, int max) {
    return 'Активно: $count/$max';
  }

  @override
  String hudBossWave(int wave) {
    return 'БОСС ВОЛНА $wave';
  }

  @override
  String hudWaveNumber(int wave) {
    return 'ВОЛНА $wave';
  }

  @override
  String get hudPerfectWave => 'ИДЕАЛЬНАЯ ВОЛНА!';

  @override
  String get hudPerfectBonus => '+10 GEOMS БОНУС';

  @override
  String hudEnemiesRemaining(int count) {
    return '$count ВРАГОВ';
  }

  @override
  String get hudBoost2x => '2x BOOST';

  @override
  String get powerUpRapidFire => 'СКОРОСТРЕЛ';

  @override
  String get powerUpOverdrive => 'OVERDRIVE';

  @override
  String get powerUpMagnet => 'МАГНИТ';

  @override
  String get powerUpTimeSlow => 'ЗАМЕДЛЕНИЕ';

  @override
  String get powerUpSpreadShot => 'ВЕЕРНЫЙ ВЫСТРЕЛ';

  @override
  String get powerUpFirePower => 'ОГНЕВАЯ МОЩЬ';

  @override
  String get tutorialTitle => 'КАК ИГРАТЬ';

  @override
  String get tutorialLeftJoystick => 'ЛЕВЫЙ ДЖОЙСТИК';

  @override
  String get tutorialLeftJoystickDesc => 'Двигай корабль';

  @override
  String get tutorialRightJoystick => 'ПРАВЫЙ ДЖОЙСТИК';

  @override
  String get tutorialRightJoystickDesc => 'Прицеливание и автострельба';

  @override
  String get tutorialBomb => 'БОМБА';

  @override
  String get tutorialBombDesc => 'Уничтожает всех ближайших врагов';

  @override
  String get tutorialGeoms => 'GEOMS';

  @override
  String get tutorialGeomsDesc => 'Собирай для очков и улучшений';

  @override
  String get tutorialPowerUp => 'POWER-UP';

  @override
  String get tutorialPowerUpDesc => 'Временные усиления';

  @override
  String get tutorialTapToStart => 'НАЖМИ ДЛЯ СТАРТА';
}
