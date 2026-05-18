import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show Locale;
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

  /// Codice lingua attiva (ISO 639-1, es. 'it', 'en', 'es', 'fr', 'de', 'pt',
  /// 'zh', 'ja', 'ru'). Default 'it' (lingua di sviluppo originale).
  /// Cambiabile da Settings → LINGUA. Usato per `MaterialApp.locale`.
  String languageCode;

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
    this.languageCode = 'it',
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

  /// Locale Flutter derivata da `languageCode`. Usata da `MaterialApp.locale`.
  Locale get locale => Locale(languageCode);

  double get damageMultiplier {
    final level = getUpgradeLevel('firepower');
    return 1.0 + level * 0.025; // +2.5% per livello (max +25% al L10)
  }

  double get speedMultiplier {
    final level = getUpgradeLevel('speed');
    return 1.0 + level * 0.025; // +2.5% per livello (max +25% al L10)
  }

  double get fireRateMultiplier {
    final level = getUpgradeLevel('fire_rate');
    return 1.0 + level * 0.025; // +2.5% per livello (max +25% al L10)
  }

  /// Durata dello scudo post-morte in secondi (0 = nessuno scudo).
  /// +2.5s per livello (max 25s al L10).
  double get postDeathShieldDuration {
    final level = getUpgradeLevel('shield_capacity');
    return level * 2.5;
  }

  int get startingLives {
    final level = getUpgradeLevel('starting_lives');
    // Integer step: live granted every 2 levels (max +5 a L10).
    return 3 + (level * 5) ~/ 10;
  }

  int get bombCapacity {
    // Bomb count is fixed at 3; the bomb_capacity upgrade now boosts radius.
    return 3;
  }

  double get bombRadius {
    final level = getUpgradeLevel('bomb_capacity');
    // L0: 375 (half arena diagonal-ish). L10: 750 (full arena width).
    return 375.0 + level * 37.5;
  }

  double get magnetRange {
    final level = getUpgradeLevel('magnet_range');
    return level * 5.0; // +5px per livello (max +50px al L10)
  }

  double get xpBoostMultiplier {
    final level = getUpgradeLevel('xp_boost');
    return 1.0 + level * 0.05; // +5% per livello (max +50% al L10)
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

  /// Minimal copyWith for loadout-style mutations that need to swap a single
  /// field without sharing the existing instance reference.
  SaveData copyWith({
    String? startingWeapon,
    String? activePet,
    String? languageCode,
  }) {
    return SaveData(
      goldGeoms: goldGeoms,
      upgrades: Map<String, int>.from(upgrades),
      unlockedSkins: List<String>.from(unlockedSkins),
      unlockedTrails: List<String>.from(unlockedTrails),
      unlockedModes: List<String>.from(unlockedModes),
      unlockedWeapons: List<String>.from(unlockedWeapons),
      highscores: Map<String, int>.from(highscores),
      totalPlaytime: totalPlaytime,
      stats: Map<String, int>.from(stats),
      playedModes: List<String>.from(playedModes),
      activeModifiers: List<String>.from(activeModifiers),
      activeSkin: activeSkin,
      activeTrail: activeTrail,
      startingWeapon: startingWeapon ?? this.startingWeapon,
      activePet: activePet ?? this.activePet,
      unlockedPets: List<String>.from(unlockedPets),
      lastDailyClaim: lastDailyClaim,
      dailyStreak: dailyStreak,
      languageCode: languageCode ?? this.languageCode,
    );
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
        'languageCode': languageCode,
      };

  factory SaveData.fromJson(Map<String, dynamic> json) => SaveData(
        goldGeoms: (json['goldGeoms'] as num?)?.toInt() ?? 0,
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
        totalPlaytime: (json['totalPlaytime'] as num?)?.toInt() ?? 0,
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
        // Default 'it' per back-compat: save vecchi senza il campo prendono
        // la lingua di sviluppo originale.
        languageCode: (json['languageCode'] as String?) ?? 'it',
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

  /// Chiude il box Hive: invocare da AppLifecycleState.detached per
  /// flush + release file handle. Hive flusha già su ogni put(), quindi
  /// il rischio data-loss è minimo, ma close() è buona pratica.
  static Future<void> close() async {
    if (!_initialized) return;
    await _box.close();
    _initialized = false;
  }
}

/// Reward giornaliero in geom (utente: "daily reward che dà +100 geom").
const int kDailyRewardAmount = 100;
