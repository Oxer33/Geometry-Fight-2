import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'data/save_data.dart';
import 'data/crash_reporter.dart';
import 'game/systems/audio_system.dart';
import 'game/systems/music_manager.dart';
import 'data/leaderboard.dart';
import 'data/achievements.dart';
import 'data/difficulty.dart';
import 'ui/screens/main_menu.dart';
import 'ui/screens/game_screen.dart';
import 'ui/screens/shop_screen.dart';
import 'ui/screens/settings_screen.dart';
import 'ui/screens/mode_select_screen.dart';
import 'ui/screens/difficulty_select_screen.dart';
import 'ui/screens/modifiers_select_screen.dart';
import 'ui/screens/loadout_screen.dart';
import 'ui/screens/summary_screen.dart';
import 'ui/screens/leaderboard_screen.dart';
import 'ui/screens/splash_screen.dart';
import 'ui/screens/stats_screen.dart';
import 'ui/screens/achievements_screen.dart';

void main() async {
  // runZonedGuarded cattura anche errori async non catturati; CrashReporter
  // copre inoltre FlutterError.onError e PlatformDispatcher.onError.
  // Obiettivo: capire i crash sporadici del gioco (loggati in
  // shared_preferences → visibili in Settings → Debug).
  await runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    await CrashReporter.install();

    // Force landscape and fullscreen
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    // Initialize Hive per save data e leaderboard.
    // Selettivo: se una singola box è corrotta, wipe SOLO quella (non butto
    // via tutto il progresso utente). Fallback generale `deleteFromDisk`
    // solo se `Hive.initFlutter()` stesso fallisce (problema a monte).
    try {
      await Hive.initFlutter();
    } catch (e, st) {
      CrashReporter.handleZoneError(e, st);
      try {
        await Hive.deleteFromDisk();
        await Hive.initFlutter();
      } catch (e2, st2) {
        CrashReporter.handleZoneError(e2, st2);
        rethrow;
      }
    }

    Future<void> initOrResetBox(
      String boxName,
      Future<void> Function() initFn,
    ) async {
      try {
        await initFn();
      } catch (e, st) {
        CrashReporter.handleZoneError(e, st);
        try {
          await Hive.deleteBoxFromDisk(boxName);
          await initFn();
        } catch (e2, st2) {
          CrashReporter.handleZoneError(e2, st2);
          rethrow;
        }
      }
    }

    await initOrResetBox('geometry_fight_save', SaveManager.init);
    await initOrResetBox('geometry_fight_leaderboard', LeaderboardManager.init);
    await initOrResetBox(
        'geometry_fight_achievements', AchievementManager.init);

    // Initialize audio system (SFX) + music manager (BGM)
    await AudioSystem.init();
    await MusicManager.init();
    // Load SFX volume from prefs
    final prefs = await SharedPreferences.getInstance();
    AudioSystem.setSfxVolume(prefs.getDouble('sfx_volume') ?? 0.8);
    AudioSystem.setBgmVolume(prefs.getDouble('bgm_volume') ?? 0.7);
    AudioSystem.setVibration(prefs.getBool('vibration') ?? true);
    // Avvia musica intro: una delle 3 tracce intro a random
    unawaited(MusicManager.playIntro());

    runApp(const GeometryFightApp());
  }, CrashReporter.handleZoneError);
}

class GeometryFightApp extends StatelessWidget {
  const GeometryFightApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Geometry Fight',
      debugShowCheckedModeBanner: false,
      // color: background a livello OS/task-switcher durante launch
      // + fallback se theme non si applica ancora.
      color: Colors.black,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
        canvasColor: Colors.black,
      ),
      home: const NavigationWrapper(),
    );
  }
}

enum AppScreen {
  splash,
  mainMenu,
  // Pre-game wizard 5 step (richiesta utente: schermate dedicate).
  modeSelect,        // 1/5 — solo modalità + scroll arrow
  difficultySelect,  // 2/5 — solo difficoltà
  modifiersSelect,   // 3/5 — solo modificatori
  loadout,           // 4/5 — arma + pet (2 step interno)
  summary,           // 5/5 — riepilogo + multipliers + START
  game,
  shop,
  settings,
  leaderboard,
  stats,
  achievements,
}

class NavigationWrapper extends StatefulWidget {
  const NavigationWrapper({super.key});

  @override
  State<NavigationWrapper> createState() => _NavigationWrapperState();
}

class _NavigationWrapperState extends State<NavigationWrapper> {
  AppScreen _currentScreen = AppScreen.splash;

  // Parametri di gioco selezionati durante il wizard pre-game.
  // Persistono in memoria attraverso le 5 step screens.
  Difficulty _selectedDifficulty = Difficulty.normal;
  GameMode _selectedMode = GameMode.classic;
  // Defensive `<String>[]` invece di `const []`: una const list non sarebbe
  // modificabile in-place se qualche callback futuro tentasse `add/remove`
  // invece di reassign. Evita "Unsupported operation" runtime error.
  List<String> _selectedModifiers = <String>[];

  void _navigateTo(AppScreen screen) {
    setState(() => _currentScreen = screen);
  }

