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
  String get upgradeBombs => '炸弹范围';

  @override
  String get upgradeBombsDesc => '每级+爆炸半径(L0半场,L10全场)';

  @override
  String get upgradeMagnet => '磁铁';

  @override
  String get upgradeMagnetDesc => '每级+10px磁铁范围(最大+50px)';

  @override
  String get upgradeXpBoost => 'XP加成';

  @override
  String get upgradeXpBoostDesc => '每级+10% GoldGeom(最大+50%)';

  @override
  String get petNameAttack => '攻击';

  @override
  String get petDescAttack => '跟随玩家+发射额外弹幕。双倍火力。';

  @override
  String get petNameCollect => '收集';

  @override
  String get petDescCollect => '自由飞行,远程收集几何体。经济加成。';

  @override
  String get petNameSweep => '扫荡';

  @override
  String get petDescSweep => '环绕玩家,接触即秒杀敌人。';

  @override
  String get petNameDefend => '防御';

  @override
  String get petDescDefend => '跟随玩家身后,向反方向射击。';

  @override
  String get petNameSnipe => '狙击';

  @override
  String get petDescSnipe => '缓慢环绕+每1.5秒激光击中最近敌人。';

  @override
  String get petNameRam => '撞击';

  @override
  String get petDescRam => '追击+撞向最近敌人。冷却1秒。';

  @override
  String get petNamePhoenix => '凤凰';

  @override
  String get petDescPhoenix => '每局自动复活一次+2秒无敌。';

  @override
  String get petNameBlackHole => '黑洞';

  @override
  String get petDescBlackHole => '引力井:拖拽150px范围内的敌人。';

  @override
  String get petNameEmpDrone => 'EMP无人机';

  @override
  String get petDescEmpDrone => '每8秒脉冲眩晕250px内敌人(0.5秒眩晕)。';

  @override
  String get petNameTacticalSpotter => '战术观察员';

  @override
  String get petDescTacticalSpotter => '玩家生命危急时0.5秒慢动作。CD 6秒。';

  @override
  String get weaponStatDmg => '伤害';

  @override
  String get weaponStatRate => '射速';

  @override
  String get weaponStatRange => '射程';

  @override
  String get weaponStatBullets => '弹数';

  @override
  String get weaponStatSpread => '散布';

  @override
  String get weaponStatBounce => '反弹';

  @override
  String get weaponStatTrack => '追踪';

  @override
  String get weaponStatBlast => '爆炸';

  @override
  String get weaponStatAoe => '范围';

  @override
  String get weaponStatPierce => '穿透';

  @override
  String get weaponStatLen => '长度';

  @override
  String get weaponStatPull => '牵引';

  @override
  String get weaponStatJumps => '跳跃';

  @override
  String get weaponStatTick => '刻';

  @override
  String get weaponRateMed => '中';

  @override
  String get weaponRateFast => '快';

  @override
  String get weaponRateSlow => '慢';

  @override
  String get weaponRateCont => '持续';

  @override
  String get modNoneCard => '无修饰符';

  @override
  String get modNoneCardDesc => '无修饰符进行游戏。';

  @override
  String get modeLockedSnack => '在商店中解锁';

  @override
  String get modNameGlassCannon => '玻璃大炮';

  @override
  String get modDescGlassCannon => '3倍伤害，但只有1条命。无无敌。';

  @override
  String get modNameBulletHell => '弹幕地狱';

  @override
  String get modDescBulletHell => '敌人射击速度提高一倍。';

  @override
  String get modNameSpeedDemon => '速度恶魔';

  @override
  String get modDescSpeedDemon => '一切速度提升1.5倍（玩家和敌人）。';

  @override
  String get modNameNoPowerups => '纯粹者';

  @override
  String get modDescNoPowerups => '比赛中没有道具。';

  @override
  String get modNameFogOfWar => '战争迷雾';

  @override
  String get modDescFogOfWar => '能见度降低。仅可见附近区域。';

  @override
  String get modNameTinyArena => '微型竞技场';

  @override
  String get modDescTinyArena => '竞技场缩小50%。躲避空间更少。';

  @override
  String get modNameOneShot => '一击必杀';

  @override
  String get modDescOneShot => '所有敌人一击毙命。你也是。';

  @override
  String get modNameChaos => '全面混乱';

  @override
  String get modDescChaos => '每10秒自动获得随机道具。';

  @override
  String get modNameGiantMode => '巨人模式';

  @override
  String get modDescGiantMode => '一切都变大2倍。敌人、子弹，一切。';

  @override
  String get modNameRicochetWorld => '全面反弹';

  @override
  String get modDescRicochetWorld => '所有子弹反弹5次。';

  @override
  String get modNameInfiniteBombs => '轰炸机';

  @override
  String get modDescInfiniteBombs => '无限炸弹！但没有武器。';

  @override
  String get modNameMagnetKing => '磁铁之王';

  @override
  String get modDescMagnetKing => '巨大的磁铁范围。几何体飞向你。';

  @override
  String get gameOverBossLabel => 'BOSS';

  @override
  String get gameOverGoldGeoms => '金色几何体';

  @override
  String get achKills100Name => '首杀';

  @override
  String get achKills100Desc => '总共击杀100个敌人';

  @override
  String get achKills1000Name => '灭绝者';

  @override
  String get achKills1000Desc => '总共击杀1,000个敌人';

  @override
  String get achKills10000Name => '几何屠夫';

  @override
  String get achKills10000Desc => '总共击杀10,000个敌人';

  @override
  String get achKills100000Name => '传奇';

  @override
  String get achKills100000Desc => '总共击杀100,000个敌人';

  @override
  String get achKillsSession200Name => '盲目之怒';

  @override
  String get achKillsSession200Desc => '一局击杀200个敌人';

  @override
  String get achKillsSession500Name => '大屠杀';

  @override
  String get achKillsSession500Desc => '一局击杀500个敌人';

  @override
  String get achKillsSession1000Name => '天启';

  @override
  String get achKillsSession1000Desc => '一局击杀1000个敌人';

  @override
  String get achBosses10Name => 'BOSS杀手';

  @override
  String get achBosses10Desc => '总共击败10个BOSS';

  @override
  String get achBosses50Name => '弑君者';

  @override
  String get achBosses50Desc => '总共击败50个BOSS';

  @override
  String get achBosses100Name => '王者灭绝者';

  @override
  String get achBosses100Desc => '总共击败100个BOSS';

  @override
  String get achBossSession5Name => '王者狩猎';

  @override
  String get achBossSession5Desc => '一局击败5个BOSS';

  @override
  String get achBombs50Name => '爆破手';

  @override
  String get achBombs50Desc => '总共使用50枚炸弹';

  @override
  String get achBombs500Name => '拆迁者';

  @override
  String get achBombs500Desc => '总共使用500枚炸弹';

  @override
  String get achScore100kName => '六位数';

  @override
  String get achScore100kDesc => '达到100,000分';

  @override
  String get achScore1mName => '百万富翁';

  @override
  String get achScore1mDesc => '达到1,000,000分';

  @override
  String get achScore10mName => '积分之王';

  @override
  String get achScore10mDesc => '达到10,000,000分';

  @override
  String get achScore100mName => '百夫长';

  @override
  String get achScore100mDesc => '达到100,000,000分';

  @override
  String get achScore1bName => '亿万富翁';

  @override
  String get achScore1bDesc => '达到1,000,000,000分';

  @override
  String get achMultiplier100Name => '连击 x100';

  @override
  String get achMultiplier100Desc => '达到100倍数';

  @override
  String get achMultiplier500Name => '连击 x500';

  @override
  String get achMultiplier500Desc => '达到500倍数';

  @override
  String get achMultiplier1000Name => '连击 x1000';

  @override
  String get achMultiplier1000Desc => '达到1000倍数';

  @override
  String get achMultiplier5000Name => '神圣连击';

  @override
  String get achMultiplier5000Desc => '达到5000倍数';

  @override
  String get achGeoms10000Name => '收藏家';

  @override
  String get achGeoms10000Desc => '总共收集10,000个几何体';

  @override
  String get achGeoms100000Name => '几何吝啬鬼';

  @override
  String get achGeoms100000Desc => '总共收集100,000个几何体';

  @override
  String get achWave20Name => '坚持者';

  @override
  String get achWave20Desc => '达到第20波';

  @override
  String get achWave50Name => '老兵';

  @override
  String get achWave50Desc => '达到第50波';

  @override
  String get achWave100Name => '百年';

  @override
  String get achWave100Desc => '达到第100波';

  @override
  String get achWave200Name => '不可阻挡';

  @override
  String get achWave200Desc => '达到第200波(Survival/Tunnel)';

  @override
  String get achPerfectWaves5Name => '不可触及';

  @override
  String get achPerfectWaves5Desc => '连续完成5个完美波';

  @override
  String get achPerfectWaves10Name => '幽灵';

  @override
  String get achPerfectWaves10Desc => '连续完成10个完美波';

  @override
  String get achPerfectWaves20Name => '神性';

  @override
  String get achPerfectWaves20Desc => '连续完成20个完美波';

  @override
  String get achClassicNormalName => '古典主义者';

  @override
  String get achClassicNormalDesc => '在普通难度完成经典模式';

  @override
  String get achClassicHardName => '硬汉';

  @override
  String get achClassicHardDesc => '在困难难度完成经典模式';

  @override
  String get achClassicNightmareName => '活体噩梦';

  @override
  String get achClassicNightmareDesc => '在噩梦难度完成经典模式';

  @override
  String get achAllModesName => '全能选手';

  @override
  String get achAllModesDesc => '游玩所有6种模式';

  @override
  String get achBossRush10Name => 'BOSS猎人';

  @override
  String get achBossRush10Desc => '在Boss Rush中达到第10个BOSS';

  @override
  String get achGames10Name => '玩家';

  @override
  String get achGames10Desc => '游玩10局';

  @override
  String get achGames100Name => '爱好者';

  @override
  String get achGames100Desc => '游玩100局';

  @override
  String get achGames500Name => '瘾君子';

  @override
  String get achGames500Desc => '游玩500局';

  @override
  String get achGold10000Name => '守财奴';

  @override
  String get achGold10000Desc => '积累10,000个金色几何体';

  @override
  String get achGold50000Name => '巨富';

  @override
  String get achGold50000Desc => '积累50,000个金色几何体';

  @override
  String get achAllUpgradesName => '满级强化';

  @override
  String get achAllUpgradesDesc => '购买所有升级';

  @override
  String get achPowerups100Name => '强化品上瘾';

  @override
  String get achPowerups100Desc => '收集100个强化品';

  @override
  String get achWavesWave20Name => '闪避者';

  @override
  String get achWavesWave20Desc => 'Waves模式：达到第20波';

  @override
  String get achWavesWave50Name => '闪避大师';

  @override
  String get achWavesWave50Desc => 'Waves模式：达到第50波';

  @override
  String get achGravityWave15Name => '天体物理学家';

  @override
  String get achGravityWave15Desc => 'Gravity Inferno：达到第15波';

  @override
  String get achPacifistCombo15Name => '和平主义者大师';

  @override
  String get achPacifistCombo15Desc => 'Pacifist：连击大门15+';

  @override
  String get achTimeAttack500kName => '计时员';

  @override
  String get achTimeAttack500kDesc => 'Time Attack：50万分';

  @override
  String get achDailyStreak7Name => '每日信徒';

  @override
  String get achDailyStreak7Desc => '连续7天领取每日奖励';

  @override
  String get achDailyStreak30Name => '月度忠诚';

  @override
  String get achDailyStreak30Desc => '连续30天领取每日奖励';

  @override
  String get achGaussKills500Name => '高斯大师';

  @override
  String get achGaussKills500Desc => '用高斯炮击杀500个敌人';

  @override
  String get achChainKills500Name => '风暴';

  @override
  String get achChainKills500Desc => '用闪电链击杀500个敌人';

  @override
  String get achAllWeaponsName => '军械师';

  @override
  String get achAllWeaponsDesc => '解锁所有武器';

  @override
  String get achAllSkinsName => '时尚达人';

  @override
  String get achAllSkinsDesc => '解锁所有皮肤';

  @override
  String get achAllTrailsName => '宇宙收藏';

  @override
  String get achAllTrailsDesc => '解锁所有尾迹';

  @override
  String get achAllPetsName => '驯兽师';

  @override
  String get achAllPetsDesc => '解锁所有宠物';
}
