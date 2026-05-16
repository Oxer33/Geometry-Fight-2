import 'package:flutter/material.dart';
import '../../data/modifiers.dart';

class ModifiersSheet extends StatefulWidget {
  final List<String> activeModifiers;
  final ValueChanged<List<String>> onChanged;

  const ModifiersSheet({
    super.key,
    required this.activeModifiers,
    required this.onChanged,
  });

  @override
  State<ModifiersSheet> createState() => _ModifiersSheetState();
}

class _ModifiersSheetState extends State<ModifiersSheet> {
  late List<String> _active;

  @override
  void initState() {
    super.initState();
    _active = List.from(widget.activeModifiers);
  }

  void _toggle(String id) {
    final wasAtCap = !_active.contains(id) && _active.length >= 3;
    if (wasAtCap) {
      // Feedback utente: cap raggiunto, drop silenzioso → SnackBar esplicita.
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            duration: Duration(milliseconds: 1500),
            backgroundColor: Color(0xFF0A0A1A),
            behavior: SnackBarBehavior.floating,
            content: Text(
              'MAX 3 MODIFICATORI',
              style: TextStyle(
                color: Colors.orangeAccent,
                fontFamily: 'monospace',
                letterSpacing: 2,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      return;
    }
    setState(() {
      if (_active.contains(id)) {
        _active.remove(id);
      } else {
        _active.add(id);
      }
    });
    widget.onChanged(List.from(_active));
  }

  @override
  Widget build(BuildContext context) {
    final multiplier = combinedScoreMultiplier(_active);

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0A0A1A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Text(
                  'MODIFICATORI',
                  style: TextStyle(
                    color: Colors.cyanAccent,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                    letterSpacing: 3,
                  ),
                ),
                const Spacer(),
                if (_active.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: multiplier > 1.0
                            ? Colors.greenAccent.withValues(alpha: 0.5)
                            : Colors.orangeAccent.withValues(alpha: 0.5),
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Score x${multiplier.toStringAsFixed(1)}',
                      style: TextStyle(
                        color: multiplier > 1.0 ? Colors.greenAccent : Colors.orangeAccent,
                        fontSize: 11,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                const SizedBox(width: 8),
                Text(
                  '${_active.length}/3',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 12,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),

          // Modifier list
          SizedBox(
            height: 280,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: allModifiers.length,
              itemBuilder: (context, index) {
                final mod = allModifiers[index];
                final isActive = _active.contains(mod.id);

                return GestureDetector(
                  onTap: () => _toggle(mod.id),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isActive
                            ? (mod.isChallenge ? Colors.redAccent : Colors.cyanAccent).withValues(alpha: 0.6)
                            : Colors.white12,
                        width: isActive ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(8),
                      color: isActive
                          ? (mod.isChallenge ? Colors.redAccent : Colors.cyanAccent).withValues(alpha: 0.08)
                          : Colors.white.withValues(alpha: 0.02),
                    ),
                    child: Row(
                      children: [
                        Text(mod.icon, style: const TextStyle(fontSize: 20)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    mod.name,
                                    style: TextStyle(
                                      color: isActive
                                          ? (mod.isChallenge ? Colors.redAccent : Colors.cyanAccent)
                                          : Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(3),
                                      color: mod.isChallenge
                                          ? Colors.redAccent.withValues(alpha: 0.15)
                                          : Colors.cyanAccent.withValues(alpha: 0.15),
                                    ),
                                    child: Text(
                                      'x${mod.scoreMultiplier.toStringAsFixed(1)}',
                                      style: TextStyle(
                                        color: mod.isChallenge ? Colors.redAccent : Colors.cyanAccent,
                                        fontSize: 9,
                                        fontFamily: 'monospace',
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                mod.description,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.5),
                                  fontSize: 10,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Toggle indicator
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isActive ? Colors.greenAccent : Colors.white24,
                            ),
                            color: isActive ? Colors.greenAccent.withValues(alpha: 0.2) : null,
                          ),
                          child: isActive
                              ? const Icon(Icons.check, color: Colors.greenAccent, size: 14)
                              : null,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
