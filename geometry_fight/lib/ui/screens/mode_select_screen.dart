import 'package:flutter/material.dart';
import '../../data/difficulty.dart';
import '../../data/save_data.dart';

/// Schermata di selezione modalità di gioco e difficoltà.
/// Design neon con card selezionabili e descrizioni.
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

class _ModeSelectScreenState extends State<ModeSelectScreen> {
  GameMode _selectedMode = GameMode.classic;
  Difficulty _selectedDifficulty = Difficulty.normal;

  @override
  Widget build(BuildContext context) {
    final saveData = SaveManager.load();
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // Header con back button
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
                    'SELEZIONA MODALITÀ',
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

            // Contenuto scrollabile
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // === MODALITÀ DI GIOCO ===
                    Text(
                      'MODALITÀ',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 11,
                        fontFamily: 'monospace',
                        letterSpacing: 4,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 100,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: GameMode.values.map((mode) {
                          final config = gameModeConfigs[mode]!;
                          // DEBUG: tutte le modalità sbloccate per test
                          // TODO: rimuovere in produzione
                          const bool kDebugUnlockAll = true;
                          final isUnlocked = kDebugUnlockAll ||
                              config.unlockCost == 0 ||
                              saveData.unlockedModes.contains(mode.name);
                          final isSelected = _selectedMode == mode;
                          return _ModeCard(
                            config: config,
                            isSelected: isSelected,
                            isUnlocked: isUnlocked,
                            onTap: isUnlocked
                                ? () => setState(() => _selectedMode = mode)
                                : null,
                          );
                        }).toList(),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // === DIFFICOLTÀ ===
                    Text(
                      'DIFFICOLTÀ',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 11,
                        fontFamily: 'monospace',
                        letterSpacing: 4,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 80,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: Difficulty.values.map((diff) {
                          final config = difficultyConfigs[diff]!;
                          final isSelected = _selectedDifficulty == diff;
                          return _DifficultyCard(
                            config: config,
                            difficulty: diff,
                            isSelected: isSelected,
                            onTap: () => setState(() => _selectedDifficulty = diff),
                          );
                        }).toList(),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // === RIEPILOGO SELEZIONE ===
                    _SelectionSummary(
                      mode: gameModeConfigs[_selectedMode]!,
                      difficulty: difficultyConfigs[_selectedDifficulty]!,
                    ),
                  ],
                ),
              ),
            ),

            // Pulsante START
            Padding(
              padding: const EdgeInsets.all(16),
              child: GestureDetector(
                onTap: () => widget.onStart(_selectedMode, _selectedDifficulty),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.cyanAccent, width: 2),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.cyanAccent.withValues(alpha: 0.3),
                        blurRadius: 16,
                      ),
                    ],
                    gradient: LinearGradient(
                      colors: [
                        Colors.cyanAccent.withValues(alpha: 0.1),
                        Colors.cyanAccent.withValues(alpha: 0.05),
                      ],
                    ),
                  ),
                  child: const Center(
                    child: Text(
                      '▶  INIZIA PARTITA',
                      style: TextStyle(
                        color: Colors.cyanAccent,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                        letterSpacing: 3,
                        shadows: [Shadow(color: Colors.cyanAccent, blurRadius: 8)],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Card per la selezione della modalità
class _ModeCard extends StatelessWidget {
  final GameModeConfig config;
  final bool isSelected;
  final bool isUnlocked;
  final VoidCallback? onTap;

  const _ModeCard({
    required this.config,
    required this.isSelected,
    required this.isUnlocked,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = isSelected
        ? Colors.cyanAccent
        : isUnlocked
            ? Colors.white24
            : Colors.white12;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 140,
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          border: Border.all(color: borderColor, width: isSelected ? 2 : 1),
          borderRadius: BorderRadius.circular(8),
          color: isSelected
              ? Colors.cyanAccent.withValues(alpha: 0.08)
              : Colors.white.withValues(alpha: 0.02),
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
                      color: isUnlocked ? Colors.white : Colors.white38,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              isUnlocked ? config.description : '🔒 ${config.unlockCost} GG',
              style: TextStyle(
                color: isUnlocked
                    ? Colors.white.withValues(alpha: 0.5)
                    : Colors.orange.withValues(alpha: 0.5),
                fontSize: 9,
                fontFamily: 'monospace',
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

/// Card per la selezione della difficoltà
class _DifficultyCard extends StatelessWidget {
  final DifficultyConfig config;
  final Difficulty difficulty;
  final bool isSelected;
  final VoidCallback onTap;

  const _DifficultyCard({
    required this.config,
    required this.difficulty,
    required this.isSelected,
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
      child: Container(
        width: 120,
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? _color : Colors.white24,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
          color: isSelected
              ? _color.withValues(alpha: 0.08)
              : Colors.white.withValues(alpha: 0.02),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              config.name,
              style: TextStyle(
                color: isSelected ? _color : Colors.white54,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Score x${config.scoreMultiplier.toStringAsFixed(0)}',
              style: TextStyle(
                color: _color.withValues(alpha: 0.5),
                fontSize: 9,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Riepilogo della selezione corrente
class _SelectionSummary extends StatelessWidget {
  final GameModeConfig mode;
  final DifficultyConfig difficulty;

  const _SelectionSummary({required this.mode, required this.difficulty});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white12),
        borderRadius: BorderRadius.circular(8),
        color: Colors.white.withValues(alpha: 0.02),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${mode.icon} ${mode.name} — ${difficulty.name}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(height: 6),
          Text(
            mode.description,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 10,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${difficulty.description} • Vite: ${difficulty.startingLives} • Bombe: ${difficulty.startingBombs}',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.4),
              fontSize: 9,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}
