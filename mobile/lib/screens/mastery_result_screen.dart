// mastery_result_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/lesson_provider.dart';
import 'cumulative_mixed_review_screen.dart';
import '../services/localization_service.dart';
import '../services/local_storage_service.dart';
import '../widgets/mascot_visual.dart';

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
  bool _isLoading = true;
  final Map<String, String> _wordById = {};

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
    } else {
      final details = await LocalStorageService.getCumulativeReviewScoreDetails(widget.sessionId);
      if (details != null) {
        final breakdownRaw = details['wordBreakdown'];
        if (breakdownRaw is List) {
          _wordBreakdown = List<Map<String, dynamic>>.from(breakdownRaw.map((e) => Map<String, dynamic>.from(e)));
        }
        final finalScoreRaw = details['finalScore'];
        if (finalScoreRaw is num) {
          _masteryScore = finalScoreRaw.toDouble();
        }
      }
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

    final pref = Provider.of<AuthProvider>(context, listen: false).learner?.languagePreference;
    
    final sessionId = widget.sessionId;
    final categoryId = widget.categoryId;
    final isSandbox = widget.isSandbox;
    final totalItems = widget.totalItems;
    final masteredCount = widget.masteredCount;
    final missedWordIds = widget.missedWordIds;
    final allWords = widget.allWords;

    final masteryPercent = _masteryScore != null
      ? _masteryScore!.round()
      : (totalItems == 0 ? 0 : (masteredCount / totalItems * 100).round());
    final passed = masteryPercent >= 70;
    final missedCount = missedWordIds?.length ?? 0;

    // Compute total wrong attempts and final score from breakdown
    final totalWrongAttempts = _wordBreakdown.fold<int>(0, (sum, w) => sum + ((w['wrongAttempts'] as int?) ?? 0));
    final finalScore = _masteryScore?.round() ?? masteryPercent;

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
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              context.go('/home');
            }
          },
        ),
        actions: const [SizedBox(width: 12)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Hero card ────────────────────────────────────────────────
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
                          size: 110,
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

              // ── Score tiles ──────────────────────────────────────────────
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
                          child: _buildScoreTile(
                            'Final score',
                            '$finalScore / 100',
                            passed ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                            passed ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildScoreTile(
                            'Words mastered',
                            '$masteredCount / $totalItems',
                            const Color(0xFF06A6FF),
                            const Color(0xFFEFF6FF),
                          ),
                        ),
                      ],
                    ),
                    if (missedCount > 0) ...[
                      const SizedBox(height: 12),
                      _buildListCard(
                        title: 'Still needs review',
                        color: const Color(0xFFEF4444),
                        background: const Color(0xFFFFF1F2),
                        items: (missedWordIds ?? []).map((id) {
                          final lookup = _wordById[id];
                          if (lookup != null && lookup.isNotEmpty) return lookup;
                          final word = allWords.firstWhere(
                            (w) => (w['wordId'] ?? w['id'] ?? '').toString() == id,
                            orElse: () => {'word': id},
                          );
                          return (word['word'] ?? word['englishWord'] ?? id).toString();
                        }).toList(),
                      ),
                    ],
                    const SizedBox(height: 12),
                    _buildListCard(
                      title: passed ? 'Words mastered' : 'Words to review',
                      color: passed ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                      background: passed ? const Color(0xFFECFDF5) : const Color(0xFFFFF1F2),
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

              // ── Per-word breakdown card ───────────────────────────────────
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
                  child: const Text(
                    'Module 4 repeats only the words you missed, so the review stays focused and active.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.5),
                  ),
                ),
              if (!passed) const SizedBox(height: 22),

              // ── Primary CTA ──────────────────────────────────────────────
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

              // ── Scoring key ──────────────────────────────────────────────
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
                const Expanded(
                  child: Text(
                    'Score Breakdown',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
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
                  width: 72,
                  child: Text('Wrong', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF94A3B8), letterSpacing: 0.8)),
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
            final wordName = (_wordById[rawId] ?? w['word'] ?? w['englishWord'] ?? rawId).toString();
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
                                color: isPerfect ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Flexible(
                              child: Text(
                                wordName,
                                style: TextStyle(
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
                        width: 72,
                        child: Center(
                          child: wrong == 0
                              ? const Icon(Icons.check_circle_outline_rounded, color: Color(0xFF10B981), size: 18)
                              : Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFEF2F2),
                                    borderRadius: BorderRadius.circular(999),
                                    border: Border.all(color: const Color(0xFFFECACA)),
                                  ),
                                  child: Text(
                                    '−$wrong',
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFFDC2626)),
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
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: isPerfect ? const Color(0xFF059669) : const Color(0xFFEF4444),
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
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
                // Final score chip
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: finalScore >= 70 ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: finalScore >= 70 ? const Color(0xFFBBF7D0) : const Color(0xFFFECACA),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Final: $finalScore / 100',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: finalScore >= 70 ? const Color(0xFF059669) : const Color(0xFFDC2626),
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
