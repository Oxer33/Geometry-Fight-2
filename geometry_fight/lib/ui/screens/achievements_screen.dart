import 'dart:math';
import 'package:flutter/material.dart';
import '../../data/achievements.dart';
import '../../l10n/generated/app_localizations.dart';
import '../widgets/neon_back_button.dart';

/// Localized name for an achievement id. Falls back to catalog Italian if id
/// is unknown (defensive — keeps render path safe when new achievements
/// are added without ARB updates).
String achievementName(String id, AppLocalizations l10n) {
  switch (id) {
    case 'kills_100':
      return l10n.achKills100Name;
    case 'kills_1000':
      return l10n.achKills1000Name;
    case 'kills_10000':
      return l10n.achKills10000Name;
    case 'kills_100000':
      return l10n.achKills100000Name;
    case 'kills_session_200':
      return l10n.achKillsSession200Name;
    case 'kills_session_500':
      return l10n.achKillsSession500Name;
    case 'kills_session_1000':
      return l10n.achKillsSession1000Name;
    case 'bosses_10':
      return l10n.achBosses10Name;
    case 'bosses_50':
      return l10n.achBosses50Name;
    case 'bosses_100':
      return l10n.achBosses100Name;
    case 'boss_session_5':
      return l10n.achBossSession5Name;
    case 'bombs_50':
      return l10n.achBombs50Name;
    case 'bombs_500':
      return l10n.achBombs500Name;
    case 'score_100k':
      return l10n.achScore100kName;
    case 'score_1m':
      return l10n.achScore1mName;
    case 'score_10m':
      return l10n.achScore10mName;
    case 'score_100m':
      return l10n.achScore100mName;
    case 'score_1b':
      return l10n.achScore1bName;
    case 'multiplier_100':
      return l10n.achMultiplier100Name;
    case 'multiplier_500':
      return l10n.achMultiplier500Name;
    case 'multiplier_1000':
      return l10n.achMultiplier1000Name;
    case 'multiplier_5000':
      return l10n.achMultiplier5000Name;
    case 'geoms_10000':
      return l10n.achGeoms10000Name;
    case 'geoms_100000':
      return l10n.achGeoms100000Name;
    case 'wave_20':
      return l10n.achWave20Name;
    case 'wave_50':
      return l10n.achWave50Name;
    case 'wave_100':
      return l10n.achWave100Name;
    case 'wave_200':
      return l10n.achWave200Name;
    case 'perfect_waves_5':
      return l10n.achPerfectWaves5Name;
    case 'perfect_waves_10':
      return l10n.achPerfectWaves10Name;
    case 'perfect_waves_20':
      return l10n.achPerfectWaves20Name;
    case 'classic_normal':
      return l10n.achClassicNormalName;
    case 'classic_hard':
      return l10n.achClassicHardName;
    case 'classic_nightmare':
      return l10n.achClassicNightmareName;
    case 'all_modes':
      return l10n.achAllModesName;
    case 'boss_rush_10':
      return l10n.achBossRush10Name;
    case 'games_10':
      return l10n.achGames10Name;
    case 'games_100':
      return l10n.achGames100Name;
    case 'games_500':
      return l10n.achGames500Name;
    case 'gold_10000':
      return l10n.achGold10000Name;
    case 'gold_50000':
      return l10n.achGold50000Name;
    case 'all_upgrades':
      return l10n.achAllUpgradesName;
    case 'powerups_100':
      return l10n.achPowerups100Name;
    case 'waves_wave_20':
      return l10n.achWavesWave20Name;
    case 'waves_wave_50':
      return l10n.achWavesWave50Name;
    case 'gravity_wave_15':
      return l10n.achGravityWave15Name;
    case 'pacifist_combo_15':
      return l10n.achPacifistCombo15Name;
    case 'time_attack_500k':
      return l10n.achTimeAttack500kName;
    case 'daily_streak_7':
      return l10n.achDailyStreak7Name;
    case 'daily_streak_30':
      return l10n.achDailyStreak30Name;
    case 'gauss_kills_500':
      return l10n.achGaussKills500Name;
    case 'chain_kills_500':
      return l10n.achChainKills500Name;
    case 'all_weapons':
      return l10n.achAllWeaponsName;
    case 'all_skins':
      return l10n.achAllSkinsName;
    case 'all_trails':
      return l10n.achAllTrailsName;
    case 'all_pets':
      return l10n.achAllPetsName;
    default:
      final a = allAchievements.firstWhere(
        (x) => x.id == id,
        orElse: () => const AchievementDef(
          id: '',
          name: '',
          description: '',
          icon: '',
          category: '',
          target: 0,
        ),
      );
      return a.name;
  }
}

