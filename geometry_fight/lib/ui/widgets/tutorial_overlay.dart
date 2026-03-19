import 'package:flutter/material.dart';

/// Tutorial overlay che appare al primo avvio del gioco.
/// Mostra i controlli base: joystick sinistro (movimento), destro (mira/sparo),
/// bomba, e obiettivo del gioco.
class TutorialOverlay extends StatelessWidget {
  final VoidCallback onDismiss;

  const TutorialOverlay({super.key, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
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
                    'COME GIOCARE',
                    style: TextStyle(
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
                    label: 'JOYSTICK SINISTRO',
                    description: 'Muovi la navicella',
                    color: Colors.cyanAccent,
                  ),
                  const SizedBox(height: 12),
                  _ControlRow(
                    icon: Icons.gps_fixed,
                    label: 'JOYSTICK DESTRO',
                    description: 'Mira e spara automaticamente',
                    color: const Color(0xFFFF4444),
                  ),
                  const SizedBox(height: 12),
                  _ControlRow(
                    icon: Icons.flash_on,
                    label: 'BOMBA',
                    description: 'Distrugge tutti i nemici vicini',
                    color: const Color(0xFFFF6600),
                  ),
                  const SizedBox(height: 12),
                  _ControlRow(
                    icon: Icons.diamond,
                    label: 'GEOMI',
                    description: 'Raccoglili per punti e upgrade',
                    color: const Color(0xFF00FFFF),
                  ),
                  const SizedBox(height: 12),
                  _ControlRow(
                    icon: Icons.star,
                    label: 'POWER-UP',
                    description: 'Potenziamenti temporanei',
                    color: const Color(0xFFFFD700),
                  ),

                  const SizedBox(height: 32),

                  // Pulsante continua
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.cyanAccent, width: 1.5),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(color: Colors.cyanAccent.withValues(alpha: 0.3), blurRadius: 12),
                      ],
                    ),
                    child: Text(
                      'TOCCA PER INIZIARE',
                      style: TextStyle(
                        color: Colors.cyanAccent,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ],
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
