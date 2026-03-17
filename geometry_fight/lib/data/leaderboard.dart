import 'package:hive/hive.dart';

/// Entry singola nella leaderboard
class LeaderboardEntry {
  final String mode;
  final String difficulty;
  final int score;
  final int wave;
  final int kills;
  final DateTime date;

  LeaderboardEntry({
    required this.mode,
    required this.difficulty,
    required this.score,
    required this.wave,
    required this.kills,
    required this.date,
  });

  Map<String, dynamic> toJson() => {
    'mode': mode,
    'difficulty': difficulty,
    'score': score,
    'wave': wave,
    'kills': kills,
    'date': date.toIso8601String(),
  };

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) =>
      LeaderboardEntry(
        mode: json['mode'] ?? 'classic',
        difficulty: json['difficulty'] ?? 'normal',
        score: json['score'] ?? 0,
        wave: json['wave'] ?? 0,
        kills: json['kills'] ?? 0,
        date: DateTime.tryParse(json['date'] ?? '') ?? DateTime.now(),
      );
}

/// Gestisce la leaderboard locale salvata con Hive.
/// Mantiene le top 10 entry per ogni combinazione modalità+difficoltà.
class LeaderboardManager {
  static late Box _box;

  static Future<void> init() async {
    _box = await Hive.openBox('geometry_fight_leaderboard');
  }

  /// Restituisce la chiave di storage per una combinazione mode/difficulty
  static String _key(String mode, String difficulty) => '${mode}_$difficulty';

  /// Restituisce le top entries per una modalità e difficoltà
  static List<LeaderboardEntry> getEntries(String mode, String difficulty) {
    final key = _key(mode, difficulty);
    final raw = _box.get(key);
    if (raw == null) return [];

    final list = List<Map<String, dynamic>>.from(
      (raw as List).map((e) => Map<String, dynamic>.from(e)),
    );
    final entries = list.map((e) => LeaderboardEntry.fromJson(e)).toList();
    // Ordina per score decrescente
    entries.sort((a, b) => b.score.compareTo(a.score));
    return entries;
  }

  /// Restituisce tutte le entries di tutte le modalità
  static List<LeaderboardEntry> getAllEntries() {
    final all = <LeaderboardEntry>[];
    for (final key in _box.keys) {
      final raw = _box.get(key);
      if (raw != null) {
        final list = List<Map<String, dynamic>>.from(
          (raw as List).map((e) => Map<String, dynamic>.from(e)),
        );
        all.addAll(list.map((e) => LeaderboardEntry.fromJson(e)));
      }
    }
    all.sort((a, b) => b.score.compareTo(a.score));
    return all;
  }

  /// Aggiunge una nuova entry e mantiene solo le top 10
  static Future<void> addEntry(LeaderboardEntry entry) async {
    final key = _key(entry.mode, entry.difficulty);
    final existing = getEntries(entry.mode, entry.difficulty);
    existing.add(entry);
    existing.sort((a, b) => b.score.compareTo(a.score));

    // Mantieni solo top 10
    final top10 = existing.take(10).toList();
    await _box.put(key, top10.map((e) => e.toJson()).toList());
  }

  /// Controlla se il punteggio è da record (top 10)
  static bool isHighScore(String mode, String difficulty, int score) {
    final entries = getEntries(mode, difficulty);
    if (entries.length < 10) return true;
    return score > entries.last.score;
  }

  /// Pulisce tutta la leaderboard
  static Future<void> clear() async {
    await _box.clear();
  }
}
