import 'dart:convert';
import 'package:isar/isar.dart';

part 'workout_model.g.dart';

// -------------------------------------------------------------------------
// WORKOUT MODEL (Ana Program)
// -------------------------------------------------------------------------
@collection
class Workout {
  Id id = Isar.autoIncrement;

  late String name;
  late DateTime date;
  
  bool isFavorite = false;

  // PT Paylaşım Ekstraları
  String? trainerName;   // Programı yazan PT'nin adı
  String? description;   // PT'den danışana not (örn: "Bu hafta düşük ağırlık yüksek tempo")
  String? category;      // "Hypertrophy", "Fat Loss" vb.

  List<Exercise> exercises = [];

  Workout();

  // --- JSON SERİALİZATION (Paylaşım İçin Şart) ---
  
  factory Workout.fromJson(Map<String, dynamic> json) {
    return Workout()
      ..name = json['name']
      ..date = json['date'] != null ? DateTime.parse(json['date']) : DateTime.now()
      ..isFavorite = json['isFavorite'] ?? false
      ..trainerName = json['trainerName']
      ..description = json['description']
      ..category = json['category']
      ..exercises = (json['exercises'] as List? ?? [])
          .map((e) => Exercise.fromJson(e))
          .toList();
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'date': date.toIso8601String(),
        'isFavorite': isFavorite,
        'trainerName': trainerName,
        'description': description,
        'category': category,
        'exercises': exercises.map((e) => e.toJson()).toList(),
      };
}

// -------------------------------------------------------------------------
// EXERCISE MODEL
// -------------------------------------------------------------------------
@embedded
class Exercise {
  late String name;
  String region = "Other"; // Analytics için
  String? note;            // Antrenörün egzersiz özelinde notu (örn: "Dirsekleri açma")
  
  List<ExerciseSet> sets = [];

  Exercise();

  factory Exercise.fromJson(Map<String, dynamic> json) {
    return Exercise()
      ..name = json['name']
      ..region = json['region'] ?? "Other"
      ..note = json['note']
      ..sets = (json['sets'] as List? ?? [])
          .map((e) => ExerciseSet.fromJson(e))
          .toList();
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'region': region,
        'note': note,
        'sets': sets.map((e) => e.toJson()).toList(),
      };
}

// -------------------------------------------------------------------------
// EXERCISE SET MODEL
// -------------------------------------------------------------------------
@embedded
class ExerciseSet {
  late double kg;
  late int reps;
  bool isCompleted = false;
  double? rpe;
  bool failure = false;

  ExerciseSet();

  factory ExerciseSet.fromJson(Map<String, dynamic> json) {
    return ExerciseSet()
      ..kg = (json['kg'] as num).toDouble()
      ..reps = json['reps'] as int
      ..isCompleted = json['isCompleted'] ?? false
      ..rpe = (json['rpe'] as num?)?.toDouble()
      ..failure = json['failure'] ?? false;
  }

  Map<String, dynamic> toJson() => {
        'kg': kg,
        'reps': reps,
        'isCompleted': isCompleted,
        'rpe': rpe,
        'failure': failure,
      };
}

// -------------------------------------------------------------------------
// CALORIE ENTRY MODEL
// -------------------------------------------------------------------------
@collection
class CalorieEntry {
  Id id = Isar.autoIncrement;

  @Index()
  late DateTime date;
  late double amount;
  String? note;
  double? protein;
  double? carbs;
  double? fat;

  CalorieEntry();

  CalorieEntry.create({
    required this.date,
    required this.amount,
    this.note,
    this.protein,
    this.carbs,
    this.fat,
  });

  // Kalori takibi genelde kişiseldir ama JSON desteği yedekleme için iyidir
  factory CalorieEntry.fromJson(Map<String, dynamic> json) {
    return CalorieEntry()
      ..date = DateTime.parse(json['date'])
      ..amount = (json['amount'] as num).toDouble()
      ..note = json['note']
      ..protein = (json['protein'] as num?)?.toDouble()
      ..carbs = (json['carbs'] as num?)?.toDouble()
      ..fat = (json['fat'] as num?)?.toDouble();
  }

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'amount': amount,
        'note': note,
        'protein': protein,
        'carbs': carbs,
        'fat': fat,
      };
}