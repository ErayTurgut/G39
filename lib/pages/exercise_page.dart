import 'package:flutter/material.dart';
import 'active_workout_page.dart';

class ExerciseSet {
  double kg;
  int reps;
  bool completed;

  ExerciseSet({
    required this.kg,
    required this.reps,
    this.completed = false,
  });
}

class ExerciseModel {
  String name;
  List<ExerciseSet> sets;

  ExerciseModel({required this.name})
      : sets = List.generate(
          3,
          (_) => ExerciseSet(kg: 0, reps: 0),
        );
}

class ExercisePage extends StatefulWidget {
  final String workoutName;

  const ExercisePage({super.key, required this.workoutName});

  @override
  State<ExercisePage> createState() => _ExercisePageState();
}

class _ExercisePageState extends State<ExercisePage> {
  final List<ExerciseModel> exercises = [];

  final List<String> exerciseLibrary = [
    "Bench Press",
    "Squat",
    "Deadlift",
    "Overhead Press",
    "Barbell Row",
    "Pull Up",
  ];

  void _addExercise(String name) {
    setState(() {
      exercises.add(ExerciseModel(name: name));
    });
  }

  /// 🔥 BURASI DÜZELTİLDİ
  void _startWorkout() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ActiveWorkoutPage(
          workoutName: widget.workoutName,
          exercises: exercises,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.workoutName)),
      body: exercises.isEmpty
          ? const Center(child: Text("Egzersiz ekleyin"))
          : ListView.builder(
              itemCount: exercises.length,
              itemBuilder: (context, index) {
                final ex = exercises[index];

                return Card(
                  child: ExpansionTile(
                    title: Text(ex.name),
                    children: [
                      ...ex.sets.map((s) {
                        return ListTile(
                          title: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  decoration:
                                      const InputDecoration(labelText: "KG"),
                                  keyboardType: TextInputType.number,
                                  onChanged: (val) =>
                                      s.kg = double.tryParse(val) ?? 0,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextField(
                                  decoration:
                                      const InputDecoration(labelText: "Reps"),
                                  keyboardType: TextInputType.number,
                                  onChanged: (val) =>
                                      s.reps = int.tryParse(val) ?? 0,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                );
              },
            ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: "addExercise",
            onPressed: () {
              showModalBottomSheet(
                context: context,
                builder: (_) => ListView(
                  children: exerciseLibrary
                      .map(
                        (e) => ListTile(
                          title: Text(e),
                          onTap: () {
                            _addExercise(e);
                            Navigator.pop(context);
                          },
                        ),
                      )
                      .toList(),
                ),
              );
            },
            child: const Icon(Icons.add),
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            heroTag: "startWorkout",
            backgroundColor: Colors.green,
            onPressed: exercises.isEmpty ? null : _startWorkout,
            child: const Icon(Icons.play_arrow),
          ),
        ],
      ),
    );
  }
}