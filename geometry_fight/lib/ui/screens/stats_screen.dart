import 'package:flutter/material.dart';
import '../../data/save_data.dart';
import '../../data/achievements.dart';

class StatsScreen extends StatelessWidget {
  final VoidCallback onBack;

  const StatsScreen({super.key, required this.onBack});

  @override
  Widget build(BuildContext context) {
    final saveData = SaveManager.load();
    final stats = saveData.stats;

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
                    'STATISTICHE',
                    style: TextStyle(
                      color: Colors.cyanAccent,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                      letterSpacing: 3,
                    ),
                  ),
                ],
              ),
            ),

            // Stats list
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionHeader(title: 'GENERALE'),
                    _StatTile(icon: '🕹️', label: 'Partite giocate', value: '${stats['gamesPlayed'] ?? 0}'),
                    _StatTile(icon: '⏱️', label: 'Tempo totale', value: _formatPlaytime(saveData.totalPlaytime)),
                    _StatTile(icon: '🪙', label: 'Gold totale guadagnato', value: '${stats['totalGoldEarned'] ?? saveData.goldGeoms}'),
                    _StatTile(icon: '💰', label: 'Gold attuale', value: '${saveData.goldGeoms}'),

                    const SizedBox(height: 16),
                    _SectionHeader(title: 'COMBATTIMENTO'),
                    _StatTile(icon: '💀', label: 'Nemici uccisi', value: _formatNumber(stats['totalKills'] ?? 0)),
                    _StatTile(icon: '👑', label: 'Boss sconfitti', value: '${stats['totalBosses'] ?? 0}'),
                    _StatTile(icon: '💣', label: 'Bombe usate', value: '${stats['totalBombs'] ?? 0}'),
                    _StatTile(icon: '⚡', label: 'Power-up raccolti', value: '${stats['totalPowerUps'] ?? 0}'),
                    _StatTile(icon: '💠', label: 'Geom raccolti', value: _formatNumber(stats['totalGeoms'] ?? 0)),

                    const SizedBox(height: 16),
                    _SectionHeader(title: 'RECORD'),
                    _StatTile(icon: '🏆', label: 'Punteggio migliore', value: _formatNumber(_bestScore(saveData))),
                    _StatTile(icon: '🌊', label: 'Wave più alta', value: '${stats['maxWave'] ?? 0}'),
                    _StatTile(icon: '🔢', label: 'Moltiplicatore massimo', value: '${stats['maxMultiplier'] ?? 0}x'),
                    _StatTile(icon: '💀', label: 'Max kill in una partita', value: '${stats['maxSessionKills'] ?? 0}'),
                    _StatTile(icon: '✨', label: 'Max wave perfette consecutive', value: '${stats['maxPerfectStreak'] ?? 0}'),

                    const SizedBox(height: 16),
                    _SectionHeader(title: 'ACHIEVEMENT'),
                    _StatTile(
                      icon: '🏅',
                      label: 'Sbloccati',
                      value: '${AchievementManager.unlockedCount()} / ${AchievementManager.totalCount()}',
                    ),

                    const SizedBox(height: 16),
                    _SectionHeader(title: 'PUNTEGGI PER MODALITÀ'),
                    ...saveData.highscores.entries.map((e) =>
                      _StatTile(icon: '📊', label: e.key.toUpperCase(), value: _formatNumber(e.value)),
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
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

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          color: Colors.cyanAccent.withValues(alpha: 0.7),
          fontSize: 12,
          fontWeight: FontWeight.bold,
          fontFamily: 'monospace',
          letterSpacing: 4,
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String icon;
  final String label;
  final String value;
  const _StatTile({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white10),
        borderRadius: BorderRadius.circular(6),
        color: Colors.white.withValues(alpha: 0.02),
      ),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 12,
                fontFamily: 'monospace',
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}
