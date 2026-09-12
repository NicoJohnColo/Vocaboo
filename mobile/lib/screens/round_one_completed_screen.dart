import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../core/motion/typography_tokens.dart';
import '../providers/auth_provider.dart';
import '../services/localization_service.dart';
import '../widgets/app_3d_button.dart';

class RoundOneCompletedScreen extends StatelessWidget {
  final String sessionId;
  final int introducedCount;
  final int knownCount;
  final String lessonId;
  final String categoryId;
  final List<String> knownWordIds;
  final List<String> unknownWordIds;
  final List<dynamic> allWords;
  final bool isSandbox;

  const RoundOneCompletedScreen({
    super.key,
    required this.sessionId,
    required this.introducedCount,
    required this.knownCount,
    required this.lessonId,
    required this.categoryId,
    required this.knownWordIds,
    required this.unknownWordIds,
    required this.allWords,
    this.isSandbox = false,
  });

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final pref = auth.learner?.languagePreference;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              // Trophy/Mascot Icon
              Center(
                child: Container(
                  width: 130,
                  height: 130,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFFEF3C7), // Light amber
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      )
                    ],
                  ),
                  child: Center(
                    child: Image.asset(
                      'assets/images/thumbsup.png',
                      width: 100,
                      height: 100,
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) => const Icon(
                        Icons.emoji_events_rounded,
                        size: 80,
                        color: Color(0xFFD97706),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 36),
              Text(
                LocalizationService.translate(pref, 'lesson_completed'),
                style: TextStyle(
                  fontFamily: AppTypography.displayFontFamily,
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF06A6FF),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                LocalizationService.translate(pref, 'round_completed_subtitle'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w500,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 36),

              // Statistics Card
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.01),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            LocalizationService.translate(pref, 'introduced'),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF64748B),
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '$introducedCount',
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 1.5,
                      height: 50,
                      color: const Color(0xFFE2E8F0),
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          const Text(
                            'MASTERED',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF64748B),
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '$knownCount / ${allWords.length}',
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF10B981),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (unknownWordIds.isNotEmpty) ...[
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF1F2),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.35), width: 1.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Still needs review',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFFEF4444)),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: unknownWordIds.map((id) {
                          final word = allWords.firstWhere(
                            (w) => (w['wordId'] ?? w['id'] ?? '').toString() == id,
                            orElse: () => {'word': id},
                          );
                          final text = (word['word'] ?? word['englishWord'] ?? id).toString();
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(color: const Color(0xFFEF4444), width: 1.5),
                            ),
                            child: Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFFEF4444))),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ],
              const Spacer(),

              // Primary back action (Dark)
              App3DButton(
                onPressed: () {
                  context.go('/home');
                },
                variant: App3DButtonVariant.dark,
                height: 54,
                depth: 5.0,
                isFullWidth: true,
                text: LocalizationService.translate(pref, 'back_to_path'),
              ),
              const SizedBox(height: 14),
              // Secondary practice action (3D secondary outline)
              App3DButton(
                onPressed: () {
                  context.go(
                    '/session/$sessionId/practice',
                    extra: {
                      'lessonId': lessonId,
                      'categoryId': categoryId,
                      'knownWordIds': knownWordIds,
                      'unknownWordIds': unknownWordIds,
                      'allWords': allWords,
                      'isSandbox': isSandbox,
                    },
                  );
                },
                variant: App3DButtonVariant.secondary,
                height: 50,
                depth: 3.5,
                isFullWidth: true,
                text: LocalizationService.translate(pref, 'practice_more'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
