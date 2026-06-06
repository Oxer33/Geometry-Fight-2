import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../data/constants.dart';
import '../../data/pet_types.dart';
import '../../data/save_data.dart';
import '../../l10n/generated/app_localizations.dart';
import '../widgets/neon_back_button.dart';

/// Localized weapon label by id (mirrors shop_screen `_weaponName`). Falls
/// back to the catalog English when an id is unknown (defensive).
String _weaponName(AppLocalizations l10n, String id, String fallback) {
  switch (id) {
    case 'basic': return l10n.weaponNameBasic;
    case 'triple': return l10n.weaponNameTriple;
    case 'spread': return l10n.weaponNameSpread;
    case 'ricochet': return l10n.weaponNameRicochet;
    case 'homing': return l10n.weaponNameHoming;
    case 'plasma': return l10n.weaponNamePlasma;
    case 'laser': return l10n.weaponNameLaser;
    case 'gauss': return l10n.weaponNameGauss;
    case 'chain': return l10n.weaponNameChain;
    default: return fallback;
  }
}

/// Localized pet label by id (mirrors shop_screen `_petName`).
String _petName(AppLocalizations l10n, String id, String fallback) {
  switch (id) {
    case 'attack': return l10n.petNameAttack;
    case 'collect': return l10n.petNameCollect;
    case 'sweep': return l10n.petNameSweep;
    case 'defend': return l10n.petNameDefend;
    case 'snipe': return l10n.petNameSnipe;
    case 'ram': return l10n.petNameRam;
    case 'phoenix': return l10n.petNamePhoenix;
    case 'black_hole_pet': return l10n.petNameBlackHole;
    case 'emp_drone': return l10n.petNameEmpDrone;
    case 'tactical_spotter': return l10n.petNameTacticalSpotter;
    default: return fallback;
  }
}

/// Schermata Loadout — pre-game weapon + pet selection in DUE STEP
/// (richiesta utente: "due schermate, una per le armi e una per i pet,
/// senza scroll, bottoni più piccoli").
///
/// Step 0: ARMA — 7 cards weapon (BASIC/TRIPLE/SPREAD/RICOCHET/HOMING/PLASMA/LASER)
///                + bottone "AVANTI" → step 1.
/// Step 1: PET  — 7 cards pet (NESSUNO + 6 da kPetCatalog)
///                + bottone "AVVIA PARTITA" → onConfirm.
///
/// Layout responsivo: GridView.count colonne 4 → cards ~90px senza scroll.
class LoadoutScreen extends StatefulWidget {
  final VoidCallback onBack;
  final VoidCallback onConfirm;

  /// Step interno iniziale: 0 = armi (4/6), 1 = pet (5/6). Default 0.
  /// Passato a 1 quando si rientra dal summary, così il bottone indietro
  /// del summary torna alla schermata PET e non a quella delle armi
  /// (richiesta utente).
  final int initialStep;

  const LoadoutScreen({
    super.key,
    required this.onBack,
    required this.onConfirm,
    this.initialStep = 0,
  });

  @override
  State<LoadoutScreen> createState() => _LoadoutScreenState();
}

class _LoadoutScreenState extends State<LoadoutScreen> {
  late SaveData _saveData;
  int _step = 0; // 0 = weapons, 1 = pets

  // Caveman-review: guard rapid double-tap on pet card from re-firing
  // widget.onConfirm() (which navigates to summary). Weapon tap calls
  // _next() which is internal step transition — also guarded to avoid
  // skipping past pet step. Widget unmounts on onConfirm so no reset.
  bool _isAdvancing = false;

  @override
  void initState() {
    super.initState();
    _saveData = SaveManager.load();
    // Seed dello step interno. Di norma 0 (armi); se rientriamo dal summary
    // (initialStep = 1) partiamo dai pet. Clamp difensivo a [0, 1].
    _step = widget.initialStep.clamp(0, 1);
  }

  // Iter 18 (utente: "show ALL weapons"): catalog allineato a shop_screen
  // (_kTotalWeapons = 9). Locked weapons grigi + lock icon nella card.
  // Gli id corrispondono a SaveData.unlockedWeapons / startingWeapon e a
  // Player.setWeaponFromId. WeaponType enum (player.dart) include anche
  // spreadFan/overdrive — sono powerup-only (drop in-game), non loadout.
  static const _weaponCatalog = [
    _WeaponEntry('basic', 'BASIC'),
    _WeaponEntry('triple', 'TRIPLE'),
    _WeaponEntry('spread', 'SPREAD'),
    _WeaponEntry('ricochet', 'RICOCH.'),
    _WeaponEntry('homing', 'HOMING'),
    _WeaponEntry('plasma', 'PLASMA'),
    _WeaponEntry('laser', 'LASER'),
    _WeaponEntry('gauss', 'GAUSS'),
    _WeaponEntry('chain', 'CHAIN'),
  ];

