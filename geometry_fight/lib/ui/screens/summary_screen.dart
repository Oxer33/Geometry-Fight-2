import 'package:flutter/material.dart';
import '../../data/constants.dart';
import '../../data/difficulty.dart';
import '../../data/daily_challenge.dart';
import '../../data/modifiers.dart';
import '../../data/save_data.dart';
import '../../l10n/generated/app_localizations.dart';
import '../widgets/neon_back_button.dart';

/// Localized difficulty label (matches helper in difficulty_select_screen).
String _diffName(AppLocalizations l10n, Difficulty d) {
  switch (d) {
    case Difficulty.easy:
      return l10n.diffEasy;
    case Difficulty.normal:
      return l10n.diffNormal;
    case Difficulty.hard:
      return l10n.diffHard;
    case Difficulty.nightmare:
      return l10n.diffNightmare;
  }
}

/// Localized weapon label by id (mirrors shop_screen `_weaponName`).
String _weaponName(AppLocalizations l10n, String id) {
  switch (id) {
    case 'basic':
      return l10n.weaponNameBasic;
    case 'triple':
      return l10n.weaponNameTriple;
    case 'spread':
      return l10n.weaponNameSpread;
    case 'ricochet':
      return l10n.weaponNameRicochet;
    case 'homing':
      return l10n.weaponNameHoming;
    case 'plasma':
      return l10n.weaponNamePlasma;
    case 'laser':
      return l10n.weaponNameLaser;
    case 'gauss':
      return l10n.weaponNameGauss;
    case 'chain':
      return l10n.weaponNameChain;
    default:
      return id.toUpperCase();
  }
}

/// Localized pet label by id (mirrors shop_screen `_petName`).
String _petName(AppLocalizations l10n, String id) {
  switch (id) {
    case 'attack':
      return l10n.petNameAttack;
    case 'collect':
      return l10n.petNameCollect;
    case 'sweep':
      return l10n.petNameSweep;
    case 'defend':
      return l10n.petNameDefend;
    case 'snipe':
      return l10n.petNameSnipe;
    case 'ram':
      return l10n.petNameRam;
    case 'phoenix':
      return l10n.petNamePhoenix;
    case 'black_hole_pet':
      return l10n.petNameBlackHole;
    case 'emp_drone':
      return l10n.petNameEmpDrone;
    case 'tactical_spotter':
      return l10n.petNameTacticalSpotter;
    default:
      return id.toUpperCase();
  }
}

