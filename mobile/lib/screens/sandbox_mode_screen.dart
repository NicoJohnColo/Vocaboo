import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/lesson_provider.dart';
import '../services/localization_service.dart';
import '../services/tts_service.dart';
import 'vocabulary_introduction_screen.dart';

class SandboxModeScreen extends StatefulWidget {
  const SandboxModeScreen({super.key});

  @override
  State<SandboxModeScreen> createState() => _SandboxModeScreenState();
}

class _SandboxModeScreenState extends State<SandboxModeScreen> {
  final TextEditingController _customWordController = TextEditingController();

  bool _loading = false;
  String? _error;
  Map<String, dynamic>? _session;
  List<Map<String, dynamic>> _words = [];

  @override
  void dispose() {
    _customWordController.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    final provider = Provider.of<LessonProvider>(context, listen: false);
    final customWord = _customWordController.text.trim();

    if (customWord.isEmpty) {
      setState(() {
        _error = 'Enter one English word.';
      });
      return;
    }

    if (customWord.split(RegExp(r'\s+')).length != 1) {
      setState(() {
        _error = 'Sandbox accepts exactly one English word.';
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    Map<String, dynamic>? result;
    String? errorMessage;
    
    try {
      result = await provider.generateSandbox(customWord: customWord);
    } catch (e) {
      // Log error and capture the error message
      debugPrint('Sandbox generation error (may have fallback): $e');
      errorMessage = e.toString();
    }

    if (!mounted) return;

    // Check if we have valid data (even if there was an error)
    final sessionValue = result?['session'];
    final wordsValue = result?['words'];
    Map<String, dynamic>? session = sessionValue is Map ? Map<String, dynamic>.from(sessionValue) : null;
    List<Map<String, dynamic>> words = wordsValue is List
        ? wordsValue.whereType<Map>().map((word) => Map<String, dynamic>.from(word)).toList()
        : <Map<String, dynamic>>[];
    
    debugPrint('After generate: session=${session != null}, words=${words.length}');
    if (words.isNotEmpty) {
      debugPrint('First word data: ${words[0]}');
    }
    
    // Check if backend returned data but with missing/empty cebuanoMeaning
    if (words.isNotEmpty) {
      for (var word in words) {
        final cebuanoMeaning = word['cebuanoMeaning']?.toString() ?? '';
        if (cebuanoMeaning.isEmpty) {
          debugPrint('WARNING: Backend returned empty cebuanoMeaning for word: ${word['englishWord']}');
          debugPrint('Full word data: $word');
        }
      }
    }
    
    setState(() {
      _loading = false;
      _session = session;
      _words = words;
      
      // Only show error if we have no data at all
      if (_session == null || _words.isEmpty) {
        // Check if it's a rate limit error
        if (errorMessage != null && 
            (errorMessage.contains('429') || 
             errorMessage.toLowerCase().contains('rate limit'))) {
          _error = 'Rate limit reached. Please wait a moment and try again.';
        } else {
          _error = 'Could not generate lesson. Please try again.';
        }
      } else {
        _error = null;
      }
    });

    // If we have data, proceed to lesson (even if Gemini failed but fallback worked)
    if (_session != null && _words.isNotEmpty) {
      final sessionId = _session!['sessionId']?.toString() ?? '';
      final lessonId = _session!['lessonId']?.toString() ?? sessionId;

      if (sessionId.isNotEmpty) {
        Navigator.of(context).push(MaterialPageRoute(
          builder: (ctx) => VocabularyIntroductionScreen(
            sessionId: sessionId,
            lessonId: lessonId,
            categoryId: '',
            knownWordIds: <String>[],
            unknownWordIds: <String>[],
            allWords: _words,
            moduleNumber: 1,
            isSandbox: true,
          ),
        ));
      }
    }
  }

  void _speakFirstWord() {
    if (_words.isEmpty) return;
    final word = _words.first['englishWord']?.toString() ?? '';
    if (word.isNotEmpty) {
      TTSService.speak(word);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pref = Provider.of<AuthProvider>(context, listen: false).learner?.languagePreference;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          LocalizationService.translate(pref, 'sandbox_mode'),
          style: const TextStyle(
            fontFamily: 'Outfit',
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: Color(0xFF0F172A),
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Enter one English word to generate a live sandbox lesson.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, color: Color(0xFF475569), fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _customWordController,
                decoration: const InputDecoration(
                  labelText: 'English word',
                  hintText: 'book',
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loading ? null : _generate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF06A6FF),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text(
                        'GENERATE SANDBOX',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 16),
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w600),
                ),
              ],
              if (_session != null) ...[
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Session: ${_session!['sessionId'] ?? ''}',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _session!['customWord']?.toString() ?? 'Sandbox practice',
                        style: const TextStyle(color: Color(0xFF64748B)),
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton(
                        onPressed: _speakFirstWord,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF0F172A),
                          side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.5),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: const Text('Hear generated word'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                ..._words.map(
                  (word) => Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          word['englishWord']?.toString() ?? '',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          word['cebuanoMeaning']?.toString() ?? '',
                          style: const TextStyle(color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
