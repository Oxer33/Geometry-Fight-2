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
}
