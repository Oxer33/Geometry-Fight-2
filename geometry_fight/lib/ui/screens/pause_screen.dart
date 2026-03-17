import 'package:flutter/material.dart';

class PauseScreen extends StatelessWidget {
  final VoidCallback onResume;
  final VoidCallback onQuit;

  const PauseScreen({
    super.key,
    required this.onResume,
    required this.onQuit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withValues(alpha: 0.7),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'PAUSED',
              style: TextStyle(
                color: Colors.cyanAccent,
                fontSize: 40,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
                letterSpacing: 8,
                shadows: [Shadow(color: Colors.cyanAccent, blurRadius: 15)],
              ),
            ),
            const SizedBox(height: 40),
            _PauseButton(
              text: 'RESUME',
              color: Colors.cyanAccent,
              onTap: onResume,
            ),
            const SizedBox(height: 16),
            _PauseButton(
              text: 'QUIT',
              color: Colors.redAccent,
              onTap: onQuit,
            ),
          ],
        ),
      ),
    );
  }
}

class _PauseButton extends StatelessWidget {
  final String text;
  final Color color;
  final VoidCallback onTap;

  const _PauseButton({
    required this.text,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 200,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: color, width: 1.5),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: color,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            fontFamily: 'monospace',
            letterSpacing: 3,
          ),
        ),
      ),
    );
  }
}
