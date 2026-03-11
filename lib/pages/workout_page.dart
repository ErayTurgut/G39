import 'package:flutter/material.dart';
import '../services/isar_service.dart';
import '../models/workout_model.dart';
import 'workout_detail_page.dart';
import 'active_exercise_page.dart';

class WorkoutPage extends StatefulWidget {
  const WorkoutPage({super.key});

  @override
  State<WorkoutPage> createState() => _WorkoutPageState();
}

class _WorkoutPageState extends State<WorkoutPage> {

  late Stream<void> favStream;

  @override
  void initState() {
    super.initState();
    favStream = IsarService.isar.workouts.watchLazy(fireImmediately: true);
  }

  void _startWorkout() {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text("Workout Name"),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: "Enter workout name",
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                if (controller.text.isEmpty) return;

                Navigator.pop(dialogContext);

                /// 🔥 ESKİ: '/exercise' route gidiyordu
                /// 🔥 YENİ: checkbox + timer olan sayfa açılıyor
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ActiveExercisePage(
                      workoutName: controller.text,
                    ),
                  ),
                );
              },
              child: const Text("Start"),
            ),
          ],
        );
      },
    );
  }

  Future<List<Workout>> _loadFavorites() async {
    final all = await IsarService.getWorkouts();
    return all.where((w) => w.isFavorite).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Workout')),
      body: StreamBuilder<void>(
        stream: favStream,
        builder: (context, snapshot) {
          return FutureBuilder<List<Workout>>(
            future: _loadFavorites(),
            builder: (context, snap) {

              final favorites = snap.data ?? [];

              return Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 60,
                      child: ElevatedButton(
                        onPressed: _startWorkout,
                        child: const Text(
                          "ANTREMANA BAŞLA",
                          style: TextStyle(fontSize: 18),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Favori Antremanlar",
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: favorites.isEmpty
                          ? const Center(child: Text("Henüz favori yok"))
                          : ListView.builder(
                              itemCount: favorites.length,
                              itemBuilder: (context, index) {
                                final fav = favorites[index];

                                return Card(
                                  child: ListTile(
                                    leading: const Icon(Icons.star, color: Colors.amber),
                                    title: Text(fav.name),
                                    subtitle: Text(fav.date.toString()),
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              WorkoutDetailPage(workout: fav),
                                        ),
                                      );
                                    },
                                  ),
                                );
                              },
                            ),
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