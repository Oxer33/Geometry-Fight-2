import 'package:flutter/material.dart';
import '../../data/constants.dart';
import '../../data/pet_types.dart';
import '../../data/save_data.dart';
import '../widgets/neon_back_button.dart';

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

  const LoadoutScreen({
    super.key,
    required this.onBack,
    required this.onConfirm,
  });

  @override
  State<LoadoutScreen> createState() => _LoadoutScreenState();
}

class _LoadoutScreenState extends State<LoadoutScreen> {
  late SaveData _saveData;
  int _step = 0; // 0 = weapons, 1 = pets

  @override
  void initState() {
    super.initState();
    _saveData = SaveManager.load();
  }

  static const _weaponCatalog = [
    _WeaponEntry('basic', 'BASIC'),
    _WeaponEntry('triple', 'TRIPLE'),
    _WeaponEntry('spread', 'SPREAD'),
    _WeaponEntry('ricochet', 'RICOCH.'),
    _WeaponEntry('homing', 'HOMING'),
    _WeaponEntry('plasma', 'PLASMA'),
    _WeaponEntry('laser', 'LASER'),
  ];

  void _selectWeapon(String id) {
    if (!_saveData.unlockedWeapons.contains(id)) return;
    setState(() => _saveData.startingWeapon = id);
    SaveManager.save(_saveData);
  }

  void _selectPet(String id) {
    if (id != 'none' && !_saveData.unlockedPets.contains(id)) return;
    setState(() => _saveData.activePet = id);
    SaveManager.save(_saveData);
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
                      isWeaponsStep ? 'LOADOUT — ARMA' : 'LOADOUT — PET',
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
                      isWeaponsStep ? '1/2' : '2/2',
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
            // Footer button
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: GestureDetector(
                onTap: isWeaponsStep ? _next : widget.onConfirm,
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: NeonColors.green.withValues(alpha: 0.12),
                    border: Border.all(
                        color: NeonColors.green.withValues(alpha: 0.7),
                        width: 2),
                    boxShadow: [
                      BoxShadow(
                          color: NeonColors.green.withValues(alpha: 0.4),
                          blurRadius: 12)
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    isWeaponsStep ? 'AVANTI' : 'AVVIA PARTITA',
                    style: const TextStyle(
                      color: NeonColors.green,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'monospace',
                      letterSpacing: 4,
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

  Widget _buildWeaponsGrid() {
    // Wrap con SizedBox espliciti — risolve overflow precedente del GridView
    // childAspectRatio (cards ~200px tall × 2 rows = 400px > available 358px
    // → row 2 tagliata da footer button). Fixed 145×80 + Wrap = altezza
    // garantita ~170px sempre dentro available. Stile match _NeonModeCard.
    return Center(
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        alignment: WrapAlignment.center,
        children: _weaponCatalog
            .map((w) => _NeonLoadoutCard(
                  title: w.displayName,
                  isSelected: _saveData.startingWeapon == w.id,
                  isUnlocked: _saveData.unlockedWeapons.contains(w.id),
                  color: NeonColors.cyan,
                  iconLetter: w.displayName.substring(0, 1),
                  onTap: () => _selectWeapon(w.id),
                ))
            .toList(),
      ),
    );
  }

  Widget _buildPetsGrid() {
    return Center(
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        alignment: WrapAlignment.center,
        children: [
          _NeonLoadoutCard(
            title: 'NESSUNO',
            isSelected: _saveData.activePet == 'none',
            isUnlocked: true,
            color: const Color(0xFF888888),
            iconLetter: '–',
            onTap: () => _selectPet('none'),
          ),
          ...kPetCatalog.map((p) => _NeonLoadoutCard(
                title: p.displayName,
                isSelected: _saveData.activePet == p.id,
                isUnlocked: _saveData.unlockedPets.contains(p.id),
                color: p.color,
                iconLetter: p.iconCode,
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

  const _NeonLoadoutCard({
    required this.title,
    required this.iconLetter,
    required this.isSelected,
    required this.isUnlocked,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = !isUnlocked;
    final eff = disabled ? const Color(0xFF555555) : color;
    return GestureDetector(
      onTap: disabled ? null : onTap,
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
            // Badge lettera con glow
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
              child: Text(
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
                            'SHOP',
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
