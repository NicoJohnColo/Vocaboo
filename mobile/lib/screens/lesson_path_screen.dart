import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../models/lesson_model.dart';
import '../providers/lesson_provider.dart';
import '../services/local_storage_service.dart';
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
  Map<String, double> _localScores = {};

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
    for (final lesson in provider.lessons) {
      // Load for all lessons regardless of backend status — covers cases where
      // backend hasn't marked the lesson COMPLETED yet (e.g. animal category sync lag)
      final localScore = await LocalStorageService.getLessonScore(lesson.lessonId);
      if (localScore != null && localScore > 0) {
        scores[lesson.lessonId] = localScore;
      }
    }
    if (mounted) {
      setState(() {
        _localScores = scores;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = Provider.of<LessonProvider>(context);
    
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
    
    // Check if review is unlocked (all source lessons completed)
    final reviewUnlocked = hasReviewNode && sourceLessonIds.isNotEmpty && 
        sourceLessonIds.every((id) {
          final found = provider.lessons.cast<LessonModel?>().firstWhere(
            (l) => l?.lessonId == id,
            orElse: () => null,
          );
          return found != null && found.status == 'COMPLETED';
        });
    
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
        title: Text(
          widget.categoryName,
          style: const TextStyle(
            fontFamily: 'Outfit',
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await provider.loadLessons(widget.categoryId);
          await _loadLocalScores(provider);
        },
        child: SafeArea(
          child: provider.isLoading && provider.lessons.isEmpty
              ? const Center(child: CircularProgressIndicator())
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

                            Color nodeColor;
                            IconData nodeIcon;
                            bool isEnabled = false;

                            if (lesson.status == 'COMPLETED') {
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
                                          ? () {
                                              if (lesson.status == 'COMPLETED') {
                                                _showCompletedLessonOptions(lesson);
                                              } else {
                                                context.push(
                                                  '/lesson/${lesson.lessonId}/diagnostic',
                                                  extra: {
                                                    'categoryId': widget.categoryId,
                                                  },
                                                );
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
                                                  '${lesson.totalWordCount} words',
                                                  style: const TextStyle(
                                                    fontSize: 11,
                                                    color: Color(0xFF64748B),
                                                  ),
                                                ),
                                                if (lesson.status == 'COMPLETED' || _localScores.containsKey(lesson.lessonId)) ...[
                                                  Builder(
                                                    builder: (context) {
                                                      final displayScore = _localScores[lesson.lessonId] ?? lesson.masteryScore;
                                                      if (displayScore == null) return const SizedBox.shrink();
                                                      return Container(
                                                        margin: const EdgeInsets.only(top: 6),
                                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                        decoration: BoxDecoration(
                                                          color: nodeColor.withValues(alpha: 0.12),
                                                          borderRadius: BorderRadius.circular(8),
                                                        ),
                                                        child: Text(
                                                          'Score: ${displayScore.clamp(0.0, 100.0).toStringAsFixed(0)}%',
                                                          style: TextStyle(
                                                            fontSize: 10,
                                                            color: nodeColor,
                                                            fontWeight: FontWeight.bold,
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

    // Load vocabulary words for this lesson
    final words = await provider.loadVocabulary(lesson.lessonId);
    final allWords = words.map((w) => w.toJson()).toList();

    if (!mounted) return;

    // Load stored score data from local storage
    final localScore = await LocalStorageService.getLessonScore(lesson.lessonId);
    final scoreDetails = await LocalStorageService.getLessonScoreDetails(lesson.lessonId);

    final overallScore = localScore ?? lesson.masteryScore ?? 0.0;

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

    final sessionId = 'review_${lesson.lessonId}_${DateTime.now().millisecondsSinceEpoch}';

    context.push(
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

  Future<void> _retryLesson(LessonModel lesson) async {
    final provider = Provider.of<LessonProvider>(context, listen: false);

    // Attempt backend reset
    final success = await provider.resetLesson(lesson.lessonId);

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

    // Navigate to diagnostic as a fresh start
    context.push(
      '/lesson/${lesson.lessonId}/diagnostic',
      extra: {
        'categoryId': widget.categoryId,
      },
    );
  }

  Widget _buildReviewNode(BuildContext context, ThemeData theme, bool reviewUnlocked, List<String> lessonIds) {
    final color = reviewUnlocked ? const Color(0xFF10B981) : const Color(0xFFCBD5E1);
    final icon = reviewUnlocked ? Icons.auto_graph_rounded : Icons.lock_rounded;
    
    // Generate dynamic label based on lesson IDs
    String reviewLabel = 'Cumulative Review';
    
    String unlockMessage = reviewUnlocked 
        ? 'Tap to start mixed review' 
        : lessonIds.length == 2 
            ? 'Complete Lessons 1 and 2' 
            : 'Complete all source lessons';

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: reviewUnlocked
                  ? () async {
                      // Check if cumulative review has been completed
                      final isCompleted = await LocalStorageService.getCumulativeReviewCompleted(widget.categoryId);
                      
                      if (!mounted) return;
                      
                      if (isCompleted) {
                        _showCompletedReviewOptions(context, lessonIds);
                      } else {
                        final reviewSessionId = 'review_${widget.categoryId}_${DateTime.now().millisecondsSinceEpoch}';
                        context.push(
                          '/session/$reviewSessionId/cumulative-review',
                          extra: {
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
        content: const Text(
          'You completed the cumulative review. What would you like to do?',
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
    final masteryScore = await LocalStorageService.getCumulativeReviewScore(widget.categoryId);
    final masteredCount = await LocalStorageService.getCumulativeReviewMasteredCount(widget.categoryId);
    final totalItems = await LocalStorageService.getCumulativeReviewTotalItems(widget.categoryId);
    final sessionId = await LocalStorageService.getCumulativeReviewSessionId(widget.categoryId) ?? 'review_${widget.categoryId}_${DateTime.now().millisecondsSinceEpoch}';
    final missedWordIds = await LocalStorageService.getCumulativeReviewMissedWordIds(widget.categoryId);
    final allWords = await LocalStorageService.getCumulativeReviewAllWords(widget.categoryId);

    if (!mounted) return;

    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => MasteryResultScreen(
        sessionId: sessionId,
        categoryId: widget.categoryId,
        isSandbox: false,
        totalItems: totalItems ?? 0,
        masteredCount: masteredCount ?? 0,
        missedWordIds: missedWordIds,
        allWords: allWords,
        masteryScore: masteryScore,
      ),
    ));
  }

  Future<void> _retryCumulativeReview(List<String> lessonIds) async {
    // Clear cumulative review completion state
    await LocalStorageService.clearCumulativeReviewCompletion(widget.categoryId);

    if (!mounted) return;

    // Navigate to cumulative review with a fresh session
    final reviewSessionId = 'review_${widget.categoryId}_${DateTime.now().millisecondsSinceEpoch}';
    context.push(
      '/session/$reviewSessionId/cumulative-review',
      extra: {
        'categoryId': widget.categoryId,
        'lessonIds': lessonIds,
        'isSandbox': false,
      },
    );
  }
}
