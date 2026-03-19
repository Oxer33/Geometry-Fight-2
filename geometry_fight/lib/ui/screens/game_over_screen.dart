import 'package:flutter/material.dart';

class GameOverScreen extends StatelessWidget {
  final int score;
  final int wave;
  final int geoms;
  final int goldEarned;
  final VoidCallback onRetry;
  final VoidCallback onQuit;

  const GameOverScreen({
    super.key,
    required this.score,
    required this.wave,
    required this.geoms,
    required this.goldEarned,
    required this.onRetry,
    required this.onQuit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withValues(alpha: 0.85),
      child: Center(
        child: SingleChildScrollView(
          child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 20),
            const Text(
              'GAME OVER',
              style: TextStyle(
                color: Colors.redAccent,
                fontSize: 36,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
                letterSpacing: 6,
                shadows: [Shadow(color: Colors.redAccent, blurRadius: 15)],
              ),
            ),
            const SizedBox(height: 16),

            // Stats
            _StatRow(label: 'SCORE', value: '$score'),
            _StatRow(label: 'WAVE', value: '$wave'),
            _StatRow(label: 'GEOMS', value: '$geoms'),

            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(
                    color: const Color(0xFFFFD700).withValues(alpha: 0.5)),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.diamond, color: Color(0xFFFFD700), size: 20),
                  const SizedBox(width: 8),
                  Text(
                    '+$goldEarned GOLD GEOMS',
                    style: const TextStyle(
                      color: Color(0xFFFFD700),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            _GameOverButton(
              text: 'RETRY',
              color: Colors.cyanAccent,
              onTap: onRetry,
            ),
            const SizedBox(height: 12),
            _GameOverButton(
              text: 'ESCI',
              color: Colors.white70,
              onTap: onQuit,
            ),
            const SizedBox(height: 20),
          ],
        ),
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;

  const _StatRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 14,
                fontFamily: 'monospace',
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}

class _GameOverButton extends StatelessWidget {
  final String text;
  final Color color;
  final VoidCallback onTap;

  const _GameOverButton({
    required this.text,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 180,
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
