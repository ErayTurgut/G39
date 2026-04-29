import 'package:audio_service/audio_service.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:io';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter/material.dart';

class MyAudioHandler extends BaseAudioHandler {
  final _player = AudioPlayer();
  final FlutterLocalNotificationsPlugin _localNotificationsPlugin = FlutterLocalNotificationsPlugin();

  MyAudioHandler() {
    _initHandler();
  }

  Future<void> _initHandler() async {
    tz.initializeTimeZones();

    await _player.setAudioContext(AudioContext(
      iOS: AudioContextIOS(
        category: AVAudioSessionCategory.playback,
        options: [AVAudioSessionOptions.mixWithOthers, AVAudioSessionOptions.duckOthers],
      ),
      android: AudioContextAndroid(
        contentType: AndroidContentType.music,
        usageType: AndroidUsageType.media,
        audioFocus: AndroidAudioFocus.gain, 
      ),
    ));

    const initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
        // ✅ Uygulama AÇIKKEN ses ve bildirim gelmesini sağlar
        defaultPresentAlert: true,
        defaultPresentSound: true,
        defaultPresentBadge: true,
      ),
    );
    
    await _localNotificationsPlugin.initialize(initializationSettings);

    // ✅ iOS İÇİN İZİN PENCERESİNİ ÇIKARTIR
    final iosImplementation = _localNotificationsPlugin
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    if (iosImplementation != null) {
      await iosImplementation.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
    }

    // Android İzinleri
    final androidImplementation = _localNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (androidImplementation != null) {
      await androidImplementation.requestNotificationsPermission();
    }
  }

  void startWorkoutSession() {
    playbackState.add(playbackState.value.copyWith(
      controls: [MediaControl.stop],
      playing: true,
      processingState: AudioProcessingState.ready,
    ));
  }

  Future<void> cancelRestNotification() async {
    await _localNotificationsPlugin.cancel(1);
  }

  Future<void> _ensureChannelExists(String soundName) async {
    final channelId = 'g39_channel_$soundName'; 
    
    final androidChannel = AndroidNotificationChannel(
      channelId,
      'G39 Antrenman ($soundName)',
      importance: Importance.max,
      playSound: true,
      sound: RawResourceAndroidNotificationSound(soundName),
    );

    await _localNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);
  }

  Future<void> scheduleRestNotification(int seconds, String soundType) async {
    final String fileName = soundType.toLowerCase().replaceAll(' ', '_');
    final String channelId = 'g39_channel_$fileName'; 

    await _ensureChannelExists(fileName);
    await cancelRestNotification(); 

    debugPrint("🔔 [G39] Bildirim kuruluyor. Kanal: $channelId, Ses: $fileName, Süre: $seconds");

    try {
      await _localNotificationsPlugin.zonedSchedule(
        1,
        'Vakit Geldi! 👊🏼',
        'Odaklan!',
        tz.TZDateTime.now(tz.local).add(Duration(seconds: seconds)),
        NotificationDetails(
          android: AndroidNotificationDetails(
            channelId, 
            'G39 Dinlenme',
            importance: Importance.max,
            priority: Priority.high,
            sound: RawResourceAndroidNotificationSound(fileName),
            playSound: true,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentSound: true, // ✅ Arka planda sesi tetikler
            presentBadge: true,
            sound: '$fileName.mp3', // ✅ Xcode'daki dosya ismi + .mp3
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (e) {
      debugPrint("❌ [G39] Bildirim hatası: $e");
    }
  }

  Future<void> playCustomSound(String soundType, {String? customPath}) async {
    try {
      await _player.stop();
      if (soundType == "custom" && customPath != null) {
        await _player.play(DeviceFileSource(customPath));
      } else {
        final String fileName = soundType.toLowerCase().replaceAll(' ', '_');
        await _player.play(AssetSource('sounds/$fileName.mp3'));
      }
    } catch (e) {
      debugPrint("❌ [G39] Ses çalma hatası: $e");
    }
  }

  @override
  Future<void> stop() async {
    await _player.stop();
    await cancelRestNotification(); 
    playbackState.add(playbackState.value.copyWith(playing: false, processingState: AudioProcessingState.idle));
    return super.stop();
  }
}