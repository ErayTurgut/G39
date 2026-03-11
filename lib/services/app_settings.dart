import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettings extends ChangeNotifier {

  static const _restKey = "restSeconds";
  static const _exerciseRestKey = "exerciseRestSeconds";
  static const _unitKey = "weightUnit";
  static const _themeKey = "darkMode";

  static const _soundEnabledKey = "restSoundEnabled";
  static const _soundTypeKey = "restSoundType";

  // NEW
  static const _weeklyGoalKey = "weeklyGoal";

  int _restSeconds = 60;
  int _exerciseRestSeconds = 120;
  String _weightUnit = "KG";
  bool _darkMode = false;

  // 🔊 SOUND SETTINGS
  bool _restSoundEnabled = true;
  String _restSoundType = "airHorn";

  // NEW
  int _weeklyGoal = 4;

  int get restSeconds => _restSeconds;
  int get exerciseRestSeconds => _exerciseRestSeconds;
  String get weightUnit => _weightUnit;
  bool get darkMode => _darkMode;

  bool get restSoundEnabled => _restSoundEnabled;
  String get restSoundType => _restSoundType;

  // NEW
  int get weeklyGoal => _weeklyGoal;

  AppSettings() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    _restSeconds = prefs.getInt(_restKey) ?? 60;
    _exerciseRestSeconds = prefs.getInt(_exerciseRestKey) ?? 120;
    _weightUnit = prefs.getString(_unitKey) ?? "KG";
    _darkMode = prefs.getBool(_themeKey) ?? false;

    _restSoundEnabled = prefs.getBool(_soundEnabledKey) ?? true;
    _restSoundType = prefs.getString(_soundTypeKey) ?? "airHorn";

    // NEW
    _weeklyGoal = prefs.getInt(_weeklyGoalKey) ?? 4;

    notifyListeners();
  }

  Future<void> setRest(int sec) async {
    _restSeconds = sec;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_restKey, sec);
    notifyListeners();
  }

  Future<void> setExerciseRest(int sec) async {
    _exerciseRestSeconds = sec;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_exerciseRestKey, sec);
    notifyListeners();
  }

  Future<void> setUnit(String unit) async {
    _weightUnit = unit;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_unitKey, unit);
    notifyListeners();
  }

  Future<void> setTheme(bool val) async {
    _darkMode = val;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themeKey, val);
    notifyListeners();
  }

  // 🔊 SOUND METHODS

  Future<void> setRestSoundEnabled(bool val) async {
    _restSoundEnabled = val;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_soundEnabledKey, val);
    notifyListeners();
  }

  Future<void> setRestSoundType(String type) async {
    _restSoundType = type;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_soundTypeKey, type);
    notifyListeners();
  }

  // NEW
  Future<void> setWeeklyGoal(int goal) async {
    _weeklyGoal = goal;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_weeklyGoalKey, goal);
    notifyListeners();
  }
}