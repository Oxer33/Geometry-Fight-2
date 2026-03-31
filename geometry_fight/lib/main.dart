import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'data/save_data.dart';
import 'data/leaderboard.dart';
import 'data/achievements.dart';
import 'data/difficulty.dart';
import 'ui/screens/main_menu.dart';
import 'ui/screens/game_screen.dart';
import 'ui/screens/shop_screen.dart';
import 'ui/screens/settings_screen.dart';
import 'ui/screens/mode_select_screen.dart';
import 'ui/screens/leaderboard_screen.dart';
import 'ui/screens/splash_screen.dart';
import 'ui/screens/stats_screen.dart';
import 'ui/screens/achievements_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Force landscape and fullscreen
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  // Initialize Hive per save data e leaderboard
  try {
    await Hive.initFlutter();
    await SaveManager.init();
    await LeaderboardManager.init();
    await AchievementManager.init();
  } catch (_) {
    // Se Hive fallisce (dati corrotti), cancella e riprova
    await Hive.deleteFromDisk();
    await Hive.initFlutter();
    await SaveManager.init();
    await LeaderboardManager.init();
    await AchievementManager.init();
  }

  runApp(const GeometryFightApp());
}

class GeometryFightApp extends StatelessWidget {
  const GeometryFightApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Geometry Fight',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
      ),
      home: const NavigationWrapper(),
    );
  }
}

enum AppScreen { splash, mainMenu, modeSelect, game, shop, settings, leaderboard, stats, achievements }

class NavigationWrapper extends StatefulWidget {
  const NavigationWrapper({super.key});

  @override
  State<NavigationWrapper> createState() => _NavigationWrapperState();
}

class _NavigationWrapperState extends State<NavigationWrapper> {
  AppScreen _currentScreen = AppScreen.splash;

  // Parametri di gioco selezionati
  Difficulty _selectedDifficulty = Difficulty.normal;
  GameMode _selectedMode = GameMode.classic;

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
          onStart: (mode, difficulty) {
            _selectedMode = mode;
            _selectedDifficulty = difficulty;
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
