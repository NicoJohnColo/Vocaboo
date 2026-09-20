import 'dart:io' show Platform;

import 'package:flutter_tts/flutter_tts.dart';

/// A high-performance wrapper around `flutter_tts` designed for rapid,
/// spammable, zero-latency speech synthesis.
///
/// Features:
/// - Pre-warmed engine initialization with offline/local voice prioritization.
/// - Immediate audio cancellation via `stop()` as the first line of any speak call.
/// - Cached language and capability checks to avoid redundant IPC overhead.
class TTSService {
  static final FlutterTts _flutterTts = FlutterTts();
  static Future<void>? _initializeFuture;
  static bool _isInitialized = false;
  static bool _filPhChecked = false;
  static bool _filPhAvailable = true;
  static String _currentLanguage = 'en-US';

  /// Initializes and pre-warms the TTS engine.
  static Future<void> initialize() {
    _initializeFuture ??= _configureTts();
    return _initializeFuture!;
  }

  static Future<void> _configureTts() async {
    try {
      if (Platform.isAndroid) {
        await _configureAndroidTts();
      }

      await _flutterTts.setSpeechRate(0.4);
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.0);
      await _flutterTts.awaitSpeakCompletion(false);
      await _flutterTts.setLanguage('en-US');
      _currentLanguage = 'en-US';

      // Pre-check Cebuano/Tagalog availability once during initialization to avoid per-tap IPC
      try {
        final isAvailable = await _flutterTts.isLanguageAvailable('fil-PH');
        _filPhAvailable = (isAvailable == true || isAvailable == 1);
        _filPhChecked = true;
      } catch (_) {
        _filPhAvailable = true;
        _filPhChecked = true;
      }

      _isInitialized = true;
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
        final englishVoices = voices
            .whereType<Map>()
            .map((voice) => voice.map((key, value) => MapEntry(key.toString(), value.toString())))
            .where((voice) {
              final locale = (voice['locale'] ?? '').toLowerCase();
              return locale.startsWith('en') || locale.contains('en-') || locale.contains('en_');
            })
            .toList();

        if (englishVoices.isNotEmpty) {
          // Force local/fast offline voices: prioritize local voices and exclude network voices
          // Network voices induce buffering latency when rapidly tapped
          final localVoice = englishVoices.firstWhere(
            (voice) {
              final name = (voice['name'] ?? '').toLowerCase();
              final features = (voice['features'] ?? '').toLowerCase();
              final isNetwork = name.contains('network') || features.contains('network');
              final isLocal = name.contains('local') || features.contains('local');
              return isLocal || !isNetwork;
            },
            orElse: () => englishVoices.first,
          );
          await _flutterTts.setVoice(localVoice);
        }
      }
    } catch (e) {
      // ignore: avoid_print
      print('TTSService.configureAndroid error: $e');
    }
  }

  /// Speaks the provided [text] using the configured TTS engine (defaulting to English).
  /// Instantly stops any playing audio before triggering new speech.
  static Future<void> speak(String text) async {
    await _flutterTts.stop();
    await speakEnglish(text);
  }

  /// Speaks the provided [text] in Cebuano using the native fil-PH locale.
  /// Instantly stops any playing audio before triggering new speech.
  static Future<bool> speakCebuano(String text) async {
    // 1. Instant cut-off: kill any existing speech immediately
    await _flutterTts.stop();
    if (text.trim().isEmpty) return true;

    try {
      if (!_isInitialized) {
        await initialize();
      }

      if (_filPhChecked && !_filPhAvailable) {
        // ignore: avoid_print
        print('TTSService: fil-PH language not available on this device');
        return false;
      }

      if (_currentLanguage != 'fil-PH') {
        await _flutterTts.setLanguage('fil-PH');
        _currentLanguage = 'fil-PH';
      }

      // Clean and normalize Cebuano text (diacritics/accents) for Tagalog TTS compatibility
      final cleanedText = cleanCebuanoDiacritics(text);
      final result = await _flutterTts.speak(cleanedText);
      return result == 1;
    } catch (e) {
      // ignore: avoid_print
      print('TTSService.speakCebuano error: $e');
      return false;
    }
  }

  /// Speaks the provided [text] in English using the native en-US locale.
  /// Instantly stops any playing audio before triggering new speech.
  static Future<bool> speakEnglish(String text) async {
    // 1. Instant cut-off: kill any existing speech immediately
    await _flutterTts.stop();
    if (text.trim().isEmpty) return true;

    try {
      if (!_isInitialized) {
        await initialize();
      }

      if (_currentLanguage != 'en-US') {
        await _flutterTts.setLanguage('en-US');
        _currentLanguage = 'en-US';
      }

      final result = await _flutterTts.speak(text);
      return result == 1;
    } catch (e) {
      // ignore: avoid_print
      print('TTSService.speakEnglish error: $e');
      return false;
    }
  }

  /// Speaks an isolated phonetic sound with clear articulation.
  /// Instantly stops any playing audio before triggering new speech.
  static Future<bool> speakSound(String soundText) async {
    await _flutterTts.stop();
    if (soundText.trim().isEmpty) return true;

    try {
      if (!_isInitialized) {
        await initialize();
      }

      if (_currentLanguage != 'en-US') {
        await _flutterTts.setLanguage('en-US');
        _currentLanguage = 'en-US';
      }

      await _flutterTts.setSpeechRate(0.32);
      final result = await _flutterTts.speak(soundText);
      await _flutterTts.setSpeechRate(0.4);
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
      await _flutterTts.stop();
    } catch (_) {
      // Safely ignore if engine is not currently bound
    }
  }
}

/// Backward-compatible instance wrapper for screens that still create `TtsService()`.
/// Automatically pre-warms the engine in constructor to eliminate cold starts.
class TtsService {
  TtsService() {
    TTSService.initialize();
  }

  Future<void> initialize() => TTSService.initialize();

  Future<void> speak(String text) => TTSService.speak(text);

  Future<bool> speakSound(String soundText) => TTSService.speakSound(soundText);

  Future<bool> speakCebuano(String text) => TTSService.speakCebuano(text);

  Future<bool> speakEnglish(String text) => TTSService.speakEnglish(text);

  Future<void> stop() => TTSService.stop();
}
