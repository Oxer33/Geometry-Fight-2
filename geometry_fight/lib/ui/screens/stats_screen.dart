import 'dart:async';
import 'package:flutter/material.dart';
import '../../data/save_data.dart';
import '../../data/achievements.dart';
import '../../l10n/generated/app_localizations.dart';
import '../widgets/neon_back_button.dart';

/// Localized label for a game-mode key. Falls back to upper-cased raw key if
/// id is unknown (defensive — preserves render path when new modes ship
/// without ARB updates).
String _statsModeLabel(String key, AppLocalizations l10n) {
  switch (key) {
    case 'classic':
      return l10n.modeClassic;
    case 'bossRush':
      return l10n.modeBossRush;
    case 'survival':
      return l10n.modeSurvival;
    case 'timeAttack':
      return l10n.modeTimeAttack;
    case 'zenMode':
      return l10n.modeZen;
    case 'tunnel':
      return l10n.modeTunnel;
    case 'dailyChallenge':
      return l10n.modeDailyChallenge;
    case 'pacifist':
      return l10n.modePacifist;
    case 'waves':
      return l10n.modeWaves;
    case 'gravityInferno':
      return l10n.modeGravityInferno;
    default:
      return key.toUpperCase();
  }
}

class StatsScreen extends StatefulWidget {
  final VoidCallback onBack;

  const StatsScreen({super.key, required this.onBack});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen>
    with TickerProviderStateMixin {
  late AnimationController _entranceController;
  late AnimationController _counterController;
  late AnimationController _glowController;
  Timer? _counterDelay;

  // Cache save data once — avoid 60x/sec deserialization
  late final SaveData _saveData;
  late final Map<String, dynamic> _stats;
  // Cache achievement counters (erano Hive read per-frame dentro builder).
  late final int _achUnlocked;
  late final int _achTotal;

  final ScrollController _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();

    _saveData = SaveManager.load();
    _stats = _saveData.stats;
    _achUnlocked = AchievementManager.unlockedCount();
    _achTotal = AchievementManager.totalCount();

    _entranceController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..forward();

    _counterController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _glowController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    )..repeat(reverse: true);

