import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../models/workout_model.dart';
import '../services/isar_service.dart';
import '../services/app_settings.dart';
import 'paywall_screen.dart';

enum ProgressMode { exercise, weekly, calorie }
enum TimeRange { oneMonth, threeMonths, sixMonths, all }

class ProgressPage extends StatefulWidget {
  const ProgressPage({super.key});

  @override
  State<ProgressPage> createState() => _ProgressPageState();
}

class _ProgressPageState extends State<ProgressPage> {
  ProgressMode selectedMode = ProgressMode.exercise;
  TimeRange selectedRange = TimeRange.all;
  TimeRange calorieSelectedRange = TimeRange.oneMonth;

  List<String> exerciseNames = [];
  String? selectedExercise;

  List<FlSpot> allSpots = [];
  List<FlSpot> filteredSpots = [];
  double prValue = 0;

  int weeklyWorkoutCount = 0;
  double weeklyVolume = 0;
  double weeklyStrongest = 0;
  int workoutStreak = 0;

  int previousWorkoutCount = 0;
  double previousVolume = 0;
  double previousStrongest = 0;

  double todayCalories = 0;
  List<CalorieEntry> todayEntries = [];
  
  List<FlSpot> calorieSpots = [];
  List<FlSpot> proteinSpots = [];
  List<FlSpot> carbSpots = [];
  List<FlSpot> fatSpots = [];

  bool _isLoading = true;
  late Stream<void> workoutStream;

  @override
  void initState() {
    super.initState();
    workoutStream = IsarService.isar.workouts.watchLazy(fireImmediately: true);
    _initialFetch();
  }

  Future<void> _initialFetch() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    await _loadAllData();
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _loadAllData() async {
    await Future.wait([
      _loadDistinctExercises(),
      _loadWeeklyStats(),
      _calculateWorkoutStreak(),
      _loadCalorieData(),
    ]);
  }

  Future<void> _loadDistinctExercises() async {
    final workouts = await IsarService.getWorkouts();
    final Set<String> practicedNames = {};
    for (var w in workouts) {
      for (var ex in w.exercises) {
        if (ex.sets.any((s) => s.isCompleted)) {
          practicedNames.add(ex.name);
        }
      }
    }
    if (!mounted) return;
    setState(() {
      exerciseNames = practicedNames.toList()..sort();
      if (selectedExercise != null && exerciseNames.contains(selectedExercise)) {
        _loadProgress(selectedExercise!);
      }
    });
  }

  Future<void> _loadCalorieData() async {
    final entries = await IsarService.getCaloriesByDate(DateTime.now());
    double tCals = entries.fold(0, (sum, e) => sum + e.amount);

    final List<FlSpot> tempCalorieSpots = [];
    final List<FlSpot> tempProteinSpots = [];
    final List<FlSpot> tempCarbSpots = [];
    final List<FlSpot> tempFatSpots = [];

    int daysToFetch = 30;
    switch (calorieSelectedRange) {
      case TimeRange.oneMonth: daysToFetch = 30; break;
      case TimeRange.threeMonths: daysToFetch = 90; break;
      case TimeRange.sixMonths: daysToFetch = 180; break;
      case TimeRange.all: daysToFetch = 365; break;
    }

    for (int i = daysToFetch - 1; i >= 0; i--) {
      final date = DateTime.now().subtract(Duration(days: i));
      final totals = await IsarService.getDailyTotals(date);
      double xVal = (daysToFetch - 1 - i).toDouble();
      tempCalorieSpots.add(FlSpot(xVal, totals['calories']!));
      tempProteinSpots.add(FlSpot(xVal, totals['protein']!));
      tempCarbSpots.add(FlSpot(xVal, totals['carbs']!));
      tempFatSpots.add(FlSpot(xVal, totals['fat']!));
    }

    if (!mounted) return;
    setState(() {
      todayCalories = tCals;
      todayEntries = entries;
      calorieSpots = tempCalorieSpots;
      proteinSpots = tempProteinSpots;
      carbSpots = tempCarbSpots;
      fatSpots = tempFatSpots;
    });
  }

