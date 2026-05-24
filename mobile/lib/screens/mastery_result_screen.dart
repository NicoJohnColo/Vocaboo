// mastery_result_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/lesson_provider.dart';
import 'cumulative_mixed_review_screen.dart';
import '../services/localization_service.dart';
import '../widgets/mascot_visual.dart';

class MasteryResultScreen extends StatelessWidget {
  final String sessionId;
  final String categoryId;
  final bool isSandbox;
  final int totalItems;
  final int masteredCount;
  final List<String>? missedWordIds;
  final List<Map<String, dynamic>> allWords;
  final double? masteryScore;

  const MasteryResultScreen({
    super.key,
    required this.sessionId,
    required this.categoryId,
    required this.isSandbox,
    required this.totalItems,
    required this.masteredCount,
    this.missedWordIds,
    this.allWords = const [],
    this.masteryScore,
  });

  @override
  Widget build(BuildContext context) {
    // Refresh dashboard/progress so unlocked lessons appear immediately.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;
      context.read<LessonProvider>().fetchDashboardProgress();
    });
    final pref = Provider.of<AuthProvider>(context, listen: false).learner?.languagePreference;
    final masteryPercent = masteryScore != null
      ? masteryScore!.round()
      : (totalItems == 0 ? 0 : (masteredCount / totalItems * 100).round());
    final passed = masteryPercent >= 70;
    final missedCount = missedWordIds?.length ?? 0;

    return Scaffold(
      backgroundColor: passed ? const Color(0xFFF7FBF7) : const Color(0xFFFFFBF7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          LocalizationService.translate(pref, 'mastery_result'),
          style: const TextStyle(
            fontFamily: 'Outfit',
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: Color(0xFF0F172A),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: const [SizedBox(width: 12)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: passed
                        ? [const Color(0xFFEFFAF1), const Color(0xFFFFFFFF)]
                        : [const Color(0xFFFFF7ED), const Color(0xFFFFFFFF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: passed ? const Color(0xFFBBF7D0) : const Color(0xFFFED7AA), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: (passed ? const Color(0xFF10B981) : const Color(0xFFF97316)).withValues(alpha: 0.12),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      width: 134,
                      height: 134,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: passed ? const Color(0xFFEFFAF1) : const Color(0xFFFFF7ED),
                      ),
                      child: Center(
                        child: MascotVisual(
                          type: passed ? MascotType.starry : MascotType.sippy,
                          size: 88,
                          isCelebrating: passed,
                          isSad: !passed,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: passed ? const Color(0xFFECFDF5) : const Color(0xFFFFF1F2),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: passed ? const Color(0xFFBBF7D0) : const Color(0xFFFECACA)),
                      ),
                      child: Text(
                        passed ? 'MASTERED' : 'REVIEW AGAIN',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.0,
                          color: passed ? const Color(0xFF059669) : const Color(0xFFEF4444),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              Text(
                passed ? LocalizationService.translate(pref, 'congratulations') : 'Keep practicing',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                passed
                    ? LocalizationService.translate(pref, 'mastery_summary')
                    : 'You are close. The missed words are ready for another round of cumulative review.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 15, color: Color(0xFF64748B), height: 1.5),
              ),
              const SizedBox(height: 22),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFFFFF), Color(0xFFF8FAFC)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildScoreTile('Mastery score', '$masteryPercent%', passed ? const Color(0xFF10B981) : const Color(0xFFEF4444), passed ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildScoreTile('Words mastered', '$masteredCount / $totalItems', const Color(0xFF06A6FF), const Color(0xFFEFF6FF)),
                        ),
                      ],
                    ),
                    if (missedCount > 0) ...[
                      const SizedBox(height: 12),
                      _buildListCard(
                        title: 'Still needs review',
                        color: const Color(0xFFEF4444),
                        background: const Color(0xFFFFF1F2),
                        items: missedWordIds ?? const [],
                      ),
                    ],
                    const SizedBox(height: 12),
                    _buildListCard(
                      title: passed ? 'Words mastered' : 'Words to review',
                      color: passed ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                      background: passed ? const Color(0xFFECFDF5) : const Color(0xFFFFF1F2),
                      items: const [],
                      masteredMode: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              if (!passed)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: const Text(
                    'Module 4 repeats only the words you missed, so the review stays focused and active.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.5),
                  ),
                ),
              const SizedBox(height: 22),
              ElevatedButton(
                onPressed: () async {
                  final lessons = Provider.of<LessonProvider>(context, listen: false);
                  if (passed) {
                    await lessons.fetchDashboardProgress();
                    if (!context.mounted) return;
                    context.go('/category/$categoryId/lessons');
                    return;
                  }

                  Navigator.of(context).pushReplacement(PageRouteBuilder(
                    transitionDuration: const Duration(milliseconds: 350),
                    reverseTransitionDuration: const Duration(milliseconds: 350),
                    pageBuilder: (context, animation, secondaryAnimation) => CumulativeMixedReviewScreen(
                      sessionId: sessionId,
                      allWords: allWords,
                      categoryId: categoryId,
                      isSandbox: isSandbox,
                      priorityWordIds: missedWordIds ?? <String>[],
                    ),
                    transitionsBuilder: (context, animation, secondaryAnimation, child) {
                      final slide = Tween<Offset>(begin: const Offset(0.08, 0), end: Offset.zero).animate(
                        CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
                      );
                      return FadeTransition(
                        opacity: animation,
                        child: SlideTransition(position: slide, child: child),
                      );
                    },
                  ));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: passed ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  elevation: 0,
                ),
                child: Text(
                  passed ? 'GO TO NEXT LESSON' : 'RETRY MODULE 4',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Lesson weighting',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 10),
                    _weightedRow('Module 1-3 completion', '60 pts', const Color(0xFF06A6FF)),
                    const SizedBox(height: 8),
                    _weightedRow('Module 4 cumulative review', '30 pts', const Color(0xFF10B981)),
                    const SizedBox(height: 8),
                    _weightedRow('Passing mark', '70 pts', const Color(0xFFEF4444)),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => context.go('/category/$categoryId/lessons'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF0F172A),
                  side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.5),
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                ),
                child: Text(
                  LocalizationService.translate(pref, 'back_to_dashboard'),
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScoreTile(String label, String value, Color accent, Color background) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent.withValues(alpha: 0.25), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: accent, letterSpacing: 0.7)),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: accent)),
        ],
      ),
    );
  }

  Widget _buildListCard({
    required String title,
    required Color color,
    required Color background,
    required List<String> items,
    bool masteredMode = false,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.35), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: color)),
          const SizedBox(height: 12),
          if (masteredMode && items.isEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _pill('animal', color),
                _pill('bird', color),
                _pill('fish', color),
                _pill('food', color),
              ],
            )
          else if (items.isEmpty)
            Text(
              'No items to review.',
              style: TextStyle(color: color.withValues(alpha: 0.8), fontSize: 13),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: items.map((item) => _pill(item, color)).toList(),
            ),
        ],
      ),
    );
  }

  Widget _pill(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color, width: 1.5),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: color),
      ),
    );
  }

  Widget _weightedRow(String label, String value, Color accent) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF475569))),
        Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: accent)),
      ],
    );
  }
}
