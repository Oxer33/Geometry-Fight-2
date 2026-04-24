import 'package:flutter/material.dart';
import '../../data/difficulty.dart';
import '../../data/save_data.dart';
import '../widgets/neon_back_button.dart';
import 'modifiers_screen.dart';

/// Schermata di selezione modalità di gioco e difficoltà.
class ModeSelectScreen extends StatefulWidget {
  final VoidCallback onBack;
  final void Function(GameMode mode, Difficulty difficulty) onStart;

  const ModeSelectScreen({
    super.key,
    required this.onBack,
    required this.onStart,
  });

  @override
  State<ModeSelectScreen> createState() => _ModeSelectScreenState();
}

class _ModeSelectScreenState extends State<ModeSelectScreen>
    with TickerProviderStateMixin {
  GameMode _selectedMode = GameMode.classic;
  Difficulty _selectedDifficulty = Difficulty.normal;
  List<String> _activeModifiers = [];
  late final SaveData _saveData;

  late AnimationController _entranceController;
  late AnimationController _glowController;
  late AnimationController _startBtnController;

  @override
  void initState() {
    super.initState();
    _saveData = SaveManager.load();
    // Seed modifiers attivi dal save — prima `_activeModifiers` partiva
    // vuoto, ignorando i modificatori selezionati in sessione precedente.
    _activeModifiers = List<String>.from(_saveData.activeModifiers);

    _entranceController = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    )..forward();

    _glowController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    )..repeat(reverse: true);

    _startBtnController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _glowController.dispose();
    _startBtnController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final saveData = _saveData;
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: AnimatedBuilder(
          animation:
              Listenable.merge([_entranceController, _glowController, _startBtnController]),
          builder: (context, _) {
            final entrance = _entranceController.value;
            final glow = _glowController.value;
            final startPulse = _startBtnController.value;

            return Column(
              children: [
                // Header
                _buildHeader(entrance, glow),

                // Contenuto scrollabile
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // === MODALITÀ DI GIOCO ===
                        _buildSectionLabel('MODALITÀ', Icons.gamepad_rounded,
                            Colors.cyanAccent, entrance, 0.1),
                        const SizedBox(height: 8),
                        _buildModeList(saveData, entrance, glow),

                        const SizedBox(height: 20),

                        // === DIFFICOLTÀ ===
                        _buildSectionLabel('DIFFICOLTÀ', Icons.speed_rounded,
                            const Color(0xFFFF8800), entrance, 0.2),
                        const SizedBox(height: 8),
                        _buildDifficultyList(entrance, glow),

                        const SizedBox(height: 16),

                        // === MODIFICATORI ===
                        _buildModifiersButton(entrance, glow),

                        const SizedBox(height: 16),

                        // === RIEPILOGO ===
                        _buildSummary(entrance, glow),
                      ],
                    ),
                  ),
                ),

                // Pulsante START
                _buildStartButton(entrance, startPulse),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(double entrance, double glow) {
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
              const Text(
                'SELEZIONA MODALITÀ',
                style: TextStyle(
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

  Widget _buildSectionLabel(String title, IconData icon, Color color,
      double entrance, double delay) {
    final e = delay >= 1.0
        ? 1.0
        : ((entrance - delay) / (1.0 - delay)).clamp(0.0, 1.0);
    return Opacity(
      opacity: e,
      child: Transform.translate(
        offset: Offset(-15 * (1 - e), 0),
        child: Row(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: 0.12),
                border: Border.all(color: color.withValues(alpha: 0.4)),
              ),
              child: Icon(icon, color: color, size: 11),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                color: color.withValues(alpha: 0.8),
                fontSize: 11,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
                letterSpacing: 4,
                shadows: [
                  Shadow(color: color.withValues(alpha: 0.3), blurRadius: 4)
                ],
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
      ),
    );
  }

  Widget _buildModeList(SaveData saveData, double entrance, double glow) {
    final e = ((entrance - 0.15) / 0.85).clamp(0.0, 1.0);
    return Opacity(
      opacity: e,
      child: Transform.translate(
        offset: Offset(0, 15 * (1 - e)),
        child: SizedBox(
          height: 105,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: GameMode.values.map((mode) {
              final config = gameModeConfigs[mode]!;
              final isUnlocked = config.unlockCost == 0 ||
                  saveData.unlockedModes.contains(mode.name);
              final isSelected = _selectedMode == mode;
              return _NeonModeCard(
                config: config,
                isSelected: isSelected,
                isUnlocked: isUnlocked,
                glow: glow,
                onTap: isUnlocked
                    ? () => setState(() => _selectedMode = mode)
                    : null,
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildDifficultyList(double entrance, double glow) {
    final e = ((entrance - 0.25) / 0.75).clamp(0.0, 1.0);
    return Opacity(
      opacity: e,
      child: Transform.translate(
        offset: Offset(0, 15 * (1 - e)),
        child: SizedBox(
          height: 85,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: Difficulty.values.map((diff) {
              final config = difficultyConfigs[diff]!;
              final isSelected = _selectedDifficulty == diff;
              return _NeonDifficultyCard(
                config: config,
                difficulty: diff,
                isSelected: isSelected,
                glow: glow,
                onTap: () => setState(() => _selectedDifficulty = diff),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildModifiersButton(double entrance, double glow) {
    final e = ((entrance - 0.35) / 0.65).clamp(0.0, 1.0);
    final hasModifiers = _activeModifiers.isNotEmpty;

    return Opacity(
      opacity: e,
      child: Transform.translate(
        offset: Offset(0, 10 * (1 - e)),
        child: GestureDetector(
          onTap: () {
            showModalBottomSheet(
              context: context,
              backgroundColor: Colors.transparent,
              isScrollControlled: true,
              builder: (_) => ModifiersSheet(
                activeModifiers: _activeModifiers,
                onChanged: (mods) =>
                    setState(() => _activeModifiers = mods),
              ),
            );
          },
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: hasModifiers
                    ? Colors.cyanAccent.withValues(alpha: 0.4 + glow * 0.1)
                    : Colors.white.withValues(alpha: 0.08),
              ),
              gradient: hasModifiers
                  ? LinearGradient(
                      colors: [
                        Colors.cyanAccent.withValues(alpha: 0.06),
                        Colors.cyanAccent.withValues(alpha: 0.02),
                      ],
                    )
                  : null,
              color: hasModifiers ? null : Colors.white.withValues(alpha: 0.02),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.tune_rounded,
                  color: hasModifiers ? Colors.cyanAccent : Colors.white38,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Text(
                  hasModifiers
                      ? 'MODIFICATORI (${_activeModifiers.length})'
                      : 'MODIFICATORI (opzionale)',
                  style: TextStyle(
                    color: hasModifiers ? Colors.cyanAccent : Colors.white38,
                    fontSize: 12,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                    shadows: hasModifiers
                        ? [
                            Shadow(
                                color:
                                    Colors.cyanAccent.withValues(alpha: 0.3),
                                blurRadius: 4)
                          ]
                        : null,
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.chevron_right_rounded,
                  color: hasModifiers
                      ? Colors.cyanAccent.withValues(alpha: 0.5)
                      : Colors.white.withValues(alpha: 0.2),
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummary(double entrance, double glow) {
    final e = ((entrance - 0.4) / 0.6).clamp(0.0, 1.0);
    final modeConfig = gameModeConfigs[_selectedMode]!;
    final diffConfig = difficultyConfigs[_selectedDifficulty]!;
    final diffColor = _diffColor(_selectedDifficulty);

    return Opacity(
      opacity: e,
      child: Transform.translate(
        offset: Offset(0, 10 * (1 - e)),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                diffColor.withValues(alpha: 0.04),
                Colors.transparent,
              ],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(modeConfig.icon, style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 8),
                  Text(
                    '${modeConfig.name} — ${diffConfig.name}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                modeConfig.description,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 10,
                  fontFamily: 'monospace',
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  _summaryChip(Icons.favorite_rounded, 'Vite: ${diffConfig.startingLives}', diffColor),
                  const SizedBox(width: 8),
                  _summaryChip(Icons.flash_on_rounded, 'Bombe: ${diffConfig.startingBombs}', diffColor),
                  const SizedBox(width: 8),
                  _summaryChip(Icons.close_fullscreen_rounded, 'x${diffConfig.scoreMultiplier.toStringAsFixed(0)}', diffColor),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _summaryChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        color: color.withValues(alpha: 0.08),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color.withValues(alpha: 0.6), size: 10),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color.withValues(alpha: 0.7),
              fontSize: 9,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStartButton(double entrance, double pulse) {
    final e = ((entrance - 0.5) / 0.5).clamp(0.0, 1.0);
    return Opacity(
      opacity: e,
      child: Transform.translate(
        offset: Offset(0, 20 * (1 - e)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: GestureDetector(
            onTap: () async {
              _saveData.activeModifiers = _activeModifiers;
              // Await save: modifiers persistono prima della transizione.
              // Prima: fire-and-forget → crash mid-wave perdeva i modifiers.
              await SaveManager.save(_saveData);
              if (!mounted) return;
              widget.onStart(_selectedMode, _selectedDifficulty);
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: Colors.cyanAccent.withValues(alpha: 0.7 + pulse * 0.3),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.cyanAccent
                        .withValues(alpha: 0.15 + pulse * 0.1),
                    blurRadius: 16 + pulse * 8,
                    spreadRadius: -2,
                  ),
                ],
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.cyanAccent.withValues(alpha: 0.12 + pulse * 0.04),
                    Colors.cyanAccent.withValues(alpha: 0.04),
                  ],
                ),
              ),
              child: const Center(
                child: Text(
                  'INIZIA PARTITA',
                  style: TextStyle(
                    color: Colors.cyanAccent,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                    letterSpacing: 4,
                    shadows: [
                      Shadow(color: Colors.cyanAccent, blurRadius: 10),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _diffColor(Difficulty d) {
    switch (d) {
      case Difficulty.easy:
        return Colors.greenAccent;
      case Difficulty.normal:
        return Colors.cyanAccent;
      case Difficulty.hard:
        return Colors.orangeAccent;
      case Difficulty.nightmare:
        return Colors.redAccent;
    }
  }
}

// ==================== NEON MODE CARD ====================
class _NeonModeCard extends StatelessWidget {
  final GameModeConfig config;
  final bool isSelected;
  final bool isUnlocked;
  final double glow;
  final VoidCallback? onTap;

  const _NeonModeCard({
    required this.config,
    required this.isSelected,
    required this.isUnlocked,
    required this.glow,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: 145,
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? Colors.cyanAccent.withValues(alpha: 0.6 + glow * 0.15)
                : isUnlocked
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.white.withValues(alpha: 0.04),
            width: isSelected ? 1.5 : 0.5,
          ),
          gradient: isSelected
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.cyanAccent.withValues(alpha: 0.1),
                    Colors.cyanAccent.withValues(alpha: 0.03),
                  ],
                )
              : null,
          color: isSelected ? null : Colors.white.withValues(alpha: 0.02),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.cyanAccent
                        .withValues(alpha: 0.1 + glow * 0.05),
                    blurRadius: 10,
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(config.icon, style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    config.name,
                    style: TextStyle(
                      color: isUnlocked
                          ? (isSelected ? Colors.cyanAccent : Colors.white)
                          : Colors.white30,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                      shadows: isSelected
                          ? [
                              Shadow(
                                  color: Colors.cyanAccent
                                      .withValues(alpha: 0.3),
                                  blurRadius: 4)
                            ]
                          : null,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              isUnlocked ? config.description : '${config.unlockCost} GG',
              style: TextStyle(
                color: isUnlocked
                    ? Colors.white.withValues(alpha: 0.45)
                    : Colors.orange.withValues(alpha: 0.5),
                fontSize: 9,
                fontFamily: 'monospace',
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            if (!isUnlocked)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Icon(Icons.lock_rounded,
                    color: Colors.white.withValues(alpha: 0.15), size: 12),
              ),
          ],
        ),
      ),
    );
  }
}

// ==================== NEON DIFFICULTY CARD ====================
class _NeonDifficultyCard extends StatelessWidget {
  final DifficultyConfig config;
  final Difficulty difficulty;
  final bool isSelected;
  final double glow;
  final VoidCallback onTap;

  const _NeonDifficultyCard({
    required this.config,
    required this.difficulty,
    required this.isSelected,
    required this.glow,
    required this.onTap,
  });

  Color get _color {
    switch (difficulty) {
      case Difficulty.easy:
        return Colors.greenAccent;
      case Difficulty.normal:
        return Colors.cyanAccent;
      case Difficulty.hard:
        return Colors.orangeAccent;
      case Difficulty.nightmare:
        return Colors.redAccent;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: 125,
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? _color.withValues(alpha: 0.5 + glow * 0.15)
                : Colors.white.withValues(alpha: 0.06),
            width: isSelected ? 1.5 : 0.5,
          ),
          gradient: isSelected
              ? LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    _color.withValues(alpha: 0.1),
                    _color.withValues(alpha: 0.03),
                  ],
                )
              : null,
          color: isSelected ? null : Colors.white.withValues(alpha: 0.02),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: _color.withValues(alpha: 0.1 + glow * 0.05),
                    blurRadius: 8,
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              config.name,
              style: TextStyle(
                color: isSelected ? _color : Colors.white38,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
                shadows: isSelected
                    ? [
                        Shadow(
                            color: _color.withValues(alpha: 0.4),
                            blurRadius: 4)
                      ]
                    : null,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: _color.withValues(alpha: isSelected ? 0.12 : 0.04),
              ),
              child: Text(
                'Score x${config.scoreMultiplier.toStringAsFixed(0)}',
                style: TextStyle(
                  color: _color.withValues(alpha: isSelected ? 0.8 : 0.4),
                  fontSize: 9,
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
