import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'services/isar_service.dart';
import 'services/app_settings.dart';

import 'pages/workout_tab.dart';
import 'pages/history_page.dart';
import 'pages/progress_page.dart';
import 'pages/settings_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await IsarService.init();

  runApp(
    ChangeNotifierProvider(
      create: (_) => AppSettings(),
      child: const FitnessApp(),
    ),
  );
}

/* ========================================================= */
/* ================= THEMES ================================= */
/* ========================================================= */

final ThemeData _darkTheme = ThemeData(
  brightness: Brightness.dark,
  scaffoldBackgroundColor: const Color(0xFF0A0B10),
  useMaterial3: true,
);

final ThemeData _lightTheme = ThemeData(
  brightness: Brightness.light,
  scaffoldBackgroundColor: Colors.white,
  useMaterial3: true,
);

/* ========================================================= */
/* ================= APP ROOT =============================== */
/* ========================================================= */

class FitnessApp extends StatelessWidget {
  const FitnessApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettings>();

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: settings.darkMode ? _darkTheme : _lightTheme,
      home: const MainPage(), // 🔥 Splash kaldırıldı
    );
  }
}

/* ========================================================= */
/* ================= MAIN PAGE ============================== */
/* ========================================================= */

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int currentIndex = 0;

  final List<Widget> pages = const [
    WorkoutTab(),
    HistoryPage(),
    ProgressPage(),
    SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: IndexedStack(
        index: currentIndex,
        children: pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        selectedItemColor: theme.colorScheme.primary,
        unselectedItemColor: Colors.grey,
        onTap: (index) => setState(() => currentIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.fitness_center),
            label: "Workout",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: "History",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.show_chart),
            label: "Progress",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: "Personalize",
          ),
        ],
      ),
    );
  }
}