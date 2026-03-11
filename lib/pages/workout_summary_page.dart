import 'package:flutter/material.dart';
import '../models/workout_model.dart';
import '../services/isar_service.dart';

class WorkoutSummaryPage extends StatefulWidget {
  final Workout workout;
  final int totalSeconds;

  const WorkoutSummaryPage({
    super.key,
    required this.workout,
    required this.totalSeconds,
  });

  @override
  State<WorkoutSummaryPage> createState() => _WorkoutSummaryPageState();
}

class _WorkoutSummaryPageState extends State<WorkoutSummaryPage> {

  double strongestToday = 0;
  String strongestExerciseToday = "";

  double lifetimeStrongest = 0;
  String lifetimeStrongestExercise = "";

  int lifetimePRCount = 0;

  bool _isDisposed = false;

  double _calculate1RM(double kg, int reps) {
    return kg * (1 + reps / 30);
  }

  Future<void> _calculateStats() async {

    final workouts = await IsarService.getWorkoutsAsc();

    if (!mounted || _isDisposed) return;

    final Map<String,double> bestPerExercise = {};

    double globalStrongest = 0;
    String globalExercise = "";

    for (var w in workouts) {
      for (var ex in w.exercises) {
        for (var s in ex.sets) {

          if (!s.isCompleted) continue;

          final oneRM = _calculate1RM(s.kg, s.reps);

          if (oneRM > globalStrongest) {
            globalStrongest = oneRM;
            globalExercise = ex.name;
          }

          final current = bestPerExercise[ex.name] ?? 0;

          if (oneRM > current) {
            bestPerExercise[ex.name] = oneRM;
          }

        }
      }
    }

    double todayStrongest = 0;
    String todayExercise = "";

    for (var ex in widget.workout.exercises) {
      for (var s in ex.sets) {

        if (!s.isCompleted) continue;

        final oneRM = _calculate1RM(s.kg, s.reps);

        if (oneRM > todayStrongest) {
          todayStrongest = oneRM;
          todayExercise = ex.name;
        }

      }
    }

    if (!mounted || _isDisposed) return;

    setState(() {
      lifetimePRCount = bestPerExercise.length;
      lifetimeStrongest = globalStrongest;
      lifetimeStrongestExercise = globalExercise;

      strongestToday = todayStrongest;
      strongestExerciseToday = todayExercise;
    });

  }

  String _formatTime(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2,'0');
    final s = (seconds % 60).toString().padLeft(2,'0');
    return "$m:$s";
  }

  @override
  void initState() {
    super.initState();
    _calculateStats();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    int totalSets = 0;
    Map<String,int> regionCount = {};

    for (var exercise in widget.workout.exercises) {

      totalSets += exercise.sets.length;

      final region = exercise.region;
      regionCount[region] = (regionCount[region] ?? 0) + 1;

    }

    return Scaffold(

      appBar: AppBar(
        title: const Text("Workout Summary"),
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),

        child: ListView(

          children: [

            Text(
              "Süre: ${_formatTime(widget.totalSeconds)}",
              style: const TextStyle(fontSize:20),
            ),

            const SizedBox(height:8),

            Text(
              "Toplam Set: $totalSets",
              style: const TextStyle(fontSize:20),
            ),

            const SizedBox(height:8),

            Text(
              "Toplam Egzersiz: ${widget.workout.exercises.length}",
              style: const TextStyle(fontSize:20),
            ),

            const SizedBox(height:30),

            if (strongestToday > 0)
              Card(
                color: Colors.orange.withOpacity(0.1),

                child: Padding(
                  padding: const EdgeInsets.all(16),

                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [

                      const Text(
                        "🔥 Strongest Lift Today",
                        style: TextStyle(
                          fontSize:18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height:6),

                      Text(
                        "$strongestExerciseToday\n${strongestToday.toStringAsFixed(1)} kg (1RM)",
                        style: const TextStyle(fontSize:18),
                      ),

                    ],
                  ),
                ),
              ),

            const SizedBox(height:20),

            if (lifetimeStrongest > 0)
              Card(
                color: Colors.blue.withOpacity(0.08),

                child: Padding(
                  padding: const EdgeInsets.all(16),

                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [

                      const Text(
                        "🏆 Lifetime Strongest",
                        style: TextStyle(
                          fontSize:18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height:6),

                      Text(
                        "$lifetimeStrongestExercise\n${lifetimeStrongest.toStringAsFixed(1)} kg (1RM)",
                        style: const TextStyle(fontSize:18),
                      ),

                      const SizedBox(height:8),

                      Text(
                        "Total PR Exercises: $lifetimePRCount",
                        style: const TextStyle(fontSize:16),
                      ),

                    ],
                  ),
                ),
              ),

            const SizedBox(height:30),

            const Text(
              "Exercises",
              style: TextStyle(
                fontSize:22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height:15),

            ...widget.workout.exercises.map((ex) {

              return Card(

                child: Padding(
                  padding: const EdgeInsets.all(12),

                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [

                      Text(
                        ex.name,
                        style: const TextStyle(
                          fontSize:18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height:8),

                      ...ex.sets.map((set) {

                        final index = ex.sets.indexOf(set);

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical:4),

                          child: Row(
                            children: [

                              Text("Set ${index+1}"),

                              const SizedBox(width:12),

                              Text("${set.kg} kg"),

                              const SizedBox(width:12),

                              Text("${set.reps} reps"),

                              const SizedBox(width:12),

                              Text(
                                set.rpe != null
                                    ? "RPE ${set.rpe}"
                                    : "-",
                              ),

                              const SizedBox(width:12),

                              if (set.failure)
                                const Text(
                                  "FAIL",
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),

                            ],
                          ),
                        );

                      }),

                    ],
                  ),
                ),
              );

            }),

            const SizedBox(height:30),

            const Text(
              "Bölge Dağılımı",
              style: TextStyle(
                fontSize:22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height:15),

            ...regionCount.entries.map((entry) {

              return Padding(
                padding: const EdgeInsets.symmetric(vertical:4),

                child: Text(
                  "${entry.key}: ${entry.value}",
                  style: const TextStyle(fontSize:18),
                ),
              );

            }),

            const SizedBox(height:30),

            SizedBox(
              width: double.infinity,

              child: ElevatedButton(

                onPressed: () {
                  if (!context.mounted) return;
                  Navigator.popUntil(context,(route)=>route.isFirst);
                },

                child: const Text("Ana Sayfaya Dön"),
              ),
            ),

          ],

        ),

      ),

    );

  }

}