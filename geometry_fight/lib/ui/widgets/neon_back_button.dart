import 'package:flutter/material.dart';

class NeonBackButton extends StatelessWidget {
  final VoidCallback onTap;
  const NeonBackButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    // M3 richiede tap-target ≥48x48: il box esterno garantisce hit area
    // accessibile pur mantenendo l'icona visivamente piccola (20px).
    return SizedBox(
      width: 48,
      height: 48,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.cyanAccent.withValues(alpha: 0.3),
              ),
              color: Colors.cyanAccent.withValues(alpha: 0.05),
            ),
            child: const Icon(
              Icons.arrow_back,
              color: Colors.cyanAccent,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
}
