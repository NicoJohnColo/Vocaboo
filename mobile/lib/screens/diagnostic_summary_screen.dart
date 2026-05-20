import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/localization_service.dart';

class DiagnosticSummaryScreen extends StatelessWidget {
  final String lessonId;
  final List<Map<String, dynamic>> knownWords;
  final List<Map<String, dynamic>> unknownWords;
  final List<Map<String, dynamic>> allWords;

  const DiagnosticSummaryScreen({
    super.key,
    required this.lessonId,
    required this.knownWords,
    required this.unknownWords,
    required this.allWords,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final pref = auth.learner?.languagePreference;
    final state = GoRouterState.of(context);
    final extra = state.extra as Map<String, dynamic>;
    final sessionId = extra['sessionId'] as String;

    final double percentage = allWords.isNotEmpty
        ? (knownWords.length / allWords.length) * 100.0
        : 0.0;

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          LocalizationService.translate(pref, 'diagnostic_summary'),
          style: const TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              // Pie/Progress Summary Card
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: theme.colorScheme.primary.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 80,
                          height: 80,
                          child: CircularProgressIndicator(
                            value: percentage / 100,
                            strokeWidth: 8,
                            backgroundColor: theme.colorScheme.background,
                            valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.tertiary),
                          ),
                        ),
                        Text(
                          '${percentage.toStringAsFixed(0)}%',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
                        ),
                      ],
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            LocalizationService.translate(pref, 'diagnostic_complete'),
                            style: theme.textTheme.titleLarge?.copyWith(fontSize: 18),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            LocalizationService.translate(pref, 'know_ratio', args: ['${knownWords.length}', '${allWords.length}']),
                            style: const TextStyle(color: Color(0xFF94A3B8)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Split lists
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Known column
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.tertiary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              LocalizationService.translate(pref, 'i_know', args: ['${knownWords.length}']),
                              style: TextStyle(
                                color: theme.colorScheme.tertiary,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                                letterSpacing: 0.5,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Expanded(
                            child: knownWords.isEmpty
                                ? const Center(
                                    child: Text(
                                      'None',
                                      style: TextStyle(color: Color(0xFF64748B)),
                                    ),
                                  )
                                : ListView.builder(
                                    itemCount: knownWords.length,
                                    itemBuilder: (context, index) {
                                      return Card(
                                        color: theme.colorScheme.surface,
                                        margin: const EdgeInsets.only(bottom: 8),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                          child: Text(
                                            knownWords[index]['englishWord'],
                                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Unknown column
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              LocalizationService.translate(pref, 'to_learn', args: ['${unknownWords.length}']),
                              style: TextStyle(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                                letterSpacing: 0.5,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Expanded(
                            child: unknownWords.isEmpty
                                ? const Center(
                                    child: Text(
                                      'None',
                                      style: TextStyle(color: Color(0xFF64748B)),
                                    ),
                                  )
                                : ListView.builder(
                                    itemCount: unknownWords.length,
                                    itemBuilder: (context, index) {
                                      return Card(
                                        color: theme.colorScheme.surface,
                                        margin: const EdgeInsets.only(bottom: 8),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                          child: Text(
                                            unknownWords[index]['englishWord'],
                                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: () {
                  final knownIds = knownWords.map((w) => w['wordId'] as String).toList();
                  final unknownIds = unknownWords.map((w) => w['wordId'] as String).toList();

                  context.go(
                    '/session/$sessionId/introduction',
                    extra: {
                      'lessonId': lessonId,
                      'knownWordIds': knownIds,
                      'unknownWordIds': unknownIds,
                      'allWords': allWords,
                    },
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  LocalizationService.translate(pref, 'start_module_1'),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
