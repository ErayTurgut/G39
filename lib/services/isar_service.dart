import 'dart:async';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../models/workout_model.dart';
import '../models/user_model.dart';

class IsarService {
  static Isar? _isar;

  /// 🔒 SAFE ACCESSOR
  static Isar get isar {
    if (_isar == null || !_isar!.isOpen) {
      throw Exception("Isar başlatılmadı. Önce IsarService.init() çağırın.");
    }
    return _isar!;
  }

  /// 🔒 INIT
  static Future<void> init() async {
    try {
      if (_isar != null && _isar!.isOpen) return;

      final dir = await getApplicationDocumentsDirectory();

      _isar = await Isar.open(
        [
          WorkoutSchema, 
          CalorieEntrySchema, 
          UserProfileSchema
        ], 
        directory: dir.path,
      );
    } catch (e, stack) {
      print("ISAR INIT ERROR: $e");
      print(stack);
      rethrow;
    }
  }

  // ================= AUTH (GİRİŞ) METOTLARI =================

  static bool hasUser() {
    return isar.userProfiles.countSync() > 0;
  }

  static Future<void> saveUser(String name, String email) async {
    final user = UserProfile()
      ..name = name
      ..email = email;

    await isar.writeTxn(() async {
      await isar.userProfiles.put(user);
    });
  }

  static Future<void> logout() async {
    try {
      await isar.writeTxn(() async {
        await isar.userProfiles.clear();
      });
    } catch (e) {
      print("LOGOUT ERROR: $e");
    }
  }

  // ================= WORKOUT (ANTRENMAN) METOTLARI =================

  static Future<void> saveWorkout(Workout workout) async {
    try {
      await isar.writeTxn(() async {
        await isar.workouts.put(workout);
      });
    } catch (e) {
      print("SAVE WORKOUT ERROR: $e");
    }
  }

  static Future<List<Workout>> getWorkouts() async {
    try {
      return await isar.workouts
          .where()
          .anyId()
          .sortByDateDesc()
          .findAll();
    } catch (e) {
      print("GET WORKOUTS ERROR: $e");
      return [];
    }
  }

  static Future<List<Workout>> getWorkoutsAsc() async {
    try {
      return await isar.workouts
          .where()
          .anyId()
          .sortByDate()
          .findAll();
    } catch (e) {
      print("GET WORKOUTS ASC ERROR: $e");
      return [];
    }
  }

  static Future<List<Workout>> getFavoriteWorkouts() async {
    try {
      return await isar.workouts
          .filter()
          .isFavoriteEqualTo(true)
          .sortByDateDesc()
          .findAll();
    } catch (e) {
      print("GET FAVORITES ERROR: $e");
      return [];
    }
  }

  // ================= 🔥 KALORİ & MAKRO METOTLARI =================

  // 🔥 YENİ: Makroları da alacak şekilde güncellendi
  static Future<void> saveCalorie(double amount, String? note, {double? protein, double? carbs, double? fat}) async {
    try {
      final entry = CalorieEntry()
        ..amount = amount
        ..date = DateTime.now()
        ..note = note
        ..protein = protein
        ..carbs = carbs
        ..fat = fat;

      await isar.writeTxn(() async {
        await isar.calorieEntrys.put(entry);
      });
    } catch (e) {
      print("SAVE CALORIE ERROR: $e");
    }
  }

  static Future<double> getTodayTotalCalories() async {
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final entries = await isar.calorieEntrys
          .filter()
          .dateBetween(startOfDay, endOfDay)
          .findAll();

      return entries.fold<double>(0.0, (prev, element) => prev + element.amount);
    } catch (e) {
      print("GET TODAY CALORIES ERROR: $e");
      return 0.0;
    }
  }

  static Future<List<CalorieEntry>> getCaloriesByDate(DateTime date) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      return await isar.calorieEntrys
          .filter()
          .dateBetween(startOfDay, endOfDay)
          .sortByDateDesc()
          .findAll();
    } catch (e) {
      print("GET CALORIES BY DATE ERROR: $e");
      return [];
    }
  }

  // 🔥 YENİ: Çizgi Grafik için Günü Gününe Kalori ve Makro Çekme
  static Future<Map<String, double>> getDailyTotals(DateTime date) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final entries = await isar.calorieEntrys
          .filter()
          .dateBetween(startOfDay, endOfDay)
          .findAll();

      double cals = 0, p = 0, c = 0, f = 0;
      for (var e in entries) {
        cals += e.amount;
        p += e.protein ?? 0;
        c += e.carbs ?? 0;
        f += e.fat ?? 0;
      }
      return {'calories': cals, 'protein': p, 'carbs': c, 'fat': f};
    } catch (e) {
      return {'calories': 0, 'protein': 0, 'carbs': 0, 'fat': 0};
    }
  }

  // =====================================================

  static Future<void> close() async {
    try {
      if (_isar != null && _isar!.isOpen) {
        await _isar!.close();
      }
    } catch (e) {
      print("ISAR CLOSE ERROR: $e");
    }
  }
}