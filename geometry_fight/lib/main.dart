import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'data/save_data.dart';
import 'data/leaderboard.dart';
import 'data/difficulty.dart';
import 'ui/screens/main_menu.dart';
import 'ui/screens/game_screen.dart';
import 'ui/screens/shop_screen.dart';
import 'ui/screens/settings_screen.dart';
import 'ui/screens/mode_select_screen.dart';
import 'ui/screens/leaderboard_screen.dart';
import 'ui/screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Force landscape and fullscreen
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  // Initialize Hive per save data e leaderboard
  await Hive.initFlutter();
  await SaveManager.init();
  await LeaderboardManager.init();

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

enum AppScreen { splash, mainMenu, modeSelect, game, shop, settings, leaderboard }

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
    switch (_currentScreen) {
      case AppScreen.splash:
        return SplashScreen(
          onComplete: () => _navigateTo(AppScreen.mainMenu),
        );
      case AppScreen.mainMenu:
        return MainMenuScreen(
          onPlay: () => _navigateTo(AppScreen.modeSelect),
          onShop: () => _navigateTo(AppScreen.shop),
          onSettings: () => _navigateTo(AppScreen.settings),
          onLeaderboard: () => _navigateTo(AppScreen.leaderboard),
        );
      case AppScreen.modeSelect:
        return ModeSelectScreen(
          onBack: () => _navigateTo(AppScreen.mainMenu),
          onStart: (mode, difficulty) {
            _selectedMode = mode;
            _selectedDifficulty = difficulty;
            _navigateTo(AppScreen.game);
          },
        );
      case AppScreen.game:
        return GameScreen(
          onQuit: () => _navigateTo(AppScreen.mainMenu),
          difficulty: _selectedDifficulty,
          gameMode: _selectedMode,
        );
      case AppScreen.shop:
        return ShopScreen(
          onBack: () => _navigateTo(AppScreen.mainMenu),
        );
      case AppScreen.settings:
        return SettingsScreen(
          onBack: () => _navigateTo(AppScreen.mainMenu),
        );
      case AppScreen.leaderboard:
        return LeaderboardScreen(
          onBack: () => _navigateTo(AppScreen.mainMenu),
        );
    }
  }
}
