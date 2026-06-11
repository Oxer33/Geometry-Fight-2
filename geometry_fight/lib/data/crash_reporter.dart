import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Mini crash-reporter locale: raccoglie errori async/sync/framework e li
/// persiste in shared_preferences sotto `crash_log`. Dal menu Settings →
/// sezione debug si può leggerli/esportarli per capire perché il gioco
/// crasha occasionalmente.
///
/// Questa implementazione è volutamente leggera (niente servizi cloud): evita
/// di aggiungere dipendenze e preserva la privacy. Se in futuro serve,
/// l'output è già formattato per essere incollato in un bug report.
class CrashReporter {
  static const _kKey = 'crash_log';
  static const _kMaxEntries = 50; // Ring buffer semplice

  static SharedPreferences? _prefs;
  static bool _installed = false;

  /// Buffer pre-init: errori raccolti prima che SharedPreferences sia pronto.
  /// Appena `_prefs` si inizializza, vengono flushati su disco.
  static final List<String> _pendingEntries = <String>[];

  /// Write chain — serializza `setStringList` per evitare che scritture
  /// concorrenti su crash-burst si sovrascrivano (last-writer-wins).
  static Future<void> _writeChain = Future.value();

  /// Installa gli handler globali. Chiamare dentro `runZonedGuarded` in main.
  static Future<void> install() async {
    if (_installed) return;
    _installed = true;

    // Errori del framework Flutter (build, layout, paint, gesture, ...)
    final previousFlutterOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      _record('flutter', details.exceptionAsString(), details.stack);
      previousFlutterOnError?.call(details);
    };

    // Errori async non catturati fuori dal framework. Chain dell'handler
    // precedente (se qualche package ne ha installato uno prima di noi).
    final previousPlatformOnError = PlatformDispatcher.instance.onError;
    PlatformDispatcher.instance.onError = (error, stack) {
      _record('platform', error.toString(), stack);
      // Se `_prefs` non è ancora pronto, NON swallowiamo: app preferisce
      // crash hard a silent-drop di errori fatali non persistiti.
      if (_prefs == null) {
        return previousPlatformOnError?.call(error, stack) ?? false;
      }
      // Honor upstream: se un handler precedente esiste, rispetta la sua
      // decisione (true=swallow, false=fatal). Default `false` se nessuno
      // chained: crash recorder registra l'errore ma non deve impedire al
      // platform di terminare l'app per errori fatali non gestiti altrimenti.
      return previousPlatformOnError?.call(error, stack) ?? false;
    };

    // Ora inizializza prefs: errori precedenti sono in `_pendingEntries`
    _prefs = await SharedPreferences.getInstance();
    if (_pendingEntries.isNotEmpty) {
      _flushPending();
    }
  }

  /// Handler per `runZonedGuarded` (errori Dart zone-based).
  static void handleZoneError(Object error, StackTrace stack) {
    _record('zone', error.toString(), stack);
  }

  static void _record(String source, String message, StackTrace? stack) {
    try {
      final timestamp = DateTime.now().toIso8601String();
      final entry = '[$timestamp][$source] $message\n${stack ?? ''}'.trim();
      if (kDebugMode) {
        debugPrint('CRASH[$source]: $message');
      }
      // Se prefs non pronto, bufferizza — flush al termine di `install()`.
      if (_prefs == null) {
        _pendingEntries.add(entry);
        if (_pendingEntries.length > _kMaxEntries) {
          _pendingEntries.removeRange(0, _pendingEntries.length - _kMaxEntries);
        }
        return;
      }
      // Serializza via _writeChain: burst di errori concorrenti rispettano
      // l'ordine invece di sovrascriversi (last-writer-wins).
      _writeChain = _writeChain
          .then((_) async {
            final existing = _prefs!.getStringList(_kKey) ?? <String>[];
            existing.add(entry);
            if (existing.length > _kMaxEntries) {
              existing.removeRange(0, existing.length - _kMaxEntries);
            }
            await _prefs!.setStringList(_kKey, existing);
          })
          .catchError(
            (_) {},
          ); // Swallow errori catena (crash recorder non deve crashare).
      unawaited(_writeChain);
    } catch (_) {
      // Recorder che crasha sarebbe un loop infinito — silenzia.
    }
  }

  static void _flushPending() {
    try {
      final flush = List<String>.from(_pendingEntries);
      _pendingEntries.clear();
      _writeChain = _writeChain
          .then((_) async {
            final existing = _prefs?.getStringList(_kKey) ?? <String>[];
            existing.addAll(flush);
            if (existing.length > _kMaxEntries) {
              existing.removeRange(0, existing.length - _kMaxEntries);
            }
            await _prefs?.setStringList(_kKey, existing);
          })
          .catchError((_) {});
      unawaited(_writeChain);
    } catch (_) {}
  }

  /// Lista dei crash log raccolti (più recente per ultimo).
  static List<String> getLogs() {
    return _prefs?.getStringList(_kKey) ?? const [];
  }

  /// Cancella i log (usato da Settings → Reset).
  static Future<void> clear() async {
    await _prefs?.remove(_kKey);
  }
}
