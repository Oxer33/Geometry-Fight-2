import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../data/save_data.dart';
import '../../data/constants.dart';
import '../widgets/neon_back_button.dart';

class ShopScreen extends StatefulWidget {
  final VoidCallback onBack;

  const ShopScreen({super.key, required this.onBack});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _previewController;
  late SaveData _saveData;
  int? _selectedPreviewIndex;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() => _selectedPreviewIndex = null);
      }
    });
    _previewController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
    _saveData = SaveManager.load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _previewController.dispose();
    super.dispose();
  }

  void _purchase(String id, int cost, VoidCallback onSuccess) {
    if (_saveData.goldGeoms >= cost) {
      setState(() {
        _saveData.goldGeoms -= cost;
        onSuccess();
        SaveManager.save(_saveData);
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gold insufficiente!', style: TextStyle(fontFamily: 'monospace')),
          backgroundColor: Colors.redAccent,
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // Neon header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  NeonBackButton(onTap: widget.onBack),
                  const SizedBox(width: 16),
                  const Text(
                    'SHOP',
                    style: TextStyle(
                      color: Colors.cyanAccent,
                      fontSize: 18,
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.bold,
                      letterSpacing: 4,
                      shadows: [Shadow(color: Colors.cyanAccent, blurRadius: 8)],
                    ),
                  ),
                  const Spacer(),
                  // Gold display
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: const Color(0xFFFFD700).withValues(alpha: 0.3),
                      ),
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFFFFD700).withValues(alpha: 0.08),
                          const Color(0xFFFFD700).withValues(alpha: 0.02),
                        ],
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.diamond, color: Color(0xFFFFD700), size: 16),
                        const SizedBox(width: 6),
                        Text(
                          '${_saveData.goldGeoms}',
                          style: const TextStyle(
                            color: Color(0xFFFFD700),
                            fontFamily: 'monospace',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            shadows: [Shadow(color: Color(0xFFFFD700), blurRadius: 4)],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Neon tab bar
            TabBar(
              controller: _tabController,
              isScrollable: true,
              labelColor: Colors.cyanAccent,
              unselectedLabelColor: Colors.white30,
              indicatorColor: Colors.cyanAccent,
              indicatorWeight: 2,
              dividerColor: Colors.white.withValues(alpha: 0.05),
              labelStyle: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
              tabs: const [
                Tab(text: 'UPGRADES'),
                Tab(text: 'WEAPONS'),
                Tab(text: 'MODES'),
                Tab(text: 'SKINS'),
                Tab(text: 'TRAILS'),
              ],
            ),
            // Tab content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildUpgradesTab(),
                  _buildWeaponsTab(),
                  _buildModesTab(),
                  _buildSkinsTab(),
                  _buildTrailsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== SKINS TAB ====================

  Widget _buildSkinsTab() {
    final skins = [
      _SkinDef('classic', 'Classic', 0, 'La navicella originale cyan', NeonColors.cyan),
      _SkinDef('stealth', 'Stealth', 500, 'Nera con bordi rossi — stile furtivo', const Color(0xFFFF2244)),
      _SkinDef('crystal', 'Crystal', 1000, 'Diamante prismatico — riflessi arcobaleno', const Color(0xFFAADDFF)),
      _SkinDef('ghost', 'Ghost', 1500, 'Semi-trasparente con scia di particelle', const Color(0xFF8888CC)),
      _SkinDef('omega', 'Omega', 3000, 'Stella a 4 punte dorata — forma unica', const Color(0xFFFFD700)),
    ];

    return _buildPreviewGrid(
      items: skins,
      unlocked: _saveData.unlockedSkins,
      activeId: _saveData.activeSkin,
      onPurchase: (item) {
        _purchase(item.id, item.cost, () {
          if (!_saveData.unlockedSkins.contains(item.id)) {
            _saveData.unlockedSkins.add(item.id);
          }
          _saveData.activeSkin = item.id;
        });
      },
      onSelect: (item) {
        setState(() => _saveData.activeSkin = item.id);
        SaveManager.save(_saveData);
      },
      previewBuilder: (item, time) => _SkinPreviewPainter(
        skinId: item.id,
        color: (item as _SkinDef).color,
        time: time,
      ),
    );
  }

  // ==================== TRAILS TAB ====================

  Widget _buildTrailsTab() {
    final trails = [
      _TrailDef('normal', 'Normal', 0, 'Scia cyan standard', NeonColors.cyan),
      _TrailDef('fire', 'Fire', 200, 'Particelle di fuoco dietro la nave', const Color(0xFFFF6600)),
      _TrailDef('ice', 'Ice', 200, 'Cristalli di ghiaccio scintillanti', const Color(0xFF88DDFF)),
      _TrailDef('plasma', 'Plasma', 200, 'Energia plasma viola pulsante', const Color(0xFFCC00FF)),
      _TrailDef('rainbow', 'Rainbow', 200, 'Colori che cambiano continuamente', NeonColors.cyan),
    ];

    return _buildPreviewGrid(
      items: trails,
      unlocked: _saveData.unlockedTrails,
      activeId: _saveData.activeTrail,
      onPurchase: (item) {
        _purchase(item.id, item.cost, () {
          if (!_saveData.unlockedTrails.contains(item.id)) {
            _saveData.unlockedTrails.add(item.id);
          }
          _saveData.activeTrail = item.id;
        });
      },
      onSelect: (item) {
        setState(() => _saveData.activeTrail = item.id);
        SaveManager.save(_saveData);
      },
      previewBuilder: (item, time) => _TrailPreviewPainter(
        trailId: item.id,
        color: (item as _TrailDef).color,
        time: time,
      ),
    );
  }

  // ==================== WEAPONS TAB ====================

  Widget _buildWeaponsTab() {
    final weapons = [
      _WeaponDef('basic', 'Basic Gun', 0, 'Proiettile singolo — affidabile e preciso', NeonColors.bulletYellow, 'parallel'),
      _WeaponDef('triple', 'Triple Shot', 800, '3 proiettili ravvicinati — fuoco concentrato', NeonColors.white, 'triple'),
      _WeaponDef('spread', 'Spread Shot', 1000, '5 proiettili a ventaglio — ottimo vs gruppi', NeonColors.spreadOrange, 'fan'),
      _WeaponDef('ricochet', 'Ricochet', 1200, 'Rimbalza sui muri — colpisce da dietro', NeonColors.ricochetGreen, 'bounce'),
      _WeaponDef('homing', 'Homing', 1500, 'Insegue i nemici — non manca mai', NeonColors.pink, 'homing'),
      _WeaponDef('plasma', 'Plasma', 2000, 'Colpo lento ma 3x danni — devasta i boss', NeonColors.plasmaViolet, 'plasma'),
      _WeaponDef('laser', 'Laser', 2500, 'Raggio continuo — taglia tutto ciò che tocca', NeonColors.laserRed, 'beam'),
    ];

    return _buildPreviewGrid(
      items: weapons,
      unlocked: _saveData.unlockedWeapons,
      activeId: _saveData.startingWeapon,
      onPurchase: (item) {
        _purchase(item.id, item.cost, () {
          if (!_saveData.unlockedWeapons.contains(item.id)) {
            _saveData.unlockedWeapons.add(item.id);
          }
          _saveData.startingWeapon = item.id;
        });
      },
      onSelect: (item) {
        setState(() => _saveData.startingWeapon = item.id);
        SaveManager.save(_saveData);
      },
      previewBuilder: (item, time) => _WeaponPreviewPainter(
        pattern: (item as _WeaponDef).pattern,
        color: item.color,
        time: time,
      ),
    );
  }

  // ==================== UPGRADES TAB ====================

  Widget _buildUpgradesTab() {
    final upgrades = [
      _UpgradeItem('firepower', 'FIREPOWER', [100, 200, 400, 800, 1500], 5,
          'Danno proiettili: +15% → +30% → +50% → +70% → +100%', Icons.local_fire_department, const Color(0xFFFF4400)),
      _UpgradeItem('speed', 'SPEED', [100, 200, 400, 800, 1500], 5,
          'Velocità navicella: +10% per livello (max +50%)', Icons.speed, NeonColors.cyan),
      _UpgradeItem('fire_rate', 'FIRE RATE', [100, 200, 400, 800, 1500], 5,
          'Cadenza di fuoco: +8% per livello (max +40%)', Icons.bolt, NeonColors.bulletYellow),
      _UpgradeItem('shield_capacity', 'SHIELD', [300, 700, 1500], 3,
          'Colpi assorbiti dallo scudo: 2 → 3 → 4 (Lv3: rigenera!)', Icons.shield_outlined, const Color(0xFF00AAFF)),
      _UpgradeItem('starting_lives', 'LIVES', [500, 1200], 2,
          'Vite iniziali: 3 → 4 → 5', Icons.favorite, const Color(0xFFFF4466)),
      _UpgradeItem('bomb_capacity', 'BOMBS', [400, 900], 2,
          'Bombe disponibili: 3 → 4 → 5', Icons.blur_circular, NeonColors.orange),
      _UpgradeItem('magnet_range', 'MAGNET', [250, 600, 1200], 3,
          'Raggio raccolta geom: +50px → +150px → +350px', Icons.radar, NeonColors.purple),
      _UpgradeItem('xp_boost', 'XP BOOST', [300, 700, 1500], 3,
          'Moltiplicatore GoldGeom: x1.2 → x1.4 → x1.7', Icons.auto_awesome, const Color(0xFFFFD700)),
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: upgrades.length,
      itemBuilder: (context, index) {
        final item = upgrades[index];
        final currentLevel = _saveData.getUpgradeLevel(item.id);
        final isMaxed = currentLevel >= item.maxLevel;
        final cost = isMaxed ? 0 : item.costs[currentLevel];

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(
              color: isMaxed
                  ? item.color.withValues(alpha: 0.4)
                  : item.color.withValues(alpha: 0.15),
            ),
            borderRadius: BorderRadius.circular(8),
            gradient: LinearGradient(
              colors: [
                item.color.withValues(alpha: isMaxed ? 0.06 : 0.02),
                Colors.transparent,
              ],
            ),
          ),
          child: Row(
            children: [
              // Icona con glow
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: item.color.withValues(alpha: 0.3)),
                  color: item.color.withValues(alpha: 0.08),
                ),
                child: Icon(item.icon, color: item.color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.name, style: TextStyle(
                      color: item.color,
                      fontSize: 14, fontWeight: FontWeight.bold, fontFamily: 'monospace',
                    )),
                    const SizedBox(height: 2),
                    Text(item.description, style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.4),
                      fontSize: 10, fontFamily: 'monospace',
                    )),
                    const SizedBox(height: 6),
                    Row(
                      children: List.generate(item.maxLevel, (i) {
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: 22, height: 4,
                          margin: const EdgeInsets.only(right: 3),
                          decoration: BoxDecoration(
                            color: i < currentLevel
                                ? item.color
                                : item.color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(2),
                            boxShadow: i < currentLevel
                                ? [BoxShadow(color: item.color.withValues(alpha: 0.4), blurRadius: 4)]
                                : null,
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),
              if (!isMaxed)
                _PurchaseButton(
                  cost: cost,
                  canAfford: _saveData.goldGeoms >= cost,
                  color: item.color,
                  onTap: () {
                    _purchase(item.id, cost, () {
                      _saveData.upgrades[item.id] = currentLevel + 1;
                    });
                  },
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.4)),
                    color: Colors.greenAccent.withValues(alpha: 0.05),
                  ),
                  child: const Text('MAX', style: TextStyle(
                    color: Colors.greenAccent,
                    fontFamily: 'monospace', fontWeight: FontWeight.bold, fontSize: 12,
                  )),
                ),
            ],
          ),
        );
      },
    );
  }

  // ==================== MODES TAB ====================

  Widget _buildModesTab() {
    final modes = [
      _ModeDef('classic', 'Classic', 0, '100 wave con boss ogni 10 — il modo standard', Icons.games, NeonColors.cyan),
      _ModeDef('bossRush', 'Boss Rush', 2000, 'Solo boss, uno dopo l\'altro — niente mob', Icons.whatshot, const Color(0xFFFF4400)),
      _ModeDef('survival', 'Survival', 2500, 'Wave infinite sempre più difficili — quanto resisti?', Icons.all_inclusive, const Color(0xFF00FF88)),
      _ModeDef('timeAttack', 'Time Attack', 1500, '3 minuti: fai più punti possibile prima che scada', Icons.timer, NeonColors.orange),
      _ModeDef('zenMode', 'Zen Mode', 1000, 'Vite infinite — gioca senza stress, esplora tutto', Icons.spa, const Color(0xFF88CCFF)),
      _ModeDef('tunnel', 'Tunnel', 3000, 'Scorrimento laterale in un tunnel infinito', Icons.straighten, NeonColors.purple),
      _ModeDef('endlessBoss', 'Boss Infiniti', 3500, 'Boss dopo boss senza fine — solo per esperti', Icons.repeat, const Color(0xFFFF00AA)),
    ];

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 2.8,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
      ),
      itemCount: modes.length,
      itemBuilder: (context, index) {
        final item = modes[index];
        final owned = _saveData.unlockedModes.contains(item.id);

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: owned
                  ? item.color.withValues(alpha: 0.4)
                  : Colors.white.withValues(alpha: 0.1),
            ),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                item.color.withValues(alpha: owned ? 0.08 : 0.02),
                Colors.transparent,
              ],
            ),
          ),
          child: Row(
            children: [
              Icon(item.icon, color: item.color.withValues(alpha: owned ? 0.8 : 0.3), size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.name, style: TextStyle(
                      color: owned ? item.color : Colors.white54,
                      fontSize: 11, fontWeight: FontWeight.bold, fontFamily: 'monospace',
                    )),
                    const SizedBox(height: 2),
                    if (owned)
                      Text('UNLOCKED', style: TextStyle(
                        color: Colors.greenAccent.withValues(alpha: 0.6),
                        fontSize: 8, fontFamily: 'monospace',
                      ))
                    else
                      _PurchaseButton(
                        cost: item.cost,
                        canAfford: _saveData.goldGeoms >= item.cost,
                        color: item.color,
                        onTap: () {
                          _purchase(item.id, item.cost, () {
                            if (!_saveData.unlockedModes.contains(item.id)) {
                              _saveData.unlockedModes.add(item.id);
                            }
                          });
                        },
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ==================== PREVIEW GRID ====================

  Widget _buildPreviewGrid({
    required List<_ShopItem> items,
    required List<String> unlocked,
    required String activeId,
    required void Function(_ShopItem) onPurchase,
    required void Function(_ShopItem) onSelect,
    required CustomPainter Function(_ShopItem item, double time) previewBuilder,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 500;
        return Row(
          children: [
            // === LISTA ITEMS ===
            SizedBox(
              width: isWide ? 200 : 160,
              child: ListView.builder(
                padding: const EdgeInsets.all(10),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  final owned = unlocked.contains(item.id);
                  final isActive = item.id == activeId;
                  final isSelected = _selectedPreviewIndex == index;

                  return GestureDetector(
                    onTap: () {
                      setState(() => _selectedPreviewIndex = index);
                      if (owned) {
                        onSelect(item);
                      }
                      // Non-owned: solo seleziona la preview, l'acquisto avviene dal bottone nel pannello preview
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected
                              ? Colors.cyanAccent.withValues(alpha: 0.6)
                              : isActive
                                  ? Colors.greenAccent.withValues(alpha: 0.3)
                                  : Colors.white.withValues(alpha: 0.08),
                          width: isSelected ? 1.5 : 1,
                        ),
                        color: isSelected
                            ? Colors.cyanAccent.withValues(alpha: 0.06)
                            : isActive
                                ? Colors.greenAccent.withValues(alpha: 0.03)
                                : Colors.transparent,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.name, style: TextStyle(
                                  color: isActive ? Colors.greenAccent : Colors.white,
                                  fontSize: 12, fontWeight: FontWeight.bold,
                                  fontFamily: 'monospace',
                                )),
                                const SizedBox(height: 2),
                                Text(item.description, style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.3),
                                  fontSize: 8, fontFamily: 'monospace',
                                )),
                              ],
                            ),
                          ),
                          if (isActive)
                            Icon(Icons.check_circle, color: Colors.greenAccent.withValues(alpha: 0.6), size: 16)
                          else if (!owned)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.diamond, color: Color(0xFFFFD700), size: 10),
                                const SizedBox(width: 2),
                                Text('${item.cost}', style: TextStyle(
                                  color: _saveData.goldGeoms >= item.cost
                                      ? const Color(0xFFFFD700) : Colors.white24,
                                  fontSize: 10, fontFamily: 'monospace',
                                )),
                              ],
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // === DIVISORE VERTICALE ===
            Container(
              width: 1,
              margin: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.cyanAccent.withValues(alpha: 0.15),
                    Colors.transparent,
                  ],
                ),
              ),
            ),

            // === PREVIEW AREA ===
            Expanded(
              child: AnimatedBuilder(
                animation: _previewController,
                builder: (context, _) {
                  final previewIndex = _selectedPreviewIndex ?? 0;
                  final item = items[previewIndex.clamp(0, items.length - 1)];
                  final owned = unlocked.contains(item.id);

                  return LayoutBuilder(
                    builder: (context, previewConstraints) {
                      final previewSize = (previewConstraints.maxHeight - 80).clamp(80.0, 200.0);
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Preview canvas
                          Container(
                            width: previewSize, height: previewSize,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.cyanAccent.withValues(alpha: 0.08),
                              ),
                              gradient: RadialGradient(
                                colors: [
                                  Colors.cyanAccent.withValues(alpha: 0.03),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                            child: CustomPaint(
                              painter: previewBuilder(item, _previewController.value * 10),
                              size: Size(previewSize, previewSize),
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Nome
                          Text(item.name, style: const TextStyle(
                            color: Colors.cyanAccent,
                            fontSize: 16, fontWeight: FontWeight.bold,
                            fontFamily: 'monospace', letterSpacing: 2,
                          )),
                          const SizedBox(height: 4),
                          Text(item.description, style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.4),
                            fontSize: 10, fontFamily: 'monospace',
                          )),
                          const SizedBox(height: 10),
                          if (!owned)
                            _PurchaseButton(
                              cost: item.cost,
                              canAfford: _saveData.goldGeoms >= item.cost,
                              color: Colors.cyanAccent,
                              onTap: () => onPurchase(item),
                              large: true,
                            )
                          else
                            Text(
                              item.id == activeId ? 'EQUIPPED' : 'OWNED — TAP TO EQUIP',
                              style: TextStyle(
                                color: item.id == activeId
                                    ? Colors.greenAccent
                                    : Colors.white.withValues(alpha: 0.4),
                                fontSize: 10, fontFamily: 'monospace', letterSpacing: 1,
                              ),
                            ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

// ==================== PURCHASE BUTTON ====================

class _PurchaseButton extends StatefulWidget {
  final int cost;
  final bool canAfford;
  final Color color;
  final VoidCallback onTap;
  final bool large;

  const _PurchaseButton({
    required this.cost, required this.canAfford,
    required this.color, required this.onTap, this.large = false,
  });

  @override
  State<_PurchaseButton> createState() => _PurchaseButtonState();
}

class _PurchaseButtonState extends State<_PurchaseButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) { setState(() => _pressed = false); if (widget.canAfford) widget.onTap(); },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.93 : 1.0,
        duration: const Duration(milliseconds: 80),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: widget.large ? 20 : 12,
            vertical: widget.large ? 8 : 5,
          ),
          decoration: BoxDecoration(
            border: Border.all(
              color: widget.canAfford
                  ? widget.color.withValues(alpha: 0.6)
                  : Colors.white.withValues(alpha: 0.15),
            ),
            borderRadius: BorderRadius.circular(6),
            color: widget.canAfford
                ? widget.color.withValues(alpha: _pressed ? 0.12 : 0.04)
                : Colors.transparent,
            boxShadow: widget.canAfford && _pressed
                ? [BoxShadow(color: widget.color.withValues(alpha: 0.2), blurRadius: 10)]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.diamond, color: const Color(0xFFFFD700),
                  size: widget.large ? 16 : 12),
              SizedBox(width: widget.large ? 6 : 4),
              Text(
                '${widget.cost}',
                style: TextStyle(
                  color: widget.canAfford ? const Color(0xFFFFD700) : Colors.white24,
                  fontFamily: 'monospace', fontWeight: FontWeight.bold,
                  fontSize: widget.large ? 14 : 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==================== DATA CLASSES ====================

class _ShopItem {
  final String id;
  final String name;
  final int cost;
  final String description;

  _ShopItem(this.id, this.name, this.cost, this.description);
}

class _SkinDef extends _ShopItem {
  final Color color;
  _SkinDef(super.id, super.name, super.cost, super.description, this.color);
}

class _TrailDef extends _ShopItem {
  final Color color;
  _TrailDef(super.id, super.name, super.cost, super.description, this.color);
}

class _WeaponDef extends _ShopItem {
  final Color color;
  final String pattern;
  _WeaponDef(super.id, super.name, super.cost, super.description, this.color, this.pattern);
}

class _ModeDef extends _ShopItem {
  final IconData icon;
  final Color color;
  _ModeDef(super.id, super.name, super.cost, super.description, this.icon, this.color);
}

class _UpgradeItem {
  final String id;
  final String name;
  final List<int> costs;
  final int maxLevel;
  final String description;
  final IconData icon;
  final Color color;

  _UpgradeItem(this.id, this.name, this.costs, this.maxLevel,
      this.description, this.icon, this.color);
}

// ==================== SKIN PREVIEW PAINTER ====================

class _SkinPreviewPainter extends CustomPainter {
  final String skinId;
  final Color color;
  final double time;

  _SkinPreviewPainter({required this.skinId, required this.color, required this.time});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    // Griglia esagonale di sfondo
    _drawHexGrid(canvas, size);

    final rotation = time * 0.4;

    // Campo energetico pulsante (archi rotanti)
    final arcPaint = Paint()
      ..color = color.withValues(alpha: 0.08 + math.sin(time * 1.5) * 0.04)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final arcRect = Rect.fromCircle(center: Offset(cx, cy), radius: 70);
    canvas.drawArc(arcRect, time * 0.3, math.pi * 0.7, false, arcPaint);
    canvas.drawArc(arcRect, time * 0.3 + math.pi, math.pi * 0.7, false, arcPaint);

    // Anello interno pulsante
    final ringPulse = 55 + math.sin(time * 2) * 4;
    final ringPaint = Paint()
      ..color = color.withValues(alpha: 0.06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;
    canvas.drawCircle(Offset(cx, cy), ringPulse, ringPaint);

    // Glow radiale
    final glowPaint = Paint()
      ..color = color.withValues(alpha: 0.06 + math.sin(time * 1.5) * 0.02);
    canvas.drawCircle(Offset(cx, cy), 45, glowPaint);

    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(rotation);

    const scale = 2.5;

    switch (skinId) {
      case 'stealth':
        _drawStealthShip(canvas, scale, color);
        break;
      case 'crystal':
        _drawCrystalShip(canvas, scale, color);
        break;
      case 'ghost':
        _drawGhostShip(canvas, scale, color);
        break;
      case 'omega':
        _drawOmegaShip(canvas, scale, color);
        break;
      default:
        _drawClassicShip(canvas, scale, color);
    }

    canvas.restore();

    _drawPreviewThrusters(canvas, cx, cy, rotation, scale);
    _drawOrbitingParticles(canvas, cx, cy, time, color);
  }

  void _drawHexGrid(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.02)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;
    const spacing = 28.0;
    for (double y = -spacing; y < size.height + spacing; y += spacing * 0.87) {
      final row = (y / (spacing * 0.87)).round();
      final xOff = (row % 2 == 0) ? 0.0 : spacing * 0.5;
      for (double x = -spacing + xOff; x < size.width + spacing; x += spacing) {
        final path = Path();
        for (int i = 0; i < 6; i++) {
          final a = i * math.pi / 3 + math.pi / 6;
          final hx = x + math.cos(a) * spacing * 0.35;
          final hy = y + math.sin(a) * spacing * 0.35;
          if (i == 0) path.moveTo(hx, hy); else path.lineTo(hx, hy);
        }
        path.close();
        canvas.drawPath(path, paint);
      }
    }
  }

  void _drawClassicShip(Canvas canvas, double s, Color c) {
    final glowPaint = Paint()
      ..color = c.withValues(alpha: 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    _drawShipPath(canvas, s, glowPaint);

    final bodyPaint = Paint()..color = c;
    _drawShipPath(canvas, s, bodyPaint);

    // Bordo luminoso
    final edgePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    _drawShipPath(canvas, s, edgePaint);

    // Cockpit
    canvas.drawCircle(Offset(0, -4 * s), 2.5 * s, Paint()..color = Colors.white.withValues(alpha: 0.8));

    // Wing lines + nodi
    final linePaint = Paint()
      ..color = c.withValues(alpha: 0.4)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(-2 * s, 0), Offset(-10 * s, 10 * s), linePaint);
    canvas.drawLine(Offset(2 * s, 0), Offset(10 * s, 10 * s), linePaint);

    // Nodi energetici sulle punte delle ali
    final nodePulse = 0.3 + math.sin(time * 4) * 0.2;
    final nodePaint = Paint()..color = c.withValues(alpha: nodePulse);
    canvas.drawCircle(Offset(-13 * s, 10 * s), 1.5, nodePaint);
    canvas.drawCircle(Offset(13 * s, 10 * s), 1.5, nodePaint);
  }

  void _drawStealthShip(Canvas canvas, double s, Color c) {
    final path = Path()
      ..moveTo(0, -16 * s)
      ..lineTo(6 * s, -4 * s)
      ..lineTo(15 * s, 8 * s)
      ..lineTo(3 * s, 6 * s)
      ..lineTo(0, 12 * s)
      ..lineTo(-3 * s, 6 * s)
      ..lineTo(-15 * s, 8 * s)
      ..lineTo(-6 * s, -4 * s)
      ..close();

    final glowPaint = Paint()
      ..color = c.withValues(alpha: 0.2)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawPath(path, glowPaint);

    final bodyPaint = Paint()..color = const Color(0xFF151520);
    canvas.drawPath(path, bodyPaint);

    // Pannelli interni
    final panelPaint = Paint()
      ..color = c.withValues(alpha: 0.08)
      ..style = PaintingStyle.fill;
    final panelL = Path()
      ..moveTo(-6 * s, -4 * s)..lineTo(0, -10 * s)..lineTo(0, 6 * s)..lineTo(-12 * s, 8 * s)..close();
    canvas.drawPath(panelL, panelPaint);

    final edgePaint = Paint()
      ..color = c
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawPath(path, edgePaint);

    // Linee circuito
    final circuitPaint = Paint()
      ..color = c.withValues(alpha: 0.2)
      ..strokeWidth = 0.5;
    canvas.drawLine(Offset(0, -10 * s), Offset(0, 8 * s), circuitPaint);
    canvas.drawLine(Offset(-6 * s, -4 * s), Offset(6 * s, -4 * s), circuitPaint);

    // Occhio rosso pulsante
    final eyePulse = 0.6 + math.sin(time * 3) * 0.3;
    canvas.drawCircle(Offset(0, -6 * s), 2.5 * s, Paint()
      ..color = c.withValues(alpha: eyePulse)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3));
    canvas.drawCircle(Offset(0, -6 * s), 1.5 * s, Paint()..color = c);
  }

  void _drawCrystalShip(Canvas canvas, double s, Color c) {
    final path = Path()
      ..moveTo(0, -18 * s)
      ..lineTo(8 * s, -2 * s)
      ..lineTo(12 * s, 8 * s)
      ..lineTo(0, 14 * s)
      ..lineTo(-12 * s, 8 * s)
      ..lineTo(-8 * s, -2 * s)
      ..close();

    final bodyPaint = Paint()..color = c.withValues(alpha: 0.25);
    canvas.drawPath(path, bodyPaint);

    // Sfaccettature con riempimento graduale
    final facetPaint = Paint()
      ..color = c.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    canvas.drawLine(Offset(0, -18 * s), Offset(0, 14 * s), facetPaint);
    canvas.drawLine(Offset(-8 * s, -2 * s), Offset(12 * s, 8 * s), facetPaint);
    canvas.drawLine(Offset(8 * s, -2 * s), Offset(-12 * s, 8 * s), facetPaint);
    // Facets extra
    canvas.drawLine(Offset(0, -18 * s), Offset(12 * s, 8 * s), facetPaint..color = c.withValues(alpha: 0.2));
    canvas.drawLine(Offset(0, -18 * s), Offset(-12 * s, 8 * s), facetPaint);

    // Riflesso prismatico che ruota
    final hue = (time * 50) % 360;
    final prismPaint = Paint()
      ..color = HSVColor.fromAHSV(0.25, hue, 0.8, 1).toColor()
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(Offset(0, -2 * s), 6 * s, prismPaint);
    // Secondo riflesso sfasato
    final prismPaint2 = Paint()
      ..color = HSVColor.fromAHSV(0.12, (hue + 120) % 360, 0.8, 1).toColor()
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
    canvas.drawCircle(Offset(3 * s, -6 * s), 4 * s, prismPaint2);

    // Bordo glow
    final borderPaint = Paint()
      ..color = c.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawPath(path, borderPaint);

    // Punti luminosi sui vertici
    final verts = [Offset(0, -18 * s), Offset(8 * s, -2 * s), Offset(12 * s, 8 * s),
                   Offset(0, 14 * s), Offset(-12 * s, 8 * s), Offset(-8 * s, -2 * s)];
    for (int i = 0; i < verts.length; i++) {
      final vPulse = 0.3 + math.sin(time * 3 + i * 1.0) * 0.3;
      canvas.drawCircle(verts[i], 1.5, Paint()..color = Colors.white.withValues(alpha: vPulse));
    }
  }

  void _drawGhostShip(Canvas canvas, double s, Color c) {
    final alpha = 0.3 + math.sin(time * 2) * 0.15;

    // Afterimage (ombra sfasata)
    canvas.save();
    canvas.translate(math.sin(time * 1.5) * 3, math.cos(time * 1.2) * 3);
    _drawShipPath(canvas, s, Paint()..color = c.withValues(alpha: alpha * 0.2));
    canvas.restore();

    final glowPaint = Paint()
      ..color = c.withValues(alpha: alpha * 0.4)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);
    _drawShipPath(canvas, s, glowPaint);

    final bodyPaint = Paint()..color = c.withValues(alpha: alpha);
    _drawShipPath(canvas, s, bodyPaint);

    // Ghost particles che salgono
    final random = math.Random(42);
    final particlePaint = Paint();
    for (int i = 0; i < 12; i++) {
      final baseAngle = i * math.pi / 6;
      final dist = 12 + random.nextDouble() * 18;
      final drift = math.sin(time * 1.5 + i * 0.7) * 5;
      final px = math.cos(baseAngle) * dist * s * 0.4 + drift;
      final py = math.sin(baseAngle) * dist * s * 0.4 - (math.sin(time * 2 + i)).abs() * 8;
      final pAlpha = (0.2 + math.sin(time * 3 + i) * 0.15).clamp(0.03, 0.4);
      final pSize = (1.0 + math.sin(time * 4 + i * 2) * 0.5) * s;
      particlePaint.color = c.withValues(alpha: pAlpha);
      canvas.drawCircle(Offset(px, py), pSize, particlePaint);
    }
  }

  void _drawOmegaShip(Canvas canvas, double s, Color c) {
    final starRotation = time * 0.8;

    canvas.save();
    canvas.rotate(starRotation);

    final path = Path();
    for (int i = 0; i < 4; i++) {
      final angle = i * math.pi / 2;
      final outerX = math.cos(angle) * 16 * s;
      final outerY = math.sin(angle) * 16 * s;
      final innerAngle = angle + math.pi / 4;
      final innerX = math.cos(innerAngle) * 6 * s;
      final innerY = math.sin(innerAngle) * 6 * s;
      if (i == 0) path.moveTo(outerX, outerY); else path.lineTo(outerX, outerY);
      path.lineTo(innerX, innerY);
    }
    path.close();

    final glowPaint = Paint()
      ..color = c.withValues(alpha: 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawPath(path, glowPaint);

    final bodyPaint = Paint()..color = c;
    canvas.drawPath(path, bodyPaint);

    // Bordo bianco
    canvas.drawPath(path, Paint()
      ..color = Colors.white.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8);

    // Stella interna contro-rotante
    canvas.save();
    canvas.rotate(-starRotation * 2);
    final innerPath = Path();
    for (int i = 0; i < 4; i++) {
      final angle = i * math.pi / 2 + math.pi / 4;
      final outerX = math.cos(angle) * 8 * s;
      final outerY = math.sin(angle) * 8 * s;
      final innerAngle = angle + math.pi / 4;
      final innerX = math.cos(innerAngle) * 3 * s;
      final innerY = math.sin(innerAngle) * 3 * s;
      if (i == 0) innerPath.moveTo(outerX, outerY); else innerPath.lineTo(outerX, outerY);
      innerPath.lineTo(innerX, innerY);
    }
    innerPath.close();
    canvas.drawPath(innerPath, Paint()
      ..color = c.withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.7);
    canvas.restore();

    // Centro orb + glow
    canvas.drawCircle(Offset.zero, 6 * s, Paint()
      ..color = c.withValues(alpha: 0.25)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));
    canvas.drawCircle(Offset.zero, 3.5 * s, Paint()..color = Colors.white.withValues(alpha: 0.8));

    // Nodi pulsanti sulle punte
    for (int i = 0; i < 4; i++) {
      final angle = i * math.pi / 2;
      final nx = math.cos(angle) * 15 * s;
      final ny = math.sin(angle) * 15 * s;
      final np = 0.3 + math.sin(time * 4 + i * 1.5) * 0.3;
      canvas.drawCircle(Offset(nx, ny), 1.5, Paint()..color = c.withValues(alpha: np));
    }

    canvas.restore();
  }

  void _drawShipPath(Canvas canvas, double s, Paint paint) {
    final path = Path()
      ..moveTo(0, -14 * s)
      ..lineTo(4 * s, -6 * s)
      ..lineTo(13 * s, 10 * s)
      ..lineTo(8 * s, 8 * s)
      ..lineTo(5 * s, 14 * s)
      ..lineTo(0, 10 * s)
      ..lineTo(-5 * s, 14 * s)
      ..lineTo(-8 * s, 8 * s)
      ..lineTo(-13 * s, 10 * s)
      ..lineTo(-4 * s, -6 * s)
      ..close();
    canvas.drawPath(path, paint);
  }

  void _drawPreviewThrusters(Canvas canvas, double cx, double cy, double rotation, double s) {
    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(rotation);

    final flameLen = 8 + math.sin(time * 8) * 3;

    for (final xOff in [-5.0 * s, 5.0 * s]) {
      // Fiamma esterna
      final flamePaint = Paint()
        ..color = const Color(0xFFFF6600).withValues(alpha: 0.35)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 3 * s);
      canvas.drawOval(
        Rect.fromCenter(center: Offset(xOff, 13 * s + flameLen * 0.5), width: 5 * s, height: flameLen * s * 0.5),
        flamePaint,
      );
      // Nucleo bianco
      canvas.drawOval(
        Rect.fromCenter(center: Offset(xOff, 13 * s + flameLen * 0.3), width: 2.5 * s, height: flameLen * s * 0.25),
        Paint()..color = Colors.white.withValues(alpha: 0.6)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
      );
    }

    canvas.restore();
  }

  void _drawOrbitingParticles(Canvas canvas, double cx, double cy, double t, Color c) {
    final paint = Paint();
    for (int i = 0; i < 8; i++) {
      final angle = t * 0.5 + i * math.pi / 4;
      final dist = 78 + math.sin(t * 0.7 + i * 2) * 8;
      final x = cx + math.cos(angle) * dist;
      final y = cy + math.sin(angle) * dist;
      final alpha = 0.1 + math.sin(t * 2 + i) * 0.08;
      paint.color = c.withValues(alpha: alpha.clamp(0.03, 0.25));
      canvas.drawCircle(Offset(x, y), 1.2, paint);
      // Connessione al successivo
      if (i < 7) {
        final nextAngle = t * 0.5 + (i + 1) * math.pi / 4;
        final nextDist = 78 + math.sin(t * 0.7 + (i + 1) * 2) * 8;
        final nx = cx + math.cos(nextAngle) * nextDist;
        final ny = cy + math.sin(nextAngle) * nextDist;
        canvas.drawLine(Offset(x, y), Offset(nx, ny), Paint()
          ..color = c.withValues(alpha: 0.03)
          ..strokeWidth = 0.5);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SkinPreviewPainter old) => old.time != time;
}

// ==================== TRAIL PREVIEW PAINTER ====================

class _TrailPreviewPainter extends CustomPainter {
  final String trailId;
  final Color color;
  final double time;

  _TrailPreviewPainter({required this.trailId, required this.color, required this.time});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    // La nave segue un percorso a 8
    final pathT = time * 0.6;
    final shipX = cx + math.cos(pathT) * 50;
    final shipY = cy + math.sin(pathT * 2) * 30;
    final angle = math.atan2(
      math.cos(pathT * 2) * 30 * 2,
      -math.sin(pathT) * 50,
    ) + math.pi / 2;

    // Trail points (simula il percorso passato)
    final trailCount = 25;
    for (int i = trailCount; i >= 0; i--) {
      final tt = pathT - i * 0.04;
      final tx = cx + math.cos(tt) * 50;
      final ty = cy + math.sin(tt * 2) * 30;
      final progress = 1.0 - i / trailCount;

      Color trailColor;
      double trailAlpha;
      double trailSize;

      switch (trailId) {
        case 'fire':
          final hue = 20 + i * 1.5;
          trailColor = HSVColor.fromAHSV(1, hue.clamp(0, 60), 1, 1).toColor();
          trailAlpha = progress * 0.5;
          trailSize = progress * 4 + 1;
          break;
        case 'ice':
          trailColor = color;
          trailAlpha = progress * 0.4;
          trailSize = progress * 3;
          // Ice crystals
          if (i % 3 == 0 && progress > 0.2) {
            _drawIceCrystal(canvas, tx, ty, progress * 4, trailAlpha);
          }
          break;
        case 'plasma':
          trailColor = color;
          trailAlpha = progress * 0.5;
          trailSize = progress * 5 + math.sin(time * 8 + i * 0.5) * 1.5;
          break;
        case 'rainbow':
          final hue = ((time * 80 + i * 12) % 360);
          trailColor = HSVColor.fromAHSV(1, hue, 0.9, 1).toColor();
          trailAlpha = progress * 0.5;
          trailSize = progress * 3.5;
          break;
        default: // normal
          trailColor = NeonColors.cyan;
          trailAlpha = progress * 0.35;
          trailSize = progress * 3;
      }

      if (trailSize > 0.5) {
        final paint = Paint()
          ..color = trailColor.withValues(alpha: trailAlpha.clamp(0.01, 0.6));
        canvas.drawCircle(Offset(tx, ty), trailSize, paint);

        // Glow
        if (progress > 0.5 && trailId != 'normal') {
          paint.color = trailColor.withValues(alpha: trailAlpha * 0.3);
          canvas.drawCircle(Offset(tx, ty), trailSize * 2.5, paint);
        }
      }
    }

    // Disegna la nave piccola
    canvas.save();
    canvas.translate(shipX, shipY);
    canvas.rotate(angle);

    final shipPaint = Paint()..color = NeonColors.cyan;
    final s = 1.2;
    final path = Path()
      ..moveTo(0, -14 * s)
      ..lineTo(4 * s, -6 * s)
      ..lineTo(13 * s, 10 * s)
      ..lineTo(8 * s, 8 * s)
      ..lineTo(5 * s, 14 * s)
      ..lineTo(0, 10 * s)
      ..lineTo(-5 * s, 14 * s)
      ..lineTo(-8 * s, 8 * s)
      ..lineTo(-13 * s, 10 * s)
      ..lineTo(-4 * s, -6 * s)
      ..close();
    canvas.drawPath(path, shipPaint);

    // Glow
    final glowPaint = Paint()
      ..color = NeonColors.cyan.withValues(alpha: 0.25)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawPath(path, glowPaint);

    canvas.restore();
  }

  void _drawIceCrystal(Canvas canvas, double x, double y, double r, double alpha) {
    final paint = Paint()
      ..color = color.withValues(alpha: alpha * 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    // 6-point ice crystal
    for (int i = 0; i < 6; i++) {
      final a = i * math.pi / 3;
      canvas.drawLine(
        Offset(x, y),
        Offset(x + math.cos(a) * r, y + math.sin(a) * r),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _TrailPreviewPainter old) => old.time != time;
}

// ==================== WEAPON PREVIEW PAINTER ====================

class _WeaponPreviewPainter extends CustomPainter {
  final String pattern;
  final Color color;
  final double time;

  _WeaponPreviewPainter({required this.pattern, required this.color, required this.time});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final shipY = cy + 35;

    // Griglia sfondo
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.015)
      ..strokeWidth = 0.5;
    for (double y = 0; y < size.height; y += 20) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
    for (double x = 0; x < size.width; x += 20) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }

    // Nemici bersaglio (rombi rosa che si muovono)
    if (pattern != 'beam') {
      _drawTargetEnemies(canvas, cx, size);
    } else {
      // Per il laser: nemico fisso in alto
      _drawTargetEnemy(canvas, cx, 25, 0.8 + math.sin(time * 6) * 0.2);
    }

    // Nave
    canvas.save();
    canvas.translate(cx, shipY);
    const s = 1.5;
    final shipPath = Path()
      ..moveTo(0, -14 * s)..lineTo(4 * s, -6 * s)..lineTo(13 * s, 10 * s)
      ..lineTo(8 * s, 8 * s)..lineTo(5 * s, 14 * s)..lineTo(0, 10 * s)
      ..lineTo(-5 * s, 14 * s)..lineTo(-8 * s, 8 * s)..lineTo(-13 * s, 10 * s)
      ..lineTo(-4 * s, -6 * s)..close();
    canvas.drawPath(shipPath, Paint()
      ..color = NeonColors.cyan.withValues(alpha: 0.25)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));
    canvas.drawPath(shipPath, Paint()..color = NeonColors.cyan);
    // Cockpit
    canvas.drawCircle(Offset(0, -5 * s), 2 * s, Paint()..color = Colors.white.withValues(alpha: 0.7));
    canvas.restore();

    // Muzzle flash pulsante
    final muzzlePhase = (time * 8) % 1.0;
    if (muzzlePhase < 0.3) {
      final mAlpha = (1 - muzzlePhase / 0.3) * 0.3;
      canvas.drawCircle(Offset(cx, shipY - 22), 4 + muzzlePhase * 6, Paint()
        ..color = color.withValues(alpha: mAlpha)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
    }

    final fireRate = _getFireRate();
    final bulletSpeed = 130.0;

    switch (pattern) {
      case 'parallel': _drawParallelBullets(canvas, cx, shipY, fireRate, bulletSpeed); break;
      case 'triple': _drawTripleBullets(canvas, cx, shipY, fireRate, bulletSpeed); break;
      case 'fan': _drawFanBullets(canvas, cx, shipY, fireRate, bulletSpeed); break;
      case 'bounce': _drawBounceBullets(canvas, cx, shipY, size); break;
      case 'homing': _drawHomingMissiles(canvas, cx, shipY, size); break;
      case 'plasma': _drawPlasmaBolts(canvas, cx, shipY, fireRate); break;
      case 'beam': _drawLaserBeam(canvas, cx, shipY); break;
    }
  }

  void _drawTargetEnemies(Canvas canvas, double cx, Size size) {
    final random = math.Random(33);
    for (int i = 0; i < 3; i++) {
      final baseX = cx + (i - 1) * 50.0;
      final x = baseX + math.sin(time * 0.7 + i * 2) * 15;
      final y = 25 + random.nextDouble() * 30 + math.cos(time * 0.5 + i) * 10;
      _drawTargetEnemy(canvas, x, y, 1.0);
    }
  }

  void _drawTargetEnemy(Canvas canvas, double x, double y, double alpha) {
    final r = 8.0;
    final rot = time * 3;
    canvas.save();
    canvas.translate(x, y);
    canvas.rotate(rot);
    final path = Path()
      ..moveTo(0, -r)..lineTo(r, 0)..lineTo(0, r)..lineTo(-r, 0)..close();
    canvas.drawPath(path, Paint()
      ..color = Color.fromRGBO(255, 50, 100, 0.15 * alpha)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));
    canvas.drawPath(path, Paint()
      ..color = Color.fromRGBO(255, 50, 100, 0.4 * alpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2);
    canvas.restore();
  }

  double _getFireRate() {
    switch (pattern) {
      case 'plasma': return 0.6;
      case 'homing': return 0.7;
      case 'triple': return 0.12;
      default: return 0.18;
    }
  }

  void _drawParallelBullets(Canvas canvas, double cx, double shipY, double rate, double speed) {
    final bulletPaint = Paint()..color = color;
    final glowPaint = Paint()
      ..color = color.withValues(alpha: 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    for (int i = 0; i < 12; i++) {
      final spawnTime = (time / rate + i * 0.5) % 8;
      final y = shipY - 22 - spawnTime * speed * 0.3;
      if (y < 10 || y > shipY - 10) continue;
      final alpha = ((shipY - 22 - y) / (shipY - 32)).clamp(0.0, 1.0);

      for (final xOff in [-6.0, 6.0]) {
        bulletPaint.color = color.withValues(alpha: alpha);
        glowPaint.color = color.withValues(alpha: alpha * 0.3);
        canvas.drawCircle(Offset(cx + xOff, y), 3, glowPaint);
        canvas.drawCircle(Offset(cx + xOff, y), 1.5, bulletPaint);
      }
    }
  }

  void _drawTripleBullets(Canvas canvas, double cx, double shipY, double rate, double speed) {
    final bulletPaint = Paint()..color = color;
    final glowPaint = Paint()
      ..color = color.withValues(alpha: 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    // Triplo sparo con angolo ristretto (~12° totali)
    const angles = [-0.105, 0.0, 0.105];
    for (int i = 0; i < 15; i++) {
      final spawnTime = (time / rate + i * 0.3) % 6;
      final dist = spawnTime * speed * 0.4;
      if (dist < 0 || shipY - 22 - dist < 10) continue;
      final alpha = (dist / (shipY - 32)).clamp(0.0, 1.0);

      for (final angle in angles) {
        final bx = cx + math.sin(angle) * dist;
        final by = shipY - 22 - math.cos(angle) * dist;
        if (by < 10 || by > shipY - 10) continue;
        bulletPaint.color = color.withValues(alpha: alpha);
        glowPaint.color = color.withValues(alpha: alpha * 0.3);
        canvas.drawCircle(Offset(bx, by), 3, glowPaint);
        canvas.drawCircle(Offset(bx, by), 1.5, bulletPaint);
      }
    }
  }

  void _drawFanBullets(Canvas canvas, double cx, double shipY, double rate, double speed) {
    final bulletPaint = Paint()..color = color;
    final glowPaint = Paint()
      ..color = color.withValues(alpha: 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

    final angles = [-0.175, -0.0875, 0.0, 0.0875, 0.175];
    for (int wave = 0; wave < 5; wave++) {
      final waveTime = (time / rate + wave * 1.2) % 8;
      if (waveTime > 3) continue;

      for (final angle in angles) {
        final dist = waveTime * speed * 0.4;
        final bx = cx + math.sin(angle) * dist;
        final by = shipY - 22 - math.cos(angle) * dist;
        if (by < 5 || by > shipY - 10) continue;
        final alpha = (1.0 - waveTime / 3).clamp(0.0, 1.0);

        bulletPaint.color = color.withValues(alpha: alpha);
        glowPaint.color = color.withValues(alpha: alpha * 0.3);
        canvas.drawCircle(Offset(bx, by), 2.5, glowPaint);
        canvas.drawCircle(Offset(bx, by), 1.2, bulletPaint);
      }
    }
  }

  void _drawBounceBullets(Canvas canvas, double cx, double shipY, Size size) {
    final bulletPaint = Paint()..color = color;
    final glowPaint = Paint()
      ..color = color.withValues(alpha: 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    final trailPaint = Paint()..strokeWidth = 1..style = PaintingStyle.stroke;

    // Bordi visibili dell'arena
    final edgePaint = Paint()
      ..color = color.withValues(alpha: 0.06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;
    canvas.drawRect(Rect.fromLTRB(12, 12, size.width - 12, shipY - 12), edgePaint);

    for (int b = 0; b < 2; b++) {
      final phase = time * 0.8 + b * 2.5;
      final points = <Offset>[];
      var x = cx;
      var y = shipY - 22.0;
      var dx = (b == 0 ? 1.0 : -1.0) * 40;
      var dy = -80.0;

      for (int step = 0; step < 100; step++) {
        points.add(Offset(x, y));
        x += dx * 0.02;
        y += dy * 0.02;
        if (x < 15 || x > size.width - 15) { dx = -dx; x = x.clamp(15, size.width - 15); }
        if (y < 15 || y > shipY - 15) { dy = -dy; y = y.clamp(15, shipY - 15); }
      }

      final idx = ((phase * 30) % points.length).toInt();

      // Trail con sfumatura
      for (int i = idx; i > idx - 20 && i > 0; i--) {
        final alpha = (1.0 - (idx - i) / 20) * 0.25;
        trailPaint.color = color.withValues(alpha: alpha);
        canvas.drawLine(points[i], points[i - 1], trailPaint);
      }

      // Flash sui punti di rimbalzo
      if (idx > 2 && idx < points.length - 1) {
        final prev = points[idx - 1];
        final curr = points[idx];
        if ((curr.dx < 18 || curr.dx > size.width - 18) || (curr.dy < 18 || curr.dy > shipY - 18)) {
          canvas.drawCircle(curr, 5, Paint()
            ..color = color.withValues(alpha: 0.2)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
        }
      }

      if (idx < points.length) {
        canvas.drawCircle(points[idx], 4, glowPaint);
        canvas.drawCircle(points[idx], 2, bulletPaint);
      }
    }
  }

  void _drawHomingMissiles(Canvas canvas, double cx, double shipY, Size size) {
    // Target che si muove
    final targetX = cx + math.cos(time * 0.5) * 45;
    final targetY = 35 + math.sin(time * 0.7) * 20;

    // Cerchio target con mirino
    final targetGlow = Paint()
      ..color = const Color(0xFFFF4444).withValues(alpha: 0.15)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(Offset(targetX, targetY), 12, targetGlow);
    _drawTargetEnemy(canvas, targetX, targetY, 0.7);

    // Mirino
    final crossPaint = Paint()
      ..color = const Color(0xFFFF4444).withValues(alpha: 0.15)
      ..strokeWidth = 0.5;
    canvas.drawLine(Offset(targetX - 18, targetY), Offset(targetX + 18, targetY), crossPaint);
    canvas.drawLine(Offset(targetX, targetY - 18), Offset(targetX, targetY + 18), crossPaint);

    // 3 missili
    for (int i = 0; i < 3; i++) {
      final phase = (time * 1.2 + i * 0.8) % 3;
      if (phase > 2.5) continue;

      final t = (phase / 2.5).clamp(0.0, 1.0);
      final startX = cx + (i - 1) * 8.0;
      final startY = shipY - 22;
      final midX = startX + (targetX - startX) * 0.3 + (i - 1) * 25;
      final midY = startY + (targetY - startY) * 0.3 - 35;
      final bx = _bezier(startX, midX, targetX, t);
      final by = _bezier(startY, midY, targetY, t);
      final alpha = (1.0 - t * 0.4).clamp(0.0, 1.0);

      // Trail con sfumatura
      for (int j = 1; j <= 10; j++) {
        final tt = (t - j * 0.025).clamp(0.0, 1.0);
        final tx = _bezier(startX, midX, targetX, tt);
        final ty = _bezier(startY, midY, targetY, tt);
        final ta = alpha * (1.0 - j / 10) * 0.3;
        canvas.drawCircle(Offset(tx, ty), 1.2, Paint()..color = color.withValues(alpha: ta));
      }

      // Missile con forma a freccia
      canvas.drawCircle(Offset(bx, by), 5, Paint()
        ..color = color.withValues(alpha: alpha * 0.25)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5));
      canvas.drawCircle(Offset(bx, by), 2.5, Paint()..color = color.withValues(alpha: alpha));

      // Impatto
      if (t > 0.9) {
        final impactAlpha = (t - 0.9) / 0.1 * 0.4;
        canvas.drawCircle(Offset(bx, by), 8 * (t - 0.9) / 0.1, Paint()
          ..color = Colors.white.withValues(alpha: impactAlpha)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
      }
    }
  }

  double _bezier(double p0, double p1, double p2, double t) {
    return (1 - t) * (1 - t) * p0 + 2 * (1 - t) * t * p1 + t * t * p2;
  }

  void _drawPlasmaBolts(Canvas canvas, double cx, double shipY, double rate) {
    for (int i = 0; i < 4; i++) {
      final phase = (time / rate + i * 2.5) % 10;
      final y = shipY - 27 - phase * 32;
      if (y < 8 || y > shipY - 15) continue;
      final alpha = (1.0 - phase / 10).clamp(0.0, 1.0);

      // Archi elettrici attorno al plasma
      final arcPaint = Paint()
        ..color = color.withValues(alpha: alpha * 0.15)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.5;
      final arcR = 8 + math.sin(time * 12 + i * 3) * 2;
      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, y), radius: arcR),
        time * 5 + i, math.pi * 0.8, false, arcPaint,
      );
      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, y), radius: arcR),
        time * 5 + i + math.pi, math.pi * 0.8, false, arcPaint,
      );

      // Plasma ball
      canvas.drawCircle(Offset(cx, y), 10, Paint()
        ..color = color.withValues(alpha: alpha * 0.15)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10));
      canvas.drawCircle(Offset(cx, y), 5, Paint()..color = color.withValues(alpha: alpha * 0.5));
      canvas.drawCircle(Offset(cx, y), 2.5, Paint()..color = Colors.white.withValues(alpha: alpha * 0.7));
    }
  }

  void _drawLaserBeam(Canvas canvas, double cx, double shipY) {
    final pulse = 0.7 + math.sin(time * 8) * 0.3;
    final beamTop = 20.0;
    final beamH = shipY - 22 - beamTop;

    // Scanning effect (il raggio oscilla leggermente)
    final scanX = cx + math.sin(time * 1.5) * 8;

    // Glow esterno
    canvas.drawRect(
      Rect.fromCenter(center: Offset(scanX, beamTop + beamH / 2), width: 18 * pulse, height: beamH),
      Paint()..color = color.withValues(alpha: 0.08 * pulse)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10));

    // Raggio medio
    canvas.drawRect(
      Rect.fromCenter(center: Offset(scanX, beamTop + beamH / 2), width: 6, height: beamH),
      Paint()..color = color.withValues(alpha: 0.3 * pulse)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3));

    // Nucleo
    canvas.drawRect(
      Rect.fromCenter(center: Offset(scanX, beamTop + beamH / 2), width: 2, height: beamH),
      Paint()..color = Colors.white.withValues(alpha: 0.6 * pulse));

    // Impatto in cima con particelle
    canvas.drawCircle(Offset(scanX, beamTop), 10 * pulse, Paint()
      ..color = color.withValues(alpha: 0.3 * pulse)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));
    // Scintille dall'impatto
    final random = math.Random(12);
    for (int i = 0; i < 4; i++) {
      final sparkAngle = time * 5 + i * math.pi / 2;
      final sparkDist = 5 + random.nextDouble() * 8;
      final sx = scanX + math.cos(sparkAngle) * sparkDist;
      final sy = beamTop + math.sin(sparkAngle).abs() * sparkDist;
      canvas.drawCircle(Offset(sx, sy), 1, Paint()
        ..color = Colors.white.withValues(alpha: 0.3 * pulse));
    }
  }

  @override
  bool shouldRepaint(covariant _WeaponPreviewPainter old) => old.time != time;
}
