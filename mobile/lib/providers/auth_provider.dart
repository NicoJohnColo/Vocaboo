import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../models/learner_model.dart';

class AuthProvider with ChangeNotifier {
  final _storage = const FlutterSecureStorage();
  
  // Update this to point to your backend API. Use 10.0.2.2 for Android Emulator to host computer localhost.
  static const String baseUrl = 'http://10.0.2.2:8080/api/v1';

  String? _token;
  LearnerModel? _learner;
  bool _isInitialized = false;
  bool _isLoading = false;
  String? _error;

  String? get token => _token;
  LearnerModel? get learner => _learner;
  bool get isAuthenticated => _token != null;
  bool get isInitialized => _isInitialized;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<void> tryAutoLogin() async {
    if (_isInitialized) return;
    _isInitialized = true;
    
    try {
      final savedToken = await _storage.read(key: 'jwt_token');
      final savedLearnerId = await _storage.read(key: 'learner_id');
      
      if (savedToken != null && savedLearnerId != null) {
        // Validate token by fetching current profile
        final response = await http.get(
          Uri.parse('$baseUrl/learners/me'),
          headers: {
            'Authorization': 'Bearer $savedToken',
            'Content-Type': 'application/json',
          },
        );

        if (response.statusCode == 200) {
          _token = savedToken;
          _learner = LearnerModel.fromJson(json.decode(response.body));
        } else if (response.statusCode == 401) {
          // Token expired or invalid
          await logout();
        }
      }
    } catch (e) {
      // Fail silently for auto-login
    }
    notifyListeners();
  }

  Future<bool> register(String displayName, int age, String pin, String languagePreference) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/learners/register'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'displayName': displayName,
          'age': age,
          'pin': pin,
          'languagePreference': languagePreference,
        }),
      );

      final body = json.decode(response.body);

      if (response.statusCode == 200) {
        _token = body['token'];
        _learner = LearnerModel(
          learnerId: body['learnerId'],
          displayName: body['displayName'],
          age: age,
          languagePreference: body['languagePreference'],
          onboardingComplete: body['onboardingComplete'] ?? true,
        );

        await _storage.write(key: 'jwt_token', value: _token);
        await _storage.write(key: 'learner_id', value: _learner!.learnerId);
        
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = body['message'] ?? 'Failed to register learner';
      }
    } catch (e) {
      _error = 'Connection error. Please check your internet connection.';
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> login(String learnerId, String pin) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/learners/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'learnerId': learnerId,
          'pin': pin,
        }),
      );

      final body = json.decode(response.body);

      if (response.statusCode == 200) {
        _token = body['token'];
        _learner = LearnerModel(
          learnerId: body['learnerId'],
          displayName: body['displayName'],
          age: 9, // Fallback, will be refreshed
          languagePreference: body['languagePreference'],
          onboardingComplete: body['onboardingComplete'] ?? true,
        );

        await _storage.write(key: 'jwt_token', value: _token);
        await _storage.write(key: 'learner_id', value: _learner!.learnerId);

        // Fetch complete profile to get age
        await fetchProfile();
        
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = body['message'] ?? 'Incorrect ID or PIN. Please try again.';
      }
    } catch (e) {
      _error = 'Connection error. Please check your internet connection.';
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<void> fetchProfile() async {
    if (_token == null) return;
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/learners/me'),
        headers: {
          'Authorization': 'Bearer $_token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        _learner = LearnerModel.fromJson(json.decode(response.body));
        notifyListeners();
      } else if (response.statusCode == 401) {
        await logout();
      }
    } catch (e) {
      // Ignore
    }
  }

  Future<bool> updateProfile(String displayName, int age) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/learners/preferences'),
        headers: {
          'Authorization': 'Bearer $_token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'displayName': displayName,
        }),
      );

      if (response.statusCode == 200) {
        await fetchProfile();
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        final body = json.decode(response.body);
        _error = body['message'] ?? 'Failed to update profile.';
      }
    } catch (e) {
      _error = 'Connection error. Please check your internet connection.';
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> changePin(String currentPin, String newPin) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/learners/change-pin'),
        headers: {
          'Authorization': 'Bearer $_token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'currentPin': currentPin,
          'newPin': newPin,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        final body = json.decode(response.body);
        _error = body['message'] ?? 'Failed to change PIN.';
      }
    } catch (e) {
      _error = 'Connection error. Please check your internet connection.';
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> updateLanguagePreference(String languagePreference) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/learners/preferences'),
        headers: {
          'Authorization': 'Bearer $_token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'languagePreference': languagePreference,
        }),
      );

      if (response.statusCode == 200) {
        await fetchProfile();
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        final body = json.decode(response.body);
        _error = body['message'] ?? 'Failed to update language preference.';
      }
    } catch (e) {
      _error = 'Connection error. Please check your internet connection.';
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<void> logout() async {
    _token = null;
    _learner = null;
    await _storage.delete(key: 'jwt_token');
    await _storage.delete(key: 'learner_id');
    notifyListeners();
  }
}
