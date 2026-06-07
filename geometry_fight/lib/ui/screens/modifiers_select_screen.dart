import 'package:flutter/material.dart';
import '../../data/constants.dart';
import '../../data/difficulty.dart';
import '../../data/modifiers.dart';
import '../../l10n/generated/app_localizations.dart';
import '../widgets/neon_back_button.dart';

/// Localized name for a modifier id. Falls back to catalog Italian if id is
/// unknown (defensive — keeps render path safe when new mods are added).
String _modifierName(String id, AppLocalizations l10n) {
  switch (id) {
    case 'glass_cannon':
      return l10n.modNameGlassCannon;
    case 'bullet_hell':
      return l10n.modNameBulletHell;
    case 'speed_demon':
      return l10n.modNameSpeedDemon;
    case 'no_powerups':
      return l10n.modNameNoPowerups;
    case 'fog_of_war':
      return l10n.modNameFogOfWar;
    case 'tiny_arena':
      return l10n.modNameTinyArena;
    case 'one_shot':
      return l10n.modNameOneShot;
    case 'chaos':
      return l10n.modNameChaos;
    case 'giant_mode':
      return l10n.modNameGiantMode;
    case 'ricochet_world':
      return l10n.modNameRicochetWorld;
    case 'infinite_bombs':
      return l10n.modNameInfiniteBombs;
    case 'magnet_king':
      return l10n.modNameMagnetKing;
    default:
      return getModifier(id)?.name ?? id;
  }
}

/// Localized description for a modifier id. Falls back to catalog Italian.
String _modifierDesc(String id, AppLocalizations l10n) {
  switch (id) {
    case 'glass_cannon':
      return l10n.modDescGlassCannon;
    case 'bullet_hell':
      return l10n.modDescBulletHell;
    case 'speed_demon':
      return l10n.modDescSpeedDemon;
    case 'no_powerups':
      return l10n.modDescNoPowerups;
    case 'fog_of_war':
      return l10n.modDescFogOfWar;
    case 'tiny_arena':
      return l10n.modDescTinyArena;
    case 'one_shot':
      return l10n.modDescOneShot;
    case 'chaos':
      return l10n.modDescChaos;
    case 'giant_mode':
      return l10n.modDescGiantMode;
    case 'ricochet_world':
      return l10n.modDescRicochetWorld;
    case 'infinite_bombs':
      return l10n.modDescInfiniteBombs;
    case 'magnet_king':
      return l10n.modDescMagnetKing;
    default:
      return getModifier(id)?.description ?? '';
  }
}

/// Iter 9: filtra modifier incompatibili con mode rules.
/// Es: pacifist no shoot → glass_cannon/bullet_hell/one_shot/ricochet_world/
/// infinite_bombs sono no-op o senza senso.
bool _modIncompatibleWithMode(String modId, GameMode mode) {
  switch (mode) {
    case GameMode.pacifist:
      return const {
        'glass_cannon',
        'bullet_hell',
        'one_shot',
        'ricochet_world',
        'infinite_bombs',
      }.contains(modId);
    case GameMode.snake:
      // Snake: no spari, no powerup. Filter tutto ciò che tocca weapons /
      // bullets / damage / powerup. Mantiene: speed_demon (player speed),
      // tiny_arena, giant_mode, chaos (mixed random), fog_of_war, magnet_king
      // (geom magnet — geom droppano ancora dalle kill via trail).
      return const {
        'glass_cannon',     // no damage da moltiplicare (no spari)
        'one_shot',         // no proiettili (no spari) + 1 vita brutale
        'ricochet_world',   // no proiettili (no spari)
        'infinite_bombs',   // bombe inutili (no targets a distanza)
        'bullet_hell',      // no spari player, nemici sparano N/A snake-flow
        'no_powerups',      // powerup già OFF in snake mode → ridondante
      }.contains(modId);
    case GameMode.waves:
      // Kamikaze non sparano → bullet_hell N/A.
      return modId == 'bullet_hell';
    case GameMode.zenMode:
      // Player immortale → 1-life mods senza senso.
      return modId == 'glass_cannon' || modId == 'one_shot';
    case GameMode.gravityInferno:
      // Tanti BH + mob misti, no spari obbligatorio. one_shot
      // brutale (1 vita + BH attrazione = unfair) → filter.
      return modId == 'one_shot';
    case GameMode.classic:
    case GameMode.bossRush:
    case GameMode.survival:
    case GameMode.timeAttack:
    case GameMode.tunnel:
    case GameMode.dailyChallenge:
      return false;
  }
}

