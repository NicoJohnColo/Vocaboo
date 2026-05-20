import 'package:flutter/material';
import 'package:go_router/go_router.dart';
import 'package:provider/provider';
import '../providers/auth_provider.dart';
import '../providers/lesson_provider.dart';
import '../models/vocabulary_word_model.dart';
import '../services/localization_service.dart';

class DiagnosticCheckScreen extends StatefulWidget {
  final String lessonId;

  const DiagnosticCheckScreen({super.key, required this.lessonId});

  @override
  State<DiagnosticCheckScreen> createState() => _DiagnosticCheckScreenState();
}

class _DiagnosticCheckScreenState extends State<DiagnosticCheckScreen> {
  List<VocabularyWordModel> _localWords = [];
  int _currentIndex = 0;
  final Map<String, bool> _answers = {};
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final words = await Provider.of<LessonProvider>(context, listen: false).loadVocabulary(widget.lessonId);
      setState(() {
        _localWords = words;
      });
    });
  }

  void _answerCurrent(bool isKnown) async {
    final word = _localWords[_currentIndex];
    _answers[word.wordId] = isKnown;

    if (_currentIndex < _localWords.length - 1) {
      setState(() {
        _currentIndex++;
      });
    } else {
      // Complete diagnostic check, submit responses
      setState(() {
        _submitting = true;
      });

      final provider = Provider.of<LessonProvider>(context, listen: false);
      final result = await provider.submitDiagnostic(widget.lessonId, _answers);

      if (result != null && mounted) {
        // Build known and unknown lists
        final List<Map<String, dynamic>> known = [];
        final List<Map<String, dynamic>> unknown = [];
        final List<Map<String, dynamic>> all = [];

        for (var w in _localWords) {
          final isKnownWord = _answers[w.wordId] ?? false;
          final wordMap = w.toJson();
          if (isKnownWord) {
            known.add(wordMap);
          } else {
            unknown.add(wordMap);
          }
          all.add(wordMap);
        }

        context.go(
          '/lesson/${widget.lessonId}/diagnostic-summary',
          extra: {
            'knownWords': known,
            'unknownWords': unknown,
            'allWords': all,
            'sessionId': result.sessionId,
          },
        );
      } else {
        setState(() {
          _submitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = Provider.of<LessonProvider>(context);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final pref = auth.learner?.languagePreference;

    if (provider.isLoading && _localWords.isEmpty) {
      return Scaffold(
        backgroundColor: theme.colorScheme.background,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_localWords.isEmpty) {
      return Scaffold(
        backgroundColor: theme.colorScheme.background,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: const Center(
          child: Text('No words loaded. Make sure the backend is seeded.'),
        ),
      );
    }

    if (_submitting) {
      return Scaffold(
        backgroundColor: theme.colorScheme.background,
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 24),
              Text(
                LocalizationService.translate(pref, 'saving_results'),
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    final currentWord = _localWords[_currentIndex];
    final progress = (_currentIndex + 1) / _localWords.length;

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Text(
          LocalizationService.translate(pref, 'diagnostic_check'),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Progress Bar
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: theme.colorScheme.surface,
                  valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                LocalizationService.translate(pref, 'card_indicator', args: ['${_currentIndex + 1}', '${_localWords.length}']),
                style: const TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
                textAlign: TextAlign.center,
              ),
              const Spacer(),

              // Word Card
              Container(
                height: 240,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: theme.colorScheme.primary.withOpacity(0.1)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    )
                  ],
                ),
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        currentWord.englishWord,
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        LocalizationService.translate(pref, 'know_word_prompt'),
                        style: TextStyle(
                          fontSize: 16,
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),

              // Buttons
              ElevatedButton(
                onPressed: () => _answerCurrent(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 2,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle_outline, size: 22),
                    SizedBox(width: 12),
                    Text(
                      LocalizationService.translate(pref, 'yes_know'),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () => _answerCurrent(false),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: BorderSide(color: theme.colorScheme.primary.withOpacity(0.5)),
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.help_outline_rounded, size: 22, color: Color(0xFFF59E0B)),
                    SizedBox(width: 12),
                    Text(
                      LocalizationService.translate(pref, 'no_dont_know'),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
