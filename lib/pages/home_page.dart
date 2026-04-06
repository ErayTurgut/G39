import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; 
import 'package:provider/provider.dart';
import 'package:isar/isar.dart';

import '../models/workout_model.dart';
import '../services/isar_service.dart';
import '../services/app_settings.dart';
import 'active_workout_page.dart';

class WorkoutPage extends StatelessWidget {
  const WorkoutPage({super.key});

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
        toolbarHeight: 50, // HistoryPage ile aynı
        centerTitle: true,
        title: Text("WORKOUT", 
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold, letterSpacing: 1.1, fontSize: 14)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12), // HistoryPage ile aynı
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- BAŞLAT BUTONU ---
            _buildBigStartButton(context, isDark),
            
            const SizedBox(height: 24),
            
            // --- BÖLÜM BAŞLIĞI ---
            Padding(
              padding: const EdgeInsets.only(left: 8, bottom: 8),
              child: const Text("FAVORİ ANTRENMANLAR", 
                style: TextStyle(
                  color: Color(0xFF3B82F6), 
                  fontWeight: FontWeight.bold, 
                  fontSize: 11, 
                  letterSpacing: 1.1
                )),
            ),

            // --- FAVORİ LİSTESİ ---
            StreamBuilder<List<Workout>>(
              stream: IsarService.isar.workouts
                  .filter()
                  .isFavoriteEqualTo(true)
                  .watch(fireImmediately: true),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const SizedBox();

                final favorites = snapshot.data ?? [];
                
                if (favorites.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Text("Henüz favori antrenman yok", 
                        style: TextStyle(color: subTextColor, fontSize: 12)),
                    ),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: favorites.length,
                  itemBuilder: (context, index) {
                    final w = favorites[index];
                    final String formattedDate = DateFormat('dd MMM, HH:mm', 'tr_TR').format(w.date);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8), // HistoryPage ile aynı (Jilet)
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: dividerColor),
                      ),
                      child: ListTile(
                        visualDensity: VisualDensity.compact, // Boşlukları emen ayar
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0), // HistoryPage ile aynı
                        leading: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF3B82F6).withOpacity(0.08), 
                            borderRadius: BorderRadius.circular(8)
                          ),
                          child: const Icon(Icons.star_rounded, color: Colors.amber, size: 18),
                        ),
                        title: Text(w.name.toUpperCase(), 
                          style: TextStyle(color: textColor, fontWeight: FontWeight.w600, fontSize: 13)),
                        
                        subtitle: Text(formattedDate, style: TextStyle(color: subTextColor, fontSize: 11)),
                        
                        trailing: Icon(Icons.chevron_right_rounded, color: isDark ? Colors.white10 : Colors.black12, size: 20),
                        onTap: () {
                          // Antrenman Başlatma Mantığı
                          _startWorkout(context, w);
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _startWorkout(BuildContext context, Workout w) {
    List<Exercise> clonedExercises = w.exercises.map((ex) {
      return Exercise()
        ..name = ex.name
        ..region = ex.region
        ..sets = ex.sets.map((s) => ExerciseSet()
          ..kg = s.kg
          ..reps = s.reps
          ..rpe = s.rpe
          ..isCompleted = false
        ).toList();
    }).toList();

    Workout newWorkout = Workout()
      ..name = w.name 
      ..date = DateTime.now() 
      ..exercises = clonedExercises; 

    Navigator.push(context, MaterialPageRoute(
      builder: (_) => ActiveWorkoutPage(workout: newWorkout, autoStart: true)
    ));
  }

  Widget _buildBigStartButton(BuildContext context, bool isDark) {
    return GestureDetector(
      onTap: () {
        Workout quickWorkout = Workout()
          ..name = "Yeni Antrenman"
          ..date = DateTime.now()
          ..exercises = [];

        Navigator.push(context, MaterialPageRoute(
          builder: (_) => ActiveWorkoutPage(workout: quickWorkout, autoStart: true)
        ));
      },
      child: Container(
        width: double.infinity,
        height: 50, // HistoryPage Appbar yüksekliğiyle orantılı
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
    );
  }
}