/// Localized description for an achievement id. Falls back to catalog Italian
/// if id is unknown.
String achievementDesc(String id, AppLocalizations l10n) {
  switch (id) {
    case 'kills_100':
      return l10n.achKills100Desc;
    case 'kills_1000':
      return l10n.achKills1000Desc;
    case 'kills_10000':
      return l10n.achKills10000Desc;
    case 'kills_100000':
      return l10n.achKills100000Desc;
    case 'kills_session_200':
      return l10n.achKillsSession200Desc;
    case 'kills_session_500':
      return l10n.achKillsSession500Desc;
    case 'kills_session_1000':
      return l10n.achKillsSession1000Desc;
    case 'bosses_10':
      return l10n.achBosses10Desc;
    case 'bosses_50':
      return l10n.achBosses50Desc;
    case 'bosses_100':
      return l10n.achBosses100Desc;
    case 'boss_session_5':
      return l10n.achBossSession5Desc;
    case 'bombs_50':
      return l10n.achBombs50Desc;
    case 'bombs_500':
      return l10n.achBombs500Desc;
    case 'score_100k':
      return l10n.achScore100kDesc;
    case 'score_1m':
      return l10n.achScore1mDesc;
    case 'score_10m':
      return l10n.achScore10mDesc;
    case 'score_100m':
      return l10n.achScore100mDesc;
    case 'score_1b':
      return l10n.achScore1bDesc;
    case 'multiplier_100':
      return l10n.achMultiplier100Desc;
    case 'multiplier_500':
      return l10n.achMultiplier500Desc;
    case 'multiplier_1000':
      return l10n.achMultiplier1000Desc;
    case 'multiplier_5000':
      return l10n.achMultiplier5000Desc;
    case 'geoms_10000':
      return l10n.achGeoms10000Desc;
    case 'geoms_100000':
      return l10n.achGeoms100000Desc;
    case 'wave_20':
      return l10n.achWave20Desc;
    case 'wave_50':
      return l10n.achWave50Desc;
    case 'wave_100':
      return l10n.achWave100Desc;
    case 'wave_200':
      return l10n.achWave200Desc;
    case 'perfect_waves_5':
      return l10n.achPerfectWaves5Desc;
    case 'perfect_waves_10':
      return l10n.achPerfectWaves10Desc;
    case 'perfect_waves_20':
      return l10n.achPerfectWaves20Desc;
    case 'classic_normal':
      return l10n.achClassicNormalDesc;
    case 'classic_hard':
      return l10n.achClassicHardDesc;
    case 'classic_nightmare':
      return l10n.achClassicNightmareDesc;
    case 'all_modes':
      return l10n.achAllModesDesc;
    case 'boss_rush_10':
      return l10n.achBossRush10Desc;
    case 'games_10':
      return l10n.achGames10Desc;
    case 'games_100':
      return l10n.achGames100Desc;
    case 'games_500':
      return l10n.achGames500Desc;
    case 'gold_10000':
      return l10n.achGold10000Desc;
    case 'gold_50000':
      return l10n.achGold50000Desc;
    case 'all_upgrades':
      return l10n.achAllUpgradesDesc;
    case 'powerups_100':
      return l10n.achPowerups100Desc;
    case 'waves_wave_20':
      return l10n.achWavesWave20Desc;
    case 'waves_wave_50':
      return l10n.achWavesWave50Desc;
    case 'gravity_wave_15':
      return l10n.achGravityWave15Desc;
    case 'pacifist_combo_15':
      return l10n.achPacifistCombo15Desc;
    case 'time_attack_500k':
      return l10n.achTimeAttack500kDesc;
    case 'daily_streak_7':
      return l10n.achDailyStreak7Desc;
    case 'daily_streak_30':
      return l10n.achDailyStreak30Desc;
    case 'gauss_kills_500':
      return l10n.achGaussKills500Desc;
    case 'chain_kills_500':
      return l10n.achChainKills500Desc;
    case 'all_weapons':
      return l10n.achAllWeaponsDesc;
    case 'all_skins':
      return l10n.achAllSkinsDesc;
    case 'all_trails':
      return l10n.achAllTrailsDesc;
    case 'all_pets':
      return l10n.achAllPetsDesc;
    default:
      final a = allAchievements.firstWhere(
        (x) => x.id == id,
        orElse: () => const AchievementDef(
          id: '',
          name: '',
          description: '',
          icon: '',
          category: '',
          target: 0,
        ),
      );
      return a.description;
  }
}

