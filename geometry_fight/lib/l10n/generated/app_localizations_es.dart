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
  String get modeSnake => 'SERPIENTE';

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

  @override
  String get skinNameClassic => 'Classic';

  @override
  String get skinDescClassic => 'La nave original cian';

  @override
  String get skinNameStealth => 'Stealth';

  @override
  String get skinDescStealth => 'Negra con bordes rojos — estilo sigiloso';

  @override
  String get skinNameCrystal => 'Crystal';

  @override
  String get skinDescCrystal => 'Diamante prismático — reflejos arcoíris';

  @override
  String get skinNameGhost => 'Ghost';

  @override
  String get skinDescGhost => 'Semitransparente con estela de partículas';

  @override
  String get skinNameOmega => 'Omega';

  @override
  String get skinDescOmega => 'Estrella dorada de 4 puntas — forma única';

  @override
  String get skinNamePhoenix => 'Phoenix';

  @override
  String get skinDescPhoenix =>
      'Alas de fuego con plumas de brasa — renace de las cenizas';

  @override
  String get skinNameCyber => 'Cyber';

  @override
  String get skinDescCyber =>
      'Malla de circuitos verde neón — overlay digital animado';

  @override
  String get skinNameVoidwalker => 'Voidwalker';

  @override
  String get skinDescVoidwalker =>
      'Núcleo violeta suspendido en el vacío — halo etéreo';

  @override
  String get skinNameAurora => 'Aurora';

  @override
  String get skinDescAurora => 'Boreal: cian/rosa/verde fluyendo';

  @override
  String get skinNameTactical => 'Tactical';

  @override
  String get skinDescTactical =>
      'Armadura militar gris/azul — placas blindadas';

  @override
  String get skinNamePrism => 'Prism';

  @override
  String get skinDescPrism => 'Cristal poligonal — refracción multi-arcoíris';

  @override
  String get skinNameTron => 'Tron';

  @override
  String get skinDescTron =>
      'Cuerpo negro con líneas cian neón — rejilla digital';

  @override
  String get skinNameSamurai => 'Samurai';

  @override
  String get skinDescSamurai =>
      'Armadura negra con detalles oro/rojo — honor y batalla';

  @override
  String get skinNameRosegold => 'RoseGold';

  @override
  String get skinDescRosegold => 'Rosa-oro metálico — elegancia moderna';

  @override
  String get skinNameNinja => 'Ninja';

  @override
  String get skinDescNinja =>
      'Gris sombra con acentos shuriken — silencioso y letal';

  @override
  String get skinNameGlitch => 'Glitch';

  @override
  String get skinDescGlitch => 'Cambio cromático RGB — aberración animada';

  @override
  String get trailNameNormal => 'Normal';

  @override
  String get trailDescNormal => 'Estela cian estándar';

  @override
  String get trailNameFire => 'Fire';

  @override
  String get trailDescFire => 'Partículas de fuego detrás de la nave';

  @override
  String get trailNameIce => 'Ice';

  @override
  String get trailDescIce => 'Cristales de hielo brillantes';

  @override
  String get trailNamePlasma => 'Plasma';

  @override
  String get trailDescPlasma => 'Energía plasma morada pulsante';

  @override
  String get trailNameRainbow => 'Rainbow';

  @override
  String get trailDescRainbow => 'Colores cambiando continuamente';

  @override
  String get trailNameComet => 'Comet';

  @override
  String get trailDescComet =>
      'Cabeza brillante con cola que se apaga lentamente';

  @override
  String get trailNameInferno => 'Inferno';

  @override
  String get trailDescInferno => 'Fuego multicapa con brasas saltarinas';

  @override
  String get trailNameVoid => 'Void';

  @override
  String get trailDescVoid => 'Vórtice oscuro que absorbe partículas violetas';

  @override
  String get trailNameQuantum => 'Quantum';

  @override
  String get trailDescQuantum =>
      'Partículas acopladas en superposición cromática';

  @override
  String get trailNameGalaxy => 'Galaxy';

  @override
  String get trailDescGalaxy => 'Estrellas en espiral con polvo cósmico';

  @override
  String get trailNameLightning => 'Lightning';

  @override
  String get trailDescLightning =>
      'Arcos eléctricos en zigzag entre puntos de estela';

  @override
  String get trailNameNebula => 'Nebula';

  @override
  String get trailDescNebula => 'Nube espacial cian/magenta pulsante';

  @override
  String get trailNamePrism => 'Prism';

  @override
  String get trailDescPrism => 'Espectro completo fluyendo por la estela';

  @override
  String get trailNameHologram => 'Hologram';

  @override
  String get trailDescHologram => 'Aberración cromática RGB estilo glitch';

  @override
  String get trailNameBiolume => 'Biolumin';

  @override
  String get trailDescBiolume => 'Bioluminiscencia acuática verde/cian';

  @override
  String get trailNameNeonpulse => 'NeonPulse';

  @override
  String get trailDescNeonpulse => 'Anillos neón blanco-cian expandiéndose';

  @override
  String get weaponNameBasic => 'Basic Gun';

  @override
  String get weaponDescBasic =>
      'Doble fila de balas amarillas paralelas — fiable y precisa.';

  @override
  String get weaponNameTriple => 'Triple Shot';

  @override
  String get weaponDescTriple => '3 balas blancas juntas — fuego concentrado.';

  @override
  String get weaponNameSpread => 'Spread Shot';

  @override
  String get weaponDescSpread =>
      '5 balas naranjas en abanico estrecho — ideal vs grupos.';

  @override
  String get weaponNameRicochet => 'Ricochet';

  @override
  String get weaponDescRicochet =>
      'Abanico de 3 disparos verdes de alto daño que rebotan 2 veces en muros.';

  @override
  String get weaponNameHoming => 'Homing';

  @override
  String get weaponDescHoming =>
      '5 misiles que siguen objetivos distintos — explotan en muros.';

  @override
  String get weaponNamePlasma => 'Plasma';

  @override
  String get weaponDescPlasma =>
      'Orbe violeta lento con AoE explosiva — devasta jefes y grupos.';

  @override
  String get weaponNameLaser => 'Laser';

  @override
  String get weaponDescLaser => 'Rayo rojo continuo — corta todo lo que toca.';

  @override
  String get weaponNameGauss => 'Gauss Cannon';

  @override
  String get weaponDescGauss =>
      'Disparo violeta con succión gravitacional 1s — agrupa enemigos para golpearlos a todos.';

  @override
  String get weaponNameChain => 'Chain Lightning';

  @override
  String get weaponDescChain =>
      'Rayo eléctrico rebota entre 5 enemigos — perfecto vs grupos.';

  @override
  String get modeDescClassic =>
      '100 oleadas con jefe cada 10 — el modo estándar';

  @override
  String get modeDescBossRush => 'Solo jefes, uno tras otro — sin mobs';

  @override
  String get modeDescSurvival =>
      'Oleadas infinitas cada vez más difíciles — ¿cuánto aguantas?';

  @override
  String get modeDescTimeAttack =>
      '3 minutos: consigue cuantos puntos puedas antes de que acabe';

  @override
  String get modeDescZenMode =>
      'Vidas infinitas — juega sin estrés, explora todo';

  @override
  String get modeDescTunnel => 'Desplazamiento lateral en un túnel infinito';

  @override
  String get modeDescPacifist =>
      '¡Sin disparos! Sobrevive con las Puertas (GW Pacifism)';

  @override
  String get modeDescWaves =>
      'Solo triángulos rojos cardinales. Agujeros negros raros. Esquive puro.';

  @override
  String get modeDescGravityInferno =>
      'Muchos agujeros negros + pocos mobs mixtos. Sin jefes. Caos gravitacional.';

  @override
  String get modeDescSnake =>
      'Estela mortal al contacto. Sin armas, sin jefes, sin potenciadores.';

  @override
  String get upgradeFirepower => 'POTENCIA';

  @override
  String get upgradeFirepowerDesc => '+5% daño por nivel (máx +25%)';

  @override
  String get upgradeFireRate => 'CADENCIA';

  @override
  String get upgradeFireRateDesc => '+5% cadencia por nivel (máx +25%)';

  @override
  String get upgradeSpeed => 'VELOCIDAD';

  @override
  String get upgradeSpeedDesc => '+5% velocidad por nivel (máx +25%)';

  @override
  String get upgradeShield => 'ESCUDO';

  @override
  String get upgradeShieldDesc =>
      'Escudo post-muerte: 5s → 10s → 15s → 20s → 25s';

  @override
  String get upgradeLives => 'VIDAS';

  @override
  String get upgradeLivesDesc => 'Vidas iniciales: 3 → 4 → 5';

  @override
  String get upgradeBombs => 'RADIO BOMBA';

  @override
  String get upgradeBombsDesc =>
      '+radio de explosión por nivel (L0 media arena, L10 arena entera)';

  @override
  String get upgradeMagnet => 'IMÁN';

  @override
  String get upgradeMagnetDesc => '+10px de radio imán por nivel (máx +50px)';

  @override
  String get upgradeXpBoost => 'BONUS XP';

  @override
  String get upgradeXpBoostDesc => '+10% GoldGeom por nivel (máx +50%)';

  @override
  String get petNameAttack => 'ATAQUE';

  @override
  String get petDescAttack =>
      'Sigue al jugador + dispara ráfagas extra. Duplica la potencia.';

  @override
  String get petNameCollect => 'RECOLECTOR';

  @override
  String get petDescCollect =>
      'Vuela libre y recoge geoms a distancia. Bonus de economía.';

  @override
  String get petNameSweep => 'BARRIDO';

  @override
  String get petDescSweep =>
      'Orbita al jugador, mata enemigos al instante al tocarlos.';

  @override
  String get petNameDefend => 'DEFENSA';

  @override
  String get petDescDefend =>
      'Sigue detrás del jugador, dispara en la dirección opuesta.';

  @override
  String get petNameSnipe => 'FRANCOTIRADOR';

  @override
  String get petDescSnipe =>
      'Órbita lenta + láser al enemigo más cercano cada 1.5s.';

  @override
  String get petNameRam => 'EMBESTIDA';

  @override
  String get petDescRam =>
      'Persigue + choca contra el enemigo más cercano. Enfriamiento 1s.';

  @override
  String get petNamePhoenix => 'FÉNIX';

  @override
  String get petDescPhoenix =>
      'Auto-revivir una vez por partida + 2s de invulnerabilidad.';

  @override
  String get petNameBlackHole => 'AGUJERO NEGRO';

  @override
  String get petDescBlackHole =>
      'Pozo gravitacional: arrastra enemigos en 150px.';

  @override
  String get petNameEmpDrone => 'DRON EMP';

  @override
  String get petDescEmpDrone =>
      'Pulso aturde enemigos en 250px cada 8s (0.5s aturdidos).';

  @override
  String get petNameTacticalSpotter => 'OBSERVADOR TÁCTICO';

  @override
  String get petDescTacticalSpotter =>
      'Cámara lenta 0.5s si el jugador está en salud crítica. CD 6s.';

  @override
  String get weaponStatDmg => 'DMG';

  @override
  String get weaponStatRate => 'CAD';

  @override
  String get weaponStatRange => 'ALC';

  @override
  String get weaponStatBullets => 'BALAS';

  @override
  String get weaponStatSpread => 'DISP';

  @override
  String get weaponStatBounce => 'REB';

  @override
  String get weaponStatTrack => 'RAST';

  @override
  String get weaponStatBlast => 'EXPL';

  @override
  String get weaponStatAoe => 'AOE';

  @override
  String get weaponStatPierce => 'PERF';

  @override
  String get weaponStatLen => 'LONG';

  @override
  String get weaponStatPull => 'ATR';

  @override
  String get weaponStatJumps => 'SALT';

  @override
  String get weaponStatTick => 'tick';

  @override
  String get weaponRateMed => 'MED';

  @override
  String get weaponRateFast => 'RÁP';

  @override
  String get weaponRateSlow => 'LENT';

  @override
  String get weaponRateCont => 'CONT';

  @override
  String get modNoneCard => 'SIN MODIFICADORES';

  @override
  String get modNoneCardDesc => 'Juega sin modificadores activos.';

  @override
  String get modeLockedSnack => 'Desbloquea en la TIENDA';

  @override
  String get modNameGlassCannon => 'CAÑÓN DE CRISTAL';

  @override
  String get modDescGlassCannon =>
      '3x daño, pero solo 1 vida. Sin invencibilidad.';

  @override
  String get modNameBulletHell => 'INFIERNO DE BALAS';

  @override
  String get modDescBulletHell => 'Los enemigos disparan el doble de rápido.';

  @override
  String get modNameSpeedDemon => 'DEMONIO DE VELOCIDAD';

  @override
  String get modDescSpeedDemon =>
      'Todo se mueve 1.5x más rápido (jugador y enemigos).';

  @override
  String get modNameNoPowerups => 'PURISTA';

  @override
  String get modDescNoPowerups => 'Sin potenciadores durante la partida.';

  @override
  String get modNameFogOfWar => 'NIEBLA DE GUERRA';

  @override
  String get modDescFogOfWar =>
      'Visibilidad reducida. Solo el área cercana es visible.';

  @override
  String get modNameTinyArena => 'ARENA PEQUEÑA';

  @override
  String get modDescTinyArena =>
      'Arena reducida un 50%. Menos espacio para esquivar.';

  @override
  String get modNameOneShot => 'UN DISPARO';

  @override
  String get modDescOneShot =>
      'Todos los enemigos mueren de 1 golpe. Tú también.';

  @override
  String get modNameChaos => 'CAOS TOTAL';

  @override
  String get modDescChaos =>
      'Potenciador aleatorio cada 10 segundos automáticamente.';

  @override
  String get modNameGiantMode => 'GIGANTE';

  @override
  String get modDescGiantMode =>
      'Todo es 2x más grande. Enemigos, balas, todo.';

  @override
  String get modNameRicochetWorld => 'REBOTE TOTAL';

  @override
  String get modDescRicochetWorld => 'Todas las balas rebotan 5 veces.';

  @override
  String get modNameInfiniteBombs => 'BOMBARDERO';

  @override
  String get modDescInfiniteBombs => '¡Bombas infinitas! Pero sin armas.';

  @override
  String get modNameMagnetKing => 'REY IMÁN';

  @override
  String get modDescMagnetKing =>
      'Rango de imán enorme. Los geoms vuelan hacia ti.';

  @override
  String get gameOverBossLabel => 'JEFE';

  @override
  String get gameOverGoldGeoms => 'GEOMS DE ORO';

  @override
  String get achKills100Name => 'Primera Sangre';

  @override
  String get achKills100Desc => 'Mata 100 enemigos en total';

  @override
  String get achKills1000Name => 'Exterminador';

  @override
  String get achKills1000Desc => 'Mata 1.000 enemigos en total';

  @override
  String get achKills10000Name => 'Genocida Geométrico';

  @override
  String get achKills10000Desc => 'Mata 10.000 enemigos en total';

  @override
  String get achKills100000Name => 'Leyenda';

  @override
  String get achKills100000Desc => 'Mata 100.000 enemigos en total';

  @override
  String get achKillsSession200Name => 'Furia Ciega';

  @override
  String get achKillsSession200Desc => 'Mata 200 enemigos en una partida';

  @override
  String get achKillsSession500Name => 'Masacre';

  @override
  String get achKillsSession500Desc => 'Mata 500 enemigos en una partida';

  @override
  String get achKillsSession1000Name => 'Apocalipsis';

  @override
  String get achKillsSession1000Desc => 'Mata 1000 enemigos en una partida';

  @override
  String get achBosses10Name => 'Asesino de Jefes';

  @override
  String get achBosses10Desc => 'Derrota 10 jefes en total';

  @override
  String get achBosses50Name => 'Regicida';

  @override
  String get achBosses50Desc => 'Derrota 50 jefes en total';

  @override
  String get achBosses100Name => 'Exterminador Real';

  @override
  String get achBosses100Desc => 'Derrota 100 jefes en total';

  @override
  String get achBossSession5Name => 'Caza Real';

  @override
  String get achBossSession5Desc => 'Derrota 5 jefes en una partida';

  @override
  String get achBombs50Name => 'Artificiero';

  @override
  String get achBombs50Desc => 'Usa 50 bombas en total';

  @override
  String get achBombs500Name => 'Demoledor';

  @override
  String get achBombs500Desc => 'Usa 500 bombas en total';

  @override
  String get achScore100kName => 'Seis Cifras';

  @override
  String get achScore100kDesc => 'Alcanza 100.000 puntos';

  @override
  String get achScore1mName => 'Millonario';

  @override
  String get achScore1mDesc => 'Alcanza 1.000.000 puntos';

  @override
  String get achScore10mName => 'Rey de los Puntos';

  @override
  String get achScore10mDesc => 'Alcanza 10.000.000 puntos';

  @override
  String get achScore100mName => 'Centurión';

  @override
  String get achScore100mDesc => 'Alcanza 100.000.000 puntos';

  @override
  String get achScore1bName => 'Multimillonario';

  @override
  String get achScore1bDesc => 'Alcanza 1.000.000.000 puntos';

  @override
  String get achMultiplier100Name => 'Combo x100';

  @override
  String get achMultiplier100Desc => 'Alcanza un multiplicador de 100x';

  @override
  String get achMultiplier500Name => 'Combo x500';

  @override
  String get achMultiplier500Desc => 'Alcanza un multiplicador de 500x';

  @override
  String get achMultiplier1000Name => 'Combo x1000';

  @override
  String get achMultiplier1000Desc => 'Alcanza un multiplicador de 1000x';

  @override
  String get achMultiplier5000Name => 'Combo Divino';

  @override
  String get achMultiplier5000Desc => 'Alcanza un multiplicador de 5000x';

  @override
  String get achGeoms10000Name => 'Coleccionista';

  @override
  String get achGeoms10000Desc => 'Recoge 10.000 geoms en total';

  @override
  String get achGeoms100000Name => 'Avaro Geométrico';

  @override
  String get achGeoms100000Desc => 'Recoge 100.000 geoms en total';

  @override
  String get achWave20Name => 'Persistente';

  @override
  String get achWave20Desc => 'Alcanza la oleada 20';

  @override
  String get achWave50Name => 'Veterano';

  @override
  String get achWave50Desc => 'Alcanza la oleada 50';

  @override
  String get achWave100Name => 'Centenario';

  @override
  String get achWave100Desc => 'Alcanza la oleada 100';

  @override
  String get achWave200Name => 'Imparable';

  @override
  String get achWave200Desc => 'Alcanza la oleada 200 (Survival/Tunnel)';

  @override
  String get achPerfectWaves5Name => 'Intocable';

  @override
  String get achPerfectWaves5Desc => 'Completa 5 oleadas perfectas seguidas';

  @override
  String get achPerfectWaves10Name => 'Fantasma';

  @override
  String get achPerfectWaves10Desc => 'Completa 10 oleadas perfectas seguidas';

  @override
  String get achPerfectWaves20Name => 'Deidad';

  @override
  String get achPerfectWaves20Desc => 'Completa 20 oleadas perfectas seguidas';

  @override
  String get achClassicNormalName => 'Clasicista';

  @override
  String get achClassicNormalDesc => 'Completa Clásico en Normal';

  @override
  String get achClassicHardName => 'Duro de Matar';

  @override
  String get achClassicHardDesc => 'Completa Clásico en Difícil';

  @override
  String get achClassicNightmareName => 'Pesadilla Viviente';

  @override
  String get achClassicNightmareDesc => 'Completa Clásico en Pesadilla';

  @override
  String get achAllModesName => 'Todoterreno';

  @override
  String get achAllModesDesc => 'Juega en los 6 modos';

  @override
  String get achBossRush10Name => 'Cazador de Jefes';

  @override
  String get achBossRush10Desc => 'Alcanza el jefe 10 en Boss Rush';

  @override
  String get achGames10Name => 'Jugador';

  @override
  String get achGames10Desc => 'Juega 10 partidas';

  @override
  String get achGames100Name => 'Aficionado';

  @override
  String get achGames100Desc => 'Juega 100 partidas';

  @override
  String get achGames500Name => 'Adicto';

  @override
  String get achGames500Desc => 'Juega 500 partidas';

  @override
  String get achGold10000Name => 'Tío Gilito';

  @override
  String get achGold10000Desc => 'Acumula 10.000 Gold Geoms';

  @override
  String get achGold50000Name => 'Magnate';

  @override
  String get achGold50000Desc => 'Acumula 50.000 Gold Geoms';

  @override
  String get achAllUpgradesName => 'Al Máximo';

  @override
  String get achAllUpgradesDesc => 'Compra todas las mejoras';

  @override
  String get achPowerups100Name => 'Adicto a los Power-Ups';

  @override
  String get achPowerups100Desc => 'Recoge 100 power-ups';

  @override
  String get achWavesWave20Name => 'Esquivador';

  @override
  String get achWavesWave20Desc => 'Modo Waves: alcanza la oleada 20';

  @override
  String get achWavesWave50Name => 'Maestro del Esquive';

  @override
  String get achWavesWave50Desc => 'Modo Waves: alcanza la oleada 50';

  @override
  String get achGravityWave15Name => 'Astrofísico';

  @override
  String get achGravityWave15Desc => 'Gravity Inferno: alcanza la oleada 15';

  @override
  String get achPacifistCombo15Name => 'Pacifista Pro';

  @override
  String get achPacifistCombo15Desc => 'Pacifist: combo gate 15+';

  @override
  String get achTimeAttack500kName => 'Cronometrista';

  @override
  String get achTimeAttack500kDesc => 'Time Attack: 500k puntos';

  @override
  String get achDailyStreak7Name => 'Devoto Diario';

  @override
  String get achDailyStreak7Desc =>
      'Reclama la recompensa diaria 7 días seguidos';

  @override
  String get achDailyStreak30Name => 'Leal Mensual';

  @override
  String get achDailyStreak30Desc =>
      'Reclama la recompensa diaria 30 días seguidos';

  @override
  String get achGaussKills500Name => 'Maestro Gauss';

  @override
  String get achGaussKills500Desc => 'Mata 500 enemigos con Gauss Cannon';

  @override
  String get achChainKills500Name => 'Tormenta';

  @override
  String get achChainKills500Desc => 'Mata 500 enemigos con Chain Lightning';

  @override
  String get achAllWeaponsName => 'Armero';

  @override
  String get achAllWeaponsDesc => 'Desbloquea todas las armas';

  @override
  String get achAllSkinsName => 'Fashionista';

  @override
  String get achAllSkinsDesc => 'Desbloquea todas las skins';

  @override
  String get achAllTrailsName => 'Colección Cósmica';

  @override
  String get achAllTrailsDesc => 'Desbloquea todas las estelas';

  @override
  String get achAllPetsName => 'Domador';

  @override
  String get achAllPetsDesc => 'Desbloquea todas las mascotas';
}