/// Schermata dedicata selezione modificatori (richiesta utente: "fare schermate
/// aggiuntive dedicate"). Wrapper full-screen del catalog modifiers in
/// `data/modifiers.dart`. Cap 3 modificatori attivi.
///
/// Diversa da `modifiers_screen.dart` (`ModifiersSheet`) che è una bottom
/// sheet modal — questa è full-screen step del wizard pre-game.
class ModifiersSelectScreen extends StatefulWidget {
  final List<String> initial;
  // Iter 9: mode passato per filtrare modifier incompatibili.
  final GameMode mode;
  final VoidCallback onBack;
  final void Function(List<String> mods) onConfirm;

  const ModifiersSelectScreen({
    super.key,
    required this.initial,
    required this.mode,
    required this.onBack,
    required this.onConfirm,
  });

  @override
  State<ModifiersSelectScreen> createState() => _ModifiersSelectScreenState();
}

class _ModifiersSelectScreenState extends State<ModifiersSelectScreen> {
  late List<String> _active;
  late List<GameModifier> _availableModifiers;
  static const _maxActive = 3;

  // Caveman-review: guard rapid double-tap from re-firing onConfirm (which
  // navigates to next screen). Widget unmounts on advance — no reset needed.
  bool _isAdvancing = false;

  /// Pacifist/Snake skippano difficulty + loadout → wizard 3 step invece di
  /// 6. Usato per scegliere l'etichetta dello step indicator ("2/3" vs "3/6").
  bool get _isShortWizard =>
      widget.mode == GameMode.pacifist || widget.mode == GameMode.snake;

