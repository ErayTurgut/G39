import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart'; 
import 'package:audioplayers/audioplayers.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:package_info_plus/package_info_plus.dart'; // 🔥 Otomatik versiyon için
import 'package:firebase_auth/firebase_auth.dart'; // 🔥 Çıkış için

import '../services/app_settings.dart';
import 'paywall_screen.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String? _dynamicBeepPrice; 
  String _appVersion = "1.0.0"; // Varsayılan

  @override
  void initState() {
    super.initState();
    _fetchLivePriceFromStore();
    _initPackageInfo(); // 🔥 Versiyonu çek
  }

  // 🔥 Pubspec'ten gerçek versiyonu okur
  Future<void> _initPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      _appVersion = "${info.version}+${info.buildNumber}";
    });
  }

  Future<void> _fetchLivePriceFromStore() async {
    try {
      Offerings offerings = await Purchases.getOfferings();
      if (offerings.current != null) {
        for (var p in offerings.current!.availablePackages) {
          if (p.storeProduct.identifier == "g39_beep") {
            setState(() {
              _dynamicBeepPrice = p.storeProduct.priceString;
            });
            break;
          }
        }
      }
    } catch (e) {
      debugPrint("❌ Fiyat senkronizasyon hatası: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettings>();
    final bool isDark = settings.darkMode;

    final Color bgColor = isDark ? const Color(0xFF050816) : const Color(0xFFF8FAFC);
    final Color appBarColor = isDark ? const Color(0xFF111018) : Colors.white;
    final Color cardColor = isDark ? const Color(0xFF101826) : Colors.white;
    final Color textColor = isDark ? Colors.white : Colors.black87;
    final Color subTextColor = isDark ? Colors.white38 : Colors.black54;
    final Color dividerColor = isDark ? Colors.white10 : Colors.black12;

    final String currentPrice = _dynamicBeepPrice ?? "...";

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: appBarColor,
        elevation: isDark ? 0 : 1,
        title: Text("AYARLAR", style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 14)),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        children: [
          _sectionTitle("ANTRENMAN AYARLARI"),
          _buildSettingsCard(
            color: cardColor,
            borderColor: dividerColor,
            children: [
              _settingsTile(isDark: isDark, icon: Icons.timer_outlined, title: "Set Arası Dinlenme", subtitle: "${settings.restSeconds} Saniye", textColor: textColor, subTextColor: subTextColor, onTap: () async {
                final val = await _numberPicker(context, "Set Arası (sn)", settings.restSeconds, 10, 300, isDark, "sn");
                if (val != null) settings.setRest(val);
              }),
              _settingsTile(isDark: isDark, icon: Icons.double_arrow_rounded, title: "Hareket Arası Dinlenme", subtitle: "${settings.exerciseRestSeconds} Saniye", textColor: textColor, subTextColor: subTextColor, onTap: () async {
                final val = await _numberPicker(context, "Hareket Arası (sn)", settings.exerciseRestSeconds, 10, 600, isDark, "sn");
                if (val != null) settings.setExerciseRest(val);
              }),
              _settingsTile(isDark: isDark, icon: Icons.monitor_weight_outlined, title: "Ağırlık Birimi", subtitle: settings.weightUnit, textColor: textColor, subTextColor: subTextColor, onTap: () => _showUnitPicker(context, settings, isDark)),
            ],
          ),

          const SizedBox(height: 24),
          _sectionTitle("HEDEFLER & SES"),
          _buildSettingsCard(
            color: cardColor,
            borderColor: dividerColor,
            children: [
              _settingsTile(isDark: isDark, icon: Icons.flag_outlined, title: "Haftalık Antrenman Hedefi", subtitle: "${settings.weeklyGoal} Gün", textColor: textColor, subTextColor: subTextColor, onTap: () async {
                final val = await _numberPicker(context, "Haftalık Hedef", settings.weeklyGoal, 1, 7, isDark, "gün");
                if (val != null) settings.setWeeklyGoal(val);
              }),
              _settingsTile(isDark: isDark, icon: Icons.local_fire_department_outlined, title: "Günlük Kalori Hedefi", subtitle: "${settings.calorieGoal.toInt()} kcal", textColor: textColor, subTextColor: subTextColor, onTap: () async {
                final val = await _numberPicker(context, "Kalori Hedefi", settings.calorieGoal.toInt(), 500, 10000, isDark, "kcal");
                if (val != null) settings.setCalorieGoal(val.toDouble());
              }),
              _settingsTile(isDark: isDark, icon: Icons.egg_alt_outlined, title: "Günlük Protein Hedefi", subtitle: "${settings.proteinGoal} g", textColor: textColor, subTextColor: subTextColor, onTap: () async {
                final val = await _numberPicker(context, "Protein Hedefi", settings.proteinGoal, 10, 500, isDark, "g");
                if (val != null) settings.setProteinGoal(val);
              }),
              _settingsTile(isDark: isDark, icon: Icons.breakfast_dining_outlined, title: "Günlük Karbonhidrat Hedefi", subtitle: "${settings.carbGoal} g", textColor: textColor, subTextColor: subTextColor, onTap: () async {
                final val = await _numberPicker(context, "Karbonhidrat Hedefi", settings.carbGoal, 10, 1000, isDark, "g");
                if (val != null) settings.setCarbGoal(val);
              }),
              _settingsTile(isDark: isDark, icon: Icons.water_drop_outlined, title: "Günlük Yağ Hedefi", subtitle: "${settings.fatGoal} g", textColor: textColor, subTextColor: subTextColor, onTap: () async {
                final val = await _numberPicker(context, "Yağ Hedefi", settings.fatGoal, 10, 500, isDark, "g");
                if (val != null) settings.setFatGoal(val);
              }),
              _switchTile(isDark: isDark, icon: Icons.volume_up_rounded, title: "Dinlenme Sesi", value: settings.restSoundEnabled, textColor: textColor, onChanged: (v) => settings.setRestSoundEnabled(v)),
              _settingsTile(isDark: isDark, icon: Icons.music_note_rounded, title: "Ses Tipi", subtitle: settings.restSoundType.toUpperCase(), textColor: textColor, subTextColor: subTextColor, onTap: () => _showSoundPicker(context, settings, isDark, currentPrice)),
            ],
          ),

          const SizedBox(height: 24),
          _sectionTitle("GÖRÜNÜM & HESAP"),
          _buildSettingsCard(
            color: cardColor,
            borderColor: dividerColor,
            children: [
              _switchTile(isDark: isDark, icon: Icons.dark_mode_outlined, title: "Koyu Tema", value: settings.darkMode, textColor: textColor, onChanged: (v) => settings.setTheme(v)),
              const Divider(color: Colors.white10, height: 1),
              // 🔥 RESTORE BUTONU
              ListTile(
                visualDensity: VisualDensity.compact,
                leading: const Icon(Icons.restore, color: Color(0xFF3B82F6), size: 20),
                title: Text("Satın Alımları Geri Yükle", style: TextStyle(color: textColor, fontSize: 13)),
                onTap: () async {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Alımlar kontrol ediliyor...")));
                  await settings.restorePurchases();
                },
              ),
              const Divider(color: Colors.white10, height: 1),
              // 🔥 ÇIKIŞ YAP BUTONU (Eksikti, Eklendi!)
              ListTile(
                visualDensity: VisualDensity.compact,
                leading: const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 20),
                title: const Text("Çıkış Yap", style: TextStyle(color: Colors.redAccent, fontSize: 13, fontWeight: FontWeight.bold)),
                onTap: () async {
                   try {
                     await Purchases.logOut(); // RevenueCat çıkış
                     await FirebaseAuth.instance.signOut(); // Firebase çıkış
                     if (context.mounted) Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
                   } catch (e) {
                     debugPrint("Çıkış hatası: $e");
                   }
                },
              ),
            ],
          ),

          const SizedBox(height: 40),
          Center(
            child: Text("G39 Pro v$_appVersion ✅", 
              style: TextStyle(color: subTextColor, fontSize: 10)),
          ),
        ],
      ),
    );
  }

  // --- UI Helper Fonksiyonların (Aynı Kalıyor) ---
  void _showSoundPicker(BuildContext context, AppSettings settings, bool isDark, String livePrice) {
    final AudioPlayer previewPlayer = AudioPlayer();
    List<String> sortedSounds = List.from(settings.availableSounds);
    sortedSounds.sort((a, b) {
      bool aLocked = settings.isSoundLocked(a);
      bool bLocked = settings.isSoundLocked(b);
      if (!aLocked && bLocked) return -1;
      if (aLocked && !bLocked) return 1;
      return a.compareTo(b);
    });
    showModalBottomSheet(context: context, backgroundColor: isDark ? const Color(0xFF111018) : Colors.white, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))), isScrollControlled: true, builder: (context) => Container(padding: const EdgeInsets.fromLTRB(20, 12, 20, 32), constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7), child: Column(mainAxisSize: MainAxisSize.min, children: [Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 20), decoration: BoxDecoration(color: isDark ? Colors.white10 : Colors.black12, borderRadius: BorderRadius.circular(10))), Text("SES KÜTÜPHANESİ", style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 15, fontWeight: FontWeight.bold)), const SizedBox(height: 12), Flexible(child: ListView.builder(shrinkWrap: true, itemCount: sortedSounds.length, itemBuilder: (context, index) { final soundName = sortedSounds[index]; final bool isLocked = settings.isSoundLocked(soundName); return _pickerOptionWithPreview(context: context, title: soundName.toUpperCase(), isSelected: settings.restSoundType == soundName, isDark: isDark, isLocked: isLocked, price: livePrice, onPlayPreview: () async { await previewPlayer.stop(); await previewPlayer.play(AssetSource('sounds/$soundName.mp3')); }, onSelect: () { if (isLocked) { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (context) => const PaywallScreen())); } else { settings.setRestSoundType(soundName); Navigator.pop(context); } }); })), const Divider(color: Colors.white10, height: 24), _pickerOptionWithPreview(context: context, title: "🎧 CİHAZDAN SEÇ", isSelected: settings.restSoundType == "custom", isDark: isDark, isLocked: !settings.isCustomSoundUnlocked, price: livePrice, onPlayPreview: null, onSelect: () async { if (settings.isCustomSoundUnlocked) { Navigator.pop(context); FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.audio); if (result != null && result.files.single.path != null) { settings.setCustomSoundPath(result.files.single.path!); } } else { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (context) => const PaywallScreen())); } }) ]))).then((_) => previewPlayer.dispose());
  }
  Widget _pickerOptionWithPreview({required BuildContext context, required String title, required bool isSelected, required bool isDark, required bool isLocked, required String price, required VoidCallback? onPlayPreview, required VoidCallback onSelect}) => ListTile(visualDensity: VisualDensity.compact, leading: onPlayPreview != null ? IconButton(icon: const Icon(Icons.play_circle_fill_rounded, color: Color(0xFF3B82F6), size: 28), onPressed: onPlayPreview) : const Icon(Icons.audiotrack_rounded, color: Colors.white24), title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: TextStyle(fontSize: 13, color: isSelected ? const Color(0xFF3B82F6) : (isDark ? Colors.white : Colors.black87), fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)), if (isLocked) Text(price, style: const TextStyle(color: Colors.amber, fontSize: 10, fontWeight: FontWeight.bold))]), trailing: isLocked ? const Icon(Icons.lock_rounded, color: Colors.amber, size: 16) : (isSelected ? const Icon(Icons.check_circle_rounded, color: Color(0xFF3B82F6), size: 18) : null), onTap: onSelect);
  Widget _sectionTitle(String title) => Padding(padding: const EdgeInsets.only(left: 8, bottom: 8), child: Text(title, style: const TextStyle(color: Color(0xFF3B82F6), fontWeight: FontWeight.bold, fontSize: 10)));
  Widget _buildSettingsCard({required List<Widget> children, required Color color, required Color borderColor}) => Container(decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(16), border: Border.all(color: borderColor)), child: Column(children: children));
  Widget _settingsTile({required bool isDark, required IconData icon, required String title, required String subtitle, required Color textColor, required Color subTextColor, required VoidCallback onTap}) => ListTile(visualDensity: VisualDensity.compact, leading: Icon(icon, color: const Color(0xFF3B82F6), size: 20), title: Text(title, style: TextStyle(color: textColor, fontSize: 13)), subtitle: Text(subtitle, style: TextStyle(color: subTextColor, fontSize: 11)), trailing: const Icon(Icons.chevron_right_rounded, size: 20), onTap: onTap);
  Widget _switchTile({required bool isDark, required IconData icon, required String title, required bool value, required Color textColor, required Function(bool) onChanged}) => SwitchListTile(secondary: Icon(icon, color: const Color(0xFF3B82F6), size: 20), title: Text(title, style: TextStyle(color: textColor, fontSize: 13)), value: value, activeColor: const Color(0xFF3B82F6), onChanged: onChanged);
  void _showUnitPicker(BuildContext context, AppSettings settings, bool isDark) { showDialog(context: context, builder: (context) => AlertDialog(backgroundColor: isDark ? const Color(0xFF111018) : Colors.white, title: Text("Ağırlık Birimi Seç", style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 16)), content: Column(mainAxisSize: MainAxisSize.min, children: [ ListTile(title: Text("KG", style: TextStyle(color: isDark ? Colors.white : Colors.black)), trailing: settings.weightUnit == "KG" ? const Icon(Icons.check_circle, color: Color(0xFF3B82F6)) : null, onTap: () { settings.setUnit("KG"); Navigator.pop(context); }), ListTile(title: Text("LBS", style: TextStyle(color: isDark ? Colors.white : Colors.black)), trailing: settings.weightUnit == "LBS" ? const Icon(Icons.check_circle, color: Color(0xFF3B82F6)) : null, onTap: () { settings.setUnit("LBS"); Navigator.pop(context); }) ]))); }
  Future<int?> _numberPicker(BuildContext context, String title, int initial, int min, int max, bool isDark, String suffix) async { TextEditingController controller = TextEditingController(text: initial.toString()); return showDialog<int>(context: context, builder: (context) => AlertDialog(backgroundColor: isDark ? const Color(0xFF111018) : Colors.white, title: Text(title, style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 16)), content: TextField(controller: controller, keyboardType: TextInputType.number, style: TextStyle(color: isDark ? Colors.white : Colors.black), decoration: InputDecoration(suffixText: suffix, suffixStyle: const TextStyle(color: Colors.grey), enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF3B82F6))), focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF3B82F6), width: 2)))), actions: [ TextButton(onPressed: () => Navigator.pop(context), child: const Text("İPTAL", style: TextStyle(color: Colors.grey))), TextButton(onPressed: () { int? val = int.tryParse(controller.text); if (val != null && val >= min && val <= max) { Navigator.pop(context, val); } else { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lütfen $min ile $max arası bir değer girin."))); } }, child: const Text("KAYDET", style: TextStyle(color: Color(0xFF3B82F6), fontWeight: FontWeight.bold))) ])); }
}