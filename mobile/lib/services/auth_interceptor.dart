import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_service.dart';
import 'token_service.dart';

/// HTTP interceptor that automatically handles 401 (Unauthorized) responses
/// by attempting a token refresh, then retrying the original request once.
/// On refresh failure, it clears all tokens (forcing the user to re-login).
class AuthInterceptor {
  final TokenService _tokenService;

  AuthInterceptor({TokenService? tokenService})
      : _tokenService = tokenService ?? TokenService();

  /// Wraps an HTTP call with automatic token refresh on 401.
  ///
  /// Usage:
  ///   final response = await interceptor.send(
  ///     () => http.get(uri, headers: await apiService.getHeaders()),
  ///     onSessionExpired: () => navigateToLogin(),
  ///   );
  Future<http.Response> send(
    Future<http.Response> Function() request, {
    void Function()? onSessionExpired,
  }) async {
    http.Response response = await request();

    if (response.statusCode == 401) {
      // Attempt token refresh
      final refreshed = await _tryRefresh();
      if (refreshed) {
        // Retry the original request with the new access token
        response = await request();
      } else {
        // Refresh failed — clear tokens and signal session expiry
        await _tokenService.clearAllTokens();
        onSessionExpired?.call();
      }
    }
    return response;
  }

  /// Calls POST /api/auth/refresh with the stored refresh token.
  /// Returns true if a new access token was successfully obtained and stored.
  Future<bool> _tryRefresh() async {
    final refreshToken = await _tokenService.getRefreshToken();
    if (refreshToken == null) return false;

    try {
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl.replaceAll('/api/v1', '')}/api/auth/refresh'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'refresh_token': refreshToken}),
      );

      if (response.statusCode == 200) {
        final body = json.decode(response.body) as Map<String, dynamic>;
        final newAccessToken = body['access_token'] as String?;
        if (newAccessToken != null) {
          await _tokenService.saveAccessToken(newAccessToken);
          return true;
        }
      }
    } catch (_) {
      // Network error — cannot refresh
    }
    return false;
  }
}
