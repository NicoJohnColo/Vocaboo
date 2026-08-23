import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../core/motion/motion.dart';
import '../models/lesson_model.dart';
import '../providers/auth_provider.dart';
import '../providers/lesson_provider.dart';
import '../services/local_storage_service.dart';
import '../services/localization_service.dart';
import 'package:uuid/uuid.dart';
import 'mastery_result_screen.dart';

class LessonPathScreen extends StatefulWidget {
  final String categoryId;
  final String categoryName;

  const LessonPathScreen({
    super.key,
    required this.categoryId,
    required this.categoryName,
  });

  @override
  State<LessonPathScreen> createState() => _LessonPathScreenState();
}

class _LessonPathScreenState extends State<LessonPathScreen> {
  Map<String, int> _localMasteredCounts = {};
  double? _cumulativeReviewScore;
  bool _cumulativeReviewCompleted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = Provider.of<LessonProvider>(context, listen: false);
      await provider.loadLessons(widget.categoryId);
      await _loadLocalScores(provider);
    });
  }

  Future<void> _loadLocalScores(LessonProvider provider) async {
    final scores = <String, double>{};
    final masteredCounts = <String, int>{};
    for (final lesson in provider.lessons) {
      final localScore = await LocalStorageService.getLessonScore(lesson.lessonId);
      if (localScore != null && localScore > 0) {
        scores[lesson.lessonId] = localScore;
      }
      
      // Try backend word difficulties first to get true mastery status
      final difficulties = await provider.loadWordDifficulties(lesson.lessonId);
      if (difficulties.isNotEmpty) {
        int backendMastered = difficulties.values.where((level) => level == 'MASTERED').length;
        masteredCounts[lesson.lessonId] = backendMastered;
      } else {
        final details = await LocalStorageService.getLessonScoreDetails(lesson.lessonId);
        if (details != null) {
          final failedRaw = details['failedSentenceWordIds'];
          Set<String> failedSentenceWordIds = {};
          if (failedRaw is List) {
            failedSentenceWordIds = Set<String>.from(failedRaw.map((e) => e.toString()));
          }
          int mastered = (lesson.totalWordCount - failedSentenceWordIds.length).clamp(0, lesson.totalWordCount);
          masteredCounts[lesson.lessonId] = mastered;
        }
      }
    }
    
    LessonModel? compositeReviewLesson = provider.lessons.cast<LessonModel?>().firstWhere(
      (lesson) => lesson?.isCompositeReview ?? false,
      orElse: () => null,
    );
    bool isReviewCompleted = await LocalStorageService.getCumulativeReviewCompleted(widget.categoryId);
    double? reviewScore = await LocalStorageService.getCumulativeReviewScore(widget.categoryId);
    if (reviewScore != null && reviewScore > 0) {
      isReviewCompleted = true;
    }
    if (!isReviewCompleted && compositeReviewLesson != null && compositeReviewLesson.status == 'COMPLETED') {
      isReviewCompleted = true;
      reviewScore ??= compositeReviewLesson.masteryScore;
    }

    // If score was wiped (e.g. during an exited retry), recover from backend dashboard
    if (!isReviewCompleted || reviewScore == null) {
      try {
        final dashboard = await provider.fetchDashboardProgress();
        if (dashboard != null) {
          final breakdowns = List<Map<String, dynamic>>.from(dashboard['categoryBreakdowns'] ?? []);
          final catMatch = breakdowns.firstWhere(
            (b) => b['categoryId']?.toString() == widget.categoryId,
            orElse: () => <String, dynamic>{},
          );
          if (catMatch.isNotEmpty && catMatch['cumulativeAccuracy'] != null) {
            final double acc = (catMatch['cumulativeAccuracy'] as num).toDouble();
            if (acc > 0) {
              isReviewCompleted = true;
              reviewScore = acc;
              await LocalStorageService.saveCumulativeReviewCompleted(
                widget.categoryId,
                acc,
                18,
                18,
                'recovered_${widget.categoryId}',
                [],
                [],
              );
            }
          }
        }
      } catch (e) {
        debugPrint('Failed to recover cumulative review score from dashboard: $e');
      }
    }
    
    if (mounted) {
      setState(() {
        _localMasteredCounts = masteredCounts;
        _cumulativeReviewCompleted = isReviewCompleted;
        _cumulativeReviewScore = reviewScore;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = Provider.of<LessonProvider>(context);
    final auth = Provider.of<AuthProvider>(context);
    final pref = auth.learner?.languagePreference;
    
    // Find composite review lesson if present
    LessonModel? compositeReviewLesson = provider.lessons.cast<LessonModel?>().firstWhere(
      (lesson) => lesson?.isCompositeReview ?? false,
      orElse: () => null,
    );

    // If backend doesn't provide a composite review lesson, construct a local static one
    if (compositeReviewLesson == null && provider.lessons.length >= 2) {
      final lesson1 = provider.lessons[0];
      final lesson2 = provider.lessons[1];
      compositeReviewLesson = LessonModel(
        lessonId: 'local_cumulative_review',
        categoryId: widget.categoryId,
        lessonTitle: 'Cumulative Review',
        lessonDescription: 'Cumulative review of Lessons 1 and 2',
        gradeLevel: 'GRADE_4',
        lessonOrder: 3,
        totalWordCount: lesson1.totalWordCount + lesson2.totalWordCount,
        status: (lesson1.status == 'COMPLETED' && lesson2.status == 'COMPLETED') ? 'UNLOCKED' : 'LOCKED',
        lessonType: 'COMPOSITE_REVIEW',
        sourceLessonIds: [lesson1.lessonId, lesson2.lessonId],
        compositeReviewAfterLessonId: lesson2.lessonId,
      );
    }
    
    final hasReviewNode = compositeReviewLesson != null;
    
    // Determine insertion index based on compositeReviewAfterLessonId
    int reviewInsertIndex = 2; // Default fallback
    List<String> sourceLessonIds = [];
    
    if (hasReviewNode) {
      final afterLessonId = compositeReviewLesson.compositeReviewAfterLessonId;
      sourceLessonIds = compositeReviewLesson.sourceLessonIds ?? [];
      
      if (afterLessonId != null) {
        final afterLessonIndex = provider.lessons.indexWhere((lesson) => lesson.lessonId == afterLessonId);
        if (afterLessonIndex >= 0) {
          reviewInsertIndex = afterLessonIndex + 1;
        }
      } else {
        // Fallback to using source lesson count
        reviewInsertIndex = sourceLessonIds.length;
      }
    }
    
    // Check if review is unlocked (all source lessons must have all words mastered)
    final reviewUnlocked = _cumulativeReviewCompleted || (hasReviewNode && sourceLessonIds.isNotEmpty && 
        sourceLessonIds.every((id) {
          final found = provider.lessons.cast<LessonModel?>().firstWhere(
            (l) => l?.lessonId == id,
            orElse: () => null,
          );
          if (found == null) return false;
          if (found.status == 'COMPLETED') return true;
          final mastered = _localMasteredCounts[id] ?? 0;
          return mastered >= found.totalWordCount && found.totalWordCount > 0;
        }));
    
    final totalItems = provider.lessons.length + (hasReviewNode ? 1 : 0);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF0F172A)),
          onPressed: () => context.go('/home'),
        ),
        title: Row(
          children: [
            AppHero(
              tag: 'category_icon_${widget.categoryId}',
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF0EA5E9).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.menu_book_rounded, color: Color(0xFF0EA5E9), size: 20),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                widget.categoryName,
                style: const TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
      body: AppRefreshIndicator(
        onRefresh: () async {
          await provider.loadLessons(widget.categoryId);
          await _loadLocalScores(provider);
        },
        child: SafeArea(
          child: provider.isLoading && provider.lessons.isEmpty
              ? ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
                  itemCount: 4,
                  itemBuilder: (_, __) => Padding(
                    padding: const EdgeInsets.only(bottom: 24.0),
                    child: AppShimmer.card(height: 100),
                  ),
                )
              : provider.error != null
                  ? Center(child: Text(provider.error!, style: const TextStyle(color: Colors.red)))
                  : provider.lessons.isEmpty
                      ? const Center(
                          child: Text(
                            'No lessons available in this category.',
                            style: TextStyle(color: Color(0xFF64748B)),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
                              itemCount: totalItems,
                          itemBuilder: (context, index) {
                            if (hasReviewNode && index == reviewInsertIndex) {
                              return _buildReviewNode(context, theme, reviewUnlocked, sourceLessonIds);
                            }

                            final lessonIndex = hasReviewNode && index > reviewInsertIndex ? index - 1 : index;
                            final lesson = provider.lessons[lessonIndex];
                            final isLast = index == totalItems - 1;

                            final mastered = _localMasteredCounts[lesson.lessonId] ?? lesson.masteredWordCount;
                            final isCompleted = lesson.status == 'COMPLETED' || (lesson.totalWordCount > 0 && mastered >= lesson.totalWordCount);

                            Color nodeColor;
                            IconData nodeIcon;
                            bool isEnabled = false;

                            if (isCompleted) {
                              nodeColor = theme.colorScheme.tertiary; // Emerald
                              nodeIcon = Icons.check_circle_rounded;
                              isEnabled = true;
                            } else if (lesson.status == 'UNLOCKED') {
                              nodeColor = const Color(0xFF0EA5E9); // Blue
                              nodeIcon = Icons.play_arrow_rounded;
                              isEnabled = true;
                            } else {
                              nodeColor = const Color(0xFFCBD5E1); // Light gray locked
                              nodeIcon = Icons.lock_rounded;
                              isEnabled = false;
                            }

                            final isLeft = index % 2 == 0;

                            return Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    if (!isLeft) const Spacer(),
                                    GestureDetector(
                                      onTap: isEnabled
                                          ? () async {
                                              final activeSession = await LocalStorageService.getActiveLessonSession(lesson.lessonId);
                                              if (activeSession != null && mounted) {
                                                _showResumePrompt(lesson, activeSession);
                                              } else if (isCompleted) {
                                                await LocalStorageService.clearActiveLessonSession(lesson.lessonId);
                                                _showCompletedLessonOptions(lesson);
                                              } else {
                                                _showContextParagraphPrompt(lesson);
                                              }
                                            }
                                          : null,
                                      child: Column(
                                        children: [
                                          // Circular node
                                          AnimatedContainer(
                                            duration: const Duration(milliseconds: 300),
                                            width: 80,
                                            height: 80,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: isEnabled
                                                  ? nodeColor.withValues(alpha: 0.12)
                                                  : const Color(0xFFF1F5F9),
                                              border: Border.all(
                                                color: nodeColor,
                                                width: 3,
                                              ),
                                              boxShadow: isEnabled
                                                  ? [
                                                      BoxShadow(
                                                        color: nodeColor.withValues(alpha: 0.2),
                                                        blurRadius: 12,
                                                        spreadRadius: 1,
                                                      )
                                                    ]
                                                  : null,
                                            ),
                                            child: Center(
                                              child: Icon(
                                                nodeIcon,
                                                color: nodeColor,
                                                size: 36,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                          // Title Card
                                          Container(
                                            width: 180,
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius: BorderRadius.circular(16),
                                              border: Border.all(
                                                color: isEnabled
                                                    ? nodeColor.withValues(alpha: 0.2)
                                                    : const Color(0xFFE2E8F0),
                                                width: 1.5,
                                              ),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black.withValues(alpha: 0.03),
                                                  blurRadius: 8,
                                                  offset: const Offset(0, 4),
                                                )
                                              ],
                                            ),
                                            child: Column(
                                              children: [
                                                Text(
                                                  lesson.lessonTitle,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 14,
                                                    color: Color(0xFF0F172A),
                                                  ),
                                                  textAlign: TextAlign.center,
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  '${lesson.totalWordCount} ${LocalizationService.translate(pref, 'words_count')}',
                                                  style: const TextStyle(
                                                    fontSize: 11,
                                                    color: Color(0xFF64748B),
                                                  ),
                                                ),
                                                if (isEnabled) ...[
                                                  Builder(
                                                    builder: (context) {
                                                      final mastered = _localMasteredCounts[lesson.lessonId] ?? lesson.masteredWordCount;
                                                      
                                                      return Container(
                                                        margin: const EdgeInsets.only(top: 6),
                                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                        decoration: BoxDecoration(
                                                          color: nodeColor.withValues(alpha: 0.12),
                                                          borderRadius: BorderRadius.circular(8),
                                                        ),
                                                        child: Text(
                                                          'Mastered: $mastered / ${lesson.totalWordCount}',
                                                          style: TextStyle(
                                                            fontSize: 10,
                                                            color: nodeColor,
                                                            fontWeight: FontWeight.bold,
                                                            fontFamily: 'Outfit',
                                                          ),
                                                        ),
                                                      );
                                                    },
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (isLeft) const Spacer(),
                                  ],
                                ),
                                if (!isLast)
                                  Container(
                                    height: 50,
                                    width: 4,
                                    margin: const EdgeInsets.symmetric(vertical: 8),
                                    decoration: BoxDecoration(
                                      color: isEnabled
                                          ? nodeColor.withValues(alpha: 0.3)
                                          : const Color(0xFFE2E8F0),
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),
        ),
      ),
    );
  }

  void _showCompletedLessonOptions(LessonModel lesson) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          lesson.lessonTitle,
          style: const TextStyle(
            fontFamily: 'Outfit',
            fontWeight: FontWeight.w900,
            color: Color(0xFF0F172A),
            fontSize: 20,
          ),
          textAlign: TextAlign.center,
        ),
        content: const Text(
          'You completed this lesson. What would you like to do?',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: Color(0xFF64748B),
            height: 1.5,
          ),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        actions: [
          // View Score button
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await _viewLessonScore(lesson);
            },
            icon: const Icon(Icons.visibility_rounded, size: 18),
            label: const Text('View Score'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF06A6FF),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              textStyle: const TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Retry button
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await _retryLesson(lesson);
            },
            icon: const Icon(Icons.replay_rounded, size: 18),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              textStyle: const TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _viewLessonScore(LessonModel lesson) async {
    final provider = Provider.of<LessonProvider>(context, listen: false);
    final navContext = context;

    // Load vocabulary words for this lesson
    final words = await provider.loadVocabulary(lesson.lessonId);
    final allWords = words.map((w) => w.toJson()).toList();

    if (!mounted) return;

    // Load stored score data from local storage
    final localScore = await LocalStorageService.getLessonScore(lesson.lessonId);
    final scoreDetails = await LocalStorageService.getLessonScoreDetails(lesson.lessonId);

    final rawScore = localScore ?? lesson.masteryScore ?? 0.0;
    final overallScore = (lesson.masteryScore != null && lesson.masteryScore! > rawScore)
        ? lesson.masteryScore!
        : (rawScore > 0.0 ? rawScore : 97.5);

    // Extract per-word data if available
    Map<String, bool> wordPronunciationCorrect = {};
    Map<String, int> wordPronunciationAttempts = {};
    Set<String> failedSentenceWordIds = {};

    if (scoreDetails != null) {
      final correctRaw = scoreDetails['wordPronunciationCorrect'];
      if (correctRaw is Map) {
        wordPronunciationCorrect = Map<String, bool>.from(correctRaw);
      }
      final attemptsRaw = scoreDetails['wordPronunciationAttempts'];
      if (attemptsRaw is Map) {
        wordPronunciationAttempts = Map<String, int>.from(attemptsRaw);
      }
      final failedRaw = scoreDetails['failedSentenceWordIds'];
      if (failedRaw is List) {
        failedSentenceWordIds = Set<String>.from(failedRaw.map((e) => e.toString()));
      }
    }

    // Ensure all words have entries (default false/0 for graceful display)
    for (final word in words) {
      wordPronunciationCorrect.putIfAbsent(word.wordId, () => false);
      wordPronunciationAttempts.putIfAbsent(word.wordId, () => 0);
    }

    if (!mounted) return;

    final sessionId = const Uuid().v4();

    // ignore: use_build_context_synchronously
    navContext.push(
      '/session/$sessionId/lesson-score',
      extra: {
        'sessionId': sessionId,
        'lessonId': lesson.lessonId,
        'categoryId': widget.categoryId,
        'lessonTitle': lesson.lessonTitle,
        'allWords': allWords,
        'wordPronunciationCorrect': wordPronunciationCorrect,
        'wordPronunciationAttempts': wordPronunciationAttempts,
        'failedSentenceWordIds': failedSentenceWordIds,
        'overallScore': overallScore,
        'isSandbox': false,
      },
    );
  }

  void _showResumePrompt(LessonModel lesson, Map<String, String> activeSession) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          'Resume Lesson',
          style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.w900, color: Color(0xFF0F172A), fontSize: 20),
          textAlign: TextAlign.center,
        ),
        content: const Text(
          'You have an active session for this lesson. Would you like to resume where you left off or start over?',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: Color(0xFF64748B), height: 1.5),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              LocalStorageService.clearActiveLessonSession(lesson.lessonId);
              _showContextParagraphPrompt(lesson);
            },
            child: const Text('Start Over', style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              final provider = Provider.of<LessonProvider>(context, listen: false);
              final words = await provider.loadVocabulary(lesson.lessonId);
              if (!mounted) return;
              context.push(
                '/loading',
                extra: {
                  'duration': 13000,
                  'redirectPath': activeSession['redirectPath'],
                  'sessionId': activeSession['sessionId'],
                  'lessonId': lesson.lessonId,
                  'categoryId': widget.categoryId,
                  'lessonTitle': lesson.lessonTitle,
                  'allWords': words.map((w) => w.toJson()).toList(),
                  'isSandbox': false,
                },
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0EA5E9),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Resume', style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _retryLesson(LessonModel lesson) async {
    final provider = Provider.of<LessonProvider>(context, listen: false);

    // Attempt backend reset
    await provider.resetLesson(lesson.lessonId);

    // Always clear local score data for this lesson
    await LocalStorageService.saveLessonScore(lesson.lessonId, 0.0);
    await LocalStorageService.clearLessonScoreDetails(lesson.lessonId);

    if (!mounted) return;

    // Refresh lessons from backend if reset succeeded, or reload anyway
    await provider.loadLessons(widget.categoryId);
    await _loadLocalScores(provider);

    if (!mounted) return;

    // Clear any cached words by reloading vocabulary fresh
    await provider.loadVocabulary(lesson.lessonId);

    if (!mounted) return;

    _showContextParagraphPrompt(lesson);
  }

  void _showContextParagraphPrompt(LessonModel lesson) {
    if (lesson.contextParagraph == null || lesson.contextParagraph!.trim().isEmpty) {
      _showFocusPromptAndStartLesson(lesson);
      return;
    }

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final pref = auth.learner?.languagePreference;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          LocalizationService.translate(pref, 'lesson_context_title'),
          style: const TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.w900, color: Color(0xFF0F172A), fontSize: 20),
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              LocalizationService.translate(pref, 'lesson_context_desc'),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Color(0xFF64748B), height: 1.5, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Text(
                '"${lesson.contextParagraph}"',
                style: const TextStyle(fontSize: 16, color: Color(0xFF334155), fontStyle: FontStyle.italic),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _showFocusPromptAndStartLesson(lesson);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0EA5E9),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              textStyle: const TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold, fontSize: 16),
            ),
            child: Text(LocalizationService.translate(pref, 'continue')),
          ),
        ],
      ),
    );
  }

  void _showFocusPromptAndStartLesson(LessonModel lesson) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    String selectedFocus = auth.learner?.posFocus ?? 'ALL';

    final options = [
      {'key': 'ALL', 'label': '🌟 All Words', 'desc': 'Practice all vocabulary words in this lesson'},
      {'key': 'NOUN', 'label': '🏷️ Nouns', 'desc': 'Focus on objects, places, and names'},
      {'key': 'VERB', 'label': '⚡ Verbs', 'desc': 'Focus on action words'},
      {'key': 'ADJECTIVE', 'label': '🎨 Adjectives', 'desc': 'Focus on descriptive words'},
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (bottomSheetContext, setModalState) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFCBD5E1),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'What would you like to focus on?',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontWeight: FontWeight.w900,
                      fontSize: 20,
                      color: Color(0xFF0F172A),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    lesson.lessonTitle,
                    style: const TextStyle(
                      fontFamily: 'Outfit',
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: Color(0xFF64748B),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  ...options.map((opt) {
                    final key = opt['key'] as String;
                    final isSelected = selectedFocus == key;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFFE0F2FE) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected ? const Color(0xFF0EA5E9) : const Color(0xFFE2E8F0),
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Material(
                        type: MaterialType.transparency,
                        child: ListTile(
                          onTap: () {
                            setModalState(() {
                              selectedFocus = key;
                            });
                          },
                          title: Text(
                            opt['label'] as String,
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                opt['desc'] as String,
                                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                              ),
                              const SizedBox(height: 4),
                              Builder(builder: (ctx) {
                                final total = key == 'ALL' 
                                    ? lesson.totalWordCount 
                                    : (lesson.posTotalWordCounts[key] ?? (lesson.totalWordCount > 0 ? lesson.totalWordCount ~/ 3 : 4));
                                final mastered = key == 'ALL'
                                    ? (_localMasteredCounts[lesson.lessonId] ?? lesson.masteredWordCount)
                                    : (lesson.posMasteredWordCounts[key] ?? 0);
                                final isDone = mastered >= total && total > 0;
                                
                                return Row(
                                  children: [
                                    Text(
                                      'Mastered: $mastered / $total words',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: isDone ? const Color(0xFF10B981) : const Color(0xFF64748B),
                                      ),
                                    ),
                                    if (isDone) ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFECFDF5),
                                          borderRadius: BorderRadius.circular(4),
                                          border: Border.all(color: const Color(0xFF10B981), width: 0.8),
                                        ),
                                        child: const Text(
                                          '✓ Finished',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w800,
                                            color: Color(0xFF10B981),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                );
                              }),
                            ],
                          ),
                          trailing: isSelected
                              ? const Icon(Icons.check_circle_rounded, color: Color(0xFF0EA5E9))
                              : const Icon(Icons.radio_button_unchecked_rounded, color: Color(0xFF94A3B8)),
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0EA5E9),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    onPressed: () async {
                      final total = selectedFocus == 'ALL'
                          ? lesson.totalWordCount
                          : (lesson.posTotalWordCounts[selectedFocus] ?? (lesson.totalWordCount > 0 ? lesson.totalWordCount ~/ 3 : 4));
                      final mastered = selectedFocus == 'ALL'
                          ? (_localMasteredCounts[lesson.lessonId] ?? lesson.masteredWordCount)
                          : (lesson.posMasteredWordCounts[selectedFocus] ?? 0);
                      final isDone = mastered >= total && total > 0;

                      // If specifically clicking an already finished POS category (e.g. Nouns 4/4), ask to restart
                      if (selectedFocus != 'ALL' && isDone) {
                        final posLabel = options.firstWhere((o) => o['key'] == selectedFocus)['label'] ?? selectedFocus;
                        final confirmRestart = await showDialog<bool>(
                          context: context,
                          builder: (dialogCtx) => AlertDialog(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            title: Text('Restart $posLabel?'),
                            content: Text('You have already mastered all words in $posLabel for this lesson. Would you like to restart and practice them again?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(dialogCtx).pop(false),
                                child: const Text('Cancel'),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF0EA5E9),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                onPressed: () => Navigator.of(dialogCtx).pop(true),
                                child: const Text('Restart & Practice'),
                              ),
                            ],
                          ),
                        );

                        if (confirmRestart != true) {
                          return;
                        }

                        // Reset progress for this specific POS in the backend
                        final lessonProvider = Provider.of<LessonProvider>(context, listen: false);
                        await lessonProvider.resetLessonProgress(lesson.lessonId, partOfSpeech: selectedFocus);
                        await LocalStorageService.clearActiveLessonSession(lesson.lessonId);
                      }

                      Navigator.of(ctx).pop();
                      await auth.updatePosFocus(selectedFocus);
                      if (mounted) {
                        context.push(
                          '/loading',
                          extra: {
                            'duration': 13000,
                            'redirectPath': '/lesson/${lesson.lessonId}/diagnostic',
                            'categoryId': widget.categoryId,
                          },
                        );
                      }
                    },
                    child: const Text(
                      'Start Lesson',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildReviewNode(BuildContext context, ThemeData theme, bool reviewUnlocked, List<String> lessonIds) {
    final bool isCompleted = _cumulativeReviewCompleted || _cumulativeReviewScore != null;
    final color = isCompleted ? theme.colorScheme.tertiary : (reviewUnlocked ? const Color(0xFF10B981) : const Color(0xFFCBD5E1));
    final icon = isCompleted ? Icons.check_circle_rounded : (reviewUnlocked ? Icons.auto_graph_rounded : Icons.lock_rounded);
    
    // Generate dynamic label based on lesson IDs
    String reviewLabel = 'Cumulative Review';
    
    String unlockMessage = isCompleted
        ? 'Tap to view score or retry'
        : (reviewUnlocked 
            ? 'Tap to start mixed review' 
            : (lessonIds.length == 2 
                ? 'Complete Lessons 1 and 2' 
                : 'Complete all source lessons'));

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AppPressable(
              onTap: reviewUnlocked
                  ? () async {
                      // Check if cumulative review has been completed
                      bool completed = _cumulativeReviewCompleted || 
                                       _cumulativeReviewScore != null || 
                                       await LocalStorageService.getCumulativeReviewCompleted(widget.categoryId) ||
                                       ((await LocalStorageService.getCumulativeReviewScore(widget.categoryId)) != null);
                      
                      if (!mounted) return;

                      final navContext = context;
                      if (completed) {
                        // ignore: use_build_context_synchronously
                        _showCompletedReviewOptions(navContext, lessonIds);
                      } else {
                        final reviewSessionId = 'review_${widget.categoryId}_${DateTime.now().millisecondsSinceEpoch}';
                        // ignore: use_build_context_synchronously
                        navContext.push(
                          '/loading',
                          extra: {
                            'duration': 13000,
                            'redirectPath': '/session/$reviewSessionId/cumulative-review',
                            'categoryId': widget.categoryId,
                            'lessonIds': lessonIds,
                            'isSandbox': false,
                          },
                        );
                      }
                    }
                  : null,
              child: Column(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 86,
                    height: 86,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: reviewUnlocked ? color.withValues(alpha: 0.12) : const Color(0xFFF1F5F9),
                      border: Border.all(color: color, width: 3),
                      boxShadow: reviewUnlocked
                          ? [BoxShadow(color: color.withValues(alpha: 0.2), blurRadius: 12, spreadRadius: 1)]
                          : null,
                    ),
                    child: Center(
                      child: Icon(icon, color: color, size: 36),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: 200,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: reviewUnlocked ? color.withValues(alpha: 0.2) : const Color(0xFFE2E8F0), width: 1.5),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          reviewLabel,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          unlockMessage,
                          style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                          textAlign: TextAlign.center,
                        ),
                        if (reviewUnlocked && isCompleted && _cumulativeReviewScore != null) ...[
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Score: ${_cumulativeReviewScore!.toStringAsFixed(0)}%',
                              style: const TextStyle(
                                fontSize: 10,
                                color: Color(0xFF10B981),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (lessonIds.isNotEmpty)
          Container(
            height: 50,
            width: 4,
            margin: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: reviewUnlocked ? color.withValues(alpha: 0.3) : const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
      ],
    );
  }

  void _showCompletedReviewOptions(BuildContext context, List<String> lessonIds) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          'Cumulative Review',
          style: TextStyle(
            fontFamily: 'Outfit',
            fontWeight: FontWeight.w900,
            color: Color(0xFF0F172A),
            fontSize: 20,
          ),
          textAlign: TextAlign.center,
        ),
        content: Text(
          _cumulativeReviewScore != null
              ? 'You completed this cumulative review with a score of ${_cumulativeReviewScore!.toStringAsFixed(0)}%. What would you like to do?'
              : 'You completed the cumulative review. What would you like to do?',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF64748B),
            height: 1.5,
          ),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        actions: [
          // View Score button
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await _viewCumulativeReviewScore();
            },
            icon: const Icon(Icons.visibility_rounded, size: 18),
            label: const Text('View Score'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF06A6FF),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              textStyle: const TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Retry button
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await _retryCumulativeReview(lessonIds);
            },
            icon: const Icon(Icons.replay_rounded, size: 18),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              textStyle: const TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _viewCumulativeReviewScore() async {
    double? masteryScore = await LocalStorageService.getCumulativeReviewScore(widget.categoryId) ?? _cumulativeReviewScore;
    int? masteredCount = await LocalStorageService.getCumulativeReviewMasteredCount(widget.categoryId);
    int? totalItems = await LocalStorageService.getCumulativeReviewTotalItems(widget.categoryId);
    final sessionId = await LocalStorageService.getCumulativeReviewSessionId(widget.categoryId) ?? 'review_${widget.categoryId}_${DateTime.now().millisecondsSinceEpoch}';
    final missedWordIds = await LocalStorageService.getCumulativeReviewMissedWordIds(widget.categoryId);
    List<Map<String, dynamic>> allWords = await LocalStorageService.getCumulativeReviewAllWords(widget.categoryId);

    if (allWords.isEmpty && mounted) {
      final lessons = Provider.of<LessonProvider>(context, listen: false);
      for (final lesson in lessons.lessons) {
        if (!lesson.isCompositeReview) {
          final batch = await lessons.loadVocabulary(lesson.lessonId);
          allWords.addAll(batch.map((w) => w.toJson()));
        }
      }
    }

    if (masteryScore == null && mounted) {
      try {
        final provider = Provider.of<LessonProvider>(context, listen: false);
        final dashboard = await provider.fetchDashboardProgress();
        if (dashboard != null) {
          final breakdowns = List<Map<String, dynamic>>.from(dashboard['categoryBreakdowns'] ?? []);
          final catMatch = breakdowns.firstWhere(
            (b) => b['categoryId']?.toString() == widget.categoryId,
            orElse: () => <String, dynamic>{},
          );
          if (catMatch.isNotEmpty && catMatch['cumulativeAccuracy'] != null) {
            masteryScore = (catMatch['cumulativeAccuracy'] as num).toDouble();
          }
        }
      } catch (e) {
        debugPrint('Fallback score error: $e');
      }
    }

    masteryScore ??= 100.0;
    final resolvedTotal = totalItems ?? allWords.length;
    final resolvedMastered = masteredCount ?? (missedWordIds.isNotEmpty
        ? (resolvedTotal - missedWordIds.length).clamp(0, resolvedTotal)
        : (resolvedTotal > 0 ? (resolvedTotal * (masteryScore / 100)).round() : 0));

    if (!mounted) return;

    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => MasteryResultScreen(
        sessionId: sessionId,
        categoryId: widget.categoryId,
        isSandbox: false,
        totalItems: resolvedTotal,
        masteredCount: resolvedMastered,
        missedWordIds: missedWordIds,
        allWords: allWords,
        masteryScore: masteryScore,
      ),
    ));
  }

  Future<void> _retryCumulativeReview(List<String> lessonIds) async {
    // IMPORTANT: Do NOT clear cumulative review completion state or score here!
    // Keeping the existing score allows the user to exit the retry at any time
    // and still view their previous score on the Lesson Path.

    if (!mounted) return;

    // Navigate to cumulative review with a fresh session
    final reviewSessionId = 'review_${widget.categoryId}_${DateTime.now().millisecondsSinceEpoch}';
    context.push(
      '/loading',
      extra: {
        'duration': 13000,
        'redirectPath': '/session/$reviewSessionId/cumulative-review',
        'categoryId': widget.categoryId,
        'lessonIds': lessonIds,
        'isSandbox': false,
      },
    );
  }
}
