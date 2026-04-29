import 'package:shared_preferences/shared_preferences.dart';

class LocalStorage {
  static Future<void> saveLearnerProfile({
    required int id,
    required String name,
    required int age,
    required String pin,
    required String languagePreference,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('learner_id', id);
    await prefs.setString('learner_name', name);
    await prefs.setInt('learner_age', age);
    await prefs.setString('learner_pin', pin);
    await prefs.setString('language_preference', languagePreference);
    await prefs.setBool('is_onboarded', true);
  }

  static Future<bool> isOnboarded() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('is_onboarded') ?? false;
  }

  static Future<Map<String, dynamic>> getLearnerProfile() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'id': prefs.getInt('learner_id'),
      'name': prefs.getString('learner_name'),
      'age': prefs.getInt('learner_age'),
      'pin': prefs.getString('learner_pin'),
      'languagePreference': prefs.getString('language_preference'),
    };
  }

  static Future<void> clearProfile() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  static Future<String?> getLanguagePreference() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('language_preference');
  }

  static Future<int?> getLearnerId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('learner_id');
  }
}
