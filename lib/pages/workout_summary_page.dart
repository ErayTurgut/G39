import 'package:flutter/material.dart';
import '../models/workout_model.dart';
import '../services/isar_service.dart'; // Senin servisin

class WorkoutSummaryPage extends StatefulWidget {
  final Workout workout;
  final int totalSeconds;

  const WorkoutSummaryPage({
    super.key,
    required this.workout,
    required this.totalSeconds,
  });

  @override
  State<WorkoutSummaryPage> createState() => _WorkoutSummaryPageState();
}

class _WorkoutSummaryPageState extends State<WorkoutSummaryPage> {
  double strongest1RM = 0;
  String strongest1RMExercise = "";
  double maxWeight = 0;
  String maxWeightExercise = "";
  
  // Tüm zamanların rekorlarını tutacak map
  Map<String, double> allTimePRs = {};
  bool isLoadingPRs = true;

  @override
  void initState() {
    super.initState();
    _calculateStats();
    _calculateAllTimePRs();
  }

  void _calculateStats() {
    double top1RM = 0;
    String top1RMEx = "";
    double topWeight = 0;
    String topWeightEx = "";

    for (final ex in widget.workout.exercises) {
      for (final s in ex.sets) {
        if (s.kg <= 0) continue;
        
        final current1RM = s.kg * (1 + s.reps / 30);
        if (current1RM > top1RM) {
          top1RM = current1RM;
          top1RMEx = ex.name;
        }

        if (s.kg > topWeight) {
          topWeight = s.kg;
          topWeightEx = ex.name;
        }
      }
    }
    setState(() {
      strongest1RM = top1RM;
      strongest1RMExercise = top1RMEx;
      maxWeight = topWeight;
      maxWeightExercise = topWeightEx;
    });
  }

