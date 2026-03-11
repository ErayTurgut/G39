import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart'; // Eklendi
import '../models/workout_model.dart';
import '../services/isar_service.dart';
import '../services/app_settings.dart'; // Eklendi
import '../services/exercise_muscle_map.dart';

enum ProgressMode { exercise, weekly }
enum ProgressType { max, volume }

class ProgressPage extends StatefulWidget {
  const ProgressPage({super.key});

  @override
  State<ProgressPage> createState() => _ProgressPageState();
}

class _ProgressPageState extends State<ProgressPage> {
  ProgressMode selectedMode = ProgressMode.exercise;
  ProgressType selectedType = ProgressType.max;

  List<String> exerciseNames = [];
  String? selectedExercise;

  List<FlSpot> spots = [];
  List<FlSpot> avgSpots = [];

  double maxYValue = 0;
  double prValue = 0;

  bool plateauDetected = false;
  bool smoothGraph = false;

  int weeklyWorkoutCount = 0;
  double weeklyVolume = 0;
  double weeklyStrongest = 0;

  int previousWorkoutCount = 0;
  double previousVolume = 0;
  double previousStrongest = 0;

  int currentPRStreak = 0;
  int longestPRStreak = 0;

  double lifetimeVolume = 0;
  int totalWorkoutCount = 0;
  List<String> unlockedAchievements = [];

  Exercise? lastWorkoutExercise;
  Exercise? previousWorkoutExercise;

  bool _isDisposed = false;

  /* ---------- EKLENEN ---------- */
  int workoutStreak = 0;
  // Artık weeklyGoal değişkeni burada sabit tutulmuyor, build içerisinde AppSettings'ten alınıyor.
  /* ----------------------------- */

  @override
  void initState() {
    super.initState();
    _initLoad();
  }

  Future<void> _initLoad() async {
    await _loadDistinctExercises();
    await _loadWeeklyStats();
    await _calculatePRStreak();
    await _calculateWorkoutStreak();
  }

  DateTime _startOfWeek(DateTime date) {
    final monday = date.subtract(Duration(days: date.weekday - 1));
    return DateTime(monday.year, monday.month, monday.day);
  }

  double _calculate1RM(double kg, int reps) {
    return kg * (1 + reps / 30);
  }

  bool _isBetween(DateTime date, DateTime start, DateTime end) {
    return !date.isBefore(start) && date.isBefore(end);
  }

