import 'package:flutter/material.dart';
import '../models/workout_model.dart';
import '../services/isar_service.dart';
import 'active_workout_page.dart';
import 'workout_detail_page.dart';

class WorkoutTab extends StatefulWidget {
  const WorkoutTab({super.key});

  @override
  State<WorkoutTab> createState() => _WorkoutTabState();
}

class _WorkoutTabState extends State<WorkoutTab> {
  late Stream<void> workoutStream;

  @override
  void initState() {
    super.initState();
    workoutStream =
        IsarService.isar.workouts.watchLazy(fireImmediately: true);
  }

  Future<List<Workout>> _loadFavorites() async {
    final all = await IsarService.getWorkouts();
    return all.where((w) => w.isFavorite).toList();
  }

  /* ================= NEW WORKOUT ================= */

  void _startWorkoutDialog() {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text("Antreman İsmi"),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: "Örn: Push Day",
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text("İptal"),
            ),
            ElevatedButton(
              onPressed: () {
                if (controller.text.isEmpty) return;

                final workout = Workout()
                  ..name = controller.text
                  ..date = DateTime.now();

                Navigator.pop(dialogContext);

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        ActiveWorkoutPage(workout: workout),
                  ),
                );
              },
              child: const Text("Başlat"),
            ),
          ],
        );
      },
    );
  }

  /* ================= REPEAT FAVORITE ================= */

  Future<void> _repeatFavoriteWorkout(Workout template) async {
    final newWorkout = Workout()
      ..name = template.name
      ..date = DateTime.now()
      ..isFavorite = false;

    // Deep copy exercises
    newWorkout.exercises = template.exercises.map((oldExercise) {
      final newExercise = Exercise()
        ..name = oldExercise.name
        ..region = oldExercise.region;

      newExercise.sets = oldExercise.sets.map((oldSet) {
        return ExerciseSet()
          ..kg = oldSet.kg
          ..reps = oldSet.reps
          ..isCompleted = false;
      }).toList();

      return newExercise;
    }).toList();

    await IsarService.saveWorkout(newWorkout);

    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ActiveWorkoutPage(
          workout: newWorkout,
          autoStart: true,
        ),
      ),
    );
  }

  /* ================= UI ================= */

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Workout")),
      body: StreamBuilder<void>(
        stream: workoutStream,
        builder: (context, snapshot) {
          return FutureBuilder<List<Workout>>(
            future: _loadFavorites(),
            builder: (context, snap) {
              final favorites = snap.data ?? [];

              return Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 60,
                      child: ElevatedButton(
                        onPressed: _startWorkoutDialog,
                        child: const Text(
                          "ANTREMANA BAŞLA",
                          style: TextStyle(fontSize: 18),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Favori Antremanlar",
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: favorites.isEmpty
                          ? const Center(
                              child: Text("Henüz favori yok"),
                            )
                          : ListView.builder(
                              itemCount: favorites.length,
                              itemBuilder: (context, index) {
                                final fav = favorites[index];

                                return Card(
                                  child: ListTile(
                                    leading: const Icon(
                                      Icons.star,
                                      color: Colors.amber,
                                    ),
                                    title: Text(fav.name),
                                    subtitle:
                                        Text(fav.date.toString()),
                                    trailing: const Icon(
                                        Icons.play_arrow),
                                    onTap: () =>
                                        _repeatFavoriteWorkout(fav),
                                    onLongPress: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              WorkoutDetailPage(
                                                  workout: fav),
                                        ),
                                      );
                                    },
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}