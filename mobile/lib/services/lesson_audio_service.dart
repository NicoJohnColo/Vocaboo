import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

class LessonAudioService {
  static final LessonAudioService _instance = LessonAudioService._internal();
  factory LessonAudioService() => _instance;
  LessonAudioService._internal();

  final AudioPlayer _bgmPlayer = AudioPlayer();
  final AudioPlayer _sfxPlayer = AudioPlayer();

  bool _isBgmPlaying = false;

  Future<void> playBgm() async {
    if (_isBgmPlaying) return;
    try {
      await _bgmPlayer.setReleaseMode(ReleaseMode.loop);
      await _bgmPlayer.play(AssetSource('audio/bgm.mp3'));
      _isBgmPlaying = true;
    } catch (e) {
      debugPrint('Error playing BGM: $e');
    }
  }

  Future<void> stopBgm() async {
    try {
      await _bgmPlayer.stop();
      _isBgmPlaying = false;
    } catch (e) {
      debugPrint('Error stopping BGM: $e');
    }
  }

  Future<void> playCorrect() async {
    try {
      await _sfxPlayer.play(AssetSource('audio/correct.mp3'));
    } catch (e) {
      debugPrint('Error playing correct SFX: $e');
    }
  }

  Future<void> playWrong() async {
    try {
      await _sfxPlayer.play(AssetSource('audio/wrong.mp3'));
    } catch (e) {
      debugPrint('Error playing wrong SFX: $e');
    }
  }

  Future<void> playTimeUp() async {
    try {
      await _sfxPlayer.play(AssetSource('audio/wrong.mp3')); // fallback to wrong.mp3
    } catch (e) {
      debugPrint('Error playing time up SFX: $e');
    }
  }
  
  void dispose() {
    _bgmPlayer.dispose();
    _sfxPlayer.dispose();
  }
}
