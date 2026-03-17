import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'data/save_data.dart';
import 'ui/screens/main_menu.dart';
import 'ui/screens/game_screen.dart';
import 'ui/screens/shop_screen.dart';
import 'ui/screens/settings_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Force landscape and fullscreen
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  // Initialize Hive
  await Hive.initFlutter();
  await SaveManager.init();

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

enum AppScreen { mainMenu, game, shop, settings }

class NavigationWrapper extends StatefulWidget {
  const NavigationWrapper({super.key});

  @override
  State<NavigationWrapper> createState() => _NavigationWrapperState();
}

class _NavigationWrapperState extends State<NavigationWrapper> {
  AppScreen _currentScreen = AppScreen.mainMenu;

  void _navigateTo(AppScreen screen) {
    setState(() => _currentScreen = screen);
  }

  @override
  Widget build(BuildContext context) {
    switch (_currentScreen) {
      case AppScreen.mainMenu:
        return MainMenuScreen(
          onPlay: () => _navigateTo(AppScreen.game),
          onShop: () => _navigateTo(AppScreen.shop),
          onSettings: () => _navigateTo(AppScreen.settings),
        );
      case AppScreen.game:
        return GameScreen(
          onQuit: () => _navigateTo(AppScreen.mainMenu),
        );
      case AppScreen.shop:
        return ShopScreen(
          onBack: () => _navigateTo(AppScreen.mainMenu),
        );
      case AppScreen.settings:
        return SettingsScreen(
          onBack: () => _navigateTo(AppScreen.mainMenu),
        );
    }
  }
}
