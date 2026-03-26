import 'package:flutter/material.dart';
import '../../data/leaderboard.dart';
import '../../data/difficulty.dart';

/// Schermata leaderboard locale — classifica per modalità + difficoltà.
/// Due livelli di filtri: modalità di gioco → livello di difficoltà.
class LeaderboardScreen extends StatefulWidget {
  final VoidCallback onBack;

  const LeaderboardScreen({super.key, required this.onBack});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  String _selectedMode = 'classic';
  String _selectedDifficulty = 'normal';

  static const _modes = [
    ('classic', 'CLASSICA', '⚔️'),
    ('bossRush', 'BOSS RUSH', '👑'),
    ('survival', 'SOPRAVVIVENZA', '♾️'),
    ('timeAttack', 'TEMPO', '⏱️'),
    ('zenMode', 'ZEN', '🧘'),
    ('tunnel', 'TUNNEL', '🌀'),
  ];

  static const _difficulties = [
    ('easy', 'FACILE', Color(0xFF44FF44)),
    ('normal', 'NORMALE', Color(0xFF4488FF)),
    ('hard', 'DIFFICILE', Color(0xFFFF8800)),
    ('nightmare', 'INCUBO', Color(0xFFFF2244)),
  ];

  @override
  Widget build(BuildContext context) {
    final entries = LeaderboardManager.getEntries(_selectedMode, _selectedDifficulty);

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──
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

            // ── Filtro Modalità ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _modes.map((m) => _ModeChip(
                    label: m.$2,
                    icon: m.$3,
                    isSelected: _selectedMode == m.$1,
                    onTap: () => setState(() => _selectedMode = m.$1),
                  )).toList(),
                ),
              ),
            ),

            const SizedBox(height: 6),

            // ── Filtro Difficoltà ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: _difficulties.map((d) => Expanded(
                  child: _DifficultyTab(
                    label: d.$2,
                    color: d.$3,
                    isSelected: _selectedDifficulty == d.$1,
                    onTap: () => setState(() => _selectedDifficulty = d.$1),
                  ),
                )).toList(),
              ),
            ),

            const SizedBox(height: 10),

            // ── Intestazione colonne ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  SizedBox(width: 30, child: Text('#', style: _headerStyle)),
                  const SizedBox(width: 8),
                  Expanded(flex: 4, child: Text('PUNTEGGIO', style: _headerStyle)),
                  Expanded(flex: 2, child: Text('WAVE', style: _headerStyle)),
                  Expanded(flex: 2, child: Text('KILLS', style: _headerStyle)),
                  SizedBox(width: 50, child: Text('DATA', style: _headerStyle)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
              child: Divider(color: Colors.white.withValues(alpha: 0.1), height: 1),
            ),

            // ── Lista entries ──
            Expanded(
              child: entries.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '—',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.15),
                              fontSize: 40,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'NESSUN RECORD',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.25),
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'monospace',
                              letterSpacing: 2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Gioca in questa modalità\nper entrare in classifica!',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.15),
                              fontSize: 11,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
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

  TextStyle get _headerStyle => TextStyle(
    color: Colors.white.withValues(alpha: 0.3),
    fontSize: 9,
    fontWeight: FontWeight.bold,
    fontFamily: 'monospace',
    letterSpacing: 1,
  );
}

/// Chip per selezionare la modalità di gioco
class _ModeChip extends StatelessWidget {
  final String label;
  final String icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _ModeChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? Colors.cyanAccent : Colors.white24,
            width: isSelected ? 1.5 : 0.5,
          ),
          color: isSelected
              ? Colors.cyanAccent.withValues(alpha: 0.12)
              : Colors.transparent,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(icon, style: const TextStyle(fontSize: 11)),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.cyanAccent : Colors.white38,
                fontSize: 9,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tab per selezionare la difficoltà — barra sottile con indicatore colorato
class _DifficultyTab extends StatelessWidget {
  final String label;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _DifficultyTab({
    required this.label,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? color.withValues(alpha: 0.6) : Colors.white12,
            width: isSelected ? 1.5 : 0.5,
          ),
          color: isSelected ? color.withValues(alpha: 0.1) : Colors.transparent,
        ),
        child: Column(
          children: [
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isSelected ? color : Colors.white30,
                fontSize: 8,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
                letterSpacing: 0.5,
              ),
            ),
            if (isSelected)
              Container(
                margin: const EdgeInsets.only(top: 3),
                width: 16,
                height: 2,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(1),
                  boxShadow: [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 4)],
                ),
              ),
          ],
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
      margin: const EdgeInsets.only(bottom: 3),
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
            flex: 4,
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
              '${entry.kills}',
              style: TextStyle(
                color: Colors.redAccent.withValues(alpha: 0.6),
                fontSize: 11,
                fontFamily: 'monospace',
              ),
            ),
          ),
          // Data
          SizedBox(
            width: 50,
            child: Text(
              '${entry.date.day}/${entry.date.month}',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.2),
                fontSize: 9,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatScore(int s) {
    if (s >= 1000000000) return '${(s / 1000000000).toStringAsFixed(1)}B';
    if (s >= 1000000) return '${(s / 1000000).toStringAsFixed(1)}M';
    if (s >= 10000) return '${s ~/ 1000}K';
    return '$s';
  }
}
