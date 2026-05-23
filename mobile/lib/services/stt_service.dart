import 'dart:convert';
import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../models/pronunciation_attempt_model.dart';
import 'api_service.dart';

class SttService {
  final _storage = const FlutterSecureStorage();

  Future<PronunciationAttemptModel> evaluatePronunciation({
    required String audioFilePath,
    required String sessionId,
    required String wordId,
    required String lessonId,
    required int moduleNumber,
    required String targetWord,
    required int attemptNumber,
  }) async {
    try {
      final file = File(audioFilePath);
      if (!await file.exists()) {
        throw Exception("Audio recording file not found.");
      }

      final bytes = await file.readAsBytes();
      final audioBase64 = base64Encode(bytes);
      final token = await _storage.read(key: 'jwt_token');

      final response = await http.post(
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

      // Debug logging for server response
      // ignore: avoid_print
      print('STT evaluate response code: ${response.statusCode}');
      // ignore: avoid_print
      print('STT evaluate response body: ${response.body}');

      if (response.statusCode == 200) {
        return PronunciationAttemptModel.fromJson(json.decode(response.body));
      } else {
        return PronunciationAttemptModel(
          attemptId: '',
          isCorrect: false,
          transcribedText: null,
          phoneticTarget: null,
          phonologicalTip: null,
          attemptNumber: attemptNumber,
          isInconclusive: true,
        );
      }
    } catch (e) {
      return PronunciationAttemptModel(
        attemptId: '',
        isCorrect: false,
        transcribedText: null,
        phoneticTarget: null,
        phonologicalTip: null,
        attemptNumber: attemptNumber,
        isInconclusive: true,
      );
    }
  }
}
