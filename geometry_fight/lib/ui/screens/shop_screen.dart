import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../data/achievements.dart';
import '../../data/save_data.dart';
import '../../data/constants.dart';
import '../../data/pet_types.dart';
import '../../l10n/generated/app_localizations.dart';
import '../widgets/neon_back_button.dart';

/// Iter 13: total counts per collection achievement (`all_*`).
/// Allineati ai cataloghi in `_buildSkinsTab` / `_buildTrailsTab` /
/// `_buildWeaponsTab` + `kPetCatalog`. Aggiornare se aggiungo entry.
const int _kTotalSkins = 16;
const int _kTotalTrails = 16;
const int _kTotalWeapons = 9;

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

  // Scroll controllers for cyan Scrollbar on every scrollable view.
  // Separate controllers per-tab so multiple ListViews can stay alive
  // simultaneously (TabBarView keeps state) without ScrollController
  // attach conflicts.
  final ScrollController _petsScrollCtrl = ScrollController();
  final ScrollController _upgradesScrollCtrl = ScrollController();
  final ScrollController _modesScrollCtrl = ScrollController();
  final ScrollController _weaponsListCtrl = ScrollController();
  final ScrollController _weaponsPreviewCtrl = ScrollController();
  final ScrollController _skinsListCtrl = ScrollController();
  final ScrollController _skinsPreviewCtrl = ScrollController();
  final ScrollController _trailsListCtrl = ScrollController();
  final ScrollController _trailsPreviewCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    // 6 tab: upgrades, weapons, pets (NUOVO), modes, skins, trails.
    _tabController = TabController(length: 6, vsync: this);
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
    _petsScrollCtrl.dispose();
    _upgradesScrollCtrl.dispose();
    _modesScrollCtrl.dispose();
    _weaponsListCtrl.dispose();
    _weaponsPreviewCtrl.dispose();
    _skinsListCtrl.dispose();
    _skinsPreviewCtrl.dispose();
    _trailsListCtrl.dispose();
    _trailsPreviewCtrl.dispose();
    super.dispose();
  }

  /// Wrap any scrollable widget with a prominent cyan scrollbar.
  /// Uses [RawScrollbar] to force exact colors/thickness regardless of theme.
  Widget _cyanScrollbar({
    required ScrollController controller,
    required Widget child,
  }) {
    return RawScrollbar(
      controller: controller,
      thumbVisibility: true,
      trackVisibility: true,
      thickness: 10,
      radius: const Radius.circular(5),
      thumbColor: const Color(0xFF00FFFF),
      trackColor: const Color(0x3300FFFF),
      trackBorderColor: const Color(0x8800FFFF),
      child: child,
    );
  }

  /// Iter 13: dopo ogni purchase verifica collection completion e
  /// unlock achievement `all_skins`/`all_trails`/`all_weapons`/`all_pets`.
  void _checkCollectionUnlocks() {
    if (_saveData.unlockedSkins.length >= _kTotalSkins) {
      AchievementManager.unlock('all_skins');
    }
    if (_saveData.unlockedTrails.length >= _kTotalTrails) {
      AchievementManager.unlock('all_trails');
    }
    if (_saveData.unlockedWeapons.length >= _kTotalWeapons) {
      AchievementManager.unlock('all_weapons');
    }
    // Pet catalog len (incluso 'none' default). Confronta su unlockedPets.
    if (_saveData.unlockedPets.length >= kPetCatalog.length) {
      AchievementManager.unlock('all_pets');
    }
  }

  // ==================== L10N HELPERS ====================
  //
  // Catalog name/description lookups by stable id. Fallback to the def's
  // raw `name`/`description` field if id isn't recognized (defensive).

  String _skinName(AppLocalizations l10n, String id, String fallback) =>
      switch (id) {
        'classic' => l10n.skinNameClassic,
        'stealth' => l10n.skinNameStealth,
        'crystal' => l10n.skinNameCrystal,
        'ghost' => l10n.skinNameGhost,
        'omega' => l10n.skinNameOmega,
        'phoenix' => l10n.skinNamePhoenix,
        'cyber' => l10n.skinNameCyber,
        'voidwalker' => l10n.skinNameVoidwalker,
        'aurora' => l10n.skinNameAurora,
        'tactical' => l10n.skinNameTactical,
        'prism' => l10n.skinNamePrism,
        'tron' => l10n.skinNameTron,
        'samurai' => l10n.skinNameSamurai,
        'rosegold' => l10n.skinNameRosegold,
        'ninja' => l10n.skinNameNinja,
        'glitch' => l10n.skinNameGlitch,
        _ => fallback,
      };

  String _skinDesc(AppLocalizations l10n, String id, String fallback) =>
      switch (id) {
        'classic' => l10n.skinDescClassic,
        'stealth' => l10n.skinDescStealth,
        'crystal' => l10n.skinDescCrystal,
        'ghost' => l10n.skinDescGhost,
        'omega' => l10n.skinDescOmega,
        'phoenix' => l10n.skinDescPhoenix,
        'cyber' => l10n.skinDescCyber,
        'voidwalker' => l10n.skinDescVoidwalker,
        'aurora' => l10n.skinDescAurora,
        'tactical' => l10n.skinDescTactical,
        'prism' => l10n.skinDescPrism,
        'tron' => l10n.skinDescTron,
        'samurai' => l10n.skinDescSamurai,
        'rosegold' => l10n.skinDescRosegold,
        'ninja' => l10n.skinDescNinja,
        'glitch' => l10n.skinDescGlitch,
        _ => fallback,
      };

  String _trailName(AppLocalizations l10n, String id, String fallback) =>
      switch (id) {
        'normal' => l10n.trailNameNormal,
        'fire' => l10n.trailNameFire,
        'ice' => l10n.trailNameIce,
        'plasma' => l10n.trailNamePlasma,
        'rainbow' => l10n.trailNameRainbow,
        'comet' => l10n.trailNameComet,
        'inferno' => l10n.trailNameInferno,
        'void' => l10n.trailNameVoid,
        'quantum' => l10n.trailNameQuantum,
        'galaxy' => l10n.trailNameGalaxy,
        'lightning' => l10n.trailNameLightning,
        'nebula' => l10n.trailNameNebula,
        'prism' => l10n.trailNamePrism,
        'hologram' => l10n.trailNameHologram,
        'biolume' => l10n.trailNameBiolume,
        'neonpulse' => l10n.trailNameNeonpulse,
        _ => fallback,
      };

  String _trailDesc(AppLocalizations l10n, String id, String fallback) =>
      switch (id) {
        'normal' => l10n.trailDescNormal,
        'fire' => l10n.trailDescFire,
        'ice' => l10n.trailDescIce,
        'plasma' => l10n.trailDescPlasma,
        'rainbow' => l10n.trailDescRainbow,
        'comet' => l10n.trailDescComet,
        'inferno' => l10n.trailDescInferno,
        'void' => l10n.trailDescVoid,
        'quantum' => l10n.trailDescQuantum,
        'galaxy' => l10n.trailDescGalaxy,
        'lightning' => l10n.trailDescLightning,
        'nebula' => l10n.trailDescNebula,
        'prism' => l10n.trailDescPrism,
        'hologram' => l10n.trailDescHologram,
        'biolume' => l10n.trailDescBiolume,
        'neonpulse' => l10n.trailDescNeonpulse,
        _ => fallback,
      };

  String _weaponName(AppLocalizations l10n, String id, String fallback) =>
      switch (id) {
        'basic' => l10n.weaponNameBasic,
        'triple' => l10n.weaponNameTriple,
        'spread' => l10n.weaponNameSpread,
        'ricochet' => l10n.weaponNameRicochet,
        'homing' => l10n.weaponNameHoming,
        'plasma' => l10n.weaponNamePlasma,
        'laser' => l10n.weaponNameLaser,
        'gauss' => l10n.weaponNameGauss,
        'chain' => l10n.weaponNameChain,
        _ => fallback,
      };

  String _weaponDesc(AppLocalizations l10n, String id, String fallback) =>
      switch (id) {
        'basic' => l10n.weaponDescBasic,
        'triple' => l10n.weaponDescTriple,
        'spread' => l10n.weaponDescSpread,
        'ricochet' => l10n.weaponDescRicochet,
        'homing' => l10n.weaponDescHoming,
        'plasma' => l10n.weaponDescPlasma,
        'laser' => l10n.weaponDescLaser,
        'gauss' => l10n.weaponDescGauss,
        'chain' => l10n.weaponDescChain,
        _ => fallback,
      };

  String _modeName(AppLocalizations l10n, String id, String fallback) =>
      switch (id) {
        'classic' => l10n.modeClassic,
        'bossRush' => l10n.modeBossRush,
        'survival' => l10n.modeSurvival,
        'timeAttack' => l10n.modeTimeAttack,
        'zenMode' => l10n.modeZen,
        'tunnel' => l10n.modeTunnel,
        'pacifist' => l10n.modePacifist,
        'waves' => l10n.modeWaves,
        'gravityInferno' => l10n.modeGravityInferno,
        _ => fallback,
      };

  String _modeDesc(AppLocalizations l10n, String id, String fallback) =>
      switch (id) {
        'classic' => l10n.modeDescClassic,
        'bossRush' => l10n.modeDescBossRush,
        'survival' => l10n.modeDescSurvival,
        'timeAttack' => l10n.modeDescTimeAttack,
        'zenMode' => l10n.modeDescZenMode,
        'tunnel' => l10n.modeDescTunnel,
        'pacifist' => l10n.modeDescPacifist,
        'waves' => l10n.modeDescWaves,
        'gravityInferno' => l10n.modeDescGravityInferno,
        _ => fallback,
      };

  String _upgradeName(AppLocalizations l10n, String id, String fallback) =>
      switch (id) {
        'firepower' => l10n.upgradeFirepower,
        'fire_rate' => l10n.upgradeFireRate,
        'speed' => l10n.upgradeSpeed,
        'shield_capacity' => l10n.upgradeShield,
        'starting_lives' => l10n.upgradeLives,
        'bomb_capacity' => l10n.upgradeBombs,
        'magnet_range' => l10n.upgradeMagnet,
        'xp_boost' => l10n.upgradeXpBoost,
        _ => fallback,
      };

  /// Catalog item name dispatch by runtime type — used in shared render code.
  String _itemName(AppLocalizations l10n, _ShopItem item) {
    if (item is _SkinDef) return _skinName(l10n, item.id, item.name);
    if (item is _TrailDef) return _trailName(l10n, item.id, item.name);
    if (item is _WeaponDef) return _weaponName(l10n, item.id, item.name);
    if (item is _ModeDef) return _modeName(l10n, item.id, item.name);
    return item.name;
  }

  String _itemDesc(AppLocalizations l10n, _ShopItem item) {
    if (item is _SkinDef) return _skinDesc(l10n, item.id, item.description);
    if (item is _TrailDef) return _trailDesc(l10n, item.id, item.description);
    if (item is _WeaponDef) return _weaponDesc(l10n, item.id, item.description);
    if (item is _ModeDef) return _modeDesc(l10n, item.id, item.description);
    return item.description;
  }

  void _purchase(String id, int cost, VoidCallback onSuccess) {
    if (_saveData.goldGeoms >= cost) {
      setState(() {
        _saveData.goldGeoms -= cost;
        onSuccess();
        _checkCollectionUnlocks();
      });
      unawaited(SaveManager.save(_saveData));
    } else {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.shopGoldInsufficient,
              style: const TextStyle(fontFamily: 'monospace')),
          backgroundColor: Colors.redAccent,
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  /// Attempt to buy/level-up an upgrade node directly from a tap on the
  /// talent-tree map. Deducts gold, increments level, saves, shows snackbar.
  /// No-op when already maxed (with a hint snackbar).
  void _tryBuyUpgrade(_UpgradeItem item) {
    final currentLevel = _saveData.getUpgradeLevel(item.id);
    // Idempotent on max-level: show hint snackbar and bail before _purchase.
    if (currentLevel >= item.maxLevel) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.shopAlreadyMax(_upgradeName(l10n, item.id, item.name)),
            style: const TextStyle(fontFamily: 'monospace'),
          ),
          backgroundColor: Colors.blueGrey,
          duration: const Duration(seconds: 1),
        ),
      );
      return;
    }
    final safeLvl = currentLevel.clamp(0, item.costs.length - 1);
    final cost = item.costs[safeLvl];
    _purchase(item.id, cost, () {
      _saveData.upgrades[item.id] = currentLevel + 1;
    });
    // Success snackbar only when the level actually advanced (purchase may
    // have failed silently inside _purchase if gold was insufficient — in
    // which case _purchase has already shown its own "gold insufficiente"
    // snackbar and we must not stack a second one).
    if (!mounted) return;
    if (_saveData.getUpgradeLevel(item.id) > currentLevel) {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.shopUpgradedToLevel(
                _upgradeName(l10n, item.id, item.name), currentLevel + 1),
            style: const TextStyle(fontFamily: 'monospace'),
          ),
          backgroundColor: Colors.green.shade700,
          duration: const Duration(milliseconds: 900),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
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
                  Text(
                    l10n.shopTitle,
                    style: const TextStyle(
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
              tabs: [
                Tab(text: l10n.shopTabUpgrades),
                Tab(text: l10n.shopTabWeapons),
                Tab(text: l10n.shopTabPets),
                Tab(text: l10n.shopTabModes),
                Tab(text: l10n.shopTabSkins),
                Tab(text: l10n.shopTabTrails),
              ],
            ),
            // Tab content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildUpgradesTab(),
                  _buildWeaponsTab(),
                  _buildPetsTab(),
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
      _SkinDef('phoenix', 'Phoenix', 2500, 'Ali di fuoco con piume di brace — rinasce dalle ceneri', const Color(0xFFFF5500)),
      _SkinDef('cyber', 'Cyber', 2000, 'Mesh circuiti neon verde — overlay digitale animato', const Color(0xFF00FF66)),
      _SkinDef('voidwalker', 'Voidwalker', 3500, 'Nucleo viola sospeso nel vuoto — alone etereo', const Color(0xFFAA44FF)),
      _SkinDef('aurora', 'Aurora', 2500, 'Boreale: ciano/rosa/verde che fluiscono', const Color(0xFF66FFCC)),
      _SkinDef('tactical', 'Tactical', 1500, 'Corazza militare grigio/blu — placche corazzate', const Color(0xFF6688AA)),
      _SkinDef('prism', 'Prism', 4000, 'Cristallo poligonale — rifrazione arcobaleno multipla', const Color(0xFFFFFFFF)),
      _SkinDef('tron', 'Tron', 3000, 'Body nero con linee neon ciano — circuit grid digitale', const Color(0xFF00DDFF)),
      _SkinDef('samurai', 'Samurai', 3500, 'Corazza nera con dettagli oro/rosso — onore e battaglia', const Color(0xFFFFAA00)),
      _SkinDef('rosegold', 'RoseGold', 2500, 'Metallico rosa-oro — eleganza moderna', const Color(0xFFFFAACC)),
      _SkinDef('ninja', 'Ninja', 2000, 'Grigio ombra con accenti shuriken — silenzioso e letale', const Color(0xFF445566)),
      _SkinDef('glitch', 'Glitch', 4500, 'RGB chromatic shift — aberration animata', const Color(0xFFFF0066)),
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
      listController: _skinsListCtrl,
      previewController: _skinsPreviewCtrl,
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
      _TrailDef('comet', 'Comet', 800, 'Testa luminosa con coda che si spegne lentamente', const Color(0xFFFFFFCC)),
      _TrailDef('inferno', 'Inferno', 1200, 'Fuoco multi-strato con braci che schizzano', const Color(0xFFFF3300)),
      _TrailDef('void', 'Void', 1500, 'Vortice oscuro che risucchia particelle viola', const Color(0xFF8800FF)),
      _TrailDef('quantum', 'Quantum', 1500, 'Particelle accoppiate in superposizione cromatica', const Color(0xFF00FFCC)),
      _TrailDef('galaxy', 'Galaxy', 2000, 'Stelle che spiraleggiano con polvere cosmica', const Color(0xFFCCAAFF)),
      _TrailDef('lightning', 'Lightning', 1500, 'Archi elettrici a zigzag tra i punti scia', const Color(0xFFFFFF44)),
      _TrailDef('nebula', 'Nebula', 1800, 'Nuvola spaziale ciano/magenta che pulsa', const Color(0xFF44CCFF)),
      _TrailDef('prism', 'Prism', 2200, 'Spettro completo che scorre lungo la scia', const Color(0xFFFF66FF)),
      _TrailDef('hologram', 'Hologram', 1700, 'RGB chromatic aberration in stile glitch', const Color(0xFFFF2244)),
      _TrailDef('biolume', 'Biolumin', 1600, 'Bioluminescenza acquatica verde/ciano', const Color(0xFF00FFAA)),
      _TrailDef('neonpulse', 'NeonPulse', 1900, 'Anelli neon expanding bianco-ciano', const Color(0xFF66FFFF)),
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
      listController: _trailsListCtrl,
      previewController: _trailsPreviewCtrl,
    );
  }

  // ==================== WEAPONS TAB ====================

  Widget _buildWeaponsTab() {
    final weapons = [
      _WeaponDef('basic', 'Basic Gun', 0,
          'Doppia fila di proiettili gialli paralleli — affidabile e preciso.',
          NeonColors.bulletYellow, 'parallel',
          stats: ['DMG: 1', 'RATE: MED', 'RANGE: 900', 'BULLETS: 2']),
      _WeaponDef('triple', 'Triple Shot', 800,
          '3 proiettili bianchi ravvicinati — fuoco concentrato.',
          NeonColors.white, 'triple',
          stats: ['DMG: 1x3', 'RATE: FAST', 'SPREAD: 12°']),
      _WeaponDef('spread', 'Spread Shot', 1000,
          '5 proiettili arancioni a ventaglio stretto — ottimo vs gruppi.',
          NeonColors.spreadOrange, 'fan',
          stats: ['DMG: 0.85x5', 'RATE: MED', 'SPREAD: 14°']),
      _WeaponDef('ricochet', 'Ricochet', 1200,
          'Ventaglio di 3 colpi verdi ad alto danno che rimbalzano 2 volte sui muri.',
          NeonColors.ricochetGreen, 'bounce',
          stats: ['DMG: 0.83x3', 'RATE: MED', 'BOUNCE: 2x', 'SPREAD: 23°']),
      _WeaponDef('homing', 'Homing', 1500,
          '5 missili che inseguono bersagli distinti — esplodono al muro.',
          NeonColors.pink, 'homing',
          stats: ['DMG: 1.5', 'RATE: SLOW', 'TRACK: 150px', 'BLAST: 48']),
      _WeaponDef('plasma', 'Plasma', 2000,
          'Orb viola lento con AoE esplosiva — devasta boss e gruppi.',
          NeonColors.plasmaViolet, 'plasma',
          stats: ['DMG: 3.9x', 'RATE: SLOW', 'AOE: 80px']),
      _WeaponDef('laser', 'Laser', 2500,
          'Raggio rosso continuo — taglia tutto ciò che tocca.',
          NeonColors.laserRed, 'beam',
          stats: ['DMG: 0.5/tick', 'RATE: CONT', 'PIERCE: ∞', 'LEN: 800']),
      _WeaponDef('gauss', 'Gauss Cannon', 2800,
          'Colpo viola con aspirazione gravitazionale 1s — raggruppa i nemici per colpirli tutti.',
          const Color(0xFFCC66FF), 'gauss',
          stats: ['DMG: 1.8', 'RATE: 0.7s', 'PULL: 220px/1s', 'PIERCE']),
      _WeaponDef('chain', 'Chain Lightning', 3200,
          'Fulmine elettrico rimbalza tra 5 nemici — perfetto vs gruppi.',
          const Color(0xFFFFFF44), 'chain',
          stats: ['DMG: 1.2x', 'RATE: 0.55s', 'JUMPS: 5', 'RANGE: 380/220']),
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
      listController: _weaponsListCtrl,
      previewController: _weaponsPreviewCtrl,
      hideDescription: true,
    );
  }

  // ==================== PETS TAB ====================

  /// Pets tab: lista pet companion (kPetCatalog) con buy/equip.
  /// Diversa dagli altri tab perché non serve preview painter — i pet
  /// sono visibili in-game, qui basta nome + descrizione + costo.
  Widget _buildPetsTab() {
    return _cyanScrollbar(
      controller: _petsScrollCtrl,
      child: ListView.builder(
      controller: _petsScrollCtrl,
      padding: const EdgeInsets.all(12),
      itemCount: kPetCatalog.length,
      itemBuilder: (context, index) {
        final p = kPetCatalog[index];
        final owned = _saveData.unlockedPets.contains(p.id);
        final isActive = _saveData.activePet == p.id;

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
                color: isActive
                    ? p.color.withValues(alpha: 0.9)
                    : p.color.withValues(alpha: 0.3),
                width: isActive ? 2 : 1),
            color: p.color.withValues(alpha: isActive ? 0.10 : 0.04),
          ),
          child: Row(
            children: [
              // Pet badge (cerchio colorato + iconCode)
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: p.color.withValues(alpha: 0.18),
                  border: Border.all(
                      color: p.color.withValues(alpha: 0.7), width: 2),
                  boxShadow: [
                    BoxShadow(
                        color: p.color.withValues(alpha: 0.5), blurRadius: 8)
                  ],
                ),
                alignment: Alignment.center,
                child: Text(
                  p.iconCode,
                  style: TextStyle(
                    color: p.color,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
              const SizedBox(width: 14),
              // Nome + descrizione
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.displayName,
                      style: TextStyle(
                        color: p.color,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        fontFamily: 'monospace',
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      p.description,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 11,
                        fontFamily: 'monospace',
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              // Action button (BUY o EQUIP/EQUIPPED)
              _PetActionButton(
                cost: p.cost,
                owned: owned,
                isActive: isActive,
                color: p.color,
                onBuy: () {
                  _purchase(p.id, p.cost, () {
                    if (!_saveData.unlockedPets.contains(p.id)) {
                      _saveData.unlockedPets.add(p.id);
                    }
                    _saveData.activePet = p.id;
                  });
                },
                onEquip: () {
                  setState(() => _saveData.activePet = p.id);
                  SaveManager.save(_saveData);
                },
              ),
            ],
          ),
        );
      },
    ),
    );
  }

  // ==================== UPGRADES TAB ====================

  /// Diagonal talent tree: 3 tiers, tiered prereqs. Tap nodo → buy +1 livello
  /// se affordable + sbloccato. Niente bottom info card: nome + level/maxLevel
  /// renderizzati sotto ogni nodo.
  Widget _buildUpgradesTab() {
    final upgrades = _upgradeNodes();
    return _cyanScrollbar(
      controller: _upgradesScrollCtrl,
      child: SingleChildScrollView(
        controller: _upgradesScrollCtrl,
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final mapW = constraints.maxWidth;
            // Aspect 1.55× → 6 righe (diamond chain) leggibili senza scroll.
            final mapH = mapW * 1.55;
            return SizedBox(
              width: mapW,
              height: mapH,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    child: AnimatedBuilder(
                      animation: _previewController,
                      builder: (_, child) => CustomPaint(
                        painter: _UpgradeMapPainter(
                          nodes: upgrades,
                          connections: _upgradeConnections,
                          saveData: _saveData,
                          time: _previewController.value * 6.283,
                        ),
                      ),
                    ),
                  ),
                  for (final node in upgrades)
                    Positioned(
                      // Width 72 → center horizontally; vertical offset 28
                      // allinea (node.y * mapH) al centro del cerchio icona
                      // (icon spans 0-56 px nel widget, centro a 28 px).
                      left: node.x * mapW - 36,
                      top: node.y * mapH - 28,
                      child: _UpgradeMapNode(
                        item: node.item,
                        currentLevel:
                            _saveData.getUpgradeLevel(node.item.id),
                        l10n: AppLocalizations.of(context)!,
                        upgradeName: _upgradeName(
                            AppLocalizations.of(context)!,
                            node.item.id,
                            node.item.name),
                        unlocked: _isUpgradeUnlocked(node.item.id),
                        onTap: () {
                          if (!_isUpgradeUnlocked(node.item.id)) return;
                          _tryBuyUpgrade(node.item);
                        },
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  /// Prereq map: id → list of (prereqId, requiredLevel) pairs.
  /// Nodo unlocked solo quando TUTTI i prereq raggiungono il loro livello.
  /// Vertical-chain layout (diamond): speed root → firepower/fire_rate →
  /// shield → bomb/lives → magnet → xp_boost.
  static const Map<String, List<(String, int)>> _prereqs = {
    'speed': [],
    'firepower': [('speed', 5)],
    'fire_rate': [('speed', 5)],
    'shield_capacity': [('firepower', 5), ('fire_rate', 5)],
    'bomb_capacity': [('shield_capacity', 5)],
    'starting_lives': [('shield_capacity', 5)],
    'magnet_range': [('bomb_capacity', 5), ('starting_lives', 5)],
    'xp_boost': [('magnet_range', 5)],
  };

  bool _isUpgradeUnlocked(String id) {
    final reqs = _prereqs[id];
    if (reqs == null || reqs.isEmpty) return true;
    for (final (prereqId, minLevel) in reqs) {
      if (_saveData.getUpgradeLevel(prereqId) < minLevel) return false;
    }
    return true;
  }

  /// Talent-tree node layout: chain verticale a diamante (6 righe).
  /// Coordinate normalizzate (x,y in [0,1] = % della grid area).
  List<_UpgradeNode> _upgradeNodes() => const [
        // Row 0 (y=0.06): root
        _UpgradeNode(
            x: 0.50,
            y: 0.06,
            item: _UpgradeItem(
                'speed',
                'SPEED',
                [50, 100, 150, 200, 250, 300, 350, 400, 450, 500],
                10,
                '+2.5% velocità per livello (max +25% al L10)',
                Icons.speed,
                NeonColors.cyan)),
        // Row 1 (y=0.22): combat core
        _UpgradeNode(
            x: 0.30,
            y: 0.22,
            item: _UpgradeItem(
                'firepower',
                'FIREPOWER',
                [50, 100, 150, 200, 250, 300, 350, 400, 450, 500],
                10,
                '+2.5% danno per livello (max +25% al L10)',
                Icons.local_fire_department,
                Color(0xFFFF4400))),
        _UpgradeNode(
            x: 0.70,
            y: 0.22,
            item: _UpgradeItem(
                'fire_rate',
                'FIRE RATE',
                [50, 100, 150, 200, 250, 300, 350, 400, 450, 500],
                10,
                '+2.5% cadenza per livello (max +25% al L10)',
                Icons.bolt,
                NeonColors.bulletYellow)),
        // Row 2 (y=0.38): shield join
        _UpgradeNode(
            x: 0.50,
            y: 0.38,
            item: _UpgradeItem(
                'shield_capacity',
                'SHIELD',
                [120, 240, 360, 480, 600, 720, 840, 960, 1080, 1200],
                10,
                'Scudo post-morte: +2.5s per livello (max 25s al L10)',
                Icons.shield_outlined,
                Color(0xFF00AAFF))),
        // Row 3 (y=0.54): bomb / lives split
        _UpgradeNode(
            x: 0.30,
            y: 0.54,
            item: _UpgradeItem(
                'bomb_capacity',
                'BOMB RANGE',
                [60, 120, 180, 240, 300, 360, 420, 480, 540, 600],
                10,
                '+raggio esplosione per livello (L0 metà arena, L10 arena intera)',
                Icons.blur_circular,
                NeonColors.orange)),
        _UpgradeNode(
            x: 0.70,
            y: 0.54,
            item: _UpgradeItem(
                'starting_lives',
                'LIVES',
                [80, 160, 240, 320, 400, 480, 560, 640, 720, 800],
                10,
                'Vite iniziali: +1 ogni 2 livelli (max +5 al L10)',
                Icons.favorite,
                Color(0xFFFF4466))),
        // Row 4 (y=0.70): magnet join
        _UpgradeNode(
            x: 0.50,
            y: 0.70,
            item: _UpgradeItem(
                'magnet_range',
                'MAGNET',
                [100, 200, 300, 400, 500, 600, 700, 800, 900, 1000],
                10,
                '+5px raggio magnete per livello (max +50px al L10)',
                Icons.radar,
                NeonColors.purple)),
        // Row 5 (y=0.86): xp tail
        _UpgradeNode(
            x: 0.50,
            y: 0.86,
            item: _UpgradeItem(
                'xp_boost',
                'XP BOOST',
                [100, 200, 300, 400, 500, 600, 700, 800, 900, 1000],
                10,
                '+5% GoldGeom per livello (max +50% al L10)',
                Icons.auto_awesome,
                Color(0xFFFFD700))),
      ];

  /// Connessioni skill-tree (id_a, id_b) — linee tra prereq e dipendenti.
  static const _upgradeConnections = <(String, String)>[
    ('speed', 'firepower'),
    ('speed', 'fire_rate'),
    ('firepower', 'shield_capacity'),
    ('fire_rate', 'shield_capacity'),
    ('shield_capacity', 'bomb_capacity'),
    ('shield_capacity', 'starting_lives'),
    ('bomb_capacity', 'magnet_range'),
    ('starting_lives', 'magnet_range'),
    ('magnet_range', 'xp_boost'),
  ];

  // ==================== MODES TAB ====================

  Widget _buildModesTab() {
    final l10n = AppLocalizations.of(context)!;
    final modes = [
      _ModeDef('classic', 'Classic', 0, '100 wave con boss ogni 10 — il modo standard', Icons.games, NeonColors.cyan),
      _ModeDef('bossRush', 'Boss Rush', 2000, 'Solo boss, uno dopo l\'altro — niente mob', Icons.whatshot, const Color(0xFFFF4400)),
      _ModeDef('survival', 'Survival', 2500, 'Wave infinite sempre più difficili — quanto resisti?', Icons.all_inclusive, const Color(0xFF00FF88)),
      _ModeDef('timeAttack', 'Time Attack', 1500, '3 minuti: fai più punti possibile prima che scada', Icons.timer, NeonColors.orange),
      _ModeDef('zenMode', 'Zen Mode', 1000, 'Vite infinite — gioca senza stress, esplora tutto', Icons.spa, const Color(0xFF88CCFF)),
      _ModeDef('tunnel', 'Tunnel', 3000, 'Scorrimento laterale in un tunnel infinito', Icons.straighten, NeonColors.purple),
      _ModeDef('pacifist', 'Pacifist', 1500, 'Niente colpi! Sopravvivi con i Gate (GW Pacifism)', Icons.spa_outlined, const Color(0xFF77FFD4)),
      _ModeDef('waves', 'Waves', 800, 'Solo triangoli rossi cardinali. Rari buchi neri. Dodge puro.', Icons.change_history, const Color(0xFFFF3344)),
      _ModeDef('gravityInferno', 'Gravity Inferno', 1800, 'Tanti buchi neri + pochi mob misti. Niente boss. Caos gravitazionale.', Icons.blur_circular, const Color(0xFF9933FF)),
    ];

    // Single-column list con card grosse: icona+nome+descrizione+stato.
    // Glow pulsante sui posseduti, "NEW" badge su Pacifist (ultima aggiunta).
    return AnimatedBuilder(
      animation: _previewController,
      builder: (context, _) {
        final pulse = (math.sin(_previewController.value * math.pi * 2) * 0.5 + 0.5);
        return _cyanScrollbar(
          controller: _modesScrollCtrl,
          child: ListView.builder(
          controller: _modesScrollCtrl,
          padding: const EdgeInsets.all(14),
          itemCount: modes.length,
          itemBuilder: (context, index) {
            final item = modes[index];
            final owned = _saveData.unlockedModes.contains(item.id);
            final canAfford = _saveData.goldGeoms >= item.cost;
            final isNew = item.id == 'pacifist';

            // Border glow alpha pulsa per gli item posseduti
            final borderAlpha = owned ? 0.35 + pulse * 0.25 : 0.12;
            final fillAlpha = owned ? 0.10 + pulse * 0.04 : 0.03;

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: item.color.withValues(alpha: borderAlpha),
                  width: owned ? 1.5 : 1,
                ),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    item.color.withValues(alpha: fillAlpha),
                    Colors.black.withValues(alpha: 0.4),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.6, 1.0],
                ),
                boxShadow: owned
                    ? [
                        BoxShadow(
                          color: item.color.withValues(alpha: 0.15 + pulse * 0.1),
                          blurRadius: 12,
                          spreadRadius: 1,
                        ),
                      ]
                    : null,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  children: [
                    // Icona dentro cerchio glowing
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: item.color.withValues(alpha: owned ? 0.6 : 0.2),
                          width: 1.2,
                        ),
                        gradient: RadialGradient(
                          colors: [
                            item.color.withValues(alpha: owned ? 0.2 : 0.05),
                            Colors.transparent,
                          ],
                        ),
                      ),
                      child: Icon(
                        item.icon,
                        color: item.color.withValues(alpha: owned ? 1.0 : 0.4),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    // Name + description
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            children: [
                              Text(
                                _modeName(l10n, item.id, item.name).toUpperCase(),
                                style: TextStyle(
                                  color: owned ? item.color : Colors.white70,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'monospace',
                                  letterSpacing: 1.5,
                                  shadows: owned
                                      ? [
                                          Shadow(
                                            color: item.color
                                                .withValues(alpha: 0.6),
                                            blurRadius: 6,
                                          ),
                                        ]
                                      : null,
                                ),
                              ),
                              if (isNew) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 5, vertical: 1),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(3),
                                    color: const Color(0xFFFFD700)
                                        .withValues(alpha: 0.15 + pulse * 0.15),
                                    border: Border.all(
                                      color: const Color(0xFFFFD700)
                                          .withValues(alpha: 0.7),
                                      width: 0.8,
                                    ),
                                  ),
                                  child: Text(
                                    l10n.shopBadgeNew,
                                    style: const TextStyle(
                                      color: Color(0xFFFFD700),
                                      fontSize: 8,
                                      fontFamily: 'monospace',
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Cost / unlocked badge
                    if (owned)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          color: Colors.greenAccent.withValues(alpha: 0.08),
                          border: Border.all(
                            color: Colors.greenAccent.withValues(alpha: 0.4),
                            width: 0.8,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.check_circle_outline,
                                color: Colors.greenAccent, size: 12),
                            const SizedBox(width: 4),
                            Text(
                              l10n.shopBadgeUnlocked,
                              style: const TextStyle(
                                color: Colors.greenAccent,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'monospace',
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      _PurchaseButton(
                        cost: item.cost,
                        canAfford: canAfford,
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
            );
          },
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
    required ScrollController listController,
    required ScrollController previewController,
    bool hideDescription = false,
  }) {
    final l10n = AppLocalizations.of(context)!;
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 500;
        return Row(
          children: [
            // === LISTA ITEMS ===
            SizedBox(
              width: isWide ? 200 : 160,
              child: _cyanScrollbar(
                controller: listController,
                child: ListView.builder(
                controller: listController,
                padding: const EdgeInsets.all(10),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  final owned = unlocked.contains(item.id);
                  final isActive = item.id == activeId;
                  final isSelected = _selectedPreviewIndex == index;

                  return GestureDetector(
                    onTap: () {
                      // Tap sulla riga = seleziona solo la preview.
                      // L'azione (buy/equip) passa dal pulsante dedicato a destra.
                      setState(() => _selectedPreviewIndex = index);
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
                            child: Text(_itemName(l10n, item),
                                style: TextStyle(
                                  color: isActive
                                      ? Colors.greenAccent
                                      : Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'monospace',
                                )),
                          ),
                          const SizedBox(width: 6),
                          _ShopActionButton(
                            state: isActive
                                ? _ShopActionState.equipped
                                : owned
                                    ? _ShopActionState.equip
                                    : _ShopActionState.buy,
                            cost: item.cost,
                            canAfford: _saveData.goldGeoms >= item.cost,
                            onTap: () {
                              if (isActive) return;
                              // FIX: sincronizza la preview con l'item su cui
                              // l'utente ha cliccato EQUIP / BUY dalla sidebar.
                              // Prima: la preview restava sull'item precedente
                              // mentre l'arma equipaggiata cambiava (mismatch).
                              setState(() => _selectedPreviewIndex = index);
                              if (owned) {
                                onSelect(item);
                              } else {
                                onPurchase(item);
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
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

                  return LayoutBuilder(
                    builder: (context, previewConstraints) {
                      // Preview dinamica: nessun bottone equip qui (sidebar lo gestisce).
                      final previewSize = (previewConstraints.maxHeight - 100).clamp(60.0, 220.0);
                      // Preview content non scrolla davvero — niente scrollbar.
                      // SingleChildScrollView mantenuto come safety per overflow
                      // su schermi cortissimi, ma senza barre laterali visibili.
                      return SingleChildScrollView(
                        controller: previewController,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
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
                            // Description card (richiesta utente).
                            _InfoCard(
                              title: _itemName(l10n, item),
                              description: _itemDesc(l10n, item),
                              accentColor: item is _WeaponDef
                                  ? (item).color
                                  : Colors.cyanAccent,
                              stats: item is _WeaponDef
                                  ? (item).stats
                                  : const [],
                              showDescription: !hideDescription,
                            ),
                          ],
                        ),
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

// ==================== SHOP ACTION BUTTON (BUY / EQUIP / EQUIPPED) ====================

enum _ShopActionState { buy, equip, equipped }

class _ShopActionButton extends StatefulWidget {
  final _ShopActionState state;
  final int cost;
  final bool canAfford;
  final VoidCallback onTap;

  const _ShopActionButton({
    required this.state,
    required this.cost,
    required this.canAfford,
    required this.onTap,
  });

  @override
  State<_ShopActionButton> createState() => _ShopActionButtonState();
}

class _ShopActionButtonState extends State<_ShopActionButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // Colori per stato
    final Color borderColor;
    final Color bgColor;
    final Color textColor;
    final String label;
    final IconData? leadingIcon;
    final bool tappable;

    switch (widget.state) {
      case _ShopActionState.buy:
        borderColor = widget.canAfford
            ? const Color(0xFFFFD700).withValues(alpha: 0.6)
            : Colors.white.withValues(alpha: 0.15);
        bgColor = widget.canAfford
            ? const Color(0xFFFFD700).withValues(alpha: _pressed ? 0.18 : 0.06)
            : Colors.transparent;
        textColor = widget.canAfford
            ? const Color(0xFFFFD700)
            : Colors.white24;
        label = '${widget.cost}';
        leadingIcon = Icons.diamond;
        tappable = widget.canAfford;
      case _ShopActionState.equip:
        borderColor = Colors.cyanAccent.withValues(alpha: 0.6);
        bgColor = Colors.cyanAccent.withValues(alpha: _pressed ? 0.18 : 0.06);
        textColor = Colors.cyanAccent;
        label = l10n.shopEquip;
        leadingIcon = null;
        tappable = true;
      case _ShopActionState.equipped:
        borderColor = Colors.greenAccent.withValues(alpha: 0.5);
        bgColor = Colors.greenAccent.withValues(alpha: 0.08);
        textColor = Colors.greenAccent;
        label = l10n.shopEquipped;
        leadingIcon = Icons.check_circle;
        tappable = false;
    }

    return GestureDetector(
      onTapDown: tappable ? (_) => setState(() => _pressed = true) : null,
      onTapUp: tappable
          ? (_) {
              setState(() => _pressed = false);
              widget.onTap();
            }
          : null,
      onTapCancel: tappable ? () => setState(() => _pressed = false) : null,
      child: AnimatedScale(
        scale: _pressed ? 0.93 : 1.0,
        duration: const Duration(milliseconds: 80),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 5,
          ),
          decoration: BoxDecoration(
            border: Border.all(color: borderColor),
            borderRadius: BorderRadius.circular(6),
            color: bgColor,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (leadingIcon != null) ...[
                Icon(leadingIcon, color: textColor, size: 11),
                const SizedBox(width: 3),
              ],
              Text(
                label,
                style: TextStyle(
                  color: textColor,
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==================== PURCHASE BUTTON ====================

class _PurchaseButton extends StatefulWidget {
  final int cost;
  final bool canAfford;
  final Color color;
  final VoidCallback onTap;

  const _PurchaseButton({
    required this.cost, required this.canAfford,
    required this.color, required this.onTap,
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
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 5,
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
              const Icon(Icons.diamond, color: Color(0xFFFFD700),
                  size: 12),
              const SizedBox(width: 4),
              Text(
                '${widget.cost}',
                style: TextStyle(
                  color: widget.canAfford ? const Color(0xFFFFD700) : Colors.white24,
                  fontFamily: 'monospace', fontWeight: FontWeight.bold,
                  fontSize: 12,
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
  /// Stat pills render nella description card sotto la preview.
  /// Formato consigliato: "LABEL: VALUE" (es. "DMG: 1", "RATE: FAST").
  final List<String> stats;
  _WeaponDef(super.id, super.name, super.cost, super.description, this.color,
      this.pattern,
      {this.stats = const []});
}

// ==================== INFO CARD ====================

/// Card con titolo + descrizione + stat pills opzionali.
/// Usata sotto la preview nello shop (richiesta utente).
class _InfoCard extends StatelessWidget {
  final String title;
  final String description;
  final Color accentColor;
  final List<String> stats;
  final bool showDescription;

  const _InfoCard({
    required this.title,
    required this.description,
    required this.accentColor,
    this.stats = const [],
    this.showDescription = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.4),
          width: 1,
        ),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accentColor.withValues(alpha: 0.08),
            Colors.black.withValues(alpha: 0.3),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Titolo (nome arma)
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: accentColor,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 6),
          // Linea separatrice neon
          Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  accentColor.withValues(alpha: 0.5),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          if (showDescription) ...[
            const SizedBox(height: 8),
            // Descrizione
            Text(
              description,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.75),
                fontSize: 10,
                fontFamily: 'monospace',
                height: 1.4,
              ),
            ),
          ],
          if (stats.isNotEmpty) ...[
            const SizedBox(height: 10),
            // Stat pills
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 6,
              runSpacing: 6,
              children: stats
                  .map((s) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          color: accentColor.withValues(alpha: 0.12),
                          border: Border.all(
                            color: accentColor.withValues(alpha: 0.35),
                            width: 0.8,
                          ),
                        ),
                        child: Text(
                          s,
                          style: TextStyle(
                            color: accentColor,
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'monospace',
                            letterSpacing: 0.8,
                          ),
                        ),
                      ))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
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

  const _UpgradeItem(this.id, this.name, this.costs, this.maxLevel,
      this.description, this.icon, this.color);
}

/// Iter 13: nodo skill-tree (mappa 2D upgrades).
/// `x`/`y` normalizzati 0-1 = posizione su grid area.
class _UpgradeNode {
  final double x;
  final double y;
  final _UpgradeItem item;
  const _UpgradeNode({required this.x, required this.y, required this.item});
}

/// Iter 13: painter linee connessione skill-tree. Pulsate con `time`.
class _UpgradeMapPainter extends CustomPainter {
  final List<_UpgradeNode> nodes;
  final List<(String, String)> connections;
  final SaveData saveData;
  final double time;

  _UpgradeMapPainter({
    required this.nodes,
    required this.connections,
    required this.saveData,
    required this.time,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
    // Shorten endpoints by icon radius per non sovrapporre i nodi.
    const double nodeRadius = 26;
    for (final (aId, bId) in connections) {
      final a = nodes.firstWhere((n) => n.item.id == aId,
          orElse: () => nodes.first);
      final b = nodes.firstWhere((n) => n.item.id == bId,
          orElse: () => nodes.first);
      final lvlA = saveData.getUpgradeLevel(aId);
      // Linea attiva quando il prereq (a) ha almeno 1 livello.
      final active = lvlA > 0;
      final color = active
          ? Color.lerp(a.item.color, b.item.color, 0.5)!
          : Colors.white.withValues(alpha: 0.12);
      final pulse = active
          ? (0.6 + 0.4 * (0.5 + 0.5 * math.sin(time + a.x * 5)))
          : 1.0;
      paint.color = active
          ? color.withValues(alpha: 0.8 * pulse)
          : color;
      // Compute endpoint shortened by nodeRadius along direction.
      final ax = a.x * size.width;
      final ay = a.y * size.height;
      final bx = b.x * size.width;
      final by = b.y * size.height;
      final dx = bx - ax;
      final dy = by - ay;
      final len = math.sqrt(dx * dx + dy * dy);
      if (len <= nodeRadius * 2) continue;
      final nx = dx / len;
      final ny = dy / len;
      canvas.drawLine(
        Offset(ax + nx * nodeRadius, ay + ny * nodeRadius),
        Offset(bx - nx * nodeRadius, by - ny * nodeRadius),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_UpgradeMapPainter old) {
    // Iter 13 (caveman): time check copre animation. SaveData mutato
    // in-place → reference compare inutile. setState dopo purchase
    // ricrea painter (new instance) → repaint comunque triggerato.
    return old.time != time;
  }
}

/// Nodo skill-tree con nome + livello sotto. Stato lock = greyed/no-tap.
class _UpgradeMapNode extends StatelessWidget {
  final _UpgradeItem item;
  final int currentLevel;
  final bool unlocked;
  final String upgradeName;
  final AppLocalizations l10n;
  final VoidCallback onTap;

  const _UpgradeMapNode({
    required this.item,
    required this.currentLevel,
    required this.unlocked,
    required this.upgradeName,
    required this.l10n,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isMaxed = currentLevel >= item.maxLevel;
    final activeColor =
        unlocked ? item.color : Colors.white.withValues(alpha: 0.25);
    final glow = !unlocked
        ? 0.15
        : isMaxed
            ? 0.9
            : (0.3 + 0.06 * currentLevel);
    return GestureDetector(
      onTap: unlocked ? onTap : null,
      child: SizedBox(
        width: 72,
        // Icon node 56px + label area ~26px (nome + level).
        height: 96,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Cerchio icona
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: activeColor.withValues(
                    alpha: unlocked ? (0.12 + 0.04 * currentLevel) : 0.05),
                border: Border.all(
                  color: activeColor.withValues(alpha: glow),
                  width: 2,
                ),
                boxShadow: unlocked
                    ? [
                        BoxShadow(
                          color: activeColor.withValues(alpha: glow * 0.5),
                          blurRadius: 10,
                        ),
                      ]
                    : null,
              ),
              alignment: Alignment.center,
              child: Icon(
                unlocked ? item.icon : Icons.lock,
                color: activeColor,
                size: unlocked ? 24 : 18,
              ),
            ),
            const SizedBox(height: 3),
            // Nome upgrade (compatto)
            SizedBox(
              width: 72,
              child: Text(
                upgradeName,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: activeColor.withValues(alpha: unlocked ? 0.95 : 0.4),
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'monospace',
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(height: 1),
            // Livello current/max
            Text(
              '$currentLevel/${item.maxLevel}',
              style: TextStyle(
                color: !unlocked
                    ? Colors.white.withValues(alpha: 0.3)
                    : isMaxed
                        ? Colors.greenAccent
                        : activeColor.withValues(alpha: 0.85),
                fontSize: 10,
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

// ==================== SKIN PREVIEW PAINTER ====================

class _SkinPreviewPainter extends CustomPainter {
  // Cached paint per hex grid — era alloc per frame × N celle.
  static final Paint _hexPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.5;

  // Cached paints per _drawStealthShip (9 allocs/frame).
  static final Paint _stealthGlowPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
  static final Paint _stealthBodyPaint = Paint()
    ..color = const Color(0xFF151520);
  static final Paint _stealthPanelPaint = Paint()
    ..style = PaintingStyle.fill;
  static final Paint _stealthEdgePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.2;
  static final Paint _stealthCircuitPaint = Paint()..strokeWidth = 0.5;
  static final Paint _stealthEyeBlurPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
  static final Paint _stealthEyeCorePaint = Paint();

  // Cached paints per _drawCrystalShip (~7 allocs/frame).
  static final Paint _crystalBodyPaint = Paint();
  static final Paint _crystalFacetPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.8;
  static final Paint _crystalPrism1Paint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
  static final Paint _crystalPrism2Paint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
  static final Paint _crystalBorderPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.5;
  static final Paint _crystalVertPaint = Paint();

  // Cached paints per _drawGhostShip (3 allocs/frame + loop particles).
  static final Paint _ghostAfterPaint = Paint();
  static final Paint _ghostGlowPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);
  static final Paint _ghostBodyPaint = Paint();

  // Cached paints per _drawOmegaShip (7 allocs/frame).
  static final Paint _omegaGlowPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
  static final Paint _omegaBodyPaint = Paint();
  static final Paint _omegaEdgePaint = Paint()
    ..color = Colors.white.withValues(alpha: 0.2)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.8;
  static final Paint _omegaInnerEdgePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.7;
  static final Paint _omegaCenterGlowPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
  static final Paint _omegaCenterCorePaint = Paint()
    ..color = Colors.white.withValues(alpha: 0.8);
  static final Paint _omegaNodePaint = Paint();

  // Cached paints per _drawPreviewThrusters (2 allocs × 2 thruster/frame).
  // Blur radius 3 * s, con s = 2.5 const → 7.5 statico.
  static final Paint _thrusterFlamePaint = Paint()
    ..color = const Color(0xFFFF6600).withValues(alpha: 0.35)
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7.5);
  static final Paint _thrusterCorePaint = Paint()
    ..color = Colors.white.withValues(alpha: 0.6)
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

  // Cached paints per _drawOrbitingParticles (2 allocs × 8 particles/frame).
  static final Paint _orbitingParticlePaint = Paint();
  static final Paint _orbitingLinePaint = Paint()..strokeWidth = 0.5;

  // Iter 4 fix (caveman-review): paint generici riusabili per le 6 nuove skin
  // (phoenix/cyber/voidwalker/aurora/tactical/prism). Prima ognuna allocava
  // 5-14 Paint() per frame → ~70 alloc totale/frame su preview attive. Ora si
  // mutano color/strokeWidth in place. NB: dopo l'uso lo strokeWidth NON
  // viene resettato — chi viene dopo deve risettare prima dell'uso.
  static final Paint _gFill = Paint();
  static final Paint _gStroke = Paint()..style = PaintingStyle.stroke;
  static final Paint _gGlowBlur = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
  static final Paint _gGlowBlurSm = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

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
      case 'phoenix':
        _drawPhoenixShip(canvas, scale, color);
        break;
      case 'cyber':
        _drawCyberShip(canvas, scale, color);
        break;
      case 'voidwalker':
        _drawVoidwalkerShip(canvas, scale, color);
        break;
      case 'aurora':
        _drawAuroraShip(canvas, scale, color);
        break;
      case 'tactical':
        _drawTacticalShip(canvas, scale, color);
        break;
      case 'prism':
        _drawPrismShip(canvas, scale, color);
        break;
      case 'tron':
        _drawTronShip(canvas, scale, color);
        break;
      case 'samurai':
        _drawSamuraiShip(canvas, scale, color);
        break;
      case 'rosegold':
        _drawRoseGoldShip(canvas, scale, color);
        break;
      case 'ninja':
        _drawNinjaShip(canvas, scale, color);
        break;
      case 'glitch':
        _drawGlitchShip(canvas, scale, color);
        break;
      default:
        _drawClassicShip(canvas, scale, color);
    }

    canvas.restore();

    _drawPreviewThrusters(canvas, cx, cy, rotation, scale);
    _drawOrbitingParticles(canvas, cx, cy, time, color);
  }

  void _drawHexGrid(Canvas canvas, Size size) {
    final paint = _hexPaint..color = Colors.white.withValues(alpha: 0.02);
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
          if (i == 0) {
            path.moveTo(hx, hy);
          } else {
            path.lineTo(hx, hy);
          }
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

    final glowPaint = _stealthGlowPaint..color = c.withValues(alpha: 0.2);
    canvas.drawPath(path, glowPaint);

    canvas.drawPath(path, _stealthBodyPaint);

    // Pannelli interni
    final panelPaint = _stealthPanelPaint..color = c.withValues(alpha: 0.08);
    final panelL = Path()
      ..moveTo(-6 * s, -4 * s)..lineTo(0, -10 * s)..lineTo(0, 6 * s)..lineTo(-12 * s, 8 * s)..close();
    canvas.drawPath(panelL, panelPaint);

    final edgePaint = _stealthEdgePaint..color = c;
    canvas.drawPath(path, edgePaint);

    // Linee circuito
    final circuitPaint = _stealthCircuitPaint..color = c.withValues(alpha: 0.2);
    canvas.drawLine(Offset(0, -10 * s), Offset(0, 8 * s), circuitPaint);
    canvas.drawLine(Offset(-6 * s, -4 * s), Offset(6 * s, -4 * s), circuitPaint);

    // Occhio rosso pulsante
    final eyePulse = 0.6 + math.sin(time * 3) * 0.3;
    canvas.drawCircle(Offset(0, -6 * s), 2.5 * s,
        _stealthEyeBlurPaint..color = c.withValues(alpha: eyePulse));
    canvas.drawCircle(Offset(0, -6 * s), 1.5 * s, _stealthEyeCorePaint..color = c);
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

    final bodyPaint = _crystalBodyPaint..color = c.withValues(alpha: 0.25);
    canvas.drawPath(path, bodyPaint);

    // Sfaccettature con riempimento graduale
    final facetPaint = _crystalFacetPaint..color = c.withValues(alpha: 0.4);
    canvas.drawLine(Offset(0, -18 * s), Offset(0, 14 * s), facetPaint);
    canvas.drawLine(Offset(-8 * s, -2 * s), Offset(12 * s, 8 * s), facetPaint);
    canvas.drawLine(Offset(8 * s, -2 * s), Offset(-12 * s, 8 * s), facetPaint);
    // Facets extra
    canvas.drawLine(Offset(0, -18 * s), Offset(12 * s, 8 * s), facetPaint..color = c.withValues(alpha: 0.2));
    canvas.drawLine(Offset(0, -18 * s), Offset(-12 * s, 8 * s), facetPaint);

    // Riflesso prismatico che ruota
    final hue = (time * 50) % 360;
    final prismPaint = _crystalPrism1Paint
      ..color = HSVColor.fromAHSV(0.25, hue, 0.8, 1).toColor();
    canvas.drawCircle(Offset(0, -2 * s), 6 * s, prismPaint);
    // Secondo riflesso sfasato
    final prismPaint2 = _crystalPrism2Paint
      ..color = HSVColor.fromAHSV(0.12, (hue + 120) % 360, 0.8, 1).toColor();
    canvas.drawCircle(Offset(3 * s, -6 * s), 4 * s, prismPaint2);

    // Bordo glow
    final borderPaint = _crystalBorderPaint..color = c.withValues(alpha: 0.6);
    canvas.drawPath(path, borderPaint);

    // Punti luminosi sui vertici
    final verts = [Offset(0, -18 * s), Offset(8 * s, -2 * s), Offset(12 * s, 8 * s),
                   Offset(0, 14 * s), Offset(-12 * s, 8 * s), Offset(-8 * s, -2 * s)];
    for (int i = 0; i < verts.length; i++) {
      final vPulse = 0.3 + math.sin(time * 3 + i * 1.0) * 0.3;
      canvas.drawCircle(verts[i], 1.5,
          _crystalVertPaint..color = Colors.white.withValues(alpha: vPulse));
    }
  }

  void _drawGhostShip(Canvas canvas, double s, Color c) {
    final alpha = 0.3 + math.sin(time * 2) * 0.15;

    // Afterimage (ombra sfasata)
    canvas.save();
    canvas.translate(math.sin(time * 1.5) * 3, math.cos(time * 1.2) * 3);
    _drawShipPath(canvas, s, _ghostAfterPaint..color = c.withValues(alpha: alpha * 0.2));
    canvas.restore();

    final glowPaint = _ghostGlowPaint..color = c.withValues(alpha: alpha * 0.4);
    _drawShipPath(canvas, s, glowPaint);

    final bodyPaint = _ghostBodyPaint..color = c.withValues(alpha: alpha);
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
      if (i == 0) {
        path.moveTo(outerX, outerY);
      } else {
        path.lineTo(outerX, outerY);
      }
      path.lineTo(innerX, innerY);
    }
    path.close();

    final glowPaint = _omegaGlowPaint..color = c.withValues(alpha: 0.3);
    canvas.drawPath(path, glowPaint);

    canvas.drawPath(path, _omegaBodyPaint..color = c);

    // Bordo bianco
    canvas.drawPath(path, _omegaEdgePaint);

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
      if (i == 0) {
        innerPath.moveTo(outerX, outerY);
      } else {
        innerPath.lineTo(outerX, outerY);
      }
      innerPath.lineTo(innerX, innerY);
    }
    innerPath.close();
    canvas.drawPath(innerPath, _omegaInnerEdgePaint..color = c.withValues(alpha: 0.25));
    canvas.restore();

    // Centro orb + glow
    canvas.drawCircle(
        Offset.zero, 6 * s, _omegaCenterGlowPaint..color = c.withValues(alpha: 0.25));
    canvas.drawCircle(Offset.zero, 3.5 * s, _omegaCenterCorePaint);

    // Nodi pulsanti sulle punte
    for (int i = 0; i < 4; i++) {
      final angle = i * math.pi / 2;
      final nx = math.cos(angle) * 15 * s;
      final ny = math.sin(angle) * 15 * s;
      final np = 0.3 + math.sin(time * 4 + i * 1.5) * 0.3;
      canvas.drawCircle(
          Offset(nx, ny), 1.5, _omegaNodePaint..color = c.withValues(alpha: np));
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
      canvas.drawOval(
        Rect.fromCenter(center: Offset(xOff, 13 * s + flameLen * 0.5), width: 5 * s, height: flameLen * s * 0.5),
        _thrusterFlamePaint,
      );
      // Nucleo bianco
      canvas.drawOval(
        Rect.fromCenter(center: Offset(xOff, 13 * s + flameLen * 0.3), width: 2.5 * s, height: flameLen * s * 0.25),
        _thrusterCorePaint,
      );
    }

    canvas.restore();
  }

  void _drawOrbitingParticles(Canvas canvas, double cx, double cy, double t, Color c) {
    final paint = _orbitingParticlePaint;
    final linePaint = _orbitingLinePaint..color = c.withValues(alpha: 0.03);
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
        canvas.drawLine(Offset(x, y), Offset(nx, ny), linePaint);
      }
    }
  }

  void _drawPhoenixShip(Canvas canvas, double s, Color c) {
    // Ali infuocate aperte: corpo centrale + due grandi ali piumate.
    final wingPhase = math.sin(time * 3) * 0.3 + 1.0;
    // Glow esterno fuoco — usa _gGlowBlur cache (blur radius 12, ok per fuoco).
    _gGlowBlur.color = const Color(0xFFFF8800).withValues(alpha: 0.35);
    canvas.drawCircle(Offset.zero, 24 * s * wingPhase, _gGlowBlur);

    // Ali sinistra/destra (forma piuma)
    for (final side in [-1.0, 1.0]) {
      final wing = Path()
        ..moveTo(0, -10 * s)
        ..quadraticBezierTo(
            side * 18 * s * wingPhase, -8 * s, side * 22 * s * wingPhase, 4 * s)
        ..quadraticBezierTo(
            side * 16 * s * wingPhase, 6 * s, side * 8 * s, 8 * s)
        ..lineTo(0, 4 * s)
        ..close();
      _gFill.color = const Color(0xFFFF2200).withValues(alpha: 0.7);
      canvas.drawPath(wing, _gFill);
      _gStroke
        ..color = const Color(0xFFFF8800).withValues(alpha: 0.5)
        ..strokeWidth = 1.5;
      canvas.drawPath(wing, _gStroke);
    }

    // Corpo centrale dorato/rosso
    final body = Path()
      ..moveTo(0, -16 * s)
      ..lineTo(4 * s, -2 * s)
      ..lineTo(3 * s, 10 * s)
      ..lineTo(-3 * s, 10 * s)
      ..lineTo(-4 * s, -2 * s)
      ..close();
    _gFill.color = c;
    canvas.drawPath(body, _gFill);
    _gStroke
      ..color = const Color(0xFFFFDD00).withValues(alpha: 0.8)
      ..strokeWidth = 1.0;
    canvas.drawPath(body, _gStroke);

    // Brace particles attorno
    for (int i = 0; i < 8; i++) {
      final ang = i * math.pi / 4 + time * 0.8;
      final dist = 18 * s + math.sin(time * 2 + i) * 4;
      final ex = math.cos(ang) * dist;
      final ey = math.sin(ang) * dist;
      final emberPulse = (math.sin(time * 4 + i) * 0.3 + 0.7).clamp(0.2, 1.0);
      _gFill.color = const Color(0xFFFFCC44).withValues(alpha: emberPulse);
      canvas.drawCircle(Offset(ex, ey), 1.4, _gFill);
    }
  }

  void _drawCyberShip(Canvas canvas, double s, Color c) {
    // Classic ship con overlay griglia circuiti + scanline.
    _gFill.color = c.withValues(alpha: 0.85);
    _drawShipPath(canvas, s, _gFill);

    // Scanline orizzontale che scorre
    final scanY = ((time * 30) % 32) - 16;
    _gStroke
      ..color = const Color(0xFF00FFAA).withValues(alpha: 0.6)
      ..strokeWidth = 1.0;
    canvas.drawLine(
        Offset(-15 * s, scanY * s), Offset(15 * s, scanY * s), _gStroke);

    // Griglia circuiti interna
    _gStroke
      ..color = const Color(0xFF00FF66).withValues(alpha: 0.4)
      ..strokeWidth = 0.5;
    for (double y = -12 * s; y <= 12 * s; y += 4 * s) {
      canvas.drawLine(Offset(-12 * s, y), Offset(12 * s, y), _gStroke);
    }
    for (double x = -10 * s; x <= 10 * s; x += 4 * s) {
      canvas.drawLine(Offset(x, -12 * s), Offset(x, 12 * s), _gStroke);
    }

    // Bordo neon brillante
    _gStroke
      ..color = const Color(0xFF00FF88)
      ..strokeWidth = 1.4;
    _drawShipPath(canvas, s, _gStroke);

    // Nodi pulsanti agli incroci griglia
    final nodes = [
      Offset(-8 * s, -4 * s),
      Offset(8 * s, -4 * s),
      const Offset(0, 0),
      Offset(-4 * s, 8 * s),
      Offset(4 * s, 8 * s),
    ];
    for (int i = 0; i < nodes.length; i++) {
      final pulse = (math.sin(time * 6 + i * 1.2) * 0.4 + 0.6).clamp(0.2, 1.0);
      _gFill.color = const Color(0xFF00FFAA).withValues(alpha: pulse);
      canvas.drawCircle(nodes[i], 2.0, _gFill);
    }
  }

  void _drawVoidwalkerShip(Canvas canvas, double s, Color c) {
    // Corpo nero traslucido + nucleo viola pulsante + alone etereo.
    final corePulse = math.sin(time * 2) * 0.2 + 1.0;

    // Alone esterno viola — uso _gGlowBlur (blur 12, vicino al desiderato 18).
    _gGlowBlur.color = c.withValues(alpha: 0.25 * corePulse);
    canvas.drawCircle(Offset.zero, 20 * s, _gGlowBlur);

    // Corpo nave nero quasi opaco
    _gFill.color = const Color(0xFF0A0014);
    _drawShipPath(canvas, s, _gFill);

    // Bordo viola luminoso
    _gStroke
      ..color = c
      ..strokeWidth = 1.3;
    _drawShipPath(canvas, s, _gStroke);

    // Nucleo centrale viola — uso _gGlowBlurSm (blur 4 = perfetto).
    _gGlowBlurSm.color = c.withValues(alpha: 0.8);
    canvas.drawCircle(Offset(0, 2 * s), 4 * s * corePulse, _gGlowBlurSm);
    _gFill.color = const Color(0xE6FFFFFF);
    canvas.drawCircle(Offset(0, 2 * s), 2 * s, _gFill);

    // Particelle ombra che orbitano
    _gFill.color = c.withValues(alpha: 0.4);
    for (int i = 0; i < 6; i++) {
      final ang = -time * 1.5 + i * math.pi / 3;
      final dist = 14 * s + math.sin(time + i) * 2;
      final px = math.cos(ang) * dist;
      final py = math.sin(ang) * dist;
      canvas.drawCircle(Offset(px, py), 1.5, _gFill);
    }
  }

  // Cached aurora paint con shader (shader RIcreato per frame perché dipende
  // da time/colors, ma il Paint object è riusato).
  static final Paint _auroraBodyPaint = Paint();

  void _drawAuroraShip(Canvas canvas, double s, Color _) {
    // Body shape classic, colore boreale che fluisce ciano→rosa→verde.
    final h1 = (time * 40) % 360;
    final h2 = (h1 + 80) % 360;
    final h3 = (h1 + 160) % 360;
    final color1 = HSVColor.fromAHSV(1, h1, 0.7, 1).toColor();
    final color2 = HSVColor.fromAHSV(1, h2, 0.7, 1).toColor();
    final color3 = HSVColor.fromAHSV(1, h3, 0.7, 1).toColor();

    // Glow esterno multi-strato — uso _gGlowBlur (blur 12, ok per 14 e 10).
    _gGlowBlur.color = color1.withValues(alpha: 0.18);
    canvas.drawCircle(Offset.zero, 22 * s, _gGlowBlur);
    _gGlowBlur.color = color2.withValues(alpha: 0.18);
    canvas.drawCircle(Offset.zero, 18 * s, _gGlowBlur);

    // Corpo: gradient verticale aurora — shader necessariamente per-frame
    // (dipende da time-shifted hue), ma riusiamo Paint object cached.
    final rect = Rect.fromCenter(
        center: Offset.zero, width: 30 * s, height: 30 * s);
    final shader = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [color1, color2, color3],
    ).createShader(rect);
    _auroraBodyPaint.shader = shader;
    _drawShipPath(canvas, s, _auroraBodyPaint);
    // Reset shader dopo l'uso (i paint generici non hanno shader).
    _auroraBodyPaint.shader = null;

    // Bordo bianco luminoso
    _gStroke
      ..color = Colors.white.withValues(alpha: 0.6)
      ..strokeWidth = 1.0;
    _drawShipPath(canvas, s, _gStroke);

    // Cockpit
    _gFill.color = Colors.white.withValues(alpha: 0.9);
    canvas.drawCircle(Offset(0, -4 * s), 2.5 * s, _gFill);

    // Veli lucenti laterali (effetto aurora)
    _gStroke.strokeWidth = 0.8;
    for (int i = 0; i < 3; i++) {
      final yOff = -8 * s + i * 6 * s;
      _gStroke.color =
          HSVColor.fromAHSV(0.3, (h1 + i * 40) % 360, 0.8, 1).toColor();
      canvas.drawLine(
          Offset(-12 * s, yOff), Offset(12 * s, yOff), _gStroke);
    }
  }

  void _drawTacticalShip(Canvas canvas, double s, Color c) {
    // Classic shape con placche corazzate + chevron militari.
    _gFill.color = const Color(0xFF334455);
    _drawShipPath(canvas, s, _gFill);

    // Strisce blu chevron sulle ali
    _gStroke
      ..color = c
      ..strokeWidth = 1.5;
    canvas.drawLine(Offset(-9 * s, 4 * s), Offset(-5 * s, -2 * s), _gStroke);
    canvas.drawLine(Offset(-9 * s, 7 * s), Offset(-5 * s, 1 * s), _gStroke);
    canvas.drawLine(Offset(9 * s, 4 * s), Offset(5 * s, -2 * s), _gStroke);
    canvas.drawLine(Offset(9 * s, 7 * s), Offset(5 * s, 1 * s), _gStroke);

    // Placca centrale con bordo
    final platePath = Path()
      ..moveTo(-3 * s, -8 * s)
      ..lineTo(3 * s, -8 * s)
      ..lineTo(2 * s, 6 * s)
      ..lineTo(-2 * s, 6 * s)
      ..close();
    _gFill.color = const Color(0xFF223344);
    canvas.drawPath(platePath, _gFill);
    _gStroke
      ..color = c
      ..strokeWidth = 1.0;
    canvas.drawPath(platePath, _gStroke);

    // Bordo esterno blu acciaio
    _gStroke
      ..color = c.withValues(alpha: 0.9)
      ..strokeWidth = 1.5;
    _drawShipPath(canvas, s, _gStroke);

    // Hatch warning (rosso lampeggiante)
    final warnPulse = (math.sin(time * 5) > 0) ? 0.9 : 0.2;
    _gFill.color = const Color(0xFFFF3344).withValues(alpha: warnPulse);
    canvas.drawCircle(Offset(0, -4 * s), 1.6, _gFill);

    // Rivetti angolari
    _gFill.color = Colors.white.withValues(alpha: 0.4);
    for (final p in [
      Offset(-10 * s, 9 * s),
      Offset(10 * s, 9 * s),
      Offset(-3 * s, -10 * s),
      Offset(3 * s, -10 * s)
    ]) {
      canvas.drawCircle(p, 0.8, _gFill);
    }
  }

  // Cached prism paint con shader sweep (shader rebuilt per frame).
  static final Paint _prismFacetPaint = Paint()..style = PaintingStyle.fill;

  void _drawPrismShip(Canvas canvas, double s, Color _) {
    // Cristallo poligonale 8 facce con rifrazione multi-color.
    final hue = (time * 60) % 360;
    final c1 = HSVColor.fromAHSV(1, hue, 1, 1).toColor();
    final c2 = HSVColor.fromAHSV(1, (hue + 120) % 360, 1, 1).toColor();
    final c3 = HSVColor.fromAHSV(1, (hue + 240) % 360, 1, 1).toColor();

    // Forma 8-faced gem
    final path = Path();
    for (int i = 0; i < 8; i++) {
      final ang = i * math.pi / 4 - math.pi / 2;
      final r = (i % 2 == 0 ? 16.0 : 10.0) * s;
      final x = math.cos(ang) * r;
      final y = math.sin(ang) * r;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();

    // Glow rifrazione triplo — uso _gGlowBlur (12 vs desiderato 14, ok).
    _gGlowBlur.color = c1.withValues(alpha: 0.3);
    canvas.drawPath(path, _gGlowBlur);

    // Corpo bianco translucido
    _gFill.color = Colors.white.withValues(alpha: 0.4);
    canvas.drawPath(path, _gFill);

    // Faccette interne con shader gradient (sweep necessariamente per-frame).
    final rect = path.getBounds();
    _prismFacetPaint
      ..shader = SweepGradient(
        center: Alignment.center,
        colors: [c1, c2, c3, c1],
        stops: const [0, 0.33, 0.66, 1],
      ).createShader(rect)
      ..color = Colors.white.withValues(alpha: 0.5);
    canvas.drawPath(path, _prismFacetPaint);
    _prismFacetPaint.shader = null;

    // Linee facette dal centro
    _gStroke
      ..color = Colors.white.withValues(alpha: 0.7)
      ..strokeWidth = 0.8;
    for (int i = 0; i < 8; i++) {
      final ang = i * math.pi / 4 - math.pi / 2;
      final r = (i % 2 == 0 ? 16.0 : 10.0) * s;
      canvas.drawLine(
          Offset.zero, Offset(math.cos(ang) * r, math.sin(ang) * r), _gStroke);
    }

    // Bordo bianco brillante
    _gStroke
      ..color = Colors.white.withValues(alpha: 0.95)
      ..strokeWidth = 1.2;
    canvas.drawPath(path, _gStroke);

    // Centro sparkle pulsante
    final sparklePulse = math.sin(time * 4) * 0.3 + 0.7;
    _gFill.color = Colors.white;
    canvas.drawCircle(Offset.zero, 3 * s * sparklePulse, _gFill);
  }

  // ─── NEW SKINS (iter 7) ──────────────────────────────────────────────

  void _drawTronShip(Canvas canvas, double s, Color c) {
    // Body nero con linee neon ciano (circuit grid).
    _gFill.color = const Color(0xFF000A14);
    _drawShipPath(canvas, s, _gFill);
    // Linee circuit luminose ciano sui bordi
    _gStroke
      ..color = c
      ..strokeWidth = 1.4;
    _drawShipPath(canvas, s, _gStroke);
    // Griglia circuit interna orizzontale
    _gStroke
      ..color = c.withValues(alpha: 0.5)
      ..strokeWidth = 0.6;
    for (double y = -10 * s; y <= 10 * s; y += 4 * s) {
      canvas.drawLine(Offset(-9 * s, y), Offset(9 * s, y), _gStroke);
    }
    // Glow scanline scorrevole
    final scanY = ((time * 25) % 28) - 14;
    _gStroke
      ..color = c.withValues(alpha: 0.85)
      ..strokeWidth = 1.0;
    canvas.drawLine(
        Offset(-12 * s, scanY * s), Offset(12 * s, scanY * s), _gStroke);
    // Cockpit nodo brillante
    _gFill.color = c;
    canvas.drawCircle(Offset(0, -4 * s), 1.6 * s, _gFill);
  }

  void _drawSamuraiShip(Canvas canvas, double s, Color c) {
    // Body nero opaco
    _gFill.color = const Color(0xFF1A0A05);
    _drawShipPath(canvas, s, _gFill);
    // Bordo oro
    _gStroke
      ..color = c
      ..strokeWidth = 1.6;
    _drawShipPath(canvas, s, _gStroke);
    // Strisce diagonali rosse (battle stripes)
    _gStroke
      ..color = const Color(0xFFFF2244)
      ..strokeWidth = 1.2;
    canvas.drawLine(Offset(-6 * s, -4 * s), Offset(6 * s, 4 * s), _gStroke);
    canvas.drawLine(Offset(-6 * s, 4 * s), Offset(6 * s, -4 * s), _gStroke);
    // Cockpit oro
    _gFill.color = c;
    canvas.drawCircle(Offset(0, -3 * s), 2 * s, _gFill);
    // Sparkle accenti sulle ali
    final pulse = math.sin(time * 3) * 0.3 + 0.7;
    _gFill.color = const Color(0xFFFFDD00).withValues(alpha: pulse);
    canvas.drawCircle(Offset(-10 * s, 8 * s), 1.4, _gFill);
    canvas.drawCircle(Offset(10 * s, 8 * s), 1.4, _gFill);
  }

  void _drawRoseGoldShip(Canvas canvas, double s, Color c) {
    // Gradiente metallico pink → gold
    _gGlowBlur.color = c.withValues(alpha: 0.4);
    canvas.drawCircle(Offset.zero, 18 * s, _gGlowBlur);
    _gFill.color = c;
    _drawShipPath(canvas, s, _gFill);
    // Highlight metallico oro chiaro top
    _gFill.color = const Color(0xFFFFE099).withValues(alpha: 0.6);
    final highlight = Path()
      ..moveTo(0, -12 * s)
      ..lineTo(3 * s, -4 * s)
      ..lineTo(-3 * s, -4 * s)
      ..close();
    canvas.drawPath(highlight, _gFill);
    // Bordo sottile rosa scuro
    _gStroke
      ..color = const Color(0xFFCC6688)
      ..strokeWidth = 0.8;
    _drawShipPath(canvas, s, _gStroke);
    // Cockpit gem brillante
    _gFill.color = const Color(0xFFFFFFFF);
    canvas.drawCircle(Offset(0, -3 * s), 1.8 * s, _gFill);
  }

  void _drawNinjaShip(Canvas canvas, double s, Color c) {
    // Body grigio-blu scurissimo
    _gFill.color = const Color(0xFF1A1F2A);
    _drawShipPath(canvas, s, _gFill);
    // Bordo sottile grigio-blu
    _gStroke
      ..color = c
      ..strokeWidth = 0.8;
    _drawShipPath(canvas, s, _gStroke);
    // Shuriken accent rotante al centro
    final shurikenAng = time * 2;
    canvas.save();
    canvas.translate(0, 2 * s);
    canvas.rotate(shurikenAng);
    final shuriken = Path();
    for (int i = 0; i < 4; i++) {
      final a = i * math.pi / 2;
      shuriken
        ..moveTo(0, 0)
        ..lineTo(math.cos(a) * 4 * s, math.sin(a) * 4 * s)
        ..lineTo(math.cos(a + 0.4) * 1.5 * s,
            math.sin(a + 0.4) * 1.5 * s);
    }
    _gStroke
      ..color = c.withValues(alpha: 0.85)
      ..strokeWidth = 0.9;
    canvas.drawPath(shuriken, _gStroke);
    canvas.restore();
    // Cockpit minuscolo
    _gFill.color = c.withValues(alpha: 0.7);
    canvas.drawCircle(Offset(0, -4 * s), 1.2 * s, _gFill);
  }

  void _drawGlitchShip(Canvas canvas, double s, Color c) {
    // RGB chromatic aberration: 3 copie body offset.
    final glitchPhase = (time * 8) % 1.0;
    final shift = (glitchPhase < 0.1) ? 3.0 : 1.5;
    // R offset left
    canvas.save();
    canvas.translate(-shift * s, 0);
    _gFill.color = const Color(0xFFFF0066).withValues(alpha: 0.7);
    _drawShipPath(canvas, s, _gFill);
    canvas.restore();
    // G offset right
    canvas.save();
    canvas.translate(shift * s, 0);
    _gFill.color = const Color(0xFF00FF66).withValues(alpha: 0.7);
    _drawShipPath(canvas, s, _gFill);
    canvas.restore();
    // B body central
    _gFill.color = const Color(0xFF0066FF).withValues(alpha: 0.85);
    _drawShipPath(canvas, s, _gFill);
    // Bordo bianco
    _gStroke
      ..color = Colors.white.withValues(alpha: 0.9)
      ..strokeWidth = 0.7;
    _drawShipPath(canvas, s, _gStroke);
    // Glitch scanline orizzontale random
    if (glitchPhase < 0.15) {
      final glitchY = (time * 40) % 26 - 13;
      _gFill.color = Colors.white.withValues(alpha: 0.6);
      canvas.drawRect(
          Rect.fromLTWH(-12 * s, glitchY * s, 24 * s, 1.5), _gFill);
    }
  }

  @override
  bool shouldRepaint(covariant _SkinPreviewPainter old) => old.time != time;
}

// ==================== TRAIL PREVIEW PAINTER ====================

class _TrailPreviewPainter extends CustomPainter {
  // Cached paints: trail loop ×25 + ice crystal + nave finale.
  static final Paint _trailBodyPaint = Paint();
  static final Paint _shipBodyPaint = Paint()..color = NeonColors.cyan;
  static final Paint _shipGlowPaint = Paint()
    ..color = NeonColors.cyan.withValues(alpha: 0.25)
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
  static final Paint _iceCrystalPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.8;

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
        case 'comet':
          // Testa luminosa bianca, coda che si raffredda da bianco→arancio→nero.
          if (progress > 0.85) {
            trailColor = Colors.white;
            trailSize = progress * 6;
          } else {
            trailColor = Color.lerp(const Color(0xFF441100),
                const Color(0xFFFFCC66), progress)!;
            trailSize = progress * 4;
          }
          trailAlpha = progress * 0.7;
          break;
        case 'inferno':
          // 3 layer di fuoco: rosso scuro, arancio, giallo brillante al centro.
          final layer = i % 3;
          final layerHue = layer == 0 ? 0.0 : (layer == 1 ? 25.0 : 50.0);
          trailColor = HSVColor.fromAHSV(1, layerHue, 1, 1).toColor();
          trailAlpha = progress * 0.55;
          trailSize = progress * (3 + layer * 0.8) +
              math.sin(time * 10 + i * 0.7) * 1.2;
          // Brace che schizza orizzontalmente
          if (i % 4 == 0 && progress > 0.3) {
            final emberX = tx + math.sin(time * 5 + i) * 8;
            final emberY = ty + math.cos(time * 4 + i) * 6;
            _trailBodyPaint.color =
                const Color(0xFFFFAA00).withValues(alpha: progress * 0.4);
            canvas.drawCircle(Offset(emberX, emberY), 1.2, _trailBodyPaint);
          }
          break;
        case 'void':
          // Particelle scure che si attorcigliano + sparkle viola brillante.
          final swirl = math.sin(time * 3 + i * 0.4) * 6;
          trailColor = i % 5 == 0
              ? const Color(0xFFEE88FF)
              : const Color(0xFF330055);
          trailAlpha = progress * 0.6;
          trailSize = progress * 3.5;
          // Glow viola attorno
          _trailBodyPaint.color =
              const Color(0xFF8800FF).withValues(alpha: progress * 0.15);
          canvas.drawCircle(
              Offset(tx + swirl, ty), trailSize * 3, _trailBodyPaint);
          break;
        case 'quantum':
          // Coppie di particelle in superposizione: alternano cyan/magenta.
          final pair = (i ~/ 2) % 2;
          trailColor = pair == 0
              ? const Color(0xFF00FFCC)
              : const Color(0xFFFF00CC);
          trailAlpha = progress * 0.5;
          trailSize = progress * 3;
          // Particella entangled offset
          final entangleOffset = (i % 2 == 0) ? 4.0 : -4.0;
          _trailBodyPaint.color = (pair == 0
                  ? const Color(0xFFFF00CC)
                  : const Color(0xFF00FFCC))
              .withValues(alpha: trailAlpha * 0.7);
          canvas.drawCircle(Offset(tx + entangleOffset, ty + entangleOffset),
              trailSize * 0.7, _trailBodyPaint);
          break;
        case 'galaxy':
          // Stelle che pulsano + polvere cosmica viola/rosa.
          final twinkle =
              (math.sin(time * 5 + i * 0.9) * 0.5 + 0.5).clamp(0.2, 1.0);
          final hue = ((240 + i * 6) % 360).toDouble();
          trailColor = HSVColor.fromAHSV(1, hue, 0.6, 1).toColor();
          trailAlpha = progress * 0.55 * twinkle;
          trailSize = progress * 3.5 * twinkle + 0.5;
          // Polvere cosmica diffusa
          if (i % 2 == 0) {
            _trailBodyPaint.color =
                const Color(0xFFCC88FF).withValues(alpha: progress * 0.1);
            canvas.drawCircle(
                Offset(tx, ty), trailSize * 4, _trailBodyPaint);
          }
          break;
        case 'lightning':
          // Zigzag elettrico: punti shiftati alternativamente + arco tra punti.
          final zigzag = (i % 2 == 0 ? 1 : -1) * 3.0;
          trailColor = const Color(0xFFFFFF88);
          trailAlpha = progress * 0.7;
          trailSize = progress * 2.5;
          // Arco tra punti consecutivi
          if (i > 0 && i < trailCount) {
            final prevTT = pathT - (i - 1) * 0.04;
            final prevX = cx + math.cos(prevTT) * 50;
            final prevY = cy + math.sin(prevTT * 2) * 30 -
                ((i - 1) % 2 == 0 ? 1 : -1) * 3;
            _trailBodyPaint
              ..color = const Color(0xFFFFFFAA)
                  .withValues(alpha: progress * 0.5)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.2;
            canvas.drawLine(
                Offset(prevX, prevY), Offset(tx + zigzag, ty), _trailBodyPaint);
            _trailBodyPaint.style = PaintingStyle.fill;
          }
          break;
        case 'nebula':
          // Nuvola cyan/magenta — pulse sinusoidale.
          final tn = (math.sin(time * 1.5 + i * 0.4) * 0.5 + 0.5);
          trailColor = Color.lerp(
              const Color(0xFF00DDFF), const Color(0xFFFF44CC), tn)!;
          trailAlpha = progress * 0.65;
          trailSize = progress * 4 + 1;
          // Soft glow attorno
          _trailBodyPaint.color =
              trailColor.withValues(alpha: progress * 0.15);
          canvas.drawCircle(Offset(tx, ty), trailSize * 2.5, _trailBodyPaint);
          break;
        case 'prism':
          // Spettro completo scrolling lungo la scia.
          final phue = ((time * 30) + i * 18) % 360;
          trailColor = HSVColor.fromAHSV(1, phue.toDouble(), 0.95, 1).toColor();
          trailAlpha = progress * 0.7;
          trailSize = progress * 3.5;
          break;
        case 'hologram':
          // Chromatic aberration RGB.
          final ch = i % 3;
          trailColor = ch == 0
              ? const Color(0xFFFF2244)
              : (ch == 1
                  ? const Color(0xFF22FFAA)
                  : const Color(0xFF2244FF));
          trailAlpha = progress * 0.6;
          trailSize = progress * 3;
          // Scanline glitch occasionale
          if (i % 4 == 0 && progress > 0.3) {
            _trailBodyPaint.color =
                Colors.white.withValues(alpha: progress * 0.3);
            canvas.drawLine(
                Offset(tx - 8, ty), Offset(tx + 8, ty), _trailBodyPaint);
          }
          break;
        case 'biolume':
          // Bioluminescenza pulse verde/ciano.
          final bpulse =
              (math.sin(time * 3 + i * 0.6) * 0.4 + 0.6).clamp(0.4, 1.0);
          trailColor = HSVColor.fromAHSV(bpulse, 160 + (i % 3) * 10.0, 0.9, 1)
              .toColor();
          trailAlpha = progress * 0.6;
          trailSize = progress * 3.5;
          break;
        case 'neonpulse':
          // Anelli neon expanding bianco/ciano.
          final tp = (math.sin(time * 5 + i * 0.5) * 0.5 + 0.5);
          trailColor = Color.lerp(
              const Color(0xFF00FFFF), const Color(0xFFFFFFFF), tp)!;
          trailAlpha = progress * 0.7;
          trailSize = progress * 3.5;
          // Anello esterno pulsante
          if (i % 2 == 0 && progress > 0.2) {
            _trailBodyPaint
              ..color = trailColor.withValues(alpha: progress * 0.25)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.2;
            canvas.drawCircle(
                Offset(tx, ty), trailSize * 2.2 + tp * 3, _trailBodyPaint);
            _trailBodyPaint.style = PaintingStyle.fill;
          }
          break;
        default: // normal
          trailColor = NeonColors.cyan;
          trailAlpha = progress * 0.35;
          trailSize = progress * 3;
      }

      // Iter 5 (utente "trails quasi invisibili"): bump 1.3 → 2.0 per
      // match con in-game `player._trailSizeMultiplier`. Applicato
      // globalmente al final size così tutti i case scalano coerenti.
      trailSize *= 2.0;
      // Alpha clamp upper 0.6 → 0.85 → match player render.
      if (trailSize > 0.5) {
        final paint = _trailBodyPaint
          ..color = trailColor.withValues(alpha: trailAlpha.clamp(0.01, 0.85));
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
    canvas.drawPath(path, _shipBodyPaint);

    // Glow
    canvas.drawPath(path, _shipGlowPaint);

    canvas.restore();
  }

  void _drawIceCrystal(Canvas canvas, double x, double y, double r, double alpha) {
    final paint = _iceCrystalPaint..color = color.withValues(alpha: alpha * 0.6);
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
  // Cached paints per homing missile (8 allocs/missile × 5 missiles/frame).
  static final Paint _homingTrailPaint = Paint();
  static final Paint _homingFlameOuterPaint = Paint();
  static final Paint _homingFlameMidPaint = Paint();
  static final Paint _homingFlameCorePaint = Paint();
  static final Paint _homingFinPaint = Paint();
  static final Paint _homingBodyPaint = Paint();
  static final Paint _homingNosePaint = Paint();
  static final Paint _homingImpactPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
  // Cached paints per plasma bolt (8 allocs/bolt × 4 bolts/frame).
  static final Paint _plasmaArcPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.6;
  static final Paint _plasmaGlowOuterPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
  static final Paint _plasmaGlowMidPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
  static final Paint _plasmaBodyGlowPaint = Paint();
  static final Paint _plasmaBodyPaint = Paint();
  static final Paint _plasmaCorePaint = Paint();

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
    canvas.drawCircle(const Offset(0, -5 * s), 2 * s, Paint()..color = Colors.white.withValues(alpha: 0.7));
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
      // Iter 13: nuovi preview pattern.
      case 'gauss': _drawGaussBolt(canvas, cx, shipY, fireRate); break;
      case 'chain': _drawChainLightning(canvas, cx, shipY, size); break;
    }
  }

  /// Iter 13: Gauss bolt preview — bullet viola lento + anelli pull.
  void _drawGaussBolt(Canvas canvas, double cx, double shipY, double fireRate) {
    final phase = (time % fireRate) / fireRate;
    final y = shipY - 12 - phase * 95;
    final bAlpha = (1 - phase).clamp(0.2, 1.0);
    // Pull ring effect attorno ship (aspirazione visual).
    final ringR = 20 + phase * 25;
    canvas.drawCircle(Offset(cx, shipY - 5), ringR, Paint()
      ..color = Color.fromRGBO(204, 102, 255, (1 - phase) * 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
    // Bullet viola big.
    canvas.drawCircle(Offset(cx, y), 7, Paint()
      ..color = Color.fromRGBO(204, 102, 255, 0.5 * bAlpha)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));
    canvas.drawCircle(Offset(cx, y), 5, Paint()
      ..color = Color.fromRGBO(204, 102, 255, bAlpha));
    canvas.drawCircle(Offset(cx, y), 2, Paint()
      ..color = Color.fromRGBO(255, 255, 255, bAlpha));
  }

  /// Iter 13: Chain Lightning preview — arco zigzag verso 3 bersagli.
  void _drawChainLightning(Canvas canvas, double cx, double shipY, Size size) {
    final rng = math.Random(time.floor() ~/ 2);
    final phase = (time * 3) % 1.0;
    final alpha = (1 - phase).clamp(0.1, 1.0);
    final pts = <Offset>[Offset(cx, shipY - 10)];
    for (int i = 0; i < 3; i++) {
      final x = cx + (i - 1) * 32.0 + (rng.nextDouble() - 0.5) * 12;
      final y = 30 + rng.nextDouble() * 20;
      pts.add(Offset(x, y));
    }
    final glowPaint = Paint()
      ..color = Color.fromRGBO(255, 255, 68, 0.6 * alpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
    final bodyPaint = Paint()
      ..color = Color.fromRGBO(255, 255, 100, alpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    for (int i = 0; i < pts.length - 1; i++) {
      final path = Path()..moveTo(pts[i].dx, pts[i].dy);
      final steps = 4;
      for (int s = 1; s < steps; s++) {
        final t = s / steps;
        final mx = pts[i].dx + (pts[i + 1].dx - pts[i].dx) * t;
        final my = pts[i].dy + (pts[i + 1].dy - pts[i].dy) * t;
        path.lineTo(mx + (rng.nextDouble() - 0.5) * 8,
            my + (rng.nextDouble() - 0.5) * 6);
      }
      path.lineTo(pts[i + 1].dx, pts[i + 1].dy);
      canvas.drawPath(path, glowPaint);
      canvas.drawPath(path, bodyPaint);
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
      case 'gauss': return 0.7;
      case 'chain': return 0.55;
      default: return 0.18;
    }
  }

  /// Mirror del render PlayerBullet in-game (projectiles.dart L150-175):
  /// glow r=4 + body r=3 + core bianco r=1.2. Senza questo helper i bullet
  /// nel preview shop apparivano simpler (solo glow+body senza nucleo) →
  /// utente: "armi nello shop devono vedersi uguali a come sono in game".
  ///
  /// Static Paint cache (caveman-fix perf): prima creavamo 3 Paint() per call,
  /// con 12-15 bullet × 6+ weapon previews × 60fps = ~12k alloc/sec sprecate.
  static final Paint _ingameBulletGlow = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
  static final Paint _ingameBulletBody = Paint();
  static final Paint _ingameBulletCore = Paint();

  void _drawInGameBullet(Canvas canvas, double x, double y, double alpha) {
    _ingameBulletGlow.color = color.withValues(alpha: alpha * 0.35);
    canvas.drawCircle(Offset(x, y), 4, _ingameBulletGlow);
    _ingameBulletBody.color = color.withValues(alpha: alpha);
    canvas.drawCircle(Offset(x, y), 3, _ingameBulletBody);
    _ingameBulletCore.color =
        const Color(0xFFFFFFFF).withValues(alpha: alpha * 0.7);
    canvas.drawCircle(Offset(x, y), 1.2, _ingameBulletCore);
  }

  void _drawParallelBullets(Canvas canvas, double cx, double shipY, double rate, double speed) {
    for (int i = 0; i < 12; i++) {
      final spawnTime = (time / rate + i * 0.5) % 8;
      final y = shipY - 22 - spawnTime * speed * 0.3;
      if (y < 10 || y > shipY - 10) continue;
      final alpha = ((shipY - 22 - y) / (shipY - 32)).clamp(0.0, 1.0);
      for (final xOff in [-6.0, 6.0]) {
        _drawInGameBullet(canvas, cx + xOff, y, alpha);
      }
    }
  }

  void _drawTripleBullets(Canvas canvas, double cx, double shipY, double rate, double speed) {
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
        _drawInGameBullet(canvas, bx, by, alpha);
      }
    }
  }

  void _drawFanBullets(Canvas canvas, double cx, double shipY, double rate, double speed) {
    // Spread in-game: 5 bullets, angoli [-0.12, -0.06, 0, +0.06, +0.12] (player.dart).
    final angles = [-0.12, -0.06, 0.0, 0.06, 0.12];
    for (int wave = 0; wave < 5; wave++) {
      final waveTime = (time / rate + wave * 1.2) % 8;
      if (waveTime > 3) continue;

      for (final angle in angles) {
        final dist = waveTime * speed * 0.4;
        final bx = cx + math.sin(angle) * dist;
        final by = shipY - 22 - math.cos(angle) * dist;
        if (by < 5 || by > shipY - 10) continue;
        final alpha = (1.0 - waveTime / 3).clamp(0.0, 1.0);
        _drawInGameBullet(canvas, bx, by, alpha);
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

    // Ricochet: ventaglio di 3 proiettili che rimbalzano (match in-game).
    // Angoli -0.20 / 0 / +0.20 rad come nel player (vedi _fireWeapon).
    const fanAngles = [-0.20, 0.0, 0.20];
    for (int b = 0; b < fanAngles.length; b++) {
      final phase = time * 0.8 + b * 1.6;
      final points = <Offset>[];
      var x = cx;
      var y = shipY - 22.0;
      // Vettore iniziale: verso l'alto ruotato per l'angolo del fan.
      final baseSpeed = 90.0;
      var dx = math.sin(fanAngles[b]) * baseSpeed;
      var dy = -math.cos(fanAngles[b]) * baseSpeed;

      for (int step = 0; step < 100; step++) {
        points.add(Offset(x, y));
        x += dx * 0.02;
        y += dy * 0.02;
        if (x < 15 || x > size.width - 15) { dx = -dx; x = x.clamp(15, size.width - 15); }
        if (y < 15 || y > shipY - 15) { dy = -dy; y = y.clamp(15, shipY - 15); }
      }

      final idx = ((phase * 30) % points.length).toInt();

      // Trail sfumato come in-game PlayerBullet._trail (8 punti, alpha*0.3).
      for (int i = idx; i > idx - 8 && i > 0; i--) {
        final alphaT = (1.0 - (idx - i) / 8) * 0.3;
        trailPaint.style = PaintingStyle.fill;
        trailPaint.color = color.withValues(alpha: alphaT);
        canvas.drawCircle(points[i], 1.5, trailPaint);
      }

      // Flash sui punti di rimbalzo
      if (idx > 2 && idx < points.length - 1) {
        final curr = points[idx];
        if ((curr.dx < 18 || curr.dx > size.width - 18) ||
            (curr.dy < 18 || curr.dy > shipY - 18)) {
          canvas.drawCircle(
              curr,
              5,
              Paint()
                ..color = color.withValues(alpha: 0.3)
                ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
        }
      }

      // Bullet match in-game PlayerBullet.render: glow r=4 alpha 0.35 +
      // body r=3 + core bianco r=1.2.
      if (idx < points.length) {
        glowPaint.color = color.withValues(alpha: 0.35);
        canvas.drawCircle(points[idx], 4, glowPaint);
        bulletPaint.color = color;
        canvas.drawCircle(points[idx], 3, bulletPaint);
        canvas.drawCircle(
            points[idx],
            1.2,
            Paint()..color = const Color(0xFFFFFFFF).withValues(alpha: 0.7));
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

    // 5 missili — match in-game (homingCount = 5 in player.dart).
    const homingCount = 5;
    for (int i = 0; i < homingCount; i++) {
      final phase = (time * 1.2 + i * 0.5) % 3;
      if (phase > 2.5) continue;

      final t = (phase / 2.5).clamp(0.0, 1.0);
      final offI = i - (homingCount - 1) / 2; // centrato: -2, -1, 0, +1, +2
      final startX = cx + offI * 6.0;
      final startY = shipY - 22;
      final midX = startX + (targetX - startX) * 0.3 + offI * 18;
      final midY = startY + (targetY - startY) * 0.3 - 35;
      final bx = _bezier(startX, midX, targetX, t);
      final by = _bezier(startY, midY, targetY, t);
      final alpha = (1.0 - t * 0.4).clamp(0.0, 1.0);

      // Trail di fumo bianco+pink (scia post-flame)
      for (int j = 1; j <= 8; j++) {
        final tt = (t - j * 0.03).clamp(0.0, 1.0);
        final tx = _bezier(startX, midX, targetX, tt);
        final ty = _bezier(startY, midY, targetY, tt);
        final ta = alpha * (1.0 - j / 8) * 0.3;
        canvas.drawCircle(Offset(tx, ty), 1.0,
            _homingTrailPaint..color = color.withValues(alpha: ta));
      }

      // Direzione missile = tangente bezier (derivata).
      final tt1 = (t + 0.01).clamp(0.0, 1.0);
      final tanX = _bezier(startX, midX, targetX, tt1) - bx;
      final tanY = _bezier(startY, midY, targetY, tt1) - by;
      final angle = math.atan2(tanY, tanX) + math.pi / 2;

      // Missile silhouette — match in-game HomingMissile.render:
      // flame rosso-arancio (dietro) + corpo cyan rounded + naso bianco + fins.
      canvas.save();
      canvas.translate(bx, by);
      canvas.rotate(angle);

      const bodyW = 4.0;
      const bodyH = 9.0;
      final flicker = 1.0 + math.sin(time * 20 + i) * 0.25;
      final flameLen = bodyH * 0.8 * flicker;

      // Flame 3 strati (outer red, mid orange, core bianco)
      canvas.drawOval(
        Rect.fromCenter(
            center: Offset(0, bodyH * 0.55 + flameLen * 0.3),
            width: bodyW * 1.3,
            height: flameLen * 1.2),
        _homingFlameOuterPaint
          ..color = const Color(0xFFFF2200).withValues(alpha: 0.5 * alpha),
      );
      canvas.drawOval(
        Rect.fromCenter(
            center: Offset(0, bodyH * 0.52 + flameLen * 0.25),
            width: bodyW * 0.85,
            height: flameLen * 0.85),
        _homingFlameMidPaint
          ..color = const Color(0xFFFF8800).withValues(alpha: 0.85 * alpha),
      );
      canvas.drawOval(
        Rect.fromCenter(
            center: Offset(0, bodyH * 0.5 + flameLen * 0.2),
            width: bodyW * 0.5,
            height: flameLen * 0.5),
        _homingFlameCorePaint..color = const Color(0xFFFFFFDD).withValues(alpha: alpha),
      );

      // Fins (triangoli laterali) — color cyan
      final finPath = Path()
        ..moveTo(-bodyW * 0.5, bodyH * 0.25)
        ..lineTo(-bodyW * 1.0, bodyH * 0.55)
        ..lineTo(-bodyW * 0.5, bodyH * 0.55)
        ..close()
        ..moveTo(bodyW * 0.5, bodyH * 0.25)
        ..lineTo(bodyW * 1.0, bodyH * 0.55)
        ..lineTo(bodyW * 0.5, bodyH * 0.55)
        ..close();
      canvas.drawPath(
          finPath, _homingFinPaint..color = color.withValues(alpha: 0.9 * alpha));

      // Corpo cyan rounded
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
              center: const Offset(0, bodyH * 0.05),
              width: bodyW,
              height: bodyH * 0.8),
          const Radius.circular(bodyW * 0.25),
        ),
        _homingBodyPaint..color = color.withValues(alpha: alpha),
      );

      // Naso bianco (cono)
      final nosePath = Path()
        ..moveTo(-bodyW * 0.5, -bodyH * 0.35)
        ..lineTo(0, -bodyH * 0.65)
        ..lineTo(bodyW * 0.5, -bodyH * 0.35)
        ..close();
      canvas.drawPath(
          nosePath,
          _homingNosePaint
            ..color = const Color(0xFFE0FFFF).withValues(alpha: alpha));

      canvas.restore();

      // Impatto
      if (t > 0.9) {
        final impactAlpha = (t - 0.9) / 0.1 * 0.4;
        canvas.drawCircle(
            Offset(bx, by),
            8 * (t - 0.9) / 0.1,
            _homingImpactPaint..color = Colors.white.withValues(alpha: impactAlpha));
      }
    }
  }

  double _bezier(double p0, double p1, double p2, double t) {
    return (1 - t) * (1 - t) * p0 + 2 * (1 - t) * t * p1 + t * t * p2;
  }

  void _drawPlasmaBolts(Canvas canvas, double cx, double shipY, double rate) {
    // Palla plasma — match in-game (3 strati glow + body + core bianco flicker).
    for (int i = 0; i < 4; i++) {
      final phase = (time / rate + i * 2.5) % 10;
      final y = shipY - 27 - phase * 32;
      if (y < 8 || y > shipY - 15) continue;
      final alpha = (1.0 - phase / 10).clamp(0.0, 1.0);
      final pulse = 0.6 + 0.4 * (0.5 + 0.5 * math.sin(time * 5 + i));
      final blink = 0.7 + 0.3 * math.sin(time * 14 + i * 2);
      final baseR = 7 + math.sin(time * 3 + i) * 1.2;

      // Archi elettrici attorno al plasma
      final arcPaint = _plasmaArcPaint..color = color.withValues(alpha: alpha * 0.2 * pulse);
      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, y), radius: baseR * 1.5),
        time * 5 + i, math.pi * 0.8, false, arcPaint,
      );
      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, y), radius: baseR * 1.5),
        time * 5 + i + math.pi, math.pi * 0.8, false, arcPaint,
      );

      // 3 strati di glow concentrici (come in-game PlasmaBullet.render).
      canvas.drawCircle(Offset(cx, y), baseR * 2.4, _plasmaGlowOuterPaint
        ..color = color.withValues(alpha: alpha * 0.25 * pulse));
      canvas.drawCircle(Offset(cx, y), baseR * 1.8, _plasmaGlowMidPaint
        ..color = color.withValues(alpha: alpha * 0.5 * pulse));
      canvas.drawCircle(Offset(cx, y), baseR * 1.3, _plasmaBodyGlowPaint
        ..color = color.withValues(alpha: alpha * 0.8 * pulse));
      // Body viola pieno
      canvas.drawCircle(Offset(cx, y), baseR, _plasmaBodyPaint
        ..color = color.withValues(alpha: alpha));
      // Nucleo bianco lampeggiante
      canvas.drawCircle(Offset(cx, y), baseR * 0.45, _plasmaCorePaint
        ..color = Colors.white.withValues(alpha: alpha * blink));
    }
  }

  void _drawLaserBeam(Canvas canvas, double cx, double shipY) {
    // Match in-game LaserBeam.render: raggio DRITTO statico (nessun scan X).
    // In-game: glow rect 12px wide + core rect 3px wide. Lifetime 0.1s
    // rinnovato ogni frame → beam continuo.
    final pulse = 0.85 + math.sin(time * 8) * 0.15;
    const beamTop = 20.0;
    final beamH = shipY - 22 - beamTop;

    // Glow esterno (12px come in-game)
    canvas.drawRect(
      Rect.fromCenter(
          center: Offset(cx, beamTop + beamH / 2),
          width: 12 * pulse,
          height: beamH),
      Paint()
        ..color = color.withValues(alpha: 0.4)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );

    // Strato medio
    canvas.drawRect(
      Rect.fromCenter(
          center: Offset(cx, beamTop + beamH / 2), width: 6, height: beamH),
      Paint()..color = color.withValues(alpha: 0.75 * pulse),
    );

    // Nucleo 3px (come in-game)
    canvas.drawRect(
      Rect.fromCenter(
          center: Offset(cx, beamTop + beamH / 2), width: 3, height: beamH),
      Paint()..color = const Color(0xFFFFFFFF).withValues(alpha: 0.9 * pulse),
    );

    // Impatto in cima (flash rosso)
    canvas.drawCircle(
        Offset(cx, beamTop),
        8 * pulse,
        Paint()
          ..color = color.withValues(alpha: 0.5 * pulse)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));
    // Scintille dall'impatto (cx = centro beam statico, non scan)
    final random = math.Random(12);
    for (int i = 0; i < 4; i++) {
      final sparkAngle = time * 5 + i * math.pi / 2;
      final sparkDist = 5 + random.nextDouble() * 8;
      final sx = cx + math.cos(sparkAngle) * sparkDist;
      final sy = beamTop + math.sin(sparkAngle).abs() * sparkDist;
      canvas.drawCircle(Offset(sx, sy), 1, Paint()
        ..color = Colors.white.withValues(alpha: 0.3 * pulse));
    }
  }

  @override
  bool shouldRepaint(covariant _WeaponPreviewPainter old) => old.time != time;
}

/// Pulsante azione per la riga di un pet nel tab PETS:
/// - se non posseduto → "BUY [cost]g"
/// - se posseduto + non attivo → "EQUIP"
/// - se attivo → "EQUIPPED" (read-only verde)
class _PetActionButton extends StatelessWidget {
  final int cost;
  final bool owned;
  final bool isActive;
  final Color color;
  final VoidCallback onBuy;
  final VoidCallback onEquip;

  const _PetActionButton({
    required this.cost,
    required this.owned,
    required this.isActive,
    required this.color,
    required this.onBuy,
    required this.onEquip,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final String label;
    final Color btnColor;
    final VoidCallback? onTap;
    if (isActive) {
      label = l10n.shopEquipped;
      btnColor = Colors.greenAccent;
      onTap = null;
    } else if (owned) {
      label = l10n.shopEquip;
      btnColor = color;
      onTap = onEquip;
    } else {
      label = l10n.shopBuyWithCost(cost);
      btnColor = const Color(0xFFFFD700);
      onTap = onBuy;
    }
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: btnColor.withValues(alpha: 0.12),
          border: Border.all(color: btnColor.withValues(alpha: 0.7)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: btnColor,
            fontSize: 11,
            fontWeight: FontWeight.w900,
            fontFamily: 'monospace',
            letterSpacing: 1.5,
          ),
        ),
      ),
    );
  }
}
