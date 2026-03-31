import 'dart:math';
import 'package:flutter/material.dart';
import '../../data/achievements.dart';

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

  static const _categories = ['combat', 'score', 'progress', 'mastery', 'special'];
  static const _categoryNames = {
    'combat': 'COMBATTIMENTO',
    'score': 'PUNTEGGIO',
    'progress': 'PROGRESSO',
    'mastery': 'MAESTRIA',
    'special': 'SPECIALI',
  };

  // Cached per-category lists (avoid rebuilding every frame)
  late final Map<String, List<AchievementDef>> _achievementsByCategory;
  late final int _unlockedCount;
  late final int _totalCount;
  late final double _completionPct;

  @override
  void initState() {
    super.initState();

    _achievementsByCategory = {
      for (final cat in _categories)
        cat: allAchievements.where((a) => a.category == cat).toList(),
    };
    _unlockedCount = AchievementManager.unlockedCount();
    _totalCount = AchievementManager.totalCount();
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
  void dispose() {
    _entranceController.dispose();
    _glowController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: AnimatedBuilder(
          animation: Listenable.merge([
            _entranceController,
            _glowController,
            _shimmerController,
          ]),
          builder: (context, _) {
            final entrance = _entranceController.value;
            final glow = _glowController.value;

            return Column(
              children: [
                // Header
                _buildHeader(entrance, _unlockedCount, _totalCount, _completionPct, glow),

                // Achievement list
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      for (int ci = 0; ci < _categories.length; ci++) ...[
                        _buildCategoryHeader(
                          _categoryNames[_categories[ci]]!,
                          _categoryColors[_categories[ci]]!,
                          _categoryIcons[_categories[ci]]!,
                          entrance,
                          ci * 0.08,
                          _categories[ci],
                        ),
                        ..._achievementsByCategory[_categories[ci]]!
                            .asMap()
                            .entries
                            .map((entry) => _buildAchievementTile(
                                  entry.value,
                                  _categoryColors[_categories[ci]]!,
                                  entrance,
                                  ci * 0.08 + entry.key * 0.02,
                                  glow,
                                )),
                        const SizedBox(height: 12),
                      ],
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(double entrance, int unlocked, int total,
      double completionPct, double glow) {
    return Opacity(
      opacity: entrance,
      child: Transform.translate(
        offset: Offset(0, -20 * (1 - entrance)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              _NeonBackButton(onTap: widget.onBack),
              const SizedBox(width: 16),
              const Text(
                'ACHIEVEMENT',
                style: TextStyle(
                  color: Colors.cyanAccent,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                  letterSpacing: 3,
                  shadows: [Shadow(color: Colors.cyanAccent, blurRadius: 8)],
                ),
              ),
              const Spacer(),
              // Completion indicator
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.cyanAccent
                        .withValues(alpha: 0.3 + glow * 0.15),
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
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryHeader(String title, Color color, IconData icon,
      double entrance, double delay, String category) {
    final catEntrance = (delay >= 1.0 ? 1.0 : ((entrance - delay) / (1.0 - delay)).clamp(0.0, 1.0));
    final catAchievements =
        allAchievements.where((a) => a.category == category);
    final catUnlocked =
        catAchievements.where((a) => AchievementManager.isUnlocked(a.id));
    final catPct = catAchievements.isNotEmpty
        ? catUnlocked.length / catAchievements.length
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
                    Shadow(color: color.withValues(alpha: 0.3), blurRadius: 4)
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
                                  blurRadius: 3),
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
                '${catUnlocked.length}/${catAchievements.length}',
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
      AchievementDef achievement, Color categoryColor, double entrance,
      double delay, double glow) {
    final tileEntrance = (delay >= 1.0 ? 1.0 : ((entrance - delay) / (1.0 - delay)).clamp(0.0, 1.0));
    final unlocked = AchievementManager.isUnlocked(achievement.id);
    final progress = AchievementManager.getProgress(achievement.id);
    final progressPct = achievement.target > 0
        ? (progress / achievement.target).clamp(0.0, 1.0)
        : 0.0;

    final accentColor = unlocked ? Colors.greenAccent : categoryColor;

    return Opacity(
      opacity: tileEntrance,
      child: Transform.translate(
        offset: Offset(0, 10 * (1 - tileEntrance)),
        child: Container(
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: unlocked
                  ? Colors.greenAccent.withValues(alpha: 0.3 + glow * 0.15)
                  : Colors.white.withValues(alpha: 0.06),
            ),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: unlocked
                  ? [
                      Colors.greenAccent.withValues(alpha: 0.06 + glow * 0.02),
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
                      color: Colors.greenAccent
                          .withValues(alpha: 0.05 + glow * 0.03),
                      blurRadius: 8,
                    ),
                  ]
                : null,
          ),
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
                      achievement.name,
                      style: TextStyle(
                        color: unlocked ? Colors.greenAccent : Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                        shadows: unlocked
                            ? [
                                Shadow(
                                    color: Colors.greenAccent
                                        .withValues(alpha: 0.3),
                                    blurRadius: 4)
                              ]
                            : null,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      achievement.description,
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
                                      color: accentColor.withValues(alpha: 0.4),
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 1;

    // Background ring
    final bgPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(center, radius, bgPaint);

    // Progress arc
    final arcPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      2 * pi * progress,
      false,
      arcPaint,
    );

    // Glow
    arcPaint.color = color.withValues(alpha: 0.3 + glow * 0.2);
    arcPaint.maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      2 * pi * progress,
      false,
      arcPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ProgressRingPainter old) =>
      old.progress != progress || old.glow != glow;
}

// ==================== NEON BACK BUTTON ====================
class _NeonBackButton extends StatelessWidget {
  final VoidCallback onTap;
  const _NeonBackButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.3)),
          color: Colors.cyanAccent.withValues(alpha: 0.05),
        ),
        child:
            const Icon(Icons.arrow_back, color: Colors.cyanAccent, size: 20),
      ),
    );
  }
}
