import 'package:flutter/material.dart';
import '../../data/constants.dart';
import '../../data/difficulty.dart';
import '../../data/modifiers.dart';
import '../../data/pet_types.dart';
import '../../data/save_data.dart';
import '../../l10n/generated/app_localizations.dart';
import '../widgets/neon_back_button.dart';

/// Schermata RIEPILOGO pre-game (richiesta utente: "schermata di riepilogo
/// alla fine ... con riepilogo di calcolo dei moltiplicatori applicati da
/// difficoltà e modificatori").
///
/// Mostra:
/// - Mode selezionato
/// - Difficoltà selezionata
/// - Modificatori attivi
/// - Loadout (arma + pet)
/// - Multipliers breakdown: difficoltà ×, modifier ×, total ×
/// - Bottone START → game.
class SummaryScreen extends StatefulWidget {
  final GameMode mode;
  final Difficulty difficulty;
  final List<String> activeModifiers;
  final VoidCallback onBack;
  final VoidCallback onStart;

  const SummaryScreen({
    super.key,
    required this.mode,
    required this.difficulty,
    required this.activeModifiers,
    required this.onBack,
    required this.onStart,
  });

  @override
  State<SummaryScreen> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends State<SummaryScreen> {
  late final SaveData _saveData;

  final ScrollController _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _saveData = SaveManager.load();
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  GameMode get mode => widget.mode;
  Difficulty get difficulty => widget.difficulty;
  List<String> get activeModifiers => widget.activeModifiers;
  VoidCallback get onBack => widget.onBack;
  VoidCallback get onStart => widget.onStart;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final saveData = _saveData;
    final diffCfg = difficultyConfigs[difficulty]!;
    final modScore = combinedScoreMultiplier(activeModifiers);
    final totalScore = diffCfg.scoreMultiplier * modScore;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                children: [
                  NeonBackButton(onTap: onBack),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l10n.summaryTitle,
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
                    child: const Text(
                      '5/5',
                      style: TextStyle(
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
                child: ListView(
                controller: _scrollCtrl,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _section(l10n.modeTitle, _modeName(mode), NeonColors.cyan),
                  _section(l10n.diffTitle, diffCfg.name, _diffColor(difficulty),
                      sub: '×${diffCfg.scoreMultiplier.toStringAsFixed(2)} score · '
                          'HP ×${diffCfg.enemyHpMultiplier} · '
                          'SPD ×${diffCfg.enemySpeedMultiplier}'),
                  // Pacifist: skip ARMA + PET (non si spara, no pet).
                  if (mode != GameMode.pacifist) ...[
                    _section(l10n.loadoutWeapon,
                        saveData.startingWeapon.toUpperCase(),
                        NeonColors.bulletYellow),
                    _section(
                        l10n.loadoutPet,
                        saveData.activePet == 'none'
                            ? l10n.loadoutPetNone
                            : (petDefById(saveData.activePet)?.displayName ??
                                saveData.activePet.toUpperCase()),
                        NeonColors.pink),
                  ],
                  _modifiersSection(l10n),
                  const SizedBox(height: 12),
                  _multiplierBreakdown(l10n, diffCfg.scoreMultiplier, modScore,
                      totalScore),
                ],
              ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: GestureDetector(
                onTap: onStart,
                child: Container(
                  height: 56,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: NeonColors.green.withValues(alpha: 0.18),
                    border: Border.all(
                        color: NeonColors.green.withValues(alpha: 0.9),
                        width: 2),
                    boxShadow: [
                      BoxShadow(
                          color: NeonColors.green.withValues(alpha: 0.5),
                          blurRadius: 18)
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    l10n.loadoutStart,
                    style: const TextStyle(
                      color: NeonColors.green,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'monospace',
                      letterSpacing: 5,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _modeName(GameMode m) {
    final l10n = AppLocalizations.of(context)!;
    switch (m) {
      case GameMode.classic: return l10n.modeClassic;
      case GameMode.zenMode: return l10n.modeZen;
      case GameMode.tunnel: return l10n.modeTunnel;
      case GameMode.bossRush: return l10n.modeBossRush;
      case GameMode.timeAttack: return l10n.modeTimeAttack;
      case GameMode.survival: return l10n.modeSurvival;
      case GameMode.dailyChallenge: return l10n.modeDailyChallenge;
      case GameMode.pacifist: return l10n.modePacifist;
      case GameMode.waves: return l10n.modeWaves;
      case GameMode.gravityInferno: return l10n.modeGravityInferno;
    }
  }

  Color _diffColor(Difficulty d) {
    switch (d) {
      case Difficulty.easy: return NeonColors.green;
      case Difficulty.normal: return NeonColors.cyan;
      case Difficulty.hard: return NeonColors.orange;
      case Difficulty.nightmare: return NeonColors.red;
    }
  }

  Widget _section(String label, String value, Color color, {String? sub}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: color.withValues(alpha: 0.08),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: TextStyle(
                color: color.withValues(alpha: 0.7),
                fontSize: 10,
                fontWeight: FontWeight.w900,
                fontFamily: 'monospace',
                letterSpacing: 2,
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    color: color,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'monospace',
                    letterSpacing: 2,
                  ),
                ),
                if (sub != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    sub,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 9,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _modifiersSection(AppLocalizations l10n) {
    if (activeModifiers.isEmpty) {
      return _section(l10n.modifiersTitle, l10n.summaryNone,
          Colors.white.withValues(alpha: 0.5));
    }
    final names = activeModifiers
        .map((id) => getModifier(id)?.name ?? id)
        .join(', ');
    final mult = combinedScoreMultiplier(activeModifiers);
    return _section(l10n.modifiersTitle, names, const Color(0xFFFF4466),
        sub: l10n.summaryActiveModifiers(
            activeModifiers.length, mult.toStringAsFixed(2)));
  }

  Widget _multiplierBreakdown(
      AppLocalizations l10n, double diffMul, double modMul, double total) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        gradient: LinearGradient(
          colors: [
            NeonColors.gold.withValues(alpha: 0.18),
            NeonColors.gold.withValues(alpha: 0.04),
          ],
        ),
        border: Border.all(color: NeonColors.gold.withValues(alpha: 0.7), width: 2),
        boxShadow: [
          BoxShadow(color: NeonColors.gold.withValues(alpha: 0.3), blurRadius: 14)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.summaryScoreMultiplierTitle,
            style: const TextStyle(
              color: NeonColors.gold,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              fontFamily: 'monospace',
              letterSpacing: 3,
            ),
          ),
          const SizedBox(height: 10),
          _row(l10n.summaryDifficultyRow, '×${diffMul.toStringAsFixed(2)}'),
          _row(l10n.summaryModifiersRow, '×${modMul.toStringAsFixed(2)}'),
          const Divider(color: Colors.white24),
          _row(l10n.summaryTotal, '×${total.toStringAsFixed(2)}',
              big: true),
        ],
      ),
    );
  }

  Widget _row(String label, String val, {bool big = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: big ? 0.95 : 0.7),
              fontSize: big ? 14 : 12,
              fontFamily: 'monospace',
              fontWeight: big ? FontWeight.w900 : FontWeight.normal,
            ),
          ),
          Text(
            val,
            style: TextStyle(
              color: big ? NeonColors.gold : Colors.white,
              fontSize: big ? 18 : 13,
              fontWeight: FontWeight.w900,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}
