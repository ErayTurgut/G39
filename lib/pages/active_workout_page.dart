import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../main.dart'; // 🔥 Global audioHandler'a erişim
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
  Timer? _saveDebounce;
  
  int _seconds = 0;
  bool workoutStarted = false;
  bool _isDisposed = false;

  final Map<int, DateTime> _setRestStarts = {}; 
  final Map<int, int> _setRestDurations = {}; 
  final Map<int, bool> _isExerciseRest = {}; 

  final Map<String, TextEditingController> _kgControllers = {};
  final Map<String, TextEditingController> _repControllers = {};
  final Map<String, TextEditingController> _rpeControllers = {}; 

  @override
  void initState() {
    super.initState();
    if (widget.workout.id != 0 && widget.workout.date.year > 2000) {
      workoutStarted = true;
      _resumeTimer();
    } else if (widget.autoStart) {
      _startWorkout();
    }
  }

  void _resumeTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _isDisposed) return;
      
      setState(() {
        _seconds = DateTime.now().difference(widget.workout.date).inSeconds;
      });
      // Not: Artık burada _checkRestTimers() gibi bir hamallık yok.
      // Bildirimi ve sesi iOS/Android kendi takip ediyor.
    });
  }

  void _startWorkout() {
    setState(() {
      workoutStarted = true;
      widget.workout.date = DateTime.now();
      _seconds = 0;
    });

    audioHandler.startWorkoutSession();
    IsarService.saveWorkout(widget.workout);
    _resumeTimer();
  }

  void _handleSetToggle(Exercise ex, ExerciseSet set) {
    final settings = context.read<AppSettings>();
    final setHash = _getSetHash(ex, set);

    setState(() {
      set.isCompleted = !set.isCompleted;
      if (set.isCompleted) {
        // Yeni bir set bitince diğerlerini temizle (sadece tek bir rest timer görünsün)
        _setRestStarts.clear();
        _setRestDurations.clear();
        _isExerciseRest.clear();
        
        _setRestStarts[setHash] = DateTime.now();
        bool allSetsDone = ex.sets.every((s) => s.isCompleted);
        int duration = allSetsDone ? settings.exerciseRestSeconds : settings.restSeconds;
        
        _setRestDurations[setHash] = duration;
        _isExerciseRest[setHash] = allSetsDone;

        // 🔥 İŞTE KRİTİK NOKTA: iOS'un kendi sistemine zamanlanmış görev veriyoruz.
        // Uygulamayı kapatsan bile bu süre sonunda ses patlayacak.
        if (settings.restSoundEnabled) {
          audioHandler.scheduleRestNotification(duration, settings.restSoundType);
        }
        
      } else {
        // Eğer yanlışlıkla tıklandıysa ve geri alınırsa bekleyen bildirimi iptal et
        audioHandler.cancelRestNotification();
        
        _setRestStarts.remove(setHash);
        _setRestDurations.remove(setHash);
        _isExerciseRest.remove(setHash);
      }
    });
    _debouncedSave();
  }

  int _getSetHash(Exercise ex, ExerciseSet s) {
    return Object.hash(ex.name, widget.workout.exercises.indexOf(ex), ex.sets.indexOf(s));
  }

  TextEditingController _getController(Map<String, TextEditingController> map, String key, String initialValue) {
    if (!map.containsKey(key)) {
      map[key] = TextEditingController(text: initialValue == "0" || initialValue == "0.0" || initialValue == "null" ? "" : initialValue);
    }
    return map[key]!;
  }

  void _debouncedSave() {
    _saveDebounce?.cancel();
    _saveDebounce = Timer(const Duration(milliseconds: 400), () => IsarService.saveWorkout(widget.workout));
  }

  @override
  void dispose() {
    _isDisposed = true;
    _timer?.cancel();
    _saveDebounce?.cancel();
    _kgControllers.values.forEach((c) => c.dispose());
    _repControllers.values.forEach((c) => c.dispose());
    _rpeControllers.values.forEach((c) => c.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    int activeRestRemaining = 0;
    String restLabel = "SET ARASI";

    _setRestStarts.forEach((hash, startAt) {
      int duration = _setRestDurations[hash] ?? 60;
      int rem = duration - DateTime.now().difference(startAt).inSeconds;
      if (rem > activeRestRemaining) {
        activeRestRemaining = rem;
        bool isExercise = _isExerciseRest[hash] ?? false;
        restLabel = isExercise ? "HAREKET ARASI" : "SET ARASI";
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFF050816),
      appBar: AppBar(
        backgroundColor: const Color(0xFF111018),
        title: Text(widget.workout.name.toUpperCase(), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
        centerTitle: true,
        actions: [
          if (workoutStarted)
            Center(
              child: Container(
                margin: const EdgeInsets.only(right: 16),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: const Color(0xFF3B82F6).withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
                child: Text(
                  "${(_seconds ~/ 60).toString().padLeft(2, '0')}:${(_seconds % 60).toString().padLeft(2, '0')}",
                  style: const TextStyle(fontSize: 18, color: Color(0xFF3B82F6), fontWeight: FontWeight.bold),
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          if (activeRestRemaining > 0)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: restLabel == "HAREKET ARASI" ? Colors.blue.withOpacity(0.15) : Colors.orange.withOpacity(0.1),
                border: Border(bottom: BorderSide(color: restLabel == "HAREKET ARASI" ? Colors.blueAccent : Colors.orangeAccent, width: 1)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.hourglass_bottom_rounded, color: restLabel == "HAREKET ARASI" ? Colors.blueAccent : Colors.orangeAccent, size: 18),
                  const SizedBox(width: 8),
                  Text("$restLabel : $activeRestRemaining s", 
                  style: TextStyle(color: restLabel == "HAREKET ARASI" ? Colors.blueAccent : Colors.orangeAccent, fontSize: 15, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 130),
              itemCount: widget.workout.exercises.length,
              itemBuilder: (context, index) => _exerciseCard(widget.workout.exercises[index]),
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: _buildBottomActionButtons(),
    );
  }

  Widget _exerciseCard(Exercise ex) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF101826),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(ex.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15))),
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.delete_sweep_outlined, color: Colors.redAccent, size: 20),
                onPressed: () {
                  setState(() => widget.workout.exercises.remove(ex));
                  _debouncedSave();
                },
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.add_circle_outline, color: Color(0xFF3B82F6), size: 24),
                onPressed: () => setState(() => ex.sets.add(ExerciseSet()..kg = 0..reps = 0)),
              ),
            ],
          ),
          const Divider(color: Colors.white10, height: 12),
          ...ex.sets.asMap().entries.map((entry) {
            final setIndex = entry.key;
            final set = entry.value;
            final key = "${ex.name}-$setIndex";
            final hash = _getSetHash(ex, set);
            
            int rem = 0;
            if (_setRestStarts.containsKey(hash)) {
              rem = (_setRestDurations[hash] ?? 60) - DateTime.now().difference(_setRestStarts[hash]!).inSeconds;
              if (rem < 0) rem = 0;
            }

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => _handleSetToggle(ex, set),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: 32, height: 32,
                      decoration: BoxDecoration(
                        color: set.isCompleted ? (rem > 0 ? Colors.orange : Colors.green) : Colors.white10,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: set.isCompleted ? Colors.transparent : Colors.white24),
                      ),
                      child: rem > 0 && set.isCompleted
                          ? const Center(child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)))
                          : Icon(set.isCompleted ? Icons.check_rounded : Icons.add_task_rounded, color: Colors.white, size: 18),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _inputField(_getController(_kgControllers, key, set.kg.toString()), "kg", (v) => set.kg = double.tryParse(v) ?? 0),
                  const SizedBox(width: 4),
                  _inputField(_getController(_repControllers, key, set.reps.toString()), "rep", (v) => set.reps = int.tryParse(v) ?? 0),
                  const SizedBox(width: 4),
                  _inputField(_getController(_rpeControllers, key, (set.rpe ?? "").toString()), "RIR", (v) => set.rpe = double.tryParse(v)),
                  const Spacer(),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.remove_circle_outline, color: Colors.white24, size: 18),
                    onPressed: () => setState(() => ex.sets.remove(set)),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _inputField(TextEditingController controller, String hint, Function(String) onChanged) {
    return Container(
      width: 48, height: 32,
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(8)),
      child: TextField(
        controller: controller,
        textAlign: TextAlign.center,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.white24, fontSize: 10),
          border: InputBorder.none,
          isDense: true,
          contentPadding: const EdgeInsets.only(top: 8),
        ),
        onChanged: (v) { onChanged(v); _debouncedSave(); },
      ),
    );
  }

  Widget _buildBottomActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: FloatingActionButton.extended(
              heroTag: "ex_add",
              backgroundColor: const Color(0xFF101826),
              onPressed: () async {
                final res = await Navigator.push(context, MaterialPageRoute(builder: (_) => const ExercisePickerPage()));
                if (res != null) {
                  setState(() {
                    widget.workout.exercises.add(
                      Exercise()
                        ..name = res["name"]
                        ..region = res["region"]
                        ..sets = List.generate(3, (_) => ExerciseSet()..kg = 0..reps = 0)
                    );
                  });
                  _debouncedSave();
                }
              },
              icon: const Icon(Icons.add_rounded, color: Color(0xFF3B82F6)),
              label: const Text("HAREKET EKLE", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FloatingActionButton.extended(
              heroTag: "ex_end",
              backgroundColor: workoutStarted ? Colors.green : const Color(0xFF3B82F6),
              onPressed: workoutStarted ? () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => WorkoutSummaryPage(workout: widget.workout, totalSeconds: _seconds))) : _startWorkout,
              icon: Icon(workoutStarted ? Icons.stop_circle_outlined : Icons.play_circle_fill_rounded, color: Colors.white),
              label: Text(workoutStarted ? "BİTİR" : "BAŞLAT", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}