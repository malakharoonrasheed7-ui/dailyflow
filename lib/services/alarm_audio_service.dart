import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

class AlarmAudioService {
  static final AudioPlayer _player = AudioPlayer();
  static bool isPlaying = false;
  static final ValueNotifier<bool> isRingingNotifier = ValueNotifier<bool>(false);

  static Future<void> init() async {
    try {
      await _player.setReleaseMode(ReleaseMode.loop);
      _player.onPlayerStateChanged.listen((state) {
        isPlaying = state == PlayerState.playing;
        isRingingNotifier.value = isPlaying;
      });
    } catch (_) {}
  }

  /// Plays alarm.mp3 in an infinite non-stop loop until user explicitly taps Stop
  static Future<void> playLooping() async {
    try {
      await _player.stop();
      await _player.setReleaseMode(ReleaseMode.loop);
      await _player.setAudioContext(
        AudioContext(
          android: const AudioContextAndroid(
            isSpeakerphoneOn: true,
            stayAwake: true,
            contentType: AndroidContentType.music,
            usageType: AndroidUsageType.alarm,
            audioFocus: AndroidAudioFocus.gainTransientExclusive,
          ),
          iOS: AudioContextIOS(
            category: AVAudioSessionCategory.playback,
            options: const {
              AVAudioSessionOptions.duckOthers,
            },
          ),
        ),
      );
      await _player.play(AssetSource('audio/alarm.mp3'), volume: 1.0);
      isPlaying = true;
      isRingingNotifier.value = true;
    } catch (e) {
      debugPrint('AlarmAudioService playLooping error: $e');
    }
  }

  /// Immediately silences the alarm
  static Future<void> stop() async {
    try {
      await _player.stop();
      isPlaying = false;
      isRingingNotifier.value = false;
    } catch (_) {}
  }
}
