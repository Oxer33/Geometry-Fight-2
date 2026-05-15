import 'package:flutter/foundation.dart';
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
  List<String> playedModes;
  List<String> activeModifiers;
  String activeSkin;
  String activeTrail;
  String startingWeapon;
  /// Pet companion id attivo (loadout). 'none' = nessun pet equipaggiato
  /// (default per save vecchi). Vedi `pet_types.dart` per id validi.
  String activePet;
  /// Lista dei pet sbloccati nello shop. Default `['none']` (sempre disponibile
  /// l'opzione "no pet"). Pet acquistati aggiunti tramite shop_screen.
  List<String> unlockedPets;

  /// Daily reward: data ultimo claim formato 'YYYY-MM-DD' ('' = mai claimato).
  /// Reward +100 geom su claim. Streak: incrementa di 1 se claim consecutivo
  /// (gap esattamente 1 giorno), reset a 1 se gap > 1 giorno.
  String lastDailyClaim;
  int dailyStreak;

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
    List<String>? playedModes,
    List<String>? activeModifiers,
    this.activeSkin = 'classic',
    this.activeTrail = 'normal',
    this.startingWeapon = 'basic',
    this.activePet = 'none',
    List<String>? unlockedPets,
    this.lastDailyClaim = '',
    this.dailyStreak = 0,
  })  : upgrades = upgrades ?? {},
        unlockedSkins = unlockedSkins ?? ['classic'],
        unlockedTrails = unlockedTrails ?? ['normal'],
        unlockedModes = unlockedModes ?? ['classic'],
        unlockedWeapons = unlockedWeapons ?? ['basic'],
        highscores = highscores ?? {},
        stats = stats ?? {},
        playedModes = playedModes ?? [],
        activeModifiers = activeModifiers ?? [],
        unlockedPets = unlockedPets ?? ['none'];

  int getUpgradeLevel(String id) => upgrades[id] ?? 0;

  double get damageMultiplier {
    final level = getUpgradeLevel('firepower');
    return 1.0 + level * 0.05; // +5% per livello (max +25% al livello 5)
  }

  double get speedMultiplier {
    final level = getUpgradeLevel('speed');
    return 1.0 + level * 0.05; // +5% per livello (max +25% al livello 5)
  }

  double get fireRateMultiplier {
    final level = getUpgradeLevel('fire_rate');
    return 1.0 + level * 0.05; // +5% per livello (max +25% al livello 5)
  }

  /// Durata dello scudo post-morte in secondi (0 = nessuno scudo).
  /// Livello 1 = 5s, livello 2 = 10s, … livello 5 = 25s.
  double get postDeathShieldDuration {
    final level = getUpgradeLevel('shield_capacity');
    return level * 5.0;
  }

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
    return level * 10.0; // +10px per livello (max +50px al livello 5)
  }

  double get xpBoostMultiplier {
    final level = getUpgradeLevel('xp_boost');
    return 1.0 + level * 0.10; // +10% per livello (max +50% al livello 5)
  }

  // ─── DAILY REWARD ─────────────────────────────────────────────────────
  /// Helper: oggi in formato `YYYY-MM-DD`.
  static String _today() {
    final d = DateTime.now();
    final m = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    return '${d.year}-$m-$dd';
  }

  /// True se daily reward è riscattabile oggi (= lastDailyClaim != oggi).
  bool canClaimDailyReward() => lastDailyClaim != _today();

  /// Riscatta daily reward: aggiunge `kDailyRewardAmount` a goldGeoms e
  /// gestisce streak (incrementa se consecutivo, reset a 1 se gap > 1).
  /// Ritorna il numero di geom ottenuti (sempre `kDailyRewardAmount`).
  /// Caller deve salvare con `SaveManager.save(this)`.
  int claimDailyReward() {
    final today = _today();
    if (lastDailyClaim == today) return 0; // già claimato

    // Streak: incrementa se ieri, reset a 1 se gap > 1 o mai claimato.
    if (lastDailyClaim.isEmpty) {
      dailyStreak = 1;
    } else {
      try {
        final lastDate = DateTime.parse(lastDailyClaim);
        final todayDate = DateTime.parse(today);
        final diff = todayDate.difference(lastDate).inDays;
        if (diff == 1) {
          dailyStreak += 1;
        } else {
          dailyStreak = 1; // gap → reset
        }
      } catch (e) {
        // Iter 13 (caveman-review): no più silent swallow — log invece.
        debugPrint('claimDailyReward parse error: $e (lastClaim=$lastDailyClaim)');
        dailyStreak = 1;
      }
    }

    lastDailyClaim = today;
    goldGeoms += kDailyRewardAmount;
    return kDailyRewardAmount;
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
        'playedModes': playedModes,
        'activeModifiers': activeModifiers,
        'activeSkin': activeSkin,
        'activeTrail': activeTrail,
        'startingWeapon': startingWeapon,
        'activePet': activePet,
        'unlockedPets': unlockedPets,
        'lastDailyClaim': lastDailyClaim,
        'dailyStreak': dailyStreak,
      };

  factory SaveData.fromJson(Map<String, dynamic> json) => SaveData(
        goldGeoms: json['goldGeoms'] ?? 0,
        // FIX C7: conversione robusta per i valori numerici (evita cast int/double da Hive)
        upgrades: Map<String, int>.from(
            ((json['upgrades'] ?? {}) as Map).map((k, v) =>
                MapEntry(k.toString(), (v as num).toInt()))),
        unlockedSkins: List<String>.from(json['unlockedSkins'] ?? ['classic']),
        unlockedTrails: List<String>.from(json['unlockedTrails'] ?? ['normal']),
        unlockedModes: List<String>.from(json['unlockedModes'] ?? ['classic']),
        unlockedWeapons:
            List<String>.from(json['unlockedWeapons'] ?? ['basic']),
        highscores: Map<String, int>.from(
            ((json['highscores'] ?? {}) as Map).map((k, v) =>
                MapEntry(k.toString(), (v as num).toInt()))),
        totalPlaytime: json['totalPlaytime'] ?? 0,
        stats: Map<String, int>.from(
            ((json['stats'] ?? {}) as Map).map((k, v) =>
                MapEntry(k.toString(), (v as num).toInt()))),
        playedModes: List<String>.from(json['playedModes'] ?? []),
        activeModifiers: List<String>.from(json['activeModifiers'] ?? []),
        activeSkin: json['activeSkin'] ?? 'classic',
        activeTrail: json['activeTrail'] ?? 'normal',
        startingWeapon: json['startingWeapon'] ?? 'basic',
        // Pet fields: default 'none' / ['none'] per back-compat con save vecchi.
        activePet: json['activePet'] ?? 'none',
        unlockedPets: List<String>.from(json['unlockedPets'] ?? ['none']),
        lastDailyClaim: json['lastDailyClaim'] ?? '',
        dailyStreak: (json['dailyStreak'] as num?)?.toInt() ?? 0,
      );
}

class SaveManager {
  static late Box _box;
  static bool _initialized = false; // FIX C6: guard contro LateInitializationError

  static Future<void> init() async {
    _box = await Hive.openBox('geometry_fight_save');
    _initialized = true;
  }

  static SaveData load() {
    if (!_initialized) return SaveData(); // FIX C6: guard se init() non è stato chiamato
    try {
      final json = _box.get('save');
      if (json == null) return SaveData();
      return SaveData.fromJson(Map<String, dynamic>.from(json));
    } catch (e) {
      debugPrint('SaveManager.load() error: $e'); // FIX C6: log invece di silenzio
      return SaveData();
    }
  }

  static Future<void> save(SaveData data) async {
    if (!_initialized) return; // Guard contro LateInitializationError.
    await _box.put('save', data.toJson());
  }

  static Future<void> clear() async {
    if (!_initialized) return;
    await _box.clear();
  }
}

/// Reward giornaliero in geom (utente: "daily reward che dà +100 geom").
const int kDailyRewardAmount = 100;
