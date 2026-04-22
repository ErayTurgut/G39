import 'package:audio_service/audio_service.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:io';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class MyAudioHandler extends BaseAudioHandler {
  final _player = AudioPlayer();
  final FlutterLocalNotificationsPlugin _localNotificationsPlugin = FlutterLocalNotificationsPlugin();

  MyAudioHandler() {
    _initHandler();
  }

  Future<void> _initHandler() async {
    // 1. Zaman dilimlerini başlat (Arka plan bildirimi için şart)
    tz.initializeTimeZones();

    // 2. AudioPlayer Konfigürasyonu (Müziği bastırma ayarları)
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

    // 3. Bildirim Ayarları
    const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings initializationSettingsIOS = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      requestCriticalPermission: true,
    );
    
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );
    
    await _localNotificationsPlugin.initialize(initializationSettings);

    // Android kanalı oluştur (Sesi önceden sisteme kaydeder)
    _createNotificationChannel('default'); 
  }

  // 🔥 XCODE'UN İSTEDİĞİ O METOD (BURADA!)
  void startWorkoutSession() {
    playbackState.add(playbackState.value.copyWith(
      controls: [MediaControl.stop],
      playing: true,
      processingState: AudioProcessingState.ready,
    ));
  }

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

  // 🔥 ARKA PLANDA SESİ TETİKLEYEN ASIL MEVZU
  Future<void> scheduleRestNotification(int seconds, String soundType) async {
    final String fileName = soundType.toLowerCase().replaceAll(' ', '_');

    // Bekleyen bildirimi temizle
    await _localNotificationsPlugin.cancel(1);

    await _localNotificationsPlugin.zonedSchedule(
      1,
      'Süre Doldu! 👊🏼',
      'Hadi moruk, yeni sete başla!',
      tz.TZDateTime.now(tz.local).add(Duration(seconds: seconds)),
      NotificationDetails(
        android: AndroidNotificationDetails(
          'workout_timer_channel',
          'G39 Dinlenme',
          importance: Importance.max,
          priority: Priority.high,
          sound: RawResourceAndroidNotificationSound(fileName),
          playSound: true,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentSound: true,
          sound: '$fileName.mp3', 
          interruptionLevel: InterruptionLevel.critical,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> cancelRestNotification() async {
    await _localNotificationsPlugin.cancel(1);
  }

  Future<void> playCustomSound(String soundType, {String? customPath}) async {
    await _player.stop();
    if (soundType == "custom" && customPath != null) {
      await _player.play(DeviceFileSource(customPath));
    } else {
      final String fileName = soundType.toLowerCase().replaceAll(' ', '_');
      await _player.play(AssetSource('sounds/$fileName.mp3'), mode: PlayerMode.lowLatency);
    }
  }

  @override
  Future<void> stop() async {
    await _player.stop();
    await cancelRestNotification();
    playbackState.add(playbackState.value.copyWith(
      playing: false,
      processingState: AudioProcessingState.idle,
    ));
    return super.stop();
  }
}