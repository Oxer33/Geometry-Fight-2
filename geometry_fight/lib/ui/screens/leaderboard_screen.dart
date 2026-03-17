import 'package:flutter/material.dart';
import '../../data/leaderboard.dart';

/// Schermata leaderboard locale con top 10 per ogni modalità.
/// Design neon con tabella stilizzata e filtri per modalità.
class LeaderboardScreen extends StatefulWidget {
  final VoidCallback onBack;

  const LeaderboardScreen({super.key, required this.onBack});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  String _filterMode = 'all';
  String _filterDifficulty = 'all';

  @override
  Widget build(BuildContext context) {
    final entries = _getFilteredEntries();

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
                    onTap: widget.onBack,
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
                    '🏆 CLASSIFICA',
                    style: TextStyle(
                      color: Color(0xFFFFD700),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                      letterSpacing: 3,
                      shadows: [Shadow(color: Color(0xFFFFD700), blurRadius: 8)],
                    ),
                  ),
                ],
              ),
            ),

            // Filtri
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _FilterChip(label: 'TUTTE', isSelected: _filterMode == 'all',
                      onTap: () => setState(() => _filterMode = 'all')),
                  _FilterChip(label: 'CLASSICA', isSelected: _filterMode == 'classic',
                      onTap: () => setState(() => _filterMode = 'classic')),
                  _FilterChip(label: 'SURVIVAL', isSelected: _filterMode == 'survival',
                      onTap: () => setState(() => _filterMode = 'survival')),
                  _FilterChip(label: 'BOSS', isSelected: _filterMode == 'bossRush',
                      onTap: () => setState(() => _filterMode = 'bossRush')),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Tabella entries
            Expanded(
              child: entries.isEmpty
                  ? Center(
                      child: Text(
                        'NESSUN RECORD\nGioca per entrare in classifica!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.3),
                          fontSize: 14,
                          fontFamily: 'monospace',
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: entries.length,
                      itemBuilder: (context, index) {
                        return _LeaderboardRow(
                          rank: index + 1,
                          entry: entries[index],
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  List<LeaderboardEntry> _getFilteredEntries() {
    if (_filterMode == 'all') {
      return LeaderboardManager.getAllEntries().take(20).toList();
    }
    // Prendi entries per tutte le difficoltà di questa modalità
    final all = <LeaderboardEntry>[];
    for (final diff in ['easy', 'normal', 'hard', 'nightmare']) {
      all.addAll(LeaderboardManager.getEntries(_filterMode, diff));
    }
    all.sort((a, b) => b.score.compareTo(a.score));
    return all.take(10).toList();
  }
}

/// Chip filtro per la leaderboard
class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.cyanAccent : Colors.white24,
            width: isSelected ? 1.5 : 0.5,
          ),
          color: isSelected
              ? Colors.cyanAccent.withValues(alpha: 0.1)
              : Colors.transparent,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.cyanAccent : Colors.white38,
            fontSize: 10,
            fontWeight: FontWeight.bold,
            fontFamily: 'monospace',
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }
}

/// Riga singola della leaderboard
class _LeaderboardRow extends StatelessWidget {
  final int rank;
  final LeaderboardEntry entry;

  const _LeaderboardRow({required this.rank, required this.entry});

  Color get _rankColor {
    switch (rank) {
      case 1: return const Color(0xFFFFD700); // Oro
      case 2: return const Color(0xFFC0C0C0); // Argento
      case 3: return const Color(0xFFCD7F32); // Bronzo
      default: return Colors.white38;
    }
  }

  String get _rankIcon {
    switch (rank) {
      case 1: return '🥇';
      case 2: return '🥈';
      case 3: return '🥉';
      default: return '$rank';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: rank <= 3 ? _rankColor.withValues(alpha: 0.3) : Colors.white10,
          width: rank <= 3 ? 1 : 0.5,
        ),
        color: rank <= 3
            ? _rankColor.withValues(alpha: 0.05)
            : Colors.white.withValues(alpha: 0.02),
      ),
      child: Row(
        children: [
          // Posizione
          SizedBox(
            width: 30,
            child: Text(
              _rankIcon,
              style: TextStyle(
                color: _rankColor,
                fontSize: rank <= 3 ? 16 : 12,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Score
          Expanded(
            flex: 3,
            child: Text(
              _formatScore(entry.score),
              style: TextStyle(
                color: rank <= 3 ? Colors.white : Colors.white70,
                fontSize: 14,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
                shadows: rank <= 3
                    ? [Shadow(color: _rankColor, blurRadius: 4)]
                    : null,
              ),
            ),
          ),
          // Wave
          Expanded(
            flex: 2,
            child: Text(
              'W${entry.wave}',
              style: TextStyle(
                color: Colors.cyanAccent.withValues(alpha: 0.6),
                fontSize: 11,
                fontFamily: 'monospace',
              ),
            ),
          ),
          // Kills
          Expanded(
            flex: 2,
            child: Text(
              '${entry.kills}K',
              style: TextStyle(
                color: Colors.redAccent.withValues(alpha: 0.6),
                fontSize: 11,
                fontFamily: 'monospace',
              ),
            ),
          ),
          // Difficoltà
          Text(
            entry.difficulty.toUpperCase().substring(0, 3),
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.3),
              fontSize: 9,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  String _formatScore(int s) {
    if (s >= 1000000) return '${(s / 1000000).toStringAsFixed(1)}M';
    if (s >= 1000) return '${(s / 1000).toStringAsFixed(1)}K';
    return '$s';
  }
}
