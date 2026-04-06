import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:purchases_flutter/purchases_flutter.dart'; 

class AppSettings extends ChangeNotifier {
  // ANAHTARLAR (KEYS)
  static const _restKey = "restSeconds";
  static const _exerciseRestKey = "exerciseRestSeconds";
  static const _unitKey = "weightUnit";
  static const _themeKey = "darkMode";
  static const _soundEnabledKey = "restSoundEnabled";
  static const _soundTypeKey = "restSoundType";
  static const _weeklyGoalKey = "weeklyGoal";
  static const _customSoundPathKey = "customSoundPath";
  static const _calorieGoalKey = "calorieGoal";
  static const _proteinGoalKey = "proteinGoal";
  static const _carbGoalKey = "carbGoal";
  static const _fatKey = "fatGoal";

  // DEĞİŞKENLER & VARSAYILANLAR
  int _restSeconds = 60;
  int _exerciseRestSeconds = 120;
  String _weightUnit = "KG";
  bool _darkMode = true; // 🔥 FABRİKA ÇIKIŞI KARANLIK MOD

  bool _restSoundEnabled = true;
  String _restSoundType = "airHorn";
  String _customSoundPath = "";
  List<String> _availableSounds = []; 

  // 💰 G39 PRO KİLİTLERİ (MONETIZATION)
  bool _isGraphUnlocked = false; 
  bool _isCustomSoundUnlocked = false; 

  int _weeklyGoal = 4;
  double _calorieGoal = 2500.0;
  int _proteinGoal = 150;
  int _carbGoal = 250;
  int _fatGoal = 70;

  // GETTER'LAR
  int get restSeconds => _restSeconds;
  int get exerciseRestSeconds => _exerciseRestSeconds;
  String get weightUnit => _weightUnit;
  bool get darkMode => _darkMode;
  bool get restSoundEnabled => _restSoundEnabled;
  String get restSoundType => _restSoundType;
  int get weeklyGoal => _weeklyGoal;
  double get calorieGoal => _calorieGoal;
  int get proteinGoal => _proteinGoal;
  int get carbGoal => _carbGoal;
  int get fatGoal => _fatGoal;
  String get customSoundPath => _customSoundPath;
  List<String> get availableSounds => _availableSounds;
  bool get isGraphUnlocked => _isGraphUnlocked;
  bool get isCustomSoundUnlocked => _isCustomSoundUnlocked;

  AppSettings() {
    _loadSettings();
    _initRevenueCat(); 
  }

  // 🔥 SES KÜTÜPHANESİ KİLİT MANTIĞI
  bool isSoundLocked(String soundName) {
    String name = soundName.toLowerCase();
    // Ücretsiz sesler
    if (name == "airhorn" || name == "horserace") return false;
    // Diğerleri için Pro veya Beat Master gerekir
    return !_isCustomSoundUnlocked;
  }

  // 🔥 G39 REVENUECAT BAŞLATMA
  Future<void> _initRevenueCat() async {
    try {
      // Log seviyesini sadece debug modda görmek istersen kalsın
      await Purchases.setLogLevel(LogLevel.debug);
      
      PurchasesConfiguration configuration = PurchasesConfiguration("goog_HnrwUHbcPDHQFuFFWOEECCQGlQa");
      await Purchases.configure(configuration);

      CustomerInfo customerInfo = await Purchases.getCustomerInfo();
      _updateEntitlements(customerInfo);

      // Satın alım durumundaki anlık değişiklikleri dinle
      Purchases.addCustomerInfoUpdateListener((info) {
        _updateEntitlements(info);
      });
    } catch (e) {
      debugPrint("G39 RevenueCat Hatası: $e");
    }
  }

  void _updateEntitlements(CustomerInfo info) {
    // 1. G39 Pro Yetkisi (Grafikler ve Premium Özellikler)
    bool isPro = info.entitlements.all["G39 Pro"]?.isActive ?? false;
    
    // 2. Beat Master Yetkisi (Sadece ses kütüphanesi - Ömür Boyu)
    bool hasBeatMaster = info.entitlements.all["Beat Master"]?.isActive ?? false;

    _isGraphUnlocked = isPro;
    _isCustomSoundUnlocked = isPro || hasBeatMaster;
    
    notifyListeners();
  }

  // --- AYARLARIN YÜKLENMESİ ---
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _restSeconds = prefs.getInt(_restKey) ?? 60;
    _exerciseRestSeconds = prefs.getInt(_exerciseRestKey) ?? 120;
    _weightUnit = prefs.getString(_unitKey) ?? "KG";
    
    // 🔥 KRİTİK: Hafızada veri yoksa 'true' döndürür (Default Dark Mode)
    _darkMode = prefs.getBool(_themeKey) ?? true; 
    
