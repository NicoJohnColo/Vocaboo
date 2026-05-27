import 'package:flutter_tts/flutter_tts.dart';

/// A simple wrapper around `flutter_tts` providing static helper methods.
///
/// The service is intentionally lightweight. It only exposes `initialize`,
/// `speak`, and `stop` because that is all the app needs from multiple
/// screens.
class TTSService {
  static final FlutterTts _flutterTts = FlutterTts();

  /// Initializes the TTS engine.
  static Future<void> initialize() async {
    try {
      await _flutterTts.setLanguage('en-US');
      await _flutterTts.setSpeechRate(0.4);
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.0);
    } catch (e) {
      // ignore: avoid_print
      print('TTSService.initialize error: $e');
    }
  }

  /// Speaks the provided [text] using the configured TTS engine.
  static Future<void> speak(String text) async {
    if (text.trim().isEmpty) return;

    try {
      // ignore: avoid_print
      print('TTSService.speak: "$text"');
      await _flutterTts.stop();
      await _flutterTts.speak(text);
    } catch (e) {
      // ignore: avoid_print
      print('TTSService.speak error: $e');
    }
  }

  /// Stops any ongoing speech synthesis.
  static Future<void> stop() async {
    try {
      await _flutterTts.stop();
    } catch (e) {
      // ignore: avoid_print
      print('TTSService.stop error: $e');
    }
  }
}

/// Backward-compatible instance wrapper for screens that still create `TtsService()`.
@Deprecated('Use TTSService instead')
class TtsService {
  Future<void> initialize() => TTSService.initialize();

  Future<void> speak(String text) => TTSService.speak(text);

  Future<void> stop() => TTSService.stop();
}
