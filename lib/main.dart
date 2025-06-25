import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:speedy/providers/provider.dart';
import 'package:speedy/screens/setting_screen.dart';
import 'services/auto_test_service.dart';
import 'screens/speed_test_screen.dart';
import 'screens/history_screen.dart';
import 'screens/map_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final preferencesProvider = PreferencesProvider();
  await preferencesProvider.loadPreferences();

  runApp(MyApp(preferencesProvider: preferencesProvider));
}

class MyApp extends StatelessWidget {
  final PreferencesProvider preferencesProvider;

  const MyApp({super.key, required this.preferencesProvider});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: preferencesProvider,
      child: Consumer<PreferencesProvider>(
        builder: (context, prefs, child) {
          return MaterialApp(
            title: "Speed Test",
            debugShowCheckedModeBanner: false,
            themeMode: prefs.themeMode,
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.cyanAccent,
                brightness: Brightness.light,
              ),
              appBarTheme: AppBarTheme(centerTitle: true),
              useMaterial3: true,
            ),
            darkTheme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.cyanAccent,
                brightness: Brightness.dark,
              ),
              appBarTheme: AppBarTheme(centerTitle: true),
              useMaterial3: true,
            ),
            home: MainScreen(),
          );
        },
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with WidgetsBindingObserver {
  int _currentIndex = 0;
  late final AutoTestService _autoTestService;

  final List<Widget> _screens = [
    SpeedTestScreen(),
    MapScreen(),
    HistoryScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _autoTestService = AutoTestService();
    _initializeAutoTest();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _autoTestService.stopAutoTest();
    super.dispose();
  }

  void _initializeAutoTest() {
    final prefs = Provider.of<PreferencesProvider>(context, listen: false);
    if (prefs.autoTestEnabled) {
      _autoTestService.startAutoTest(prefs.autoTestInterval);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final prefs = Provider.of<PreferencesProvider>(context, listen: false);

    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      // Arrêter les tests automatiques quand l'app est en arrière-plan
        _autoTestService.stopAutoTest();
        break;
      case AppLifecycleState.resumed:
      // Redémarrer les tests automatiques si activés
        if (prefs.autoTestEnabled) {
          _autoTestService.startAutoTest(prefs.autoTestInterval);
        }
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PreferencesProvider>(
      builder: (context, prefs, child) {
        // Gérer les changements d'état des tests automatiques
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (prefs.autoTestEnabled && !_autoTestService.isRunning) {
            _autoTestService.startAutoTest(prefs.autoTestInterval);
          } else if (!prefs.autoTestEnabled && _autoTestService.isRunning) {
            _autoTestService.stopAutoTest();
          }
        });

        return Scaffold(
          body: _screens[_currentIndex],
          bottomNavigationBar: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            currentIndex: _currentIndex,
            onTap: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            selectedItemColor: Colors.cyanAccent,
            unselectedItemColor: Colors.grey,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            elevation: 8,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.map),
                label: 'Map',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.history),
                label: 'History',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.settings),
                label: 'Settings',
              ),
            ],
          ),
        );
      },
    );
  }
}