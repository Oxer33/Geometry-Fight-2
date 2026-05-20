import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../data/difficulty.dart';
import '../../data/save_data.dart';
import '../../l10n/generated/app_localizations.dart';
import '../widgets/neon_back_button.dart';

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
  // Iter 22 (flutter-review cleanup): rimosso `_selectedMode` — il flow è
  // tap-to-advance, non c'è più stato "selezionato". Lo step indicator
  // header hardcoded a `_totalStepsForMode(GameMode.classic)` (default
  // mostrato al boot — dopo tap il widget unmounta).
  late final SaveData _saveData;

  // Caveman-review: guard against rapid double-tap firing onConfirm twice
  // (page transition race). Reset is unnecessary — widget unmounts on advance.
  bool _isAdvancing = false;

  late AnimationController _entranceController;
  late AnimationController _glowController;

  @override
  void initState() {
    super.initState();
    _saveData = SaveManager.load();

    _entranceController = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    )..forward();

    _glowController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    )..repeat(reverse: true);

    // Iter 19: rimosso _startBtnController — non più bottone AVANTI (tap-to-advance).
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final saveData = _saveData;
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: AnimatedBuilder(
          animation: Listenable.merge([_entranceController, _glowController]),
          builder: (context, _) {
            final entrance = _entranceController.value;
            final glow = _glowController.value;

            // Iter 19 (utente: "auto-advance on tap"): rimosso bottone
            // AVANTI bottom — tap su card unlocked = setState + onConfirm.
            return Column(
              children: [
                // Header (con step indicator 1/5 a destra integrato — iter 8).
                _buildHeader(l10n, entrance, glow),

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
                          child: _buildModeList(l10n, saveData, entrance, glow),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(AppLocalizations l10n, double entrance, double glow) {
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
              Expanded(
                child: Text(
                  l10n.modeSelectTitle,
                  style: const TextStyle(
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
              // Caveman-review: indicator dinamico — pacifist/snake skippano
              // difficulty + loadout → wizard 3 step invece di 5. Lo step 1
              // resta 1 in entrambi, ma il totale cambia. Calcolato dopo che
              // l'utente ha scelto la modalità in `_selectedMode`.
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.cyanAccent.withValues(alpha: 0.5),
                  ),
                ),
                child: Text(
                  // Step 1 di N: hard-coded a classic (5 step) — il tap
                  // su qualsiasi card avanza prima che l'indicator si
                  // aggiorni, quindi mostriamo sempre il default.
                  '1/${_totalStepsForMode(GameMode.classic)}',
                  style: const TextStyle(
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

  /// Numero totale di step del wizard pre-game in base alla modalità.
  /// Pacifist/Snake skippano difficulty + loadout → 3 step (mode, modifiers,
  /// summary). Le altre modalità seguono il flusso completo a 5 step.
  int _totalStepsForMode(GameMode mode) {
    return (mode == GameMode.pacifist || mode == GameMode.snake) ? 3 : 5;
  }

  Widget _buildModeList(
    AppLocalizations l10n,
    SaveData saveData,
    double entrance,
    double glow,
  ) {
    final e = ((entrance - 0.15) / 0.85).clamp(0.0, 1.0);
    // Iter 20 (richiesta utente: "card height -50%, width -30%, 3 file,
    // testo centrato H+V, ~5-6 card per riga visibili"):
    //   - crossAxisCount 2 → 3 (più file visibili contemporaneamente).
    //   - card 145×56 → 101×28 (width -30%, height -50%).
    //   - container 128 → 110 (3 × 28 + 2 × 6 spacing + 10 padding).
    //   - childAspectRatio 56/145 → 28/101 ≈ 0.277 (crossExtent/mainExtent
    //     per horizontal GridView).
    // Iter 21 (richiesta utente: "bottoni troppo larghi, -20%"):
    //   - card 101 → 81 (width -20%). Height invariata (28).
    //   - childAspectRatio 28/101 → 28/81 ≈ 0.346.
    return Opacity(
      opacity: e,
      child: Transform.translate(
        offset: Offset(0, 15 * (1 - e)),
        child: SizedBox(
          height: 110,
          child: GridView.count(
            scrollDirection: Axis.horizontal,
            crossAxisCount: 3, // 3 rows visibili
            mainAxisSpacing: 6,
            crossAxisSpacing: 6,
            childAspectRatio: 28 / 81, // crossExtent/mainExtent = card 81×28
            padding: const EdgeInsets.all(5),
            children: GameMode.values.map((mode) {
              final config = gameModeConfigs[mode]!;
              final isUnlocked =
                  config.unlockCost == 0 ||
                  saveData.unlockedModes.contains(mode.name);
              return _NeonModeCard(
                config: config,
                modeName: _modeName(l10n, mode),
                mode: mode,
                isUnlocked: isUnlocked,
                glow: glow,
                onTap: () {
                  // Iter 19 (utente: "tap auto-advance"). Locked → snackbar
                  // "Sblocca nello SHOP"; unlocked → onConfirm immediato.
                  // Caveman-review: _isAdvancing guard blocks double-tap race
                  // (PageRoute push not yet committed → second tap re-fires).
                  if (_isAdvancing) return;
                  if (!isUnlocked) {
                    _showLockedSnack(l10n);
                    return;
                  }
                  _isAdvancing = true;
                  // Iter 22: rimosso `setState(_selectedMode = mode)` — il
                  // visual `isSelected` non esiste più (cards uniformi), e
                  // il widget unmount tramite onConfirm rende il rebuild
                  // sprecato.
                  widget.onConfirm(mode);
                },
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  // Iter 19: snackbar quando tap su modalità locked (tap-to-advance flow).
  void _showLockedSnack(AppLocalizations l10n) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          duration: const Duration(milliseconds: 1100),
          backgroundColor: const Color(0xFF0A0A1A),
          behavior: SnackBarBehavior.floating,
          content: Text(
            l10n.modeLockedSnack,
            style: const TextStyle(
              color: Colors.amber,
              fontFamily: 'monospace',
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      );
  }

  String _modeName(AppLocalizations l10n, GameMode mode) {
    switch (mode) {
      case GameMode.classic:
        return l10n.modeClassic;
      case GameMode.bossRush:
        return l10n.modeBossRush;
      case GameMode.survival:
        return l10n.modeSurvival;
      case GameMode.timeAttack:
        return l10n.modeTimeAttack;
      case GameMode.zenMode:
        return l10n.modeZen;
      case GameMode.tunnel:
        return l10n.modeTunnel;
      case GameMode.dailyChallenge:
        return l10n.modeDailyChallenge;
      case GameMode.pacifist:
        return l10n.modePacifist;
      case GameMode.waves:
        return l10n.modeWaves;
      case GameMode.gravityInferno:
        return l10n.modeGravityInferno;
      case GameMode.snake:
        return l10n.modeSnake;
    }
  }

  // Removed _buildDifficultyList: difficoltà ora in DifficultySelectScreen.

  // Removed unused _buildModifiersButton + _buildSummary + _summaryChip +
  // _diffColor (legacy iter 19 bottom-of-screen blocks). The wizard now uses
  // dedicated steps for modifiers/difficulty/summary — those legacy widgets
  // contained hardcoded Italian strings that would have to be migrated to
  // l10n if kept. Dead code removed.

  // Iter 19: rimosso _buildStartButton — tap-to-advance sostituisce il
  // bottone AVANTI bottom (vedi onTap di _NeonModeCard in _buildModeList).
}

// ==================== NEON MODE CARD ====================
/// Color theme per modalità (richiesta utente iter 8: card colorate con
/// FX cosmici). Stessi colori dei tab leaderboard per coerenza visiva.
Color _modeColor(GameMode m) {
  switch (m) {
    case GameMode.classic:
      return const Color(0xFF00FFFF); // ciano
    case GameMode.bossRush:
      return const Color(0xFFCC00FF); // viola
    case GameMode.survival:
      return const Color(0xFFFF4466); // rosa-rosso
    case GameMode.timeAttack:
      return const Color(0xFFFF8800); // arancio
    case GameMode.zenMode:
      return const Color(0xFF44FF44); // verde
    case GameMode.tunnel:
      return const Color(0xFF4488FF); // blu
    case GameMode.dailyChallenge:
      return const Color(0xFFFFD700); // oro
    case GameMode.pacifist:
      return const Color(0xFF77FFD4); // ciano pastel
    case GameMode.waves:
      return const Color(0xFFFF3344); // rosso
    case GameMode.gravityInferno:
      return const Color(0xFF9933FF); // viola gravity
    case GameMode.snake:
      return const Color(0xFF66FF66); // verde lime
  }
}

class _NeonModeCard extends StatelessWidget {
  final GameModeConfig config;
  final String modeName;
  final bool isUnlocked;
  final double glow;
  final VoidCallback? onTap;
  // Iter 8: GameMode passato per derivare color theme cosmico.
  final GameMode mode;

  const _NeonModeCard({
    required this.config,
    required this.modeName,
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
    // Accessibility note: tap area 28h × 81w soddisfa WCAG 2.2 AA target
    // size (24×24 min). Sotto Material 48dp guideline per scelta esplicita
    // di compattezza richiesta dall'utente (3 file × 11 modi → 28h max).
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        // Iter 21 (utente: "tap auto-advance, no preselezione classic"):
        // rimossa la distinzione visuale `isSelected` vs `unlocked-but-not-
        // selected` — il flow è tap-to-advance, non c'è più una card
        // "selezionata in attesa di Avanti". Tutte le card unlocked
        // hanno lo stesso bordo + glow moderato per uniformità.
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: isUnlocked
              ? [
                  BoxShadow(
                    color: themeColor.withValues(alpha: 0.25 + glow * 0.15),
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
                  ),
                ),
              ),
              // Border neon — uniforme per tutte le card unlocked
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: tint.withValues(alpha: isUnlocked ? 0.55 : 0.18),
                      width: 1.2,
                    ),
                  ),
                ),
              ),
              // Contenuto compact (iter 20: 28h card, testo centrato H+V).
              // Row centrato sia orizzontalmente sia verticalmente, con icona
              // + nome modalità. Per i mode locked l'icona del lucchetto e
              // il costo restano in linea (no Column nested per minimizzare
              // altezza). FittedBox per auto-shrink su nomi lunghi (GRAVITY
              // INFERNO, BOSS RUSH).
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      Text(config.icon, style: const TextStyle(fontSize: 14)),
                      const SizedBox(width: 4),
                      // Caveman-review: FittedBox.scaleDown senza floor poteva
                      // ridurre "GRAVITY INFERNO" (15 chars × monospace) sotto
                      // i ~7px su 4 colonne visibili → illeggibile. Wrap con
                      // MediaQuery clamp + maxLines:1 + ellipsis come ultimo
                      // baluardo se anche lo scaling al floor non basta.
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.center,
                          // Minimum scale floor: 0.75 → ~9px effettivi sul
                          // font 12 base, ancora leggibile sul 28h delle card.
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(minWidth: 0),
                            child: Text(
                              modeName,
                              maxLines: 1,
                              softWrap: false,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              // Iter 21 (utente: "scritte tutte bianche
                              // evidenti come classic preselezionata"):
                              // unlocked = sempre bianco fontSize 13
                              // shadow forte themeColor blurRadius 8;
                              // locked = white30 senza shadow. Rimossa
                              // distinzione isSelected (tap auto-advance).
                              style: TextStyle(
                                color: isUnlocked
                                    ? Colors.white
                                    : Colors.white30,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                fontFamily: 'monospace',
                                letterSpacing: -0.5,
                                shadows: isUnlocked
                                    ? [
                                        Shadow(
                                          color: themeColor.withValues(
                                            alpha: 0.95,
                                          ),
                                          blurRadius: 8,
                                        ),
                                      ]
                                    : null,
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (!isUnlocked) ...[
                        const SizedBox(width: 4),
                        Icon(
                          Icons.lock_rounded,
                          color: Colors.orange.withValues(alpha: 0.65),
                          size: 10,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '${config.unlockCost}',
                          style: TextStyle(
                            color: Colors.orange.withValues(alpha: 0.7),
                            fontSize: 9,
                            fontFamily: 'monospace',
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ],
                    ],
                  ),
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
/// `pulse` (0..1) anima twinkle stelle.
class _CosmicCardPainter extends CustomPainter {
  final Color color;
  final int seed;
  final double pulse;

  _CosmicCardPainter({
    required this.color,
    required this.seed,
    required this.pulse,
  });

  // Cached paint allocs.
  static final Paint _bgPaint = Paint();
  static final Paint _starPaint = Paint();
  static final Paint _nebulaPaint = Paint();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    // Base scuro con gradient radiale colorato.
    _bgPaint.shader = RadialGradient(
      center: const Alignment(-0.4, -0.6),
      radius: 1.4,
      colors: [color.withValues(alpha: 0.32), const Color(0xFF050010)],
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
      _nebulaPaint,
    );
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
      _starPaint.color = const Color(
        0xFFFFFFFF,
      ).withValues(alpha: twinkle * 0.7);
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
      old.pulse != pulse || old.color != color || old.seed != seed;
}

// Removed unused _NeonDifficultyCard (legacy iter 19 — difficulty now lives
// in DifficultySelectScreen). Held config.name (catalog Italian) and a
// hardcoded "Score x" prefix that would need l10n if revived.
