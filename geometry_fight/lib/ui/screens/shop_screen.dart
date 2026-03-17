import 'package:flutter/material.dart';
import '../../data/save_data.dart';

class ShopScreen extends StatefulWidget {
  final VoidCallback onBack;

  const ShopScreen({super.key, required this.onBack});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late SaveData _saveData;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _saveData = SaveManager.load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _purchase(String id, int cost, VoidCallback onSuccess) {
    if (_saveData.goldGeoms >= cost) {
      setState(() {
        _saveData.goldGeoms -= cost;
        onSuccess();
        SaveManager.save(_saveData);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.cyanAccent),
          onPressed: widget.onBack,
        ),
        title: Row(
          children: [
            const Text(
              'SHOP',
              style: TextStyle(
                color: Colors.cyanAccent,
                fontFamily: 'monospace',
                fontWeight: FontWeight.bold,
                letterSpacing: 4,
              ),
            ),
            const Spacer(),
            const Icon(Icons.diamond, color: Color(0xFFFFD700), size: 18),
            const SizedBox(width: 6),
            Text(
              '${_saveData.goldGeoms}',
              style: const TextStyle(
                color: Color(0xFFFFD700),
                fontFamily: 'monospace',
                fontSize: 18,
              ),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: Colors.cyanAccent,
          unselectedLabelColor: Colors.white38,
          indicatorColor: Colors.cyanAccent,
          labelStyle: const TextStyle(fontFamily: 'monospace', fontSize: 11),
          tabs: const [
            Tab(text: 'SKINS'),
            Tab(text: 'TRAILS'),
            Tab(text: 'UPGRADES'),
            Tab(text: 'WEAPONS'),
            Tab(text: 'MODES'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSkinsTab(),
          _buildTrailsTab(),
          _buildUpgradesTab(),
          _buildWeaponsTab(),
          _buildModesTab(),
        ],
      ),
    );
  }

  Widget _buildSkinsTab() {
    final skins = [
      _ShopItem('classic', 'Classic', 0, 'Default ship'),
      _ShopItem('stealth', 'Stealth', 500, 'Black with red edges'),
      _ShopItem('crystal', 'Crystal', 1000, 'Diamond with prismatic effects'),
      _ShopItem('ghost', 'Ghost', 1500, 'Semi-transparent with particles'),
      _ShopItem('omega', 'Omega', 3000, '4-point star with rotation'),
    ];

    return _buildItemGrid(skins, _saveData.unlockedSkins, (item) {
      _purchase(item.id, item.cost, () {
        _saveData.unlockedSkins.add(item.id);
        _saveData.activeSkin = item.id;
      });
    }, (item) {
      setState(() => _saveData.activeSkin = item.id);
      SaveManager.save(_saveData);
    });
  }

  Widget _buildTrailsTab() {
    final trails = [
      _ShopItem('normal', 'Normal', 0, 'Default trail'),
      _ShopItem('fire', 'Fire', 200, 'Flame particles'),
      _ShopItem('ice', 'Ice', 200, 'Frost crystals'),
      _ShopItem('plasma', 'Plasma', 200, 'Energy plasma'),
      _ShopItem('rainbow', 'Rainbow', 200, 'Color shifting'),
    ];

    return _buildItemGrid(trails, _saveData.unlockedTrails, (item) {
      _purchase(item.id, item.cost, () {
        _saveData.unlockedTrails.add(item.id);
        _saveData.activeTrail = item.id;
      });
    }, (item) {
      setState(() => _saveData.activeTrail = item.id);
      SaveManager.save(_saveData);
    });
  }

  Widget _buildUpgradesTab() {
    final upgrades = [
      _UpgradeItem('firepower', 'FIREPOWER', [100, 200, 400, 800, 1500], 5,
          '+15-30% damage per level'),
      _UpgradeItem(
          'speed', 'SPEED', [100, 200, 400, 800, 1500], 5, '+10% speed per level'),
      _UpgradeItem('fire_rate', 'FIRE RATE', [100, 200, 400, 800, 1500], 5,
          '+8% fire rate per level'),
      _UpgradeItem('shield_capacity', 'SHIELD', [300, 700, 1500], 3,
          'Shield absorbs more hits'),
      _UpgradeItem('starting_lives', 'LIVES', [500, 1200], 2, 'Start with more lives'),
      _UpgradeItem('bomb_capacity', 'BOMBS', [400, 900], 2, 'Carry more bombs'),
      _UpgradeItem(
          'magnet_range', 'MAGNET', [250, 600, 1200], 3, 'Auto-collect range'),
      _UpgradeItem(
          'xp_boost', 'XP BOOST', [300, 700, 1500], 3, 'More GoldGeoms per game'),
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
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(
              color: isMaxed
                  ? Colors.greenAccent.withValues(alpha: 0.3)
                  : Colors.cyanAccent.withValues(alpha: 0.3),
            ),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.description,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 11,
                        fontFamily: 'monospace',
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Level indicators
                    Row(
                      children: List.generate(item.maxLevel, (i) {
                        return Container(
                          width: 20,
                          height: 4,
                          margin: const EdgeInsets.only(right: 3),
                          decoration: BoxDecoration(
                            color: i < currentLevel
                                ? Colors.cyanAccent
                                : Colors.white12,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),
              if (!isMaxed)
                GestureDetector(
                  onTap: () {
                    _purchase(item.id, cost, () {
                      _saveData.upgrades[item.id] = currentLevel + 1;
                    });
                  },
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: _saveData.goldGeoms >= cost
                            ? Colors.cyanAccent
                            : Colors.white24,
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.diamond,
                            color: Color(0xFFFFD700), size: 14),
                        const SizedBox(width: 4),
                        Text(
                          '$cost',
                          style: TextStyle(
                            color: _saveData.goldGeoms >= cost
                                ? Colors.cyanAccent
                                : Colors.white24,
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                const Text(
                  'MAX',
                  style: TextStyle(
                    color: Colors.greenAccent,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWeaponsTab() {
    final weapons = [
      _ShopItem('basic', 'Basic Gun', 0, 'Default weapon'),
      _ShopItem('twin', 'Twin Shot', 800, 'Parallel double bullets'),
      _ShopItem('spread', 'Spread Shot', 1000, '5-bullet fan'),
      _ShopItem('ricochet', 'Ricochet', 1200, 'Bouncing bullets'),
    ];

    return _buildItemGrid(weapons, _saveData.unlockedWeapons, (item) {
      _purchase(item.id, item.cost, () {
        _saveData.unlockedWeapons.add(item.id);
        _saveData.startingWeapon = item.id;
      });
    }, (item) {
      setState(() => _saveData.startingWeapon = item.id);
      SaveManager.save(_saveData);
    });
  }

  Widget _buildModesTab() {
    final modes = [
      _ShopItem('classic', 'Classic', 0, '40 waves + endless'),
      _ShopItem('boss_rush', 'Boss Rush', 2000, 'Boss after boss'),
      _ShopItem('survival', 'Survival', 2500, 'Infinite waves, no breaks'),
      _ShopItem('challenge', 'Challenge', 3000, '10 unique challenges'),
    ];

    return _buildItemGrid(modes, _saveData.unlockedModes, (item) {
      _purchase(item.id, item.cost, () {
        _saveData.unlockedModes.add(item.id);
      });
    }, null);
  }

  Widget _buildItemGrid(
    List<_ShopItem> items,
    List<String> unlocked,
    void Function(_ShopItem) onPurchase,
    void Function(_ShopItem)? onSelect,
  ) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.3,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final owned = unlocked.contains(item.id);

        return GestureDetector(
          onTap: () {
            if (owned && onSelect != null) {
              onSelect(item);
            } else if (!owned) {
              onPurchase(item);
            }
          },
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(
                color: owned
                    ? Colors.cyanAccent.withValues(alpha: 0.5)
                    : Colors.white24,
              ),
              borderRadius: BorderRadius.circular(6),
              color: owned ? Colors.cyanAccent.withValues(alpha: 0.05) : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  item.name,
                  style: TextStyle(
                    color: owned ? Colors.cyanAccent : Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  item.description,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4),
                    fontSize: 10,
                    fontFamily: 'monospace',
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                if (owned)
                  const Text(
                    'OWNED',
                    style: TextStyle(
                      color: Colors.greenAccent,
                      fontSize: 11,
                      fontFamily: 'monospace',
                    ),
                  )
                else
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.diamond,
                          color: Color(0xFFFFD700), size: 14),
                      const SizedBox(width: 4),
                      Text(
                        '${item.cost}',
                        style: TextStyle(
                          color: _saveData.goldGeoms >= item.cost
                              ? const Color(0xFFFFD700)
                              : Colors.white24,
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ShopItem {
  final String id;
  final String name;
  final int cost;
  final String description;

  _ShopItem(this.id, this.name, this.cost, this.description);
}

class _UpgradeItem {
  final String id;
  final String name;
  final List<int> costs;
  final int maxLevel;
  final String description;

  _UpgradeItem(this.id, this.name, this.costs, this.maxLevel, this.description);
}
