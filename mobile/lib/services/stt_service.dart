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

      if (_disposed) return _inconclusiveResult(attemptNumber);

      // Proactively refresh the token if it is already expired so we don't
      // send a request we know will fail with 403.
      final token = await _getValidToken();

      if (_disposed) return _inconclusiveResult(attemptNumber);

      final requestBody = json.encode({
        'sessionId': sessionId,
        'wordId': wordId,
        'lessonId': lessonId,
        'moduleNumber': moduleNumber,
        'targetWord': targetWord,
        'audioBase64': audioBase64,
        'attemptNumber': attemptNumber,
      });

      var response = await client.post(
        Uri.parse('${ApiService.baseUrl}/pronunciation/evaluate'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: requestBody,
      );

      // ignore: avoid_print
      print('STT evaluate response code: ${response.statusCode}');
      // ignore: avoid_print
      print('STT evaluate response body: ${response.body}');

      // Defensive retry: if the server still returns 403, attempt one token
      // refresh and retry the request (handles clock-skew and edge cases).
      if (response.statusCode == 403 || response.statusCode == 401) {
        final refreshed = await _tryRefreshToken();
        if (refreshed && !_disposed) {
          final newToken = await _storage.read(key: 'access_token');
          response = await client.post(
            Uri.parse('${ApiService.baseUrl}/pronunciation/evaluate'),
            headers: {
              'Authorization': 'Bearer $newToken',
              'Content-Type': 'application/json',
            },
            body: requestBody,
          );
          // ignore: avoid_print
          print('STT retry response code: ${response.statusCode}');
        }
      }

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

  /// Returns the stored access token, refreshing it first if it is expired.
  Future<String?> _getValidToken() async {
    try {
      final token = await _storage.read(key: 'jwt_token');
      if (token == null) return null;

      // Decode and check the 'exp' claim without a dependency on TokenService.
      final parts = token.split('.');
      if (parts.length == 3) {
        final payload = parts[1];
        final padded = payload.padRight(
            payload.length + (4 - payload.length % 4) % 4, '=');
        final decoded = utf8.decode(base64Url.decode(padded));
        final Map<String, dynamic> claims = json.decode(decoded);
        final exp = claims['exp'];
        if (exp != null) {
          final expiryDate =
              DateTime.fromMillisecondsSinceEpoch((exp as int) * 1000);
          if (DateTime.now().isAfter(expiryDate)) {
            // Token is expired — refresh before proceeding.
            await _tryRefreshToken();
            return await _storage.read(key: 'access_token');
          }
        }
      }
      return token;
    } catch (_) {
      return await _storage.read(key: 'jwt_token');
    }
  }

  /// Calls POST /api/auth/refresh with the stored refresh token.
  /// Returns true if a new access token was obtained and saved.
  Future<bool> _tryRefreshToken() async {
    try {
      final refreshToken = await _storage.read(key: 'refresh_token');
      if (refreshToken == null) return false;

      final refreshUrl = ApiService.baseUrl
          .replaceAll('/api/v1', '');
      final response = await http.post(
        Uri.parse('$refreshUrl/api/auth/refresh'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'refresh_token': refreshToken}),
      );

      if (response.statusCode == 200) {
        final body = json.decode(response.body) as Map<String, dynamic>;
        final newAccessToken = body['access_token'] as String?;
        if (newAccessToken != null) {
          // Write under both keys (jwt_token is the key SttService reads,
          // access_token is the key TokenService / AuthInterceptor write to).
          await Future.wait([
            _storage.write(key: 'jwt_token', value: newAccessToken),
            _storage.write(key: 'access_token', value: newAccessToken),
          ]);
          return true;
        }
      }
    } catch (_) {
      // Network error — cannot refresh
    }
    return false;
  }
}