  @override
  Widget build(BuildContext context) {
    // Container nero costante per evitare flash bianchi durante le transizioni
    return Container(
      color: Colors.black,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 350),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        transitionBuilder: (child, animation) {
          // No transition for splash/game (they have their own animations)
          final key = (child.key as ValueKey?)?.value;
          if (key == 'splash' || key == 'game') {
            return child;
          }
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.0, 0.03),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          );
        },
        child: _buildScreen(),
      ),
    );
  }

  Widget _buildScreen() {
    switch (_currentScreen) {
      case AppScreen.splash:
        return SplashScreen(
          key: const ValueKey('splash'),
          onComplete: () => _navigateTo(AppScreen.mainMenu),
        );
      case AppScreen.mainMenu:
        return MainMenuScreen(
          key: const ValueKey('mainMenu'),
          onPlay: () => _navigateTo(AppScreen.modeSelect),
          onShop: () => _navigateTo(AppScreen.shop),
          onSettings: () => _navigateTo(AppScreen.settings),
          onLeaderboard: () => _navigateTo(AppScreen.leaderboard),
          onStats: () => _navigateTo(AppScreen.stats),
          onAchievements: () => _navigateTo(AppScreen.achievements),
        );
      case AppScreen.modeSelect:
        return ModeSelectScreen(
          key: const ValueKey('modeSelect'),
          onBack: () => _navigateTo(AppScreen.mainMenu),
          onConfirm: (mode) {
            // Step 1/5 → 2/5 difficoltà.
            // Pacifist: skip difficulty (combo Pacifist+Nightmare = unwinnable
            // perché drone speed ×1.5, player no shoot, lives=1). Forziamo
            // Normal e saltiamo direttamente a modifiersSelect.
            setState(() {
              _selectedMode = mode;
              if (mode == GameMode.pacifist) {
                _selectedDifficulty = Difficulty.normal;
                _selectedModifiers = <String>[];
              }
            });
            if (mode == GameMode.pacifist) {
              _navigateTo(AppScreen.modifiersSelect);
            } else {
              _navigateTo(AppScreen.difficultySelect);
            }
          },
        );
      case AppScreen.difficultySelect:
        return DifficultySelectScreen(
          key: const ValueKey('difficultySelect'),
          initial: _selectedDifficulty,
          mode: _selectedMode,
          onBack: () => _navigateTo(AppScreen.modeSelect),
          onConfirm: (diff) {
            // Step 2/5 → 3/5 modificatori.
            setState(() => _selectedDifficulty = diff);
            // Modifier list parte VUOTA ogni partita (utente: "me ne
            // ritrovo 3 preselezionati sempre"). Sticky behavior precedente
            // (load da saveData.activeModifiers) confondeva: utente vedeva
            // mods scelti in partita precedente già attivi e doveva
            // deselezionarli. Reset a [] = scelta esplicita ogni game.
            _selectedModifiers = <String>[];
            _navigateTo(AppScreen.modifiersSelect);
          },
        );
      case AppScreen.modifiersSelect:
        return ModifiersSelectScreen(
          key: const ValueKey('modifiersSelect'),
          initial: _selectedModifiers,
          mode: _selectedMode,
          // Pacifist: difficulty step skipped → back va direttamente a mode.
          onBack: () => _navigateTo(_selectedMode == GameMode.pacifist
              ? AppScreen.modeSelect
              : AppScreen.difficultySelect),
          onConfirm: (mods) {
            // Step 3/5 → 4/5 loadout.
            // Pacifist: skip loadout (no shooting → arma irrilevante; pet
            // disabilitato in game_world). Vai diretto a summary.
            setState(() => _selectedModifiers = mods);
            if (_selectedMode == GameMode.pacifist) {
              _navigateTo(AppScreen.summary);
            } else {
              _navigateTo(AppScreen.loadout);
            }
          },
        );
      case AppScreen.loadout:
        return LoadoutScreen(
          key: const ValueKey('loadout'),
          onBack: () => _navigateTo(AppScreen.modifiersSelect),
          onConfirm: () => _navigateTo(AppScreen.summary),
        );
      case AppScreen.summary:
        return SummaryScreen(
          key: const ValueKey('summary'),
          mode: _selectedMode,
          difficulty: _selectedDifficulty,
          activeModifiers: _selectedModifiers,
          // Pacifist: loadout skipped → back va a modifiersSelect.
          onBack: () => _navigateTo(_selectedMode == GameMode.pacifist
              ? AppScreen.modifiersSelect
              : AppScreen.loadout),
          onStart: () async {
            // Persist modifiers in saveData prima del game start: GameWorld
            // li legge da `saveData.activeModifiers` in onLoad.
            // Try/catch difensivo: se SaveManager.save fallisce (Hive lock,
            // disk full), non blocchiamo navigazione → game parte comunque
            // con i modifiers in memory (saveData ricaricato in onLoad
            // ricaderà sui vecchi valori se save fallita, accettabile).
            try {
              final sd = SaveManager.load();
              sd.activeModifiers = _selectedModifiers;
              await SaveManager.save(sd);
            } catch (_) {}
            if (!mounted) return;
            _navigateTo(AppScreen.game);
          },
        );
      case AppScreen.game:
        return GameScreen(
          key: const ValueKey('game'),
          onQuit: () => _navigateTo(AppScreen.mainMenu),
          difficulty: _selectedDifficulty,
          gameMode: _selectedMode,
        );
      case AppScreen.shop:
        return ShopScreen(
          key: const ValueKey('shop'),
          onBack: () => _navigateTo(AppScreen.mainMenu),
        );
      case AppScreen.settings:
        return SettingsScreen(
          key: const ValueKey('settings'),
          onBack: () => _navigateTo(AppScreen.mainMenu),
        );
      case AppScreen.leaderboard:
        return LeaderboardScreen(
          key: const ValueKey('leaderboard'),
          onBack: () => _navigateTo(AppScreen.mainMenu),
        );
      case AppScreen.stats:
        return StatsScreen(
          key: const ValueKey('stats'),
          onBack: () => _navigateTo(AppScreen.mainMenu),
        );
      case AppScreen.achievements:
        return AchievementsScreen(
          key: const ValueKey('achievements'),
          onBack: () => _navigateTo(AppScreen.mainMenu),
        );
    }
  }
}
