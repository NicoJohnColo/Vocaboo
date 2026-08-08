import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/lesson_provider.dart';
import '../services/localization_service.dart';

class DiagnosticSummaryScreen extends StatelessWidget {
  final String lessonId;
  final String categoryId;
  final List<Map<String, dynamic>> knownWords;
  final List<Map<String, dynamic>> unknownWords;
  final List<Map<String, dynamic>> allWords;

  const DiagnosticSummaryScreen({
    super.key,
    required this.lessonId,
    required this.categoryId,
    required this.knownWords,
    required this.unknownWords,
    required this.allWords,
  });

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final pref = auth.learner?.languagePreference;
    final state = GoRouterState.of(context);
    final extra = state.extra as Map<String, dynamic>;
    final sessionId = extra['sessionId'] as String;

    final double percentage = allWords.isNotEmpty
        ? (knownWords.length / allWords.length) * 100.0
        : 0.0;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          LocalizationService.translate(pref, 'diagnostic_summary'),
          style: const TextStyle(
            fontFamily: 'Outfit',
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              // Progress Summary Card
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
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
                            backgroundColor: const Color(0xFFE2E8F0),
                            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
                          ),
                        ),
                        Text(
                          '${percentage.toStringAsFixed(0)}%',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Color(0xFF0F172A),
                          ),
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
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            LocalizationService.translate(pref, 'know_ratio', args: ['${knownWords.length}', '${allWords.length}']),
                            style: const TextStyle(color: Color(0xFF64748B)),
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
                              color: const Color(0xFF10B981).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              LocalizationService.translate(pref, 'i_know', args: ['${knownWords.length}']),
                              style: const TextStyle(
                                color: Color(0xFF10B981),
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
                                      return Container(
                                        margin: const EdgeInsets.only(bottom: 8),
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF8FAFC),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: const Color(0xFFE2E8F0)),
                                        ),
                                        child: Text(
                                          knownWords[index]['englishWord'],
                                          style: const TextStyle(
                                            color: Color(0xFF0F172A),
                                            fontWeight: FontWeight.w600,
                                          ),
                                          textAlign: TextAlign.center,
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
                              color: const Color(0xFF0EA5E9).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              LocalizationService.translate(pref, 'to_learn', args: ['${unknownWords.length}']),
                              style: const TextStyle(
                                color: Color(0xFF0EA5E9),
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
                                      return Container(
                                        margin: const EdgeInsets.only(bottom: 8),
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF8FAFC),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: const Color(0xFFE2E8F0)),
                                        ),
                                        child: Text(
                                          unknownWords[index]['englishWord'],
                                          style: const TextStyle(
                                            color: Color(0xFF0F172A),
                                            fontWeight: FontWeight.w600,
                                          ),
                                          textAlign: TextAlign.center,
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
                onPressed: () async {
                  final auth = Provider.of<AuthProvider>(context, listen: false);
                  final lessonProvider = Provider.of<LessonProvider>(context, listen: false);
                  final posFocus = auth.learner?.posFocus;
                  final filter = (posFocus != null && posFocus != 'ALL') ? posFocus : null;
                  
                  final activityData = categoryId.isNotEmpty
                      ? await lessonProvider.loadCategoryActivity(categoryId)
                      : await lessonProvider.loadLessonActivity(lessonId, partOfSpeech: filter);
                  final activityByWordId = {
                    for (final item in activityData)
                      if ((item['wordId'] ?? '').toString().isNotEmpty) item['wordId'].toString(): item,
                  };

                  final enrichedAllWords = allWords.map((word) {
                    final wordId = (word['wordId'] ?? '').toString();
                    final activity = activityByWordId[wordId];
                    if (activity == null) {
                      return word;
                    }
                    return <String, dynamic>{
                      ...word,
                      ...activity,
                    };
                  }).toList();

                  if (!context.mounted) {
                    return;
                  }

                  final knownIds = knownWords.map((w) => w['wordId'] as String).toList();
                  final unknownIds = unknownWords.map((w) => w['wordId'] as String).toList();

                  context.go(
                    '/session/$sessionId/introduction',
                    extra: {
                      'lessonId': lessonId,
                      'categoryId': categoryId,
                      'knownWordIds': knownIds,
                      'unknownWordIds': unknownIds,
                      'allWords': enrichedAllWords,
                      'isSandbox': false,
                    },
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F172A),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
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