    _counterDelay = Timer(const Duration(milliseconds: 300), () {
      if (mounted) _counterController.forward();
    });
  }

  @override
  void dispose() {
    _counterDelay?.cancel();
    _entranceController.dispose();
    _counterController.dispose();
    _glowController.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final saveData = _saveData;
    final stats = _stats;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: AnimatedBuilder(
          animation: Listenable.merge([
            _entranceController,
            _counterController,
            _glowController,
          ]),
          builder: (context, _) {
            final entrance = _entranceController.value;
            final counter = Curves.easeOutCubic.transform(
                _counterController.value);
            final glow = _glowController.value;

            return Column(
              children: [
                // Header
                _buildHeader(l10n, entrance),

                // Stats list
                Expanded(
                  child: RawScrollbar(
                    controller: _scrollCtrl,
                    thumbVisibility: true,
                    trackVisibility: true,
                    thickness: 10,
                    radius: const Radius.circular(5),
                    thumbColor: const Color(0xFF00FFFF),
                    trackColor: const Color(0x3300FFFF),
                    trackBorderColor: const Color(0x8800FFFF),
                    child: SingleChildScrollView(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSection(l10n.statsSectionGeneral, Colors.cyanAccent, entrance, 0.0, [
                          _StatData(l10n.statsGamesPlayed, '${_animInt(stats['gamesPlayed'] ?? 0, counter)}', Icons.videogame_asset_rounded, Colors.cyanAccent),
                          _StatData(l10n.statsTotalPlaytime, _formatPlaytime(saveData.totalPlaytime), Icons.timer_rounded, Colors.cyanAccent),
                          _StatData(l10n.statsTotalGoldEarned, '${_animInt(stats['totalGoldEarned'] ?? saveData.goldGeoms, counter)}', Icons.diamond_rounded, const Color(0xFFFFD700)),
                          _StatData(l10n.statsCurrentGold, '${_animInt(saveData.goldGeoms, counter)}', Icons.account_balance_wallet_rounded, const Color(0xFFFFD700)),
                        ], glow),

                        const SizedBox(height: 16),

                        _buildSection(l10n.statsSectionCombat, const Color(0xFFFF4466), entrance, 0.1, [
                          _StatData(l10n.statsEnemiesKilled, _animFormatNumber(stats['totalKills'] ?? 0, counter), Icons.local_fire_department_rounded, const Color(0xFFFF4466)),
                          _StatData(l10n.statsBossesDefeated, '${_animInt(stats['totalBosses'] ?? 0, counter)}', Icons.shield_rounded, const Color(0xFFCC00FF)),
                          _StatData(l10n.statsBombsUsed, '${_animInt(stats['totalBombs'] ?? 0, counter)}', Icons.flash_on_rounded, Colors.orangeAccent),
                          _StatData(l10n.statsPowerUpsCollected, '${_animInt(stats['totalPowerUps'] ?? 0, counter)}', Icons.bolt_rounded, Colors.yellowAccent),
                          _StatData(l10n.statsGeomsCollected, _animFormatNumber(stats['totalGeoms'] ?? 0, counter), Icons.hexagon_rounded, Colors.cyanAccent),
                        ], glow),

                        const SizedBox(height: 16),

                        _buildSection(l10n.statsSectionRecords, const Color(0xFFFFD700), entrance, 0.2, [
                          _StatData(l10n.statsBestScore, _animFormatNumber(_bestScore(saveData), counter), Icons.emoji_events_rounded, const Color(0xFFFFD700)),
                          _StatData(l10n.statsHighestWave, '${_animInt(stats['maxWave'] ?? 0, counter)}', Icons.waves_rounded, Colors.cyanAccent),
                          _StatData(l10n.statsMaxMultiplier, '${_animInt(stats['maxMultiplier'] ?? 0, counter)}x', Icons.close_fullscreen_rounded, const Color(0xFFCC00FF)),
                          _StatData(l10n.statsMaxSessionKills, '${_animInt(stats['maxSessionKills'] ?? 0, counter)}', Icons.whatshot_rounded, const Color(0xFFFF4466)),
                          _StatData(l10n.statsMaxPerfectStreak, '${_animInt(stats['maxPerfectStreak'] ?? 0, counter)}', Icons.auto_awesome_rounded, Colors.greenAccent),
                        ], glow),

                        const SizedBox(height: 16),

                        _buildSection(l10n.statsSectionAchievements, Colors.greenAccent, entrance, 0.3, [
                          _StatData(l10n.statsAchievementsUnlocked, '$_achUnlocked / $_achTotal', Icons.military_tech_rounded, Colors.greenAccent,
                            progress: _achTotal > 0 ? _achUnlocked / _achTotal : 0.0),
                        ], glow),

                        if (saveData.highscores.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          _buildSection(l10n.statsSectionScoresByMode, Colors.purpleAccent, entrance, 0.4,
                            saveData.highscores.entries.map((e) =>
                              _StatData(_statsModeLabel(e.key, l10n), _animFormatNumber(e.value, counter), Icons.leaderboard_rounded, Colors.purpleAccent),
                            ).toList(),
                          glow),
                        ],

                        const SizedBox(height: 32),
                      ],
                    ),
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

  Widget _buildHeader(AppLocalizations l10n, double entrance) {
    return Opacity(
      opacity: entrance,
      child: Transform.translate(
        offset: Offset(0, -20 * (1 - entrance)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              NeonBackButton(onTap: widget.onBack),
              const SizedBox(width: 16),
              Text(
                l10n.statsTitle,
                style: const TextStyle(
                  color: Colors.cyanAccent,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                  letterSpacing: 3,
                  shadows: [Shadow(color: Colors.cyanAccent, blurRadius: 8)],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title, Color color, double entrance, double delay,
      List<_StatData> stats, double glow) {
    final sectionEntrance = delay >= 1.0
        ? 1.0
        : ((entrance - delay) / (1.0 - delay)).clamp(0.0, 1.0);

    return Opacity(
      opacity: sectionEntrance,
      child: Transform.translate(
        offset: Offset(0, 20 * (1 - sectionEntrance)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section header with glowing line
            Row(
              children: [
                Container(
                  width: 3,
                  height: 14,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(2),
                    boxShadow: [
                      BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 4),
                    ],
                  ),
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
                    shadows: [Shadow(color: color.withValues(alpha: 0.3), blurRadius: 4)],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    height: 1,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          color.withValues(alpha: 0.3),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...stats.map((s) => _buildStatTile(s, color, glow)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatTile(_StatData data, Color sectionColor, double glow) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            data.color.withValues(alpha: 0.04 + glow * 0.02),
            Colors.transparent,
          ],
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Icon in colored circle
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: data.color.withValues(alpha: 0.1),
                  border: Border.all(
                    color: data.color.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Icon(data.icon, color: data.color, size: 14),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  data.label,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 12,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
              Text(
                data.value,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                  shadows: [
                    Shadow(
                      color: data.color.withValues(alpha: 0.3 + glow * 0.2),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
            ],
          ),
          // Optional progress bar
          if (data.progress != null) ...[
            const SizedBox(height: 8),
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
                    widthFactor: data.progress!.clamp(0.0, 1.0),
                    child: Container(
                      height: 4,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(3),
                        gradient: LinearGradient(
                          colors: [
                            data.color,
                            data.color.withValues(alpha: 0.6),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: data.color.withValues(alpha: 0.4),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  int _animInt(int target, double progress) {
    return (target * progress).round();
  }

  String _animFormatNumber(int target, double progress) {
    final n = (target * progress).round();
    return _formatNumber(n);
  }

  int _bestScore(SaveData data) {
    if (data.highscores.isEmpty) return 0;
    return data.highscores.values.reduce((a, b) => a > b ? a : b);
  }

  String _formatPlaytime(int totalSeconds) {
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final secs = totalSeconds % 60;
    if (hours > 0) return '${hours}h ${minutes}m';
    if (minutes > 0) return '${minutes}m ${secs}s';
    return '${secs}s';
  }

  String _formatNumber(int n) {
    if (n >= 1000000000) return '${(n / 1000000000).toStringAsFixed(1)}B';
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 10000) return '${n ~/ 1000}K';
    return '$n';
  }
}

// ==================== DATA CLASS ====================
class _StatData {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final double? progress;

  _StatData(this.label, this.value, this.icon, this.color, {this.progress});
}

