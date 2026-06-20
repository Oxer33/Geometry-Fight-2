import 'package:flutter/material.dart';
import '../../l10n/generated/app_localizations.dart';

/// Tutorial overlay che appare al primo avvio del gioco.
/// Mostra i controlli base: joystick sinistro (movimento), destro (mira/sparo),
/// bomba, e obiettivo del gioco.
class TutorialOverlay extends StatelessWidget {
  final VoidCallback onDismiss;

  const TutorialOverlay({super.key, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // PopScope: Android back NON deve bypassare il tutorial e popare la
    // schermata gioco senza marcare `tutorial_seen`. Intercetta → dismiss.
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) onDismiss();
      },
      child: GestureDetector(
        onTap: onDismiss,
        child: Container(
          color: Colors.black.withValues(alpha: 0.85),
          child: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Titolo
                    Text(
                      l10n.tutorialTitle,
                      style: const TextStyle(
                        color: Colors.cyanAccent,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        fontFamily: 'monospace',
                        letterSpacing: 4,
                        shadows: [
                          Shadow(color: Colors.cyanAccent, blurRadius: 12),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Controlli
                    _ControlRow(
                      icon: Icons.gamepad,
                      label: l10n.tutorialLeftJoystick,
                      description: l10n.tutorialLeftJoystickDesc,
                      color: Colors.cyanAccent,
                    ),
                    const SizedBox(height: 12),
                    _ControlRow(
                      icon: Icons.gps_fixed,
                      label: l10n.tutorialRightJoystick,
                      description: l10n.tutorialRightJoystickDesc,
                      color: const Color(0xFFFF4444),
                    ),
                    const SizedBox(height: 12),
                    _ControlRow(
                      icon: Icons.flash_on,
                      label: l10n.tutorialBomb,
                      description: l10n.tutorialBombDesc,
                      color: const Color(0xFFFF6600),
                    ),
                    const SizedBox(height: 12),
                    _ControlRow(
                      icon: Icons.diamond,
                      label: l10n.tutorialGeoms,
                      description: l10n.tutorialGeomsDesc,
                      color: const Color(0xFF00FFFF),
                    ),
                    const SizedBox(height: 12),
                    _ControlRow(
                      icon: Icons.star,
                      label: l10n.tutorialPowerUp,
                      description: l10n.tutorialPowerUpDesc,
                      color: const Color(0xFFFFD700),
                    ),

                    const SizedBox(height: 32),

                    // Pulsante continua
                    Semantics(
                      button: true,
                      label: l10n.tutorialTapToStart,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 28,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.cyanAccent,
                            width: 1.5,
                          ),
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.cyanAccent.withValues(alpha: 0.3),
                              blurRadius: 12,
                            ),
                          ],
                        ),
                        child: Text(
                          l10n.tutorialTapToStart,
                          style: const TextStyle(
                            color: Colors.cyanAccent,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'monospace',
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ControlRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String description;
  final Color color;

  const _ControlRow({
    required this.icon,
    required this.label,
    required this.description,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            border: Border.all(color: color.withValues(alpha: 0.5), width: 1),
            borderRadius: BorderRadius.circular(8),
            color: color.withValues(alpha: 0.1),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                  letterSpacing: 1,
                ),
              ),
              Text(
                description,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 11,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
