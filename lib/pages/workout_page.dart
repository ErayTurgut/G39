import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; 
import 'package:provider/provider.dart';
import 'package:isar/isar.dart';

import '../services/isar_service.dart';
import '../models/workout_model.dart';
import '../services/app_settings.dart';
import 'active_workout_page.dart'; 

class WorkoutPage extends StatefulWidget {
  const WorkoutPage({super.key});

  @override
  State<WorkoutPage> createState() => _WorkoutPageState();
}

class _WorkoutPageState extends State<WorkoutPage> {
  late Stream<void> workoutStream;

  @override
  void initState() {
    super.initState();
    workoutStream = IsarService.isar.workouts.watchLazy(fireImmediately: true);
    _initDatabase();
  }

  Future<void> _initDatabase() async {
    await _seedStarterWorkouts();
    if (mounted) setState(() {}); 
  }

  Future<void> _seedStarterWorkouts() async {
    final existing = await IsarService.isar.workouts
        .filter()
        .nameEqualTo('Başlangıç Seviyesi Full Body (A)')
        .findFirst();

    if (existing == null) {
      final oldDate = DateTime(2024, 1, 1); 
      final starterWorkouts = [
        _createTemplateWorkout('Başlangıç Seviyesi Full Body (A)', [
          _createEx("Leg Press", "Leg"), _createEx("Bench Press", "Chest"), 
          _createEx("Pec Deck", "Chest"), _createEx("Lat Pulldown", "Back"), 
          _createEx("Shoulder Press", "Shoulder"), _createEx("Biceps Curl", "Arm")
        ], oldDate),
        _createTemplateWorkout('Başlangıç Seviyesi Full Body (B)', [
          _createEx("Leg Press", "Leg"), _createEx("Lat Pulldown", "Back"), 
          _createEx("Seated Row", "Back"), _createEx("Bench Press", "Chest"), 
          _createEx("Lateral Raise", "Shoulder"), _createEx("Triceps Pushdown", "Arm")
        ], oldDate.add(const Duration(hours: 1))),
        _createTemplateWorkout('Başlangıç Seviyesi Upper Body', [
          _createEx("Bench Press", "Chest"), _createEx("Lat Pulldown", "Back"), 
          _createEx("Pec Deck", "Chest"), _createEx("Seated Row", "Back"), 
          _createEx("Shoulder Press", "Shoulder"), _createEx("Biceps Curl", "Arm"), 
          _createEx("Triceps Pushdown", "Arm")
        ], oldDate.add(const Duration(hours: 2))),
        _createTemplateWorkout('Başlangıç Seviyesi Lower Body', [
          _createEx("Leg Press", "Leg"), _createEx("Leg Curl", "Leg"), 
          _createEx("Leg Extension", "Leg"), _createEx("Glute Bridge", "Leg"), 
          _createEx("Walking Lunge", "Leg"), _createEx("Calf Raise", "Leg"), 
          _createEx("Plank", "Core")
        ], oldDate.add(const Duration(hours: 3))),
      ];

      await IsarService.isar.writeTxn(() async {
        await IsarService.isar.workouts.putAll(starterWorkouts);
      });
    }
  }

  Workout _createTemplateWorkout(String name, List<Exercise> exercises, DateTime date) {
    return Workout()..name = name..date = date..isFavorite = true..exercises = exercises;
  }

  Exercise _createEx(String name, String region) {
    return Exercise()..name = name..region = region..sets = List.generate(3, (i) => ExerciseSet()..kg = 0..reps = 0..isCompleted = false);
  }

  String _getSubtitle(Workout fav) {
    switch (fav.name) {
      case 'Başlangıç Seviyesi Full Body (A)': return "6 Hareket - Göğüs & Biceps Odaklı";
      case 'Başlangıç Seviyesi Full Body (B)': return "6 Hareket - Sırt & Triceps Odaklı";
      case 'Başlangıç Seviyesi Upper Body': return "7 Hareket - Üst Vücut Gelişimi";
      case 'Başlangıç Seviyesi Lower Body': return "7 Hareket - Alt Vücut & Mobilite";
      default: return DateFormat('dd MMM, HH:mm', 'tr_TR').format(fav.date);
    }
  }

  Future<List<Workout>> _loadFavorites() async {
    return await IsarService.isar.workouts
        .where()
        .filter()
        .isFavoriteEqualTo(true)
        .sortByDateDesc()
        .findAll();
  }

