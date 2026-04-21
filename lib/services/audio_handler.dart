import 'package:audio_service/audio_service.dart';
import 'package:audioplayers/audioplayers.dart';

class MyAudioHandler extends BaseAudioHandler {
  final _player = AudioPlayer();

  MyAudioHandler() {
    // Ses ayarlarını burada da yapıyoruz (Apple Music'i kısmaması için)
    _player.setAudioContext(AudioContext(
      iOS: AudioContextIOS(
        category: AVAudioSessionCategory.playback,
        options: [AVAudioSessionOptions.mixWithOthers],
      ),
      android: AudioContextAndroid(
        contentType: AndroidContentType.music,
        usageType: AndroidUsageType.media,
        audioFocus: AndroidAudioFocus.none,
      ),
    ));
  }

  // UI'dan gelen ses çalma komutlarını burada karşılayacağız
  @override
  Future<void> play() async {
    // Burada bip sesini tetikleyeceğiz
    await _player.play(AssetSource('sounds/beep.mp3'));
  }

  // İhtiyaç duyarsan özel fonksiyonlar ekleyebilirsin
  Future<void> playCustomSound(String path, bool isAsset) async {
    if (isAsset) {
      await _player.play(AssetSource(path));
    } else {
      await _player.play(DeviceFileSource(path));
    }
  }
}