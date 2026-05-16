import 'package:flutter/material.dart';
import '../../data/constants.dart';
import '../../data/difficulty.dart';
import '../../data/modifiers.dart';
import '../widgets/neon_back_button.dart';

/// Iter 9: filtra modifier incompatibili con mode rules.
/// Es: pacifist no shoot → glass_cannon/bullet_hell/one_shot/ricochet_world/
/// infinite_bombs sono no-op o senza senso.
bool _modIncompatibleWithMode(String modId, GameMode mode) {
  switch (mode) {
    case GameMode.pacifist:
      return const {
        'glass_cannon',
        'bullet_hell',
        'one_shot',
        'ricochet_world',
        'infinite_bombs',
      }.contains(modId);
    case GameMode.waves:
      // Kamikaze non sparano → bullet_hell N/A.
      return modId == 'bullet_hell';
    case GameMode.zenMode:
      // Player immortale → 1-life mods senza senso.
      return modId == 'glass_cannon' || modId == 'one_shot';
    case GameMode.gravityInferno:
      // Tanti BH + mob misti, no spari obbligatorio. one_shot
      // brutale (1 vita + BH attrazione = unfair) → filter.
      return modId == 'one_shot';
    case GameMode.classic:
    case GameMode.bossRush:
    case GameMode.survival:
    case GameMode.timeAttack:
    case GameMode.tunnel:
    case GameMode.dailyChallenge:
      return false;
  }
}

/// Schermata dedicata selezione modificatori (richiesta utente: "fare schermate
/// aggiuntive dedicate"). Wrapper full-screen del catalog modifiers in
/// `data/modifiers.dart`. Cap 3 modificatori attivi.
///
/// Diversa da `modifiers_screen.dart` (`ModifiersSheet`) che è una bottom
/// sheet modal — questa è full-screen step del wizard pre-game.
class ModifiersSelectScreen extends StatefulWidget {
  final List<String> initial;
  // Iter 9: mode passato per filtrare modifier incompatibili.
  final GameMode mode;
  final VoidCallback onBack;
  final void Function(List<String> mods) onConfirm;

  const ModifiersSelectScreen({
    super.key,
    required this.initial,
    required this.mode,
    required this.onBack,
    required this.onConfirm,
  });

  @override
  State<ModifiersSelectScreen> createState() => _ModifiersSelectScreenState();
}

class _ModifiersSelectScreenState extends State<ModifiersSelectScreen> {
  late List<String> _active;
  late List<GameModifier> _availableModifiers;
  static const _maxActive = 3;

  @override
  void initState() {
    super.initState();
    // Filter out modifier incompatibili con la mode selezionata.
    _availableModifiers = allModifiers
        .where((m) => !_modIncompatibleWithMode(m.id, widget.mode))
        .toList();
    // Pulisci modifiers iniziali che non sono più compatibili (utente
    // potrebbe avere mods sticky da partita precedente).
    _active = widget.initial
        .where((id) =>
            _availableModifiers.any((m) => m.id == id))
        .toList();
  }

  void _toggle(String id) {
    bool showCapSnack = false;
    setState(() {
      // Iter 9 fix: pattern immutable — replace list instead of in-place
      // mutation (rispetta global rule "ALWAYS create new objects").
      if (_active.contains(id)) {
        _active = [..._active]..remove(id);
      } else if (_active.length < _maxActive) {
        _active = [..._active, id];
      } else {
        showCapSnack = true;
      }
    });
    if (showCapSnack) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(
          duration: Duration(milliseconds: 1200),
          backgroundColor: Color(0xFF0A0A1A),
          behavior: SnackBarBehavior.floating,
          content: Text('MAX $_maxActive MODIFICATORI',
              style: TextStyle(
                  color: Colors.amber,
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.w900)),
        ));
    }
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
                      'MODIFICATORI',
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
                      '3/5',
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
            // Counter attivi
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text(
                    'Attivi: ${_active.length}/$_maxActive',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 11,
                      fontFamily: 'monospace',
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Score ×${combinedScoreMultiplier(_active).toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: NeonColors.gold,
                      fontSize: 11,
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _availableModifiers.length,
                itemBuilder: (_, i) {
                  final m = _availableModifiers[i];
                  final on = _active.contains(m.id);
                  final color = m.isChallenge
                      ? const Color(0xFFFF4466)
                      : const Color(0xFF44CCFF);
                  return GestureDetector(
                    onTap: () => _toggle(m.id),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: on
                            ? color.withValues(alpha: 0.15)
                            : color.withValues(alpha: 0.04),
                        border: Border.all(
                            color: color.withValues(
                                alpha: on ? 0.95 : 0.3),
                            width: on ? 2 : 1),
                      ),
                      child: Row(
                        children: [
                          Text(m.icon,
                              style: const TextStyle(fontSize: 22)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  m.name,
                                  style: TextStyle(
                                    color: color,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w900,
                                    fontFamily: 'monospace',
                                    letterSpacing: 2,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  m.description,
                                  style: TextStyle(
                                    color:
                                        Colors.white.withValues(alpha: 0.7),
                                    fontSize: 10,
                                    fontFamily: 'monospace',
                                    height: 1.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '×${m.scoreMultiplier.toStringAsFixed(1)}',
                            style: TextStyle(
                              color: m.scoreMultiplier > 1.0
                                  ? NeonColors.green
                                  : Colors.amber,
                              fontSize: 11,
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: GestureDetector(
                onTap: () => widget.onConfirm(_active),
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
}
