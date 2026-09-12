import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../models/vocabulary_word_model.dart';
import '../providers/auth_provider.dart';
import '../providers/lesson_provider.dart';
import '../services/local_storage_service.dart';
import '../services/localization_service.dart';
import '../core/motion/motion.dart';

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
// Word rating chip helper
// ────────────────────────────────────────────────────────────────
_WordRatingStyle _getWordRatingStyle(String? rating) {
  switch (rating) {
    case 'GOLD':
      return const _WordRatingStyle(
        '🥇',
        'Gold',
        Color(0xFFD97706),
        Color(0xFFFFFBEB),
        Color(0xFFFCD34D),
      );
    case 'SILVER':
      return const _WordRatingStyle(
        '🥈',
        'Silver',
        Color(0xFF475569),
        Color(0xFFF1F5F9),
        Color(0xFFCBD5E1),
      );
    case 'BRONZE':
      return const _WordRatingStyle(
        '🥉',
        'Bronze',
        Color(0xFF92400E),
        Color(0xFFFFF7ED),
        Color(0xFFFED7AA),
      );
    default:
      return const _WordRatingStyle(
        '',
        '',
        Colors.transparent,
        Colors.transparent,
        Colors.transparent,
      );
  }
}

class _WordRatingStyle {
  final String emoji;
  final String label;
  final Color primary;
  final Color background;
  final Color border;
  const _WordRatingStyle(
    this.emoji,
    this.label,
    this.primary,
    this.background,
    this.border,
  );
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
  final String? classroomId;
  final String? className;

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
    this.classroomId,
    this.className,
  });

  @override
  State<LessonScoreScreen> createState() => _LessonScoreScreenState();
}

