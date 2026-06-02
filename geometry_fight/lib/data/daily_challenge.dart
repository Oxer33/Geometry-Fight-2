import 'difficulty.dart';

/// Configurazione DETERMINISTICA della Daily Challenge.
///
/// Arma + pet + difficoltà sono derivati esclusivamente dalla data UTC del
/// giorno → IDENTICI per tutti i player nello stesso giorno. Insieme al seed
/// wave già deterministico (`WaveSystem._dailySeed`) e ai modifiers azzerati,
/// questo rende il daily la STESSA identica run per tutti — base necessaria
/// per una classifica globale equa (vedi roadmap leaderboard).
///
/// Nessuno stato, nessuna persistenza: pure function della data.
class DailyChallenge {
  const DailyChallenge._();

  /// Seed stabile dal giorno UTC (YYYYMMDD). Cambia a mezzanotte UTC.
  static int seedForDate(DateTime utc) {
    final d = DateTime.utc(utc.year, utc.month, utc.day);
    return d.year * 10000 + d.month * 100 + d.day;
  }

  /// Weapon id riconosciuti da `Player.setWeaponFromId` (esclusa `basic`:
  /// il daily assegna sempre un'arma "speciale"). NB: spreadFan/overdrive/
  /// chainLightning non sono mappati da setWeaponFromId → esclusi (userebbero
  /// basic). `chain` = Chain Lightning.
  static const List<String> _weaponIds = [
    'spread',
    'triple',
    'ricochet',
    'homing',
    'plasma',
    'laser',
    'gauss',
    'chain',
  ];

  /// Pet id reali (kPetCatalog) — il daily ha sempre un companion (no 'none').
  static const List<String> _petIds = [
    'attack',
    'collect',
    'sweep',
    'defend',
    'snipe',
    'ram',
    'phoenix',
    'black_hole_pet',
    'emp_drone',
    'tactical_spotter',
  ];

  static String weaponIdForDate(DateTime utc) {
    final s = seedForDate(utc);
    return _weaponIds[s % _weaponIds.length];
  }

  static String petIdForDate(DateTime utc) {
    // Offset diverso dal weapon così arma e pet variano indipendentemente.
    final s = seedForDate(utc);
    return _petIds[(s ~/ 7) % _petIds.length];
  }

  static Difficulty difficultyForDate(DateTime utc) {
    final s = seedForDate(utc);
    return Difficulty.values[(s ~/ 13) % Difficulty.values.length];
  }

  // ─── Convenience "oggi" (UTC) ───
  static DateTime get _today => DateTime.now().toUtc();
  static String get todayWeaponId => weaponIdForDate(_today);
  static String get todayPetId => petIdForDate(_today);
  static Difficulty get todayDifficulty => difficultyForDate(_today);
}
