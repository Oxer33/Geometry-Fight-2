import 'package:flutter/material.dart';
import '../../data/achievements.dart';

class AchievementsScreen extends StatelessWidget {
  final VoidCallback onBack;

  const AchievementsScreen({super.key, required this.onBack});

  @override
  Widget build(BuildContext context) {
    final categories = ['combat', 'score', 'progress', 'mastery', 'special'];
    final categoryNames = {
      'combat': 'COMBATTIMENTO',
      'score': 'PUNTEGGIO',
      'progress': 'PROGRESSO',
      'mastery': 'MAESTRIA',
      'special': 'SPECIALI',
    };

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: onBack,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white24),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.arrow_back, color: Colors.white54, size: 20),
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Text(
                    'ACHIEVEMENT',
                    style: TextStyle(
                      color: Colors.cyanAccent,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                      letterSpacing: 3,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.3)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${AchievementManager.unlockedCount()} / ${AchievementManager.totalCount()}',
                      style: const TextStyle(
                        color: Colors.cyanAccent,
                        fontSize: 12,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Achievement list
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  for (final category in categories) ...[
                    Padding(
                      padding: const EdgeInsets.only(top: 8, bottom: 8),
                      child: Text(
                        categoryNames[category]!,
                        style: TextStyle(
                          color: Colors.cyanAccent.withValues(alpha: 0.7),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'monospace',
                          letterSpacing: 4,
                        ),
                      ),
                    ),
                    ...allAchievements
                        .where((a) => a.category == category)
                        .map((a) => _AchievementTile(achievement: a)),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AchievementTile extends StatelessWidget {
  final AchievementDef achievement;
  const _AchievementTile({required this.achievement});

  @override
  Widget build(BuildContext context) {
    final unlocked = AchievementManager.isUnlocked(achievement.id);
    final progress = AchievementManager.getProgress(achievement.id);
    final progressPct = (progress / achievement.target).clamp(0.0, 1.0);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(
          color: unlocked
              ? Colors.greenAccent.withValues(alpha: 0.5)
              : Colors.white12,
        ),
        borderRadius: BorderRadius.circular(8),
        color: unlocked
            ? Colors.greenAccent.withValues(alpha: 0.05)
            : Colors.white.withValues(alpha: 0.02),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: unlocked
                  ? Colors.greenAccent.withValues(alpha: 0.15)
                  : Colors.white.withValues(alpha: 0.05),
              border: Border.all(
                color: unlocked ? Colors.greenAccent.withValues(alpha: 0.3) : Colors.white12,
              ),
            ),
            child: Center(
              child: Text(
                unlocked ? achievement.icon : '🔒',
                style: TextStyle(fontSize: unlocked ? 18 : 14),
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
                  // Progress bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: progressPct,
                      backgroundColor: Colors.white12,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.cyanAccent.withValues(alpha: 0.7),
                      ),
                      minHeight: 3,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$progress / ${achievement.target}',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.3),
                      fontSize: 9,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Reward
          if (achievement.reward > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                border: Border.all(
                  color: unlocked
                      ? Colors.greenAccent.withValues(alpha: 0.3)
                      : const Color(0xFFFFD700).withValues(alpha: 0.3),
                ),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    unlocked ? Icons.check : Icons.diamond,
                    color: unlocked ? Colors.greenAccent : const Color(0xFFFFD700),
                    size: 12,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${achievement.reward}',
                    style: TextStyle(
                      color: unlocked ? Colors.greenAccent : const Color(0xFFFFD700),
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
    );
  }
}
