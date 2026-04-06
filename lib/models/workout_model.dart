import 'package:isar/isar.dart';

part 'workout_model.g.dart';

@collection
class Workout {
  Id id = Isar.autoIncrement;

  late String name;
  late DateTime date;

  bool isFavorite = false;

  List<Exercise> exercises = [];
}

@embedded
class Exercise {
  late String name;

  /// analytics için
  String region = "Other";

  List<ExerciseSet> sets = [];
}

@embedded
class ExerciseSet {
  late double kg;
  late int reps;

  /// checkbox state
  bool isCompleted = false;

  /// RPE (0–10)
  double? rpe;

  /// failure set mi
  bool failure = false;
}

// 🔥 YENİ: KALORİ TAKİP MODELİ
@collection
class CalorieEntry {
  Id id = Isar.autoIncrement;

  @Index()
  late DateTime date; // Giriş yapılan tarih ve saat

  late double amount; // Alınan kalori miktarı (kcal)

  String? note; // "Öğle yemeği", "Protein bar" gibi notlar
  
  double? protein;
  double? carbs;
  double? fat;

  // Isar için boş constructor şart
  CalorieEntry();

  CalorieEntry.create({
    required this.date,
    required this.amount,
    this.note,
  });
}