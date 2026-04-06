import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/workout_model.dart';
import '../services/isar_service.dart';
import '../services/app_settings.dart';

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
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Değişiklikler kaydedildi"), duration: Duration(seconds: 1))
      );
      Navigator.pop(context);
    }
  }

  void _addSet(Exercise exercise) {
    setState(() {
      exercise.sets = List.from(exercise.sets);
      exercise.sets.add(ExerciseSet()..kg = 0..reps = 0..rpe = null..isCompleted = true);
    });
  }

  void _deleteSet(Exercise exercise, ExerciseSet set) {
    setState(() {
      exercise.sets = List.from(exercise.sets);
      exercise.sets.remove(set);
    });
  }

  void _deleteExercise(Exercise exercise) {
    setState(() {
      widget.workout.exercises = List.from(widget.workout.exercises);
      widget.workout.exercises.remove(exercise);
    });
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettings>();
    final bool isDark = settings.darkMode;

    final Color bgColor = isDark ? const Color(0xFF050816) : const Color(0xFFF8FAFC);
    final Color appBarColor = isDark ? const Color(0xFF111018) : Colors.white;
    final Color cardColor = isDark ? const Color(0xFF101826) : Colors.white;
    final Color textColor = isDark ? Colors.white : Colors.black87;
    final Color subTextColor = isDark ? Colors.white38 : Colors.black54;
    final Color dividerColor = isDark ? Colors.white10 : Colors.black12;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: appBarColor,
        elevation: isDark ? 0 : 1,
        toolbarHeight: 50,
        centerTitle: true,
        title: Text(widget.workout.name.toUpperCase(), 
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold, letterSpacing: 1.1, fontSize: 14)),
        actions: [
          IconButton(
            icon: Icon(Icons.check_rounded, color: const Color(0xFF3B82F6), size: 22),
            onPressed: _saveWorkout,
          )
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        itemCount: widget.workout.exercises.length,
        itemBuilder: (context, index) {
          final ex = widget.workout.exercises[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: dividerColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(ex.name, style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 13)),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 18),
                      onPressed: () => _deleteExercise(ex),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ...ex.sets.asMap().entries.map((entry) {
                  final setIndex = entry.key;
                  final s = entry.value;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        _setIndexCircle(setIndex + 1, isDark),
                        const SizedBox(width: 10),
                        _compactInput(
                          initial: s.kg == 0 ? "" : s.kg.toString(),
                          label: "KG",
                          onChanged: (val) => s.kg = double.tryParse(val) ?? 0,
                          isDark: isDark,
                        ),
                        const SizedBox(width: 6),
                        _compactInput(
                          initial: s.reps == 0 ? "" : s.reps.toString(),
                          label: "REP",
                          onChanged: (val) => s.reps = int.tryParse(val) ?? 0,
                          isDark: isDark,
                        ),
                        const SizedBox(width: 6),
                        _compactInput(
                          initial: s.rpe == null ? "" : s.rpe.toString(),
                          label: "RIR",
                          onChanged: (val) => s.rpe = double.tryParse(val),
                          isDark: isDark,
                        ),
                        const Spacer(),
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          icon: const Icon(Icons.remove_circle_outline, color: Colors.white24, size: 16),
                          onPressed: () => _deleteSet(ex, s),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: () => _addSet(ex),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B82F6).withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF3B82F6).withOpacity(0.1)),
                    ),
                    child: const Center(
                      child: Text("+ SET EKLE", style: TextStyle(color: Color(0xFF3B82F6), fontWeight: FontWeight.bold, fontSize: 11)),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _setIndexCircle(int index, bool isDark) {
    return Container(
      width: 20, height: 20,
      decoration: BoxDecoration(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05), shape: BoxShape.circle),
      child: Center(child: Text(index.toString(), style: TextStyle(color: isDark ? Colors.white38 : Colors.black38, fontSize: 10, fontWeight: FontWeight.bold))),
    );
  }

  Widget _compactInput({required String initial, required String label, required Function(String) onChanged, required bool isDark}) {
    return Container(
      width: 50, height: 32,
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.03),
        borderRadius: BorderRadius.circular(8),
      ),
      child: TextFormField(
        initialValue: initial,
        textAlign: TextAlign.center,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 12, fontWeight: FontWeight.bold),
        decoration: InputDecoration(
          hintText: label,
          hintStyle: const TextStyle(color: Colors.white24, fontSize: 9),
          border: InputBorder.none,
          isDense: true,
          contentPadding: const EdgeInsets.only(top: 8),
        ),
        onChanged: onChanged,
      ),
    );
  }
}