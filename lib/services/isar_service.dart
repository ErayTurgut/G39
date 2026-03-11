import 'dart:async';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../models/workout_model.dart';

class IsarService {
  static Isar? _isar;

  /// 🔒 SAFE ACCESSOR
  static Isar get isar {
    if (_isar == null || !_isar!.isOpen) {
      throw Exception("Isar is not initialized. Call IsarService.init() first.");
    }
    return _isar!;
  }

  /// 🔒 INIT (double-open korumalı)
  static Future<void> init() async {
    try {
      if (_isar != null && _isar!.isOpen) {
        return;
      }

      final dir = await getApplicationDocumentsDirectory();

      _isar = await Isar.open(
        [WorkoutSchema],
        directory: dir.path,
      );
    } catch (e, stack) {
      print("ISAR INIT ERROR: $e");
      print(stack);
      rethrow;
    }
  }

  /// 🔒 SAFE WRITE
  static Future<void> saveWorkout(Workout workout) async {
    try {
      await isar.writeTxn(() async {
        await isar.workouts.put(workout);
      });
    } catch (e, stack) {
      print("SAVE WORKOUT ERROR: $e");
      print(stack);
    }
  }

  /// 🔒 History (DESC)
  static Future<List<Workout>> getWorkouts() async {
    try {
      return await isar.workouts
          .where()
          .anyId()
          .sortByDateDesc()
          .findAll();
    } catch (e, stack) {
      print("GET WORKOUTS DESC ERROR: $e");
      print(stack);
      return [];
    }
  }

  /// 🔒 Progress (ASC)
  static Future<List<Workout>> getWorkoutsAsc() async {
    try {
      return await isar.workouts
          .where()
          .anyId()
          .sortByDate()
          .findAll();
    } catch (e, stack) {
      print("GET WORKOUTS ASC ERROR: $e");
      print(stack);
      return [];
    }
  }

  /// 🔒 Favorites
  static Future<List<Workout>> getFavoriteWorkouts() async {
    try {
      return await isar.workouts
          .filter()
          .isFavoriteEqualTo(true)
          .sortByDateDesc()
          .findAll();
    } catch (e, stack) {
      print("GET FAVORITES ERROR: $e");
      print(stack);
      return [];
    }
  }

  /// 🔒 OPTIONAL: Graceful close (future backup için gerekli olacak)
  static Future<void> close() async {
    try {
      if (_isar != null && _isar!.isOpen) {
        await _isar!.close();
      }
    } catch (e, stack) {
      print("ISAR CLOSE ERROR: $e");
      print(stack);
    }
  }
}