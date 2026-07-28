import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../models/vocabulary_word_model.dart';
import '../providers/lesson_provider.dart';

// ────────────────────────────────────────────────────────────────
// Badge metadata helper
// ────────────────────────────────────────────────────────────────
class _BadgeInfo {
  final String emoji;
  final String label;
  final String subtitle;
  final Color primary;
  final Color background;
  final Color border;

  const _BadgeInfo({
    required this.emoji,
    required this.label,
    required this.subtitle,
    required this.primary,
    required this.background,
    required this.border,
  });
}

_BadgeInfo _getBadgeInfo(String? badge) {
  switch (badge) {
    case 'PERFECT_GOLD':
      return const _BadgeInfo(
        emoji: '🏆',
        label: 'Perfect Gold',
        subtitle: 'Flawless — all words mastered with zero errors!',
        primary: Color(0xFFCA8A04),
        background: Color(0xFFFEF9C3),
        border: Color(0xFFFDE047),
      );
    case 'GOLD':
      return const _BadgeInfo(
        emoji: '🥇',
        label: 'Gold',
        subtitle: 'Excellent — at most 2 mistakes across all words.',
        primary: Color(0xFFD97706),
        background: Color(0xFFFFFBEB),
        border: Color(0xFFFCD34D),
      );
    case 'SILVER':
      return const _BadgeInfo(
        emoji: '🥈',
        label: 'Silver',
        subtitle: 'Good job — keep practising to reach Gold!',
        primary: Color(0xFF475569),
        background: Color(0xFFF1F5F9),
        border: Color(0xFFCBD5E1),
      );
    default: // BRONZE
      return const _BadgeInfo(
        emoji: '🥉',
        label: 'Bronze',
        subtitle: 'You completed the lesson — keep going!',
        primary: Color(0xFF92400E),
        background: Color(0xFFFFF7ED),
        border: Color(0xFFFED7AA),
      );
  }
}

// ────────────────────────────────────────────────────────────────
// Screen
// ────────────────────────────────────────────────────────────────
class LessonScoreScreen extends StatefulWidget {
  final String sessionId;
  final String lessonId;
  final String categoryId;
  final String lessonTitle;
  final List<VocabularyWordModel> allWords;
  final Map<String, bool> wordPronunciationCorrect;
  final Map<String, int> wordPronunciationAttempts;
  final Set<String> failedSentenceWordIds;
  final double overallScore;
  final bool isSandbox;
  final int? masteredCount;
  final List<String>? needsReviewWords;
  final bool isPerfectFirstAttempt;

  const LessonScoreScreen({
    super.key,
    required this.sessionId,
    required this.lessonId,
    required this.categoryId,
    required this.lessonTitle,
    required this.allWords,
    required this.wordPronunciationCorrect,
    required this.wordPronunciationAttempts,
    required this.failedSentenceWordIds,
    required this.overallScore,
    this.isSandbox = false,
    this.masteredCount,
    this.needsReviewWords,
    this.isPerfectFirstAttempt = false,
  });

  @override
  State<LessonScoreScreen> createState() => _LessonScoreScreenState();
}