/// Localized modifier label by id (matches helper in modifiers_select_screen).
String _modifierLabel(AppLocalizations l10n, String id) {
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
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: NeonColors.cyan.withValues(alpha: 0.5),
                      ),
                    ),
                    // Step indicator dinamico: pacifist/snake skippano
                    // difficulty + loadout → summary è step 3 di 3 (wizard
                    // corto). Altre modalità è 6 di 6 (wizard completo).
                    child: Text(
                      (mode == GameMode.pacifist || mode == GameMode.snake)
                          ? '3/3'
                          : '6/6',
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
                    const SizedBox(height: 4),
                    // Riga 1: modalità | difficoltà.
                    _twoCol(
                      _section(
                          l10n.modeTitle, _modeName(mode), NeonColors.cyan),
                      _section(
                        l10n.diffTitle,
                        _diffName(l10n, difficulty),
                        _diffColor(difficulty),
                        sub:
                            '×${diffCfg.scoreMultiplier.toStringAsFixed(2)} ${l10n.diffScoreMultiplier} · '
                            'HP ×${diffCfg.enemyHpMultiplier} · '
                            'SPD ×${diffCfg.enemySpeedMultiplier}',
                      ),
                    ),
                    // Riga 2: arma | pet. Pacifist & Snake li saltano (non si
                    // spara, no pet) → niente riga loadout.
                    if (mode != GameMode.pacifist && mode != GameMode.snake)
                      _twoCol(
                        // Daily Challenge: arma + pet auto-assegnati dalla data
                        // UTC (uguali per tutti), non dal loadout salvato.
                        () {
                          final isDaily = mode == GameMode.dailyChallenge;
                          final weaponId = isDaily
                              ? DailyChallenge.todayWeaponId
                              : saveData.startingWeapon;
                          return _section(
                            l10n.loadoutWeapon,
                            _weaponName(l10n, weaponId),
                            NeonColors.bulletYellow,
                            sub: isDaily ? l10n.modeDailyChallenge : null,
                          );
                        }(),
                        () {
                          final isDaily = mode == GameMode.dailyChallenge;
                          final petId = isDaily
                              ? DailyChallenge.todayPetId
                              : saveData.activePet;
                          return _section(
                            l10n.loadoutPet,
                            petId == 'none'
                                ? l10n.loadoutPetNone
                                : _petName(l10n, petId),
                            NeonColors.pink,
                            sub: isDaily ? l10n.modeDailyChallenge : null,
                          );
                        }(),
                      ),
                    // Modificatori: full width (possono essere molti).
                    _modifiersSection(l10n),
                    const SizedBox(height: 12),
                    // Score multiplier: full width.
                    _multiplierBreakdown(
                      l10n,
                      diffCfg.scoreMultiplier,
                      modScore,
                      totalScore,
                    ),
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
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: NeonColors.green.withValues(alpha: 0.5),
                        blurRadius: 18,
                      ),
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
      case GameMode.classic:
        return l10n.modeClassic;
      case GameMode.zenMode:
        return l10n.modeZen;
      case GameMode.tunnel:
        return l10n.modeTunnel;
      case GameMode.bossRush:
        return l10n.modeBossRush;
      case GameMode.timeAttack:
        return l10n.modeTimeAttack;
      case GameMode.survival:
        return l10n.modeSurvival;
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

  Color _diffColor(Difficulty d) {
    switch (d) {
      case Difficulty.easy:
        return NeonColors.green;
      case Difficulty.normal:
        return NeonColors.cyan;
      case Difficulty.hard:
        return NeonColors.orange;
      case Difficulty.nightmare:
        return NeonColors.red;
    }
  }

  /// Card compatta verticale: etichetta in alto, valore sotto, sub opzionale.
  /// Usata sia a piena larghezza (modificatori) sia dentro `_twoCol` (2 col).
  /// Niente margin: lo spacing è gestito dal contenitore (twoCol / ListView).
  Widget _section(String label, String value, Color color, {String? sub}) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: color.withValues(alpha: 0.08),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: color.withValues(alpha: 0.7),
              fontSize: 10,
              fontWeight: FontWeight.w900,
              fontFamily: 'monospace',
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.w900,
              fontFamily: 'monospace',
              letterSpacing: 1.5,
            ),
          ),
          if (sub != null) ...[
            const SizedBox(height: 3),
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
    );
  }

  /// Due card affiancate su 2 colonne, di pari altezza (IntrinsicHeight +
  /// CrossAxisAlignment.stretch così la card più corta si allunga a pareggiare).
  Widget _twoCol(Widget left, Widget right) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: left),
            const SizedBox(width: 8),
            Expanded(child: right),
          ],
        ),
      ),
    );
  }

  Widget _modifiersSection(AppLocalizations l10n) {
    if (activeModifiers.isEmpty) {
      return _section(
        l10n.modifiersTitle,
        l10n.summaryNone,
        Colors.white.withValues(alpha: 0.5),
      );
    }
    final names = activeModifiers
        .map((id) => _modifierLabel(l10n, id))
        .join(', ');
    final mult = combinedScoreMultiplier(activeModifiers);
    return _section(
      l10n.modifiersTitle,
      names,
      const Color(0xFFFF4466),
      sub: l10n.summaryActiveModifiers(
        activeModifiers.length,
        mult.toStringAsFixed(2),
      ),
    );
  }

  Widget _multiplierBreakdown(
    AppLocalizations l10n,
    double diffMul,
    double modMul,
    double total,
  ) {
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
        border: Border.all(
          color: NeonColors.gold.withValues(alpha: 0.7),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: NeonColors.gold.withValues(alpha: 0.3),
            blurRadius: 14,
          ),
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
          _row(l10n.summaryTotal, '×${total.toStringAsFixed(2)}', big: true),
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
