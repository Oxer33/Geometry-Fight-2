import 'package:flutter/material.dart';
import '../../data/constants.dart';
import '../../data/difficulty.dart';
import '../widgets/neon_back_button.dart';

/// Schermata dedicata selezione difficoltà (richiesta utente: "fare schermate
/// aggiuntive dedicate" per separare mode/diff/mods/loadout/summary).
///
/// 4 difficoltà: FACILE, NORMALE, DIFFICILE, INCUBO con descrizione +
/// multiplier preview. Selezione persiste in main.dart `_selectedDifficulty`.
class DifficultySelectScreen extends StatefulWidget {
  final Difficulty initial;
  // Iter 6: mode param per nascondere "Vite" chip in pacifist (1 vita fissa).
  final GameMode mode;
  final VoidCallback onBack;
  final void Function(Difficulty diff) onConfirm;

  const DifficultySelectScreen({
    super.key,
    required this.initial,
    required this.mode,
    required this.onBack,
    required this.onConfirm,
  });

  @override
  State<DifficultySelectScreen> createState() => _DifficultySelectScreenState();
}

class _DifficultySelectScreenState extends State<DifficultySelectScreen> {
  late Difficulty _sel;

  @override
  void initState() {
    super.initState();
    _sel = widget.initial;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                children: [
                  NeonBackButton(onTap: widget.onBack),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'DIFFICOLTÀ',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        fontFamily: 'monospace',
                        letterSpacing: 4,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: NeonColors.cyan.withValues(alpha: 0.5)),
                    ),
                    child: const Text(
                      '2/5',
                      style: TextStyle(
                        color: NeonColors.cyan,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GridView.count(
                  // Iter 10 (utente): 4 card lista verticale → griglia 2×2
                  // senza scroll. Rimossa description + chip HP/SPD/Vite.
                  // Solo nome + score multiplier per card.
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  // childAspectRatio 2.0 → 3.2 (utente: card troppo grandi,
                  // devono rientrare tutte nello schermo senza scroll).
                  childAspectRatio: 3.2,
                  physics: const NeverScrollableScrollPhysics(),
                  children: Difficulty.values.map((d) {
                    final cfg = difficultyConfigs[d]!;
                    final selected = _sel == d;
                    final color = _diffColor(d);
                    return GestureDetector(
                      onTap: () => setState(() => _sel = d),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: selected
                              ? color.withValues(alpha: 0.18)
                              : color.withValues(alpha: 0.05),
                          border: Border.all(
                              color: color.withValues(
                                  alpha: selected ? 0.95 : 0.4),
                              width: selected ? 2.5 : 1),
                          boxShadow: selected
                              ? [
                                  BoxShadow(
                                      color: color.withValues(alpha: 0.4),
                                      blurRadius: 12)
                                ]
                              : null,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              cfg.name,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: color,
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                fontFamily: 'monospace',
                                letterSpacing: 3,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '×${cfg.scoreMultiplier.toStringAsFixed(1)} score',
                              style: TextStyle(
                                color: color.withValues(alpha: 0.8),
                                fontSize: 12,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: GestureDetector(
                onTap: () => widget.onConfirm(_sel),
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: NeonColors.green.withValues(alpha: 0.12),
                    border: Border.all(
                        color: NeonColors.green.withValues(alpha: 0.7),
                        width: 2),
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    'AVANTI',
                    style: TextStyle(
                      color: NeonColors.green,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'monospace',
                      letterSpacing: 4,
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

  Color _diffColor(Difficulty d) {
    switch (d) {
      case Difficulty.easy: return NeonColors.green;
      case Difficulty.normal: return NeonColors.cyan;
      case Difficulty.hard: return NeonColors.orange;
      case Difficulty.nightmare: return NeonColors.red;
    }
  }

  // _statChip rimosso (utente: card minimal senza chip HP/SPD/Vite).
}