  // Iter 19 (utente: "tap auto-advance pre-game"). Weapon tap:
  // unlocked → select + advance to pets; locked → snackbar, no advance.
  // Caveman-review: locked tap does NOT set _isAdvancing (snackbar only),
  // so user can immediately retap an unlocked card.
  void _selectWeapon(String id) {
    if (_isAdvancing) return;
    if (!_saveData.unlockedWeapons.contains(id)) {
      final l10n = AppLocalizations.of(context)!;
      _showLockedSnack(l10n.loadoutLocked);
      return;
    }
    setState(() => _saveData = _saveData.copyWith(startingWeapon: id));
    unawaited(SaveManager.save(_saveData));
    _next();
  }

  // Iter 19: pet tap. Unlocked (incluso 'none') → select + onConfirm
  // (advance to summary). Locked → snackbar, no advance.
  // Caveman-review: _isAdvancing guards against double-tap re-firing
  // onConfirm which would push summary route twice. Locked tap skips guard.
  void _selectPet(String id) {
    if (_isAdvancing) return;
    if (id != 'none' && !_saveData.unlockedPets.contains(id)) {
      final l10n = AppLocalizations.of(context)!;
      _showLockedSnack(l10n.loadoutPetLocked);
      return;
    }
    _isAdvancing = true;
    setState(() => _saveData = _saveData.copyWith(activePet: id));
    unawaited(SaveManager.save(_saveData));
    widget.onConfirm();
  }

