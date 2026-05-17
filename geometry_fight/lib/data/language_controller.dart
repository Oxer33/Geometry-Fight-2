import 'package:flutter/material.dart';

import 'save_data.dart';

/// Holds the current app [Locale] and notifies listeners on change.
///
/// Singleton via [instance] so any widget can call
/// `LanguageController.instance.setLanguage(code)` without prop drilling.
/// The active locale is persisted in [SaveData.languageCode] (Hive box).
class LanguageController extends ChangeNotifier {
  LanguageController._();

  static final LanguageController instance = LanguageController._();

  /// Locales matching the ARB files under `lib/l10n/`. Order is meaningful
  /// only for UI list display (e.g. Settings → Language picker).
  static const List<Locale> supportedLocales = <Locale>[
    Locale('it'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('de'),
    Locale('pt'),
    Locale('ru'),
    Locale('zh'),
    Locale('ja'),
  ];

  Locale _locale = const Locale('it');
  Locale get locale => _locale;

  /// Seeds the controller from the persisted save. Call after
  /// `SaveManager.init()` in `main()` and before `runApp`.
  Future<void> init() async {
    final code = SaveManager.load().languageCode;
    _locale = Locale(code);
  }

  /// Updates the active language and persists the change.
  ///
  /// No-op when [code] matches the current locale (avoids unnecessary
  /// MaterialApp rebuilds). Persists via `SaveManager.save(copyWith(...))`
  /// since the codebase uses immutable copyWith semantics
  /// (SaveManager has no `update()` method — Grep confirmed only
  /// `init()`, `load()`, `save()`, `clear()`, `close()`).
  Future<void> setLanguage(String code) async {
    if (_locale.languageCode == code) return;
    _locale = Locale(code);
    final current = SaveManager.load();
    await SaveManager.save(current.copyWith(languageCode: code));
    notifyListeners();
  }
}