class _LessonScoreScreenState extends State<LessonScoreScreen>
    with TickerProviderStateMixin {
  String? _badgeType;
  bool _badgeLoading = true;

  late final AnimationController _badgeScale;
  late final Animation<double> _scaleAnim;
  late final AnimationController _badgeFade;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();

    _badgeScale = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scaleAnim = CurvedAnimation(parent: _badgeScale, curve: Curves.elasticOut);

    _badgeFade = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _fadeAnim = CurvedAnimation(parent: _badgeFade, curve: Curves.easeIn);

    if (!widget.isSandbox) {
      _fetchBadge();
    } else {
      setState(() => _badgeLoading = false);
    }
  }

  Future<void> _fetchBadge() async {
    final provider = Provider.of<LessonProvider>(context, listen: false);
    final result = await provider.completeMasterySession(
      widget.sessionId,
      widget.lessonId,
      score: widget.overallScore,
      isPerfectFirstAttempt: widget.isPerfectFirstAttempt,
    );
    if (mounted) {
      setState(() {
        _badgeType = result?['badgeType'] as String? ?? 'BRONZE';
        _badgeLoading = false;
      });
      _badgeFade.forward();
      await Future.delayed(const Duration(milliseconds: 80));
      _badgeScale.forward();
    }
  }

  @override
  void dispose() {
    _badgeScale.dispose();
    _badgeFade.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final effectiveMastered = widget.masteredCount ??
        widget.allWords
            .where((w) => !widget.failedSentenceWordIds.contains(w.wordId))
            .length;

    final effectiveNeedsReview = widget.needsReviewWords ??
        widget.allWords
            .where((w) => widget.failedSentenceWordIds.contains(w.wordId))
            .map((w) => w.englishWord)
            .toList();

    final totalWords = widget.allWords.length;
    final allMastered = effectiveMastered >= totalWords;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Lesson Complete',
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: Color(0xFF0F172A),
          ),
        ),
        centerTitle: false,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Hero icon
                    Center(
                      child: Container(
                        width: 132,
                        height: 132,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: allMastered
                              ? const Color(0xFFECFDF5)
                              : const Color(0xFFEFF6FF),
                          boxShadow: [
                            BoxShadow(
                              color: (allMastered
                                      ? const Color(0xFF10B981)
                                      : const Color(0xFF06A6FF))
                                  .withValues(alpha: 0.12),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            allMastered ? '🌟' : '📘',
                            style: const TextStyle(fontSize: 72),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    Text(
                      widget.lessonTitle,
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
                      allMastered
                          ? 'Great work! You have mastered all words in this lesson.'
                          : 'You have completed all modules. Keep practising the words below.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 15,
                        color: Color(0xFF64748B),
                        height: 1.5,
                      ),
                    ),
                    if (allMastered) ...[
                      const SizedBox(height: 12),
                      Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFFDE68A)),
                          ),
                          child: const Text(
                            '+50 bonus',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFFB45309),
                              fontFamily: 'Outfit',
                            ),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 28),

                    // ── Mastery Badge Card ──────────────────────────────────
                    if (!widget.isSandbox) ...[
                      if (_badgeLoading)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 20),
                            child: CircularProgressIndicator(strokeWidth: 2.5),
                          ),
                        )
                      else
                        FadeTransition(
                          opacity: _fadeAnim,
                          child: ScaleTransition(
                            scale: _scaleAnim,
                            child: _BadgeCard(badgeType: _badgeType),
                          ),
                        ),
                      const SizedBox(height: 20),
                    ],

                    // ── Mastery Count Card ──────────────────────────────────
                    Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 22, horizontal: 20),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                            color: const Color(0xFFE2E8F0), width: 1.5),
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
                          Text(
                            'Words Mastered',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Colors.grey[600],
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 10),
                          RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: '$effectiveMastered',
                                  style: TextStyle(
                                    fontSize: 48,
                                    fontWeight: FontWeight.w900,
                                    color: allMastered
                                        ? const Color(0xFF10B981)
                                        : const Color(0xFF06A6FF),
                                  ),
                                ),
                                TextSpan(
                                  text: ' / $totalWords',
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF94A3B8),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── Words Needing Review ────────────────────────────────
                    if (effectiveNeedsReview.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF1F2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: const Color(0xFFFECACA), width: 1.5),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: const [
                                Icon(Icons.refresh_rounded,
                                    color: Color(0xFFEF4444), size: 18),
                                SizedBox(width: 8),
                                Text(
                                  'Still Needs Practice',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFFEF4444),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: effectiveNeedsReview
                                  .map((word) => Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 7),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius:
                                              BorderRadius.circular(999),
                                          border: Border.all(
                                              color: const Color(0xFFEF4444),
                                              width: 1.5),
                                        ),
                                        child: Text(
                                          word,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFFEF4444),
                                          ),
                                        ),
                                      ))
                                  .toList(),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // ── Per-Word Breakdown ──────────────────────────────────
                    const Text(
                      'Word Breakdown',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 12),

                    ...widget.allWords.asMap().entries.map((entry) {
                      final word = entry.value;
                      final failedSentence =
                          widget.failedSentenceWordIds.contains(word.wordId);
                      final attempts =
                          widget.wordPronunciationAttempts[word.wordId] ?? 0;

                      final mastered = !failedSentence;
                      final statusLabel =
                          mastered ? 'Mastered' : 'Needs Review';
                      final statusColor = mastered
                          ? const Color(0xFF10B981)
                          : const Color(0xFFEF4444);
                      final statusBgColor = mastered
                          ? const Color(0xFFECFDF5)
                          : const Color(0xFFFEF2F2);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: const Color(0xFFE2E8F0), width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.02),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: statusBgColor,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                mastered
                                    ? Icons.check_rounded
                                    : Icons.refresh_rounded,
                                color: statusColor,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    word.englishWord,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    word.cebuanoMeaning,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF64748B),
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                  if (!widget.isSandbox && attempts > 0) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      'Pronunciation: $attempts attempt${attempts == 1 ? '' : 's'}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF94A3B8),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            if (!widget.isSandbox)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: statusBgColor,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                      color: statusColor, width: 1),
                                ),
                                child: Text(
                                  statusLabel,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: statusColor,
                                    letterSpacing: 0.4,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    }),

                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),

            // Footer Action Bar
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: Colors.grey.withValues(alpha: 0.1)),
                ),
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (widget.isSandbox || widget.categoryId.isEmpty) {
                      context.go('/home');
                      return;
                    }
                    final lessonProvider =
                        Provider.of<LessonProvider>(context, listen: false);
                    String categoryName = 'Lessons';
                    try {
                      final category = lessonProvider.categories
                          .firstWhere((c) => c.categoryId == widget.categoryId);
                      categoryName = category.categoryName;
                    } catch (_) {}
                    context.go(
                      '/category/${widget.categoryId}/lessons?name=${Uri.encodeComponent(categoryName)}',
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: const Text(
                    'DONE',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────
// Badge Card Widget
// ────────────────────────────────────────────────────────────────
class _BadgeCard extends StatelessWidget {
  final String? badgeType;
  const _BadgeCard({required this.badgeType});

  @override
  Widget build(BuildContext context) {
    final info = _getBadgeInfo(badgeType);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
      decoration: BoxDecoration(
        color: info.background,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: info.border, width: 2),
        boxShadow: [
          BoxShadow(
            color: info.primary.withValues(alpha: 0.12),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Text(info.emoji, style: const TextStyle(fontSize: 48)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Lesson Badge',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: info.primary.withValues(alpha: 0.7),
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  info.label,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: info.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  info.subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: info.primary.withValues(alpha: 0.75),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
