import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:app_links/app_links.dart';
import '../models/workout_model.dart';
import 'isar_service.dart';

// -------------------------------------------------------------------------
// WORKOUT SHARING (Encoding & Sharing Logic)
// -------------------------------------------------------------------------
class WorkoutSharing {
  /// Antrenman verisini sıkıştırıp g39:// şemasına uygun hale getirir
  static String encodeWorkout(Workout workout) {
    try {
      final jsonStr = jsonEncode(workout.toJson());
      final bytes = utf8.encode(jsonStr);
      final compressed = gzip.encode(bytes);
      return base64Url.encode(compressed);
    } catch (e) {
      debugPrint("Encoding hatası: $e");
      return "";
    }
  }

  /// Sıkıştırılmış kodu tekrar Workout nesnesine çevirir
  static Workout? decodeWorkout(String code) {
    try {
      final compressed = base64Url.decode(code);
      final bytes = gzip.decode(compressed);
      final jsonStr = utf8.decode(bytes);
      final Map<String, dynamic> jsonData = jsonDecode(jsonStr);
      return Workout.fromJson(jsonData);
    } catch (e) {
      debugPrint("Decoding hatası: $e");
      return null;
    }
  }

  /// Paylaşım menüsünü açar (Custom Scheme Linki ile)
  static Future<void> shareMyProgram(Workout workout) async {
    final String shareCode = encodeWorkout(workout);
    if (shareCode.isEmpty) return;

    // Domain almadığımız için "g39://" şemasını kullanıyoruz
    final String shareUrl = "g39://share?data=$shareCode";

    final String message = 
        "${workout.trainerName ?? 'Antrenörün'} sana bir program gönderdi: ${workout.name}\n\n"
        "Antrenmanı G39 uygulamasına yüklemek için tıkla:\n"
        "$shareUrl";

    await Share.share(
      message,
      subject: "${workout.name} Program Paylaşımı",
    );
  }
}

// -------------------------------------------------------------------------
// LINK HANDLER (Deep Link Yakalama & UI Bildirimi)
// -------------------------------------------------------------------------
class LinkHandler {
  static final _appLinks = AppLinks();

  /// Uygulama başlangıcında link dinlemeyi başlatır
  static void init(BuildContext context) {
    // 1. Uygulama kapalıyken linkle açılırsa
    // 🔥 DÜZELTİLDİ: getInitialAppLink() ismi getInitialLink() olarak güncellendi.
    _appLinks.getInitialLink().then((uri) {
      if (uri != null) _handleLink(context, uri);
    });

    // 2. Uygulama arkadayken linke tıklanırsa
    _appLinks.uriLinkStream.listen((uri) {
      _handleLink(context, uri);
    });
  }

  static void _handleLink(BuildContext context, Uri uri) {
    // g39://share?data=... yapısındaki data parametresini oku
    final code = uri.queryParameters['data'];
    if (code == null) return;

    final workout = WorkoutSharing.decodeWorkout(code);
    if (workout != null) {
      _showAcceptDialog(context, workout);
    }
  }

  /// Kullanıcıya "Kabul Ediyor musun?" modalını gösterir
  static void _showAcceptDialog(BuildContext context, Workout workout) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Color(0xFF101826), // Dark tema kart rengin
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(10))),
            const SizedBox(height: 20),
            const Icon(Icons.fitness_center_rounded, color: Color(0xFF3B82F6), size: 40),
            const SizedBox(height: 16),
            const Text(
              "Yeni Program Geldi!",
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              "${workout.trainerName ?? 'Antrenörün'} sana '${workout.name}' programını gönderdi. Kütüphanene eklemek ister misin?",
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("VAZGEÇ", style: TextStyle(color: Colors.white38)),
                  ),
                ),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3B82F6),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () async {
                      // Isar'a kaydet
                      await IsarService.saveWorkout(workout);
                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Program başarıyla eklendi!")),
                        );
                      }
                    },
                    child: const Text("KAYDET", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}