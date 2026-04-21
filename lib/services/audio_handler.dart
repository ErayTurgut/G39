import 'package:audio_service/audio_service.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:io';

class MyAudioHandler extends BaseAudioHandler {
  final _player = AudioPlayer();
  final FlutterLocalNotificationsPlugin _localNotificationsPlugin = FlutterLocalNotificationsPlugin();

  MyAudioHandler() {
    _initHandler();
  }

  Future<void> _initHandler() async {
    // 1. AudioPlayer Konfigürasyonu (Ducking ve Mixing)
    await _player.setAudioContext(AudioContext(
      iOS: AudioContextIOS(
        category: AVAudioSessionCategory.playback,
        options: [
          AVAudioSessionOptions.mixWithOthers,
          AVAudioSessionOptions.duckOthers,
        ],
      ),
      android: AudioContextAndroid(
        contentType: AndroidContentType.music,
        usageType: AndroidUsageType.media,
        audioFocus: AndroidAudioFocus.none,
      ),
    ));

    // 2. Bildirim Ayarları (Android Kanalını Oluşturma)
    const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings initializationSettingsIOS = DarwinInitializationSettings();
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );
    await _localNotificationsPlugin.initialize(initializationSettings);

    // Android için özel bildirim kanalı (Native sesleri kullanabilmesi için)
    // Önemli: Kanal bir kez oluşturulduktan sonra sesi değişmez, silip tekrar kurmak gerekir.
    _createNotificationChannel('default'); 
  }

  // Dinamik bildirim kanalı oluşturucu
  Future<void> _createNotificationChannel(String soundName) async {
    final androidChannel = AndroidNotificationChannel(
      'workout_timer_channel',
      'G39 Antrenman Sayaçları',
      importance: Importance.max,
      playSound: true,
      sound: RawResourceAndroidNotificationSound(soundName == 'default' ? 'beep' : soundName),
    );

    await _localNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);
  }

  // 🔥 ARKA PLANDA BİLDİRİM VE SES TETİKLEME
  Future<void> triggerRestNotification(String soundType) async {
    // İsim temizleme: "AIR HORN" -> "air_horn"
    final String fileName = soundType.toLowerCase().replaceAll(' ', '_');

    final androidDetails = AndroidNotificationDetails(
      'workout_timer_channel',
      'Süre Doldu! 👊🏼',
      channelDescription: 'Antrenman devam ediyor',
      importance: Importance.max,
      priority: Priority.high,
      sound: RawResourceAndroidNotificationSound(fileName), // res/raw içindeki dosya
      playSound: true,
    );

    final iosDetails = DarwinNotificationDetails(
      presentSound: true,
      sound: '$fileName.mp3', // Xcode'a eklediğin dosya adı
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotificationsPlugin.show(
      1,
      'Süre Doldu! 👊🏼',
      'Hadi moruk, yeni sete başla!',
      notificationDetails,
    );
  }

  // 🔥 ÖN PLANDA ÖNİZLEME VEYA SES ÇALMA
  Future<void> playCustomSound(String soundType, {String? customPath}) async {
    await _player.stop();
    
    if (soundType == "custom" && customPath != null) {
      await _player.play(DeviceFileSource(customPath));
    } else {
      final String fileName = soundType.toLowerCase().replaceAll(' ', '_');
      await _player.play(AssetSource('sounds/$fileName.mp3'), mode: PlayerMode.lowLatency);
    }

    playbackState.add(playbackState.value.copyWith(
      playing: true,
      processingState: AudioProcessingState.ready,
    ));
  }

  @override
  Future<void> play() async {
    // Varsayılan bip sesi için (Geriye dönük uyumluluk)
    await playCustomSound('beep');
  }

  void startWorkoutSession() {
    playbackState.add(playbackState.value.copyWith(
      controls: [MediaControl.stop],
      playing: true,
      processingState: AudioProcessingState.ready,
    ));
  }

  @override
  Future<void> stop() async {
    await _player.stop();
    playbackState.add(playbackState.value.copyWith(
      playing: false,
      processingState: AudioProcessingState.idle,
    ));
    return super.stop();
  }
}