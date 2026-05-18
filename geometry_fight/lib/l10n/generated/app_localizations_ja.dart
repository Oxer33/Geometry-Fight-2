// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get appTitle => 'Geometry Fight 2';

  @override
  String get menuPlay => 'プレイ';

  @override
  String get menuShop => 'ショップ';

  @override
  String get menuStore => 'ショップ';

  @override
  String get menuSettings => '設定';

  @override
  String get menuStats => '統計';

  @override
  String get menuAchievements => 'トロフィー';

  @override
  String get menuAchievementsAlt => '実績';

  @override
  String get menuLeaderboard => 'ランキング';

  @override
  String get menuQuit => '終了';

  @override
  String get diffEasy => 'イージー';

  @override
  String get diffNormal => 'ノーマル';

  @override
  String get diffHard => 'ハード';

  @override
  String get diffNightmare => 'ナイトメア';

  @override
  String get diffNext => '次へ';

  @override
  String get diffTitle => '難易度';

  @override
  String get diffScoreMultiplier => 'スコア';

  @override
  String get settingsTitle => '設定';

  @override
  String get settingsAudio => 'オーディオ';

  @override
  String get settingsGameplay => 'ゲームプレイ';

  @override
  String get settingsMusic => 'ミュージック';

  @override
  String get settingsSfx => 'SFX';

  @override
  String get settingsSfxLong => '効果音';

  @override
  String get settingsVibration => 'バイブレーション';

  @override
  String get settingsShowFps => 'FPS表示';

  @override
  String get settingsLanguage => '言語';

  @override
  String get settingsCrashLogs => 'クラッシュログ';

  @override
  String get settingsReset => 'データリセット';

  @override
  String get settingsDangerZone => '危険ゾーン';

  @override
  String get settingsTestDebug => 'TEST / DEBUG';

  @override
  String get settingsAddCredits => '+1000 クレジット';

  @override
  String get settingsResetPurchases => '購入リセット';

  @override
  String get settingsPurchasesReset => '購入がリセットされました!';

  @override
  String settingsCreditsAdded(int total) {
    return '+1000クレジット!合計: $total';
  }

  @override
  String settingsCrashLogsTitle(int count) {
    return 'クラッシュ ($count)';
  }

  @override
  String get settingsNoCrash => 'クラッシュ記録はありません。\nゲームが落ちた場合ここに表示されます。';

  @override
  String get settingsCopy => 'コピー';

  @override
  String get settingsDelete => '削除';

  @override
  String get settingsLogsCopied => 'ログをコピーしました';

  @override
  String get shopTitle => 'ショップ';

  @override
  String get shopGoldInsufficient => 'ゴールドが足りません!';

  @override
  String get shopEquip => '装備';

  @override
  String get shopEquipped => '装備中';

  @override
  String get shopBuy => '購入';

  @override
  String get shopMaxLevel => 'MAX';

  @override
  String get shopTabWeapons => '武器';

  @override
  String get shopTabSkins => 'スキン';

  @override
  String get shopTabTrails => 'トレイル';

  @override
  String get shopTabPets => 'ペット';

  @override
  String get shopTabUpgrades => 'アップグレード';

  @override
  String get shopTabModes => 'モード';

  @override
  String get shopPurchased => '購入しました!';

  @override
  String get shopLocked => 'ロック中';

  @override
  String get shopCost => '価格';

  @override
  String get shopLevel => 'レベル';

  @override
  String get shopScrollMore => 'スクロールでもっと';

  @override
  String get loadoutTitle => '装備品';

  @override
  String get loadoutWeapon => '武器';

  @override
  String get loadoutPet => 'ペット';

  @override
  String get loadoutLocked => 'ショップでこの武器を解除';

  @override
  String get loadoutPetLocked => 'ショップでこのペットを解除';

  @override
  String get loadoutStart => 'ゲーム開始';

  @override
  String get loadoutPetNone => 'なし';

  @override
  String shopAlreadyMax(String name) {
    return '$name は最大レベルです！';
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
  String get shopBadgeNew => '新';

  @override
  String get shopBadgeUnlocked => '解除済み';

  @override
  String shopBuyWithCost(int cost) {
    return '購入 ${cost}g';
  }

  @override
  String get shopTapNodeForDetails => 'ノードをタップして詳細を表示';

  @override
  String get modeTitle => 'モード';

  @override
  String get modeSelectTitle => 'モードを選択';

  @override
  String get modeEndless => 'エンドレス';

  @override
  String get modeBossRush => 'ボスラッシュ';

  @override
  String get modeSurvival => 'サバイバル';

  @override
  String get modeChallenge => 'チャレンジ';

  @override
  String get modeClassic => 'クラシック';

  @override
  String get modePacifist => 'パシフィスト';

  @override
  String get modeTimeAttack => 'タイムアタック';

  @override
  String get modeZen => '禅';

  @override
  String get modeTunnel => 'トンネル';

  @override
  String get modeDailyChallenge => 'デイリーチャレンジ';

  @override
  String get modeWaves => 'ウェーブ';

  @override
  String get modeGravityInferno => '重力インフェルノ';

  @override
  String get splashSkip => 'スキップ';

  @override
  String get splashTapToStart => 'タップしてスタート';

  @override
  String get modifiersTitle => 'モディファイア';

  @override
  String get modifiersConfirm => '確認';

  @override
  String get back => '戻る';

  @override
  String get play => 'プレイ';

  @override
  String get pause => '一時停止';

  @override
  String get resume => '再開';

  @override
  String get restart => 'リスタート';

  @override
  String get retry => 'リトライ';

  @override
  String get quit => '終了';

  @override
  String get close => '閉じる';

  @override
  String get next => '次へ';

  @override
  String get start => 'スタート';

  @override
  String get yes => 'はい';

  @override
  String get no => 'いいえ';

  @override
  String get confirm => '確認';

  @override
  String get cancel => 'キャンセル';

  @override
  String get continueAction => '続ける';

  @override
  String get score => 'スコア';

  @override
  String get wave => 'ウェーブ';

  @override
  String get lives => 'ライフ';

  @override
  String get level => 'レベル';

  @override
  String get gold => 'ゴールド';

  @override
  String get geoms => 'GEOMS';

  @override
  String get best => 'ベスト';

  @override
  String get kills => 'キル';

  @override
  String get timeLabel => 'タイム';

  @override
  String get highScore => 'ハイスコア';

  @override
  String get newRun => 'ニューラン';

  @override
  String get gameOver => 'ゲームオーバー';

  @override
  String get newRecord => '新記録!';

  @override
  String get victory => '勝利';

  @override
  String get achievementsTitle => 'トロフィー';

  @override
  String get achievementUnlocked => 'トロフィー獲得!';

  @override
  String get achievementCategoryCombat => '戦闘';

  @override
  String get achievementCategoryScore => 'スコア';

  @override
  String get achievementCategoryProgress => '進捗';

  @override
  String get achievementCategoryMastery => 'マスタリー';

  @override
  String get achievementCategorySpecial => 'スペシャル';

  @override
  String get leaderboardTitle => 'ランキング';

  @override
  String get leaderboardEmpty => 'まだスコアがありません';

  @override
  String get statsTitle => '統計';

  @override
  String get summaryTitle => 'サマリー';

  @override
  String get dailyRewardTitle => 'デイリーリワード';

  @override
  String dailyRewardGeoms(int amount) {
    return '+$amount GEOM';
  }

  @override
  String dailyRewardStreakOne(int count) {
    return '連続: $count日';
  }

  @override
  String dailyRewardStreakMany(int count) {
    return '連続: $count日';
  }

  @override
  String get settingsResetTitle => 'データリセット';

  @override
  String get settingsResetWarning => '全ての進行状況、アップグレード、購入が削除されます。';

  @override
  String get settingsResetButton => 'リセット';

  @override
  String get settingsResetAllData => '全データをリセット';

  @override
  String get badgeKiller => 'キラー';

  @override
  String get badgeMassacre => '大虐殺';

  @override
  String get badgePersistent => '粘り強い';

  @override
  String get badgeVeteran => 'ベテラン';

  @override
  String get badgeBossHunter => 'ボスハンター';

  @override
  String get badgeRegicide => '国王殺し';

  @override
  String get newAchievementBanner => '★ 新しい実績! ★';

  @override
  String get columnDate => '日付';

  @override
  String leaderboardRecords(int count) {
    return '$count REC';
  }

  @override
  String get leaderboardNoRecord => '記録なし';

  @override
  String get leaderboardEmptyHint => 'このモードをプレイして\nランキングに挑戦！';

  @override
  String get statsSectionGeneral => '全般';

  @override
  String get statsSectionCombat => '戦闘';

  @override
  String get statsSectionRecords => '記録';

  @override
  String get statsSectionAchievements => '実績';

  @override
  String get statsSectionScoresByMode => 'モード別スコア';

  @override
  String get statsGamesPlayed => 'プレイ回数';

  @override
  String get statsTotalPlaytime => '総プレイ時間';

  @override
  String get statsTotalGoldEarned => '獲得ゴールド合計';

  @override
  String get statsCurrentGold => '現在のゴールド';

  @override
  String get statsEnemiesKilled => '倒した敵';

  @override
  String get statsBossesDefeated => '倒したボス';

  @override
  String get statsBombsUsed => '使用したボム';

  @override
  String get statsPowerUpsCollected => '取得したパワーアップ';

  @override
  String get statsGeomsCollected => '取得したGeom';

  @override
  String get statsBestScore => 'ベストスコア';

  @override
  String get statsHighestWave => '最高ウェーブ';

  @override
  String get statsMaxMultiplier => '最大倍率';

  @override
  String get statsMaxSessionKills => '1ゲーム最大キル';

  @override
  String get statsMaxPerfectStreak => '最大パーフェクトウェーブ';

  @override
  String get statsAchievementsUnlocked => '解除済み';

  @override
  String get summaryNone => 'なし';

  @override
  String get summaryScoreMultiplierTitle => 'スコア倍率';

  @override
  String get summaryDifficultyRow => '難易度';

  @override
  String get summaryModifiersRow => 'モディファイア';

  @override
  String get summaryTotal => '合計';

  @override
  String summaryActiveModifiers(int count, String mult) {
    return '$count 有効 · ×$mult score';
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
    return '最大 $count モディファイア';
  }

  @override
  String modifiersScoreLabel(String mult) {
    return 'スコア x$mult';
  }

  @override
  String modifiersActiveCount(int count, int max) {
    return '有効: $count/$max';
  }

  @override
  String hudBossWave(int wave) {
    return 'ボス ウェーブ $wave';
  }

  @override
  String hudWaveNumber(int wave) {
    return 'ウェーブ $wave';
  }

  @override
  String get hudPerfectWave => 'パーフェクトウェーブ！';

  @override
  String get hudPerfectBonus => '+10 GEOMS ボーナス';

  @override
  String hudEnemiesRemaining(int count) {
    return '敵 $count';
  }

  @override
  String get hudBoost2x => '2x ブースト';

  @override
  String get powerUpRapidFire => 'ラピッドファイア';

  @override
  String get powerUpOverdrive => 'オーバードライブ';

  @override
  String get powerUpMagnet => 'マグネット';

  @override
  String get powerUpTimeSlow => 'タイムスロー';

  @override
  String get powerUpSpreadShot => 'スプレッドショット';

  @override
  String get powerUpFirePower => 'ファイアパワー';

  @override
  String get tutorialTitle => '遊び方';

  @override
  String get tutorialLeftJoystick => '左スティック';

  @override
  String get tutorialLeftJoystickDesc => '機体を移動';

  @override
  String get tutorialRightJoystick => '右スティック';

  @override
  String get tutorialRightJoystickDesc => '自動で照準・射撃';

  @override
  String get tutorialBomb => 'ボム';

  @override
  String get tutorialBombDesc => '近くの敵をすべて破壊';

  @override
  String get tutorialGeoms => 'GEOMS';

  @override
  String get tutorialGeomsDesc => '集めてスコアとアップグレード';

  @override
  String get tutorialPowerUp => 'パワーアップ';

  @override
  String get tutorialPowerUpDesc => '一時的なブースト';

  @override
  String get tutorialTapToStart => 'タップしてスタート';

  @override
  String get skinNameClassic => 'Classic';

  @override
  String get skinDescClassic => 'オリジナルのシアンの機体';

  @override
  String get skinNameStealth => 'Stealth';

  @override
  String get skinDescStealth => '黒に赤縁——ステルススタイル';

  @override
  String get skinNameCrystal => 'Crystal';

  @override
  String get skinDescCrystal => 'プリズム結晶——虹の反射';

  @override
  String get skinNameGhost => 'Ghost';

  @override
  String get skinDescGhost => '半透明、粒子の軌跡付き';

  @override
  String get skinNameOmega => 'Omega';

  @override
  String get skinDescOmega => '黄金の四芒星——独特な形';

  @override
  String get skinNamePhoenix => 'Phoenix';

  @override
  String get skinDescPhoenix => '炎の翼に燠羽根——灰から蘇る';

  @override
  String get skinNameCyber => 'Cyber';

  @override
  String get skinDescCyber => 'ネオングリーンの回路メッシュ——アニメーションデジタルオーバーレイ';

  @override
  String get skinNameVoidwalker => 'Voidwalker';

  @override
  String get skinDescVoidwalker => '紫のコアが虚空に浮遊——幽玄なハロー';

  @override
  String get skinNameAurora => 'Aurora';

  @override
  String get skinDescAurora => 'オーロラ:シアン/ピンク/グリーンが流れる';

  @override
  String get skinNameTactical => 'Tactical';

  @override
  String get skinDescTactical => '灰青の軍用アーマー——装甲プレート';

  @override
  String get skinNamePrism => 'Prism';

  @override
  String get skinDescPrism => '多角形クリスタル——マルチ虹の屈折';

  @override
  String get skinNameTron => 'Tron';

  @override
  String get skinDescTron => '黒ボディにシアンネオンライン——デジタル回路グリッド';

  @override
  String get skinNameSamurai => 'Samurai';

  @override
  String get skinDescSamurai => '黒鎧に金赤のディテール——名誉と戦い';

  @override
  String get skinNameRosegold => 'RoseGold';

  @override
  String get skinDescRosegold => 'メタリックローズゴールド——モダンな優雅さ';

  @override
  String get skinNameNinja => 'Ninja';

  @override
  String get skinDescNinja => '影色グレーに手裏剣アクセント——静かで致命的';

  @override
  String get skinNameGlitch => 'Glitch';

  @override
  String get skinDescGlitch => 'RGB色彩シフト——アニメーション収差';

  @override
  String get trailNameNormal => 'Normal';

  @override
  String get trailDescNormal => '標準シアン軌跡';

  @override
  String get trailNameFire => 'Fire';

  @override
  String get trailDescFire => '機体後方の火の粒子';

  @override
  String get trailNameIce => 'Ice';

  @override
  String get trailDescIce => 'きらめく氷の結晶';

  @override
  String get trailNamePlasma => 'Plasma';

  @override
  String get trailDescPlasma => '脈動する紫のプラズマエネルギー';

  @override
  String get trailNameRainbow => 'Rainbow';

  @override
  String get trailDescRainbow => '絶えず変化する色';

  @override
  String get trailNameComet => 'Comet';

  @override
  String get trailDescComet => '明るい頭部とゆっくり消えるテール';

  @override
  String get trailNameInferno => 'Inferno';

  @override
  String get trailDescInferno => '多層の炎と飛び散る燠';

  @override
  String get trailNameVoid => 'Void';

  @override
  String get trailDescVoid => '紫の粒子を吸い込む暗い渦';

  @override
  String get trailNameQuantum => 'Quantum';

  @override
  String get trailDescQuantum => '色彩重ね合わせの対粒子';

  @override
  String get trailNameGalaxy => 'Galaxy';

  @override
  String get trailDescGalaxy => '渦巻く星と宇宙塵';

  @override
  String get trailNameLightning => 'Lightning';

  @override
  String get trailDescLightning => '軌跡点間のジグザグ電弧';

  @override
  String get trailNameNebula => 'Nebula';

  @override
  String get trailDescNebula => '脈動するシアン/マゼンタの宇宙雲';

  @override
  String get trailNamePrism => 'Prism';

  @override
  String get trailDescPrism => '軌跡に沿って流れる全スペクトル';

  @override
  String get trailNameHologram => 'Hologram';

  @override
  String get trailDescHologram => 'RGB色収差グリッチスタイル';

  @override
  String get trailNameBiolume => 'Biolumin';

  @override
  String get trailDescBiolume => '水中生物発光 緑/シアン';

  @override
  String get trailNameNeonpulse => 'NeonPulse';

  @override
  String get trailDescNeonpulse => '拡大する白シアンのネオンリング';

  @override
  String get weaponNameBasic => 'Basic Gun';

  @override
  String get weaponDescBasic => '黄色弾の平行2列——信頼性と精度。';

  @override
  String get weaponNameTriple => 'Triple Shot';

  @override
  String get weaponDescTriple => '白弾3発を密集——集中射撃。';

  @override
  String get weaponNameSpread => 'Spread Shot';

  @override
  String get weaponDescSpread => 'オレンジ弾5発の狭い扇形——集団に最適。';

  @override
  String get weaponNameRicochet => 'Ricochet';

  @override
  String get weaponDescRicochet => '高ダメージ緑弾3発の扇形——壁で2回跳ね返る。';

  @override
  String get weaponNameHoming => 'Homing';

  @override
  String get weaponDescHoming => '個別ターゲット追跡5ミサイル——壁で爆発。';

  @override
  String get weaponNamePlasma => 'Plasma';

  @override
  String get weaponDescPlasma => '遅い紫オーブと爆発AoE——ボスと集団を蹂躙。';

  @override
  String get weaponNameLaser => 'Laser';

  @override
  String get weaponDescLaser => '連続する赤いビーム——触れたものすべてを切断。';

  @override
  String get weaponNameGauss => 'Gauss Cannon';

  @override
  String get weaponDescGauss => '紫の弾に1秒の重力吸引——敵を集めて全弾命中。';

  @override
  String get weaponNameChain => 'Chain Lightning';

  @override
  String get weaponDescChain => '電撃が5体の敵を跳ね回る——集団に最適。';

  @override
  String get modeDescClassic => '100ウェーブ・10ごとにボス——標準モード';

  @override
  String get modeDescBossRush => 'ボスのみ次々と——雑魚なし';

  @override
  String get modeDescSurvival => '無限ウェーブが徐々に難化——どこまで耐える?';

  @override
  String get modeDescTimeAttack => '3分間:時間切れまでに高得点を狙え';

  @override
  String get modeDescZenMode => '無限ライフ——ストレスなしで全てを探求';

  @override
  String get modeDescTunnel => '無限トンネル内の横スクロール';

  @override
  String get modeDescPacifist => '射撃禁止!ゲートで生き残れ(GW Pacifism)';

  @override
  String get modeDescWaves => '基本の赤い三角形のみ。稀にブラックホール。純粋な回避。';

  @override
  String get modeDescGravityInferno => '多数のブラックホール+混合雑魚少数。ボスなし。重力カオス。';

  @override
  String get upgradeFirepower => '火力';

  @override
  String get upgradeFirepowerDesc => 'レベルごとに+5%ダメージ(最大+25%)';

  @override
  String get upgradeFireRate => '連射';

  @override
  String get upgradeFireRateDesc => 'レベルごとに+5%発射速度(最大+25%)';

  @override
  String get upgradeSpeed => '速度';

  @override
  String get upgradeSpeedDesc => 'レベルごとに+5%速度(最大+25%)';

  @override
  String get upgradeShield => 'シールド';

  @override
  String get upgradeShieldDesc => '死亡後シールド:5秒→10秒→15秒→20秒→25秒';

  @override
  String get upgradeLives => 'ライフ';

  @override
  String get upgradeLivesDesc => '初期ライフ:3→4→5';

  @override
  String get upgradeBombs => 'ボム範囲';

  @override
  String get upgradeBombsDesc => 'レベルごとに+爆発半径(L0半アリーナ,L10全アリーナ)';

  @override
  String get upgradeMagnet => 'マグネット';

  @override
  String get upgradeMagnetDesc => 'レベルごとに+10px磁石範囲(最大+50px)';

  @override
  String get upgradeXpBoost => 'XPブースト';

  @override
  String get upgradeXpBoostDesc => 'レベルごとに+10% GoldGeom(最大+50%)';
}
