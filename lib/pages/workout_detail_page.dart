import 'package:flutter/material.dart';
import '../models/workout_model.dart';
import '../services/isar_service.dart';

class WorkoutDetailPage extends StatefulWidget {
  final Workout workout;

  const WorkoutDetailPage({super.key, required this.workout});

  @override
  State<WorkoutDetailPage> createState() => _WorkoutDetailPageState();
}

class _WorkoutDetailPageState extends State<WorkoutDetailPage> {

  Future<void> _saveWorkout() async {

    await IsarService.isar.writeTxn(() async {
      await IsarService.isar.workouts.put(widget.workout);
    });

    if (context.mounted) Navigator.pop(context);
  }

  void _addSet(Exercise exercise) {

    setState(() {

      exercise.sets = List.from(exercise.sets);

      exercise.sets.add(
        ExerciseSet()
          ..kg = 0
          ..reps = 0
          ..rpe = null,
      );

    });

  }

  void _deleteSet(Exercise exercise, ExerciseSet set) {

    setState(() {

      exercise.sets = List.from(exercise.sets);
      exercise.sets.remove(set);

    });

  }

  void _deleteExercise(Exercise exercise) async {

    setState(() {

      widget.workout.exercises =
          List.from(widget.workout.exercises);

      widget.workout.exercises.remove(exercise);

    });

    await IsarService.isar.writeTxn(() async {
      await IsarService.isar.workouts.put(widget.workout);
    });

  }

  @override
  Widget build(BuildContext context) {

    final workout = widget.workout;

    return Scaffold(

      appBar: AppBar(

        title: Text(workout.name),

        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveWorkout,
          )
        ],

      ),

      body: ListView(

        children: workout.exercises.map((ex) {

          return Card(

            margin: const EdgeInsets.all(12),

            child: ExpansionTile(

              title: Text(ex.name),

              trailing: IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () => _deleteExercise(ex),
              ),

              children: [

                ...ex.sets.map((s) {

                  return ListTile(

                    title: Row(

                      children: [

                        Expanded(
                          child: TextFormField(
                            initialValue: s.kg == 0
                                ? ""
                                : s.kg.toString(),
                            decoration:
                                const InputDecoration(labelText: "KG"),
                            keyboardType: TextInputType.number,
                            onChanged: (val) {
                              s.kg =
                                  double.tryParse(val) ?? 0;
                            },
                          ),
                        ),

                        const SizedBox(width: 10),

                        Expanded(
                          child: TextFormField(
                            initialValue: s.reps == 0
                                ? ""
                                : s.reps.toString(),
                            decoration:
                                const InputDecoration(labelText: "Reps"),
                            keyboardType: TextInputType.number,
                            onChanged: (val) {
                              s.reps =
                                  int.tryParse(val) ?? 0;
                            },
                          ),
                        ),

                        const SizedBox(width: 10),

                        Expanded(
                          child: TextFormField(
                            initialValue: s.rpe == null
                                ? ""
                                : s.rpe.toString(),
                            decoration:
                                const InputDecoration(labelText: "RPE"),
                            keyboardType: TextInputType.number,
                            onChanged: (val) {
                              s.rpe =
                                  double.tryParse(val);
                            },
                          ),
                        ),

                      ],

                    ),

                    trailing: IconButton(
                      icon: const Icon(Icons.remove_circle),
                      onPressed: () => _deleteSet(ex, s),
                    ),

                  );

                }).toList(),

                const SizedBox(height: 8),

                Center(
                  child: ElevatedButton.icon(
                    onPressed: () => _addSet(ex),
                    icon: const Icon(Icons.add),
                    label: const Text("Add Set"),
                  ),
                ),

                const SizedBox(height: 12),

              ],

            ),

          );

        }).toList(),

      ),

    );

  }

}