import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_service.dart';

class VocabularyIntroductionService extends ApiService {
  Future<bool> updateStepProgress({
    required String sessionId,
    required String wordId,
    required String pathway,
    required int stepCompleted,
    required String status,
    int moduleNumber = 1,
  }) async {
    try {
      final headers = await getHeaders();
      final response = await http.patch(
        Uri.parse('${ApiService.baseUrl}/sessions/$sessionId/progress'),
        headers: headers,
        body: json.encode({
          'wordId': wordId,
          'pathway': pathway,
          'stepCompleted': stepCompleted,
          'status': status,
          'moduleNumber': moduleNumber,
        }),
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