  /* ---------- EKLENEN ---------- */
  Future<void> _calculateWorkoutStreak() async {
    final workouts = await IsarService.getWorkouts();

    if (workouts.isEmpty) return;

    workouts.sort((a, b) => b.date.compareTo(a.date));

    int streak = 0;
    DateTime checkDate = DateTime.now();

    for (var w in workouts) {
      final diff = checkDate.difference(w.date).inDays;

      if (diff == 0 || diff == 1) {
        streak++;
        checkDate = w.date.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }

    if (!mounted) return;
    setState(() {
      workoutStreak = streak;
    });
  }
  /* ----------------------------- */

  Future<void> _calculatePRStreak() async {
    final workouts = await IsarService.getWorkoutsAsc();
    if (!mounted || _isDisposed) return;

    Map<String, double> lastPR = {};

    int streak = 0;
    int maxStreak = 0;

    for (var w in workouts) {
      bool improved = false;

      for (var ex in w.exercises) {
        for (var s in ex.sets) {
          if (!s.isCompleted) continue;

          final oneRM = _calculate1RM(s.kg, s.reps);
          final prev = lastPR[ex.name] ?? 0;

          if (oneRM > prev) {
            lastPR[ex.name] = oneRM;
            improved = true;
          }
        }
      }

      if (improved) {
        streak++;
        if (streak > maxStreak) maxStreak = streak;
      } else {
        streak = 0;
      }
    }

    setState(() {
      currentPRStreak = streak;
      longestPRStreak = maxStreak;
    });

    await _loadAchievements();
  }

  Future<void> _loadAchievements() async {
    final workouts = await IsarService.getWorkoutsAsc();
    if (!mounted || _isDisposed) return;

    double totalVol = 0;

    for (var w in workouts) {
      for (var ex in w.exercises) {
        for (var s in ex.sets) {
          if (!s.isCompleted) continue;
          totalVol += s.kg * s.reps;
        }
      }
    }

    List<String> badges = [];

    if (totalVol >= 10000) badges.add("🥉 10K Volume");
    if (totalVol >= 50000) badges.add("🥈 50K Volume");
    if (totalVol >= 100000) badges.add("🥇 100K Volume");
    if (totalVol >= 250000) badges.add("💎 250K Volume");

    if (workouts.length >= 10) badges.add("🔥 10 Workouts");
    if (workouts.length >= 25) badges.add("🔥 25 Workouts");
    if (workouts.length >= 50) badges.add("🔥 50 Workouts");
    if (workouts.length >= 100) badges.add("🔥 100 Workouts");

    if (currentPRStreak >= 3) badges.add("⚡ 3 PR Streak");
    if (currentPRStreak >= 5) badges.add("⚡ 5 PR Streak");
    if (currentPRStreak >= 10) badges.add("⚡ 10 PR Streak");

    if (prValue > 0) badges.add("🏆 First PR");

    setState(() {
      lifetimeVolume = totalVol;
      totalWorkoutCount = workouts.length;
      unlockedAchievements = badges;
    });
  }

  Future<void> _loadWeeklyStats() async {
    final workouts = await IsarService.getWorkoutsAsc();
    if (!mounted || _isDisposed) return;

    final now = DateTime.now();

    final currentWeekStart = _startOfWeek(now);
    final currentWeekEnd = currentWeekStart.add(const Duration(days: 7));

    final previousWeekStart = currentWeekStart.subtract(const Duration(days: 7));

    final previousWeekEnd = previousWeekStart.add(const Duration(days: 7));

    int currentCount = 0;
    int previousCount = 0;

    double currentVol = 0;
    double previousVol = 0;

    double currentStrong = 0;
    double previousStrong = 0;

    for (var w in workouts) {
      final date = DateTime(w.date.year, w.date.month, w.date.day);

      final isCurrent = _isBetween(date, currentWeekStart, currentWeekEnd);

      final isPrevious = _isBetween(date, previousWeekStart, previousWeekEnd);

      if (isCurrent) currentCount++;
      if (isPrevious) previousCount++;

      for (var ex in w.exercises) {
        for (var s in ex.sets) {
          if (!s.isCompleted) continue;

          final volume = s.kg * s.reps;
          final oneRM = _calculate1RM(s.kg, s.reps);

          if (isCurrent) {
            currentVol += volume;
            if (oneRM > currentStrong) currentStrong = oneRM;
          }

          if (isPrevious) {
            previousVol += volume;
            if (oneRM > previousStrong) previousStrong = oneRM;
          }
        }
      }
    }

    setState(() {
      weeklyWorkoutCount = currentCount;
      weeklyVolume = currentVol;
      weeklyStrongest = currentStrong;
      previousWorkoutCount = previousCount;
      previousVolume = previousVol;
      previousStrongest = previousStrong;
    });
  }

  Future<void> _loadDistinctExercises() async {
    final workouts = await IsarService.getWorkouts();
    if (!mounted || _isDisposed) return;

    final names = <String>{};

    for (var w in workouts) {
      for (var ex in w.exercises) {
        names.add(ex.name);
      }
    }

    setState(() {
      exerciseNames = names.toList()..sort();
    });
  }

  Future<void> _loadProgress(String exerciseName) async {
    final workouts = await IsarService.getWorkoutsAsc();
    if (!mounted || _isDisposed) return;

    final tempSpots = <FlSpot>[];
    final tempAvg = <FlSpot>[];

    double tempMax = 0;
    double tempPR = 0;

    int index = 0;

    List<Exercise> matchingExercises = [];

    for (var w in workouts) {
      for (var ex in w.exercises) {
        if (ex.name == exerciseName) {
          matchingExercises.add(ex);

          double value = 0;

          if (selectedType == ProgressType.max) {
            for (var s in ex.sets) {
              if (s.kg > value) value = s.kg;
            }
          } else {
            for (var s in ex.sets) {
              value += s.kg * s.reps;
            }
          }

          if (value > tempPR) tempPR = value;
          if (value > tempMax) tempMax = value;

          tempSpots.add(FlSpot(index.toDouble(), value));
          index++;
        }
      }
    }

    for (int i = 0; i < tempSpots.length; i++) {
      double sum = 0;
      int count = 0;

      for (int j = i - 2; j <= i; j++) {
        if (j >= 0) {
          sum += tempSpots[j].y;
          count++;
        }
      }

      tempAvg.add(FlSpot(tempSpots[i].x, sum / count));
    }

    bool plateau = false;

    if (tempSpots.length >= 4) {
      final last = tempSpots.last.y;
      final prev = tempSpots[tempSpots.length - 4].y;

      if ((last - prev).abs() < 1) {
        plateau = true;
      }
    }

    Exercise? last;
    Exercise? prev;

    if (matchingExercises.length >= 2) {
      last = matchingExercises.last;
      prev = matchingExercises[matchingExercises.length - 2];
    }

    setState(() {
      spots = tempSpots;
      avgSpots = tempAvg;

      maxYValue = tempMax;
      prValue = tempPR;

      plateauDetected = plateau;

      lastWorkoutExercise = last;
      previousWorkoutExercise = prev;
    });
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    /* ---------- DEGISIKLIK BURADA ---------- */
    final settings = context.watch<AppSettings>(); // Ayarları dinle
    final int weeklyGoal = settings.weeklyGoal; // Güncel hedefi al
    final double weeklyGoalProgress = weeklyWorkoutCount / weeklyGoal; // İlerlemeyi hesapla
    /* --------------------------------------- */

    return Scaffold(
      appBar: AppBar(title: const Text("Progress")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ToggleButtons(
              isSelected: [
                selectedMode == ProgressMode.exercise,
                selectedMode == ProgressMode.weekly
              ],
              onPressed: (index) {
                setState(() {
                  selectedMode = index == 0 ? ProgressMode.exercise : ProgressMode.weekly;
                });
              },
              children: const [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Text("Exercise"),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Text("Weekly"),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: selectedMode == ProgressMode.exercise
                  ? _buildExerciseMode()
                  : _buildWeeklyMode(weeklyGoal, weeklyGoalProgress), // Degiskenleri gonder
            )
          ],
        ),
      ),
    );
  }

