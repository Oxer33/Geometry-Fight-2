import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../widgets/animated_builder_widget.dart';

/// Menu principale con layout landscape responsive.
/// Due colonne: titolo+sottotitolo a sinistra, bottoni compatti a destra.
/// Background animato con geometrie fluttuanti neon.
class MainMenuScreen extends StatefulWidget {
  final VoidCallback onPlay;
  final VoidCallback onShop;
  final VoidCallback onSettings;
  final VoidCallback? onLeaderboard;

  const MainMenuScreen({
    super.key,
    required this.onPlay,
    required this.onShop,
    required this.onSettings,
    this.onLeaderboard,
  });

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _bgController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _bgController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isLandscape = screenSize.width > screenSize.height;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // === BACKGROUND ANIMATO ===
          NeonAnimatedBuilder(
            animation: _bgController,
            builder: (context, _) => CustomPaint(
              painter: _MenuBackgroundPainter(_bgController.value),
              size: screenSize,
            ),
          ),

          // === CONTENUTO RESPONSIVE ===
          SafeArea(
            child: isLandscape
                ? _buildLandscapeLayout()
                : _buildPortraitLayout(),
          ),

          // === VERSIONE in basso a destra ===
          Positioned(
            bottom: 8,
            right: 12,
            child: Text(
              'v2.0',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.15),
                fontSize: 10,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Layout landscape: titolo a sinistra, bottoni a destra
  Widget _buildLandscapeLayout() {
    return Row(
      children: [
        // Lato sinistro: titolo e sottotitolo
        Expanded(
          flex: 5,
          child: Center(
            child: _buildTitle(),
          ),
        ),
        // Lato destro: bottoni
        Expanded(
          flex: 4,
          child: Center(
            child: _buildButtonColumn(),
          ),
        ),
      ],
    );
  }

  /// Layout portrait: tutto in colonna
  Widget _buildPortraitLayout() {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 40),
            _buildTitle(),
            const SizedBox(height: 40),
            _buildButtonColumn(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildTitle() {
    return NeonAnimatedBuilder(
      animation: _pulseController,
      builder: (context, _) {
        final glow = 8 + _pulseController.value * 12;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'GEOMETRY',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.cyanAccent,
                fontSize: 36,
                fontWeight: FontWeight.w900,
                fontFamily: 'monospace',
                letterSpacing: 6,
                shadows: [
                  Shadow(color: Colors.cyanAccent, blurRadius: glow),
                  Shadow(
                    color: Colors.cyanAccent.withValues(alpha: 0.5),
                    blurRadius: glow * 2,
                  ),
                ],
              ),
            ),
            Text(
              'FIGHT',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.cyanAccent,
                fontSize: 48,
                fontWeight: FontWeight.w900,
                fontFamily: 'monospace',
                letterSpacing: 12,
                shadows: [
                  Shadow(color: Colors.cyanAccent, blurRadius: glow),
                  Shadow(
                    color: Colors.cyanAccent.withValues(alpha: 0.5),
                    blurRadius: glow * 2,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'TWIN-STICK NEON SHOOTER',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.4),
                fontSize: 10,
                fontFamily: 'monospace',
                letterSpacing: 4,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildButtonColumn() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _NeonButton(
          text: 'GIOCA',
          icon: Icons.play_arrow,
          color: Colors.cyanAccent,
          onTap: widget.onPlay,
          isPrimary: true,
        ),
        const SizedBox(height: 10),
        _NeonButton(
          text: 'NEGOZIO',
          icon: Icons.storefront,
          color: const Color(0xFFFFD700),
          onTap: widget.onShop,
        ),
        if (widget.onLeaderboard != null) ...[
          const SizedBox(height: 10),
          _NeonButton(
            text: 'CLASSIFICA',
            icon: Icons.emoji_events,
            color: const Color(0xFFFFD700),
            onTap: widget.onLeaderboard!,
          ),
        ],
        const SizedBox(height: 10),
        _NeonButton(
          text: 'IMPOSTAZIONI',
          icon: Icons.settings,
          color: Colors.white54,
          onTap: widget.onSettings,
        ),
      ],
    );
  }
}

/// Bottone neon compatto e responsive con icona
class _NeonButton extends StatelessWidget {
  final String text;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool isPrimary;

  const _NeonButton({
    required this.text,
    required this.icon,
    required this.color,
    required this.onTap,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    final maxWidth = MediaQuery.of(context).size.width * 0.35;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: maxWidth.clamp(140.0, 220.0),
        padding: EdgeInsets.symmetric(
          vertical: isPrimary ? 12 : 9,
          horizontal: 14,
        ),
        decoration: BoxDecoration(
          border: Border.all(
            color: color.withValues(alpha: isPrimary ? 0.8 : 0.5),
            width: isPrimary ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
          color: color.withValues(alpha: isPrimary ? 0.08 : 0.03),
          boxShadow: isPrimary
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.25),
                    blurRadius: 16,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: isPrimary ? 20 : 16),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                text,
                style: TextStyle(
                  color: color,
                  fontSize: isPrimary ? 16 : 13,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                  letterSpacing: 2,
                  shadows: isPrimary
                      ? [Shadow(color: color, blurRadius: 6)]
                      : null,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Background animato del menu con geometrie neon fluttuanti e gradiente
class _MenuBackgroundPainter extends CustomPainter {
  final double progress;

  _MenuBackgroundPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    // Gradiente di sfondo scuro
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF050515),
          Color(0xFF0A0A20),
          Color(0xFF050510),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // Griglia sottile
    final gridPaint = Paint()
      ..color = Colors.cyanAccent.withValues(alpha: 0.03)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    const spacing = 50.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Geometrie fluttuanti (più grandi e varie)
    final shapePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final random = math.Random(42);
    for (int i = 0; i < 12; i++) {
      final baseX = random.nextDouble() * size.width;
      final baseY = random.nextDouble() * size.height;
      final spd = 0.3 + random.nextDouble() * 0.7;
      final angle = progress * math.pi * 2 * spd + i * 0.5;

      final x = baseX + math.cos(angle) * 40;
      final y = baseY + math.sin(angle * 0.7) * 30;
      final r = 10 + random.nextDouble() * 25;
      final alpha = 0.05 + random.nextDouble() * 0.08;

      // Colori diversi per le forme
      final colors = [
        Colors.cyanAccent,
        const Color(0xFFFF00AA),
        const Color(0xFFFFD700),
        const Color(0xFF00FF88),
      ];
      shapePaint.color = colors[i % colors.length].withValues(alpha: alpha);

      if (i % 4 == 0) {
        canvas.drawCircle(Offset(x, y), r, shapePaint);
      } else if (i % 4 == 1) {
        canvas.save();
        canvas.translate(x, y);
        canvas.rotate(angle * 0.3);
        canvas.drawRect(
          Rect.fromCenter(center: Offset.zero, width: r * 1.5, height: r * 1.5),
          shapePaint,
        );
        canvas.restore();
      } else if (i % 4 == 2) {
        final path = Path()
          ..moveTo(x, y - r)
          ..lineTo(x + r * 0.87, y + r * 0.5)
          ..lineTo(x - r * 0.87, y + r * 0.5)
          ..close();
        canvas.drawPath(path, shapePaint);
      } else {
        // Esagono
        final hexPath = Path();
        for (int j = 0; j < 6; j++) {
          final a = j * math.pi / 3 + angle * 0.2;
          final hx = x + r * math.cos(a);
          final hy = y + r * math.sin(a);
          if (j == 0) hexPath.moveTo(hx, hy); else hexPath.lineTo(hx, hy);
        }
        hexPath.close();
        canvas.drawPath(hexPath, shapePaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _MenuBackgroundPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
