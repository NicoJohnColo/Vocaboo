import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../core/motion/motion.dart';
import '../providers/lesson_provider.dart';
import 'cumulative_review_screen.dart';
import '../services/local_storage_service.dart';
import '../services/scoring_service.dart';
import '../widgets/mascot_visual.dart';
import '../widgets/category_completion_dialog.dart';

class MasteryResultScreen extends StatefulWidget {
  final String sessionId;
  final String categoryId;
  final bool isSandbox;
  final int totalItems;
  final int masteredCount;
  final List<String>? missedWordIds;
  final List<Map<String, dynamic>> allWords;
  final double? masteryScore;
  /// Per-word breakdown: each entry has 'word', 'wordId', 'wrongAttempts', 'points'
  final List<Map<String, dynamic>> wordBreakdown;

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
    this.wordBreakdown = const [],
  });

  @override
  State<MasteryResultScreen> createState() => _MasteryResultScreenState();
}

class _MasteryResultScreenState extends State<MasteryResultScreen> {
  List<Map<String, dynamic>> _wordBreakdown = [];
  double? _masteryScore;
  double? _overallAccuracy;
  int? _totalItems;
  int? _masteredCount;
  List<String>? _missedWordIds;
  bool _isLoading = true;
  final Map<String, String> _wordById = {};
  final Map<String, int> _wrongAttemptsByWordId = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;
      context.read<LessonProvider>().fetchDashboardProgress();
    });
    _loadData();
  }

  Future<void> _loadData() async {
    if (widget.wordBreakdown.isNotEmpty) {
      _wordBreakdown = widget.wordBreakdown;
      _masteryScore = widget.masteryScore;
      _totalItems = widget.totalItems > 0 ? widget.totalItems : widget.wordBreakdown.length;
      _masteredCount = widget.masteredCount > 0
          ? widget.masteredCount
          : widget.wordBreakdown.where((w) => ((w['wrongAttempts'] as int?) ?? 0) == 0).length;
      _missedWordIds = widget.missedWordIds ?? widget.wordBreakdown
          .where((w) => ((w['wrongAttempts'] as int?) ?? 0) > 0)
          .map((w) => (w['wordId'] ?? w['id'] ?? '').toString())
          .where((id) => id.isNotEmpty)
          .toList();
      for (final b in _wordBreakdown) {
        final id = (b['wordId'] ?? b['id'] ?? '').toString();
        final wrong = (b['wrongAttempts'] as int?) ?? 0;
        if (id.isNotEmpty) {
          _wrongAttemptsByWordId[id] = wrong;
        }
      }
    } else {
      final details = await LocalStorageService.getCumulativeReviewScoreDetails(widget.sessionId);
      if (details != null) {
        final breakdownRaw = details['wordBreakdown'];
        if (breakdownRaw is List) {
          _wordBreakdown = List<Map<String, dynamic>>.from(breakdownRaw.map((e) => Map<String, dynamic>.from(e)));
          _totalItems = _wordBreakdown.length;
          _masteredCount = _wordBreakdown.where((w) => ((w['wrongAttempts'] as int?) ?? 0) == 0).length;
          _missedWordIds = _wordBreakdown
              .where((w) => ((w['wrongAttempts'] as int?) ?? 0) > 0)
              .map((w) => (w['wordId'] ?? w['id'] ?? '').toString())
              .where((id) => id.isNotEmpty)
              .toList();
          for (final b in _wordBreakdown) {
            final id = (b['wordId'] ?? b['id'] ?? '').toString();
            final wrong = (b['wrongAttempts'] as int?) ?? 0;
            if (id.isNotEmpty) {
              _wrongAttemptsByWordId[id] = wrong;
            }
          }
        }
        final wrongMap = details['wordWrongAttempts'];
        if (wrongMap is Map) {
          wrongMap.forEach((k, v) {
            if (v is num) {
              _wrongAttemptsByWordId[k.toString()] = v.toInt();
            }
          });
        }
        final finalScoreRaw = details['finalScore'] ?? details['cumulativeReviewScore'] ?? details['score'];
        if (finalScoreRaw is num && _masteryScore == null) {
          _masteryScore = finalScoreRaw.toDouble();
        }
        if (details['totalWords'] is int && _totalItems == null) {
          _totalItems = details['totalWords'] as int;
        }
        if (details['masteredCount'] is int && _masteredCount == null) {
          _masteredCount = details['masteredCount'] as int;
        }
      }
      if (_masteryScore == null && widget.masteryScore != null) {
        _masteryScore = widget.masteryScore;
      }
    }

    if (mounted) {
      try {
        final lessons = Provider.of<LessonProvider>(context, listen: false);
        final dashboard = await lessons.fetchDashboardProgress();
        if (dashboard != null) {
          final breakdowns = List<Map<String, dynamic>>.from(dashboard['categoryBreakdowns'] ?? []);
          final catMatch = breakdowns.firstWhere(
            (b) => b['categoryId']?.toString() == widget.categoryId,
            orElse: () => <String, dynamic>{},
          );
          if (catMatch.isNotEmpty) {
            if (catMatch['overallAccuracy'] != null) {
              _overallAccuracy = (catMatch['overallAccuracy'] as num).toDouble();
            }
            // Only use cumulativeAccuracy if session score is entirely missing
            if (_masteryScore == null && widget.masteryScore == null && catMatch['cumulativeAccuracy'] != null) {
              _masteryScore = (catMatch['cumulativeAccuracy'] as num).toDouble();
            }
          }
        }
      } catch (_) {}
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
    // Build a quick lookup map from any provided `allWords` so we can
    // display human-friendly words instead of raw IDs.
    _buildWordMapFromWidget();
    // Also merge any names available from the saved breakdown details.
    try {
      for (final b in _wordBreakdown) {
        final id = (b['wordId'] ?? '').toString();
        final name = (b['word'] ?? '').toString();
        if (id.isNotEmpty && name.isNotEmpty && !_wordById.containsKey(id)) {
          _wordById[id] = name;
        }
      }
    } catch (_) {}
  }

  void _buildWordMapFromWidget() {
    try {
      for (final w in widget.allWords) {
        final id = (w['wordId'] ?? w['id'] ?? w['vocabularyId'] ?? '').toString();
        final name = (w['word'] ?? w['englishWord'] ?? w['english_word'] ?? '').toString();
        if (id.isNotEmpty && name.isNotEmpty) {
          _wordById[id] = name;
        }
      }
    } catch (_) {
      // ignore any malformed entries
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator(color: Color(0xFF0F172A))),
      );
    }

    final sessionId = widget.sessionId;
    final categoryId = widget.categoryId;
    final isSandbox = widget.isSandbox;
    final totalItems = _totalItems ?? (widget.totalItems > 0 ? widget.totalItems : widget.allWords.length);
    final missedWordIds = _missedWordIds ?? widget.missedWordIds;
    final masteredCount = _masteredCount ?? (missedWordIds != null && totalItems > 0
        ? (totalItems - missedWordIds.length).clamp(0, totalItems)
        : (widget.masteredCount > 0 ? widget.masteredCount : totalItems));
    final allWords = widget.allWords;

    // The score for this screen MUST be the current cumulative review session score,
    // NOT the full lesson / category lifetime average (_overallAccuracy, which was 91%)!
    final double sessionCumulativeScore = _masteryScore ??
        widget.masteryScore ??
        (totalItems > 0 ? (masteredCount / totalItems * 100.0) : 0.0);
    final finalScore = sessionCumulativeScore.round();
    final passed = ScoringService.isPassing(finalScore.toDouble());
    final missedCount = missedWordIds?.length ?? 0;

    // Compute total wrong attempts from breakdown
    final totalWrongAttempts = _wordBreakdown.fold<int>(0, (sum, w) => sum + ((w['wrongAttempts'] as int?) ?? 0));

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leadingWidth: 64,
        leading: Center(
          child: Container(
            width: 42,
            height: 42,
            margin: const EdgeInsets.only(left: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0F172A).withValues(alpha: 0.07),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0F172A), size: 20),
              onPressed: () {
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                } else {
                  context.go('/home');
                }
              },
              padding: EdgeInsets.zero,
            ),
          ),
        ),
        title: Text(
          'Mastery Results',
          style: AppTypography.baloo2(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF06A6FF),
          ),
        ),
        actions: const [SizedBox(width: 16)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── 1. Hero Card: Golden Badge with Celebration Aura ──────────
              Container(
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFFBEB), Color(0xFFFFFFFF)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0F172A).withValues(alpha: 0.06),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    if (passed)
                      AppRewardBadgeReveal(
                        tier: badgeTierFromScore(finalScore.toDouble()),
                        badgeSize: 116.0,
                      )
                    else ...[
                      Container(
                        width: 130,
                        height: 130,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFFFFF7ED),
                        ),
                        child: const Center(
                          child: MascotVisual(
                            type: MascotType.sippy,
                            size: 105,
                            isSad: true,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF1F2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFFECACA)),
                        ),
                        child: Text(
                          'REVIEW AGAIN',
                          style: AppTypography.baloo2(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.8,
                            color: const Color(0xFFEF4444),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 22),

              // ── 2. Celebration Heading & Subtitle ─────────────────────────
              Text(
                passed ? 'Congratulations! 🎉' : 'Keep Practicing! 💪',
                textAlign: TextAlign.center,
                style: AppTypography.baloo2(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                passed
                    ? 'You mastered all the words in this lesson!'
                    : 'You are close! Review the missed words to achieve mastery.',
                textAlign: TextAlign.center,
                style: AppTypography.nunito(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF64748B),
                  height: 1.4,
                ),
              ),
              if (passed) ...[
                const SizedBox(height: 14),
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: const Color(0xFFFDE68A), width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('⭐', style: TextStyle(fontSize: 15)),
                        const SizedBox(width: 6),
                        Text(
                          '+50 Bonus XP',
                          style: AppTypography.baloo2(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFFB45309),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),

              // ── 3. Score & Progress Cards (Blue Theme) ───────────
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0F172A).withValues(alpha: 0.04),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildScoreTile(
                            'Cumulative Score',
                            '$finalScore%',
                            passed ? const Color(0xFF0284C7) : const Color(0xFFEF4444),
                            passed ? const Color(0xFFEFF6FF) : const Color(0xFFFEF2F2),
                            countValue: finalScore,
                            suffix: '%',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildScoreTile(
                            'Words Mastered',
                            '$masteredCount / $totalItems',
                            const Color(0xFF2563EB),
                            const Color(0xFFEFF6FF),
                          ),
                        ),
                      ],
                    ),
                    if (missedCount > 0) ...[
                      const SizedBox(height: 14),
                      _buildListCard(
                        title: 'Still Needs Review',
                        color: const Color(0xFFEA580C),
                        background: const Color(0xFFFFF7ED),
                        items: (missedWordIds ?? []).map((id) {
                          final lookup = _wordById[id];
                          if (lookup != null && lookup.isNotEmpty) return lookup;
                          final word = allWords.firstWhere(
                            (w) => (w['wordId'] ?? w['id'] ?? '').toString() == id,
                            orElse: () => {'word': id},
                          );
                          return (word['word'] ?? word['englishWord'] ?? id).toString();
                        }).toList(),
                        itemIds: missedWordIds,
                        mistakesMap: _wrongAttemptsByWordId,
                      ),
                    ],
                    const SizedBox(height: 14),
                    _buildListCard(
                      title: passed ? 'Words Mastered' : 'Words to Review',
                      color: const Color(0xFF0284C7),
                      background: const Color(0xFFF8FAFC),
                      items: (passed
                        ? allWords.where((w) => !(missedWordIds ?? []).contains((w['wordId'] ?? w['id'] ?? '').toString()))
                        : allWords
                      ).map((w) {
                        final id = (w['wordId'] ?? w['id'] ?? '').toString();
                        final name = (_wordById[id] ?? w['word'] ?? w['englishWord'] ?? '').toString();
                        return name;
                      }).where((s) => s.isNotEmpty).toList(),
                      masteredMode: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ── 4. Per-word breakdown card ────────────────────────────────
              if (_wordBreakdown.isNotEmpty) ...[
                _buildBreakdownCard(_wordBreakdown, totalWrongAttempts, finalScore),
                const SizedBox(height: 20),
              ],

              // ── Retry hint ───────────────────────────────────────────────
              if (!passed)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Text(
                    'Module 4 repeats only the words you missed, so the review stays focused and active.',
                    textAlign: TextAlign.center,
                    style: AppTypography.nunito(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF64748B), height: 1.5),
                  ),
                ),
              if (!passed) const SizedBox(height: 22),

              // ── 5. Primary CTA ───────────────────────────────────────────
              App3DButton(
                onPressed: () async {
                  final lessons = Provider.of<LessonProvider>(context, listen: false);
                  if (passed) {
                    if (isSandbox) {
                      context.go('/sandbox');
                      return;
                    }
                    await lessons.fetchDashboardProgress();
                    if (!context.mounted) return;
                    await CategoryCompletionDialog.show(
                      context,
                      categoryName: categoryId,
                      categoryId: categoryId,
                    );
                    return;
                  }

                  Navigator.of(context).pushReplacement(PageRouteBuilder(
                    transitionDuration: const Duration(milliseconds: 350),
                    reverseTransitionDuration: const Duration(milliseconds: 350),
                    pageBuilder: (context, animation, secondaryAnimation) => CumulativeReviewScreen(
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
                variant: passed ? App3DButtonVariant.primary : App3DButtonVariant.danger,
                height: 56,
                depth: 5.0,
                isFullWidth: true,
                borderRadius: 18,
                text: passed ? 'Continue 🎉' : 'Retry Module 4 🔄',
              ),
              const SizedBox(height: 12),

              // ── 6. Secondary CTA ─────────────────────────────────────────
              App3DButton(
                onPressed: () => isSandbox
                    ? context.go('/sandbox')
                    : context.go('/category/$categoryId/lessons'),
                variant: App3DButtonVariant.secondary,
                height: 48,
                depth: 3.5,
                isFullWidth: true,
                borderRadius: 16,
                text: isSandbox ? 'Back to Sandbox' : 'Back to Lessons',
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Per-word breakdown card ──────────────────────────────────────────────
  Widget _buildBreakdownCard(
    List<Map<String, dynamic>> breakdown,
    int totalWrong,
    int finalScore,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: const BoxDecoration(
              color: Color(0xFF0F172A),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(22),
                topRight: Radius.circular(22),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.bar_chart_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Score Breakdown',
                    style: TextStyle(
                      fontFamily: AppTypography.displayFontFamily,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '${breakdown.length} words',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),

          // Column headers
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
            child: Row(
              children: [
                const Expanded(
                  flex: 5,
                  child: Text('Word', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF94A3B8), letterSpacing: 0.8)),
                ),
                const SizedBox(
                  width: 86,
                  child: Text('Mistakes', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF94A3B8), letterSpacing: 0.8)),
                ),
                const SizedBox(
                  width: 72,
                  child: Text('Points', textAlign: TextAlign.right, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF94A3B8), letterSpacing: 0.8)),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),

          // Word rows
          ...breakdown.asMap().entries.map((entry) {
            final i = entry.key;
            final w = entry.value;
            final wrong = (w['wrongAttempts'] as int?) ?? 0;
            final points = (w['points'] is num) ? (w['points'] as num).toDouble() : 0.0;
            final rawId = (w['wordId'] ?? w['id'] ?? '').toString();
            final wordName = (_wordById[rawId] ?? w['word'] ?? w['englishWord'] ?? rawId).toString().replaceAll('_', ' ');
            final isPerfect = wrong == 0;
            final isLast = i == breakdown.length - 1;

            return Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
                  color: i.isEven ? const Color(0xFFFAFAFC) : Colors.white,
                  child: Row(
                    children: [
                      // Word name + mastery indicator
                      Expanded(
                        flex: 5,
                        child: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: isPerfect ? const Color(0xFF0284C7) : const Color(0xFFEF4444),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Flexible(
                              child: Text(
                                wordName,
                                style: AppTypography.baloo2(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: isPerfect ? const Color(0xFF0F172A) : const Color(0xFF7F1D1D),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Wrong attempts badge
                      SizedBox(
                        width: 86,
                        child: Center(
                          child: wrong == 0
                              ? const Icon(Icons.check_circle_rounded, color: Color(0xFF0284C7), size: 18)
                              : Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFEF2F2),
                                    borderRadius: BorderRadius.circular(999),
                                    border: Border.all(color: const Color(0xFFFECACA)),
                                  ),
                                  child: Text(
                                    '$wrong mistake${wrong > 1 ? 's' : ''}',
                                    style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: Color(0xFFDC2626)),
                                  ),
                                ),
                        ),
                      ),
                      // Points
                      SizedBox(
                        width: 72,
                        child: Text(
                          '${points.toStringAsFixed(points == points.roundToDouble() ? 0 : 2)} pts',
                          textAlign: TextAlign.right,
                          style: AppTypography.baloo2(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: isPerfect ? const Color(0xFF0284C7) : const Color(0xFFEF4444),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (!isLast) const Divider(height: 1, indent: 20, endIndent: 20, color: Color(0xFFE2E8F0)),
              ],
            );
          }),

          const Divider(height: 1, color: Color(0xFFE2E8F0)),

          // Summary footer
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
            child: Row(
              children: [
                // Total wrong attempts
                Expanded(
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded, color: Color(0xFFDC2626), size: 16),
                      const SizedBox(width: 6),
                      Text(
                        '$totalWrong total wrong attempt${totalWrong == 1 ? '' : 's'}',
                        style: AppTypography.nunito(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
                // Final score chip
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: finalScore >= 80 ? const Color(0xFFEFF6FF) : const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: finalScore >= 80 ? const Color(0xFFBAE6FD) : const Color(0xFFFECACA),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Cumulative: $finalScore%',
                        style: AppTypography.baloo2(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: finalScore >= 80 ? const Color(0xFF0284C7) : const Color(0xFFDC2626),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreTile(String label, String value, Color accent, Color background, {num? countValue, String suffix = ''}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent.withValues(alpha: 0.3), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.replaceAll('_', ' '),
            style: AppTypography.nunito(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: accent,
            ),
          ),
          const SizedBox(height: 6),
          if (countValue != null)
            AppAnimatedCounter(
              value: countValue,
              suffix: suffix,
              style: AppTypography.baloo2(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: accent,
              ),
            )
          else
            Text(
              value.replaceAll('_', ' '),
              style: AppTypography.baloo2(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: accent,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildListCard({
    required String title,
    required Color color,
    required Color background,
    required List<String> items,
    List<String>? itemIds,
    Map<String, int>? mistakesMap,
    bool masteredMode = false,
  }) {
    final cleanTitle = title.replaceAll('_', ' ');
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.25), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                masteredMode ? Icons.check_circle_rounded : Icons.info_outline_rounded,
                size: 18,
                color: color,
              ),
              const SizedBox(width: 8),
              Text(
                cleanTitle,
                style: AppTypography.baloo2(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (items.isEmpty)
            Text(
              'No words to review.',
              style: AppTypography.nunito(color: const Color(0xFF64748B), fontSize: 13, fontWeight: FontWeight.w600),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: items.asMap().entries.map((entry) {
                final idx = entry.key;
                final item = entry.value;
                final id = (itemIds != null && idx < itemIds.length) ? itemIds[idx] : null;
                final mistakes = (id != null && mistakesMap != null) ? mistakesMap[id] : null;
                return _pill(item, color, mistakes: mistakes);
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _pill(String text, Color color, {int? mistakes}) {
    final cleanWord = text.replaceAll('_', ' ');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.08),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            cleanWord,
            style: AppTypography.baloo2(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0F172A),
            ),
          ),
          if (mistakes != null && mistakes > 0) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFECACA)),
              ),
              child: Text(
                '$mistakes mistake${mistakes > 1 ? 's' : ''}',
                style: AppTypography.nunito(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFFDC2626),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
