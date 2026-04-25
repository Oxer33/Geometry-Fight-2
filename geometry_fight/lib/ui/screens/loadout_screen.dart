import 'package:flutter/material.dart';
import '../../data/constants.dart';
import '../../data/pet_types.dart';
import '../../data/save_data.dart';
import '../widgets/neon_back_button.dart';

/// Schermata Loadout — pre-game weapon + pet selection.
///
/// Pushed dopo `ModeSelectScreen` e prima di `GameScreen` quando l'utente
/// preme "START". Permette di scegliere:
/// - Arma di partenza (tra unlocked weapons in shop)
/// - Pet companion (tra unlocked pets in shop, opzione 'none' sempre disponibile)
///
/// Le selezioni vengono persistite in `SaveData.startingWeapon` /
/// `SaveData.activePet`. La partita reinizia con questi valori.
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

  @override
  void initState() {
    super.initState();
    _saveData = SaveManager.load();
  }

  // Catalog statico armi (mirror del catalog in shop_screen — qui solo
  // per visualizzazione/selezione loadout).
  static const _weaponCatalog = [
    _WeaponEntry('basic', 'BASIC', 'Doppia fila gialla'),
    _WeaponEntry('triple', 'TRIPLE', '3 colpi bianchi'),
    _WeaponEntry('spread', 'SPREAD', '5 colpi a ventaglio'),
    _WeaponEntry('ricochet', 'RICOCHET', 'Rimbalzano sui muri'),
    _WeaponEntry('homing', 'HOMING', 'Missili inseguitori'),
    _WeaponEntry('plasma', 'PLASMA', 'Orb AoE viola'),
    _WeaponEntry('laser', 'LASER', 'Raggio continuo'),
  ];

  void _selectWeapon(String id) {
    if (!_saveData.unlockedWeapons.contains(id)) return;
    setState(() {
      _saveData.startingWeapon = id;
    });
    SaveManager.save(_saveData);
  }

  void _selectPet(String id) {
    // 'none' sempre disponibile; altri pet richiedono unlock dallo shop.
    if (id != 'none' && !_saveData.unlockedPets.contains(id)) return;
    setState(() {
      _saveData.activePet = id;
    });
    SaveManager.save(_saveData);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // Header con back + titolo + start
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  NeonBackButton(onTap: widget.onBack),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'LOADOUT',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        fontFamily: 'monospace',
                        letterSpacing: 6,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48), // bilancia il back btn
                ],
              ),
            ),
            // Content scrollable
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _SectionTitle(label: 'ARMA DI PARTENZA'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: _weaponCatalog
                          .map((w) => _LoadoutCard(
                                title: w.displayName,
                                subtitle: w.description,
                                isSelected: _saveData.startingWeapon == w.id,
                                isUnlocked:
                                    _saveData.unlockedWeapons.contains(w.id),
                                color: NeonColors.cyan,
                                onTap: () => _selectWeapon(w.id),
                              ))
                          .toList(),
                    ),
                    const SizedBox(height: 28),
                    const _SectionTitle(label: 'PET COMPANION'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _LoadoutCard(
                          title: 'NESSUNO',
                          subtitle: 'Solo, no pet',
                          isSelected: _saveData.activePet == 'none',
                          isUnlocked: true,
                          color: const Color(0xFF888888),
                          onTap: () => _selectPet('none'),
                        ),
                        ...kPetCatalog.map((p) => _LoadoutCard(
                              title: p.displayName,
                              subtitle: p.description,
                              isSelected: _saveData.activePet == p.id,
                              isUnlocked:
                                  _saveData.unlockedPets.contains(p.id),
                              color: p.color,
                              onTap: () => _selectPet(p.id),
                            )),
                      ],
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
            // Footer START button
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: GestureDetector(
                onTap: widget.onConfirm,
                child: Container(
                  height: 56,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: NeonColors.green.withValues(alpha: 0.12),
                    border: Border.all(
                        color: NeonColors.green.withValues(alpha: 0.7),
                        width: 2),
                    boxShadow: [
                      BoxShadow(
                          color: NeonColors.green.withValues(alpha: 0.4),
                          blurRadius: 14)
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
}

class _WeaponEntry {
  final String id;
  final String displayName;
  final String description;
  const _WeaponEntry(this.id, this.displayName, this.description);
}

class _SectionTitle extends StatelessWidget {
  final String label;
  const _SectionTitle({required this.label});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 22,
          color: NeonColors.cyan,
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w900,
            fontFamily: 'monospace',
            letterSpacing: 3,
          ),
        ),
      ],
    );
  }
}

class _LoadoutCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isSelected;
  final bool isUnlocked;
  final Color color;
  final VoidCallback onTap;

  const _LoadoutCard({
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.isUnlocked,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = !isUnlocked;
    final effectiveColor = disabled ? const Color(0xFF555555) : color;
    return GestureDetector(
      onTap: disabled ? null : onTap,
      child: Container(
        width: 160,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: isSelected
              ? effectiveColor.withValues(alpha: 0.18)
              : effectiveColor.withValues(alpha: 0.05),
          border: Border.all(
              color:
                  effectiveColor.withValues(alpha: isSelected ? 0.95 : 0.35),
              width: isSelected ? 2.5 : 1),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                      color: effectiveColor.withValues(alpha: 0.5),
                      blurRadius: 12)
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                color: effectiveColor,
                fontSize: 14,
                fontWeight: FontWeight.w900,
                fontFamily: 'monospace',
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                color: effectiveColor.withValues(alpha: 0.6),
                fontSize: 10,
                fontFamily: 'monospace',
                height: 1.2,
              ),
            ),
            if (disabled)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  'LOCKED (shop)',
                  style: TextStyle(
                    color: Colors.amber.withValues(alpha: 0.7),
                    fontSize: 9,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
