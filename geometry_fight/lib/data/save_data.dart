import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show Locale;
import 'package:hive/hive.dart';

import 'crash_reporter.dart';
import 'talents/talent_service.dart';

class SaveData {
  int goldGeoms;
  Map<String, int> upgrades;

  /// Talent web — total XP accumulated across runs. Player level (and therefore
  /// the number of talent points) is DERIVED from this via [playerLevel]; level
  /// is never stored, XP is the single source-of-truth. See [levelForXp].
  int playerXp;

  /// Owned talent node ids (single-rank). `ownedTalents.length` == points spent.
  /// Available points = [playerLevel] − spent. Cleared by respec.
  List<String> ownedTalents;

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
    this.playerXp = 0,
    List<String>? ownedTalents,
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
  }) : upgrades = upgrades ?? {},
       ownedTalents = ownedTalents ?? [],
       unlockedSkins = unlockedSkins ?? ['classic'],
       unlockedTrails = unlockedTrails ?? ['normal'],
       unlockedModes = unlockedModes ?? ['classic'],
       unlockedWeapons = unlockedWeapons ?? ['basic'],
       highscores = highscores ?? {},
       stats = stats ?? {},
       playedModes = playedModes ?? [],
       activeModifiers = activeModifiers ?? [],
       unlockedPets = unlockedPets ?? ['none'];

  /// Restituisce il livello di un upgrade, clamped a `[0, kMaxUpgradeLevel]`
  /// per difendersi da save corrotti o tampered (es. utenti che editano la
  /// Hive box). Tutte le formule scaling (damage/speed/bomb/etc.) usano
  /// questo getter, quindi la clamp è single source-of-truth.
  int getUpgradeLevel(String id) =>
      (upgrades[id] ?? 0).clamp(0, kMaxUpgradeLevel);

  /// Locale Flutter derivata da `languageCode`. Usata da `MaterialApp.locale`.
  Locale get locale => Locale(languageCode);

  // ─── TALENT WEB: levelling + folded stats ─────────────────────────────────
  /// Folded talent bonuses. Cached per instance, invalidated by [_ownedVersion]
  /// which is bumped on every owned-set mutation (see [allocateTalent] /
  /// [respecTalents]). Length alone is NOT a safe key: respec→reallocate to the
  /// same count would serve a stale fold. Combat reads stat getters every
  /// frame, so this stays O(1) after the first fold.
  TalentStats get talentStats {
    if (_folded == null || _foldedKey != _ownedVersion) {
      _folded = foldTalents(ownedTalents);
      _foldedKey = _ownedVersion;
    }
    return _folded!;
  }

  TalentStats? _folded;
  int _foldedKey = -1;
  int _ownedVersion = 0;

  /// Mark [id] owned and invalidate the folded-stats cache. Single entry point
  /// for allocation so the cache key ([_ownedVersion]) always advances.
  void allocateTalent(String id) {
    ownedTalents.add(id);
    _ownedVersion++;
  }

  /// Clear all owned talents (respec) and invalidate the cache.
  void respecTalents() {
    ownedTalents.clear();
    _ownedVersion++;
  }

  /// Player level derived from [playerXp]. Starts at 1.
  int get playerLevel => levelForXp(playerXp);

  /// Talent points still available to spend (earned − spent).
  int get talentPoints =>
      (playerLevel - ownedTalents.length).clamp(0, playerLevel);

  /// Accumulate XP (per-kill / per-boss at run end). Mutates in place.
  void addXp(int amount) {
    if (amount <= 0) return;
    playerXp += amount;
  }

  /// TESTING: grant enough XP to jump [levels] player levels above the current
  /// one. Backs the debug "+1000 levels" button.
  void grantTestLevels(int levels) {
    // Ceiling 30000 keeps xpForLevel (≈9e9 at L30000) well inside int64 — a
    // larger target would overflow and corrupt playerXp into a negative.
    final target = (playerLevel + levels).clamp(1, 30000);
    final needed = xpForLevel(target);
    if (needed > playerXp) playerXp = needed;
  }

  // ─── Stat getters (folded from owned talents; shop upgrades removed) ───────
  // Getter NAMES are kept stable so the combat layer needs no changes.
  double get damageMultiplier => 1.0 + talentStats.atkPct;

  double get speedMultiplier => 1.0 + talentStats.moveSpeed;

  double get fireRateMultiplier => 1.0 + talentStats.fireRate;

  /// Post-death shield duration in seconds, summed from Shield Duration talents
  /// (+0.1s each). After a non-fatal hit (lives remaining) the player gets this
  /// many seconds of invulnerability — see Player.takeDamage.
  double get postDeathShieldDuration => talentStats.shieldDuration;

  /// Lives fixed at 3 (no HP/lives talents in a one-shot game).
  int get startingLives => 3;

  int get bombCapacity => 3;

  /// Base 375px blast, scaled by Bomb Radius talents + Bomb empower forks.
  double get bombRadius =>
      375.0 * (1.0 + talentStats.bombRadius + talentStats.bombPower);

  /// Extra magnet pickup range in px from Ascendant talents.
  double get magnetRange => talentStats.magnet;

  /// Multiplies gold earned at run end (Gold Find).
  double get xpBoostMultiplier => 1.0 + talentStats.goldFind;

  /// Multiplies XP earned during a run (XP Find → faster levelling).
  double get xpFindMultiplier => 1.0 + talentStats.essenceFind;

  /// Crit chance fraction (clamped 0..1) from Deadeye talents.
  double get critChance => talentStats.critChance.clamp(0.0, 1.0);

  /// Base crit damage multiplier.
  static const double kCritMultiplier = 2.2;

  /// Effective crit damage multiplier (base + Crit Damage talents).
  double get critMultiplier => kCritMultiplier + talentStats.critDmg;

  /// Dash is always available (no shop gate). Cooldown cut by CDR talents.
  bool get dashUnlocked => true;

  /// Dash cooldown in seconds: base 2.0s reduced by global cooldown talents and
  /// Dash empower forks, floored at 0.6s.
  double get dashCooldown =>
      (2.0 * (1.0 - talentStats.cooldown) * (1.0 - talentStats.dashCdr)).clamp(
        0.6,
        2.0,
      );

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
        debugPrint(
          'claimDailyReward parse error: $e (lastClaim=$lastDailyClaim)',
        );
        dailyStreak = 1;
      }
    }

    lastDailyClaim = today;
    goldGeoms += kDailyRewardAmount;
    return kDailyRewardAmount;
  }

  /// Returns a copy of this SaveData with the given fields replaced. Any field
  /// not passed is carried over; collections are defensively copied so the new
  /// instance never shares mutable list/map references with the original. All
  /// fields are now overridable, so callers can update immutably
  /// (`save = save.copyWith(goldGeoms: save.goldGeoms + 100)`) instead of
  /// mutating in place.
  SaveData copyWith({
    int? goldGeoms,
    Map<String, int>? upgrades,
    int? playerXp,
    List<String>? ownedTalents,
    List<String>? unlockedSkins,
    List<String>? unlockedTrails,
    List<String>? unlockedModes,
    List<String>? unlockedWeapons,
    Map<String, int>? highscores,
    int? totalPlaytime,
    Map<String, int>? stats,
    List<String>? playedModes,
    List<String>? activeModifiers,
    String? activeSkin,
    String? activeTrail,
    String? startingWeapon,
    String? activePet,
    List<String>? unlockedPets,
    String? lastDailyClaim,
    int? dailyStreak,
    String? languageCode,
  }) {
    return SaveData(
      goldGeoms: goldGeoms ?? this.goldGeoms,
      upgrades: upgrades ?? Map<String, int>.from(this.upgrades),
      playerXp: playerXp ?? this.playerXp,
      ownedTalents: ownedTalents ?? List<String>.from(this.ownedTalents),
      unlockedSkins: unlockedSkins ?? List<String>.from(this.unlockedSkins),
      unlockedTrails: unlockedTrails ?? List<String>.from(this.unlockedTrails),
      unlockedModes: unlockedModes ?? List<String>.from(this.unlockedModes),
      unlockedWeapons:
          unlockedWeapons ?? List<String>.from(this.unlockedWeapons),
      highscores: highscores ?? Map<String, int>.from(this.highscores),
      totalPlaytime: totalPlaytime ?? this.totalPlaytime,
      stats: stats ?? Map<String, int>.from(this.stats),
      playedModes: playedModes ?? List<String>.from(this.playedModes),
      activeModifiers:
          activeModifiers ?? List<String>.from(this.activeModifiers),
      activeSkin: activeSkin ?? this.activeSkin,
      activeTrail: activeTrail ?? this.activeTrail,
      startingWeapon: startingWeapon ?? this.startingWeapon,
      activePet: activePet ?? this.activePet,
      unlockedPets: unlockedPets ?? List<String>.from(this.unlockedPets),
      lastDailyClaim: lastDailyClaim ?? this.lastDailyClaim,
      dailyStreak: dailyStreak ?? this.dailyStreak,
      languageCode: languageCode ?? this.languageCode,
    );
  }

  Map<String, dynamic> toJson() => {
    'goldGeoms': goldGeoms,
    'upgrades': upgrades,
    'playerXp': playerXp,
    'ownedTalents': ownedTalents,
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
      ((json['upgrades'] ?? {}) as Map).map(
        (k, v) => MapEntry(k.toString(), (v as num?)?.toInt() ?? 0),
      ),
    ),
    // Talent web (back-compat: old saves default to 0 XP / no talents).
    playerXp: (json['playerXp'] as num?)?.toInt() ?? 0,
    ownedTalents: List<String>.from(json['ownedTalents'] ?? const <String>[]),
    unlockedSkins: List<String>.from(json['unlockedSkins'] ?? ['classic']),
    unlockedTrails: List<String>.from(json['unlockedTrails'] ?? ['normal']),
    unlockedModes: List<String>.from(json['unlockedModes'] ?? ['classic']),
    unlockedWeapons: List<String>.from(json['unlockedWeapons'] ?? ['basic']),
    highscores: Map<String, int>.from(
      ((json['highscores'] ?? {}) as Map).map(
        (k, v) => MapEntry(k.toString(), (v as num?)?.toInt() ?? 0),
      ),
    ),
    totalPlaytime: (json['totalPlaytime'] as num?)?.toInt() ?? 0,
    stats: Map<String, int>.from(
      ((json['stats'] ?? {}) as Map).map(
        (k, v) => MapEntry(k.toString(), (v as num?)?.toInt() ?? 0),
      ),
    ),
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
  static bool _initialized =
      false; // FIX C6: guard contro LateInitializationError

  static Future<void> init() async {
    _box = await Hive.openBox('geometry_fight_save');
    _initialized = true;
  }

  static SaveData load() {
    if (!_initialized) {
      return SaveData(); // FIX C6: guard se init() non è stato chiamato
    }
    try {
      final json = _box.get('save');
      if (json == null) return SaveData();
      return SaveData.fromJson(Map<String, dynamic>.from(json));
    } catch (e) {
      debugPrint(
        'SaveManager.load() error: $e',
      ); // FIX C6: log invece di silenzio
      return SaveData();
    }
  }

  static Future<void> save(SaveData data) async {
    if (!_initialized) return; // Guard contro LateInitializationError.
    try {
      await _box.put('save', data.toJson());
    } catch (e, st) {
      // Una scrittura Hive fallita NON deve crashare il gioco né sparire in
      // silenzio: logghiamo nel CrashReporter così la perdita di progresso è
      // diagnosticabile (visibile nei crash log).
      CrashReporter.handleZoneError(e, st);
    }
  }

  static Future<void> clear() async {
    if (!_initialized) return;
    try {
      await _box.clear();
    } catch (e, st) {
      CrashReporter.handleZoneError(e, st);
    }
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

/// Livello max per tutti gli upgrade dello shop (10-level scaling iter).
/// Usato da `SaveData.getUpgradeLevel` per il clamp difensivo e da
/// `_checkAllUpgrades` (game_screen) per l'achievement "all_upgrades".
const int kMaxUpgradeLevel = 10;

// ─── TALENT WEB: XP ↔ level curve ───────────────────────────────────────────
// Per-level cost grows linearly: xpForNext(L) = 60 + (L-1)*20. Cumulative XP to
// reach level L is the closed form total(L) = 10·(L-1)·(L+4):
//   L1→0, L2→60, L3→140, L4→240 …
// Inverting gives an O(1) [levelForXp]. The player starts at level 1.

/// Total XP required to be AT [level] (level ≥ 1).
int xpForLevel(int level) {
  final l = level < 1 ? 1 : level;
  return 10 * (l - 1) * (l + 4);
}

/// Player level for a given total [xp] (≥ 1).
int levelForXp(int xp) {
  if (xp <= 0) return 1;
  final m = ((-5 + math.sqrt(25 + 0.4 * xp)) / 2).floor();
  return 1 + (m < 0 ? 0 : m);
}

/// XP granted per normal mob kill (utente: "valore di exp per ogni mob").
const int kXpPerKill = 5;

/// XP granted per boss kill (worth many mobs).
const int kXpPerBoss = 250;
