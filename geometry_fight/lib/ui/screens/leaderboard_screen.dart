import 'package:flutter/material.dart';
import '../../data/leaderboard.dart';
import '../../l10n/generated/app_localizations.dart';
import '../widgets/neon_back_button.dart';

/// Schermata leaderboard locale — classifica per modalità + difficoltà.
/// Due livelli di filtri: modalità di gioco → livello di difficoltà.
class LeaderboardScreen extends StatefulWidget {
  final VoidCallback onBack;

  const LeaderboardScreen({super.key, required this.onBack});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen>
    with TickerProviderStateMixin {
  String _selectedMode = 'classic';
  String _selectedDifficulty = 'normal';
  // Cache: evita deserializzazione Hive per-frame dentro AnimatedBuilder.
  // Refresh solo quando filtri cambiano.
  late List<LeaderboardEntry> _cachedEntries;

  late AnimationController _entranceController;
  late AnimationController _glowController;

  final ScrollController _modeCtrl = ScrollController();
  final ScrollController _entriesCtrl = ScrollController();

  void _refreshEntries() {
    _cachedEntries =
        LeaderboardManager.getEntries(_selectedMode, _selectedDifficulty);
  }

  List<(String, String, IconData, Color)> _modes(AppLocalizations l10n) => [
        ('classic', l10n.modeClassic, Icons.bolt_rounded, const Color(0xFF00FFFF)),
        ('bossRush', l10n.modeBossRush, Icons.shield_rounded, const Color(0xFFCC00FF)),
        ('survival', l10n.modeSurvival, Icons.all_inclusive_rounded, const Color(0xFFFF4466)),
        ('timeAttack', l10n.modeTimeAttack, Icons.timer_rounded, const Color(0xFFFF8800)),
        ('zenMode', l10n.modeZen, Icons.self_improvement_rounded, const Color(0xFF44FF44)),
        ('tunnel', l10n.modeTunnel, Icons.rotate_90_degrees_ccw_rounded, const Color(0xFF4488FF)),
        ('dailyChallenge', l10n.modeDailyChallenge, Icons.calendar_today_rounded, const Color(0xFFFFD700)),
        ('pacifist', l10n.modePacifist, Icons.spa_outlined, const Color(0xFF77FFD4)),
        ('waves', l10n.modeWaves, Icons.change_history, const Color(0xFFFF3344)),
        ('gravityInferno', l10n.modeGravityInferno, Icons.blur_circular, const Color(0xFF9933FF)),
        ('snake', l10n.modeSnake, Icons.timeline_rounded, const Color(0xFF66FF66)),
      ];

  List<(String, String, Color)> _difficulties(AppLocalizations l10n) => [
        ('easy', l10n.diffEasy, const Color(0xFF44FF44)),
        ('normal', l10n.diffNormal, const Color(0xFF4488FF)),
        ('hard', l10n.diffHard, const Color(0xFFFF8800)),
        ('nightmare', l10n.diffNightmare, const Color(0xFFFF2244)),
      ];

  @override
  void initState() {
    super.initState();
    _refreshEntries();
    _entranceController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..forward();

    _glowController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _glowController.dispose();
    _modeCtrl.dispose();
    _entriesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final entries = _cachedEntries;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: AnimatedBuilder(
          animation: Listenable.merge([_entranceController, _glowController]),
          builder: (context, _) {
            final entrance = _entranceController.value;
            final glow = _glowController.value;

            return Column(
              children: [
                // ── Header ──
                _buildHeader(l10n, entrance, glow),

                // ── Filtro Modalità ──
                _buildModeFilter(l10n, entrance),

                const SizedBox(height: 6),

                // ── Filtro Difficoltà ──
                _buildDifficultyFilter(l10n, entrance, glow),

                const SizedBox(height: 10),

                // ── Intestazione colonne ──
                _buildColumnHeaders(l10n, entrance),

                // ── Divider ──
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                  child: Opacity(
                    opacity: entrance,
                    child: Container(
                      height: 1,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            const Color(0xFFFFD700).withValues(alpha: 0.2),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // ── Lista entries ──
                Expanded(
                  child: entries.isEmpty
                      ? _buildEmptyState(l10n, entrance, glow)
                      : _buildEntryList(entries, entrance, glow),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(AppLocalizations l10n, double entrance, double glow) {
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
              // Trophy icon with glow
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFFFFD700).withValues(alpha: 0.2 + glow * 0.1),
                      const Color(0xFFFFD700).withValues(alpha: 0.02),
                    ],
                  ),
                  border: Border.all(
                    color: const Color(0xFFFFD700).withValues(alpha: 0.4),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFFD700).withValues(alpha: 0.15 + glow * 0.1),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: const Icon(Icons.emoji_events_rounded,
                    color: Color(0xFFFFD700), size: 16),
              ),
              const SizedBox(width: 10),
              Text(
                l10n.leaderboardTitle,
                style: const TextStyle(
                  color: Color(0xFFFFD700),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                  letterSpacing: 3,
                  shadows: [Shadow(color: Color(0xFFFFD700), blurRadius: 8)],
                ),
              ),
              const Spacer(),
              // Total entries counter
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xFFFFD700).withValues(alpha: 0.2),
                  ),
                  color: const Color(0xFFFFD700).withValues(alpha: 0.05),
                ),
                child: Text(
                  l10n.leaderboardRecords(_cachedEntries.length),
                  style: TextStyle(
                    color: const Color(0xFFFFD700).withValues(alpha: 0.6),
                    fontSize: 10,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModeFilter(AppLocalizations l10n, double entrance) {
    final e = ((entrance - 0.1) / 0.9).clamp(0.0, 1.0);
    // Iter 21 (richiesta utente: "horizontal scrollbar overlap il border
    // ciano del tab selezionato"). Rimosso il `RawScrollbar` wrapper sui
    // mode tab — il visual track ciano si sovrapponeva al border ciano
    // del chip selezionato e veniva letto come "underline duplicato".
    // I tab restano scrollabili via swipe / drag orizzontale.
    return Opacity(
      opacity: e,
      child: Transform.translate(
        offset: Offset(-20 * (1 - e), 0),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: SingleChildScrollView(
            controller: _modeCtrl,
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _modes(l10n).map((m) {
                final isSelected = _selectedMode == m.$1;
                return _NeonModeChip(
                  label: m.$2,
                  icon: m.$3,
                  color: m.$4,
                  isSelected: isSelected,
                  onTap: () => setState(() {
                    _selectedMode = m.$1;
                    _refreshEntries();
                  }),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDifficultyFilter(
      AppLocalizations l10n, double entrance, double glow) {
    final e = ((entrance - 0.15) / 0.85).clamp(0.0, 1.0);
    return Opacity(
      opacity: e,
      child: Transform.translate(
        offset: Offset(0, 10 * (1 - e)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: _difficulties(l10n).map((d) {
              final isSelected = _selectedDifficulty == d.$1;
              return Expanded(
                child: _NeonDifficultyTab(
                  label: d.$2,
                  color: d.$3,
                  isSelected: isSelected,
                  onTap: () => setState(() {
                    _selectedDifficulty = d.$1;
                    _refreshEntries();
                  }),
                  glow: isSelected ? glow : 0,
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildColumnHeaders(AppLocalizations l10n, double entrance) {
    final e = ((entrance - 0.2) / 0.8).clamp(0.0, 1.0);
    return Opacity(
      opacity: e * 0.5,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            const SizedBox(width: 30, child: Text('#', style: _headerStyle)),
            const SizedBox(width: 8),
            Expanded(flex: 4, child: Text(l10n.score, style: _headerStyle)),
            Expanded(flex: 2, child: Text(l10n.wave, style: _headerStyle)),
            Expanded(flex: 2, child: Text(l10n.kills, style: _headerStyle)),
            SizedBox(width: 50, child: Text(l10n.columnDate, style: _headerStyle)),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(AppLocalizations l10n, double entrance, double glow) {
    final e = ((entrance - 0.3) / 0.7).clamp(0.0, 1.0);
    return Center(
      child: Opacity(
        opacity: e,
        child: Transform.scale(
          scale: 0.9 + e * 0.1,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Empty trophy with dim glow
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.03),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.06),
                  ),
                ),
                child: Icon(
                  Icons.emoji_events_outlined,
                  color: Colors.white.withValues(alpha: 0.12),
                  size: 30,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                l10n.leaderboardNoRecord,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.25),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                  letterSpacing: 3,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                l10n.leaderboardEmptyHint,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.12),
                  fontSize: 11,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEntryList(
      List<LeaderboardEntry> entries, double entrance, double glow) {
    return RawScrollbar(
      controller: _entriesCtrl,
      thumbVisibility: true,
      trackVisibility: true,
      thickness: 10,
      radius: const Radius.circular(5),
      thumbColor: const Color(0xFF00FFFF),
      trackColor: const Color(0x3300FFFF),
      trackBorderColor: const Color(0x8800FFFF),
      child: ListView.builder(
      controller: _entriesCtrl,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        // Stagger each row slightly
        final rowDelay = 0.25 + index * 0.03;
        final rowEntrance = rowDelay >= 1.0
            ? 1.0
            : ((entrance - rowDelay) / (1.0 - rowDelay)).clamp(0.0, 1.0);

        final entry = entries[index];
        return Opacity(
          key: ValueKey('lb-${entry.date.millisecondsSinceEpoch}-${entry.score}-$index'),
          opacity: rowEntrance,
          child: Transform.translate(
            offset: Offset(0, 15 * (1 - rowEntrance)),
            child: _NeonLeaderboardRow(
              rank: index + 1,
              entry: entry,
              glow: glow,
            ),
          ),
        );
      },
    ),
    );
  }

  // Static const avoids allocating a new TextStyle on every AnimatedBuilder frame.
  static const TextStyle _headerStyle = TextStyle(
        color: Color(0x4DFFFFFF), // equivalent to Colors.white.withValues(alpha: 0.3)
        fontSize: 9,
        fontWeight: FontWeight.bold,
        fontFamily: 'monospace',
        letterSpacing: 1,
      );
}

// ==================== NEON MODE CHIP ====================
class _NeonModeChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _NeonModeChip({
    required this.label,
    required this.icon,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? color.withValues(alpha: 0.6)
                : Colors.white.withValues(alpha: 0.08),
            width: isSelected ? 1.5 : 0.5,
          ),
          gradient: isSelected
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    color.withValues(alpha: 0.12),
                    color.withValues(alpha: 0.04),
                  ],
                )
              : null,
          color: isSelected ? null : Colors.transparent,
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.15),
                    blurRadius: 8,
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? color : Colors.white24,
              size: 12,
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? color : Colors.white30,
                fontSize: 9,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
                letterSpacing: 0.5,
                shadows: isSelected
                    ? [Shadow(color: color.withValues(alpha: 0.3), blurRadius: 4)]
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== NEON DIFFICULTY TAB ====================
class _NeonDifficultyTab extends StatelessWidget {
  final String label;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;
  final double glow;

  const _NeonDifficultyTab({
    required this.label,
    required this.color,
    required this.isSelected,
    required this.onTap,
    required this.glow,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: const EdgeInsets.symmetric(vertical: 7),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? color.withValues(alpha: 0.5 + glow * 0.15)
                : Colors.white.withValues(alpha: 0.06),
            width: isSelected ? 1.5 : 0.5,
          ),
          gradient: isSelected
              ? LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    color.withValues(alpha: 0.1),
                    color.withValues(alpha: 0.03),
                  ],
                )
              : null,
          color: isSelected ? null : Colors.transparent,
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.1 + glow * 0.05),
                    blurRadius: 6,
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isSelected ? color : Colors.white24,
                fontSize: 8,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
                letterSpacing: 0.5,
                shadows: isSelected
                    ? [Shadow(color: color.withValues(alpha: 0.4), blurRadius: 3)]
                    : null,
              ),
            ),
            if (isSelected)
              Container(
                margin: const EdgeInsets.only(top: 4),
                width: 18,
                height: 2,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(1),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.6),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ==================== NEON LEADERBOARD ROW ====================
class _NeonLeaderboardRow extends StatelessWidget {
  final int rank;
  final LeaderboardEntry entry;
  final double glow;

  const _NeonLeaderboardRow({
    required this.rank,
    required this.entry,
    required this.glow,
  });

  Color get _rankColor {
    switch (rank) {
      case 1:
        return const Color(0xFFFFD700); // Oro
      case 2:
        return const Color(0xFFC0C0C0); // Argento
      case 3:
        return const Color(0xFFCD7F32); // Bronzo
      default:
        return Colors.white38;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPodium = rank <= 3;

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isPodium
              ? _rankColor.withValues(alpha: 0.3 + glow * 0.1)
              : Colors.white.withValues(alpha: 0.04),
          width: isPodium ? 1.5 : 0.5,
        ),
        gradient: isPodium
            ? LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  _rankColor.withValues(alpha: 0.06 + glow * 0.02),
                  _rankColor.withValues(alpha: 0.01),
                ],
              )
            : null,
        color: isPodium ? null : Colors.white.withValues(alpha: 0.02),
        boxShadow: isPodium
            ? [
                BoxShadow(
                  color: _rankColor.withValues(alpha: 0.08 + glow * 0.04),
                  blurRadius: 8,
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          // Rank badge
          Container(
            width: 28,
            height: 28,
            decoration: isPodium
                ? BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        _rankColor.withValues(alpha: 0.2),
                        _rankColor.withValues(alpha: 0.05),
                      ],
                    ),
                    border: Border.all(
                      color: _rankColor.withValues(alpha: 0.4),
                    ),
                  )
                : null,
            child: Center(
              child: isPodium
                  ? Icon(
                      rank == 1
                          ? Icons.looks_one_rounded
                          : rank == 2
                              ? Icons.looks_two_rounded
                              : Icons.looks_3_rounded,
                      color: _rankColor,
                      size: 16,
                    )
                  : Text(
                      '$rank',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.3),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 10),

          // Score
          Expanded(
            flex: 4,
            child: Text(
              _formatScore(entry.score),
              style: TextStyle(
                color: isPodium ? Colors.white : Colors.white70,
                fontSize: 15,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
                shadows: isPodium
                    ? [
                        Shadow(
                          color: _rankColor.withValues(alpha: 0.5),
                          blurRadius: 6,
                        ),
                      ]
                    : null,
              ),
            ),
          ),

          // Wave
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Icon(Icons.waves_rounded,
                    color: Colors.cyanAccent.withValues(alpha: 0.4), size: 10),
                const SizedBox(width: 3),
                Text(
                  '${entry.wave}',
                  style: TextStyle(
                    color: Colors.cyanAccent.withValues(alpha: 0.7),
                    fontSize: 11,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),

          // Kills
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Icon(Icons.local_fire_department_rounded,
                    color: const Color(0xFFFF4466).withValues(alpha: 0.4),
                    size: 10),
                const SizedBox(width: 3),
                Text(
                  '${entry.kills}',
                  style: TextStyle(
                    color: const Color(0xFFFF4466).withValues(alpha: 0.7),
                    fontSize: 11,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),

          // Date
          SizedBox(
            width: 50,
            child: Text(
              '${entry.date.day.toString().padLeft(2, '0')}/${entry.date.month.toString().padLeft(2, '0')}',
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
