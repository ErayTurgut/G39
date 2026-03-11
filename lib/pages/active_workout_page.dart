import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:audioplayers/audioplayers.dart';

import '../models/workout_model.dart';
import '../services/isar_service.dart';
import '../services/app_settings.dart';
import 'exercise_picker_page.dart';
import 'workout_summary_page.dart';

class ActiveWorkoutPage extends StatefulWidget {
  final Workout workout;
  final bool autoStart;

  const ActiveWorkoutPage({
    super.key,
    required this.workout,
    this.autoStart = false,
  });

  @override
  State<ActiveWorkoutPage> createState() => _ActiveWorkoutPageState();
}

class _ActiveWorkoutPageState extends State<ActiveWorkoutPage> {
  Timer? _timer;
  Timer? _restTimer;

  final AudioPlayer _player = AudioPlayer();

  int _seconds = 0;
  int _restRemaining = 0;
  String _restType = "";

  bool workoutStarted = false;
  bool _isDisposed = false;

  final Map<String, TextEditingController> _kgControllers = {};
  final Map<String, TextEditingController> _repControllers = {};
  final Map<String, TextEditingController> _rpeControllers = {};

  @override
  void initState() {
    super.initState();

    if (widget.autoStart) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_isDisposed) {
          _startWorkout();
        }
      });
    }
  }

  TextEditingController _kgController(String key, double value) {
    if (!_kgControllers.containsKey(key)) {
      _kgControllers[key] =
          TextEditingController(text: value == 0 ? "" : value.toString());
    }
    return _kgControllers[key]!;
  }

  TextEditingController _repController(String key, int value) {
    if (!_repControllers.containsKey(key)) {
      _repControllers[key] =
          TextEditingController(text: value == 0 ? "" : value.toString());
    }
    return _repControllers[key]!;
  }

  TextEditingController _rpeController(String key, double? value) {
    if (!_rpeControllers.containsKey(key)) {
      _rpeControllers[key] =
          TextEditingController(text: value == null ? "" : value.toString());
    }
    return _rpeControllers[key]!;
  }

  String _formatTime() {
    final m = (_seconds ~/ 60).toString().padLeft(2, '0');
    final s = (_seconds % 60).toString().padLeft(2, '0');
    return "$m:$s";
  }

  Future<void> _playBeep() async {
    try {
      await _player.play(
        AssetSource('sounds/airHorn.mp3'),
        volume: 1.0,
      );
    } catch (_) {}
  }

  void _startWorkout() async {
    if (widget.workout.exercises.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Önce hareket ekleyin")),
      );
      return;
    }

    await IsarService.saveWorkout(widget.workout);

    setState(() {
      workoutStarted = true;
      _seconds = 0;
    });

    _timer?.cancel();

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _isDisposed) return;

      setState(() {
        _seconds++;
      });
    });
  }

  Future<void> _finishWorkout() async {
    _timer?.cancel();
    _restTimer?.cancel();

    await IsarService.saveWorkout(widget.workout);

    if (!mounted) return;

    await Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => WorkoutSummaryPage(
          workout: widget.workout,
          totalSeconds: _seconds,
        ),
      ),
    );
  }

  Future<void> _addExercise() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const ExercisePickerPage(),
      ),
    );

    if (result == null) return;

    final exercise = Exercise()
      ..name = result["name"]
      ..region = result["region"];

    exercise.sets = [
      ExerciseSet()..kg = 0..reps = 0..isCompleted = false,
      ExerciseSet()..kg = 0..reps = 0..isCompleted = false,
      ExerciseSet()..kg = 0..reps = 0..isCompleted = false,
    ];

    setState(() {
      widget.workout.exercises.add(exercise);
    });

    await IsarService.saveWorkout(widget.workout);
  }

  void _addSet(Exercise exercise) {
    setState(() {
      exercise.sets.add(
        ExerciseSet()..kg = 0..reps = 0..isCompleted = false,
      );
    });

    IsarService.saveWorkout(widget.workout);
  }

  void _deleteSet(Exercise exercise, ExerciseSet set) {
    setState(() {
      exercise.sets.remove(set);
    });

    IsarService.saveWorkout(widget.workout);
  }

  void _startSetRest() {
    final rest = context.read<AppSettings>().restSeconds;

    _restType = "SET REST";

    _restTimer?.cancel();

    setState(() {
      _restRemaining = rest;
    });

    _restTimer =
        Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (_restRemaining == 0) {
        timer.cancel();
        await _playBeep();
      } else {
        setState(() {
          _restRemaining--;
        });
      }
    });
  }

  @override
  void dispose() {
    _isDisposed = true;

    _timer?.cancel();
    _restTimer?.cancel();

    for (var c in _kgControllers.values) {
      c.dispose();
    }

    for (var c in _repControllers.values) {
      c.dispose();
    }

    for (var c in _rpeControllers.values) {
      c.dispose();
    }

    _player.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.workout.name),
        actions: [
          if (workoutStarted)
            Padding(
              padding: const EdgeInsets.only(right: 20),
              child: Center(
                child: Text(
                  _formatTime(),
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          if (_restRemaining > 0)
            Container(
              padding: const EdgeInsets.all(12),
              color: Colors.orange.withOpacity(0.15),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.timer),
                  const SizedBox(width: 10),
                  Text(
                    "$_restType : $_restRemaining s",
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          Expanded(
            child: ListView.builder(
              itemCount: widget.workout.exercises.length,
              itemBuilder: (context, index) {
                final ex = widget.workout.exercises[index];

                return Card(
                  margin: const EdgeInsets.all(10),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              ex.name,
                              style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add),
                              onPressed: () => _addSet(ex),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ...ex.sets.map((set) {
                          final setIndex = ex.sets.indexOf(set);
                          final key = "${ex.name}-$setIndex";

                          return Padding(
                            padding:
                                const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                Checkbox(
                                  value: set.isCompleted,
                                  onChanged: (val) {
                                    setState(() {
                                      set.isCompleted =
                                          val ?? false;
                                    });

                                    if (val == true) {
                                      _startSetRest();
                                    }

                                    IsarService.saveWorkout(
                                        widget.workout);
                                  },
                                ),

                                Text("Set ${setIndex + 1}"),

                                const SizedBox(width: 10),

                                SizedBox(
                                  width: 60,
                                  child: TextField(
                                    controller:
                                        _kgController(key, set.kg),
                                    keyboardType:
                                        TextInputType.number,
                                    decoration:
                                        const InputDecoration(
                                      hintText: "kg",
                                      isDense: true,
                                    ),
                                    onChanged: (val) {
                                      set.kg =
                                          double.tryParse(val) ?? 0;
                                      IsarService.saveWorkout(widget.workout);
                                    },
                                  ),
                                ),

                                const SizedBox(width: 6),

                                SizedBox(
                                  width: 60,
                                  child: TextField(
                                    controller:
                                        _repController(key, set.reps),
                                    keyboardType:
                                        TextInputType.number,
                                    decoration:
                                        const InputDecoration(
                                      hintText: "reps",
                                      isDense: true,
                                    ),
                                    onChanged: (val) {
                                      set.reps =
                                          int.tryParse(val) ?? 0;
                                      IsarService.saveWorkout(widget.workout);
                                    },
                                  ),
                                ),

                                const SizedBox(width: 6),

                                SizedBox(
                                  width: 60,
                                  child: TextField(
                                    controller:
                                        _rpeController(key, set.rpe),
                                    keyboardType:
                                        TextInputType.number,
                                    decoration:
                                        const InputDecoration(
                                      hintText: "RPE",
                                      isDense: true,
                                    ),
                                    onChanged: (val) {
                                      set.rpe =
                                          double.tryParse(val);
                                      IsarService.saveWorkout(widget.workout);
                                    },
                                  ),
                                ),

                                const Spacer(),

                                IconButton(
                                  icon: const Icon(
                                      Icons.delete,
                                      color: Colors.red),
                                  onPressed: () =>
                                      _deleteSet(ex, set),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),

      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.extended(
            heroTag: "addExercise",
            onPressed: _addExercise,
            icon: const Icon(Icons.add),
            label: const Text("Exercise"),
          ),

          const SizedBox(height: 10),

          if (!workoutStarted)
            FloatingActionButton.extended(
              heroTag: "startWorkout",
              onPressed: _startWorkout,
              icon: const Icon(Icons.play_arrow),
              label: const Text("Start"),
            ),

          if (workoutStarted)
            FloatingActionButton.extended(
              heroTag: "finishWorkout",
              onPressed: _finishWorkout,
              icon: const Icon(Icons.stop),
              label: const Text("Finish"),
            ),
        ],
      ),
    );
  }
}