  void _showLockedSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: const TextStyle(fontFamily: 'monospace'),
        ),
        backgroundColor: Colors.amber.shade800,
        duration: const Duration(milliseconds: 900),
      ),
    );
  }

  void _next() {
    setState(() => _step = 1);
  }

  void _backStep() {
    if (_step == 1) {
      setState(() => _step = 0);
    } else {
      widget.onBack();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isWeaponsStep = _step == 0;
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                children: [
                  NeonBackButton(onTap: _backStep),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      isWeaponsStep
                          ? '${l10n.loadoutTitle} — ${l10n.loadoutWeapon}'
                          : '${l10n.loadoutTitle} — ${l10n.loadoutPet}',
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
                  // Step indicator (1/2 o 2/2)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: NeonColors.cyan.withValues(alpha: 0.5)),
                    ),
                    child: Text(
                      // Wizard a 6 step: mode(1)→diff(2)→mods(3)→arma(4)→
                      // pet(5)→summary(6). Arma e pet sono due schermate
                      // distinte (sub-step interno _step) → 4/6 e 5/6.
                      isWeaponsStep ? '4/6' : '5/6',
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
            // Content (no scroll)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child:
                    isWeaponsStep ? _buildWeaponsGrid() : _buildPetsGrid(),
              ),
            ),
            // Iter 19 (utente: "auto-advance on tap"): rimosso bottone
            // AVANTI / AVVIA PARTITA bottom — tap su weapon → _next() (pet
            // page); tap su pet → widget.onConfirm() (summary).
          ],
        ),
      ),
    );
  }

  Widget _buildWeaponsGrid() {
    // Wrap con SizedBox espliciti — risolve overflow precedente del GridView
    // childAspectRatio (cards ~200px tall × 2 rows = 400px > available 358px
    // → row 2 tagliata da footer button). Fixed 145×80 + Wrap = altezza
    // garantita ~170px sempre dentro available. Stile match _NeonModeCard.
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        alignment: WrapAlignment.center,
        children: _weaponCatalog.map((w) {
          final localizedTitle = _weaponName(l10n, w.id, w.displayName);
          return _NeonLoadoutCard(
            title: localizedTitle,
            isSelected: _saveData.startingWeapon == w.id,
            isUnlocked: _saveData.unlockedWeapons.contains(w.id),
            color: NeonColors.cyan,
            iconLetter: localizedTitle.isNotEmpty
                ? localizedTitle.substring(0, 1)
                : w.displayName.substring(0, 1),
            onTap: () => _selectWeapon(w.id),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPetsGrid() {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        alignment: WrapAlignment.center,
        children: [
          _NeonLoadoutCard(
            title: l10n.loadoutPetNone,
            isSelected: _saveData.activePet == 'none',
            isUnlocked: true,
            color: const Color(0xFF888888),
            iconLetter: '–',
            onTap: () => _selectPet('none'),
          ),
          ...kPetCatalog.map((p) => _NeonLoadoutCard(
                title: _petName(l10n, p.id, p.displayName),
                isSelected: _saveData.activePet == p.id,
                isUnlocked: _saveData.unlockedPets.contains(p.id),
                color: p.color,
                iconLetter: p.iconCode,
                petType: p.type,
                onTap: () => _selectPet(p.id),
              )),
        ],
      ),
    );
  }
}

class _WeaponEntry {
  final String id;
  final String displayName;
  const _WeaponEntry(this.id, this.displayName);
}

/// Card neon loadout — match stile `_NeonModeCard` (mode_select_screen).
/// SizedBox 145×80 fixed → niente overflow su 2 rows + footer button.
/// Layout: badge lettera 28×28 + Text colonna (title + lock) padding 10.
class _NeonLoadoutCard extends StatelessWidget {
  final String title;
  final String iconLetter;
  final bool isSelected;
  final bool isUnlocked;
  final Color color;
  final VoidCallback onTap;
  // Iter 9: se present, render visuale del pet via CustomPaint invece
  // della lettera (richiesta utente "metti il pet nelle card").
  final PetType? petType;

  const _NeonLoadoutCard({
    required this.title,
    required this.iconLetter,
    required this.isSelected,
    required this.isUnlocked,
    required this.color,
    required this.onTap,
    this.petType,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final disabled = !isUnlocked;
    final eff = disabled ? const Color(0xFF555555) : color;
    // Caveman-review: locked cards still tappable so the selector can show a
    // "buy first" snackbar instead of silently swallowing the gesture.
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: 145,
        height: 80,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          gradient: isSelected
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    eff.withValues(alpha: 0.22),
                    eff.withValues(alpha: 0.06),
                  ],
                )
              : LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    eff.withValues(alpha: 0.08),
                    Colors.black.withValues(alpha: 0.2),
                  ],
                ),
          border: Border.all(
            color: isSelected
                ? eff.withValues(alpha: 0.95)
                : eff.withValues(alpha: 0.35),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                      color: eff.withValues(alpha: 0.45),
                      blurRadius: 14,
                      spreadRadius: -2)
                ]
              : null,
        ),
        child: Row(
          children: [
            // Badge: lettera per armi, CustomPaint shape per pet (iter 9).
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: eff.withValues(alpha: 0.18),
                border: Border.all(color: eff, width: 1.6),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                            color: eff.withValues(alpha: 0.5),
                            blurRadius: 8)
                      ]
                    : null,
              ),
              alignment: Alignment.center,
              child: petType != null
                  ? CustomPaint(
                      size: const Size(28, 28),
                      painter: _PetIconPainter(
                        type: petType!,
                        color: eff,
                      ),
                    )
                  : Text(
                      iconLetter,
                      style: TextStyle(
                        color: eff,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        fontFamily: 'monospace',
                      ),
                    ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: eff,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'monospace',
                      letterSpacing: 1.5,
                      shadows: isSelected
                          ? [
                              Shadow(
                                  color: eff.withValues(alpha: 0.5),
                                  blurRadius: 4)
                            ]
                          : null,
                    ),
                  ),
                  if (disabled)
                    Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: Row(
                        children: [
                          Icon(Icons.lock,
                              size: 9,
                              color:
                                  Colors.amber.withValues(alpha: 0.7)),
                          const SizedBox(width: 3),
                          Text(
                            l10n.menuShop,
                            style: TextStyle(
                              color:
                                  Colors.amber.withValues(alpha: 0.7),
                              fontSize: 8,
                              fontFamily: 'monospace',
                            ),
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
    );
  }
}

/// Painter per icona pet stilizzata nelle card loadout (iter 9).
/// Disegna shape semplificato per ogni `PetType` matching color.
class _PetIconPainter extends CustomPainter {
  final PetType type;
  final Color color;

  _PetIconPainter({required this.type, required this.color});

  // Iter 13 (caveman-review): instance fields invece di static per
  // evitare shared paint state corruption se più painter parallel.
  final Paint _fill = Paint();
  final Paint _stroke = Paint()..style = PaintingStyle.stroke;

