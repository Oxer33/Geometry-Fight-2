// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Geometry Fight 2';

  @override
  String get menuPlay => 'JUGAR';

  @override
  String get menuShop => 'TIENDA';

  @override
  String get menuStore => 'TIENDA';

  @override
  String get menuSettings => 'AJUSTES';

  @override
  String get menuStats => 'ESTADÍSTICAS';

  @override
  String get menuAchievements => 'TROFEOS';

  @override
  String get menuAchievementsAlt => 'LOGROS';

  @override
  String get menuLeaderboard => 'CLASIFICACIÓN';

  @override
  String get menuQuit => 'SALIR';

  @override
  String get diffEasy => 'FÁCIL';

  @override
  String get diffNormal => 'NORMAL';

  @override
  String get diffHard => 'DIFÍCIL';

  @override
  String get diffNightmare => 'PESADILLA';

  @override
  String get diffNext => 'SIGUIENTE';

  @override
  String get diffTitle => 'DIFICULTAD';

  @override
  String get diffScoreMultiplier => 'puntos';

  @override
  String get settingsTitle => 'AJUSTES';

  @override
  String get settingsAudio => 'AUDIO';

  @override
  String get settingsGameplay => 'JUEGO';

  @override
  String get settingsMusic => 'MÚSICA';

  @override
  String get settingsSfx => 'SFX';

  @override
  String get settingsSfxLong => 'EFECTOS DE SONIDO';

  @override
  String get settingsVibration => 'VIBRACIÓN';

  @override
  String get settingsShowFps => 'MOSTRAR FPS';

  @override
  String get settingsLanguage => 'IDIOMA';

  @override
  String get settingsCrashLogs => 'REGISTROS DE FALLOS';

  @override
  String get settingsReset => 'REINICIAR DATOS';

  @override
  String get settingsDangerZone => 'ZONA PELIGROSA';

  @override
  String get settingsTestDebug => 'TEST / DEBUG';

  @override
  String get settingsAddCredits => '+1000 CRÉDITOS';

  @override
  String get settingsResetPurchases => 'REINICIAR COMPRAS';

  @override
  String get settingsPurchasesReset => '¡Compras reiniciadas!';

  @override
  String settingsCreditsAdded(int total) {
    return '¡+1000 créditos! Total: $total';
  }

  @override
  String settingsCrashLogsTitle(int count) {
    return 'FALLOS ($count)';
  }

  @override
  String get settingsNoCrash =>
      'Sin fallos registrados.\nSi el juego falla, aparecerá aquí.';

  @override
  String get settingsCopy => 'COPIAR';

  @override
  String get settingsDelete => 'BORRAR';

  @override
  String get settingsLogsCopied => 'Registros copiados';

  @override
  String get shopTitle => 'TIENDA';

  @override
  String get shopGoldInsufficient => '¡Oro insuficiente!';

  @override
  String get shopEquip => 'EQUIPAR';

  @override
  String get shopEquipped => 'EQUIPADO';

  @override
  String get shopBuy => 'COMPRAR';

  @override
  String get shopMaxLevel => 'MAX';

  @override
  String get shopTabWeapons => 'ARMAS';

  @override
  String get shopTabSkins => 'ASPECTOS';

  @override
  String get shopTabTrails => 'ESTELAS';

  @override
  String get shopTabPets => 'MASCOTAS';

  @override
  String get shopTabUpgrades => 'MEJORAS';

  @override
  String get shopTabModes => 'MODOS';

  @override
  String get shopPurchased => '¡Comprado!';

  @override
  String get shopLocked => 'BLOQUEADO';

  @override
  String get shopCost => 'COSTE';

  @override
  String get shopLevel => 'NIVEL';

  @override
  String get shopScrollMore => 'Desliza para más';

  @override
  String get loadoutTitle => 'EQUIPO';

  @override
  String get loadoutWeapon => 'ARMA';

  @override
  String get loadoutPet => 'MASCOTA';

  @override
  String get loadoutLocked => 'Desbloquea esta arma en la TIENDA';

  @override
  String get loadoutPetLocked => 'Desbloquea esta mascota en la TIENDA';

  @override
  String get loadoutStart => 'INICIAR PARTIDA';

  @override
  String get loadoutPetNone => 'NINGUNO';

  @override
  String shopAlreadyMax(String name) {
    return '¡$name ya está al máximo!';
  }

  @override
  String shopUpgradedToLevel(String name, int level) {
    return '$name NV $level';
  }

  @override
  String shopLevelOf(int current, int max) {
    return 'NV $current / $max';
  }

  @override
  String get shopBadgeNew => 'NUEVO';

  @override
  String get shopBadgeUnlocked => 'DESBLOQUEADO';

  @override
  String shopBuyWithCost(int cost) {
    return 'COMPRAR ${cost}g';
  }

  @override
  String get shopTapNodeForDetails => 'TOCA UN NODO PARA VER DETALLES';

  @override
  String get modeTitle => 'MODO';

  @override
  String get modeSelectTitle => 'SELECCIONAR MODO';

  @override
  String get modeEndless => 'INFINITO';

  @override
  String get modeBossRush => 'ASALTO DE JEFES';

  @override
  String get modeSurvival => 'SUPERVIVENCIA';

  @override
  String get modeChallenge => 'DESAFÍO';

  @override
  String get modeClassic => 'CLÁSICO';

  @override
  String get modePacifist => 'PACIFISTA';

  @override
  String get modeTimeAttack => 'CONTRARRELOJ';

  @override
  String get modeZen => 'ZEN';

  @override
  String get modeTunnel => 'TÚNEL';

  @override
  String get modeDailyChallenge => 'RETO DIARIO';

  @override
  String get modeWaves => 'OLEADAS';

  @override
  String get modeGravityInferno => 'INFIERNO GRAVITATORIO';

  @override
  String get splashSkip => 'SALTAR';

  @override
  String get splashTapToStart => 'TOCA PARA EMPEZAR';

  @override
  String get modifiersTitle => 'MODIFICADORES';

  @override
  String get modifiersConfirm => 'CONFIRMAR';

  @override
  String get back => 'ATRÁS';

  @override
  String get play => 'JUGAR';

  @override
  String get pause => 'PAUSA';

  @override
  String get resume => 'REANUDAR';

  @override
  String get restart => 'REINICIAR';

  @override
  String get retry => 'REINTENTAR';

  @override
  String get quit => 'SALIR';

  @override
  String get close => 'CERRAR';

  @override
  String get next => 'SIGUIENTE';

  @override
  String get start => 'INICIAR';

  @override
  String get yes => 'SÍ';

  @override
  String get no => 'NO';

  @override
  String get confirm => 'CONFIRMAR';

  @override
  String get cancel => 'CANCELAR';

  @override
  String get continueAction => 'CONTINUAR';

  @override
  String get score => 'PUNTUACIÓN';

  @override
  String get wave => 'OLEADA';

  @override
  String get lives => 'VIDAS';

  @override
  String get level => 'NIVEL';

  @override
  String get gold => 'ORO';

  @override
  String get geoms => 'GEOMS';

  @override
  String get best => 'MEJOR';

  @override
  String get kills => 'BAJAS';

  @override
  String get timeLabel => 'TIEMPO';

  @override
  String get highScore => 'RÉCORD';

  @override
  String get newRun => 'NUEVA PARTIDA';

  @override
  String get gameOver => 'FIN DEL JUEGO';

  @override
  String get newRecord => '¡NUEVO RÉCORD!';

  @override
  String get victory => 'VICTORIA';

  @override
  String get achievementsTitle => 'TROFEOS';

  @override
  String get achievementUnlocked => '¡Trofeo Desbloqueado!';

  @override
  String get achievementCategoryCombat => 'COMBATE';

  @override
  String get achievementCategoryScore => 'PUNTUACIÓN';

  @override
  String get achievementCategoryProgress => 'PROGRESO';

  @override
  String get achievementCategoryMastery => 'MAESTRÍA';

  @override
  String get achievementCategorySpecial => 'ESPECIAL';

  @override
  String get leaderboardTitle => 'CLASIFICACIÓN';

  @override
  String get leaderboardEmpty => 'Sin puntuaciones aún';

  @override
  String get statsTitle => 'ESTADÍSTICAS';

  @override
  String get summaryTitle => 'RESUMEN';

  @override
  String get dailyRewardTitle => 'RECOMPENSA DIARIA';

  @override
  String dailyRewardGeoms(int amount) {
    return '+$amount GEOM';
  }

  @override
  String dailyRewardStreakOne(int count) {
    return 'Racha: $count día';
  }

  @override
  String dailyRewardStreakMany(int count) {
    return 'Racha: $count días';
  }

  @override
  String get settingsResetTitle => 'RESETEAR DATOS';

  @override
  String get settingsResetWarning =>
      'Todo el progreso, mejoras y compras serán eliminados.';

  @override
  String get settingsResetButton => 'RESETEAR';

  @override
  String get settingsResetAllData => 'RESETEAR TODOS LOS DATOS';

  @override
  String get badgeKiller => 'ASESINO';

  @override
  String get badgeMassacre => 'MASACRE';

  @override
  String get badgePersistent => 'PERSISTENTE';

  @override
  String get badgeVeteran => 'VETERANO';

  @override
  String get badgeBossHunter => 'CAZADOR DE JEFES';

  @override
  String get badgeRegicide => 'REGICIDA';

  @override
  String get newAchievementBanner => '★ ¡NUEVO LOGRO! ★';

  @override
  String get columnDate => 'FECHA';

  @override
  String leaderboardRecords(int count) {
    return '$count REC';
  }

  @override
  String get leaderboardNoRecord => 'SIN RÉCORDS';

  @override
  String get leaderboardEmptyHint =>
      '¡Juega en este modo\npara entrar en la clasificación!';

  @override
  String get statsSectionGeneral => 'GENERAL';

  @override
  String get statsSectionCombat => 'COMBATE';

  @override
  String get statsSectionRecords => 'RÉCORDS';

  @override
  String get statsSectionAchievements => 'LOGROS';

  @override
  String get statsSectionScoresByMode => 'PUNTUACIONES POR MODO';

  @override
  String get statsGamesPlayed => 'Partidas jugadas';

  @override
  String get statsTotalPlaytime => 'Tiempo total';

  @override
  String get statsTotalGoldEarned => 'Oro total ganado';

  @override
  String get statsCurrentGold => 'Oro actual';

  @override
  String get statsEnemiesKilled => 'Enemigos eliminados';

  @override
  String get statsBossesDefeated => 'Jefes derrotados';

  @override
  String get statsBombsUsed => 'Bombas usadas';

  @override
  String get statsPowerUpsCollected => 'Power-ups recogidos';

  @override
  String get statsGeomsCollected => 'Geoms recogidos';

  @override
  String get statsBestScore => 'Mejor puntuación';

  @override
  String get statsHighestWave => 'Oleada más alta';

  @override
  String get statsMaxMultiplier => 'Multiplicador máximo';

  @override
  String get statsMaxSessionKills => 'Máx. bajas en partida';

  @override
  String get statsMaxPerfectStreak => 'Máx. oleadas perfectas';

  @override
  String get statsAchievementsUnlocked => 'Desbloqueados';

  @override
  String get summaryNone => 'Ninguno';

  @override
  String get summaryScoreMultiplierTitle => 'MULTIPLICADOR DE PUNTUACIÓN';

  @override
  String get summaryDifficultyRow => 'Dificultad';

  @override
  String get summaryModifiersRow => 'Modificadores';

  @override
  String get summaryTotal => 'TOTAL';

  @override
  String summaryActiveModifiers(int count, String mult) {
    return '$count activos · ×$mult score';
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
    return 'MÁX $count MODIFICADORES';
  }

  @override
  String modifiersScoreLabel(String mult) {
    return 'Score x$mult';
  }

  @override
  String modifiersActiveCount(int count, int max) {
    return 'Activos: $count/$max';
  }

  @override
  String hudBossWave(int wave) {
    return 'BOSS OLEADA $wave';
  }

  @override
  String hudWaveNumber(int wave) {
    return 'OLEADA $wave';
  }

  @override
  String get hudPerfectWave => '¡OLEADA PERFECTA!';

  @override
  String get hudPerfectBonus => '+10 GEOMS BONUS';

  @override
  String hudEnemiesRemaining(int count) {
    return '$count ENEMIGOS';
  }

  @override
  String get hudBoost2x => '2x BOOST';

  @override
  String get powerUpRapidFire => 'FUEGO RÁPIDO';

  @override
  String get powerUpOverdrive => 'OVERDRIVE';

  @override
  String get powerUpMagnet => 'IMÁN';

  @override
  String get powerUpTimeSlow => 'TIEMPO LENTO';

  @override
  String get powerUpSpreadShot => 'DISPARO MÚLTIPLE';

  @override
  String get powerUpFirePower => 'PODER DE FUEGO';

  @override
  String get tutorialTitle => 'CÓMO JUGAR';

  @override
  String get tutorialLeftJoystick => 'JOYSTICK IZQUIERDO';

  @override
  String get tutorialLeftJoystickDesc => 'Mueve la nave';

  @override
  String get tutorialRightJoystick => 'JOYSTICK DERECHO';

  @override
  String get tutorialRightJoystickDesc => 'Apunta y dispara automáticamente';

  @override
  String get tutorialBomb => 'BOMBA';

  @override
  String get tutorialBombDesc => 'Destruye a todos los enemigos cercanos';

  @override
  String get tutorialGeoms => 'GEOMS';

  @override
  String get tutorialGeomsDesc => 'Recógelos para puntos y mejoras';

  @override
  String get tutorialPowerUp => 'POWER-UP';

  @override
  String get tutorialPowerUpDesc => 'Mejoras temporales';

  @override
  String get tutorialTapToStart => 'TOCA PARA EMPEZAR';
}