  // --- SENİN SERVİSİNİ KULLANARAK REKORLARI HESAPLAYAN KISIM ---
  Future<void> _calculateAllTimePRs() async {
    // Senin servisinden tüm geçmişi çekiyoruz
    final allWorkouts = await IsarService.getWorkouts();
    Map<String, double> tempPRs = {};

    for (var w in allWorkouts) {
      // Eğer bu workout şu an bitirdiğimiz antrenmansa, rekor karşılaştırması için onu atla
      if (w.id == widget.workout.id && widget.workout.id != 0) continue;

      for (var ex in w.exercises) {
        for (var s in ex.sets) {
          if (!tempPRs.containsKey(ex.name) || s.kg > tempPRs[ex.name]!) {
            tempPRs[ex.name] = s.kg;
          }
        }
      }
    }

    setState(() {
      allTimePRs = tempPRs;
      isLoadingPRs = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    int totalSets = 0;
    Set<String> regions = {};
    for (final ex in widget.workout.exercises) {
      totalSets += ex.sets.length;
      if (ex.region.isNotEmpty) regions.add(ex.region);
    }
    String regionsText = regions.isEmpty ? "Genel" : regions.join(", ");

    return Scaffold(
      backgroundColor: const Color(0xFF050816),
      appBar: AppBar(
        backgroundColor: const Color(0xFF111018),
        title: const Text("Antrenman Özeti"),
        elevation: 0,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: ListView(
                children: [
                  _headerCard(),
                  const SizedBox(height: 16),
                  _dashboardRow(totalSets, regionsText),
                  const SizedBox(height: 24),

                  const Text("Bugünün Analizi", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white70)),
                  const SizedBox(height: 12),
                  
                  // AKILLI PR KARTI
                  if (maxWeight > 0)
                    _smartPRCard(
                      title: "Günün En Ağırı",
                      exercise: maxWeightExercise,
                      weight: maxWeight,
                      allTimeMax: allTimePRs[maxWeightExercise] ?? 0,
                      icon: Icons.fitness_center,
                      color: const Color(0xFF1E1B4B),
                    ),
                  
                  const SizedBox(height: 8),

                  if (strongest1RM > 0)
                    _prCard(
                      title: "Tahmini 1RM (Güç)",
                      subtitle: "$strongest1RMExercise - ${strongest1RM.toStringAsFixed(1)} kg",
                      icon: Icons.bolt,
                      color: const Color(0xFF312E81),
                    ),

                  const SizedBox(height: 24),
                  const Text("Egzersiz Detayları", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 12),

                  ...widget.workout.exercises.map((ex) => _exerciseTile(ex)),
                ],
              ),
            ),
            _finishButton(context),
          ],
        ),
      ),
    );
  }

  Widget _smartPRCard({required String title, required String exercise, required double weight, required double allTimeMax, required IconData icon, required Color color}) {
    // Eğer bugünkü ağırlık, geçmiş rekorlardan büyükse yeni rekor sayılır
    bool isNewRecord = allTimeMax == 0 || weight > allTimeMax;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isNewRecord ? Colors.orangeAccent.withOpacity(0.5) : Colors.white10),
      ),
      child: Row(
        children: [
          Icon(icon, color: isNewRecord ? Colors.orangeAccent : Colors.white24, size: 24),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white60, fontSize: 12)),
                const SizedBox(height: 2),
                Text("$exercise - $weight kg", style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                if (isNewRecord && allTimeMax > 0)
                  const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Text("🔥 YENİ KİŞİSEL REKOR!", style: TextStyle(color: Colors.orangeAccent, fontSize: 11, fontWeight: FontWeight.bold)),
                  )
                else if (allTimeMax > 0)
                   Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text("Kişisel Rekorun: $allTimeMax kg", style: const TextStyle(color: Colors.white38, fontSize: 11)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- DİĞER YARDIMCI WIDGET'LAR ---

  Widget _headerCard() {
    return Container(
      width: double.infinity, padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF1E293B), Color(0xFF0F172A)]),
        borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white10),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.workspace_premium, color: Colors.orangeAccent, size: 28),
          SizedBox(width: 12),
          Text("Gelişim Kaydedildi!", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _dashboardRow(int totalSets, String regionsText) {
    return Row(
      children: [
        Expanded(child: _statBox(title: "Süre", value: "${(widget.totalSeconds ~/ 60)} dk", icon: Icons.timer_outlined)),
        const SizedBox(width: 6),
        Expanded(child: _statBox(title: "Hareket", value: "${widget.workout.exercises.length}", icon: Icons.fitness_center)),
        const SizedBox(width: 6),
        Expanded(child: _statBox(title: "Set", value: "$totalSets", icon: Icons.reorder)),
        const SizedBox(width: 6),
        Expanded(child: _statBox(title: "Bölge", value: regionsText, icon: Icons.accessibility_new, isSmallText: true)),
      ],
    );
  }

  Widget _statBox({required String title, required String value, required IconData icon, bool isSmallText = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
      decoration: BoxDecoration(color: const Color(0xFF101826), borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.white10)),
      child: Column(
        children: [
          Icon(icon, color: Colors.blueAccent, size: 16),
          const SizedBox(height: 6),
          Text(title, style: const TextStyle(color: Colors.white54, fontSize: 10)),
          const SizedBox(height: 2),
          Text(value, textAlign: TextAlign.center, style: TextStyle(fontSize: isSmallText ? 10 : 14, fontWeight: FontWeight.bold, color: Colors.white), maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _prCard({required String title, required String subtitle, required IconData icon, required Color color}) {
    return Container(
      width: double.infinity, padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(18), border: Border.all(color: Colors.white.withOpacity(0.05))),
      child: Row(
        children: [
          Icon(icon, color: Colors.orangeAccent, size: 24),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white60, fontSize: 12)),
            Text(subtitle, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
          ])),
        ],
      ),
    );
  }

  Widget _exerciseTile(Exercise ex) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: const Color(0xFF101826), borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(ex.name, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
            Text(ex.region, style: const TextStyle(color: Colors.blueAccent, fontSize: 11)),
          ]),
          const SizedBox(height: 8),
          Wrap(spacing: 8, children: ex.sets.asMap().entries.map((e) => Text("S${e.key + 1}: ${e.value.kg}kg x ${e.value.reps}", style: const TextStyle(color: Colors.white60, fontSize: 12))).toList()),
        ],
      ),
    );
  }

  Widget _finishButton(BuildContext context) {
    return SizedBox(
      width: double.infinity, height: 56,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3B82F6), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
        onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
        child: const Text("ANTRENMANI TAMAMLA", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
      ),
    );
  }
}