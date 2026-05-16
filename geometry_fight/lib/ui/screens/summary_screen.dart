import 'package:flutter/material.dart';
import '../../data/constants.dart';
import '../../data/difficulty.dart';
import '../../data/modifiers.dart';
import '../../data/pet_types.dart';
import '../../data/save_data.dart';
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

  @override
  void initState() {
    super.initState();
    _saveData = SaveManager.load();
  }

  GameMode get mode => widget.mode;
  Difficulty get difficulty => widget.difficulty;
  List<String> get activeModifiers => widget.activeModifiers;
  VoidCallback get onBack => widget.onBack;
  VoidCallback get onStart => widget.onStart;

  @override
  Widget build(BuildContext context) {
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
                  const Expanded(
                    child: Text(
                      'RIEPILOGO',
                      textAlign: TextAlign.center,
                      style: TextStyle(
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
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _section('MODALITÀ', _modeName(mode), NeonColors.cyan),
                  _section('DIFFICOLTÀ', diffCfg.name, _diffColor(difficulty),
                      sub: '×${diffCfg.scoreMultiplier.toStringAsFixed(2)} score · '
                          'HP ×${diffCfg.enemyHpMultiplier} · '
                          'SPD ×${diffCfg.enemySpeedMultiplier}'),
                  // Pacifist: skip ARMA + PET (non si spara, no pet).
                  if (mode != GameMode.pacifist) ...[
                    _section('ARMA',
                        saveData.startingWeapon.toUpperCase(),
                        NeonColors.bulletYellow),
                    _section(
                        'PET',
                        saveData.activePet == 'none'
                            ? 'NESSUNO'
                            : (petDefById(saveData.activePet)?.displayName ??
                                saveData.activePet.toUpperCase()),
                        NeonColors.pink),
                  ],
                  _modifiersSection(),
                  const SizedBox(height: 12),
                  _multiplierBreakdown(diffCfg.scoreMultiplier, modScore,
                      totalScore),
                ],
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
                  child: const Text(
                    'AVVIA PARTITA',
                    style: TextStyle(
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
    switch (m) {
      case GameMode.classic: return 'CLASSIC';
      case GameMode.zenMode: return 'ZEN';
      case GameMode.tunnel: return 'TUNNEL';
      case GameMode.bossRush: return 'BOSS RUSH';
      case GameMode.timeAttack: return 'TIME ATTACK';
      case GameMode.survival: return 'SURVIVAL';
      case GameMode.dailyChallenge: return 'DAILY';
      case GameMode.pacifist: return 'PACIFIST';
      case GameMode.waves: return 'WAVES';
      case GameMode.gravityInferno: return 'GRAVITY INFERNO';
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

  Widget _modifiersSection() {
    if (activeModifiers.isEmpty) {
      return _section('MODIFICATORI', 'Nessuno',
          Colors.white.withValues(alpha: 0.5));
    }
    final names = activeModifiers
        .map((id) => getModifier(id)?.name ?? id)
        .join(', ');
    final mult = combinedScoreMultiplier(activeModifiers);
    return _section('MODIFICATORI', names, const Color(0xFFFF4466),
        sub: '${activeModifiers.length} attivi · ×${mult.toStringAsFixed(2)} score');
  }

  Widget _multiplierBreakdown(double diffMul, double modMul, double total) {
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
          const Text(
            'MOLTIPLICATORE PUNTEGGIO',
            style: TextStyle(
              color: NeonColors.gold,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              fontFamily: 'monospace',
              letterSpacing: 3,
            ),
          ),
          const SizedBox(height: 10),
          _row('Difficoltà', '×${diffMul.toStringAsFixed(2)}'),
          _row('Modificatori', '×${modMul.toStringAsFixed(2)}'),
          const Divider(color: Colors.white24),
          _row('TOTALE', '×${total.toStringAsFixed(2)}',
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
