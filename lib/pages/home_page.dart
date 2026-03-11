import 'package:flutter/material.dart';
import 'workout_page.dart';
import 'history_page.dart';
import 'progress_page.dart';
import 'settings_page.dart';

class HomePage extends StatefulWidget {
const HomePage({super.key});

@override
State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
int currentIndex = 0;

final List<Widget> pages = [
WorkoutPage(),
HistoryPage(),
ProgressPage(),
SettingsPage(),
];

@override
Widget build(BuildContext context) {
return Scaffold(
body: IndexedStack(
index: currentIndex,
children: pages,
),
bottomNavigationBar: BottomNavigationBar(
currentIndex: currentIndex,
type: BottomNavigationBarType.fixed,
backgroundColor: const Color(0xFF111325),
selectedItemColor: Colors.white,
unselectedItemColor: Colors.white54,
onTap: (index) {
setState(() {
currentIndex = index;
});
},
items: const [
BottomNavigationBarItem(
icon: Icon(Icons.fitness_center),
label: 'Workout',
),
BottomNavigationBarItem(
icon: Icon(Icons.history),
label: 'History',
),
BottomNavigationBarItem(
icon: Icon(Icons.show_chart),
label: 'Progress',
),
BottomNavigationBarItem(
icon: Icon(Icons.settings),
label: 'Settings',
),
],
),
);
}
}