  // --- ANTRENMAN ADI SORAN POPUP FONKSİYONU ---
  void _showStartWorkoutDialog(bool isDark) {
    final TextEditingController nameController = TextEditingController(text: "Yeni Antrenman");
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF111018) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Antrenman Başlat", 
          style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 16, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: nameController,
          autofocus: true,
          style: TextStyle(color: isDark ? Colors.white : Colors.black87),
          decoration: InputDecoration(
            hintText: "Antrenman adı girin...",
            hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.black38),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: isDark ? Colors.white10 : Colors.black12)),
            focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF3B82F6), width: 2)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("İPTAL", style: TextStyle(color: isDark ? Colors.white24 : Colors.black26, fontSize: 12)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3B82F6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              final String workoutName = nameController.text.trim().isEmpty ? "Yeni Antrenman" : nameController.text;
              Navigator.pop(context); // Dialogu kapat
              
              Workout newEmptyWorkout = Workout()
                ..name = workoutName
                ..date = DateTime.now()
                ..exercises = [];
              
              Navigator.push(context, 
                MaterialPageRoute(builder: (_) => ActiveWorkoutPage(workout: newEmptyWorkout, autoStart: true))
              );
            },
            child: const Text("BAŞLA", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettings>();
    final bool isDark = settings.darkMode;
    final Color bgColor = isDark ? const Color(0xFF050816) : const Color(0xFFF8FAFC);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF111018) : Colors.white,
        elevation: 0,
        toolbarHeight: 50,
        centerTitle: true,
        title: Text("G39 PRO", style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.bold, letterSpacing: 1.2, fontSize: 16)),
      ),
      body: StreamBuilder<void>(
        stream: workoutStream,
        builder: (context, snapshot) {
          return FutureBuilder<List<Workout>>(
            future: _loadFavorites(),
            builder: (context, snap) {
              final favorites = snap.data ?? [];

              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeroButton(isDark), // Popupa bağlanan buton
                    const SizedBox(height: 20),

                    const Text("FAVORİ ANTRENMANLAR", style: TextStyle(color: Color(0xFF3B82F6), fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1.1)),
                    const SizedBox(height: 10),

                    if (favorites.isEmpty)
                      const Center(child: Padding(padding: EdgeInsets.only(top: 40), child: Text("Henüz favori yok", style: TextStyle(color: Colors.grey, fontSize: 12))))
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: favorites.length,
                        itemBuilder: (context, index) {
                          final fav = favorites[index];
                          final subtitle = _getSubtitle(fav);
                          return _buildUnifiedCard(fav.name.toUpperCase(), subtitle, isDark, workout: fav);
                        },
                      ),
                    
                    const SizedBox(height: 24),
                    _buildDisclaimer(isDark),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildUnifiedCard(String title, String subtitle, bool isDark, {required Workout workout}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8), 
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF101826) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05)),
      ),
      child: ListTile(
        visualDensity: VisualDensity.compact, 
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
        leading: const Icon(Icons.star_rounded, color: Colors.amber, size: 22), 
        title: Text(title, style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.bold, fontSize: 13)), 
        subtitle: Text(subtitle, style: TextStyle(color: isDark ? Colors.white38 : Colors.black45, fontSize: 11)),
        trailing: const Icon(Icons.play_circle_fill_rounded, color: Color(0xFF3B82F6), size: 26), 
        onTap: () {
          List<Exercise> cloned = workout.exercises.map((ex) => Exercise()..name = ex.name..region = ex.region..sets = ex.sets.map((s) => ExerciseSet()..kg = s.kg..reps = s.reps..isCompleted = false).toList()).toList();
          Workout newW = Workout()..name = workout.name..date = DateTime.now()..exercises = cloned;
          Navigator.push(context, MaterialPageRoute(builder: (_) => ActiveWorkoutPage(workout: newW, autoStart: true)));
        },
      ),
    );
  }

  Widget _buildHeroButton(bool isDark) {
    return GestureDetector(
      onTap: () => _showStartWorkoutDialog(isDark), // Popup tetikleniyor
      child: Container(
        width: double.infinity, height: 50, 
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: isDark ? [const Color(0xFF1E293B), const Color(0xFF0F172A)] : [const Color(0xFF3B82F6), const Color(0xFF2563EB)]),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(child: Text("ANTREMANA BAŞLA", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14))),
      ),
    );
  }

Widget _buildDisclaimer(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? Colors.amber.withOpacity(0.05) : Colors.amber.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.amber.withOpacity(0.2) : Colors.amber.withOpacity(0.3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.tips_and_updates_rounded, 
            color: isDark ? Colors.amber.shade300 : Colors.amber.shade700,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              "Başlangıç Seviyesi programlarımız, genel adaptasyon sürecini desteklemek amacıyla global fitness standartları çerçevesinde kurgulanmıştır. Bu içerikler kişiye özel bir reçete veya tıbbi tavsiye niteliği taşımamaktadır. Kronik rahatsızlığı veya fiziksel kısıtlaması olan kullanıcıların, antrenmanlara başlamadan önce bir profesyonele danışması önem arz eder.",
              style: TextStyle(
                color: isDark ? Colors.amber.shade100 : Colors.amber.shade900,
                fontSize: 10.5,
                height: 1.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}