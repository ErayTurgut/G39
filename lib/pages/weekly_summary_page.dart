import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/isar_service.dart';
import '../models/workout_model.dart';
import '../services/app_settings.dart';

class WeeklySummaryPage extends StatefulWidget {
  const WeeklySummaryPage({super.key});

  @override
  State<WeeklySummaryPage> createState() => _WeeklySummaryPageState();
}

class _WeeklySummaryPageState extends State<WeeklySummaryPage> {
  int workoutCount = 0;
  int totalSets = 0;
  double totalVolume = 0;
  String mostWorkedRegion = "";
  double strongestLift = 0;
  String strongestExercise = "";

  int streak = 0;

  double _calculate1RM(double kg, int reps) {
    return kg * (1 + reps / 30);
  }

  DateTime _startOfWeek(DateTime date) {
    return date.subtract(Duration(days: date.weekday - 1));
  }

  bool _sameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Future<void> _calculateWeeklyStats() async {
    final workouts = await IsarService.getWorkoutsAsc();

    final now = DateTime.now();
    final weekStart = _startOfWeek(now);
    final weekEnd = weekStart.add(const Duration(days: 7));

    final Map<String, int> regionCount = {};

    for (var w in workouts) {
      if (w.date.isAfter(weekStart) && w.date.isBefore(weekEnd)) {
        workoutCount++;

        for (var ex in w.exercises) {
          regionCount[ex.region] = (regionCount[ex.region] ?? 0) + 1;

          for (var s in ex.sets) {
            if (!s.isCompleted) continue;

            totalSets++;
            totalVolume += s.kg * s.reps;

            final oneRM = _calculate1RM(s.kg, s.reps);

            if (oneRM > strongestLift) {
              strongestLift = oneRM;
              strongestExercise = ex.name;
            }
          }
        }
      }
    }

    if (regionCount.isNotEmpty) {
      mostWorkedRegion =
          regionCount.entries.reduce((a, b) => a.value > b.value ? a : b).key;
    }

    _calculateStreak(workouts);

    setState(() {});
  }

  void _calculateStreak(List<Workout> workouts) {
    if (workouts.isEmpty) return;

    workouts.sort((a, b) => b.date.compareTo(a.date));

    DateTime checkDate = DateTime.now();

    for (var w in workouts) {
      if (_sameDay(w.date, checkDate) ||
          _sameDay(w.date, checkDate.subtract(const Duration(days: 1)))) {
        streak++;
        checkDate = w.date.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _calculateWeeklyStats();
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettings>();
    final goal = settings.weeklyGoal;
    final progress = workoutCount / goal;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Weekly Summary"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: workoutCount == 0
            ? const Center(child: Text("Bu hafta veri yok"))
            : ListView(
                children: [

                  Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        "🔥 $streak Day Streak",
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),

                  _StatCard(
                    "Weekly Goal",
                    "$workoutCount / $goal workouts",
                  ),

                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: LinearProgressIndicator(
                      value: progress > 1 ? 1 : progress,
                    ),
                  ),

                  _StatCard("Workout Count", "$workoutCount"),
                  _StatCard("Total Sets", "$totalSets"),
                  _StatCard("Total Volume",
                      "${totalVolume.toStringAsFixed(0)} kg"),
                  _StatCard("Most Worked Region", mostWorkedRegion),

                  _StatCard(
                    "Strongest Lift",
                    strongestLift > 0
                        ? "$strongestExercise\n${strongestLift.toStringAsFixed(1)} kg (1RM)"
                        : "-",
                  ),
                ],
              ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;

  const _StatCard(this.title, this.value);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Text(value,
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}