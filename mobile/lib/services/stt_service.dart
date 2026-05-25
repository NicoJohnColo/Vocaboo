import 'dart:convert';
import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../models/pronunciation_attempt_model.dart';
import 'api_service.dart';

class SttService {
  final _storage = const FlutterSecureStorage();
  http.Client? _activeClient;
  bool _disposed = false;

  /// Call from the owning widget's dispose() to abort any in-flight request.
  void dispose() {
    _disposed = true;
    _activeClient?.close();
    _activeClient = null;
  }

  PronunciationAttemptModel _inconclusiveResult(int attemptNumber) =>
      PronunciationAttemptModel(
        attemptId: '',
        isCorrect: false,
        transcribedText: null,
        phoneticTarget: null,
        phonologicalTip: null,
        attemptNumber: attemptNumber,
        isInconclusive: true,
      );

  Future<PronunciationAttemptModel> evaluatePronunciation({
    required String audioFilePath,
    required String sessionId,
    required String wordId,
    required String lessonId,
    required int moduleNumber,
    required String targetWord,
    required int attemptNumber,
  }) async {
    if (_disposed) return _inconclusiveResult(attemptNumber);

    // Close any previous in-flight request before starting a new one.
    _activeClient?.close();
    final client = http.Client();
    _activeClient = client;

    try {
      final file = File(audioFilePath);
      if (!await file.exists()) {
        throw Exception('Audio recording file not found.');
      }

      final bytes = await file.readAsBytes();
      final audioBase64 = base64Encode(bytes);
      final token = await _storage.read(key: 'jwt_token');

      if (_disposed) return _inconclusiveResult(attemptNumber);

      final response = await client.post(
        Uri.parse('${ApiService.baseUrl}/pronunciation/evaluate'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'sessionId': sessionId,
          'wordId': wordId,
          'lessonId': lessonId,
          'moduleNumber': moduleNumber,
          'targetWord': targetWord,
          'audioBase64': audioBase64,
          'attemptNumber': attemptNumber,
        }),
      );

      // ignore: avoid_print
      print('STT evaluate response code: ${response.statusCode}');
      // ignore: avoid_print
      print('STT evaluate response body: ${response.body}');

      _activeClient = null;

      if (response.statusCode == 200) {
        return PronunciationAttemptModel.fromJson(json.decode(response.body));
      }
      return _inconclusiveResult(attemptNumber);
    } catch (_) {
      _activeClient = null;
      return _inconclusiveResult(attemptNumber);
    } finally {
      // Only close the client we own; a newer call may have already replaced it.
      if (identical(_activeClient, client)) {
        client.close();
        _activeClient = null;
      }
    }
  }
}
