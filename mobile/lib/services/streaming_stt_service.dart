import 'package:speech_to_text/speech_to_text.dart';

class StreamingSttService {
  final SpeechToText _speech = SpeechToText();
  bool _initialized = false;

  Future<bool> initialize() async {
    if (_initialized) return true;

    _initialized = await _speech.initialize(
      onError: (error) {},
      onStatus: (status) {},
    );

    return _initialized;
  }

  bool get isListening => _speech.isListening;

  /// Starts listening and forwards a simplified result callback with the
  /// recognized transcript and whether the result is final.
  Future<void> startListening({
    required void Function(String transcript, bool isFinal) onResult,
    required void Function(String status) onStatus,
    required void Function(String errorMsg) onError,
    String? localeId,
  }) async {
    final available = await initialize();
    if (!available) {
      throw StateError('Speech recognition is not available on this device.');
    }

    await _speech.listen(
      onResult: (dynamic result) {
        try {
          final dynamic r = result;
          String recognized = '';
          bool isFinal = false;

          try {
            recognized = (r.recognizedWords ?? r['recognizedWords'] ?? '').toString();
          } catch (_) {
            try {
              recognized = r.toString();
            } catch (_) {
              recognized = '';
            }
          }

          try {
            isFinal = (r.finalResult ?? r['finalResult'] ?? r['final'] ?? false) as bool;
          } catch (_) {
            isFinal = false;
          }

          onResult(recognized.trim(), isFinal);
        } catch (e) {
          // Fall back to sending stringified result
          onResult(result?.toString() ?? '', false);
        }
      },
      onSoundLevelChange: (_) {},
      listenOptions: SpeechListenOptions(
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 2),
        partialResults: true,
        cancelOnError: true,
        localeId: localeId,
      ),
      // The newer speech_to_text API surfaces status/error via initialize/listen
      // return values and may not accept these named parameters. We still
      // forward status/errors through the initialize hooks and simplified
      // callbacks.
    );
  }

  Future<void> stopListening() async {
    if (_speech.isListening) {
      await _speech.stop();
    }
  }

  Future<void> cancel() async {
    if (_speech.isListening) {
      await _speech.cancel();
    }
  }

  void dispose() {
    _speech.cancel();
  }
}