import 'package:hive/hive.dart';

class SaveData {
  int goldGeoms;
  Map<String, int> upgrades;
  List<String> unlockedSkins;
  List<String> unlockedTrails;
  List<String> unlockedModes;
  List<String> unlockedWeapons;
  Map<String, int> highscores;
  int totalPlaytime;
  Map<String, int> stats;
  String activeSkin;
  String activeTrail;
  String startingWeapon;

  SaveData({
    this.goldGeoms = 0,
    Map<String, int>? upgrades,
    List<String>? unlockedSkins,
    List<String>? unlockedTrails,
    List<String>? unlockedModes,
    List<String>? unlockedWeapons,
    Map<String, int>? highscores,
    this.totalPlaytime = 0,
    Map<String, int>? stats,
    this.activeSkin = 'classic',
    this.activeTrail = 'normal',
    this.startingWeapon = 'basic',
  })  : upgrades = upgrades ?? {},
        unlockedSkins = unlockedSkins ?? ['classic'],
        unlockedTrails = unlockedTrails ?? ['normal'],
        unlockedModes = unlockedModes ?? ['classic'],
        unlockedWeapons = unlockedWeapons ?? ['basic'],
        highscores = highscores ?? {},
        stats = stats ?? {};

  int getUpgradeLevel(String id) => upgrades[id] ?? 0;

  double get damageMultiplier {
    final level = getUpgradeLevel('firepower');
    const bonuses = [0.0, 0.15, 0.30, 0.50, 0.70, 1.0];
    return 1.0 + (level < bonuses.length ? bonuses[level] : 1.0);
  }

  double get speedMultiplier {
    final level = getUpgradeLevel('speed');
    return 1.0 + level * 0.10;
  }

  double get fireRateMultiplier {
    final level = getUpgradeLevel('fire_rate');
    return 1.0 + level * 0.08;
  }

  int get shieldCapacity {
    final level = getUpgradeLevel('shield_capacity');
    return 1 + level;
  }

  bool get shieldRegens => getUpgradeLevel('shield_capacity') >= 3;

  int get startingLives {
    final level = getUpgradeLevel('starting_lives');
    return 3 + level;
  }

  int get bombCapacity {
    final level = getUpgradeLevel('bomb_capacity');
    return 3 + level;
  }

  double get magnetRange {
    final level = getUpgradeLevel('magnet_range');
    const ranges = [0.0, 50.0, 150.0, 350.0];
    return level < ranges.length ? ranges[level] : 350.0;
  }

  double get xpBoostMultiplier {
    final level = getUpgradeLevel('xp_boost');
    const boosts = [1.0, 1.2, 1.4, 1.7];
    return level < boosts.length ? boosts[level] : 1.7;
  }

  Map<String, dynamic> toJson() => {
        'goldGeoms': goldGeoms,
        'upgrades': upgrades,
        'unlockedSkins': unlockedSkins,
        'unlockedTrails': unlockedTrails,
        'unlockedModes': unlockedModes,
        'unlockedWeapons': unlockedWeapons,
        'highscores': highscores,
        'totalPlaytime': totalPlaytime,
        'stats': stats,
        'activeSkin': activeSkin,
        'activeTrail': activeTrail,
        'startingWeapon': startingWeapon,
      };

  factory SaveData.fromJson(Map<String, dynamic> json) => SaveData(
        goldGeoms: json['goldGeoms'] ?? 0,
        upgrades: Map<String, int>.from(json['upgrades'] ?? {}),
        unlockedSkins: List<String>.from(json['unlockedSkins'] ?? ['classic']),
        unlockedTrails: List<String>.from(json['unlockedTrails'] ?? ['normal']),
        unlockedModes: List<String>.from(json['unlockedModes'] ?? ['classic']),
        unlockedWeapons:
            List<String>.from(json['unlockedWeapons'] ?? ['basic']),
        highscores: Map<String, int>.from(json['highscores'] ?? {}),
        totalPlaytime: json['totalPlaytime'] ?? 0,
        stats: Map<String, int>.from(json['stats'] ?? {}),
        activeSkin: json['activeSkin'] ?? 'classic',
        activeTrail: json['activeTrail'] ?? 'normal',
        startingWeapon: json['startingWeapon'] ?? 'basic',
      );
}

class SaveManager {
  static late Box _box;

  static Future<void> init() async {
    _box = await Hive.openBox('geometry_fight_save');
  }

  static SaveData load() {
    final json = _box.get('save');
    if (json == null) return SaveData();
    return SaveData.fromJson(Map<String, dynamic>.from(json));
  }

  static Future<void> save(SaveData data) async {
    await _box.put('save', data.toJson());
  }

  static Future<void> clear() async {
    await _box.clear();
  }
}
