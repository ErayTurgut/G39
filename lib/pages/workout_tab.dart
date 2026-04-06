import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; 
import 'package:provider/provider.dart';
import 'package:isar/isar.dart';

import '../models/workout_model.dart';
import '../services/isar_service.dart';
import '../services/app_settings.dart';
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
    workoutStream = IsarService.isar.workouts.watchLazy(fireImmediately: true);
  }

  Future<List<Workout>> _loadFavorites() async {
    final all = await IsarService.getWorkouts();
    return all.where((w) => w.isFavorite).toList();
  }

  /* ================= JİLET POPUP (DAMLASIZ & İMLEÇSİZ) ================= */
  void _startWorkoutDialog() {
    final settings = context.read<AppSettings>();
    final bool isDark = settings.darkMode;
    final controller = TextEditingController(text: "Yeni Antrenman");

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF111018) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text("YENİ ANTRENMAN", 
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black87, 
              fontSize: 15, 
              fontWeight: FontWeight.bold, 
              letterSpacing: 1.1
            )),
          content: TextField(
            controller: controller,
            autofocus: true,
            showCursor: false, // 🔥 İmleç yok
            enableInteractiveSelection: false, // 🔥 Damla/Seçim baloncuğu yok
            style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 16),
            decoration: InputDecoration(
              hintText: "Antrenman ismi girin...",
              hintStyle: TextStyle(fontSize: 14, color: isDark ? Colors.white24 : Colors.black26),
              filled: true,
              fillColor: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text("İPTAL", style: TextStyle(color: isDark ? Colors.white24 : Colors.black26, fontSize: 12)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              onPressed: () {
                if (controller.text.trim().isEmpty) return;

                final workout = Workout()
                  ..name = controller.text
                  ..date = DateTime.now();

                Navigator.pop(dialogContext);

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ActiveWorkoutPage(workout: workout, autoStart: true),
                  ),
                );
              },
              child: const Text("BAŞLAT", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
            ),
          ],
        );
      },
    );
  }

  /* ================= FAVORİ TEKRARLA ================= */
  Future<void> _repeatFavoriteWorkout(Workout template) async {
    final newWorkout = Workout()
      ..name = template.name
      ..date = DateTime.now()
      ..isFavorite = false;

    newWorkout.exercises = template.exercises.map((oldEx) {
      final nEx = Exercise()..name = oldEx.name..region = oldEx.region;
      nEx.sets = oldEx.sets.map((s) => ExerciseSet()..kg = s.kg..reps = s.reps..isCompleted = false).toList();
      return nEx;
    }).toList();

    await IsarService.saveWorkout(newWorkout);
    if (!mounted) return;

    Navigator.push(context, MaterialPageRoute(
      builder: (_) => ActiveWorkoutPage(workout: newWorkout, autoStart: true),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettings>();
    final bool isDark = settings.darkMode;

    final Color bgColor = isDark ? const Color(0xFF050816) : const Color(0xFFF8FAFC);
    final Color cardColor = isDark ? const Color(0xFF101826) : Colors.white;
    final Color textColor = isDark ? Colors.white : Colors.black87;
    final Color subTextColor = isDark ? Colors.white38 : Colors.black54;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF111018) : Colors.white,
        elevation: isDark ? 0 : 1,
        toolbarHeight: 50,
        centerTitle: true,
        title: Text("WORKOUT", style: TextStyle(color: textColor, fontWeight: FontWeight.bold, letterSpacing: 1.1, fontSize: 14)),
      ),
      body: StreamBuilder<void>(
        stream: workoutStream,
        builder: (context, snapshot) {
          return FutureBuilder<List<Workout>>(
            future: _loadFavorites(),
            builder: (context, snap) {
              final favorites = snap.data ?? [];

              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- KOMPAKT BAŞLAT BUTONU ---
                    GestureDetector(
                      onTap: _startWorkoutDialog,
                      child: Container(
                        width: double.infinity,
                        height: 50,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isDark 
                              ? [const Color(0xFF1E293B), const Color(0xFF0F172A)] 
                              : [const Color(0xFF3B82F6), const Color(0xFF2563EB)],
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Center(
                          child: Text("ANTREMANA BAŞLA", 
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.2, fontSize: 14)),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    Padding(
                      padding: const EdgeInsets.only(left: 8, bottom: 8),
                      child: Text("FAVORİ ANTRENMANLAR", 
                        style: TextStyle(color: const Color(0xFF3B82F6), fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1.1)),
                    ),

                    if (favorites.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 40),
                          child: Text("Henüz favori antrenman yok", style: TextStyle(color: subTextColor, fontSize: 12)),
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: favorites.length,
                        itemBuilder: (context, index) {
                          final fav = favorites[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: cardColor, 
                              borderRadius: BorderRadius.circular(16), 
                              border: Border.all(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05))
                            ),
                            child: ListTile(
                              visualDensity: VisualDensity.compact,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
                              leading: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(color: const Color(0xFF3B82F6).withOpacity(0.08), borderRadius: BorderRadius.circular(8)),
                                child: const Icon(Icons.star_rounded, color: Colors.amber, size: 18),
                              ),
                              title: Text(fav.name.toUpperCase(), style: TextStyle(color: textColor, fontWeight: FontWeight.w600, fontSize: 13)),
                              trailing: Icon(Icons.play_arrow_rounded, color: isDark ? Colors.white10 : Colors.black12, size: 20),
                              onTap: () => _repeatFavoriteWorkout(fav),
                              onLongPress: () {
                                Navigator.push(context, MaterialPageRoute(builder: (_) => WorkoutDetailPage(workout: fav)));
                              },
                            ),
                          );
                        },
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