    _restSoundEnabled = prefs.getBool(_soundEnabledKey) ?? true;
    _restSoundType = prefs.getString(_soundTypeKey) ?? "airHorn";
    _weeklyGoal = prefs.getInt(_weeklyGoalKey) ?? 4;
    _calorieGoal = prefs.getDouble(_calorieGoalKey) ?? 2500.0;
    _customSoundPath = prefs.getString(_customSoundPathKey) ?? "";
    _proteinGoal = prefs.getInt(_proteinGoalKey) ?? 150;
    _carbGoal = prefs.getInt(_carbGoalKey) ?? 250;
    _fatGoal = prefs.getInt(_fatKey) ?? 70;

    await loadAvailableSounds();
    notifyListeners();
  }

  // 🛍️ SATIN ALMA METOTLARI
  Future<void> subscribeToPro(String productId) async {
    try {
      PurchaseResult purchaseResult = await Purchases.purchaseProduct(productId);
      _updateEntitlements(purchaseResult.customerInfo);
    } catch (e) {
      debugPrint("Abonelik hatası: $e");
    }
  }

  Future<void> buyBeatMaster() async {
    try {
      PurchaseResult purchaseResult = await Purchases.purchaseProduct("g39_beep");
      _updateEntitlements(purchaseResult.customerInfo);
    } catch (e) {
      debugPrint("Beat Master alım hatası: $e");
    }
  }

  Future<void> restorePurchases() async {
    try {
      CustomerInfo restoredInfo = await Purchases.restorePurchases();
      _updateEntitlements(restoredInfo);
    } catch (e) {
      debugPrint("Geri yükleme hatası: $e");
    }
  }

  // 📂 SES DOSYALARI YÖNETİMİ
  Future<void> loadAvailableSounds() async {
    Set<String> soundNames = {};
    try {
      final AssetManifest manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      final List<String> assetPaths = manifest.listAssets()
          .where((String path) => path.toLowerCase().startsWith('assets/sounds/') && 
                                 (path.toLowerCase().endsWith('.mp3') || path.toLowerCase().endsWith('.wav')))
          .toList();
      
      for (var path in assetPaths) {
        soundNames.add(path.split('/').last.replaceAll(RegExp(r'\.(mp3|wav|MP3|WAV)$'), ''));
      }

      final directory = await getApplicationDocumentsDirectory();
      final String customDirPath = p.join(directory.path, 'custom_sounds');
      final customDir = Directory(customDirPath);

      if (await customDir.exists()) {
        final List<FileSystemEntity> files = customDir.listSync();
        for (var file in files) {
          if (file is File) {
            String fileName = p.basename(file.path);
            if (fileName.toLowerCase().endsWith('.mp3') || fileName.toLowerCase().endsWith('.wav') || fileName.toLowerCase().endsWith('.m4a')) {
              soundNames.add(fileName.replaceAll(RegExp(r'\.(mp3|wav|m4a|MP3|WAV|M4A)$'), ''));
            }
          }
        }
      }
      _availableSounds = soundNames.toList()..sort();
    } catch (e) {
      debugPrint("Sound Bank hatası: $e");
    }
    notifyListeners();
  }

  Future<bool> setCustomSoundPath(String originalPath) async {
    if (!_isCustomSoundUnlocked) return false; 

    try {
      final directory = await getApplicationDocumentsDirectory();
      final String customDirPath = p.join(directory.path, 'custom_sounds');
      await Directory(customDirPath).create(recursive: true);

      final String fileName = p.basename(originalPath);
      final String newPath = p.join(customDirPath, fileName);

      File originalFile = File(originalPath);
      if (await originalFile.exists()) {
        await originalFile.copy(newPath);
        _customSoundPath = newPath;
        _restSoundType = "custom";
        await loadAvailableSounds();
        
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_customSoundPathKey, newPath);
        await prefs.setString(_soundTypeKey, "custom");
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint("Ses kopyalama hatası: $e");
    }
    return false;
  }

  // --- SETTER'LAR (STORAGE KAYITLI) ---
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

  Future<void> setWeeklyGoal(int goal) async {
    _weeklyGoal = goal;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_weeklyGoalKey, goal);
    notifyListeners();
  }

  Future<void> setCalorieGoal(double goal) async {
    _calorieGoal = goal;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_calorieGoalKey, goal);
    notifyListeners();
  }

  Future<void> setProteinGoal(int goal) async {
    _proteinGoal = goal;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_proteinGoalKey, goal);
    notifyListeners();
  }

  Future<void> setCarbGoal(int goal) async {
    _carbGoal = goal;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_carbGoalKey, goal);
    notifyListeners();
  }

  Future<void> setFatGoal(int goal) async {
    _fatGoal = goal;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_fatKey, goal);
    notifyListeners();
  }
}