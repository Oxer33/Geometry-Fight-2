// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'Geometry Fight 2';

  @override
  String get menuPlay => '开始游戏';

  @override
  String get menuShop => '商店';

  @override
  String get menuStore => '商店';

  @override
  String get menuSettings => '设置';

  @override
  String get menuStats => '统计';

  @override
  String get menuAchievements => '奖杯';

  @override
  String get menuAchievementsAlt => '成就';

  @override
  String get menuLeaderboard => '排行榜';

  @override
  String get menuQuit => '退出';

  @override
  String get diffEasy => '简单';

  @override
  String get diffNormal => '普通';

  @override
  String get diffHard => '困难';

  @override
  String get diffNightmare => '噩梦';

  @override
  String get diffNext => '下一步';

  @override
  String get diffTitle => '难度';

  @override
  String get diffScoreMultiplier => '得分';

  @override
  String get settingsTitle => '设置';

  @override
  String get settingsAudio => '音频';

  @override
  String get settingsGameplay => '玩法';

  @override
  String get settingsMusic => '音乐';

  @override
  String get settingsSfx => '音效';

  @override
  String get settingsSfxLong => '音效';

  @override
  String get settingsVibration => '震动';

  @override
  String get settingsShowFps => '显示 FPS';

  @override
  String get settingsLanguage => '语言';

  @override
  String get settingsCrashLogs => '崩溃日志';

  @override
  String get settingsReset => '重置数据';

  @override
  String get settingsDangerZone => '危险区';

  @override
  String get settingsTestDebug => '测试 / 调试';

  @override
  String get settingsAddCredits => '+1000 点数';

  @override
  String get settingsResetPurchases => '重置购买';

  @override
  String get settingsPurchasesReset => '购买已重置!';

  @override
  String settingsCreditsAdded(int total) {
    return '+1000 点数!总计:$total';
  }

  @override
  String settingsCrashLogsTitle(int count) {
    return '崩溃 ($count)';
  }

  @override
  String get settingsNoCrash => '没有崩溃记录。\n如果游戏崩溃,将显示在这里。';

  @override
  String get settingsCopy => '复制';

  @override
  String get settingsDelete => '删除';

  @override
  String get settingsLogsCopied => '日志已复制';

  @override
  String get shopTitle => '商店';

  @override
  String get shopGoldInsufficient => '金币不足!';

  @override
  String get shopEquip => '装备';

  @override
  String get shopEquipped => '已装备';

  @override
  String get shopBuy => '购买';

  @override
  String get shopMaxLevel => 'MAX';

  @override
  String get shopTabWeapons => '武器';

  @override
  String get shopTabSkins => '皮肤';

  @override
  String get shopTabTrails => '尾迹';

  @override
  String get shopTabPets => '宠物';

  @override
  String get shopTabUpgrades => '升级';

  @override
  String get shopTabModes => '模式';

  @override
  String get shopPurchased => '已购买!';

  @override
  String get shopLocked => '已锁定';

  @override
  String get shopCost => '价格';

  @override
  String get shopLevel => '等级';

  @override
  String get shopScrollMore => '滚动查看更多';

  @override
  String get loadoutTitle => '装备';

  @override
  String get loadoutWeapon => '武器';

  @override
  String get loadoutPet => '宠物';

  @override
  String get loadoutLocked => '在商店解锁此武器';

  @override
  String get loadoutPetLocked => '在商店解锁此宠物';

  @override
  String get loadoutStart => '开始游戏';

  @override
  String get loadoutPetNone => '无';

  @override
  String shopAlreadyMax(String name) {
    return '$name 已满级！';
  }

  @override
  String shopUpgradedToLevel(String name, int level) {
    return '$name 等级 $level';
  }

  @override
  String shopLevelOf(int current, int max) {
    return '等级 $current / $max';
  }

  @override
  String get shopBadgeNew => '新';

  @override
  String get shopBadgeUnlocked => '已解锁';

  @override
  String shopBuyWithCost(int cost) {
    return '购买 ${cost}g';
  }

  @override
  String get shopTapNodeForDetails => '点击节点查看详情';

  @override
  String get modeTitle => '模式';

  @override
  String get modeSelectTitle => '选择模式';

  @override
  String get modeEndless => '无尽';

  @override
  String get modeBossRush => 'BOSS 冲刺';

  @override
  String get modeSurvival => '生存';

  @override
  String get modeChallenge => '挑战';

  @override
  String get modeClassic => '经典';

  @override
  String get modePacifist => '和平主义';

  @override
  String get modeTimeAttack => '限时挑战';

  @override
  String get modeZen => '禅意';

  @override
  String get modeTunnel => '隧道';

  @override
  String get modeDailyChallenge => '每日挑战';

  @override
  String get modeWaves => '波次';

  @override
  String get modeGravityInferno => '引力炼狱';

  @override
  String get splashSkip => '跳过';

  @override
  String get splashTapToStart => '点击开始';

  @override
  String get modifiersTitle => '修饰符';

  @override
  String get modifiersConfirm => '确认';

  @override
  String get back => '返回';

  @override
  String get play => '开始';

  @override
  String get pause => '暂停';

  @override
  String get resume => '继续';

  @override
  String get restart => '重新开始';

  @override
  String get retry => '重试';

  @override
  String get quit => '退出';

  @override
  String get close => '关闭';

  @override
  String get next => '下一步';

  @override
  String get start => '开始';

  @override
  String get yes => '是';

  @override
  String get no => '否';

  @override
  String get confirm => '确认';

  @override
  String get cancel => '取消';

  @override
  String get continueAction => '继续';

  @override
  String get score => '得分';

  @override
  String get wave => '波次';

  @override
  String get lives => '生命';

  @override
  String get level => '等级';

  @override
  String get gold => '金币';

  @override
  String get geoms => 'GEOMS';

  @override
  String get best => '最佳';

  @override
  String get kills => '击杀';

  @override
  String get timeLabel => '时间';

  @override
  String get highScore => '最高分';

  @override
  String get newRun => '新一轮';

  @override
  String get gameOver => '游戏结束';

  @override
  String get newRecord => '新纪录!';

  @override
  String get victory => '胜利';

  @override
  String get achievementsTitle => '奖杯';

  @override
  String get achievementUnlocked => '奖杯解锁!';

  @override
  String get achievementCategoryCombat => '战斗';

  @override
  String get achievementCategoryScore => '得分';

  @override
  String get achievementCategoryProgress => '进度';

  @override
  String get achievementCategoryMastery => '精通';

  @override
  String get achievementCategorySpecial => '特别';

  @override
  String get leaderboardTitle => '排行榜';

  @override
  String get leaderboardEmpty => '暂无成绩';

  @override
  String get statsTitle => '统计';

  @override
  String get summaryTitle => '总结';

  @override
  String get dailyRewardTitle => '每日奖励';

  @override
  String dailyRewardGeoms(int amount) {
    return '+$amount GEOM';
  }

  @override
  String dailyRewardStreakOne(int count) {
    return '连续:$count 天';
  }

  @override
  String dailyRewardStreakMany(int count) {
    return '连续:$count 天';
  }

  @override
  String get settingsResetTitle => '重置数据';

  @override
  String get settingsResetWarning => '所有进度、升级和购买将被清除。';

  @override
  String get settingsResetButton => '重置';

  @override
  String get settingsResetAllData => '重置所有数据';

  @override
  String get badgeKiller => '杀手';

  @override
  String get badgeMassacre => '大屠杀';

  @override
  String get badgePersistent => '坚持者';

  @override
  String get badgeVeteran => '老兵';

  @override
  String get badgeBossHunter => 'BOSS猎手';

  @override
  String get badgeRegicide => '弑君者';

  @override
  String get newAchievementBanner => '★ 新成就! ★';

  @override
  String get columnDate => '日期';

  @override
  String leaderboardRecords(int count) {
    return '$count 记录';
  }

  @override
  String get leaderboardNoRecord => '暂无记录';

  @override
  String get leaderboardEmptyHint => '在此模式下游玩\n以进入排行榜！';

  @override
  String get statsSectionGeneral => '综合';

  @override
  String get statsSectionCombat => '战斗';

  @override
  String get statsSectionRecords => '记录';

  @override
  String get statsSectionAchievements => '成就';

  @override
  String get statsSectionScoresByMode => '各模式得分';

  @override
  String get statsGamesPlayed => '游戏场数';

  @override
  String get statsTotalPlaytime => '总游戏时间';

  @override
  String get statsTotalGoldEarned => '累计金币';

  @override
  String get statsCurrentGold => '当前金币';

  @override
  String get statsEnemiesKilled => '击杀敌人';

  @override
  String get statsBossesDefeated => '击败BOSS';

  @override
  String get statsBombsUsed => '使用炸弹';

  @override
  String get statsPowerUpsCollected => '收集道具';

  @override
  String get statsGeomsCollected => '收集Geom';

  @override
  String get statsBestScore => '最高得分';

  @override
  String get statsHighestWave => '最高波次';

  @override
  String get statsMaxMultiplier => '最大倍率';

  @override
  String get statsMaxSessionKills => '单局最多击杀';

  @override
  String get statsMaxPerfectStreak => '最长完美波次';

  @override
  String get statsAchievementsUnlocked => '已解锁';

  @override
  String get summaryNone => '无';

  @override
  String get summaryScoreMultiplierTitle => '得分倍率';

  @override
  String get summaryDifficultyRow => '难度';

  @override
  String get summaryModifiersRow => '修改器';

  @override
  String get summaryTotal => '总计';

  @override
  String summaryActiveModifiers(int count, String mult) {
    return '$count 个激活 · ×$mult score';
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
    return '最多 $count 个修饰符';
  }

  @override
  String modifiersScoreLabel(String mult) {
    return '分数 x$mult';
  }

  @override
  String modifiersActiveCount(int count, int max) {
    return '已启用: $count/$max';
  }

  @override
  String hudBossWave(int wave) {
    return 'BOSS 第 $wave 波';
  }

  @override
  String hudWaveNumber(int wave) {
    return '第 $wave 波';
  }

  @override
  String get hudPerfectWave => '完美一波！';

  @override
  String get hudPerfectBonus => '+10 GEOMS 奖励';

  @override
  String hudEnemiesRemaining(int count) {
    return '$count 个敌人';
  }

  @override
  String get hudBoost2x => '2x 加成';

  @override
  String get powerUpRapidFire => '快速射击';

  @override
  String get powerUpOverdrive => '超载';

  @override
  String get powerUpMagnet => '磁铁';

  @override
  String get powerUpTimeSlow => '时间减缓';

  @override
  String get powerUpSpreadShot => '散射';

  @override
  String get powerUpFirePower => '火力';

  @override
  String get tutorialTitle => '如何游玩';

  @override
  String get tutorialLeftJoystick => '左摇杆';

  @override
  String get tutorialLeftJoystickDesc => '移动飞船';

  @override
  String get tutorialRightJoystick => '右摇杆';

  @override
  String get tutorialRightJoystickDesc => '瞄准并自动射击';

  @override
  String get tutorialBomb => '炸弹';

  @override
  String get tutorialBombDesc => '摧毁附近所有敌人';

  @override
  String get tutorialGeoms => 'GEOMS';

  @override
  String get tutorialGeomsDesc => '收集以获得积分和升级';

  @override
  String get tutorialPowerUp => '强化道具';

  @override
  String get tutorialPowerUpDesc => '临时加成';

  @override
  String get tutorialTapToStart => '点击开始';

  @override
  String get skinNameClassic => 'Classic';

  @override
  String get skinDescClassic => '原版青色飞船';

  @override
  String get skinNameStealth => 'Stealth';

  @override
  String get skinDescStealth => '黑色红边——隐秘风格';

  @override
  String get skinNameCrystal => 'Crystal';

  @override
  String get skinDescCrystal => '棱镜钻石——彩虹反射';

  @override
  String get skinNameGhost => 'Ghost';

  @override
  String get skinDescGhost => '半透明带粒子尾迹';

  @override
  String get skinNameOmega => 'Omega';

  @override
  String get skinDescOmega => '金色四角星——独特形状';

  @override
  String get skinNamePhoenix => 'Phoenix';

  @override
  String get skinDescPhoenix => '火翼带余烬羽毛——浴火重生';

  @override
  String get skinNameCyber => 'Cyber';

  @override
  String get skinDescCyber => '霓虹绿电路网格——动态数字覆层';

  @override
  String get skinNameVoidwalker => 'Voidwalker';

  @override
  String get skinDescVoidwalker => '紫色核心悬于虚空——飘渺光环';

  @override
  String get skinNameAurora => 'Aurora';

  @override
  String get skinDescAurora => '北极光:青/粉/绿流动';

  @override
  String get skinNameTactical => 'Tactical';

  @override
  String get skinDescTactical => '灰蓝军用装甲——装甲板';

  @override
  String get skinNamePrism => 'Prism';

  @override
  String get skinDescPrism => '多边形水晶——多重彩虹折射';

  @override
  String get skinNameTron => 'Tron';

  @override
  String get skinDescTron => '黑色机身配霓虹青线——数字电路网格';

  @override
  String get skinNameSamurai => 'Samurai';

  @override
  String get skinDescSamurai => '黑色铠甲配金红细节——荣耀与战斗';

  @override
  String get skinNameRosegold => 'RoseGold';

  @override
  String get skinDescRosegold => '金属玫瑰金——现代优雅';

  @override
  String get skinNameNinja => 'Ninja';

  @override
  String get skinDescNinja => '暗影灰带手里剑装饰——无声致命';

  @override
  String get skinNameGlitch => 'Glitch';

  @override
  String get skinDescGlitch => 'RGB色移——动态色差';

  @override
  String get trailNameNormal => 'Normal';

  @override
  String get trailDescNormal => '标准青色尾迹';

  @override
  String get trailNameFire => 'Fire';

  @override
  String get trailDescFire => '飞船后的火焰粒子';

  @override
  String get trailNameIce => 'Ice';

  @override
  String get trailDescIce => '闪烁的冰晶';

  @override
  String get trailNamePlasma => 'Plasma';

  @override
  String get trailDescPlasma => '脉动紫色等离子能量';

  @override
  String get trailNameRainbow => 'Rainbow';

  @override
  String get trailDescRainbow => '持续变色';

  @override
  String get trailNameComet => 'Comet';

  @override
  String get trailDescComet => '明亮的头部带缓慢消逝的尾巴';

  @override
  String get trailNameInferno => 'Inferno';

  @override
  String get trailDescInferno => '多层火焰带飞溅余烬';

  @override
  String get trailNameVoid => 'Void';

  @override
  String get trailDescVoid => '黑暗漩涡吸入紫色粒子';

  @override
  String get trailNameQuantum => 'Quantum';

  @override
  String get trailDescQuantum => '成对粒子的色叠加';

  @override
  String get trailNameGalaxy => 'Galaxy';

  @override
  String get trailDescGalaxy => '螺旋星辰带宇宙尘埃';

  @override
  String get trailNameLightning => 'Lightning';

  @override
  String get trailDescLightning => '尾迹点之间的Z字形电弧';

  @override
  String get trailNameNebula => 'Nebula';

  @override
  String get trailDescNebula => '脉动青/品红色太空云';

  @override
  String get trailNamePrism => 'Prism';

  @override
  String get trailDescPrism => '完整光谱沿尾迹流动';

  @override
  String get trailNameHologram => 'Hologram';

  @override
  String get trailDescHologram => 'RGB色差故障风格';

  @override
  String get trailNameBiolume => 'Biolumin';

  @override
  String get trailDescBiolume => '水生生物发光 绿/青';

  @override
  String get trailNameNeonpulse => 'NeonPulse';

  @override
  String get trailDescNeonpulse => '扩张的白青色霓虹环';

  @override
  String get weaponNameBasic => 'Basic Gun';

  @override
  String get weaponDescBasic => '双排平行黄色子弹——可靠精确。';

  @override
  String get weaponNameTriple => 'Triple Shot';

  @override
  String get weaponDescTriple => '3发紧密白色子弹——集中火力。';

  @override
  String get weaponNameSpread => 'Spread Shot';

  @override
  String get weaponDescSpread => '5发橙色子弹紧密扇形——克制群敌。';

  @override
  String get weaponNameRicochet => 'Ricochet';

  @override
  String get weaponDescRicochet => '3发高伤害绿色扇形射击,可弹墙2次。';

  @override
  String get weaponNameHoming => 'Homing';

  @override
  String get weaponDescHoming => '5枚导弹追踪不同目标——撞墙爆炸。';

  @override
  String get weaponNamePlasma => 'Plasma';

  @override
  String get weaponDescPlasma => '缓慢紫色球带爆炸AoE——重创Boss和群敌。';

  @override
  String get weaponNameLaser => 'Laser';

  @override
  String get weaponDescLaser => '连续红色光束——切断一切。';

  @override
  String get weaponNameGauss => 'Gauss Cannon';

  @override
  String get weaponDescGauss => '紫色射击带1秒引力吸引——聚集敌人一击全中。';

  @override
  String get weaponNameChain => 'Chain Lightning';

  @override
  String get weaponDescChain => '电闪在5个敌人间弹跳——完美克制群敌。';

  @override
  String get modeDescClassic => '100波每10波一个Boss——标准模式';

  @override
  String get modeDescBossRush => '仅Boss,一个接一个——无小怪';

  @override
  String get modeDescSurvival => '无尽波次越来越难——你能撑多久?';

  @override
  String get modeDescTimeAttack => '3分钟:在时间结束前尽可能得分';

  @override
  String get modeDescZenMode => '无限生命——无压力游玩,探索一切';

  @override
  String get modeDescTunnel => '无尽隧道侧向滚动';

  @override
  String get modeDescPacifist => '禁止射击!用Gate生存(GW Pacifism)';

  @override
  String get modeDescWaves => '仅基本红色三角形。罕见黑洞。纯闪避。';

  @override
  String get modeDescGravityInferno => '众多黑洞+少量混合小怪。无Boss。引力混乱。';

  @override
  String get upgradeFirepower => '火力';

  @override
  String get upgradeFirepowerDesc => '每级+5%伤害(最大+25%)';

  @override
  String get upgradeFireRate => '射速';

  @override
  String get upgradeFireRateDesc => '每级+5%射速(最大+25%)';

  @override
  String get upgradeSpeed => '速度';

  @override
  String get upgradeSpeedDesc => '每级+5%速度(最大+25%)';

  @override
  String get upgradeShield => '护盾';

  @override
  String get upgradeShieldDesc => '死后护盾:5秒→10秒→15秒→20秒→25秒';

  @override
  String get upgradeLives => '生命';

  @override
  String get upgradeLivesDesc => '初始生命:3→4→5';

  @override
  String get upgradeBombs => '炸弹';

  @override
  String get upgradeBombsDesc => '可用炸弹:3→4→5';

  @override
  String get upgradeMagnet => '磁铁';

  @override
  String get upgradeMagnetDesc => '每级+10px磁铁范围(最大+50px)';

  @override
  String get upgradeXpBoost => 'XP加成';

  @override
  String get upgradeXpBoostDesc => '每级+10% GoldGeom(最大+50%)';
}