  final ScrollController _scrollCtrl = ScrollController();

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // Filter out modifier incompatibili con la mode selezionata.
    _availableModifiers = allModifiers
        .where((m) => !_modIncompatibleWithMode(m.id, widget.mode))
        .toList();
    // Pulisci modifiers iniziali che non sono più compatibili (utente
    // potrebbe avere mods sticky da partita precedente).
    _active = widget.initial
        .where((id) =>
            _availableModifiers.any((m) => m.id == id))
        .toList();
  }

  // Tap su un modificatore = TOGGLE on/off (illumina/spegne). NON avanza più
  // alla schermata successiva (richiesta utente: "al primo che clicco va
  // avanti" → ora multi-select). L'avanzamento avviene SOLO dal tap sulla
  // card di conferma in cima alla lista (`_confirm`).
  void _tapMod(String id) {
    final wasActive = _active.contains(id);
    if (wasActive) {
      // Toggle OFF: rimuovi dalla selezione.
      setState(() => _active = _active.where((m) => m != id).toList());
      return;
    }
    // Toggle ON: aggiungi se sotto il cap, altrimenti snackbar.
    if (_active.length >= _maxActive) {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          duration: const Duration(milliseconds: 1100),
          backgroundColor: const Color(0xFF0A0A1A),
          behavior: SnackBarBehavior.floating,
          content: Text(l10n.modifiersMaxActive(_maxActive),
              style: const TextStyle(
                  color: Colors.amber,
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.w900)),
        ));
      return;
    }
    setState(() => _active = [..._active, id]);
  }

  // Card di conferma in cima alla lista: avanza al prossimo step con i
  // modificatori attualmente attivi (lista vuota = nessun modificatore).
  void _confirm() {
    if (_isAdvancing) return;
    _isAdvancing = true;
    widget.onConfirm(_active);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // Total items = 1 (NO MODIFIERS card) + N filtered modifiers.
    final itemCount = _availableModifiers.length + 1;
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                children: [
                  NeonBackButton(onTap: widget.onBack),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l10n.modifiersTitle,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        fontFamily: 'monospace',
                        letterSpacing: 4,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: NeonColors.cyan.withValues(alpha: 0.5)),
                    ),
                    // Step indicator dinamico: pacifist/snake skippano
                    // difficulty + loadout → questo screen è step 2 di 3.
                    // Altre modalità è 3 di 6 (full wizard).
                    child: Text(
                      _isShortWizard
                          ? '2/3'
                          : '3/6',
                      style: const TextStyle(
                        color: NeonColors.cyan,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Counter attivi
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text(
                    l10n.modifiersActiveCount(_active.length, _maxActive),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 11,
                      fontFamily: 'monospace',
                    ),
                  ),
                  const Spacer(),
                  Text(
                    l10n.modifiersScoreLabel(
                        combinedScoreMultiplier(_active).toStringAsFixed(2)),
                    style: const TextStyle(
                      color: NeonColors.gold,
                      fontSize: 11,
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: RawScrollbar(
                controller: _scrollCtrl,
                thumbVisibility: true,
                trackVisibility: true,
                thickness: 10,
                radius: const Radius.circular(5),
                thumbColor: const Color(0xFF00FFFF),
                trackColor: const Color(0x3300FFFF),
                trackBorderColor: const Color(0x8800FFFF),
                child: ListView.builder(
                controller: _scrollCtrl,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: itemCount,
                itemBuilder: (_, i) {
                  // First slot: confirm/summary card (NO MODIFIERS quando
                  // vuoto, altrimenti nomi mod attivi + moltiplicatore totale).
                  if (i == 0) return _buildConfirmCard(l10n);
                  final m = _availableModifiers[i - 1];
                  final on = _active.contains(m.id);
                  final color = m.isChallenge
                      ? const Color(0xFFFF4466)
                      : const Color(0xFF44CCFF);
                  return GestureDetector(
                    onTap: () => _tapMod(m.id),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: on
                            ? color.withValues(alpha: 0.15)
                            : color.withValues(alpha: 0.04),
                        border: Border.all(
                            color: color.withValues(
                                alpha: on ? 0.95 : 0.3),
                            width: on ? 2 : 1),
                      ),
                      child: Row(
                        children: [
                          Text(m.icon,
                              style: const TextStyle(fontSize: 22)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _modifierName(m.id, l10n),
                                  style: TextStyle(
                                    color: color,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w900,
                                    fontFamily: 'monospace',
                                    letterSpacing: 2,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _modifierDesc(m.id, l10n),
                                  style: TextStyle(
                                    color:
                                        Colors.white.withValues(alpha: 0.7),
                                    fontSize: 10,
                                    fontFamily: 'monospace',
                                    height: 1.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '×${m.scoreMultiplier.toStringAsFixed(1)}',
                            style: TextStyle(
                              color: m.scoreMultiplier > 1.0
                                  ? NeonColors.green
                                  : Colors.amber,
                              fontSize: 11,
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              ),
            ),
            // Iter 19 (utente: "auto-advance on tap"): rimosso bottone
            // AVANTI bottom — tap su card mod chiama _tapMod → onConfirm.
          ],
        ),
      ),
    );
  }

  /// Card di conferma in cima alla lista. Funge da pulsante AVANTI.
  /// - Nessun modificatore attivo: stile cyan "NESSUN MODIFICATORE" (×1.0).
  /// - Modificatori attivi: stile oro con i NOMI dei mod a sinistra e il loro
  ///   moltiplicatore TOTALE dei punti a destra (richiesta utente).
  /// Tap → avanza al prossimo step con la selezione corrente.
  Widget _buildConfirmCard(AppLocalizations l10n) {
    if (_active.isEmpty) {
      final color = NeonColors.cyan.withValues(alpha: 0.85);
      return GestureDetector(
        onTap: _confirm,
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: color.withValues(alpha: 0.10),
            border: Border.all(color: color, width: 2),
          ),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: color, width: 1.6),
                ),
                alignment: Alignment.center,
                child: Icon(Icons.block_rounded, color: color, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.modNoneCard,
                      style: TextStyle(
                        color: color,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        fontFamily: 'monospace',
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.modNoneCardDesc,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 10,
                        fontFamily: 'monospace',
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '×1.0',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 11,
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      );
    }
    // Stato con modificatori attivi: oro + nomi + moltiplicatore totale.
    final names = _active.map((id) => _modifierName(id, l10n)).join(', ');
    final total = combinedScoreMultiplier(_active);
    return GestureDetector(
      onTap: _confirm,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          gradient: LinearGradient(
            colors: [
              NeonColors.gold.withValues(alpha: 0.20),
              NeonColors.gold.withValues(alpha: 0.05),
            ],
          ),
          border: Border.all(
            color: NeonColors.gold.withValues(alpha: 0.9),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: NeonColors.gold.withValues(alpha: 0.35),
              blurRadius: 12,
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: NeonColors.gold, width: 1.6),
              ),
              alignment: Alignment.center,
              child: const Icon(Icons.play_arrow_rounded,
                  color: NeonColors.gold, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    names,
                    style: const TextStyle(
                      color: NeonColors.gold,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'monospace',
                      letterSpacing: 1.2,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    l10n.modifiersActiveCount(_active.length, _maxActive),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 10,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Moltiplicatore totale dei punti dei modificatori attivi.
            Text(
              '×${total.toStringAsFixed(2)}',
              style: const TextStyle(
                color: NeonColors.gold,
                fontSize: 15,
                fontWeight: FontWeight.w900,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
