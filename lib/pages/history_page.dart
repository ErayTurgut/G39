import 'package:flutter/material.dart';
import '../services/isar_service.dart';
import '../models/workout_model.dart';
import 'workout_detail_page.dart';
import 'active_workout_page.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {

  late Stream<void> historyStream;

  @override
  void initState() {
    super.initState();

    historyStream =
        IsarService.isar.workouts.watchLazy(fireImmediately: true);
  }

  Future<List<Workout>> _loadWorkouts() async {
    return await IsarService.getWorkouts();
  }

  /* ================= RENAME ================= */

  void _renameWorkout(BuildContext context, Workout workout) {

    final controller = TextEditingController(text: workout.name);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Rename Workout"),
        content: TextField(controller: controller),
        actions: [

          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),

          ElevatedButton(
            child: const Text("Save"),
            onPressed: () async {

              await IsarService.isar.writeTxn(() async {

                workout.name = controller.text;
                await IsarService.isar.workouts.put(workout);

              });

              if (context.mounted) Navigator.pop(context);

            },
          ),
        ],
      ),
    );
  }

  /* ================= DELETE ================= */

  void _deleteWorkout(BuildContext context, Workout workout) {

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Workout"),
        content: const Text("Are you sure?"),
        actions: [

          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),

          ElevatedButton(
            child: const Text("Delete"),
            onPressed: () async {

              await IsarService.isar.writeTxn(() async {
                await IsarService.isar.workouts.delete(workout.id);
              });

              if (context.mounted) Navigator.pop(context);

            },
          ),
        ],
      ),
    );
  }

  /* ================= REPEAT WORKOUT ================= */

  Future<void> _repeatWorkout(
      BuildContext context,
      Workout oldWorkout,
  ) async {

    final newWorkout = Workout()
      ..name = oldWorkout.name
      ..date = DateTime.now()
      ..isFavorite = false;

    newWorkout.exercises = oldWorkout.exercises.map((oldExercise) {

      final newExercise = Exercise()
        ..name = oldExercise.name
        ..region = oldExercise.region;

      newExercise.sets = oldExercise.sets.map((oldSet) {

        return ExerciseSet()
          ..kg = oldSet.kg
          ..reps = oldSet.reps
          ..rpe = oldSet.rpe
          ..isCompleted = false;

      }).toList();

      return newExercise;

    }).toList();

    await IsarService.saveWorkout(newWorkout);

    if (!mounted) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ActiveWorkoutPage(
          workout: newWorkout,
          autoStart: true,
        ),
      ),
    );
  }

  /* ================= FAVORITE ================= */

  Future<void> _toggleFavorite(Workout workout) async {

    await IsarService.isar.writeTxn(() async {

      workout.isFavorite = !workout.isFavorite;
      await IsarService.isar.workouts.put(workout);

    });

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        title: const Text("History"),
      ),

      body: StreamBuilder<void>(

        stream: historyStream,

        builder: (context, snapshot) {

          return FutureBuilder<List<Workout>>(

            future: _loadWorkouts(),

            builder: (context, snap) {

              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(
                    child: CircularProgressIndicator());
              }

              final workouts = snap.data ?? [];

              if (workouts.isEmpty) {
                return const Center(
                    child: Text("No workouts yet"));
              }

              return ListView.builder(

                itemCount: workouts.length,

                itemBuilder: (context, index) {

                  final w = workouts[index];

                  return Card(

                    margin: const EdgeInsets.all(8),

                    child: ListTile(

                      title: Text(w.name),

                      subtitle: Text(w.date.toString()),

                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [

                          IconButton(
                            icon: Icon(
                              w.isFavorite
                                  ? Icons.star
                                  : Icons.star_border,
                              color: w.isFavorite
                                  ? Colors.amber
                                  : Colors.grey,
                            ),
                            onPressed: () => _toggleFavorite(w),
                          ),

                          PopupMenuButton<String>(

                            onSelected: (val) {

                              if (val == 'repeat') {
                                _repeatWorkout(context, w);
                              }

                              else if (val == 'rename') {
                                _renameWorkout(context, w);
                              }

                              else if (val == 'delete') {
                                _deleteWorkout(context, w);
                              }

                            },

                            itemBuilder: (_) => const [

                              PopupMenuItem(
                                value: 'repeat',
                                child: Text("Repeat Workout"),
                              ),

                              PopupMenuItem(
                                value: 'rename',
                                child: Text("Rename"),
                              ),

                              PopupMenuItem(
                                value: 'delete',
                                child: Text("Delete"),
                              ),

                            ],

                          ),

                        ],
                      ),

                      onTap: () {

                        final freshWorkout =
                            IsarService.isar.workouts.getSync(w.id);

                        if (freshWorkout == null) return;

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                WorkoutDetailPage(workout: freshWorkout),
                          ),
                        );

                      },
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}