  double _calculate1RM(double kg, int reps) => kg * (1 + reps / 30);

  Future<void> _calculateWorkoutStreak() async {
    final workouts = await IsarService.getWorkouts();
    if (workouts.isEmpty) {
      if (mounted) setState(() => workoutStreak = 0);
      return;
    }
    workouts.sort((a, b) => b.date.compareTo(a.date));
    int streak = 0;
    DateTime checkDate = DateTime.now();
    for (var w in workouts) {
      final diff = DateTime(checkDate.year, checkDate.month, checkDate.day)
          .difference(DateTime(w.date.year, w.date.month, w.date.day)).inDays;
      if (diff == 0 || diff == 1) {
        streak++;
        checkDate = w.date.subtract(const Duration(days: 1));
      } else if (diff > 1) { break; }
    }
    if (mounted) setState(() => workoutStreak = streak);
  }

  Future<void> _loadWeeklyStats() async {
    final workouts = await IsarService.getWorkoutsAsc();
    final now = DateTime.now();
    final cWS = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));
    final cWE = cWS.add(const Duration(days: 7));
    final pWS = cWS.subtract(const Duration(days: 7));
    final pWE = pWS.add(const Duration(days: 7));

    int cC = 0, pC = 0;
    double cV = 0, pV = 0, cS = 0, pS = 0;

    for (var w in workouts) {
      final d = DateTime(w.date.year, w.date.month, w.date.day);
      bool isC = !d.isBefore(cWS) && d.isBefore(cWE);
      bool isP = !d.isBefore(pWS) && d.isBefore(pWE);
      if (isC) cC++; if (isP) pC++;

      for (var ex in w.exercises) {
        for (var s in ex.sets) {
          if (!s.isCompleted) continue;
          final current1RM = _calculate1RM(s.kg, s.reps);
          if (isC) { cV += s.kg * s.reps; if (current1RM > cS) cS = current1RM; }
          if (isP) { pV += s.kg * s.reps; if (current1RM > pS) pS = current1RM; }
        }
      }
    }
    if (mounted) {
      setState(() {
        weeklyWorkoutCount = cC; weeklyVolume = cV; weeklyStrongest = cS;
        previousWorkoutCount = pC; previousVolume = pV; previousStrongest = pS;
      });
    }
  }

  Future<void> _loadProgress(String exerciseName) async {
    final workouts = await IsarService.getWorkoutsAsc();
    final tempSpots = <FlSpot>[];
    double tempPR = 0;
    int workoutIndex = 0;

    for (var w in workouts) {
      double workoutMax = 0;
      bool foundInWorkout = false;
      for (var ex in w.exercises) {
        if (ex.name == exerciseName) {
          for (var s in ex.sets) {
            if (s.isCompleted && s.kg > workoutMax) {
              workoutMax = s.kg;
              foundInWorkout = true;
            }
          }
        }
      }
      if (foundInWorkout && workoutMax > 0) {
        if (workoutMax > tempPR) tempPR = workoutMax;
        tempSpots.add(FlSpot(workoutIndex.toDouble(), workoutMax));
        workoutIndex++;
      }
    }

    if (mounted) {
      setState(() {
        allSpots = tempSpots;
        prValue = tempPR;
        _applyTimeFilter();
      });
    }
  }

  void _applyTimeFilter() {
    if (allSpots.isEmpty) {
      setState(() { filteredSpots = []; });
      return;
    }
    int countToKeep = allSpots.length;
    switch (selectedRange) {
      case TimeRange.oneMonth: countToKeep = 8; break;
      case TimeRange.threeMonths: countToKeep = 24; break;
      case TimeRange.sixMonths: countToKeep = 48; break;
      case TimeRange.all: countToKeep = allSpots.length; break;
    }
    setState(() {
      filteredSpots = allSpots.length > countToKeep 
          ? allSpots.sublist(allSpots.length - countToKeep) 
          : List.from(allSpots);
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

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: appBarColor,
        elevation: isDark ? 0 : 1,
        toolbarHeight: 50,
        title: Text("GELİŞİM ANALİZİ", 
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold, letterSpacing: 1.1, fontSize: 14)),
        centerTitle: true,
      ),
      body: StreamBuilder<void>(
        stream: workoutStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.active) {
            _loadAllData();
          }

          return _isLoading 
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF3B82F6)))
            : Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Column(children: [
                  _modeSwitcher(cardColor, textColor, isDark),
                  const SizedBox(height: 16),
                  Expanded(child: _buildCurrentTab(settings, cardColor, textColor, isDark))
                ]),
              );
        }
      ),
    );
  }

  Widget _modeSwitcher(Color cardColor, Color textColor, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: isDark ? Colors.white10 : Colors.black12)),
      child: Row(children: [
        _modeBtn("Egzersiz", ProgressMode.exercise, isDark),
        _modeBtn("Haftalık", ProgressMode.weekly, isDark),
        _modeBtn("Beslenme", ProgressMode.calorie, isDark), 
      ]),
    );
  }

  Widget _modeBtn(String lbl, ProgressMode mode, bool isDark) {
    bool active = selectedMode == mode;
    return Expanded(child: GestureDetector(
      onTap: () => setState(() => selectedMode = mode),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF3B82F6) : Colors.transparent, 
          borderRadius: BorderRadius.circular(10)
        ),
        child: Text(lbl, textAlign: TextAlign.center, 
          style: TextStyle(color: active ? Colors.white : (isDark ? Colors.white38 : Colors.black38), fontWeight: FontWeight.bold, fontSize: 12)),
      ),
    ));
  }

  Widget _buildCurrentTab(AppSettings settings, Color cardColor, Color textColor, bool isDark) {
    final Color subTextColor = isDark ? Colors.white38 : Colors.black45;
    switch (selectedMode) {
      case ProgressMode.exercise:
        return _buildExerciseTab(cardColor, textColor, subTextColor, isDark, settings);
      case ProgressMode.weekly:
        final progPercent = settings.weeklyGoal > 0 ? weeklyWorkoutCount / settings.weeklyGoal : 0.0;
        return _buildWeeklyTab(settings.weeklyGoal, progPercent, cardColor, textColor, subTextColor, isDark);
      case ProgressMode.calorie:
        return _buildCalorieTab(cardColor, textColor, subTextColor, isDark, settings);
    }
  }

  Widget _buildCalorieTab(Color cardColor, Color textColor, Color subTextColor, bool isDark, AppSettings settings) {
    final double goal = settings.calorieGoal;
    double percent = goal > 0 ? todayCalories / goal : 0;
    if (percent > 1.0) percent = 1.0;

    double tProt = 0; double tCarb = 0; double tFat = 0;
    for (var e in todayEntries) {
      tProt += e.protein ?? 0; tCarb += e.carbs ?? 0; tFat += e.fat ?? 0;
    }

    return Column(children: [
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardColor, borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
        ),
        child: Column(children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text("Bugün Alınan", style: TextStyle(color: subTextColor, fontSize: 11, fontWeight: FontWeight.bold)),
              Text("${todayCalories.toInt()} / ${goal.toInt()} kcal", 
                style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold)),
            ]),
            const Icon(Icons.local_fire_department_rounded, color: Colors.orangeAccent, size: 24),
          ]),
          const SizedBox(height: 12),
          _buildCustomProgressBar(percent, todayCalories > goal),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: _buildMiniMacroBar("PROTEİN", tProt, settings.proteinGoal, Colors.blueAccent, subTextColor, textColor)),
            const SizedBox(width: 12),
            Expanded(child: _buildMiniMacroBar("KARB", tCarb, settings.carbGoal, Colors.greenAccent, subTextColor, textColor)),
            const SizedBox(width: 12),
            Expanded(child: _buildMiniMacroBar("YAĞ", tFat, settings.fatGoal, Colors.redAccent, subTextColor, textColor)),
          ]),
        ]),
      ),
      const SizedBox(height: 16),
      _buildTimeRangeBar(calorieSelectedRange, (r) {
        if (!settings.isGraphUnlocked) {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const PaywallScreen()));
          return;
        }
        setState(() => calorieSelectedRange = r);
        _loadCalorieData(); 
      }, isDark),
      const SizedBox(height: 12),
      _buildCalorieChartSection(isDark, settings, subTextColor, cardColor),
      const SizedBox(height: 12),
      GestureDetector(
        onTap: () => _showMacroDialog(isDark), 
        child: Container(
          height: 48,
          decoration: BoxDecoration(color: const Color(0xFF3B82F6), borderRadius: BorderRadius.circular(12)),
          child: const Center(child: Text("BESLENME EKLE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13))),
        ),
      ),
      const SizedBox(height: 12),
      Expanded(
        child: todayEntries.isEmpty 
          ? Center(child: Text("Giriş yok", style: TextStyle(color: subTextColor, fontSize: 12)))
          : ListView.builder(
              itemCount: todayEntries.length,
              itemBuilder: (context, index) {
                final entry = todayEntries[index];
                final List<String> macros = [];
                if (entry.protein != null) macros.add("${entry.protein!.toInt()}g P");
                if (entry.carbs != null) macros.add("${entry.carbs!.toInt()}g C");
                if (entry.fat != null) macros.add("${entry.fat!.toInt()}g Y");
                return Dismissible(
                  key: Key(entry.id.toString()),
                  direction: DismissDirection.endToStart,
                  onDismissed: (_) async {
                    await IsarService.isar.writeTxn(() => IsarService.isar.calorieEntrys.delete(entry.id));
                    _loadCalorieData();
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: isDark ? Colors.white10 : Colors.black12)),
                    child: ListTile(
                      visualDensity: VisualDensity.compact,
                      title: Text("${entry.amount.toInt()} kcal", style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 13)),
                      subtitle: Text(macros.isNotEmpty ? macros.join(" • ") : "Sadece Kalori", style: TextStyle(color: subTextColor, fontSize: 11)),
                    ),
                  ),
                );
              },
            ),
      ),
    ]);
  }

  Widget _buildExerciseTab(Color cardColor, Color textColor, Color subTextColor, bool isDark, AppSettings settings) {
    return Column(children: [
      GestureDetector(
        onTap: () => _showSearchModal(isDark),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: isDark ? Colors.white10 : Colors.black12)),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(selectedExercise ?? "Egzersiz Seçin...", style: TextStyle(color: selectedExercise != null ? textColor : subTextColor, fontWeight: FontWeight.w600, fontSize: 13)),
            const Icon(Icons.search_rounded, color: Color(0xFF3B82F6), size: 20),
          ]),
        ),
      ),
      const SizedBox(height: 12),
      if (selectedExercise != null) ...[
        _buildTimeRangeBar(selectedRange, (r) {
          if (!settings.isGraphUnlocked) {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const PaywallScreen()));
            return;
          }
          setState(() { selectedRange = r; _applyTimeFilter(); });
        }, isDark),
        const SizedBox(height: 12),
        _headerInfoRow(textColor, subTextColor),
        const SizedBox(height: 16),
        Expanded(child: _buildLockedChart(isDark, settings, "PROGRESS ANALYTICS", subTextColor)),
      ] else
        Expanded(child: Center(child: Text("Verisi olan bir hareket seçin", style: TextStyle(color: subTextColor, fontSize: 12)))),
    ]);
  }

  Widget _buildWeeklyTab(int g, double pPercent, Color cardColor, Color textColor, Color subTextColor, bool isDark) {
    return ListView(children: [
      _summaryHeader("🔥 $workoutStreak GÜN SERİ", "Disiplinli ilerliyorsun!", isDark),
      const SizedBox(height: 12),
      _goalPanel(g, pPercent, cardColor, textColor, subTextColor, isDark),
      _compBox("Antrenman", weeklyWorkoutCount, previousWorkoutCount, "", cardColor, textColor, isDark),
      _compBox("Hacim", weeklyVolume, previousVolume, "kg", cardColor, textColor, isDark),
    ]);
  }

  // --- GRAFİK ÇİZİM FONKSİYONLARI ---

  Widget _buildProChart(bool isDark) {
    if (filteredSpots.isEmpty) return const Center(child: Text("Veri bulunamadı"));
    final Color subTextColor = isDark ? Colors.white30 : Colors.black38;

    return Padding(
      padding: const EdgeInsets.fromLTRB(5, 20, 15, 5),
      child: LineChart(
        LineChartData(
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (spot) => isDark ? const Color(0xFF1E293B) : Colors.white,
              getTooltipItems: (touchedSpots) => touchedSpots.map((spot) => LineTooltipItem(
                '${spot.y.toInt()} kg',
                TextStyle(color: spot.y >= prValue ? Colors.amber : (isDark ? Colors.white : Colors.black), fontWeight: FontWeight.bold),
              )).toList(),
            ),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: prValue > 0 ? prValue / 4 : 10,
            getDrawingHorizontalLine: (value) => FlLine(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05), strokeWidth: 1),
          ),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 35,
                interval: prValue > 0 ? prValue / 4 : 10,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toInt().toString(), 
                    style: TextStyle(
                      color: value.toInt() == prValue.toInt() ? Colors.amber : subTextColor, 
                      fontSize: 10, 
                      fontWeight: FontWeight.bold
                    ),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          minY: 0,
          maxY: prValue > 0 ? prValue * 1.15 : 100,
          lineBarsData: [
            LineChartBarData(
              spots: filteredSpots,
              isCurved: true,
              barWidth: 3,
              gradient: const LinearGradient(colors: [Color(0xFF3B82F6), Color(0xFF60A5FA)]),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [const Color(0xFF3B82F6).withOpacity(0.15), const Color(0xFF3B82F6).withOpacity(0)]),
              ),
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  bool isPeak = spot.y >= prValue;
                  return FlDotCirclePainter(
                    radius: isPeak ? 5 : 3, 
                    color: isPeak ? Colors.amber : Colors.black, 
                    strokeWidth: isPeak ? 2 : 1.5, 
                    strokeColor: isDark ? const Color(0xFF101826) : Colors.white
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  LineChartData _calorieChartData(bool isDark) {
    double maxVal = 0;
    for (var s in calorieSpots) if (s.y > maxVal) maxVal = s.y;
    for (var s in proteinSpots) if (s.y > maxVal) maxVal = s.y;
    for (var s in carbSpots) if (s.y > maxVal) maxVal = s.y;
    for (var s in fatSpots) if (s.y > maxVal) maxVal = s.y;
    
    double finalMaxY = maxVal > 0 ? maxVal * 1.2 : 2000;
    // Sol eksen için 4 parçalı interval
    double sideInterval = finalMaxY / 4;

    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: sideInterval,
        getDrawingHorizontalLine: (value) => FlLine(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05), strokeWidth: 1),
      ),
      titlesData: FlTitlesData(
        show: true,
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 35,
            interval: sideInterval,
            getTitlesWidget: (value, meta) {
              return Text(
                value.toInt().toString(), 
                style: const TextStyle(color: Colors.grey, fontSize: 8, fontWeight: FontWeight.bold),
              );
            },
          ),
        ),
      ),
      borderData: FlBorderData(show: false),
      lineBarsData: [
        LineChartBarData(spots: calorieSpots, isCurved: true, color: Colors.orangeAccent, barWidth: 3, dotData: const FlDotData(show: false)),
        LineChartBarData(spots: proteinSpots, isCurved: true, color: Colors.blueAccent, barWidth: 2, dotData: const FlDotData(show: false)),
        LineChartBarData(spots: carbSpots, isCurved: true, color: Colors.greenAccent, barWidth: 2, dotData: const FlDotData(show: false)),
        LineChartBarData(spots: fatSpots, isCurved: true, color: Colors.redAccent, barWidth: 2, dotData: const FlDotData(show: false)),
      ],
      minY: 0, 
      maxY: finalMaxY, 
    );
  }

  // --- YARDIMCI METOTLAR ---

  Widget _buildMiniMacroBar(String title, double current, int goal, Color color, Color subTextColor, Color textColor) {
    double percent = goal > 0 ? current / goal : 0;
    if (percent > 1.0) percent = 1.0;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(title, style: TextStyle(color: subTextColor, fontSize: 10, fontWeight: FontWeight.bold)),
        Text("${current.toInt()}/${goal}g", style: TextStyle(color: textColor, fontSize: 10, fontWeight: FontWeight.bold)),
      ]),
      const SizedBox(height: 4),
      Stack(children: [
        Container(height: 6, width: double.infinity, decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(10))),
        FractionallySizedBox(widthFactor: percent, child: Container(height: 6, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(10)))),
      ]),
    ]);
  }

  Widget _buildTimeRangeBar(TimeRange currentRange, ValueChanged<TimeRange> onChanged, bool isDark) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      _buildRangeBtn("1A", TimeRange.oneMonth, currentRange, onChanged, isDark),
      _buildRangeBtn("3A", TimeRange.threeMonths, currentRange, onChanged, isDark),
      _buildRangeBtn("6A", TimeRange.sixMonths, currentRange, onChanged, isDark),
      _buildRangeBtn("Hepsi", TimeRange.all, currentRange, onChanged, isDark),
    ]
  );

  Widget _buildRangeBtn(String lbl, TimeRange range, TimeRange currentRange, ValueChanged<TimeRange> onChanged, bool isDark) {
    bool active = currentRange == range;
    return GestureDetector(
      onTap: () => onChanged(range),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), 
        decoration: BoxDecoration(
          color: active ? const Color(0xFF3B82F6).withOpacity(0.1) : Colors.transparent, 
          borderRadius: BorderRadius.circular(8), 
          border: Border.all(color: active ? const Color(0xFF3B82F6) : (isDark ? Colors.white10 : Colors.black12))
        ), 
        child: Text(lbl, style: TextStyle(color: active ? (isDark ? Colors.white : const Color(0xFF3B82F6)) : (isDark ? Colors.white38 : Colors.black38), fontSize: 11, fontWeight: FontWeight.bold))
      ),
    );
  }

  Widget _buildLockedChart(bool isDark, AppSettings settings, String title, Color subTextColor) {
    if (settings.isGraphUnlocked) {
      return Container(
        decoration: BoxDecoration(color: isDark ? const Color(0xFF101826) : Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: isDark ? Colors.white10 : Colors.black12)),
        child: title.contains("PROGRESS") ? _buildProChart(isDark) : Padding(padding: const EdgeInsets.all(12), child: LineChart(_calorieChartData(isDark))),
      );
    }
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PaywallScreen())),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(color: isDark ? const Color(0xFF101826) : Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: isDark ? Colors.white10 : Colors.black12)),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.lock_rounded, color: Colors.amber, size: 30),
          const SizedBox(height: 8),
          Text("PRO ANALİZ PAKETİ", style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.bold, fontSize: 12)),
        ]),
      ),
    );
  }

  Widget _buildCalorieChartSection(bool isDark, AppSettings settings, Color subTextColor, Color cardColor) {
    return Container(
      height: 220, // Rakamlar için biraz daha alan ayırdım
      padding: const EdgeInsets.only(bottom: 8, top: 8),
      decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: isDark ? Colors.white10 : Colors.black12)),
      child: settings.isGraphUnlocked ? Column(children: [
          Padding(padding: const EdgeInsets.only(top: 4.0, left: 16, right: 16), child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                _buildLegendItem("Kalori", Colors.orangeAccent), _buildLegendItem("Protein", Colors.blueAccent), _buildLegendItem("Karb", Colors.greenAccent), _buildLegendItem("Yağ", Colors.redAccent),
              ],),),
          const SizedBox(height: 12),
          Expanded(child: Padding(padding: const EdgeInsets.only(right: 16.0, bottom: 8.0, left: 4.0), child: LineChart(_calorieChartData(isDark)),),),
        ],) : GestureDetector( 
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PaywallScreen())),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.lock_rounded, color: Colors.amber, size: 30),
          const SizedBox(height: 8),
          Text("PRO GRAFİK ANALİZİ", style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.bold, fontSize: 12)),
          const SizedBox(height: 4),
          Text("Gelişimini detaylı görmek için yükselt", style: TextStyle(color: subTextColor, fontSize: 10)),
        ]),
      ),
    );
  }

  Widget _buildLegendItem(String title, Color color) => Row(children: [
    Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
    const SizedBox(width: 4),
    Text(title, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
  ]);

  Widget _buildCustomProgressBar(double percent, bool isOver) {
    return Stack(children: [
      Container(height: 8, width: double.infinity, decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(10))),
      FractionallySizedBox(widthFactor: percent, child: Container(height: 8, decoration: BoxDecoration(gradient: LinearGradient(colors: isOver ? [Colors.redAccent, Colors.red] : [const Color(0xFF3B82F6), const Color(0xFF60A5FA)]), borderRadius: BorderRadius.circular(10)))),
    ]);
  }

  void _showSearchModal(bool isDark) {
    List<String> localFiltered = List.from(exerciseNames);
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: isDark ? const Color(0xFF111018) : Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => StatefulBuilder(builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, top: 20, left: 16, right: 16),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(autofocus: true, style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 14),
              decoration: InputDecoration(hintText: "Egzersiz Ara...", hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.black38, fontSize: 13), prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF3B82F6), size: 18), filled: true, fillColor: isDark ? Colors.white10 : Colors.black.withOpacity(0.05), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none), isDense: true, ),
              onChanged: (val) => setModalState(() => localFiltered = exerciseNames.where((e) => e.toLowerCase().contains(val.toLowerCase())).toList()),
            ),
            const SizedBox(height: 12),
            ConstrainedBox(constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.4), child: ListView.builder(shrinkWrap: true, itemCount: localFiltered.length, itemBuilder: (context, i) => ListTile(dense: true, title: Text(localFiltered[i], style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 13)), onTap: () { setState(() => selectedExercise = localFiltered[i]); _loadProgress(localFiltered[i]); Navigator.pop(context); }, ), ), ),
          ]),),),
    );
  }

  void _showMacroDialog(bool isDark) {
    final calCtrl = TextEditingController(); final pCtrl = TextEditingController(); final fCtrl = TextEditingController(); final cCtrl = TextEditingController();
    showDialog(context: context, builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF111018) : Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Beslenme Ekle", style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 16, fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [_buildMacroInput("Kalori (kcal)", calCtrl, isDark, Colors.orangeAccent), const SizedBox(height: 12), _buildMacroInput("Protein (g)", pCtrl, isDark, Colors.blueAccent), const SizedBox(height: 12), _buildMacroInput("Karbonhidrat (g)", cCtrl, isDark, Colors.greenAccent), const SizedBox(height: 12), _buildMacroInput("Yağ (g)", fCtrl, isDark, Colors.redAccent), ],)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("İPTAL", style: TextStyle(color: isDark ? Colors.white24 : Colors.black26, fontSize: 12))),
          ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3B82F6), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: () async {
              double? p = double.tryParse(pCtrl.text); double? c = double.tryParse(cCtrl.text); double? f = double.tryParse(fCtrl.text); double? cal = double.tryParse(calCtrl.text);
              if (cal == null && (p != null || c != null || f != null)) cal = ((p ?? 0) * 4) + ((c ?? 0) * 4) + ((f ?? 0) * 9);
              if (cal != null && cal > 0) { await IsarService.saveCalorie(cal, "Giriş", protein: p, carbs: c, fat: f); _loadCalorieData(); Navigator.pop(context); } 
              else { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Lütfen geçerli bir kalori veya makro girin!"))); }
            },
            child: const Text("EKLE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildMacroInput(String label, TextEditingController ctrl, bool isDark, Color color) => TextField(
    controller: ctrl, keyboardType: TextInputType.number, style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 15, fontWeight: FontWeight.bold),
    decoration: InputDecoration(labelText: label, labelStyle: TextStyle(color: isDark ? Colors.white38 : Colors.black38, fontSize: 13), enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: isDark ? Colors.white10 : Colors.black12), borderRadius: BorderRadius.circular(10)), focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: color, width: 2), borderRadius: BorderRadius.circular(10)), contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), ),
  );

  Widget _headerInfoRow(Color tc, Color stc) => Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [_infoBox("EN YÜKSEK", "${prValue.toInt()} kg", tc, stc), _infoBox("VERİ", "${filteredSpots.length} Kayıt", tc, stc), ]);
  Widget _infoBox(String t, String v, Color tc, Color stc) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(t, style: TextStyle(color: stc, fontSize: 9, fontWeight: FontWeight.bold)), Text(v, style: TextStyle(color: tc, fontWeight: FontWeight.bold, fontSize: 18)), ]);
  Widget _summaryHeader(String t, String s, bool isDark) => Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(gradient: LinearGradient(colors: isDark ? [const Color(0xFF1E293B), const Color(0xFF0F172A)] : [const Color(0xFF3B82F6), const Color(0xFF1E40AF)]), borderRadius: BorderRadius.circular(16)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(t, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)), Text(s, style: const TextStyle(color: Colors.white70, fontSize: 11))]));
  Widget _goalPanel(int g, double p, Color cc, Color tc, Color stc, bool id) => Container(padding: const EdgeInsets.all(16), margin: const EdgeInsets.only(bottom: 12), decoration: BoxDecoration(color: cc, borderRadius: BorderRadius.circular(16), border: Border.all(color: id ? Colors.white10 : Colors.black12)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text("Haftalık Hedef", style: TextStyle(color: stc, fontSize: 11)), Text("$weeklyWorkoutCount / $g Antrenman", style: TextStyle(color: tc, fontSize: 18, fontWeight: FontWeight.bold)), const SizedBox(height: 8), LinearProgressIndicator(value: p, color: const Color(0xFF3B82F6), backgroundColor: Colors.black12, minHeight: 6)]));
  Widget _compBox(String t, num c, num p, String u, Color cc, Color tc, bool id) {
    final d = (c - p).toDouble();
    return Container(margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), decoration: BoxDecoration(color: cc, borderRadius: BorderRadius.circular(12), border: Border.all(color: id ? Colors.white10 : Colors.black12)), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(t, style: TextStyle(color: id ? Colors.white38 : Colors.black45, fontSize: 10)), Text("${c.toInt()} $u", style: TextStyle(color: tc, fontWeight: FontWeight.bold, fontSize: 14))]), Icon(d >= 0 ? Icons.arrow_upward : Icons.arrow_downward, color: d >= 0 ? Colors.greenAccent : Colors.redAccent, size: 14)]));
  }

  @override 
  void dispose() { super.dispose(); }
}