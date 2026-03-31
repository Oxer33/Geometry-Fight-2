import 'package:flutter/material.dart';

class NeonBackButton extends StatelessWidget {
  final VoidCallback onTap;
  const NeonBackButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.3)),
          color: Colors.cyanAccent.withValues(alpha: 0.05),
        ),
        child: const Icon(Icons.arrow_back, color: Colors.cyanAccent, size: 20),
      ),
    );
  }
}