  @override
  void paint(Canvas canvas, Size size) {
    // Clip a canvas bounds (iter 9 fix): _PetIconPainter rendeva bullet
    // attack a cy-1.2r → fuori dal canvas (cy-r=0). ClipRect previene
    // bleed nei layout circostanti.
    canvas.clipRect(Offset.zero & size);

    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = math.min(size.width, size.height) / 2;
    // Reset full paint state at entry (iter 9 fix: static paints riusati
    // potrebbero mantenere strokeWidth/color stantii dal precedente paint).
    _fill
      ..color = color
      ..style = PaintingStyle.fill
      ..maskFilter = null;
    _stroke
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..maskFilter = null;

    switch (type) {
      case PetType.attack:
        // Triangolo punta su (mini ship gunner). Clampato dentro canvas.
        final path = Path()
          ..moveTo(cx, cy - r * 0.7)
          ..lineTo(cx + r * 0.6, cy + r * 0.55)
          ..lineTo(cx - r * 0.6, cy + r * 0.55)
          ..close();
        canvas.drawPath(path, _fill);
        // Mini canna (entro canvas)
        _stroke.strokeWidth = 1.6;
        canvas.drawLine(Offset(cx, cy - r * 0.7), Offset(cx, cy - r * 0.88), _stroke);
        // Bullet pre-spara (iter 13 fix: ridotto da 0.95→0.85 per stare
        // completamente dentro canvas — radius 1.4 + cy-r*0.95 era half-clipped).
        _fill.color = const Color(0xFFFFFFFF);
        canvas.drawCircle(Offset(cx, cy - r * 0.85), 1.2, _fill);
      case PetType.collect:
        // Esagono cyan con cerchio interno (geom magnet feel).
        final path = Path();
        for (int i = 0; i < 6; i++) {
          final ang = i * math.pi / 3 - math.pi / 2;
          final x = cx + math.cos(ang) * r * 0.85;
          final y = cy + math.sin(ang) * r * 0.85;
          if (i == 0) {
            path.moveTo(x, y);
          } else {
            path.lineTo(x, y);
          }
        }
        path.close();
        canvas.drawPath(path, _stroke);
        // Geom centrale (rombo)
        final geom = Path()
          ..moveTo(cx, cy - r * 0.4)
          ..lineTo(cx + r * 0.35, cy)
          ..lineTo(cx, cy + r * 0.4)
          ..lineTo(cx - r * 0.35, cy)
          ..close();
        canvas.drawPath(geom, _fill);
      case PetType.sweep:
        // Stella 4 punte rotante (orbita).
        final path = Path();
        for (int i = 0; i < 8; i++) {
          final ang = i * math.pi / 4 - math.pi / 2;
          final radius = (i.isEven) ? r * 0.95 : r * 0.35;
          final x = cx + math.cos(ang) * radius;
          final y = cy + math.sin(ang) * radius;
          if (i == 0) {
            path.moveTo(x, y);
          } else {
            path.lineTo(x, y);
          }
        }
        path.close();
        canvas.drawPath(path, _fill);
      case PetType.defend:
        // Pentagono shield + barra orizzontale interna.
        final path = Path();
        for (int i = 0; i < 5; i++) {
          final ang = i * math.pi * 2 / 5 - math.pi / 2;
          final x = cx + math.cos(ang) * r * 0.9;
          final y = cy + math.sin(ang) * r * 0.9;
          if (i == 0) {
            path.moveTo(x, y);
          } else {
            path.lineTo(x, y);
          }
        }
        path.close();
        canvas.drawPath(path, _fill);
        // Cross interno
        _stroke
          ..color = const Color(0xFFFFFFFF)
          ..strokeWidth = 1.6;
        canvas.drawLine(Offset(cx - r * 0.35, cy), Offset(cx + r * 0.35, cy), _stroke);
        canvas.drawLine(Offset(cx, cy - r * 0.35), Offset(cx, cy + r * 0.1), _stroke);
      case PetType.snipe:
        // Diamond con crosshair.
        final path = Path()
          ..moveTo(cx, cy - r * 0.85)
          ..lineTo(cx + r * 0.55, cy)
          ..lineTo(cx, cy + r * 0.85)
          ..lineTo(cx - r * 0.55, cy)
          ..close();
        canvas.drawPath(path, _stroke);
        // Crosshair lines
        _stroke.strokeWidth = 1.0;
        canvas.drawLine(Offset(cx - r * 0.95, cy), Offset(cx + r * 0.95, cy), _stroke);
        canvas.drawLine(Offset(cx, cy - r * 0.95), Offset(cx, cy + r * 0.95), _stroke);
        _fill.color = color;
        canvas.drawCircle(Offset(cx, cy), 2.0, _fill);
      case PetType.ram:
        // Chevron freccia (impatto).
        _stroke
          ..color = color
          ..strokeWidth = 2.5;
        final path = Path()
          ..moveTo(cx - r * 0.7, cy + r * 0.5)
          ..lineTo(cx, cy - r * 0.5)
          ..lineTo(cx + r * 0.7, cy + r * 0.5);
        canvas.drawPath(path, _stroke);
        // Doppia freccia
        final path2 = Path()
          ..moveTo(cx - r * 0.7, cy + r * 0.85)
          ..lineTo(cx, cy - r * 0.15)
          ..lineTo(cx + r * 0.7, cy + r * 0.85);
        _stroke.strokeWidth = 1.6;
        canvas.drawPath(path2, _stroke);
      case PetType.none:
        // Default: cerchio vuoto
        canvas.drawCircle(Offset(cx, cy), r * 0.5, _stroke);
      // Nuovi pet (swap roster): phoenix / blackHolePet / empDrone /
      // tacticalSpotter. Icone stilizzate matching color + concept.
      case PetType.phoenix:
        // Fiamma stilizzata (ali spiegate + nucleo).
        final wings = Path()
          ..moveTo(cx, cy - r * 0.85)
          ..lineTo(cx + r * 0.75, cy)
          ..lineTo(cx + r * 0.4, cy + r * 0.25)
          ..lineTo(cx, cy + r * 0.85)
          ..lineTo(cx - r * 0.4, cy + r * 0.25)
          ..lineTo(cx - r * 0.75, cy)
          ..close();
        canvas.drawPath(wings, _fill);
        // Spark interno bianco.
        _fill.color = const Color(0xFFFFFFFF);
        canvas.drawCircle(Offset(cx, cy), r * 0.18, _fill);
      case PetType.blackHolePet:
        // Disco scuro + anello viola (event horizon).
        _stroke.strokeWidth = 1.8;
        canvas.drawCircle(Offset(cx, cy), r * 0.85, _stroke);
        // Disco centrale nero.
        final blackDisc = Paint()
          ..color = const Color(0xFF000000)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(Offset(cx, cy), r * 0.45, blackDisc);
        // Ring orbitale interno.
        _stroke.strokeWidth = 1.2;
        canvas.drawCircle(Offset(cx, cy), r * 0.55, _stroke);
      case PetType.empDrone:
        // Hexagon + 4 antenne cardinali (waveform feel).
        final hex = Path();
        for (int i = 0; i < 6; i++) {
          final a = i * math.pi / 3;
          final x = cx + math.cos(a) * r * 0.55;
          final y = cy + math.sin(a) * r * 0.55;
          if (i == 0) {
            hex.moveTo(x, y);
          } else {
            hex.lineTo(x, y);
          }
        }
        hex.close();
        canvas.drawPath(hex, _fill);
        // Antenne EMP (4 punte cardinali).
        _stroke
          ..color = const Color(0xFFFFFFFF)
          ..strokeWidth = 1.6;
        canvas.drawLine(Offset(cx, cy - r * 0.6),
            Offset(cx, cy - r * 0.95), _stroke);
        canvas.drawLine(Offset(cx, cy + r * 0.6),
            Offset(cx, cy + r * 0.95), _stroke);
        canvas.drawLine(Offset(cx - r * 0.6, cy),
            Offset(cx - r * 0.95, cy), _stroke);
        canvas.drawLine(Offset(cx + r * 0.6, cy),
            Offset(cx + r * 0.95, cy), _stroke);
      case PetType.tacticalSpotter:
        // Scope: cerchio + crosshair + dot centrale.
        _stroke
          ..color = color
          ..strokeWidth = 1.8;
        canvas.drawCircle(Offset(cx, cy), r * 0.7, _stroke);
        _stroke
          ..color = const Color(0xFFFFFFFF)
          ..strokeWidth = 1.0;
        canvas.drawLine(Offset(cx - r * 0.95, cy),
            Offset(cx + r * 0.95, cy), _stroke);
        canvas.drawLine(Offset(cx, cy - r * 0.95),
            Offset(cx, cy + r * 0.95), _stroke);
        _fill.color = color;
        canvas.drawCircle(Offset(cx, cy), r * 0.18, _fill);
      case PetType.slower:
        // Orologio: cerchio + due lancette + perno (metafora "rallenta tempo").
        _stroke
          ..color = color
          ..strokeWidth = 1.8;
        canvas.drawCircle(Offset(cx, cy), r * 0.78, _stroke);
        _stroke
          ..color = const Color(0xFFFFFFFF)
          ..strokeWidth = 1.4;
        canvas.drawLine(Offset(cx, cy), Offset(cx, cy - r * 0.42), _stroke);
        canvas.drawLine(Offset(cx, cy), Offset(cx + r * 0.6, cy), _stroke);
        _fill.color = color;
        canvas.drawCircle(Offset(cx, cy), r * 0.16, _fill);
    }
  }

  @override
  bool shouldRepaint(_PetIconPainter old) =>
      old.type != type || old.color != color;
}
