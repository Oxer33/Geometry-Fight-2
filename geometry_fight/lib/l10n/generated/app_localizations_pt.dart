// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get appTitle => 'Geometry Fight 2';

  @override
  String get menuPlay => 'JOGAR';

  @override
  String get menuShop => 'LOJA';

  @override
  String get menuStore => 'LOJA';

  @override
  String get menuSettings => 'AJUSTES';

  @override
  String get menuStats => 'ESTATÍSTICAS';

  @override
  String get menuAchievements => 'TROFÉUS';

  @override
  String get menuAchievementsAlt => 'CONQUISTAS';

  @override
  String get menuLeaderboard => 'CLASSIFICAÇÃO';

  @override
  String get menuQuit => 'SAIR';

  @override
  String get diffEasy => 'FÁCIL';

  @override
  String get diffNormal => 'NORMAL';

  @override
  String get diffHard => 'DIFÍCIL';

  @override
  String get diffNightmare => 'PESADELO';

  @override
  String get diffNext => 'PRÓXIMO';

  @override
  String get diffTitle => 'DIFICULDADE';

  @override
  String get diffScoreMultiplier => 'pontos';

  @override
  String get settingsTitle => 'AJUSTES';

  @override
  String get settingsAudio => 'ÁUDIO';

  @override
  String get settingsGameplay => 'JOGABILIDADE';

  @override
  String get settingsMusic => 'MÚSICA';

  @override
  String get settingsSfx => 'SFX';

  @override
  String get settingsSfxLong => 'EFEITOS SONOROS';

  @override
  String get settingsVibration => 'VIBRAÇÃO';

  @override
  String get settingsShowFps => 'MOSTRAR FPS';

  @override
  String get settingsLanguage => 'IDIOMA';

  @override
  String get settingsCrashLogs => 'REGISTROS DE FALHAS';

  @override
  String get settingsReset => 'RESETAR DADOS';

  @override
  String get settingsDangerZone => 'ZONA DE PERIGO';

  @override
  String get settingsTestDebug => 'TEST / DEBUG';

  @override
  String get settingsAddCredits => '+1000 CRÉDITOS';

  @override
  String get settingsResetPurchases => 'RESETAR COMPRAS';

  @override
  String get settingsPurchasesReset => 'Compras resetadas!';

  @override
  String settingsCreditsAdded(int total) {
    return '+1000 créditos! Total: $total';
  }

  @override
  String settingsCrashLogsTitle(int count) {
    return 'FALHAS ($count)';
  }

  @override
  String get settingsNoCrash =>
      'Nenhuma falha registrada.\nSe o jogo travar, aparecerá aqui.';

  @override
  String get settingsCopy => 'COPIAR';

  @override
  String get settingsDelete => 'APAGAR';

  @override
  String get settingsLogsCopied => 'Registros copiados';

  @override
  String get shopTitle => 'LOJA';

  @override
  String get shopGoldInsufficient => 'Ouro insuficiente!';

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
  String get shopTabSkins => 'SKINS';

  @override
  String get shopTabTrails => 'RASTROS';

  @override
  String get shopTabPets => 'MASCOTES';

  @override
  String get shopTabUpgrades => 'MELHORIAS';

  @override
  String get shopTabModes => 'MODOS';

  @override
  String get shopPurchased => 'Comprado!';

  @override
  String get shopLocked => 'BLOQUEADO';

  @override
  String get shopCost => 'CUSTO';

  @override
  String get shopLevel => 'NÍVEL';

  @override
  String get shopScrollMore => 'Role para mais';

  @override
  String get loadoutTitle => 'EQUIPAMENTO';

  @override
  String get loadoutWeapon => 'ARMA';

  @override
  String get loadoutPet => 'MASCOTE';

  @override
  String get loadoutLocked => 'Desbloqueie esta arma na LOJA';

  @override
  String get loadoutPetLocked => 'Desbloqueie este mascote na LOJA';

  @override
  String get loadoutStart => 'INICIAR PARTIDA';

  @override
  String get loadoutPetNone => 'NENHUM';

  @override
  String shopAlreadyMax(String name) {
    return '$name já está no máximo!';
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
  String get shopBadgeNew => 'NOVO';

  @override
  String get shopBadgeUnlocked => 'DESBLOQUEADO';

  @override
  String shopBuyWithCost(int cost) {
    return 'COMPRAR ${cost}g';
  }

  @override
  String get shopTapNodeForDetails => 'TOQUE NUM NÓ PARA VER DETALHES';

  @override
  String get modeTitle => 'MODO';

  @override
  String get modeSelectTitle => 'SELECIONAR MODO';

  @override
  String get modeEndless => 'INFINITO';

  @override
  String get modeBossRush => 'BOSS RUSH';

  @override
  String get modeSurvival => 'SOBREVIVÊNCIA';

  @override
  String get modeChallenge => 'DESAFIO';

  @override
  String get modeClassic => 'CLÁSSICO';

  @override
  String get modePacifist => 'PACIFISTA';

  @override
  String get modeTimeAttack => 'CONTRA O TEMPO';

  @override
  String get modeZen => 'ZEN';

  @override
  String get modeTunnel => 'TÚNEL';

  @override
  String get modeDailyChallenge => 'DESAFIO DIÁRIO';

  @override
  String get modeWaves => 'ONDAS';

  @override
  String get modeGravityInferno => 'INFERNO GRAVITACIONAL';

  @override
  String get splashSkip => 'PULAR';

  @override
  String get splashTapToStart => 'TOQUE PARA COMEÇAR';

  @override
  String get modifiersTitle => 'MODIFICADORES';

  @override
  String get modifiersConfirm => 'CONFIRMAR';

  @override
  String get back => 'VOLTAR';

  @override
  String get play => 'JOGAR';

  @override
  String get pause => 'PAUSA';

  @override
  String get resume => 'RETOMAR';

  @override
  String get restart => 'REINICIAR';

  @override
  String get retry => 'TENTAR DE NOVO';

  @override
  String get quit => 'SAIR';

  @override
  String get close => 'FECHAR';

  @override
  String get next => 'PRÓXIMO';

  @override
  String get start => 'INICIAR';

  @override
  String get yes => 'SIM';

  @override
  String get no => 'NÃO';

  @override
  String get confirm => 'CONFIRMAR';

  @override
  String get cancel => 'CANCELAR';

  @override
  String get continueAction => 'CONTINUAR';

  @override
  String get score => 'PONTOS';

  @override
  String get wave => 'ONDA';

  @override
  String get lives => 'VIDAS';

  @override
  String get level => 'NÍVEL';

  @override
  String get gold => 'OURO';

  @override
  String get geoms => 'GEOMS';

  @override
  String get best => 'MELHOR';

  @override
  String get kills => 'ABATES';

  @override
  String get timeLabel => 'TEMPO';

  @override
  String get highScore => 'RECORDE';

  @override
  String get newRun => 'NOVA PARTIDA';

  @override
  String get gameOver => 'FIM DE JOGO';

  @override
  String get newRecord => 'NOVO RECORDE!';

  @override
  String get victory => 'VITÓRIA';

  @override
  String get achievementsTitle => 'TROFÉUS';

  @override
  String get achievementUnlocked => 'Troféu Desbloqueado!';

  @override
  String get achievementCategoryCombat => 'COMBATE';

  @override
  String get achievementCategoryScore => 'PONTOS';

  @override
  String get achievementCategoryProgress => 'PROGRESSO';

  @override
  String get achievementCategoryMastery => 'MAESTRIA';

  @override
  String get achievementCategorySpecial => 'ESPECIAL';

  @override
  String get leaderboardTitle => 'CLASSIFICAÇÃO';

  @override
  String get leaderboardEmpty => 'Sem pontuações ainda';

  @override
  String get statsTitle => 'ESTATÍSTICAS';

  @override
  String get summaryTitle => 'RESUMO';

  @override
  String get dailyRewardTitle => 'RECOMPENSA DIÁRIA';

  @override
  String dailyRewardGeoms(int amount) {
    return '+$amount GEOM';
  }

  @override
  String dailyRewardStreakOne(int count) {
    return 'Sequência: $count dia';
  }

  @override
  String dailyRewardStreakMany(int count) {
    return 'Sequência: $count dias';
  }

  @override
  String get settingsResetTitle => 'REINICIAR DADOS';

  @override
  String get settingsResetWarning =>
      'Todo o progresso, melhorias e compras serão apagados.';

  @override
  String get settingsResetButton => 'RESET';

  @override
  String get settingsResetAllData => 'REINICIAR TODOS OS DADOS';

  @override
  String get badgeKiller => 'ASSASSINO';

  @override
  String get badgeMassacre => 'MASSACRE';

  @override
  String get badgePersistent => 'PERSISTENTE';

  @override
  String get badgeVeteran => 'VETERANO';

  @override
  String get badgeBossHunter => 'CAÇADOR DE CHEFES';

  @override
  String get badgeRegicide => 'REGICIDA';

  @override
  String get newAchievementBanner => '★ NOVA CONQUISTA! ★';

  @override
  String get columnDate => 'DATA';

  @override
  String leaderboardRecords(int count) {
    return '$count REC';
  }

  @override
  String get leaderboardNoRecord => 'SEM RECORDES';

  @override
  String get leaderboardEmptyHint =>
      'Jogue neste modo\npara entrar na classificação!';

  @override
  String get statsSectionGeneral => 'GERAL';

  @override
  String get statsSectionCombat => 'COMBATE';

  @override
  String get statsSectionRecords => 'RECORDES';

  @override
  String get statsSectionAchievements => 'CONQUISTAS';

  @override
  String get statsSectionScoresByMode => 'PONTUAÇÕES POR MODO';

  @override
  String get statsGamesPlayed => 'Partidas jogadas';

  @override
  String get statsTotalPlaytime => 'Tempo total';

  @override
  String get statsTotalGoldEarned => 'Ouro total ganho';

  @override
  String get statsCurrentGold => 'Ouro atual';

  @override
  String get statsEnemiesKilled => 'Inimigos eliminados';

  @override
  String get statsBossesDefeated => 'Chefes derrotados';

  @override
  String get statsBombsUsed => 'Bombas usadas';

  @override
  String get statsPowerUpsCollected => 'Power-ups coletados';

  @override
  String get statsGeomsCollected => 'Geoms coletados';

  @override
  String get statsBestScore => 'Melhor pontuação';

  @override
  String get statsHighestWave => 'Onda mais alta';

  @override
  String get statsMaxMultiplier => 'Multiplicador máximo';

  @override
  String get statsMaxSessionKills => 'Máx. kills em partida';

  @override
  String get statsMaxPerfectStreak => 'Máx. ondas perfeitas';

  @override
  String get statsAchievementsUnlocked => 'Desbloqueadas';

  @override
  String get summaryNone => 'Nenhum';

  @override
  String get summaryScoreMultiplierTitle => 'MULTIPLICADOR DE PONTUAÇÃO';

  @override
  String get summaryDifficultyRow => 'Dificuldade';

  @override
  String get summaryModifiersRow => 'Modificadores';

  @override
  String get summaryTotal => 'TOTAL';

  @override
  String summaryActiveModifiers(int count, String mult) {
    return '$count ativos · ×$mult score';
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
    return 'Ativos: $count/$max';
  }

  @override
  String hudBossWave(int wave) {
    return 'BOSS ONDA $wave';
  }

  @override
  String hudWaveNumber(int wave) {
    return 'ONDA $wave';
  }

  @override
  String get hudPerfectWave => 'ONDA PERFEITA!';

  @override
  String get hudPerfectBonus => '+10 GEOMS BÔNUS';

  @override
  String hudEnemiesRemaining(int count) {
    return '$count INIMIGOS';
  }

  @override
  String get hudBoost2x => '2x BOOST';

  @override
  String get powerUpRapidFire => 'TIRO RÁPIDO';

  @override
  String get powerUpOverdrive => 'OVERDRIVE';

  @override
  String get powerUpMagnet => 'ÍMÃ';

  @override
  String get powerUpTimeSlow => 'TEMPO LENTO';

  @override
  String get powerUpSpreadShot => 'TIRO MÚLTIPLO';

  @override
  String get powerUpFirePower => 'PODER DE FOGO';

  @override
  String get tutorialTitle => 'COMO JOGAR';

  @override
  String get tutorialLeftJoystick => 'JOYSTICK ESQUERDO';

  @override
  String get tutorialLeftJoystickDesc => 'Move a nave';

  @override
  String get tutorialRightJoystick => 'JOYSTICK DIREITO';

  @override
  String get tutorialRightJoystickDesc => 'Mira e atira automaticamente';

  @override
  String get tutorialBomb => 'BOMBA';

  @override
  String get tutorialBombDesc => 'Destrói todos os inimigos próximos';

  @override
  String get tutorialGeoms => 'GEOMS';

  @override
  String get tutorialGeomsDesc => 'Colete para pontos e upgrades';

  @override
  String get tutorialPowerUp => 'POWER-UP';

  @override
  String get tutorialPowerUpDesc => 'Melhorias temporárias';

  @override
  String get tutorialTapToStart => 'TOQUE PARA COMEÇAR';

  @override
  String get skinNameClassic => 'Classic';

  @override
  String get skinDescClassic => 'A nave original ciano';

  @override
  String get skinNameStealth => 'Stealth';

  @override
  String get skinDescStealth => 'Preta com bordas vermelhas — estilo furtivo';

  @override
  String get skinNameCrystal => 'Crystal';

  @override
  String get skinDescCrystal => 'Diamante prismático — reflexos arco-íris';

  @override
  String get skinNameGhost => 'Ghost';

  @override
  String get skinDescGhost => 'Semitransparente com rastro de partículas';

  @override
  String get skinNameOmega => 'Omega';

  @override
  String get skinDescOmega => 'Estrela dourada de 4 pontas — forma única';

  @override
  String get skinNamePhoenix => 'Phoenix';

  @override
  String get skinDescPhoenix =>
      'Asas de fogo com penas de brasa — renasce das cinzas';

  @override
  String get skinNameCyber => 'Cyber';

  @override
  String get skinDescCyber =>
      'Malha de circuitos verde néon — overlay digital animado';

  @override
  String get skinNameVoidwalker => 'Voidwalker';

  @override
  String get skinDescVoidwalker =>
      'Núcleo violeta suspenso no vazio — halo etéreo';

  @override
  String get skinNameAurora => 'Aurora';

  @override
  String get skinDescAurora => 'Boreal: ciano/rosa/verde fluindo';

  @override
  String get skinNameTactical => 'Tactical';

  @override
  String get skinDescTactical =>
      'Armadura militar cinza/azul — placas blindadas';

  @override
  String get skinNamePrism => 'Prism';

  @override
  String get skinDescPrism => 'Cristal poligonal — refração multi-arco-íris';

  @override
  String get skinNameTron => 'Tron';

  @override
  String get skinDescTron =>
      'Corpo preto com linhas ciano néon — grade digital';

  @override
  String get skinNameSamurai => 'Samurai';

  @override
  String get skinDescSamurai =>
      'Armadura preta com detalhes ouro/vermelho — honra e batalha';

  @override
  String get skinNameRosegold => 'RoseGold';

  @override
  String get skinDescRosegold => 'Rosa-dourado metálico — elegância moderna';

  @override
  String get skinNameNinja => 'Ninja';

  @override
  String get skinDescNinja =>
      'Cinza sombra com toques shuriken — silencioso e letal';

  @override
  String get skinNameGlitch => 'Glitch';

  @override
  String get skinDescGlitch => 'Mudança cromática RGB — aberração animada';

  @override
  String get trailNameNormal => 'Normal';

  @override
  String get trailDescNormal => 'Rastro ciano padrão';

  @override
  String get trailNameFire => 'Fire';

  @override
  String get trailDescFire => 'Partículas de fogo atrás da nave';

  @override
  String get trailNameIce => 'Ice';

  @override
  String get trailDescIce => 'Cristais de gelo brilhantes';

  @override
  String get trailNamePlasma => 'Plasma';

  @override
  String get trailDescPlasma => 'Energia plasma roxa pulsante';

  @override
  String get trailNameRainbow => 'Rainbow';

  @override
  String get trailDescRainbow => 'Cores mudando continuamente';

  @override
  String get trailNameComet => 'Comet';

  @override
  String get trailDescComet =>
      'Cabeça brilhante com cauda que se apaga lentamente';

  @override
  String get trailNameInferno => 'Inferno';

  @override
  String get trailDescInferno => 'Fogo multicamada com brasas saltando';

  @override
  String get trailNameVoid => 'Void';

  @override
  String get trailDescVoid => 'Vórtice escuro sugando partículas violetas';

  @override
  String get trailNameQuantum => 'Quantum';

  @override
  String get trailDescQuantum =>
      'Partículas acopladas em superposição cromática';

  @override
  String get trailNameGalaxy => 'Galaxy';

  @override
  String get trailDescGalaxy => 'Estrelas em espiral com poeira cósmica';

  @override
  String get trailNameLightning => 'Lightning';

  @override
  String get trailDescLightning =>
      'Arcos elétricos em zigzag entre pontos do rastro';

  @override
  String get trailNameNebula => 'Nebula';

  @override
  String get trailDescNebula => 'Nuvem espacial ciano/magenta pulsante';

  @override
  String get trailNamePrism => 'Prism';

  @override
  String get trailDescPrism => 'Espectro completo fluindo pelo rastro';

  @override
  String get trailNameHologram => 'Hologram';

  @override
  String get trailDescHologram => 'Aberração cromática RGB estilo glitch';

  @override
  String get trailNameBiolume => 'Biolumin';

  @override
  String get trailDescBiolume => 'Bioluminescência aquática verde/ciano';

  @override
  String get trailNameNeonpulse => 'NeonPulse';

  @override
  String get trailDescNeonpulse => 'Anéis néon branco-ciano expandindo';

  @override
  String get weaponNameBasic => 'Basic Gun';

  @override
  String get weaponDescBasic =>
      'Dupla fileira de balas amarelas paralelas — confiável e precisa.';

  @override
  String get weaponNameTriple => 'Triple Shot';

  @override
  String get weaponDescTriple => '3 balas brancas próximas — fogo concentrado.';

  @override
  String get weaponNameSpread => 'Spread Shot';

  @override
  String get weaponDescSpread =>
      '5 balas laranjas em leque estreito — ótimo vs grupos.';

  @override
  String get weaponNameRicochet => 'Ricochet';

  @override
  String get weaponDescRicochet =>
      'Leque de 3 tiros verdes de alto dano que ricocheteiam 2 vezes nas paredes.';

  @override
  String get weaponNameHoming => 'Homing';

  @override
  String get weaponDescHoming =>
      '5 mísseis perseguindo alvos distintos — explodem nas paredes.';

  @override
  String get weaponNamePlasma => 'Plasma';

  @override
  String get weaponDescPlasma =>
      'Orbe violeta lento com AoE explosiva — devasta chefes e grupos.';

  @override
  String get weaponNameLaser => 'Laser';

  @override
  String get weaponDescLaser =>
      'Feixe vermelho contínuo — corta tudo que toca.';

  @override
  String get weaponNameGauss => 'Gauss Cannon';

  @override
  String get weaponDescGauss =>
      'Tiro violeta com sucção gravitacional 1s — agrupa inimigos para atingir todos.';

  @override
  String get weaponNameChain => 'Chain Lightning';

  @override
  String get weaponDescChain =>
      'Raio elétrico ricocheteia entre 5 inimigos — perfeito vs grupos.';

  @override
  String get modeDescClassic => '100 ondas com chefe a cada 10 — o modo padrão';

  @override
  String get modeDescBossRush => 'Só chefes, um após o outro — sem mobs';

  @override
  String get modeDescSurvival =>
      'Ondas infinitas cada vez mais difíceis — quanto você aguenta?';

  @override
  String get modeDescTimeAttack =>
      '3 minutos: faça o máximo de pontos antes do tempo acabar';

  @override
  String get modeDescZenMode =>
      'Vidas infinitas — jogue sem estresse, explore tudo';

  @override
  String get modeDescTunnel => 'Rolagem lateral em um túnel infinito';

  @override
  String get modeDescPacifist =>
      'Sem tiros! Sobreviva com os Gates (GW Pacifism)';

  @override
  String get modeDescWaves =>
      'Só triângulos vermelhos cardinais. Raros buracos negros. Esquiva pura.';

  @override
  String get modeDescGravityInferno =>
      'Muitos buracos negros + poucos mobs mistos. Sem chefes. Caos gravitacional.';

  @override
  String get upgradeFirepower => 'PODER';

  @override
  String get upgradeFirepowerDesc => '+5% dano por nível (máx +25%)';

  @override
  String get upgradeFireRate => 'CADÊNCIA';

  @override
  String get upgradeFireRateDesc => '+5% cadência por nível (máx +25%)';

  @override
  String get upgradeSpeed => 'VELOCIDADE';

  @override
  String get upgradeSpeedDesc => '+5% velocidade por nível (máx +25%)';

  @override
  String get upgradeShield => 'ESCUDO';

  @override
  String get upgradeShieldDesc =>
      'Escudo pós-morte: 5s → 10s → 15s → 20s → 25s';

  @override
  String get upgradeLives => 'VIDAS';

  @override
  String get upgradeLivesDesc => 'Vidas iniciais: 3 → 4 → 5';

  @override
  String get upgradeBombs => 'RAIO BOMBA';

  @override
  String get upgradeBombsDesc =>
      '+raio de explosão por nível (L0 meia arena, L10 arena inteira)';

  @override
  String get upgradeMagnet => 'ÍMÃ';

  @override
  String get upgradeMagnetDesc => '+10px de alcance ímã por nível (máx +50px)';

  @override
  String get upgradeXpBoost => 'BÔNUS XP';

  @override
  String get upgradeXpBoostDesc => '+10% GoldGeom por nível (máx +50%)';
}