class AchievementsScreen extends StatefulWidget {
  final VoidCallback onBack;

  const AchievementsScreen({super.key, required this.onBack});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen>
    with TickerProviderStateMixin {
  late AnimationController _entranceController;
  late AnimationController _glowController;
  late AnimationController _shimmerController;

  static const _categoryColors = {
    'combat': Color(0xFFFF4466),
    'score': Color(0xFFFFD700),
    'progress': Colors.cyanAccent,
    'mastery': Color(0xFFCC00FF),
    'special': Colors.greenAccent,
  };

  static const _categoryIcons = {
    'combat': Icons.local_fire_department_rounded,
    'score': Icons.emoji_events_rounded,
    'progress': Icons.trending_up_rounded,
    'mastery': Icons.auto_awesome_rounded,
    'special': Icons.star_rounded,
  };

  static const _categories = [
    'combat',
    'score',
    'progress',
    'mastery',
    'special',
  ];

  Map<String, String> _categoryNames(AppLocalizations l10n) => {
    'combat': l10n.achievementCategoryCombat,
    'score': l10n.achievementCategoryScore,
    'progress': l10n.achievementCategoryProgress,
    'mastery': l10n.achievementCategoryMastery,
    'special': l10n.achievementCategorySpecial,
  };

  // Cache localized category names (locale-dependent): build once in
  // didChangeDependencies invece di ricostruire la Map ad ogni frame.
  late Map<String, String> _categoryNamesCache;

  // Cached per-category lists (avoid rebuilding every frame)
  late final Map<String, List<AchievementDef>> _achievementsByCategory;
  late final int _unlockedCount;
  late final int _totalCount;
  late final double _completionPct;
  // Cache unlocked/progress (era ~3600 Hive reads/sec durante entrance).
  late final Map<String, bool> _unlockedCache;
  late final Map<String, int> _progressCache;

  final ScrollController _listCtrl = ScrollController();

  @override
  void initState() {
    super.initState();

    _achievementsByCategory = {
      for (final cat in _categories)
        cat: allAchievements.where((a) => a.category == cat).toList(),
    };
    // Snapshot stato Hive una volta sola invece di ogni frame.
    _unlockedCache = {
      for (final a in allAchievements)
        a.id: AchievementManager.isUnlocked(a.id),
    };
    _progressCache = {
      for (final a in allAchievements)
        a.id: AchievementManager.getProgress(a.id),
    };
    _unlockedCount = _unlockedCache.values.where((v) => v).length;
    _totalCount = _unlockedCache.length;
    _completionPct = _totalCount > 0 ? _unlockedCount / _totalCount : 0.0;
    _entranceController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..forward();

    _glowController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    )..repeat(reverse: true);

    _shimmerController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Localized names depend on the locale (an inherited dependency), so
    // rebuild the cache here instead of on every build/frame.
    _categoryNamesCache = _categoryNames(AppLocalizations.of(context)!);
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _glowController.dispose();
    _shimmerController.dispose();
    _listCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final categoryNames = _categoryNamesCache;
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        // Only the one-shot ENTRANCE animation drives this top-level rebuild.
        // The repeating glow controller is consumed by narrow AnimatedBuilders
        // wrapped around just the decorations that read it (header completion
        // chip + tile decoration), so glow ticks no longer rebuild the whole
        // Column/ListView. _shimmerController drives nothing and is therefore
        // not part of any rebuild path.
        child: AnimatedBuilder(
          animation: _entranceController,
          builder: (context, _) {
            final entrance = _entranceController.value;

            return Column(
              children: [
                // Header
                _buildHeader(
                  l10n,
                  entrance,
                  _unlockedCount,
                  _totalCount,
                  _completionPct,
                ),

                // Achievement list
                Expanded(
                  child: RawScrollbar(
                    controller: _listCtrl,
                    thumbVisibility: true,
                    trackVisibility: true,
                    thickness: 10,
                    radius: const Radius.circular(5),
                    thumbColor: const Color(0xFF00FFFF),
                    trackColor: const Color(0x3300FFFF),
                    trackBorderColor: const Color(0x8800FFFF),
                    child: ListView(
                      controller: _listCtrl,
                      padding: const EdgeInsets.all(16),
                      children: [
                        for (int ci = 0; ci < _categories.length; ci++) ...[
                          _buildCategoryHeader(
                            categoryNames[_categories[ci]]!,
                            _categoryColors[_categories[ci]]!,
                            _categoryIcons[_categories[ci]]!,
                            entrance,
                            ci * 0.08,
                            _categories[ci],
                          ),
                          ..._achievementsByCategory[_categories[ci]]!
                              .asMap()
                              .entries
                              .map(
                                (entry) => _buildAchievementTile(
                                  entry.value,
                                  _categoryColors[_categories[ci]]!,
                                  entrance,
                                  ci * 0.08 + entry.key * 0.02,
                                  l10n,
                                ),
                              ),
                          const SizedBox(height: 12),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(
    AppLocalizations l10n,
    double entrance,
    int unlocked,
    int total,
    double completionPct,
  ) {
    return Opacity(
      opacity: entrance,
      child: Transform.translate(
        offset: Offset(0, -20 * (1 - entrance)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Semantics(
                button: true,
                label: l10n.back,
                child: NeonBackButton(onTap: widget.onBack),
              ),
              const SizedBox(width: 16),
              Text(
                l10n.menuAchievementsAlt,
                style: const TextStyle(
                  color: Colors.cyanAccent,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                  letterSpacing: 3,
                  shadows: [Shadow(color: Colors.cyanAccent, blurRadius: 8)],
                ),
              ),
              const Spacer(),
              // Completion indicator. Only the border alpha and progress-ring
              // glow read the repeating glow controller, so wrap just this
              // subtree in a narrow AnimatedBuilder instead of rebuilding the
              // whole header every glow frame.
              AnimatedBuilder(
                animation: _glowController,
                builder: (context, _) {
                  final glow = _glowController.value;
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.cyanAccent.withValues(
                          alpha: 0.3 + glow * 0.15,
                        ),
                      ),
                      gradient: LinearGradient(
                        colors: [
                          Colors.cyanAccent.withValues(alpha: 0.08),
                          Colors.cyanAccent.withValues(alpha: 0.02),
                        ],
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Mini progress ring
                        SizedBox(
                          width: 18,
                          height: 18,
                          child: CustomPaint(
                            painter: _ProgressRingPainter(
                              progress: completionPct,
                              color: Colors.cyanAccent,
                              glow: glow,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '$unlocked / $total',
                          style: TextStyle(
                            color: Colors.cyanAccent,
                            fontSize: 12,
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(
                                color: Colors.cyanAccent.withValues(alpha: 0.3),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryHeader(
    String title,
    Color color,
    IconData icon,
    double entrance,
    double delay,
    String category,
  ) {
    final catEntrance = (delay >= 1.0
        ? 1.0
        : ((entrance - delay) / (1.0 - delay)).clamp(0.0, 1.0));
    // Use the pre-built category list from initState to avoid re-filtering
    // allAchievements on every AnimatedBuilder frame.
    final catAchievements = _achievementsByCategory[category]!;
    final catUnlockedCount = catAchievements
        .where((a) => _unlockedCache[a.id] == true)
        .length;
    final catPct = catAchievements.isNotEmpty
        ? catUnlockedCount / catAchievements.length
        : 0.0;

    return Opacity(
      opacity: catEntrance,
      child: Transform.translate(
        offset: Offset(-20 * (1 - catEntrance), 0),
        child: Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 8),
          child: Row(
            children: [
              // Category icon
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(alpha: 0.15),
                  border: Border.all(color: color.withValues(alpha: 0.4)),
                ),
                child: Icon(icon, color: color, size: 12),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: color.withValues(alpha: 0.9),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                  letterSpacing: 4,
                  shadows: [
                    Shadow(color: color.withValues(alpha: 0.3), blurRadius: 4),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Category progress bar
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: Stack(
                    children: [
                      Container(
                        height: 2,
                        color: Colors.white.withValues(alpha: 0.05),
                      ),
                      FractionallySizedBox(
                        widthFactor: catPct,
                        child: Container(
                          height: 2,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [color, color.withValues(alpha: 0.4)],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: color.withValues(alpha: 0.3),
                                blurRadius: 3,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$catUnlockedCount/${catAchievements.length}',
                style: TextStyle(
                  color: color.withValues(alpha: 0.5),
                  fontSize: 9,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAchievementTile(
    AchievementDef achievement,
    Color categoryColor,
    double entrance,
    double delay,
    AppLocalizations l10n,
  ) {
    final tileEntrance = (delay >= 1.0
        ? 1.0
        : ((entrance - delay) / (1.0 - delay)).clamp(0.0, 1.0));
    final unlocked = _unlockedCache[achievement.id] ?? false;
    final progress = _progressCache[achievement.id] ?? 0;
    final progressPct = achievement.target > 0
        ? (progress / achievement.target).clamp(0.0, 1.0)
        : 0.0;

    final accentColor = unlocked ? Colors.greenAccent : categoryColor;
    final tileName = achievementName(achievement.id, l10n);
    // Accessibility-only state suffix. No 'locked/unlocked' ARB string pair
    // exists, so use literal text here rather than adding new l10n keys.
    final tileStateLabel = unlocked ? 'Unlocked' : 'Locked';

    return Semantics(
      label: '$tileName ($tileStateLabel)',
      enabled: unlocked,
      child: Opacity(
        opacity: tileEntrance,
        child: Transform.translate(
          offset: Offset(0, 10 * (1 - tileEntrance)),
          // Only the decoration (border / gradient / shadow alpha on unlocked
          // tiles) reads the repeating glow controller. Wrap just this tile's
          // decoration in a narrow AnimatedBuilder; the inner Row content is
          // passed via `child` so it is built once and reused across glow
          // frames instead of rebuilding with the whole screen.
          child: AnimatedBuilder(
            animation: _glowController,
            child: Row(
              children: [
                // Icon circle
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: unlocked
                          ? [
                              Colors.greenAccent.withValues(alpha: 0.2),
                              Colors.greenAccent.withValues(alpha: 0.05),
                            ]
                          : [
                              Colors.white.withValues(alpha: 0.06),
                              Colors.white.withValues(alpha: 0.02),
                            ],
                    ),
                    border: Border.all(
                      color: unlocked
                          ? Colors.greenAccent.withValues(alpha: 0.4)
                          : Colors.white.withValues(alpha: 0.1),
                      width: 1.5,
                    ),
                    boxShadow: unlocked
                        ? [
                            BoxShadow(
                              color: Colors.greenAccent.withValues(alpha: 0.15),
                              blurRadius: 6,
                            ),
                          ]
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      unlocked ? achievement.icon : '?',
                      style: TextStyle(
                        fontSize: unlocked ? 18 : 16,
                        color: unlocked ? null : Colors.white38,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        achievementName(achievement.id, l10n),
                        style: TextStyle(
                          color: unlocked ? Colors.greenAccent : Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'monospace',
                          shadows: unlocked
                              ? [
                                  Shadow(
                                    color: Colors.greenAccent.withValues(
                                      alpha: 0.3,
                                    ),
                                    blurRadius: 4,
                                  ),
                                ]
                              : null,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        achievementDesc(achievement.id, l10n),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 10,
                          fontFamily: 'monospace',
                        ),
                      ),
                      if (!unlocked && achievement.target > 1) ...[
                        const SizedBox(height: 6),
                        // Animated progress bar
                        ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: Stack(
                            children: [
                              Container(
                                height: 4,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.06),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                              FractionallySizedBox(
                                widthFactor: progressPct,
                                child: Container(
                                  height: 4,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(3),
                                    gradient: LinearGradient(
                                      colors: [
                                        accentColor,
                                        accentColor.withValues(alpha: 0.6),
                                      ],
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: accentColor.withValues(
                                          alpha: 0.4,
                                        ),
                                        blurRadius: 4,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$progress / ${achievement.target}',
                          style: TextStyle(
                            color: accentColor.withValues(alpha: 0.4),
                            fontSize: 9,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Reward badge
                if (achievement.reward > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: unlocked
                            ? Colors.greenAccent.withValues(alpha: 0.4)
                            : const Color(0xFFFFD700).withValues(alpha: 0.3),
                      ),
                      gradient: LinearGradient(
                        colors: unlocked
                            ? [
                                Colors.greenAccent.withValues(alpha: 0.1),
                                Colors.greenAccent.withValues(alpha: 0.03),
                              ]
                            : [
                                const Color(0xFFFFD700).withValues(alpha: 0.08),
                                const Color(0xFFFFD700).withValues(alpha: 0.02),
                              ],
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          unlocked ? Icons.check_circle_rounded : Icons.diamond,
                          color: unlocked
                              ? Colors.greenAccent
                              : const Color(0xFFFFD700),
                          size: 12,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${achievement.reward}',
                          style: TextStyle(
                            color: unlocked
                                ? Colors.greenAccent
                                : const Color(0xFFFFD700),
                            fontSize: 11,
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            builder: (context, child) {
              final glow = _glowController.value;
              return Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: unlocked
                        ? Colors.greenAccent.withValues(
                            alpha: 0.3 + glow * 0.15,
                          )
                        : Colors.white.withValues(alpha: 0.06),
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: unlocked
                        ? [
                            Colors.greenAccent.withValues(
                              alpha: 0.06 + glow * 0.02,
                            ),
                            Colors.greenAccent.withValues(alpha: 0.01),
                          ]
                        : [
                            Colors.white.withValues(alpha: 0.02),
                            Colors.transparent,
                          ],
                  ),
                  boxShadow: unlocked
                      ? [
                          BoxShadow(
                            color: Colors.greenAccent.withValues(
                              alpha: 0.05 + glow * 0.03,
                            ),
                            blurRadius: 8,
                          ),
                        ]
                      : null,
                ),
                child: child,
              );
            },
          ),
        ),
      ),
    );
  }
}

// ==================== PROGRESS RING ====================
class _ProgressRingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double glow;

  _ProgressRingPainter({
    required this.progress,
    required this.color,
    required this.glow,
  });

  // Paint cache: evita alloc per frame durante glow/entrance animation.
  static final Paint _bgPaint = Paint()
    ..color = Colors.white.withValues(alpha: 0.1)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2;
  static final Paint _arcPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2
    ..strokeCap = StrokeCap.round;
  static final Paint _glowPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2
    ..strokeCap = StrokeCap.round
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 1;

    // Background ring
    canvas.drawCircle(center, radius, _bgPaint);

    // Progress arc
    _arcPaint.color = color;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      2 * pi * progress,
      false,
      _arcPaint,
    );

    // Glow
    _glowPaint.color = color.withValues(alpha: 0.3 + glow * 0.2);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      2 * pi * progress,
      false,
      _glowPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ProgressRingPainter old) =>
      old.progress != progress || old.glow != glow;
}
