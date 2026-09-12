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

  /// Speaks the provided [text] using the configured TTS engine (defaulting to English).
  static Future<void> speak(String text) async {
    await speakEnglish(text);
  }

  /// Speaks the provided [text] in Cebuano using the native fil-PH locale.
  /// Returns true if successful, false if the language/engine is not supported.
  static Future<bool> speakCebuano(String text) async {
    if (text.trim().isEmpty) return true;

    try {
      await initialize();
      
      // Check language availability
      final isAvailable = await _flutterTts.isLanguageAvailable('fil-PH');
      if (isAvailable == null || isAvailable == false) {
        // ignore: avoid_print
        print('TTSService: fil-PH language not available on this device');
        return false;
      }

      await _flutterTts.stop();
      await _flutterTts.setLanguage('fil-PH');
      
      // Clean and normalize Cebuano text (diacritics/accents) for Tagalog TTS compatibility
      final cleanedText = cleanCebuanoDiacritics(text);
      // ignore: avoid_print
      print('TTSService.speakCebuano: "$cleanedText" (original: "$text")');
      
      final result = await _flutterTts.speak(cleanedText);
      return result == 1; // 1 indicates success in flutter_tts API
    } catch (e) {
      // ignore: avoid_print
      print('TTSService.speakCebuano error: $e');
      return false;
    }
  }

  /// Speaks the provided [text] in English using the native en-US locale.
  /// Returns true if successful.
  static Future<bool> speakEnglish(String text) async {
    if (text.trim().isEmpty) return true;

    try {
      await initialize();
      await _flutterTts.stop();
      await _flutterTts.setLanguage('en-US');
      
      // ignore: avoid_print
      print('TTSService.speakEnglish: "$text"');
      final result = await _flutterTts.speak(text);
      return result == 1;
    } catch (e) {
      // ignore: avoid_print
      print('TTSService.speakEnglish error: $e');
      return false;
    }
  }

  /// Speaks an isolated phonetic sound (e.g. "ah", "sh", "buh") with clear articulation.
  static Future<bool> speakSound(String soundText) async {
    if (soundText.trim().isEmpty) return true;
    try {
      await initialize();
      await _flutterTts.stop();
      await _flutterTts.setLanguage('en-US');
      await _flutterTts.setSpeechRate(0.32); // Slightly slower for clear sound articulation
      final result = await _flutterTts.speak(soundText);
      await _flutterTts.setSpeechRate(0.4); // Reset to default
      return result == 1;
    } catch (e) {
      // ignore: avoid_print
      print('TTSService.speakSound error: $e');
      return false;
    }
  }

  /// Cleans and replaces common accented characters to ensure smooth pronunciation by the engine.
  static String cleanCebuanoDiacritics(String text) {
    var cleaned = text;
    const diacritics = {
      'á': 'a', 'à': 'a', 'â': 'a', 'ä': 'a', 'ã': 'a',
      'é': 'e', 'è': 'e', 'ê': 'e', 'ë': 'e',
      'í': 'i', 'ì': 'i', 'î': 'i', 'ï': 'i',
      'ó': 'o', 'ò': 'o', 'ô': 'o', 'ö': 'o', 'õ': 'o',
      'ú': 'u', 'ù': 'u', 'û': 'u', 'ü': 'u',
      'Á': 'A', 'À': 'A', 'Â': 'A', 'Ä': 'A', 'Ã': 'A',
      'É': 'E', 'È': 'E', 'Ê': 'E', 'Ë': 'E',
      'Í': 'I', 'Ì': 'I', 'Î': 'I', 'Ï': 'I',
      'Ó': 'O', 'Ò': 'O', 'Ô': 'O', 'Ö': 'O', 'Õ': 'O',
      'Ú': 'U', 'Ù': 'U', 'Û': 'U', 'Ü': 'U',
    };
    
    diacritics.forEach((accent, replacement) {
      cleaned = cleaned.replaceAll(accent, replacement);
    });
    return cleaned;
  }

  /// Stops any ongoing speech synthesis.
  static Future<void> stop() async {
    try {
      if (_initializeFuture != null) {
        await _flutterTts.stop();
      }
    } catch (_) {
      // Safely ignore if engine is not currently bound
    }
  }
}

/// Backward-compatible instance wrapper for screens that still create `TtsService()`.
@Deprecated('Use TTSService instead')
class TtsService {
  Future<void> initialize() => TTSService.initialize();

  Future<void> speak(String text) => TTSService.speak(text);
  
  Future<bool> speakSound(String soundText) => TTSService.speakSound(soundText);
  
  Future<bool> speakCebuano(String text) => TTSService.speakCebuano(text);
  
  Future<bool> speakEnglish(String text) => TTSService.speakEnglish(text);

  Future<void> stop() => TTSService.stop();
}