  /* Exercise mode tamamen aynı bırakıldı */

  Widget _buildExerciseMode() {
    return Column(
      children: [
        DropdownButton<String>(
          value: exerciseNames.contains(selectedExercise) ? selectedExercise : null,
          hint: const Text("Hareket Seç"),
          isExpanded: true,
          items: exerciseNames
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: (val) {
            if (val == null) return;

            setState(() => selectedExercise = val);

            _loadProgress(val);
          },
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "PR: ${prValue.toStringAsFixed(1)}",
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Switch(
              value: smoothGraph,
              onChanged: (v) {
                setState(() => smoothGraph = v);
              },
            )
          ],
        ),
        const SizedBox(height: 20),
        Expanded(
          child: spots.isEmpty
              ? const Center(child: Text("Veri yok"))
              : LineChart(
                  LineChartData(
                    minX: 0,
                    maxX: spots.length <= 1 ? 1 : (spots.length - 1).toDouble(),
                    minY: 0,
                    maxY: maxYValue == 0 ? 10 : maxYValue * 1.2,
                    titlesData: FlTitlesData(
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          interval: 5,
                          reservedSize: 40,
                          getTitlesWidget: (value, meta) {
                            if (value % 5 != 0) {
                              return const SizedBox();
                            }

                            return Text(
                              value.toInt().toString(),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            );
                          },
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          interval: 1,
                          getTitlesWidget: (value, meta) {
                            return Text(
                              "W${value.toInt() + 1}",
                              style: const TextStyle(fontSize: 10),
                            );
                          },
                        ),
                      ),
                    ),
                    lineTouchData: LineTouchData(
                      enabled: true,
                      touchTooltipData: LineTouchTooltipData(
                        getTooltipColor: (touchedSpot) => Colors.black,
                      ),
                    ),
                    lineBarsData: [
                      if (!smoothGraph)
                        LineChartBarData(
                          spots: spots,
                          isCurved: true,
                          barWidth: 4,
                          color: Colors.blueAccent,
                          dotData: FlDotData(
                            show: true,
                            getDotPainter: (spot, percent, bar, index) {
                              if ((spot.y - prValue).abs() < 0.01) {
                                return FlDotCirclePainter(
                                  radius: 6,
                                  color: Colors.amber,
                                  strokeWidth: 2,
                                  strokeColor: Colors.black,
                                );
                              }

                              return FlDotCirclePainter(
                                radius: 3,
                                color: Colors.blueAccent,
                              );
                            },
                          ),
                        ),
                      if (smoothGraph)
                        LineChartBarData(
                          spots: avgSpots,
                          isCurved: true,
                          barWidth: 3,
                          color: Colors.green,
                          dotData: const FlDotData(show: false),
                        ),
                    ],
                  ),
                ),
        ),
        if (lastWorkoutExercise != null && previousWorkoutExercise != null)
          _comparisonCard()
      ],
    );
  }

  Widget _comparisonCard() {
    double lastVolume = 0;
    double prevVolume = 0;

    for (var s in lastWorkoutExercise!.sets) {
      lastVolume += s.kg * s.reps;
    }

    for (var s in previousWorkoutExercise!.sets) {
      prevVolume += s.kg * s.reps;
    }

    final diff = lastVolume - prevVolume;

    return Card(
      margin: const EdgeInsets.only(top: 20),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Workout Comparison",
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text("Last volume: ${lastVolume.toStringAsFixed(0)}"),
            Text("Previous volume: ${prevVolume.toStringAsFixed(0)}"),
            Text(
              diff >= 0
                  ? "+${diff.toStringAsFixed(0)} improvement"
                  : "${diff.toStringAsFixed(0)} drop",
            )
          ],
        ),
      ),
    );
  }

  /* Weekly Mode — sadece buraya ekleme yapıldı */

  Widget _buildWeeklyMode(int weeklyGoal, double weeklyGoalProgress) {
    return ListView(
      children: [
        Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              "🔥 $workoutStreak Day Streak",
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Weekly Goal",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "$weeklyWorkoutCount / $weeklyGoal workouts",
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                LinearProgressIndicator(
                  value: weeklyGoalProgress > 1 ? 1 : weeklyGoalProgress,
                ),
              ],
            ),
          ),
        ),
        _compareCard(
            "Workouts", weeklyWorkoutCount, previousWorkoutCount),
        _compareCard("Volume (kg)", weeklyVolume, previousVolume),
        _compareCard(
            "Strongest Lift (1RM)", weeklyStrongest, previousStrongest),
        const SizedBox(height: 20),
        if (unlockedAchievements.isNotEmpty)
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: unlockedAchievements
                .map((a) => Chip(label: Text(a)))
                .toList(),
          )
      ],
    );
  }

  Widget _compareCard(String title, num current, num previous) {
    final diff = current - previous;
    final improved = diff >= 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              current.toStringAsFixed(0),
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(
                  improved ? Icons.arrow_upward : Icons.arrow_downward,
                  color: improved ? Colors.green : Colors.red,
                  size: 18,
                ),
                const SizedBox(width: 4),
                Text(
                  diff == 0
                      ? "No change"
                      : "${diff.toStringAsFixed(0)} vs last week",
                )
              ],
            )
          ],
        ),
      ),
    );
  }
}