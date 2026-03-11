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