import 'dart:math' as math;

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

  /// Modifier id validi per il daily (mirror di `allModifiers` in
  /// modifiers.dart). `infinite_bombs` ESCLUSO: rimuove le armi → annullerebbe
  /// l'arma speciale che il daily assegna apposta per la giornata.
  static const List<String> _modifierIds = [
    'glass_cannon',
    'bullet_hell',
    'speed_demon',
    'no_powerups',
    'fog_of_war',
    'tiny_arena',
    'one_shot',
    'chaos',
    'giant_mode',
    'ricochet_world',
    'magnet_king',
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

  /// Esattamente 2 modificatori deterministici dal giorno UTC (richiesta
  /// utente: "devono sempre capitare i modificatori abilitati ma non più di
  /// due"). Stessi per tutti i player nello stesso giorno → daily equo.
  /// Fisher-Yates shuffle seedato dalla data, prende i primi 2 distinti.
  static List<String> modifiersForDate(DateTime utc) {
    final ids = List<String>.of(_modifierIds);
    // XOR con costante (golden ratio 32-bit) per scorrelare dallo stream usato
    // da weapon/pet/difficulty: niente accoppiamento arma↔modifier.
    final rng = math.Random(seedForDate(utc) ^ 0x9E3779B9);
    for (int i = ids.length - 1; i > 0; i--) {
      final j = rng.nextInt(i + 1);
      final tmp = ids[i];
      ids[i] = ids[j];
      ids[j] = tmp;
    }
    return List<String>.unmodifiable(ids.take(2));
  }

  // ─── Convenience "oggi" (UTC) ───
  static DateTime get _today => DateTime.now().toUtc();
  static String get todayWeaponId => weaponIdForDate(_today);
  static String get todayPetId => petIdForDate(_today);
  static Difficulty get todayDifficulty => difficultyForDate(_today);
  static List<String> get todayModifiers => modifiersForDate(_today);
}
