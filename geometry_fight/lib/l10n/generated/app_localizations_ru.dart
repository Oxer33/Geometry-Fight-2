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

  @override
  String get skinNameClassic => 'Classic';

  @override
  String get skinDescClassic => 'Оригинальный голубой корабль';

  @override
  String get skinNameStealth => 'Stealth';

  @override
  String get skinDescStealth => 'Чёрный с красными краями — скрытный стиль';

  @override
  String get skinNameCrystal => 'Crystal';

  @override
  String get skinDescCrystal => 'Призматический алмаз — радужные отражения';

  @override
  String get skinNameGhost => 'Ghost';

  @override
  String get skinDescGhost => 'Полупрозрачный со шлейфом частиц';

  @override
  String get skinNameOmega => 'Omega';

  @override
  String get skinDescOmega => 'Золотая 4-конечная звезда — уникальная форма';

  @override
  String get skinNamePhoenix => 'Phoenix';

  @override
  String get skinDescPhoenix =>
      'Огненные крылья с перьями-углями — возрождается из пепла';

  @override
  String get skinNameCyber => 'Cyber';

  @override
  String get skinDescCyber =>
      'Неоново-зелёная сетка схем — анимированный цифровой оверлей';

  @override
  String get skinNameVoidwalker => 'Voidwalker';

  @override
  String get skinDescVoidwalker => 'Фиолетовое ядро в пустоте — эфирный ореол';

  @override
  String get skinNameAurora => 'Aurora';

  @override
  String get skinDescAurora =>
      'Северное сияние: голубой/розовый/зелёный потоки';

  @override
  String get skinNameTactical => 'Tactical';

  @override
  String get skinDescTactical =>
      'Военная броня серо-синяя — бронированные пластины';

  @override
  String get skinNamePrism => 'Prism';

  @override
  String get skinDescPrism =>
      'Полигональный кристалл — мульти-радужное преломление';

  @override
  String get skinNameTron => 'Tron';

  @override
  String get skinDescTron =>
      'Чёрный корпус с неоновыми голубыми линиями — цифровая сетка схем';

  @override
  String get skinNameSamurai => 'Samurai';

  @override
  String get skinDescSamurai =>
      'Чёрная броня с золото-красными деталями — честь и битва';

  @override
  String get skinNameRosegold => 'RoseGold';

  @override
  String get skinDescRosegold =>
      'Металлическое розовое золото — современная элегантность';

  @override
  String get skinNameNinja => 'Ninja';

  @override
  String get skinDescNinja =>
      'Теневой серый с акцентами сюрикена — тихий и смертоносный';

  @override
  String get skinNameGlitch => 'Glitch';

  @override
  String get skinDescGlitch =>
      'RGB хроматический сдвиг — анимированная аберрация';

  @override
  String get trailNameNormal => 'Normal';

  @override
  String get trailDescNormal => 'Стандартный голубой след';

  @override
  String get trailNameFire => 'Fire';

  @override
  String get trailDescFire => 'Огненные частицы за кораблём';

  @override
  String get trailNameIce => 'Ice';

  @override
  String get trailDescIce => 'Сверкающие ледяные кристаллы';

  @override
  String get trailNamePlasma => 'Plasma';

  @override
  String get trailDescPlasma => 'Пульсирующая фиолетовая плазма';

  @override
  String get trailNameRainbow => 'Rainbow';

  @override
  String get trailDescRainbow => 'Непрерывно меняющиеся цвета';

  @override
  String get trailNameComet => 'Comet';

  @override
  String get trailDescComet => 'Яркая голова с медленно угасающим хвостом';

  @override
  String get trailNameInferno => 'Inferno';

  @override
  String get trailDescInferno => 'Многослойный огонь с разлетающимися углями';

  @override
  String get trailNameVoid => 'Void';

  @override
  String get trailDescVoid => 'Тёмный вихрь, поглощающий фиолетовые частицы';

  @override
  String get trailNameQuantum => 'Quantum';

  @override
  String get trailDescQuantum =>
      'Связанные частицы в хроматической суперпозиции';

  @override
  String get trailNameGalaxy => 'Galaxy';

  @override
  String get trailDescGalaxy => 'Звёзды по спирали с космической пылью';

  @override
  String get trailNameLightning => 'Lightning';

  @override
  String get trailDescLightning =>
      'Зигзагообразные электродуги между точками следа';

  @override
  String get trailNameNebula => 'Nebula';

  @override
  String get trailDescNebula =>
      'Пульсирующее голубо-пурпурное космическое облако';

  @override
  String get trailNamePrism => 'Prism';

  @override
  String get trailDescPrism => 'Полный спектр течёт вдоль следа';

  @override
  String get trailNameHologram => 'Hologram';

  @override
  String get trailDescHologram => 'RGB хроматическая аберрация в стиле глитч';

  @override
  String get trailNameBiolume => 'Biolumin';

  @override
  String get trailDescBiolume => 'Водная биолюминесценция зелёная/голубая';

  @override
  String get trailNameNeonpulse => 'NeonPulse';

  @override
  String get trailDescNeonpulse => 'Расширяющиеся бело-голубые неоновые кольца';

  @override
  String get weaponNameBasic => 'Basic Gun';

  @override
  String get weaponDescBasic =>
      'Двойной ряд параллельных жёлтых пуль — надёжно и точно.';

  @override
  String get weaponNameTriple => 'Triple Shot';

  @override
  String get weaponDescTriple =>
      '3 плотных белых пули — концентрированный огонь.';

  @override
  String get weaponNameSpread => 'Spread Shot';

  @override
  String get weaponDescSpread =>
      '5 оранжевых пуль узким веером — отлично против групп.';

  @override
  String get weaponNameRicochet => 'Ricochet';

  @override
  String get weaponDescRicochet =>
      'Веер из 3 зелёных снарядов высокого урона, отскакивают 2 раза от стен.';

  @override
  String get weaponNameHoming => 'Homing';

  @override
  String get weaponDescHoming =>
      '5 ракет преследуют разные цели — взрываются о стены.';

  @override
  String get weaponNamePlasma => 'Plasma';

  @override
  String get weaponDescPlasma =>
      'Медленный фиолетовый шар со взрывным AoE — крушит боссов и группы.';

  @override
  String get weaponNameLaser => 'Laser';

  @override
  String get weaponDescLaser =>
      'Непрерывный красный луч — режет всё на своём пути.';

  @override
  String get weaponNameGauss => 'Gauss Cannon';

  @override
  String get weaponDescGauss =>
      'Фиолетовый выстрел с гравитационным притяжением 1с — собирает врагов для удара по всем.';

  @override
  String get weaponNameChain => 'Chain Lightning';

  @override
  String get weaponDescChain =>
      'Электрическая молния скачет между 5 врагами — идеально против групп.';

  @override
  String get modeDescClassic =>
      '100 волн с боссом каждые 10 — стандартный режим';

  @override
  String get modeDescBossRush => 'Только боссы, один за другим — без мобов';

  @override
  String get modeDescSurvival =>
      'Бесконечные волны всё сложнее — сколько выдержишь?';

  @override
  String get modeDescTimeAttack =>
      '3 минуты: набери максимум очков до окончания времени';

  @override
  String get modeDescZenMode =>
      'Бесконечные жизни — играй без стресса, изучай всё';

  @override
  String get modeDescTunnel => 'Боковая прокрутка в бесконечном туннеле';

  @override
  String get modeDescPacifist =>
      'Без выстрелов! Выживай с помощью Gates (GW Pacifism)';

  @override
  String get modeDescWaves =>
      'Только кардинальные красные треугольники. Редкие чёрные дыры. Чистое уклонение.';

  @override
  String get modeDescGravityInferno =>
      'Много чёрных дыр + мало смешанных мобов. Без боссов. Гравитационный хаос.';

  @override
  String get upgradeFirepower => 'УРОН';

  @override
  String get upgradeFirepowerDesc => '+5% урона за уровень (макс +25%)';

  @override
  String get upgradeFireRate => 'СКОРОСТРЕЛЬН.';

  @override
  String get upgradeFireRateDesc =>
      '+5% скорострельности за уровень (макс +25%)';

  @override
  String get upgradeSpeed => 'СКОРОСТЬ';

  @override
  String get upgradeSpeedDesc => '+5% скорости за уровень (макс +25%)';

  @override
  String get upgradeShield => 'ЩИТ';

  @override
  String get upgradeShieldDesc =>
      'Щит после смерти: 5с → 10с → 15с → 20с → 25с';

  @override
  String get upgradeLives => 'ЖИЗНИ';

  @override
  String get upgradeLivesDesc => 'Начальные жизни: 3 → 4 → 5';

  @override
  String get upgradeBombs => 'БОМБЫ';

  @override
  String get upgradeBombsDesc => 'Доступные бомбы: 3 → 4 → 5';

  @override
  String get upgradeMagnet => 'МАГНИТ';

  @override
  String get upgradeMagnetDesc =>
      '+10px радиуса магнита за уровень (макс +50px)';

  @override
  String get upgradeXpBoost => 'БУСТ XP';

  @override
  String get upgradeXpBoostDesc => '+10% GoldGeom за уровень (макс +50%)';
}
