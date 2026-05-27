import 'dart:io' show Platform;

import 'package:flutter_tts/flutter_tts.dart';

/// A simple wrapper around `flutter_tts` providing static helper methods.
///
/// The service is intentionally lightweight. It only exposes `initialize`,
/// `speak`, and `stop` because that is all the app needs from multiple
/// screens.
class TTSService {
  static final FlutterTts _flutterTts = FlutterTts();
  static Future<void>? _initializeFuture;

  /// Initializes the TTS engine.
  static Future<void> initialize() async {
    if (_initializeFuture != null) {
      return _initializeFuture!;
    }

    _initializeFuture = _configureTts();
    return _initializeFuture!;
  }

  static Future<void> _configureTts() async {
    try {
      if (Platform.isAndroid) {
        await _configureAndroidTts();
      }

      await _flutterTts.setLanguage('en-US');
      await _flutterTts.setSpeechRate(0.4);
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.0);
      await _flutterTts.awaitSpeakCompletion(false);
    } catch (e) {
      // ignore: avoid_print
      print('TTSService.initialize error: $e');
    }
  }

  static Future<void> _configureAndroidTts() async {
    try {
      final engines = await _flutterTts.getEngines;
      if (engines is List && engines.isNotEmpty) {
        final engineCandidates = engines.map((engine) => engine.toString()).toList();
        final preferredEngine = engineCandidates.firstWhere(
          (engine) => engine.toLowerCase().contains('google'),
          orElse: () => engineCandidates.first,
        );
        await _flutterTts.setEngine(preferredEngine);
      }

      final voices = await _flutterTts.getVoices;
      if (voices is List && voices.isNotEmpty) {
        final englishVoice = voices
            .whereType<Map>()
            .map((voice) => voice.map((key, value) => MapEntry(key.toString(), value.toString())))
            .where((voice) {
              final locale = (voice['locale'] ?? '').toLowerCase();
              return locale.startsWith('en') || locale.contains('en-');
            })
            .toList();

        if (englishVoice.isNotEmpty) {
          await _flutterTts.setVoice(englishVoice.first);
        }
      }
    } catch (e) {
      // ignore: avoid_print
      print('TTSService.configureAndroid error: $e');
    }
  }

  /// Speaks the provided [text] using the configured TTS engine.
  static Future<void> speak(String text) async {
    if (text.trim().isEmpty) return;

    try {
      await initialize();
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
