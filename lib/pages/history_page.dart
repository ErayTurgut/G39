import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; 
import 'package:provider/provider.dart';
import 'package:isar/isar.dart';

import '../models/workout_model.dart';
import '../services/isar_service.dart';
import '../services/app_settings.dart';
import '../services/sharing_service.dart'; // 🔥 EKLEME: Paylaşım servisi eklendi
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
    historyStream = IsarService.isar.workouts.watchLazy(fireImmediately: true);
  }

  Future<List<Workout>> _loadWorkouts() async {
    return await IsarService.getWorkouts();
  }

  /* ================= ANTRENMANI BAŞLAT (RE-START) ================= */
  Future<void> _startExistingWorkout(BuildContext context, Workout oldWorkout) async {
    final newWorkout = Workout()
      ..name = oldWorkout.name
      ..date = DateTime.now()
      ..isFavorite = false;

    newWorkout.exercises = oldWorkout.exercises.map((oldEx) {
      final newEx = Exercise()
        ..name = oldEx.name
        ..region = oldEx.region;

      newEx.sets = oldEx.sets.map((oldS) {
        return ExerciseSet()
          ..kg = oldS.kg
          ..reps = oldS.reps
          ..rpe = oldS.rpe
          ..isCompleted = false;
      }).toList();

      return newEx;
    }).toList();

    await IsarService.saveWorkout(newWorkout);
    if (!mounted) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ActiveWorkoutPage(workout: newWorkout, autoStart: true),
      ),
    );
  }

  /* ================= RENAME & DELETE (KOMPAKT POPUP) ================= */
  void _renameWorkout(BuildContext context, Workout workout, bool isDark) {
    final controller = TextEditingController(text: workout.name);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF111018) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("İsim Değiştir", style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 16, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 14),
          autofocus: true,
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("İPTAL", style: TextStyle(color: isDark ? Colors.white24 : Colors.black26, fontSize: 12))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3B82F6), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: () async {
              await IsarService.isar.writeTxn(() async {
                workout.name = controller.text;
                await IsarService.isar.workouts.put(workout);
              });
              if (mounted) Navigator.pop(context);
            },
            child: const Text("KAYDET", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  void _deleteWorkout(BuildContext context, Workout workout, bool isDark) {
    showDialog(context: context, builder: (_) => AlertDialog(
      backgroundColor: isDark ? const Color(0xFF111018) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text("Kaydı Sil", style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 16, fontWeight: FontWeight.bold)),
      content: Text("Bu kaydı silmek istediğine emin misin?", style: TextStyle(color: isDark ? Colors.white70 : Colors.black54, fontSize: 13)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text("VAZGEÇ", style: TextStyle(color: isDark ? Colors.white24 : Colors.black26, fontSize: 12))),
        ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))), 
        onPressed: () async {
          await IsarService.isar.writeTxn(() async { await IsarService.isar.workouts.delete(workout.id); });
          if (mounted) Navigator.pop(context);
        }, child: const Text("SİL", style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold))),
      ],
    ));
  }

  Future<void> _toggleFavorite(Workout workout) async {
    await IsarService.isar.writeTxn(() async { workout.isFavorite = !workout.isFavorite; await IsarService.isar.workouts.put(workout); });
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettings>();
    final bool isDark = settings.darkMode;

    final Color bgColor = isDark ? const Color(0xFF050816) : const Color(0xFFF8FAFC);
    final Color cardColor = isDark ? const Color(0xFF101826) : Colors.white;
    final Color textColor = isDark ? Colors.white : Colors.black87;
    final Color subTextColor = isDark ? Colors.white38 : Colors.black54;
    final Color dividerColor = isDark ? Colors.white10 : Colors.black12;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF111018) : Colors.white,
        elevation: isDark ? 0 : 1,
        toolbarHeight: 50,
        centerTitle: true,
        title: Text("GEÇMİŞ", style: TextStyle(color: textColor, fontWeight: FontWeight.bold, letterSpacing: 1.1, fontSize: 14)),
      ),
      body: StreamBuilder<void>(
        stream: historyStream,
        builder: (context, snapshot) {
          return FutureBuilder<List<Workout>>(
            future: _loadWorkouts(),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) return const SizedBox();
              final workouts = snap.data ?? [];
              if (workouts.isEmpty) return Center(child: Text("Henüz kayıt yok", style: TextStyle(color: subTextColor, fontSize: 13)));

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                itemCount: workouts.length,
                itemBuilder: (context, index) {
                  final w = workouts[index];
                  final String dateStr = DateFormat('dd MMM, HH:mm', 'tr_TR').format(w.date);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: dividerColor)),
                    child: ListTile(
                      visualDensity: VisualDensity.compact,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
                      onTap: () {
                        final freshWorkout = IsarService.isar.workouts.getSync(w.id);
                        if (freshWorkout != null) Navigator.push(context, MaterialPageRoute(builder: (_) => WorkoutDetailPage(workout: freshWorkout)));
                      },
                      leading: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(color: const Color(0xFF3B82F6).withOpacity(0.08), borderRadius: BorderRadius.circular(8)),
                        child: Icon(Icons.history_rounded, color: const Color(0xFF3B82F6), size: 18),
                      ),
                      title: Text(w.name.toUpperCase(), style: TextStyle(color: textColor, fontWeight: FontWeight.w600, fontSize: 13)),
                      subtitle: Text(dateStr, style: TextStyle(color: subTextColor, fontSize: 11)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            icon: Icon(w.isFavorite ? Icons.star_rounded : Icons.star_outline_rounded, color: w.isFavorite ? Colors.amber : subTextColor, size: 20),
                            onPressed: () => _toggleFavorite(w),
                          ),
                          Theme(
                            data: Theme.of(context).copyWith(cardColor: isDark ? const Color(0xFF1A1D2D) : Colors.white),
                            child: PopupMenuButton<String>(
                              padding: EdgeInsets.zero,
                              icon: Icon(Icons.more_vert_rounded, color: isDark ? Colors.white10 : Colors.black12, size: 20),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              onSelected: (val) {
                                if (val == 'start') _startExistingWorkout(context, w);
                                if (val == 'share') WorkoutSharing.shareMyProgram(w); // 🔥 EKLEME: Paylaşım aksiyonu
                                if (val == 'rename') _renameWorkout(context, w, isDark);
                                if (val == 'delete') _deleteWorkout(context, w, isDark);
                              },
                              itemBuilder: (_) => [
                                _buildMenuItem('start', Icons.play_arrow_rounded, "Tekrar Başlat", Colors.greenAccent, isDark),
                                // 🔥 EKLEME: Tam araya Paylaş eklendi
                                _buildMenuItem('share', Icons.share_rounded, "Programı Paylaş", Colors.blueAccent, isDark), 
                                _buildMenuItem('rename', Icons.edit_note_rounded, "İsim Değiştir", isDark ? Colors.white70 : Colors.black54, isDark),
                                _buildMenuItem('delete', Icons.delete_outline_rounded, "Kaydı Sil", Colors.redAccent, isDark),
                              ],
                            ),
                          ),
                        ],
                      ),
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

  PopupMenuItem<String> _buildMenuItem(String val, IconData icon, String txt, Color color, bool isDark) {
    return PopupMenuItem(
      value: val,
      height: 35,
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 10),
          Text(txt, style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}