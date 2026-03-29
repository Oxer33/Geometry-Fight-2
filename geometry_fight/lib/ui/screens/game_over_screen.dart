import 'package:flutter/material.dart';
import '../../data/achievements.dart';

class GameOverScreen extends StatelessWidget {
  final int score;
  final int wave;
  final int geoms;
  final int goldEarned;
  final int kills;
  final int bossKills;
  final List<AchievementDef> newAchievements;
  final VoidCallback onRetry;
  final VoidCallback onQuit;

  const GameOverScreen({
    super.key,
    required this.score,
    required this.wave,
    required this.geoms,
    required this.goldEarned,
    this.kills = 0,
    this.bossKills = 0,
    this.newAchievements = const [],
    required this.onRetry,
    required this.onQuit,
  });

  int _calcPerformanceBonus() {
    int bonus = 0;
    if (kills >= 200) bonus += 50;
    if (kills >= 500) bonus += 100;
    if (wave >= 20) bonus += 50;
    if (wave >= 50) bonus += 150;
    if (bossKills >= 3) bonus += 100;
    if (bossKills >= 5) bonus += 200;
    return bonus;
  }

  @override
  Widget build(BuildContext context) {
    final perfBonus = _calcPerformanceBonus();
    final achievementGold = newAchievements.fold(0, (sum, a) => sum + a.reward);
    final totalGold = goldEarned + perfBonus + achievementGold;

    return Container(
      color: Colors.black.withValues(alpha: 0.85),
      child: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 20),
              const Text(
                'GAME OVER',
                style: TextStyle(
                  color: Colors.redAccent,
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                  letterSpacing: 6,
                  shadows: [Shadow(color: Colors.redAccent, blurRadius: 15)],
                ),
              ),
              const SizedBox(height: 16),

              // Stats
              _StatRow(label: 'SCORE', value: '$score'),
              _StatRow(label: 'WAVE', value: '$wave'),
              _StatRow(label: 'KILLS', value: '$kills'),
              _StatRow(label: 'BOSS', value: '$bossKills'),
              _StatRow(label: 'GEOMS', value: '$geoms'),

              const SizedBox(height: 10),

              // Gold earned
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                decoration: BoxDecoration(
                  border: Border.all(
                      color: const Color(0xFFFFD700).withValues(alpha: 0.5)),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.diamond,
                            color: Color(0xFFFFD700), size: 20),
                        const SizedBox(width: 8),
                        Text(
                          '+$totalGold GOLD GEOMS',
                          style: const TextStyle(
                            color: Color(0xFFFFD700),
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                    if (perfBonus > 0 || achievementGold > 0) ...[
                      const SizedBox(height: 4),
                      Text(
                        '$goldEarned base${perfBonus > 0 ? ' + $perfBonus bonus' : ''}${achievementGold > 0 ? ' + $achievementGold achievement' : ''}',
                        style: TextStyle(
                          color:
                              const Color(0xFFFFD700).withValues(alpha: 0.6),
                          fontSize: 10,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Performance badges
              if (perfBonus > 0) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  alignment: WrapAlignment.center,
                  children: [
                    if (kills >= 200)
                      _BonusBadge(
                          text: 'KILLER', color: Colors.orangeAccent),
                    if (kills >= 500)
                      _BonusBadge(
                          text: 'MASSACRO', color: Colors.redAccent),
                    if (wave >= 20)
                      _BonusBadge(
                          text: 'PERSISTENTE', color: Colors.cyanAccent),
                    if (wave >= 50)
                      _BonusBadge(
                          text: 'VETERANO', color: Colors.purpleAccent),
                    if (bossKills >= 3)
                      _BonusBadge(
                          text: 'BOSS HUNTER', color: Colors.amberAccent),
                    if (bossKills >= 5)
                      _BonusBadge(
                          text: 'REGICIDA', color: Colors.amber),
                  ],
                ),
              ],

              // New achievements
              if (newAchievements.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(
                        color: Colors.greenAccent.withValues(alpha: 0.5)),
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.greenAccent.withValues(alpha: 0.05),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'NUOVO ACHIEVEMENT!',
                        style: TextStyle(
                          color: Colors.greenAccent,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'monospace',
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...newAchievements.map((a) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(a.icon,
                                    style: const TextStyle(fontSize: 16)),
                                const SizedBox(width: 8),
                                Text(
                                  a.name,
                                  style: const TextStyle(
                                    color: Colors.greenAccent,
                                    fontSize: 12,
                                    fontFamily: 'monospace',
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (a.reward > 0) ...[
                                  const SizedBox(width: 8),
                                  Text(
                                    '+${a.reward}',
                                    style: const TextStyle(
                                      color: Color(0xFFFFD700),
                                      fontSize: 11,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                  const SizedBox(width: 2),
                                  const Icon(Icons.diamond,
                                      color: Color(0xFFFFD700), size: 10),
                                ],
                              ],
                            ),
                          )),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 20),

              // Buttons
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _GameOverButton(
                    text: 'RIPROVA',
                    color: Colors.cyanAccent,
                    onTap: onRetry,
                  ),
                  const SizedBox(width: 16),
                  _GameOverButton(
                    text: 'ESCI',
                    color: Colors.white70,
                    onTap: onQuit,
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _BonusBadge extends StatelessWidget {
  final String text;
  final Color color;
  const _BonusBadge({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        border: Border.all(color: color.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(4),
        color: color.withValues(alpha: 0.1),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontFamily: 'monospace',
          fontWeight: FontWeight.bold,
          letterSpacing: 1,
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;

  const _StatRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 14,
                fontFamily: 'monospace',
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}

class _GameOverButton extends StatelessWidget {
  final String text;
  final Color color;
  final VoidCallback onTap;

  const _GameOverButton({
    required this.text,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 180,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: color, width: 1.5),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: color,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            fontFamily: 'monospace',
            letterSpacing: 3,
          ),
        ),
      ),
    );
  }
}
