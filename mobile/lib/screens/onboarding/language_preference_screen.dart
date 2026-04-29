import 'package:flutter/material.dart';
import '../../services/learner_service.dart';
import '../../models/learner_model.dart';
import '../../utils/local_storage.dart';

class LanguagePreferenceScreen extends StatefulWidget {
  final String name;
  final int age;
  final String pin;

  const LanguagePreferenceScreen({
    super.key,
    required this.name,
    required this.age,
    required this.pin,
  });

  @override
  State<LanguagePreferenceScreen> createState() =>
      _LanguagePreferenceScreenState();
}

class _LanguagePreferenceScreenState extends State<LanguagePreferenceScreen> {
  String selectedPreference = 'Cebuano-to-English';
  bool isLoading = false;

  final List<Map<String, String>> preferences = [
    {
      'value': 'Cebuano-to-English',
      'label': 'Cebuano-to-English',
      'description':
          'Instructions appear in Cebuano first, followed by English'
    },
    {
      'value': 'Full English',
      'label': 'Full English',
      'description': 'All instructions are in English only'
    },
    {
      'value': 'Cebuano/English Mixed',
      'label': 'Cebuano/English Mixed',
      'description':
          'Cebuano for explanations, English for task directions'
    },
  ];

  Future<void> completeOnboarding() async {
    setState(() => isLoading = true);
    try {
      final learner = LearnerModel(
        name: widget.name,
        age: widget.age,
        pin: widget.pin,
        languagePreference: selectedPreference,
      );
      final created = await LearnerService.createLearner(learner);
      await LocalStorage.saveLearnerProfile(
        id: created.id!,
        name: created.name,
        age: created.age,
        pin: created.pin,
        languagePreference: created.languagePreference,
      );
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e. Please try again.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Choose Language Mode')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'How would you like instructions to appear?',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: ListView(
                children: preferences.map((pref) {
                  return Card(
                    child: RadioListTile<String>(
                      title: Text(
                        pref['label']!,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(pref['description']!),
                      value: pref['value']!,
                      groupValue: selectedPreference,
                      onChanged: (value) {
                        setState(() => selectedPreference = value!);
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isLoading ? null : completeOnboarding,
                child: isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text('Start Learning'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
