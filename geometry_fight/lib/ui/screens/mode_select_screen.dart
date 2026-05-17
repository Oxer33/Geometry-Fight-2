import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../data/difficulty.dart';
import '../../data/save_data.dart';
import '../widgets/neon_back_button.dart';
import 'modifiers_screen.dart';

/// Schermata di selezione modalità di gioco (richiesta utente: split del
/// flow pre-game in screens dedicate). Solo MODE selection — difficoltà
/// + modificatori + loadout + summary in screens separate.
///
/// onConfirm passa solo la `GameMode` scelta. Il resto del wizard pre-game
/// è gestito da `main.dart` _navigateTo().
class ModeSelectScreen extends StatefulWidget {
  final VoidCallback onBack;
  final void Function(GameMode mode) onConfirm;

  const ModeSelectScreen({
    super.key,
    required this.onBack,
    required this.onConfirm,
  });

  @override
  State<ModeSelectScreen> createState() => _ModeSelectScreenState();
}

class _ModeSelectScreenState extends State<ModeSelectScreen>
    with TickerProviderStateMixin {
  GameMode _selectedMode = GameMode.classic;
  // ignore: unused_field
  final Difficulty _selectedDifficulty = Difficulty.normal;
  List<String> _activeModifiers = [];
  late final SaveData _saveData;

  late AnimationController _entranceController;
  late AnimationController _glowController;
  late AnimationController _startBtnController;

  @override
  void initState() {
    super.initState();
    _saveData = SaveManager.load();
    // Seed modifiers attivi dal save — prima `_activeModifiers` partiva
    // vuoto, ignorando i modificatori selezionati in sessione precedente.
    _activeModifiers = List<String>.from(_saveData.activeModifiers);

    _entranceController = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    )..forward();

    _glowController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    )..repeat(reverse: true);

    _startBtnController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _glowController.dispose();
    _startBtnController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final saveData = _saveData;
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: AnimatedBuilder(
          animation:
              Listenable.merge([_entranceController, _glowController, _startBtnController]),
          builder: (context, _) {
            final entrance = _entranceController.value;
            final glow = _glowController.value;
            final startPulse = _startBtnController.value;

            return Column(
              children: [
                // Header (con step indicator 1/5 a destra integrato — iter 8).
                _buildHeader(entrance, glow),

                // Mode list orizzontale (con scroll arrow indicator)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Iter 8: rimosso _buildSectionLabel('MODALITÀ',...)
                        // duplicato → header già "SELEZIONA MODALITÀ".
                        // Iter 13 (utente: "togliamo freccia scroll"):
                        // rimossi Stack + chevron icon + black gradient fade.
                        Expanded(
                          child: _buildModeList(saveData, entrance, glow),
                        ),
                      ],
                    ),
                  ),
                ),

                // Pulsante AVANTI (era START)
                _buildStartButton(entrance, startPulse),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(double entrance, double glow) {
    return Opacity(
      opacity: entrance,
      child: Transform.translate(
        offset: Offset(0, -20 * (1 - entrance)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              NeonBackButton(onTap: widget.onBack),
              const SizedBox(width: 16),
              const Expanded(
                child: Text(
                  'SELEZIONA MODALITÀ',
                  style: TextStyle(
                    color: Colors.cyanAccent,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                    letterSpacing: 3,
                    shadows: [Shadow(color: Colors.cyanAccent, blurRadius: 8)],
                  ),
                ),
              ),
              // Step indicator iter 8: integrato nell'header (top-dx) come
              // negli altri screen pre-partita (summary/difficulty).
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: Colors.cyanAccent.withValues(alpha: 0.5)),
                ),
                child: const Text(
                  '1/5',
                  style: TextStyle(
                    color: Colors.cyanAccent,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Iter 8: rimosso _buildSectionLabel (unused dopo cleanup duplicato).

  Widget _buildModeList(SaveData saveData, double entrance, double glow) {
    final e = ((entrance - 0.15) / 0.85).clamp(0.0, 1.0);
    // Iter 12 (utente: "card alte la metà + 2 file"). GridView 2 row.
    return Opacity(
      opacity: e,
      child: Transform.translate(
        offset: Offset(0, 15 * (1 - e)),
        child: SizedBox(
          // Iter 15: glow halved again → padding/spacing ulteriormente ridotti.
          height: 128,
          child: GridView.count(
            scrollDirection: Axis.horizontal,
            crossAxisCount: 2, // 2 rows
            mainAxisSpacing: 6,
            crossAxisSpacing: 6,
            childAspectRatio: 56 / 145, // height/width = card 145×56
            padding: const EdgeInsets.all(5),
            children: GameMode.values.map((mode) {
              final config = gameModeConfigs[mode]!;
              final isUnlocked = config.unlockCost == 0 ||
                  saveData.unlockedModes.contains(mode.name);
              final isSelected = _selectedMode == mode;
              return _NeonModeCard(
                config: config,
                mode: mode,
                isSelected: isSelected,
                isUnlocked: isUnlocked,
                glow: glow,
                onTap: isUnlocked
                    ? () => setState(() => _selectedMode = mode)
                    : null,
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  // Removed _buildDifficultyList: difficoltà ora in DifficultySelectScreen.

  // ignore: unused_element
  Widget _buildModifiersButton(double entrance, double glow) {
    final e = ((entrance - 0.35) / 0.65).clamp(0.0, 1.0);
    final hasModifiers = _activeModifiers.isNotEmpty;

    return Opacity(
      opacity: e,
      child: Transform.translate(
        offset: Offset(0, 10 * (1 - e)),
        child: GestureDetector(
          onTap: () {
            showModalBottomSheet(
              context: context,
              backgroundColor: Colors.transparent,
              isScrollControlled: true,
              builder: (_) => ModifiersSheet(
                activeModifiers: _activeModifiers,
                onChanged: (mods) =>
                    setState(() => _activeModifiers = mods),
              ),
            );
          },
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: hasModifiers
                    ? Colors.cyanAccent.withValues(alpha: 0.4 + glow * 0.1)
                    : Colors.white.withValues(alpha: 0.08),
              ),
              gradient: hasModifiers
                  ? LinearGradient(
                      colors: [
                        Colors.cyanAccent.withValues(alpha: 0.06),
                        Colors.cyanAccent.withValues(alpha: 0.02),
                      ],
                    )
                  : null,
              color: hasModifiers ? null : Colors.white.withValues(alpha: 0.02),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.tune_rounded,
                  color: hasModifiers ? Colors.cyanAccent : Colors.white38,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Text(
                  hasModifiers
                      ? 'MODIFICATORI (${_activeModifiers.length})'
                      : 'MODIFICATORI (opzionale)',
                  style: TextStyle(
                    color: hasModifiers ? Colors.cyanAccent : Colors.white38,
                    fontSize: 12,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                    shadows: hasModifiers
                        ? [
                            Shadow(
                                color:
                                    Colors.cyanAccent.withValues(alpha: 0.3),
                                blurRadius: 4)
                          ]
                        : null,
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.chevron_right_rounded,
                  color: hasModifiers
                      ? Colors.cyanAccent.withValues(alpha: 0.5)
                      : Colors.white.withValues(alpha: 0.2),
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ignore: unused_element
  Widget _buildSummary(double entrance, double glow) {
    final e = ((entrance - 0.4) / 0.6).clamp(0.0, 1.0);
    final modeConfig = gameModeConfigs[_selectedMode]!;
    final diffConfig = difficultyConfigs[_selectedDifficulty]!;
    final diffColor = _diffColor(_selectedDifficulty);

    return Opacity(
      opacity: e,
      child: Transform.translate(
        offset: Offset(0, 10 * (1 - e)),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                diffColor.withValues(alpha: 0.04),
                Colors.transparent,
              ],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(modeConfig.icon, style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 8),
                  Text(
                    '${modeConfig.name} — ${diffConfig.name}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                modeConfig.description,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 10,
                  fontFamily: 'monospace',
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  // Pacifist: 1 vita fissa, 0 bombe → nascondi chips inutili.
                  if (_selectedMode != GameMode.pacifist) ...[
                    _summaryChip(Icons.favorite_rounded, 'Vite: ${diffConfig.startingLives}', diffColor),
                    const SizedBox(width: 8),
                    _summaryChip(Icons.flash_on_rounded, 'Bombe: ${diffConfig.startingBombs}', diffColor),
                    const SizedBox(width: 8),
                  ],
                  _summaryChip(Icons.close_fullscreen_rounded, 'x${diffConfig.scoreMultiplier.toStringAsFixed(0)}', diffColor),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _summaryChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        color: color.withValues(alpha: 0.08),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color.withValues(alpha: 0.6), size: 10),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color.withValues(alpha: 0.7),
              fontSize: 9,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStartButton(double entrance, double pulse) {
    final e = ((entrance - 0.5) / 0.5).clamp(0.0, 1.0);
    return Opacity(
      opacity: e,
      child: Transform.translate(
        offset: Offset(0, 20 * (1 - e)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: GestureDetector(
            onTap: () {
              // Solo MODE selection — diff/mods/loadout/summary in screens
              // dedicate (vedi main.dart routing).
              widget.onConfirm(_selectedMode);
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: Colors.cyanAccent.withValues(alpha: 0.7 + pulse * 0.3),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.cyanAccent
                        .withValues(alpha: 0.15 + pulse * 0.1),
                    blurRadius: 16 + pulse * 8,
                    spreadRadius: -2,
                  ),
                ],
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.cyanAccent.withValues(alpha: 0.12 + pulse * 0.04),
                    Colors.cyanAccent.withValues(alpha: 0.04),
                  ],
                ),
              ),
              child: const Center(
                child: Text(
                  'AVANTI',
                  style: TextStyle(
                    color: Colors.cyanAccent,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                    letterSpacing: 4,
                    shadows: [
                      Shadow(color: Colors.cyanAccent, blurRadius: 10),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _diffColor(Difficulty d) {
    switch (d) {
      case Difficulty.easy:
        return Colors.greenAccent;
      case Difficulty.normal:
        return Colors.cyanAccent;
      case Difficulty.hard:
        return Colors.orangeAccent;
      case Difficulty.nightmare:
        return Colors.redAccent;
    }
  }
}

// ==================== NEON MODE CARD ====================
/// Color theme per modalità (richiesta utente iter 8: card colorate con
/// FX cosmici). Stessi colori dei tab leaderboard per coerenza visiva.
Color _modeColor(GameMode m) {
  switch (m) {
    case GameMode.classic: return const Color(0xFF00FFFF);       // ciano
    case GameMode.bossRush: return const Color(0xFFCC00FF);      // viola
    case GameMode.survival: return const Color(0xFFFF4466);      // rosa-rosso
    case GameMode.timeAttack: return const Color(0xFFFF8800);    // arancio
    case GameMode.zenMode: return const Color(0xFF44FF44);       // verde
    case GameMode.tunnel: return const Color(0xFF4488FF);        // blu
    case GameMode.dailyChallenge: return const Color(0xFFFFD700);// oro
    case GameMode.pacifist: return const Color(0xFF77FFD4);      // ciano pastel
    case GameMode.waves: return const Color(0xFFFF3344);         // rosso
    case GameMode.gravityInferno: return const Color(0xFF9933FF);// viola gravity
  }
}

class _NeonModeCard extends StatelessWidget {
  final GameModeConfig config;
  final bool isSelected;
  final bool isUnlocked;
  final double glow;
  final VoidCallback? onTap;
  // Iter 8: GameMode passato per derivare color theme cosmico.
  final GameMode mode;

  const _NeonModeCard({
    required this.config,
    required this.isSelected,
    required this.isUnlocked,
    required this.glow,
    required this.mode,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final themeColor = _modeColor(mode);
    final desat = isUnlocked ? 1.0 : 0.35;
    final tint = Color.lerp(Colors.white24, themeColor, desat)!;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        // Iter 12: width fit GridView constraint, height target 56.
        // Glow shimmer multi-layer pulsante quando selected.
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected
              ? [
                  // Iter 15 (utente: "glow ancora più piccolo, metà"):
                  // halved again da iter14. Compatto, no overflow su altre.
                  BoxShadow(
                    color: themeColor.withValues(alpha: 0.55 + glow * 0.35),
                    blurRadius: 6 + glow * 2.5,
                    spreadRadius: 0.5 + glow * 0.5,
                  ),
                  BoxShadow(
                    color: themeColor.withValues(alpha: 0.4),
                    blurRadius: 3,
                  ),
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.15 + glow * 0.15),
                    blurRadius: 1,
                  ),
                ]
              : isUnlocked
                  ? [
                      BoxShadow(
                        color: themeColor.withValues(alpha: 0.15 + glow * 0.1),
                        blurRadius: 10,
                      ),
                    ]
                  : null,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            children: [
              // Cosmic background painter: radial gradient + stelle stabili.
              Positioned.fill(
                child: CustomPaint(
                  painter: _CosmicCardPainter(
                    color: tint,
                    seed: mode.hashCode,
                    pulse: glow,
                    isSelected: isSelected,
                  ),
                ),
              ),
              // Border neon
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? themeColor.withValues(alpha: 0.85 + glow * 0.15)
                          : tint.withValues(alpha: isUnlocked ? 0.45 : 0.18),
                      width: isSelected ? 2.0 : 1.0,
                    ),
                  ),
                ),
              ),
              // Contenuto compact (iter 12: fit 56h).
              Padding(
                // Iter 18 (utente: "nome modalità più grande +50%"):
                // padding orizzontale 8 → 4 per dare più spazio al testo.
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                child: Row(
                  children: [
                    Text(config.icon, style: const TextStyle(fontSize: 21)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            config.name,
                            style: TextStyle(
                              // Iter 13 contrast (utente: "scritta selected
                              // stesso colore della card"): selected → white
                              // bold con glow themeColor; unselected →
                              // themeColor stesso (highlight non-selezionato).
                              color: !isUnlocked
                                  ? Colors.white30
                                  : isSelected
                                      ? Colors.white
                                      : themeColor,
                              // Iter 18 (utente: "+50% fontSize"):
                              // 26/23 → 39/35 con w800. Padding orizzontale
                              // ridotto per evitare line break.
                              fontSize: isSelected ? 39 : 35,
                              fontWeight: FontWeight.w800,
                              fontFamily: 'monospace',
                              letterSpacing: -0.5,
                              shadows: isUnlocked
                                  ? [
                                      Shadow(
                                          color: isSelected
                                              ? themeColor
                                                  .withValues(alpha: 0.95)
                                              : themeColor
                                                  .withValues(alpha: 0.45),
                                          blurRadius: isSelected ? 10 : 5)
                                    ]
                                  : null,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                          if (!isUnlocked)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.lock_rounded,
                                    color: Colors.orange
                                        .withValues(alpha: 0.65),
                                    size: 12),
                                const SizedBox(width: 3),
                                Flexible(
                                  child: Text(
                                    '${config.unlockCost}',
                                    style: TextStyle(
                                      color: Colors.orange
                                          .withValues(alpha: 0.7),
                                      // Iter 16: 9 → 12 (+30%).
                                      fontSize: 12,
                                      fontFamily: 'monospace',
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Cosmic card background: radial gradient mode-color + stelle deterministiche
/// (seed = mode.hashCode, sempre stesse posizioni per card consistente).
/// `pulse` (0..1) anima twinkle stelle. `isSelected` boost luminosità.
class _CosmicCardPainter extends CustomPainter {
  final Color color;
  final int seed;
  final double pulse;
  final bool isSelected;

  _CosmicCardPainter({
    required this.color,
    required this.seed,
    required this.pulse,
    required this.isSelected,
  });

  // Cached paint allocs.
  static final Paint _bgPaint = Paint();
  static final Paint _starPaint = Paint();
  static final Paint _nebulaPaint = Paint();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    // Base scuro con gradient radiale colorato (più intenso se selected).
    final gradStrength = isSelected ? 0.55 : 0.32;
    _bgPaint.shader = RadialGradient(
      center: const Alignment(-0.4, -0.6),
      radius: 1.4,
      colors: [
        color.withValues(alpha: gradStrength),
        const Color(0xFF050010),
      ],
    ).createShader(rect);
    canvas.drawRect(rect, _bgPaint);
    _bgPaint.shader = null;

    // Nebula soft blob (mode color, blurred-ish).
    _nebulaPaint
      ..color = color.withValues(alpha: 0.18 + pulse * 0.08)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14);
    canvas.drawCircle(
        Offset(size.width * 0.75, size.height * 0.7),
        size.width * 0.45,
        _nebulaPaint);
    _nebulaPaint.maskFilter = null;

    // Stelle (deterministe via seed).
    final rng = math.Random(seed);
    final starCount = 18;
    for (int i = 0; i < starCount; i++) {
      final x = rng.nextDouble() * size.width;
      final y = rng.nextDouble() * size.height;
      final r = 0.4 + rng.nextDouble() * 1.4;
      // Twinkle: ogni stella pulsa con phase diversa derivata da i.
      final phase = (pulse + i * 0.13) % 1.0;
      final twinkle = 0.4 + (math.sin(phase * math.pi * 2) * 0.5 + 0.5) * 0.6;
      _starPaint.color = const Color(0xFFFFFFFF)
          .withValues(alpha: twinkle * (isSelected ? 0.95 : 0.7));
      canvas.drawCircle(Offset(x, y), r, _starPaint);
    }
    // Stella accenti color (3) più grandi.
    for (int i = 0; i < 3; i++) {
      final x = rng.nextDouble() * size.width;
      final y = rng.nextDouble() * size.height;
      final phase = (pulse + i * 0.27) % 1.0;
      final twinkle = 0.5 + (math.sin(phase * math.pi * 2) * 0.5 + 0.5) * 0.5;
      _starPaint.color = color.withValues(alpha: twinkle * 0.9);
      canvas.drawCircle(Offset(x, y), 2.2, _starPaint);
    }
  }

  @override
  bool shouldRepaint(_CosmicCardPainter old) =>
      old.pulse != pulse ||
      old.color != color ||
      old.seed != seed ||
      old.isSelected != isSelected;
}

// ==================== NEON DIFFICULTY CARD ====================
// ignore: unused_element
class _NeonDifficultyCard extends StatelessWidget {
  final DifficultyConfig config;
  final Difficulty difficulty;
  final bool isSelected;
  final double glow;
  final VoidCallback onTap;

  const _NeonDifficultyCard({
    required this.config,
    required this.difficulty,
    required this.isSelected,
    required this.glow,
    required this.onTap,
  });

  Color get _color {
    switch (difficulty) {
      case Difficulty.easy:
        return Colors.greenAccent;
      case Difficulty.normal:
        return Colors.cyanAccent;
      case Difficulty.hard:
        return Colors.orangeAccent;
      case Difficulty.nightmare:
        return Colors.redAccent;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: 125,
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? _color.withValues(alpha: 0.5 + glow * 0.15)
                : Colors.white.withValues(alpha: 0.06),
            width: isSelected ? 1.5 : 0.5,
          ),
          gradient: isSelected
              ? LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    _color.withValues(alpha: 0.1),
                    _color.withValues(alpha: 0.03),
                  ],
                )
              : null,
          color: isSelected ? null : Colors.white.withValues(alpha: 0.02),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: _color.withValues(alpha: 0.1 + glow * 0.05),
                    blurRadius: 8,
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              config.name,
              style: TextStyle(
                color: isSelected ? _color : Colors.white38,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
                shadows: isSelected
                    ? [
                        Shadow(
                            color: _color.withValues(alpha: 0.4),
                            blurRadius: 4)
                      ]
                    : null,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: _color.withValues(alpha: isSelected ? 0.12 : 0.04),
              ),
              child: Text(
                'Score x${config.scoreMultiplier.toStringAsFixed(0)}',
                style: TextStyle(
                  color: _color.withValues(alpha: isSelected ? 0.8 : 0.4),
                  fontSize: 9,
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