class _LessonScoreScreenState extends State<LessonScoreScreen>
    with TickerProviderStateMixin {
  String? _badgeType;
  double _calculatedScore = 0.0;
  bool _badgeLoading = true;
  List<Map<String, dynamic>> _wordSummary = [];
  bool _wordSummaryLoading = true;

  late final AnimationController _badgeScale;
  late final Animation<double> _scaleAnim;
  late final AnimationController _badgeFade;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _calculatedScore = widget.overallScore;

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
      _initializeData();
    } else {
      final accurateScore = widget.overallScore > 0
          ? widget.overallScore
          : 100.0;
      final provider = Provider.of<LessonProvider>(context, listen: false);
      final totalWordsCount = widget.allWords.length;
      final int masteredWordsCount =
          (widget.overallScore >= 70.0 || widget.isPerfectFirstAttempt)
          ? totalWordsCount
          : (totalWordsCount > 0 ? (totalWordsCount * 0.7).round() : 1);

      LocalStorageService.updateSandboxSessionMastery(
        widget.sessionId,
        lessonId: widget.lessonId,
        masteredCount: masteredWordsCount,
        totalCount: totalWordsCount,
        isCompleted: true,
      );
      provider
          .completeSandbox(widget.sessionId, finalScore: accurateScore)
          .catchError((_) => null);

      setState(() {
        _badgeLoading = false;
        _wordSummaryLoading = false;
        _calculatedScore = accurateScore;
      });
      _badgeScale.forward();
      _badgeFade.forward();
    }
  }

  Future<void> _initializeData() async {
    await _fetchWordSummary();
    final wordAccuracies = _wordSummary
        .map((item) => (item['accuracy'] as num?)?.toDouble())
        .whereType<double>()
        .toList();
    final double newCumulativeAccuracy = wordAccuracies.isNotEmpty
        ? ((wordAccuracies.reduce((a, b) => a + b) / wordAccuracies.length))
              .clamp(0.0, 100.0)
        : 0.0;

    final double accurateScore = newCumulativeAccuracy > 0
        ? newCumulativeAccuracy
        : widget.overallScore;

    debugPrint(
      'LessonScoreScreen: newCumulative=$newCumulativeAccuracy => accurateScore=$accurateScore',
    );
    if (mounted) {
      setState(() {
        _calculatedScore = accurateScore;
        _wordSummaryLoading = false;
      });
    }
    if (!widget.isSandbox && accurateScore > 0) {
      await LocalStorageService.saveLessonScore(
        widget.lessonId,
        accurateScore,
        force: false,
      );
    }
    await _fetchBadge(score: accurateScore);
  }

  Future<void> _fetchBadge({required double score}) async {
    final provider = Provider.of<LessonProvider>(context, listen: false);
    final result = await provider.completeMasterySession(
      widget.sessionId,
      widget.lessonId,
      score: score,
      isPerfectFirstAttempt: widget.isPerfectFirstAttempt,
    );
    provider.fetchDashboardProgress().catchError((_) => null);
    provider.loadCategories().catchError((_) => null);
    if (mounted) {
      final backendBadge = result?['badgeType'] as String?;
      final fallbackBadge = score >= 90.0
          ? 'GOLD'
          : (score >= 75.0 ? 'SILVER' : 'BRONZE');
      setState(() {
        _badgeType = backendBadge ?? fallbackBadge;
        _badgeLoading = false;
      });
      _badgeFade.forward();
      await Future.delayed(const Duration(milliseconds: 80));
      _badgeScale.forward();
    }
  }

  Future<void> _fetchWordSummary() async {
    final provider = Provider.of<LessonProvider>(context, listen: false);
    final summary = await provider.fetchWordMasterySummary(
      widget.lessonId,
      sessionId: widget.sessionId,
    );
    if (mounted) {
      setState(() {
        _wordSummary = summary;
      });
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
    final auth = Provider.of<AuthProvider>(context);
    final pref = auth.learner?.languagePreference;
    final effectiveMastered =
        widget.masteredCount ??
        widget.allWords
            .where((w) => !widget.failedSentenceWordIds.contains(w.wordId))
            .length;

    final effectiveNeedsReview =
        widget.needsReviewWords ??
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
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: Text(
          LocalizationService.translate(pref, 'lesson_completed'),
          style: AppTypography.baloo2(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF06A6FF),
          ),
        ),
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
                    // Hero mascot image
                    Center(
                      child: Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: allMastered
                              ? const Color(0xFFECFDF5)
                              : const Color(0xFFEFF6FF),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  (allMastered
                                          ? const Color(0xFF10B981)
                                          : const Color(0xFF06A6FF))
                                      .withValues(alpha: 0.15),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Image.asset(
                            allMastered
                                ? 'assets/images/scoremascot.png'
                                : 'assets/images/thumbsup.png',
                            width: 110,
                            height: 110,
                            fit: BoxFit.contain,
                            errorBuilder: (_, _, _) => Text(
                              allMastered ? '🌟' : '📘',
                              style: const TextStyle(fontSize: 72),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    Text(
                      widget.lessonTitle,
                      textAlign: TextAlign.center,
                      style: AppTypography.baloo2(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      allMastered
                          ? LocalizationService.translate(
                              pref,
                              'all_words_mastered_msg',
                            )
                          : LocalizationService.translate(
                              pref,
                              'keep_practising_msg',
                            ),
                      textAlign: TextAlign.center,
                      style: AppTypography.nunito(
                        fontSize: 15,
                        color: const Color(0xFF64748B),
                        height: 1.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (allMastered) ...[
                      const SizedBox(height: 12),
                      Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFFDE68A)),
                          ),
                          child: Text(
                            '+50 ${LocalizationService.translate(pref, 'bonus')}',
                            style: AppTypography.baloo2(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFFB45309),
                            ),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 28),

                    // ── Mastery Badge & Accuracy Cards ─────────────────────
                    if (!widget.isSandbox &&
                        (_badgeLoading || _wordSummaryLoading)) ...[
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 40),
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ] else ...[
                      if (!widget.isSandbox) ...[
                        AppRewardBadgeReveal(
                          tier: _badgeType != null
                              ? badgeTierFromString(_badgeType)
                              : badgeTierFromScore(
                                  _calculatedScore > 0
                                      ? _calculatedScore
                                      : widget.overallScore,
                                ),
                          subtitle:
                              'Overall Lesson Score: ${(_calculatedScore > 0 ? _calculatedScore : widget.overallScore).toStringAsFixed(0)}%',
                        ),
                        const SizedBox(height: 20),
                      ],

                      // ── Dual XP Reward Banner (Blue Header) ─────────────────
                      _buildDualXpRewardBanner(
                        context,
                        widget.classroomId,
                        widget.className,
                        pref,
                      ),
                      const SizedBox(height: 20),

                      // ── Mastery Count Card ──────────────────────────────────
                      Builder(
                        builder: (context) {
                          // Count mastered based on lesson-specific accuracy (70%+ = Silver/Gold = completed)
                          // Instead of lifetime tierState which shows MASTERED only after long-term mastery
                          final backendMastered = _wordSummary.isEmpty
                              ? null
                              : _wordSummary.where((w) {
                                  final accuracy =
                                      (w['accuracy'] as num?)?.toDouble() ??
                                      0.0;
                                  // Count words with 70%+ accuracy as "mastered" for this lesson
                                  return accuracy >= 70.0;
                                }).length;
                          final effectiveMastered =
                              backendMastered ??
                              widget.masteredCount ??
                              widget.allWords
                                  .where(
                                    (w) => !widget.failedSentenceWordIds
                                        .contains(w.wordId),
                                  )
                                  .length;
                          final totalWords = _wordSummary.isNotEmpty
                              ? _wordSummary.length
                              : widget.allWords.length;
                          final allMastered = effectiveMastered >= totalWords;

                          return Row(
                            children: [
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 22,
                                    horizontal: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(24),
                                    border: Border.all(
                                      color: const Color(0xFFE2E8F0),
                                      width: 1.5,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: 0.04,
                                        ),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    children: [
                                      Text(
                                        LocalizationService.translate(
                                          pref,
                                          'words_mastered',
                                        ),
                                        style: AppTypography.nunito(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: const Color(0xFF64748B),
                                          letterSpacing: 0.5,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 10),
                                      RichText(
                                        text: TextSpan(
                                          children: [
                                            TextSpan(
                                              text: '$effectiveMastered',
                                              style: AppTypography.baloo2(
                                                fontSize: 40,
                                                fontWeight: FontWeight.w800,
                                                color: allMastered
                                                    ? const Color(0xFF10B981)
                                                    : const Color(0xFF06A6FF),
                                              ),
                                            ),
                                            TextSpan(
                                              text: ' / $totalWords',
                                              style: AppTypography.nunito(
                                                fontSize: 18,
                                                fontWeight: FontWeight.w700,
                                                color: const Color(0xFF94A3B8),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 22,
                                    horizontal: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(24),
                                    border: Border.all(
                                      color: const Color(0xFFE2E8F0),
                                      width: 1.5,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: 0.04,
                                        ),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    children: [
                                      Text(
                                        LocalizationService.translate(
                                          pref,
                                          'accuracy',
                                        ),
                                        style: AppTypography.nunito(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: const Color(0xFF64748B),
                                          letterSpacing: 0.5,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 10),
                                      Builder(
                                        builder: (context) {
                                          final int totalLessonAttempts =
                                              _wordSummary.fold<int>(
                                                0,
                                                (sum, w) =>
                                                    sum +
                                                    ((w['totalAttempts']
                                                                as num?)
                                                            ?.toInt() ??
                                                        0),
                                              );
                                          final int totalLessonCorrect =
                                              _wordSummary.fold<int>(
                                                0,
                                                (sum, w) =>
                                                    sum +
                                                    ((w['correctAttempts']
                                                                as num?)
                                                            ?.toInt() ??
                                                        (w['correctCount']
                                                                as num?)
                                                            ?.toInt() ??
                                                        0),
                                              );
                                          final wordAccuracies = _wordSummary
                                              .map(
                                                (item) =>
                                                    (item['accuracy'] as num?)
                                                        ?.toDouble(),
                                              )
                                              .whereType<double>()
                                              .toList();
                                          final double summaryAvg =
                                              wordAccuracies.isNotEmpty
                                              ? (wordAccuracies.reduce(
                                                      (a, b) => a + b,
                                                    ) /
                                                    wordAccuracies.length)
                                              : 0.0;
                                          final double displayAccuracy =
                                              _calculatedScore > 0
                                              ? _calculatedScore
                                              : (summaryAvg > 0
                                                    ? summaryAvg
                                                    : (totalLessonAttempts > 0
                                                          ? ((totalLessonCorrect /
                                                                        totalLessonAttempts) *
                                                                    100.0)
                                                                .clamp(
                                                                  0.0,
                                                                  100.0,
                                                                )
                                                          : (widget.overallScore >
                                                                    0
                                                                ? widget
                                                                      .overallScore
                                                                : 0.0)));

                                          return Text(
                                            '${displayAccuracy.toStringAsFixed(0)}%',
                                            style: AppTypography.baloo2(
                                              fontSize: 40,
                                              color: displayAccuracy >= 80
                                                  ? const Color(0xFF10B981)
                                                  : (displayAccuracy >= 50
                                                        ? const Color(
                                                            0xFFF59E0B,
                                                          )
                                                        : const Color(
                                                            0xFFEF4444,
                                                          )),
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                    ],

                    // ── Words Needing Review ────────────────────────────────
                    if (effectiveNeedsReview.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF1F2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(0xFFFECACA),
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.refresh_rounded,
                                  color: Color(0xFFEF4444),
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  LocalizationService.translate(
                                    pref,
                                    'still_needs_practice',
                                  ),
                                  style: const TextStyle(
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
                                  .map(
                                    (word) => Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 7,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(
                                          999,
                                        ),
                                        border: Border.all(
                                          color: const Color(0xFFEF4444),
                                          width: 1.5,
                                        ),
                                      ),
                                      child: Text(
                                        word,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFFEF4444),
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // ── Per-Word Breakdown ──────────────────────────────────
                    Text(
                      LocalizationService.translate(pref, 'word_breakdown'),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 12),

                    if (_wordSummaryLoading)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        ),
                      )
                    else if (_wordSummary.isNotEmpty)
                      ..._wordSummary.map((wordData) {
                        final tierState =
                            wordData['tierState'] as String? ?? 'LEARNING';
                        final wordRating = wordData['wordRating'] as String?;
                        final englishWord =
                            wordData['englishWord'] as String? ?? '';
                        final cebuanoMeaning =
                            wordData['cebuanoMeaning'] as String? ?? '';
                        final isMastered = tierState == 'MASTERED';
                        final rating = _getWordRatingStyle(wordRating);
                        final double wordAccuracy =
                            (wordData['accuracy'] as num?)?.toDouble() ?? 0.0;
                        final int correctAttempts =
                            (wordData['correctAttempts'] as num?)?.toInt() ?? 0;
                        final int totalAttempts =
                            (wordData['totalAttempts'] as num?)?.toInt() ?? 0;
                        final bool isRetaken =
                            wordData['isRetaken'] as bool? ?? false;
                        final bool isImproved =
                            wordData['isImproved'] as bool? ?? false;
                        final double? previousAccuracy =
                            (wordData['previousAccuracy'] as num?)?.toDouble();
                        final double? bestAccuracy =
                            (wordData['bestAccuracy'] as num?)?.toDouble();

                        Color borderColor;
                        Color cardBg;
                        if (isRetaken) {
                          if (isImproved) {
                            borderColor = const Color(0xFF10B981);
                            cardBg = const Color(0xFFF0FDF4);
                          } else {
                            borderColor = const Color(0xFF06A6FF);
                            cardBg = const Color(0xFFF0F9FF);
                          }
                        } else if (isMastered) {
                          borderColor = const Color(
                            0xFF10B981,
                          ).withValues(alpha: 0.35);
                          cardBg = Colors.white;
                        } else {
                          borderColor = const Color(0xFFE2E8F0);
                          cardBg = Colors.white;
                        }

                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: cardBg,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: borderColor,
                              width: isRetaken ? 2.0 : 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: isRetaken && isImproved
                                    ? const Color(
                                        0xFF10B981,
                                      ).withValues(alpha: 0.08)
                                    : Colors.black.withValues(alpha: 0.02),
                                blurRadius: isRetaken ? 6 : 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              // Status icon circle
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: isRetaken
                                      ? (isImproved
                                            ? const Color(0xFFDCFCE7)
                                            : const Color(0xFFE0F2FE))
                                      : (isMastered
                                            ? const Color(0xFFECFDF5)
                                            : const Color(0xFFF1F5F9)),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  isRetaken
                                      ? (isImproved
                                            ? Icons.trending_up_rounded
                                            : Icons.replay_rounded)
                                      : (isMastered
                                            ? Icons.check_rounded
                                            : Icons.school_rounded),
                                  color: isRetaken
                                      ? (isImproved
                                            ? const Color(0xFF16A34A)
                                            : const Color(0xFF0284C7))
                                      : (isMastered
                                            ? const Color(0xFF10B981)
                                            : const Color(0xFF94A3B8)),
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Wrap(
                                      crossAxisAlignment:
                                          WrapCrossAlignment.center,
                                      spacing: 6,
                                      runSpacing: 4,
                                      children: [
                                        Text(
                                          englishWord,
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF0F172A),
                                          ),
                                        ),
                                        if (isRetaken && isImproved)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFDCFCE7),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                              border: Border.all(
                                                color: const Color(0xFF86EFAC),
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Text(
                                                  '📈 ',
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                  ),
                                                ),
                                                Text(
                                                  previousAccuracy != null
                                                      ? '+${(wordAccuracy - previousAccuracy).round()}% Improved'
                                                      : 'New High!',
                                                  style: const TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w800,
                                                    color: Color(0xFF15803D),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          )
                                        else if (isRetaken)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFE0F2FE),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                              border: Border.all(
                                                color: const Color(0xFFBAE6FD),
                                              ),
                                            ),
                                            child: const Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  '🔄 ',
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                  ),
                                                ),
                                                Text(
                                                  'Retaken',
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w800,
                                                    color: Color(0xFF0284C7),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      cebuanoMeaning,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF64748B),
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    if (bestAccuracy != null &&
                                        bestAccuracy > wordAccuracy) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        'Best: ${bestAccuracy.round()}%',
                                        style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF64748B),
                                        ),
                                      ),
                                    ],
                                    if (totalAttempts > 0) ...[
                                      Row(
                                        children: [
                                          Icon(
                                            correctAttempts == totalAttempts
                                                ? Icons
                                                      .check_circle_outline_rounded
                                                : Icons.info_outline_rounded,
                                            size: 13,
                                            color:
                                                correctAttempts == totalAttempts
                                                ? const Color(0xFF10B981)
                                                : const Color(0xFF94A3B8),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            '$correctAttempts/$totalAttempts correct${totalAttempts > correctAttempts ? ' • ${totalAttempts - correctAttempts} error${totalAttempts - correctAttempts > 1 ? "s" : ""} this session' : ' • 0 errors this session'}',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color:
                                                  correctAttempts ==
                                                      totalAttempts
                                                  ? const Color(0xFF059669)
                                                  : const Color(0xFF64748B),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ] else ...[
                                      const Row(
                                        children: [
                                          Icon(
                                            Icons.bookmark_outline_rounded,
                                            size: 13,
                                            color: Color(0xFF94A3B8),
                                          ),
                                          SizedBox(width: 4),
                                          Text(
                                            'Lesson accuracy preserved',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w500,
                                              color: Color(0xFF94A3B8),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (wordRating != null &&
                                      wordRating.isNotEmpty)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3.5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: rating.background,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: rating.border,
                                          width: 1,
                                        ),
                                      ),
                                      child: Text(
                                        '${rating.emoji} ${rating.label}',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: rating.primary,
                                        ),
                                      ),
                                    )
                                  else
                                    _TierBadge(
                                      tierState: tierState,
                                      pref: pref,
                                    ),
                                  if (wordAccuracy > 0) ...[
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 7,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: wordAccuracy >= 90
                                            ? const Color(0xFFF0FDF4)
                                            : (wordAccuracy >= 75
                                                  ? const Color(0xFFFFFBEB)
                                                  : const Color(0xFFFEF2F2)),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: wordAccuracy >= 90
                                              ? const Color(0xFFBBF7D0)
                                              : (wordAccuracy >= 75
                                                    ? const Color(0xFFFDE68A)
                                                    : const Color(0xFFFECACA)),
                                          width: 1,
                                        ),
                                      ),
                                      child: Text(
                                        '${wordAccuracy.toStringAsFixed(wordAccuracy % 1 == 0 ? 0 : 1)}%',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w800,
                                          color: wordAccuracy >= 90
                                              ? const Color(0xFF16A34A)
                                              : (wordAccuracy >= 75
                                                    ? const Color(0xFFD97706)
                                                    : const Color(0xFFDC2626)),
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        );
                      })
                    else
                      // Fallback to old local rendering if backend is unavailable
                      ...widget.allWords.map((word) {
                        final failed = widget.failedSentenceWordIds.contains(
                          word.wordId,
                        );
                        final mastered = !failed;
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
                              color: const Color(0xFFE2E8F0),
                              width: 1.5,
                            ),
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
                                    Text(
                                      word.cebuanoMeaning,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF64748B),
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: statusBgColor,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: statusColor,
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  mastered
                                      ? LocalizationService.translate(
                                          pref,
                                          'mastered',
                                        )
                                      : LocalizationService.translate(
                                          pref,
                                          'needs_review',
                                        ),
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: statusColor,
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
              child: Builder(
                builder: (context) {
                  final lessonProvider = Provider.of<LessonProvider>(
                    context,
                    listen: false,
                  );

                  // Try to find next unlocked lesson
                  String? nextLessonId;
                  String? nextLessonTitle;
                  try {
                    final currentLessonIndex = lessonProvider.lessons
                        .indexWhere((l) => l.lessonId == widget.lessonId);
                    if (currentLessonIndex >= 0 &&
                        currentLessonIndex <
                            lessonProvider.lessons.length - 1) {
                      for (
                        int i = currentLessonIndex + 1;
                        i < lessonProvider.lessons.length;
                        i++
                      ) {
                        final nextLesson = lessonProvider.lessons[i];
                        if (nextLesson.status == 'UNLOCKED') {
                          nextLessonId = nextLesson.lessonId;
                          nextLessonTitle = nextLesson.lessonTitle;
                          break;
                        }
                      }
                    }
                  } catch (_) {}

                  final hasNextLesson =
                      nextLessonId != null && !widget.isSandbox;

                  return Column(
                    children: [
                      if (hasNextLesson) ...[
                        SizedBox(
                          width: double.infinity,
                          child: App3DButton(
                            text:
                                'Next Lesson: ${nextLessonTitle ?? "Continue"}',
                            variant: App3DButtonVariant.primary,
                            height: 56,
                            onPressed: () {
                              final classQuery = widget.classroomId != null
                                  ? '&classId=${Uri.encodeComponent(widget.classroomId!)}'
                                  : '';
                              lessonProvider.clearActiveClassroom();
                              String categoryName = 'Lessons';
                              try {
                                final category = lessonProvider.categories
                                    .firstWhere(
                                      (c) => c.categoryId == widget.categoryId,
                                    );
                                categoryName = category.categoryName;
                              } catch (_) {}
                              context.go(
                                '/category/${widget.categoryId}/lessons?name=${Uri.encodeComponent(categoryName)}$classQuery',
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      SizedBox(
                        width: double.infinity,
                        child: App3DButton(
                          text: hasNextLesson
                              ? 'Back to Lessons'
                              : LocalizationService.translate(pref, 'done'),
                          variant: hasNextLesson
                              ? App3DButtonVariant.secondary
                              : App3DButtonVariant.success,
                          height: 56,
                          onPressed: () {
                            final classQuery = widget.classroomId != null
                                ? '&classId=${Uri.encodeComponent(widget.classroomId!)}'
                                : '';
                            lessonProvider.clearActiveClassroom();
                            if (widget.isSandbox) {
                              if (context.canPop()) {
                                context.pop();
                              } else {
                                context.go(
                                  '/sandbox?sessionId=${widget.sessionId}',
                                );
                              }
                              return;
                            }
                            if (widget.categoryId.isEmpty) {
                              context.go('/home');
                              return;
                            }
                            String categoryName = 'Lessons';
                            try {
                              final category = lessonProvider.categories
                                  .firstWhere(
                                    (c) => c.categoryId == widget.categoryId,
                                  );
                              categoryName = category.categoryName;
                            } catch (_) {}
                            context.go(
                              '/category/${widget.categoryId}/lessons?name=${Uri.encodeComponent(categoryName)}$classQuery',
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Dual XP Reward Banner (Blue Header) ──────────────────────────────────
  Widget _buildDualXpRewardBanner(
    BuildContext context,
    String? explicitClassId,
    String? explicitClassName,
    String? pref,
  ) {
    final lessonProvider = Provider.of<LessonProvider>(context, listen: false);
    final effectiveClassId =
        explicitClassId ?? lessonProvider.activeClassroomId;
    final effectiveClassName =
        explicitClassName ?? lessonProvider.activeClassName;

    if (effectiveClassId != null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFEFF6FF), Color(0xFFF0FDF4)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFF93C5FD), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2563EB).withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0284C7),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.school_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Class Activity Completed!',
                        style: AppTypography.baloo2(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF0284C7), // BLUE header!
                        ),
                      ),
                      Text(
                        effectiveClassName != null
                            ? 'Recorded for $effectiveClassName'
                            : 'Recorded for your classroom roster',
                        style: AppTypography.nunito(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 10,
                      horizontal: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFBBF7D0)),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '🏫 Class Score',
                          style: AppTypography.nunito(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF059669),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '+50 pts',
                          style: AppTypography.baloo2(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF047857),
                          ),
                        ),
                        Text(
                          'Class Leaderboard',
                          style: AppTypography.nunito(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF10B981),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 10,
                      horizontal: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFBFDBFE)),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '🌍 Global Score',
                          style: AppTypography.nunito(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF0284C7),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '+50 XP',
                          style: AppTypography.baloo2(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF0369A1),
                          ),
                        ),
                        Text(
                          'All-Time Total',
                          style: AppTypography.nunito(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF38BDF8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                '✓ Submitted to teacher class dashboard & leaderboard',
                style: AppTypography.nunito(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF059669),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Global free-play session
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF0284C7),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.public_rounded,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Global Free-Play Practice',
                  style: AppTypography.baloo2(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0284C7), // BLUE header!
                  ),
                ),
                Text(
                  'Points credited to all-time global XP & leaderboard',
                  style: AppTypography.nunito(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF0284C7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '+50 XP',
              style: AppTypography.baloo2(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────
// Tier Badge Widget
// ────────────────────────────────────────────────────────────────
class _TierBadge extends StatelessWidget {
  final String tierState;
  final String? pref;
  const _TierBadge({required this.tierState, required this.pref});

  @override
  Widget build(BuildContext context) {
    String label;
    Color color;
    Color bg;

    switch (tierState) {
      case 'MASTERED':
        label = LocalizationService.translate(pref, 'mastered');
        color = const Color(0xFF10B981);
        bg = const Color(0xFFECFDF5);
        break;
      case 'PROFICIENT':
        label = LocalizationService.translate(pref, 'proficient');
        color = const Color(0xFF2563EB);
        bg = const Color(0xFFEFF6FF);
        break;
      case 'FAMILIAR':
        label = LocalizationService.translate(pref, 'familiar');
        color = const Color(0xFFF59E0B);
        bg = const Color(0xFFFFFBEB);
        break;
      default: // LEARNING
        label = LocalizationService.translate(pref, 'learning');
        color = const Color(0xFF94A3B8);
        bg = const Color(0xFFF8FAFC);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w800,
          color: color,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _BadgeCard extends StatelessWidget {
  final String? badgeType;
  const _BadgeCard({required this.badgeType});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final pref = auth.learner?.languagePreference;
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
                  LocalizationService.translate(pref, 'lesson_badge'),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: info.primary.withValues(alpha: 0.7),
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  LocalizationService.translate(
                    pref,
                    badgeType == 'PERFECT_GOLD'
                        ? 'badge_perfect_gold'
                        : badgeType == 'GOLD'
                        ? 'badge_gold'
                        : badgeType == 'SILVER'
                        ? 'badge_silver'
                        : 'badge_bronze',
                  ),
                  style: AppTypography.baloo2(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: info.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  LocalizationService.translate(
                    pref,
                    badgeType == 'PERFECT_GOLD'
                        ? 'badge_perfect_gold_sub'
                        : badgeType == 'GOLD'
                        ? 'badge_gold_sub'
                        : badgeType == 'SILVER'
                        ? 'badge_silver_sub'
                        : 'badge_bronze_sub',
                  ),
                  style: AppTypography.nunito(
                    fontSize: 12,
                    color: info.primary.withValues(alpha: 0.75),
                    height: 1.4,
                    fontWeight: FontWeight.w500,
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
