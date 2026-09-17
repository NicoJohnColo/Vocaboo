import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import 'dart:math';

import '../core/motion/motion.dart';
import '../models/lesson_model.dart';
import '../providers/auth_provider.dart';
import '../providers/lesson_provider.dart';
import '../services/local_storage_service.dart';
import '../services/localization_service.dart';
import '../widgets/app_path_line.dart';
import '../widgets/lesson_popover_card.dart';
import '../widgets/app_3d_bottom_nav_bar.dart';
import '../widgets/cebuano_text_highlighter.dart';
import 'mastery_result_screen.dart';

class LessonPathScreen extends StatefulWidget {
  final String categoryId;
  final String categoryName;
  final String? classId;

  const LessonPathScreen({
    super.key,
    required this.categoryId,
    required this.categoryName,
    this.classId,
  });

  @override
  State<LessonPathScreen> createState() => _LessonPathScreenState();
}

class _LessonPathScreenState extends State<LessonPathScreen> {
  Map<String, int> _localMasteredCounts = {};
  Map<String, double> _localScores = {};
  final Map<String, Map<String, dynamic>> _activeSessionsByLessonId = {};
  double? _cumulativeReviewScore;
  bool _cumulativeReviewCompleted = false;

  // Requirement 1: No info card shown by default on load
  String? _selectedLessonId;

  // Requirement 3: Tracking newly unlocked lessons and locked shake
  final Set<String> _previouslyKnownLocked = {};
  final Set<String> _newlyUnlockedLessonIds = {};
  String? _shakingLockedLessonId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = Provider.of<LessonProvider>(context, listen: false);
      if (widget.classId != null && widget.classId!.isNotEmpty) {
        await provider.loadClassLessons(
          widget.classId!,
          categoryId: widget.categoryId,
        );
      } else {
        await provider.loadLessons(widget.categoryId);
      }
      await _loadLocalScores(provider);
    });
  }

  Future<void> _loadLocalScores(LessonProvider provider) async {
    final scores = <String, double>{};
    final masteredCounts = <String, int>{};

    for (final lesson in provider.lessons) {
      final localScore = await LocalStorageService.getLessonScore(
        lesson.lessonId,
      );
      if (localScore != null && localScore > 0) {
        scores[lesson.lessonId] = localScore;
      }

      final active = await LocalStorageService.getActiveLessonSession(
        lesson.lessonId,
      );
      if (active != null) {
        _activeSessionsByLessonId[lesson.lessonId] = active;
      } else {
        _activeSessionsByLessonId.remove(lesson.lessonId);
      }

      // lesson.masteredWordCount from the lesson list API is the authoritative
      // source — it counts words at MASTERED level across all modules.
      // Using it directly avoids mismatches with module-specific endpoints.
      masteredCounts[lesson.lessonId] = lesson.masteredWordCount;

      // Detect unlock state transitions
      final isNowUnlocked =
          lesson.status == 'UNLOCKED' || lesson.status == 'COMPLETED';
      if (_previouslyKnownLocked.contains(lesson.lessonId) && isNowUnlocked) {
        _newlyUnlockedLessonIds.add(lesson.lessonId);
      }
      if (lesson.status == 'LOCKED') {
        _previouslyKnownLocked.add(lesson.lessonId);
      }
    }

    LessonModel? compositeReviewLesson = provider.lessons
        .cast<LessonModel?>()
        .firstWhere(
          (lesson) => lesson?.isCompositeReview ?? false,
          orElse: () => null,
        );
    bool isReviewCompleted =
        await LocalStorageService.getCumulativeReviewCompleted(
          widget.categoryId,
        );
    double? reviewScore = await LocalStorageService.getCumulativeReviewScore(
      widget.categoryId,
    );
    if (reviewScore != null && reviewScore > 0) {
      isReviewCompleted = true;
    }
    if (!isReviewCompleted &&
        compositeReviewLesson != null &&
        compositeReviewLesson.status == 'COMPLETED') {
      isReviewCompleted = true;
      reviewScore ??= compositeReviewLesson.masteryScore;
    }

    // Recover score if available
    if (!isReviewCompleted || reviewScore == null) {
      try {
        final dashboard = await provider.fetchDashboardProgress();
        if (dashboard != null) {
          final breakdowns = List<Map<String, dynamic>>.from(
            dashboard['categoryBreakdowns'] ?? [],
          );
          final catMatch = breakdowns.firstWhere(
            (b) => b['categoryId']?.toString() == widget.categoryId,
            orElse: () => <String, dynamic>{},
          );
          if (catMatch.isNotEmpty && catMatch['cumulativeAccuracy'] != null) {
            final double acc = (catMatch['cumulativeAccuracy'] as num)
                .toDouble();
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
        debugPrint(
          'Failed to recover cumulative review score from dashboard: $e',
        );
      }
    }

    if (mounted) {
      setState(() {
        _localMasteredCounts = masteredCounts;
        _localScores = scores;
        _cumulativeReviewCompleted = isReviewCompleted;
        _cumulativeReviewScore = reviewScore;
      });
    }
  }

  Color _getCategoryThemeColor() {
    final lower = widget.categoryName.toLowerCase();
    if (lower.contains('food') || lower.contains('kitchen')) {
      return const Color(0xFF0EA5E9); // Vocaboo Primary Sky Blue
    }
    if (lower.contains('color')) return const Color(0xFF0284C7);
    if (lower.contains('body')) return const Color(0xFF0EA5E9);
    if (lower.contains('animal')) return const Color(0xFF10B981);
    if (lower.contains('place')) return const Color(0xFF0284C7);
    return const Color(0xFF0EA5E9);
  }

  void _handleNodeTap(LessonModel lesson, bool isLocked) {
    if (isLocked) {
      // Requirement 3: Locked node does nothing, triggers brief lock shake with haptic
      HapticFeedback.lightImpact();
      setState(() {
        _shakingLockedLessonId = lesson.lessonId;
      });
      return;
    }

    HapticFeedback.lightImpact();
    // Refresh active session status for the tapped lesson
    LocalStorageService.getActiveLessonSession(lesson.lessonId).then((active) {
      if (mounted) {
        setState(() {
          if (active != null) {
            _activeSessionsByLessonId[lesson.lessonId] = active;
          } else {
            _activeSessionsByLessonId.remove(lesson.lessonId);
          }
        });
      }
    });

    if (_selectedLessonId == lesson.lessonId) {
      _selectedLessonId = null;
      _handleStartLesson(lesson);
    } else {
      setState(() {
        _selectedLessonId = lesson.lessonId; // Single card open at a time
      });
    }
  }

  void _dismissPopover() {
    if (_selectedLessonId != null) {
      setState(() {
        _selectedLessonId = null;
      });
    }
  }

  Future<void> _handleStartLesson(LessonModel lesson) async {
    _dismissPopover();
    final activeSession = await LocalStorageService.getActiveLessonSession(
      lesson.lessonId,
    );
    if (activeSession != null && mounted) {
      _showResumePrompt(lesson, activeSession);
      return;
    }

    if (!mounted) return;

    final mastered = _localMasteredCounts[lesson.lessonId] ?? lesson.masteredWordCount;
    final total = lesson.totalWordCount;
    final isCompleted =
        total > 0 && mastered >= total && lesson.status == 'COMPLETED';
    if (isCompleted) {
      _showCompletedLessonOptions(lesson);
    } else {
      _showContextParagraphPrompt(lesson);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = Provider.of<LessonProvider>(context);

    // Find composite review lesson if present
    LessonModel? compositeReviewLesson = provider.lessons
        .cast<LessonModel?>()
        .firstWhere(
          (lesson) => lesson?.isCompositeReview ?? false,
          orElse: () => null,
        );

    // Construct local static review lesson if not in backend list
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
        status: (lesson1.status == 'COMPLETED' && lesson2.status == 'COMPLETED')
            ? 'UNLOCKED'
            : 'LOCKED',
        lessonType: 'COMPOSITE_REVIEW',
        sourceLessonIds: [lesson1.lessonId, lesson2.lessonId],
        compositeReviewAfterLessonId: lesson2.lessonId,
      );
    }

    final hasReviewNode = compositeReviewLesson != null;
    int reviewInsertIndex = 2;
    List<String> sourceLessonIds = [];

    if (hasReviewNode) {
      final afterLessonId = compositeReviewLesson.compositeReviewAfterLessonId;
      sourceLessonIds = compositeReviewLesson.sourceLessonIds ?? [];

      if (afterLessonId != null) {
        final afterLessonIndex = provider.lessons.indexWhere(
          (lesson) => lesson.lessonId == afterLessonId,
        );
        if (afterLessonIndex >= 0) {
          reviewInsertIndex = afterLessonIndex + 1;
        }
      } else {
        reviewInsertIndex = sourceLessonIds.length;
      }
    }

    final reviewUnlocked =
        _cumulativeReviewCompleted ||
        (hasReviewNode &&
            sourceLessonIds.isNotEmpty &&
            sourceLessonIds.every((id) {
              final found = provider.lessons.cast<LessonModel?>().firstWhere(
                (l) => l?.lessonId == id,
                orElse: () => null,
              );
              if (found == null) return false;
              if (found.status == 'COMPLETED') return true;
              final mastered = _localMasteredCounts[id] ?? 0;
              return mastered >= found.totalWordCount &&
                  found.totalWordCount > 0;
            }));

    final totalItems = provider.lessons.length + (hasReviewNode ? 1 : 0);
    final themeColor = _getCategoryThemeColor();

    // Determine current / next-up active lesson index (first unlocked & uncompleted)
    int currentActiveIndex = -1;
    for (int i = 0; i < provider.lessons.length; i++) {
      final l = provider.lessons[i];
      final mastered = _localMasteredCounts[l.lessonId] ?? l.masteredWordCount;
      final total = l.totalWordCount;
      final isDone =
          l.status == 'COMPLETED' ||
          (total > 0 && mastered >= total);
      if (l.status == 'UNLOCKED' && !isDone) {
        currentActiveIndex = i;
        break;
      }
    }
    if (currentActiveIndex == -1 &&
        provider.lessons.isNotEmpty &&
        provider.lessons[0].status == 'UNLOCKED') {
      currentActiveIndex = 0;
    }
    int totalMasteredWords = 0;
    int totalCategoryWords = 0;
    for (final l in provider.lessons) {
      final m = _localMasteredCounts[l.lessonId] ?? l.masteredWordCount;
      totalMasteredWords += m;
      totalCategoryWords += l.totalWordCount;
    }
    if (totalCategoryWords == 0) totalCategoryWords = provider.lessons.fold(0, (sum, l) => sum + l.totalWordCount);

    return Scaffold(
      backgroundColor: const Color(0xFFFBF8FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFFFFF),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: Center(
          child: Container(
            margin: const EdgeInsets.only(left: 12),
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: IconButton(
              icon: const Icon(
                Icons.arrow_back_rounded,
                color: Color(0xFF1E293B),
                size: 20,
              ),
              onPressed: () => Navigator.of(context).canPop()
                  ? Navigator.of(context).pop()
                  : context.go(widget.classId != null ? '/classes' : '/home'),
            ),
          ),
        ),
        title: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFFE0F2FE),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                widget.classId != null
                    ? Icons.school_rounded
                    : Icons.menu_book_rounded,
                color: const Color(0xFF0284C7),
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.categoryName,
                    style: AppTypography.baloo2(
                      fontWeight: FontWeight.w800,
                      fontSize: 20,
                      color: const Color(0xFF00B4D8),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (widget.classId != null)
                    Text(
                      'Classroom Lessons',
                      style: AppTypography.nunito(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0284C7),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFFDE047), width: 1.2),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('⭐', style: TextStyle(fontSize: 12)),
                      const SizedBox(width: 4),
                      Text(
                        '$totalMasteredWords / $totalCategoryWords',
                        style: AppTypography.baloo2(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF713F12),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    'Mastered',
                    style: AppTypography.nunito(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF15803D),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Background subtle pastel sparkles and confetti shapes (no mascot images)
          const _BackgroundSparkles(),

          // Main content
          GestureDetector(
            // Requirement 1: Tapping anywhere dismisses open card
            onTap: _dismissPopover,
            behavior: HitTestBehavior.translucent,
            child: AppRefreshIndicator(
              onRefresh: () async {
                if (widget.classId != null && widget.classId!.isNotEmpty) {
                  await provider.loadClassLessons(widget.classId!);
                } else {
                  await provider.loadLessons(widget.categoryId);
                }
                await _loadLocalScores(provider);
              },
              child: SafeArea(
                child: provider.isLoading && provider.lessons.isEmpty
                    ? ListView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24.0,
                          vertical: 16.0,
                        ),
                        itemCount: 3,
                        itemBuilder: (_, _) => Padding(
                          padding: const EdgeInsets.only(bottom: 24.0),
                          child: AppShimmer.card(height: 120),
                        ),
                      )
                    : provider.lessonsError != null
                    ? Center(
                        child: Text(
                          provider.lessonsError!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      )
                    : provider.lessons.isEmpty
                    ? Center(
                        child: Text(
                          widget.classId != null
                              ? 'No lessons published for this classroom yet.'
                              : 'No lessons available in this category.',
                          style: const TextStyle(color: Color(0xFF94A3B8)),
                        ),
                      )
                    : ListView.builder(
                        // Requirement 4: Tightened vertical spacing near top & throughout
                        padding: const EdgeInsets.fromLTRB(
                          16.0,
                          12.0,
                          16.0,
                          36.0,
                        ),
                        itemCount: totalItems,
                        itemBuilder: (context, index) {
                          final isLast = index == totalItems - 1;

                          // Calculate alignment of this node and the next node to draw smooth interconnecting path
                          final PathNodeAlignment currentAlignment;
                          if (hasReviewNode && index == reviewInsertIndex) {
                            currentAlignment = PathNodeAlignment.center;
                          } else {
                            final lIndex =
                                hasReviewNode && index > reviewInsertIndex
                                ? index - 1
                                : index;
                            currentAlignment = (lIndex % 2 == 0)
                                ? PathNodeAlignment.left
                                : PathNodeAlignment.right;
                          }

                          PathNodeAlignment nextAlignment =
                              PathNodeAlignment.center;
                          bool nextUnlocked = false;
                          if (!isLast) {
                            if (hasReviewNode &&
                                (index + 1) == reviewInsertIndex) {
                              nextAlignment = PathNodeAlignment.center;
                              nextUnlocked = reviewUnlocked;
                            } else {
                              final nextLIndex =
                                  hasReviewNode &&
                                      (index + 1) > reviewInsertIndex
                                  ? (index + 1) - 1
                                  : (index + 1);
                              nextAlignment = (nextLIndex % 2 == 0)
                                  ? PathNodeAlignment.left
                                  : PathNodeAlignment.right;
                              final nextLesson = provider.lessons[nextLIndex];
                              final nextMastered = _localMasteredCounts[nextLesson.lessonId] ??
                                  nextLesson.masteredWordCount;
                              final nextTotal = nextLesson.totalWordCount;
                              final nextIsDone =
                                  nextLesson.status == 'COMPLETED' ||
                                  (nextTotal > 0 && nextMastered >= nextTotal);
                              nextUnlocked =
                                  nextLesson.status == 'UNLOCKED' || nextIsDone;
                            }
                          }

                          if (hasReviewNode && index == reviewInsertIndex) {
                            return _buildReviewNode(
                              context: context,
                              theme: theme,
                              reviewUnlocked: reviewUnlocked,
                              lessonIds: sourceLessonIds,
                              isLast: isLast,
                              fromAlignment: currentAlignment,
                              toAlignment: nextAlignment,
                              isPathUnlocked: nextUnlocked,
                            );
                          }

                          final lessonIndex =
                              hasReviewNode && index > reviewInsertIndex
                              ? index - 1
                              : index;
                          final lesson = provider.lessons[lessonIndex];

                          final mastered = _localMasteredCounts[lesson.lessonId] ?? lesson.masteredWordCount;
                          final total = lesson.totalWordCount;
                          final isCompleted =
                              total > 0 && mastered >= total && lesson.status == 'COMPLETED';
                          final isUnlocked =
                              lesson.status == 'UNLOCKED' || isCompleted;
                          final isLocked = !isUnlocked;
                          final isCurrentActive =
                              lessonIndex == currentActiveIndex && !isCompleted;
                          final isNewlyUnlocked = _newlyUnlockedLessonIds
                              .contains(lesson.lessonId);

                          // Stagger path layout: alternate left / right
                          final isLeft = lessonIndex % 2 == 0;

                          return _buildNumberedNodeItem(
                            context: context,
                            lesson: lesson,
                            lessonIndex: lessonIndex,
                            isLeft: isLeft,
                            isLocked: isLocked,
                            isCompleted: isCompleted,
                            isCurrentActive: isCurrentActive,
                            isNewlyUnlocked: isNewlyUnlocked,
                            isLast: isLast,
                            mastered: mastered,
                            total: total,
                            themeColor: themeColor,
                            fromAlignment: currentAlignment,
                            toAlignment: nextAlignment,
                            isPathUnlocked: nextUnlocked,
                          );
                        },
                      ),
              ),
            ),
          ), // closes GestureDetector
        ], // closes Stack children
      ), // closes Stack
      bottomNavigationBar: const App3DBottomNavBar(currentPath: '/category'),
    );
  }

  Widget _buildNumberedNodeItem({
    required BuildContext context,
    required LessonModel lesson,
    required int lessonIndex,
    required bool isLeft,
    required bool isLocked,
    required bool isCompleted,
    required bool isCurrentActive,
    required bool isNewlyUnlocked,
    required bool isLast,
    required int mastered,
    int? total,
    required Color themeColor,
    required PathNodeAlignment fromAlignment,
    required PathNodeAlignment toAlignment,
    required bool isPathUnlocked,
  }) {
    final isSelected = _selectedLessonId == lesson.lessonId;
    final isShaking = _shakingLockedLessonId == lesson.lessonId;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6.0),
          child: Stack(
            clipBehavior: Clip.none,
            alignment: isLeft ? Alignment.centerLeft : Alignment.centerRight,
            children: [
              // Main Node Column (3D Disc + Progress Card)
              Row(
                mainAxisAlignment: isLeft
                    ? MainAxisAlignment.start
                    : MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (!isLeft) const Spacer(),

                  Padding(
                    padding: EdgeInsets.only(
                      left: isLeft ? 16.0 : 0.0,
                      right: !isLeft ? 16.0 : 0.0,
                    ),
                    child: _LockedShakeWidget(
                      isShaking: isShaking,
                      onComplete: () {
                        if (mounted) {
                          setState(() => _shakingLockedLessonId = null);
                        }
                      },
                      child: _UnlockTransitionWidget(
                        isNewlyUnlocked: isNewlyUnlocked,
                        onTransitionComplete: () {
                          if (mounted) {
                            setState(() {
                              _newlyUnlockedLessonIds.remove(lesson.lessonId);
                            });
                          }
                        },
                        child: _3DPathNodeWidget(
                          lesson: lesson,
                          lessonIndex: lessonIndex,
                          isLeft: isLeft,
                          isLocked: isLocked,
                          isCompleted: isCompleted,
                          isCurrentActive: isCurrentActive,
                          mastered: mastered,
                          totalOverride: total,
                          onTap: () => _handleNodeTap(lesson, isLocked),
                          onStart: () => _handleStartLesson(lesson),
                          onRefresh:
                              (!isLocked && (isCompleted || mastered > 0))
                              ? () => _handleStartLesson(lesson)
                              : null,
                        ),
                      ),
                    ),
                  ),

                  if (isLeft) const Spacer(),
                ],
              ),

              // Popover Card positioned adjacent to the 3D disc
              if (isSelected && !isLocked)
                Positioned(
                  left: isLeft ? 136.0 : null,
                  right: !isLeft ? 136.0 : null,
                  top: 0,
                  child: LessonPopoverCard(
                    categoryName: widget.categoryName,
                    totalWordCount: lesson.totalWordCount,
                    description: lesson.lessonDescription,
                    buttonText:
                        _activeSessionsByLessonId.containsKey(lesson.lessonId)
                        ? 'Resume'
                        : (isCompleted ? 'Review' : 'Start'),
                    className: lesson.className,
                    backgroundColor: themeColor,
                    isTailOnLeft: isLeft,
                    score: isCompleted ? _localScores[lesson.lessonId] : null,
                    masteredCount: mastered,
                    width: (MediaQuery.of(context).size.width - 150).clamp(
                      180.0,
                      240.0,
                    ),
                    onStart: () => _handleStartLesson(lesson),
                    onDismiss: _dismissPopover,
                  ),
                ),
            ],
          ),
        ),

        // Connecting highway ribbon road with white dashed center stripe
        if (!isLast)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2.0),
            child: AppPathLine(
              isUnlocked: isPathUnlocked,
              fromAlignment: fromAlignment,
              toAlignment: toAlignment,
              solidColor: (lessonIndex % 2 == 0)
                  ? const Color(0xFFDDD6FE) // soft lavender ribbon
                  : const Color(0xFFBAE6FD), // soft sky-blue ribbon
              dashedColor: const Color(0xFFE2E8F0),
              height: 56.0,
              width: 15.0,
              nodeCenterOffset: 96.0,
            ),
          ),
      ],
    );
  }

  Widget _buildReviewNode({
    required BuildContext context,
    required ThemeData theme,
    required bool reviewUnlocked,
    required List<String> lessonIds,
    required bool isLast,
    required PathNodeAlignment fromAlignment,
    required PathNodeAlignment toAlignment,
    required bool isPathUnlocked,
  }) {
    final bool isCompleted =
        _cumulativeReviewCompleted || _cumulativeReviewScore != null;
    final color = isCompleted
        ? const Color(0xFF7C3AED)
        : (reviewUnlocked ? const Color(0xFF6366F1) : const Color(0xFFB197FC));
    final icon = isCompleted
        ? Icons.check_circle_rounded
        : (reviewUnlocked ? Icons.auto_awesome_rounded : Icons.lock_rounded);

    final unlockMessage = isCompleted
        ? 'Tap to view score or retry'
        : (reviewUnlocked
              ? 'Tap to start mixed review'
              : (lessonIds.length == 2
                    ? 'Complete Lessons 1 and 2'
                    : 'Complete all source lessons'));

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: reviewUnlocked
              ? () async {
                  bool completed =
                      _cumulativeReviewCompleted ||
                      _cumulativeReviewScore != null ||
                      await LocalStorageService.getCumulativeReviewCompleted(
                        widget.categoryId,
                      ) ||
                      ((await LocalStorageService.getCumulativeReviewScore(
                            widget.categoryId,
                          )) !=
                          null);

                  if (!mounted) return;
                  final navContext = context;
                  if (completed) {
                    _showCompletedReviewOptions(navContext, lessonIds);
                  } else {
                    final reviewSessionId =
                        'review_${widget.categoryId}_${DateTime.now().millisecondsSinceEpoch}';
                    navContext.push(
                      '/session/$reviewSessionId/cumulative-review',
                      extra: {
                        'categoryId': widget.categoryId,
                        'lessonIds': lessonIds,
                        'isSandbox': false,
                      },
                    );
                  }
                }
              : () {
                  HapticFeedback.lightImpact();
                },
          child: Column(
            children: [
              // Circular 3D Review Node with tactile pushdown
              _Review3DDisc(
                reviewUnlocked: reviewUnlocked,
                isCompleted: isCompleted,
                color: color,
                icon: icon,
              ),
              const SizedBox(height: 10),
              // Cumulative Review Card
              Container(
                width: 190,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: reviewUnlocked
                        ? color.withValues(alpha: 0.30)
                        : const Color(0xFFE9D5FF),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      'Cumulative Review',
                      style: AppTypography.baloo2(
                        fontWeight: FontWeight.w800,
                        fontSize: 13.5,
                        color: const Color(0xFF0F172A),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      unlockMessage,
                      style: AppTypography.nunito(
                        fontSize: 11,
                        color: const Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (reviewUnlocked &&
                        isCompleted &&
                        _cumulativeReviewScore != null) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFF10B981,
                          ).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Accuracy: ${_cumulativeReviewScore!.toStringAsFixed(0)}%',
                          style: AppTypography.baloo2(
                            fontSize: 10.5,
                            color: const Color(0xFF10B981),
                            fontWeight: FontWeight.w800,
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
        if (!isLast)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2.0),
            child: AppPathLine(
              isUnlocked: isPathUnlocked,
              fromAlignment: fromAlignment,
              toAlignment: toAlignment,
              solidColor: const Color(0xFFDDD6FE),
              dashedColor: const Color(0xFFE2E8F0),
              height: 56.0,
              width: 15.0,
              nodeCenterOffset: 96.0,
            ),
          ),
      ],
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
          style: AppTypography.baloo2(
            fontWeight: FontWeight.w800,
            color: const Color(0xFF0F172A),
            fontSize: 20,
          ),
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'You completed this lesson. What would you like to do?',
              textAlign: TextAlign.center,
              style: AppTypography.nunito(
                fontSize: 14,
                color: const Color(0xFF64748B),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () async {
                Navigator.of(ctx).pop();
                await _viewLessonScore(lesson);
              },
              icon: const Icon(Icons.visibility_rounded, size: 18),
              label: Text(
                'View Score',
                style: AppTypography.baloo2(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF06A6FF),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(ctx).pop();
                _showFocusPromptAndStartLesson(lesson);
              },
              icon: const Icon(Icons.psychology_rounded, size: 18),
              label: Text(
                'Practice',
                style: AppTypography.baloo2(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B5CF6),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () async {
                Navigator.of(ctx).pop();
                await _retryLesson(lesson);
              },
              icon: const Icon(Icons.replay_rounded, size: 18),
              label: Text(
                'Retry',
                style: AppTypography.baloo2(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _viewLessonScore(LessonModel lesson) async {
    final provider = Provider.of<LessonProvider>(context, listen: false);
    final navContext = context;

    final words = await provider.loadVocabulary(lesson.lessonId);
    final allWords = words.map((w) => w.toJson()).toList();

    if (!mounted) return;

    final localScore = await LocalStorageService.getLessonScore(
      lesson.lessonId,
    );
    final scoreDetails = await LocalStorageService.getLessonScoreDetails(
      lesson.lessonId,
    );

    double overallScore =
        (lesson.masteryScore != null && lesson.masteryScore! > 0.0)
        ? lesson.masteryScore!
        : (localScore != null && localScore > 0.0 ? localScore : 0.0);
    try {
      final summary = await provider.fetchWordMasterySummary(lesson.lessonId);
      if (summary.isNotEmpty) {
        final wordAccuracies = summary
            .map((item) => (item['accuracy'] as num?)?.toDouble())
            .whereType<double>()
            .toList();
        if (wordAccuracies.isNotEmpty) {
          overallScore =
              (wordAccuracies.reduce((a, b) => a + b) / wordAccuracies.length)
                  .clamp(0.0, 100.0);
        }
      }
    } catch (_) {}

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
        failedSentenceWordIds = Set<String>.from(
          failedRaw.map((e) => e.toString()),
        );
      }
    }

    for (final word in words) {
      wordPronunciationCorrect.putIfAbsent(word.wordId, () => false);
      wordPronunciationAttempts.putIfAbsent(word.wordId, () => 0);
    }

    if (!mounted) return;

    final sessionId = const Uuid().v4();
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
        'classroomId': widget.classId,
        'className': lesson.className,
      },
    );
  }

  void _showResumePrompt(
    LessonModel lesson,
    Map<String, dynamic> activeSession,
  ) {
    final sessionPos = activeSession['posFocus'] as String?;
    final posLabel = (sessionPos != null && sessionPos != 'ALL')
        ? ' ($sessionPos focus)'
        : '';

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        titlePadding: const EdgeInsets.fromLTRB(20, 16, 12, 0),
        title: Row(
          children: [
            Expanded(
              child: Text(
                'Resume Lesson$posLabel',
                style: AppTypography.baloo2(
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0F172A),
                  fontSize: 20,
                ),
                textAlign: TextAlign.left,
              ),
            ),
            IconButton(
              icon: const Icon(
                Icons.close_rounded,
                color: Color(0xFF94A3B8),
                size: 22,
              ),
              onPressed: () => Navigator.of(
                ctx,
              ).pop(), // Close dialog without clearing active session!
            ),
          ],
        ),
        content: Text(
          'You have an active session for ${lesson.lessonTitle}$posLabel. Would you like to resume where you left off or start over?',
          textAlign: TextAlign.left,
          style: AppTypography.nunito(
            fontSize: 14,
            color: const Color(0xFF64748B),
            height: 1.5,
          ),
        ),
        actionsAlignment: MainAxisAlignment.end,
        actions: [
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFFFCA5A5)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            onPressed: () async {
              Navigator.of(ctx).pop();
              await LocalStorageService.clearActiveLessonSession(
                lesson.lessonId,
              );
              final sid = activeSession['sessionId'] as String?;
              if (sid != null) {
                await LocalStorageService.clearModuleProgressSnapshot(sid);
                await LocalStorageService.clearPracticeSessionState(sid);
              }
              if (mounted) {
                setState(() {
                  _activeSessionsByLessonId.remove(lesson.lessonId);
                });
                _showContextParagraphPrompt(lesson);
              }
            },
            child: Text(
              'Restart / Start Over',
              style: AppTypography.baloo2(
                fontWeight: FontWeight.w700,
                color: const Color(0xFFEF4444),
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF06A6FF),
              foregroundColor: Colors.white,
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            ),
            icon: const Icon(Icons.play_arrow_rounded, size: 18),
            label: Text(
              'Resume Session',
              style: AppTypography.baloo2(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: Colors.white,
              ),
            ),
            onPressed: () async {
              Navigator.of(ctx).pop();
              final auth = Provider.of<AuthProvider>(context, listen: false);
              final provider = Provider.of<LessonProvider>(
                context,
                listen: false,
              );

              // Maintain exact posFocus of the session
              if (sessionPos != null && sessionPos.isNotEmpty) {
                await auth.updatePosFocus(sessionPos);
              }

              // Preserve exact words from session, or load filtered words
              List<Map<String, dynamic>> words = [];
              if (activeSession['allWords'] != null &&
                  (activeSession['allWords'] as List).isNotEmpty) {
                words = List<Map<String, dynamic>>.from(
                  activeSession['allWords'],
                );
              } else {
                final loaded = await provider.loadVocabulary(
                  lesson.lessonId,
                  partOfSpeech: (sessionPos != null && sessionPos != 'ALL')
                      ? sessionPos
                      : null,
                );
                words = loaded.map((w) => w.toJson()).toList();
              }

              final known =
                  (activeSession['knownWordIds'] as List<dynamic>?)
                      ?.map((e) => e.toString())
                      .toList() ??
                  [];
              final unknown =
                  (activeSession['unknownWordIds'] as List<dynamic>?)
                      ?.map((e) => e.toString())
                      .toList() ??
                  [];

              if (!mounted) return;
              final savedRoute =
                  (activeSession['redirectPath'] as String?)?.replaceFirst(
                    '/vocab-intro',
                    '/introduction',
                  ) ??
                  '/session/${activeSession['sessionId']}/introduction';
              context.push(
                savedRoute,
                extra: {
                  'sessionId': activeSession['sessionId'],
                  'lessonId': lesson.lessonId,
                  'categoryId': widget.categoryId,
                  'lessonTitle': lesson.lessonTitle,
                  'allWords': words,
                  'knownWordIds': known,
                  'unknownWordIds': unknown,
                  'isSandbox': false,
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _retryLesson(LessonModel lesson) async {
    final provider = Provider.of<LessonProvider>(context, listen: false);
    await provider.resetLesson(lesson.lessonId);
    await LocalStorageService.saveLessonScore(lesson.lessonId, 0.0);
    await LocalStorageService.clearLessonScoreDetails(lesson.lessonId);

    if (!mounted) return;
    await provider.loadLessons(widget.categoryId);
    await _loadLocalScores(provider);

    if (!mounted) return;
    await provider.loadVocabulary(lesson.lessonId);

    if (!mounted) return;
    _showContextParagraphPrompt(lesson);
  }

  void _showContextParagraphPrompt(LessonModel lesson) {
    if (lesson.contextParagraph == null ||
        lesson.contextParagraph!.trim().isEmpty) {
      _showFocusPromptAndStartLesson(lesson);
      return;
    }

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final pref = auth.learner?.languagePreference;
    final provider = Provider.of<LessonProvider>(context, listen: false);
    
    // Collect all words for highlighting (both Cebuano and English to cover context paragraphs in either language)
    final highlightWords = provider.words.expand((w) => [w.cebuanoMeaning, w.englishWord]).join(', ');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          LocalizationService.translate(pref, 'lesson_context_title'),
          style: AppTypography.baloo2(
            fontWeight: FontWeight.w800,
            color: const Color(0xFF0F172A),
            fontSize: 20,
          ),
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              LocalizationService.translate(pref, 'lesson_context_desc'),
              textAlign: TextAlign.center,
              style: AppTypography.nunito(
                fontSize: 14,
                color: const Color(0xFF64748B),
                height: 1.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: CebuanoTextHighlighter(
                text: '"${lesson.contextParagraph}"',
                highlightWord: highlightWords,
                style: AppTypography.nunito(
                  fontSize: 16,
                  color: const Color(0xFF334155),
                  fontStyle: FontStyle.italic,
                  height: 1.5,
                ),
                highlightStyle: AppTypography.nunito(
                  fontSize: 16,
                  color: const Color(0xFF0369A1),
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w900,
                  height: 1.5,
                  decoration: TextDecoration.underline,
                  decorationColor: const Color(0xFF0284C7),
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                _showFocusPromptAndStartLesson(lesson);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0EA5E9),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                'CONTINUE',
                style: AppTypography.baloo2(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFocusPromptAndStartLesson(LessonModel lesson) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final pref = auth.learner?.languagePreference;
    String selectedFocus = 'ALL';

    final options = [
      {
        'key': 'ALL',
        'label': LocalizationService.translate(pref, 'focus_all_words'),
        'desc': LocalizationService.translate(pref, 'focus_all_words_desc'),
      },
      {
        'key': 'NOUN',
        'label': LocalizationService.translate(pref, 'focus_nouns'),
        'desc': LocalizationService.translate(pref, 'focus_nouns_desc'),
      },
      {
        'key': 'VERB',
        'label': LocalizationService.translate(pref, 'focus_verbs'),
        'desc': LocalizationService.translate(pref, 'focus_verbs_desc'),
      },
      {
        'key': 'ADJECTIVE',
        'label': LocalizationService.translate(pref, 'focus_adjectives'),
        'desc': LocalizationService.translate(pref, 'focus_adjectives_desc'),
      },
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (bottomSheetContext, setModalState) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
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
                  Text(
                    LocalizationService.translate(pref, 'pos_focus_title'),
                    style: AppTypography.baloo2(
                      fontWeight: FontWeight.w800,
                      fontSize: 20,
                      color: const Color(0xFF0F172A),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    lesson.lessonTitle,
                    style: AppTypography.nunito(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: const Color(0xFF64748B),
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
                        color: isSelected
                            ? const Color(0xFFE0F2FE)
                            : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF0EA5E9)
                              : const Color(0xFFE2E8F0),
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
                            style: AppTypography.baloo2(
                              fontWeight: isSelected
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                opt['desc'] as String,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Builder(
                                builder: (ctx) {
                                  final total = key == 'ALL'
                                      ? lesson.totalWordCount
                                      : (lesson.posTotalWordCounts[key] ??
                                            (lesson.totalWordCount > 0
                                                ? lesson.totalWordCount ~/ 3
                                                : 4));
                                  final mastered = key == 'ALL'
                                      ? (_localMasteredCounts[lesson
                                                .lessonId] ??
                                            lesson.masteredWordCount)
                                      : (lesson.posMasteredWordCounts[key] ??
                                            0);
                                  final isDone = mastered >= total && total > 0;

                                  return Row(
                                    children: [
                                      Text(
                                        '${LocalizationService.translate(pref, 'mastered')}: $mastered / $total ${LocalizationService.translate(pref, 'words_count')}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: isDone
                                              ? const Color(0xFF10B981)
                                              : const Color(0xFF64748B),
                                        ),
                                      ),
                                      if (isDone) ...[
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 1,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFECFDF5),
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                            border: Border.all(
                                              color: const Color(0xFF10B981),
                                              width: 0.8,
                                            ),
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
                                      ] else if (mastered > 0) ...[
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 1,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFEFF6FF),
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                            border: Border.all(
                                              color: const Color(0xFF93C5FD),
                                              width: 0.8,
                                            ),
                                          ),
                                          child: Text(
                                            'In Progress (${total - mastered} left)',
                                            style: const TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w700,
                                              color: Color(0xFF1D4ED8),
                                            ),
                                          ),
                                        ),
                                      ] else ...[
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 1,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFF1F5F9),
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                            border: Border.all(
                                              color: const Color(0xFFCBD5E1),
                                              width: 0.8,
                                            ),
                                          ),
                                          child: const Text(
                                            'Not Started',
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w700,
                                              color: Color(0xFF64748B),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  );
                                },
                              ),
                            ],
                          ),
                          trailing: isSelected
                              ? const Icon(
                                  Icons.check_circle_rounded,
                                  color: Color(0xFF0EA5E9),
                                )
                              : const Icon(
                                  Icons.radio_button_unchecked_rounded,
                                  color: Color(0xFF94A3B8),
                                ),
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
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    onPressed: () async {
                      final total = selectedFocus == 'ALL'
                          ? lesson.totalWordCount
                          : (lesson.posTotalWordCounts[selectedFocus] ??
                                (lesson.totalWordCount > 0
                                    ? lesson.totalWordCount ~/ 3
                                    : 4));
                      final mastered = selectedFocus == 'ALL'
                          ? (_localMasteredCounts[lesson.lessonId] ??
                                lesson.masteredWordCount)
                          : (lesson.posMasteredWordCounts[selectedFocus] ?? 0);
                      final isDone = mastered >= total && total > 0;

                      if (selectedFocus != 'ALL' && isDone) {
                        final posLabel =
                            options.firstWhere(
                              (o) => o['key'] == selectedFocus,
                            )['label'] ??
                            selectedFocus;
                        final confirmRestart = await showDialog<bool>(
                          context: context,
                          builder: (dialogCtx) => AlertDialog(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            title: Text(
                              'Restart $posLabel?',
                              style: AppTypography.baloo2(
                                fontWeight: FontWeight.w800,
                                fontSize: 20,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                            content: Text(
                              'You have already mastered all words in $posLabel for this lesson. Would you like to restart and practice them again?',
                              style: AppTypography.nunito(
                                fontSize: 14,
                                color: const Color(0xFF475569),
                                height: 1.4,
                              ),
                            ),
                            actionsPadding: const EdgeInsets.fromLTRB(
                              16,
                              0,
                              16,
                              16,
                            ),
                            actions: [
                              OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFF64748B),
                                  side: const BorderSide(
                                    color: Color(0xFFCBD5E1),
                                    width: 1.5,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 10,
                                  ),
                                ),
                                onPressed: () =>
                                    Navigator.of(dialogCtx).pop(false),
                                child: Text(
                                  LocalizationService.translate(pref, 'cancel'),
                                  style: AppTypography.baloo2(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF0EA5E9),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 10,
                                  ),
                                  elevation: 0,
                                ),
                                onPressed: () =>
                                    Navigator.of(dialogCtx).pop(true),
                                child: Text(
                                  'Restart & Practice',
                                  style: AppTypography.baloo2(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );

                        if (confirmRestart != true) {
                          return;
                        }

                        final lessonProvider = Provider.of<LessonProvider>(
                          context,
                          listen: false,
                        );
                        await lessonProvider.resetLessonProgress(
                          lesson.lessonId,
                          partOfSpeech: selectedFocus,
                        );
                        await LocalStorageService.clearActiveLessonSession(
                          lesson.lessonId,
                        );
                      }

                      if (!ctx.mounted) return;
                      Navigator.of(ctx).pop();
                      await auth.updatePosFocus(selectedFocus);
                      if (mounted) {
                        context.push(
                          '/lesson/${lesson.lessonId}/diagnostic',
                          extra: {
                            'categoryId': widget.categoryId,
                            'lessonTitle': lesson.lessonTitle,
                          },
                        );
                      }
                    },
                    child: Text(
                      LocalizationService.translate(pref, 'start_lesson'),
                      style: AppTypography.baloo2(
                        fontWeight: FontWeight.w800,
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

  void _showCompletedReviewOptions(
    BuildContext context,
    List<String> lessonIds,
  ) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'Cumulative Review',
          style: AppTypography.baloo2(
            fontWeight: FontWeight.w800,
            color: const Color(0xFF0F172A),
            fontSize: 20,
          ),
          textAlign: TextAlign.center,
        ),
        content: Text(
          _cumulativeReviewScore != null
              ? 'You completed this cumulative review with a score of ${_cumulativeReviewScore!.toStringAsFixed(0)}%. What would you like to do?'
              : 'You completed the cumulative review. What would you like to do?',
          textAlign: TextAlign.center,
          style: AppTypography.nunito(
            fontSize: 14,
            color: const Color(0xFF64748B),
            height: 1.5,
          ),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        actions: [
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await _viewCumulativeReviewScore();
            },
            icon: const Icon(Icons.visibility_rounded, size: 18),
            label: Text(
              'View Score',
              style: AppTypography.baloo2(
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF06A6FF),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await _retryCumulativeReview(lessonIds);
            },
            icon: const Icon(Icons.replay_rounded, size: 18),
            label: Text(
              'Retry',
              style: AppTypography.baloo2(
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _viewCumulativeReviewScore() async {
    double? masteryScore =
        await LocalStorageService.getCumulativeReviewScore(widget.categoryId) ??
        _cumulativeReviewScore;
    int? masteredCount =
        await LocalStorageService.getCumulativeReviewMasteredCount(
          widget.categoryId,
        );
    int? totalItems = await LocalStorageService.getCumulativeReviewTotalItems(
      widget.categoryId,
    );
    final sessionId =
        await LocalStorageService.getCumulativeReviewSessionId(
          widget.categoryId,
        ) ??
        'review_${widget.categoryId}_${DateTime.now().millisecondsSinceEpoch}';
    final missedWordIds =
        await LocalStorageService.getCumulativeReviewMissedWordIds(
          widget.categoryId,
        );
    List<Map<String, dynamic>> allWords =
        await LocalStorageService.getCumulativeReviewAllWords(
          widget.categoryId,
        );

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
          final breakdowns = List<Map<String, dynamic>>.from(
            dashboard['categoryBreakdowns'] ?? [],
          );
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

    final resolvedTotal = totalItems ?? allWords.length;
    final resolvedMastered =
        masteredCount ??
        (missedWordIds.isNotEmpty
            ? (resolvedTotal - missedWordIds.length).clamp(0, resolvedTotal)
            : 0);

    if (masteryScore == null) {
      if (resolvedTotal > 0 && resolvedMastered > 0) {
        masteryScore = (resolvedMastered / resolvedTotal * 100.0).clamp(0.0, 100.0);
      } else {
        masteryScore = 0.0;
      }
    }

    if (!mounted) return;

    Navigator.of(context).push(
      MaterialPageRoute(
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
      ),
    );
  }

  Future<void> _retryCumulativeReview(List<String> lessonIds) async {
    if (!mounted) return;

    final reviewSessionId =
        'review_${widget.categoryId}_${DateTime.now().millisecondsSinceEpoch}';
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

/// Shake animation for locked nodes when tapped
class _LockedShakeWidget extends StatefulWidget {
  final Widget child;
  final bool isShaking;
  final VoidCallback? onComplete;

  const _LockedShakeWidget({
    required this.child,
    required this.isShaking,
    this.onComplete,
  });

  @override
  State<_LockedShakeWidget> createState() => _LockedShakeWidgetState();
}

class _LockedShakeWidgetState extends State<_LockedShakeWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _offsetAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _offsetAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -7.0), weight: 25),
      TweenSequenceItem(tween: Tween(begin: -7.0, end: 7.0), weight: 35),
      TweenSequenceItem(tween: Tween(begin: 7.0, end: -3.0), weight: 20),
      TweenSequenceItem(tween: Tween(begin: -3.0, end: 0.0), weight: 20),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void didUpdateWidget(_LockedShakeWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isShaking && !oldWidget.isShaking) {
      _controller.forward(from: 0.0).then((_) {
        widget.onComplete?.call();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_offsetAnim.value, 0),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// Pulsing glowing ring around the current/next-up active node
class _PulsingGlowRing extends StatefulWidget {
  final Color glowColor;
  final double size;

  const _PulsingGlowRing({
    this.glowColor = const Color(0xFFA78BFA),
    this.size = 130.0,
  });

  @override
  State<_PulsingGlowRing> createState() => _PulsingGlowRingState();
}

class _PulsingGlowRingState extends State<_PulsingGlowRing>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.98, end: 1.10).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOutSine),
    );
    _opacityAnimation = Tween<double>(begin: 0.25, end: 0.60).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, _) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.glowColor.withValues(
                alpha: _opacityAnimation.value * 0.15,
              ),
              boxShadow: [
                BoxShadow(
                  color: widget.glowColor.withValues(
                    alpha: _opacityAnimation.value * 0.35,
                  ),
                  blurRadius: 18,
                  spreadRadius: 3,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Unlock transition: 400ms grayscale -> full color fade + 300ms celebration pop
class _UnlockTransitionWidget extends StatefulWidget {
  final Widget child;
  final bool isNewlyUnlocked;
  final VoidCallback? onTransitionComplete;

  const _UnlockTransitionWidget({
    required this.child,
    required this.isNewlyUnlocked,
    this.onTransitionComplete,
  });

  @override
  State<_UnlockTransitionWidget> createState() =>
      _UnlockTransitionWidgetState();
}

class _UnlockTransitionWidgetState extends State<_UnlockTransitionWidget>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _saturationAnimation;

  late AnimationController _popController;
  late Animation<double> _popAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _saturationAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _popController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _popAnimation =
        TweenSequence<double>([
          TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.12), weight: 50),
          TweenSequenceItem(tween: Tween(begin: 1.12, end: 1.0), weight: 50),
        ]).animate(
          CurvedAnimation(parent: _popController, curve: Curves.easeOutBack),
        );

    if (widget.isNewlyUnlocked) {
      _startTransition();
    }
  }

  void _startTransition() {
    _fadeController.forward(from: 0.0).then((_) {
      _popController.forward(from: 0.0).then((_) {
        widget.onTransitionComplete?.call();
      });
    });
  }

  @override
  void didUpdateWidget(_UnlockTransitionWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isNewlyUnlocked && !oldWidget.isNewlyUnlocked) {
      _startTransition();
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _popController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isNewlyUnlocked) {
      return widget.child;
    }

    return AnimatedBuilder(
      animation: Listenable.merge([_fadeController, _popController]),
      builder: (context, child) {
        final sat = _saturationAnimation.value;
        final scale = _popController.isAnimating ? _popAnimation.value : 1.0;

        return Transform.scale(
          scale: scale,
          child: ColorFiltered(
            colorFilter: ColorFilter.matrix(_getSaturationMatrix(sat)),
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }

  List<double> _getSaturationMatrix(double sat) {
    final double r = 0.2126 * (1 - sat);
    final double g = 0.7152 * (1 - sat);
    final double b = 0.0722 * (1 - sat);

    return <double>[
      r + sat,
      g,
      b,
      0,
      0,
      r,
      g + sat,
      b,
      0,
      0,
      r,
      g,
      b + sat,
      0,
      0,
      0,
      0,
      0,
      1,
      0,
    ];
  }
}

/// 3D Numbered Pedestal Disc Node Widget with tactile pushdown animation
class _3DPathNodeWidget extends StatefulWidget {
  final LessonModel lesson;
  final int lessonIndex;
  final bool isLeft;
  final bool isLocked;
  final bool isCompleted;
  final bool isCurrentActive;
  final int mastered;
  final int? totalOverride;
  final VoidCallback onTap;
  final VoidCallback? onStart;
  final VoidCallback? onRefresh;

  const _3DPathNodeWidget({
    required this.lesson,
    required this.lessonIndex,
    required this.isLeft,
    required this.isLocked,
    required this.isCompleted,
    required this.isCurrentActive,
    required this.mastered,
    this.totalOverride,
    required this.onTap,
    this.onStart,
    this.onRefresh,
  });

  @override
  State<_3DPathNodeWidget> createState() => _3DPathNodeWidgetState();
}

class _3DPathNodeWidgetState extends State<_3DPathNodeWidget> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final lessonNumber = widget.lessonIndex + 1;
    final isPurpleTheme = widget.lessonIndex % 2 == 0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Top disc with side refresh button
        SizedBox(
          width: 170,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              // Pulsing glow ring for active node
              if (widget.isCurrentActive && !_isPressed)
                _PulsingGlowRing(glowColor: const Color(0xFF60A5FA), size: 110),

              // 3D Circular Pedestal Disc with tactile pushdown animation
              GestureDetector(
                onTapDown: (_) {
                  setState(() => _isPressed = true);
                  HapticFeedback.lightImpact();
                },
                onTapUp: (_) {
                  setState(() => _isPressed = false);
                  widget.onTap();
                },
                onTapCancel: () {
                  setState(() => _isPressed = false);
                },
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 90),
                  curve: Curves.easeOutCubic,
                  transform: Matrix4.translationValues(
                    0,
                    _isPressed ? 4.0 : 0.0,
                    0,
                  ),
                  width: 94,
                  height: 94,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.isLocked
                        ? const Color(0xFFCBD5E1)
                        : const Color(0xFFDCEAFE),
                    boxShadow: [
                      BoxShadow(
                        color: widget.isLocked
                            ? Colors.black.withValues(alpha: 0.05)
                            : const Color(
                                0xFF3B82F6,
                              ).withValues(alpha: _isPressed ? 0.08 : 0.18),
                        blurRadius: _isPressed ? 6 : 18,
                        offset: Offset(0, _isPressed ? 3 : 10),
                      ),
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: EdgeInsets.only(bottom: _isPressed ? 1.5 : 6.0),
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: widget.isLocked
                              ? [
                                  const Color(0xFFF8FAFC),
                                  const Color(0xFFE2E8F0),
                                ]
                              : [Colors.white, const Color(0xFFEFF6FF)],
                        ),
                        border: Border.all(
                          color: widget.isLocked
                              ? const Color(0xFFCBD5E1)
                              : const Color(0xFFE2EDFB),
                          width: 2.5,
                        ),
                      ),
                      child: Center(
                        child: Container(
                          width: 68,
                          height: 68,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            border: Border.all(
                              color: widget.isLocked
                                  ? const Color(0xFFE2E8F0)
                                  : const Color(0xFFE0EBF7),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(
                                  0xFF93C5FD,
                                ).withValues(alpha: 0.14),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Center(
                            child: _buildOutlinedNumber(
                              lessonNumber,
                              widget.isLocked,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Overlapping bottom rim status badge
              Positioned(
                bottom: -5 + (_isPressed ? 4.0 : 0.0),
                child: Container(
                  width: 27,
                  height: 27,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.isLocked
                        ? const Color(0xFFF1F5F9)
                        : const Color(0xFFE0F2FE),
                    border: Border.all(color: Colors.white, width: 2.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: widget.isLocked
                        ? const Icon(
                            Icons.lock_rounded,
                            size: 13,
                            color: Color(0xFF94A3B8),
                          )
                        : (widget.isCompleted
                              ? const Icon(
                                  Icons.check_rounded,
                                  size: 15,
                                  color: Color(0xFF2563EB),
                                )
                              : const Icon(
                                  Icons.person_rounded,
                                  size: 15,
                                  color: Color(0xFF2563EB),
                                )),
                  ),
                ),
              ),

              // Floating circular refresh/review button (beside node 1 or completed node)
              if (!widget.isLocked && widget.onRefresh != null)
                Positioned(
                  top: 2,
                  right: widget.isLeft ? 0 : null,
                  left: !widget.isLeft ? 0 : null,
                  child: _FloatingActionButton(onTap: widget.onRefresh!),
                ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Progress Card directly underneath
        if (!widget.isLocked)
          GestureDetector(
            onTap: widget.onStart ?? widget.onTap,
            child: _PathProgressCard(
              lesson: widget.lesson,
              mastered: widget.mastered,
              totalOverride: widget.totalOverride,
              isCompleted: widget.isCompleted,
              isPurpleTheme: isPurpleTheme,
            ),
          ),
      ],
    );
  }

  Widget _buildOutlinedNumber(int number, bool isLocked) {
    final numStr = '$number';
    final strokeColor = isLocked
        ? const Color(0xFF94A3B8)
        : const Color(0xFF3B82F6);
    final fillColor = isLocked ? const Color(0xFFF8FAFC) : Colors.white;

    return Stack(
      alignment: Alignment.center,
      children: [
        // Outlined stroke
        Text(
          numStr,
          style: AppTypography.baloo2(fontSize: 38, fontWeight: FontWeight.w900)
              .copyWith(
                foreground: Paint()
                  ..style = PaintingStyle.stroke
                  ..strokeWidth = 3.5
                  ..strokeCap = StrokeCap.round
                  ..strokeJoin = StrokeJoin.round
                  ..color = strokeColor,
              ),
        ),
        // Inner fill
        Text(
          numStr,
          style: AppTypography.baloo2(
            fontSize: 38,
            fontWeight: FontWeight.w900,
            color: fillColor,
          ),
        ),
      ],
    );
  }
}

/// Floating circular refresh button beside node
class _FloatingActionButton extends StatefulWidget {
  final VoidCallback onTap;

  const _FloatingActionButton({required this.onTap});

  @override
  State<_FloatingActionButton> createState() => _FloatingActionButtonState();
}

class _FloatingActionButtonState extends State<_FloatingActionButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        setState(() => _pressed = true);
        HapticFeedback.lightImpact();
      },
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 90),
        transform: Matrix4.translationValues(0, _pressed ? 2.0 : 0.0, 0),
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFBAE6FD), width: 1.8),
          boxShadow: [
            BoxShadow(
              color: const Color(
                0xFF0284C7,
              ).withValues(alpha: _pressed ? 0.08 : 0.16),
              blurRadius: _pressed ? 4 : 8,
              offset: Offset(0, _pressed ? 1 : 3),
            ),
          ],
        ),
        child: const Center(
          child: Icon(
            Icons.refresh_rounded,
            size: 22,
            color: Color(0xFF0284C7),
          ),
        ),
      ),
    );
  }
}

/// Rounded Progress Card below node with corner badges
class _PathProgressCard extends StatelessWidget {
  final LessonModel lesson;
  final int mastered;
  final int? totalOverride;
  final bool isCompleted;
  final bool isPurpleTheme;

  const _PathProgressCard({
    required this.lesson,
    required this.mastered,
    this.totalOverride,
    required this.isCompleted,
    required this.isPurpleTheme,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = isPurpleTheme
        ? const Color(0xFFE9D5FF)
        : const Color(0xFFBAE6FD);
    final shadowColor = isPurpleTheme
        ? const Color(0xFF8B5CF6)
        : const Color(0xFF0284C7);
    final subtitleColor = isPurpleTheme
        ? const Color(0xFF7C3AED)
        : const Color(0xFF0284C7);
    final progressGradient = isPurpleTheme
        ? const LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)])
        : const LinearGradient(colors: [Color(0xFF38BDF8), Color(0xFF0284C7)]);
    final progressTrack = isPurpleTheme
        ? const Color(0xFFF3E8FF)
        : const Color(0xFFE0F2FE);

    final totalWords = totalOverride ?? lesson.totalWordCount;
    final masteredText = '$mastered/$totalWords Mastered';
    final progressFraction = totalWords > 0
        ? (mastered / totalWords).clamp(0.0, 1.0)
        : 0.0;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Main Card Container
        Container(
          width: 184,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderColor, width: 1.8),
            boxShadow: [
              BoxShadow(
                color: shadowColor.withValues(alpha: 0.10),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (lesson.className != null && lesson.className!.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  margin: const EdgeInsets.only(bottom: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: const Color(0xFFBFDBFE).withValues(alpha: 0.5),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.school_rounded,
                        size: 9,
                        color: Color(0xFF2563EB),
                      ),
                      const SizedBox(width: 3),
                      Flexible(
                        child: Text(
                          lesson.className!,
                          style: AppTypography.nunito(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF1D4ED8),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Word count label
              Text(
                '$totalWords ${totalWords == 1 ? 'word' : 'words'}',
                style: AppTypography.baloo2(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  color: const Color(0xFF0F172A),
                ),
                maxLines: 1,
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 1),

              // Mastery subtitle
              Text(
                masteredText,
                style: AppTypography.baloo2(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  color: subtitleColor,
                ),
                maxLines: 1,
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 6),

              // Gradient Progress Bar
              Container(
                height: 6,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: progressTrack,
                  borderRadius: BorderRadius.circular(3),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: progressFraction,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: progressGradient,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Top-left attached ornament badge
        Positioned(
          top: -10,
          left: -8,
          child: isPurpleTheme ? _buildStarBadge() : _buildFlowerBadge(),
        ),

        // Bottom-right attached ornament badge
        Positioned(
          bottom: -6,
          right: -8,
          child: isPurpleTheme ? _buildCloudBadge() : _buildHeartBadge(),
        ),
      ],
    );
  }

  Widget _buildStarBadge() {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: const Color(0xFFFEF9C3),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFACC15).withValues(alpha: 0.45),
            blurRadius: 6,
          ),
        ],
      ),
      child: const Center(
        child: Icon(Icons.star_rounded, size: 17, color: Color(0xFFEAB308)),
      ),
    );
  }

  Widget _buildFlowerBadge() {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: const Color(0xFFE0F2FE),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF38BDF8).withValues(alpha: 0.45),
            blurRadius: 6,
          ),
        ],
      ),
      child: const Center(
        child: Icon(
          Icons.local_florist_rounded,
          size: 16,
          color: Color(0xFF0284C7),
        ),
      ),
    );
  }

  Widget _buildCloudBadge() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF3E8FF),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFA855F7).withValues(alpha: 0.25),
            blurRadius: 4,
          ),
        ],
      ),
      child: const Icon(
        Icons.cloud_rounded,
        size: 14,
        color: Color(0xFFA855F7),
      ),
    );
  }

  Widget _buildHeartBadge() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFFFE4E6),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF43F5E).withValues(alpha: 0.25),
            blurRadius: 4,
          ),
        ],
      ),
      child: const Icon(
        Icons.favorite_rounded,
        size: 13,
        color: Color(0xFFF43F5E),
      ),
    );
  }
}

/// Subtle scattered pastel geometric sparkles across map background
class _BackgroundSparkles extends StatelessWidget {
  const _BackgroundSparkles();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(child: CustomPaint(painter: _SparklesPainter())),
    );
  }
}

class _SparklesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final items = [
      (0.13 * w, 140.0, 14.0, 'star4', const Color(0xFFDDD6FE)),
      (0.44 * w, 130.0, 7.0, 'diamond', const Color(0xFFFDE047)),
      (0.52 * w, 320.0, 6.0, 'circle', const Color(0xFF93C5FD)),
      (0.43 * w, 380.0, 8.0, 'diamond', const Color(0xFFFDE047)),
      (0.38 * w, 440.0, 7.0, 'diamond', const Color(0xFFFDA4AF)),
      (0.36 * w, 600.0, 9.0, 'heart', const Color(0xFF86EFAC)),
      (0.57 * w, 630.0, 8.0, 'diamond', const Color(0xFFFDE047)),
      (0.75 * w, 455.0, 10.0, 'circle', const Color(0xFFFFCCD5)),
      (0.61 * w, 720.0, 8.0, 'diamond', const Color(0xFF7DD3FC)),
      (0.12 * w, 780.0, 12.0, 'star4', const Color(0xFFE9D5FF)),
      (0.85 * w, 820.0, 7.0, 'diamond', const Color(0xFFFDE047)),
      (0.88 * w, 950.0, 9.0, 'circle', const Color(0xFFFECDD3)),
      (0.15 * w, 1050.0, 8.0, 'diamond', const Color(0xFF86EFAC)),
      (0.82 * w, 1180.0, 10.0, 'star4', const Color(0xFFDDD6FE)),
    ];

    for (final item in items) {
      final x = item.$1;
      final y = item.$2;
      final s = item.$3;
      final shape = item.$4;
      final color = item.$5;

      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;

      if (shape == 'diamond') {
        final path = Path()
          ..moveTo(x, y - s)
          ..lineTo(x + s * 0.7, y)
          ..lineTo(x, y + s)
          ..lineTo(x - s * 0.7, y)
          ..close();
        canvas.drawPath(path, paint);
      } else if (shape == 'star4') {
        final path = Path();
        path.moveTo(x, y - s);
        path.quadraticBezierTo(x, y, x + s, y);
        path.quadraticBezierTo(x, y, x, y + s);
        path.quadraticBezierTo(x, y, x - s, y);
        path.quadraticBezierTo(x, y, x, y - s);
        path.close();
        canvas.drawPath(path, paint);
      } else if (shape == 'heart') {
        final path = Path();
        final r = s * 0.5;
        path.moveTo(x, y + r);
        path.cubicTo(x - s, y - r * 0.5, x - r, y - s, x, y - r * 0.5);
        path.cubicTo(x + r, y - s, x + s, y - r * 0.5, x, y + r);
        canvas.drawPath(path, paint);
      } else {
        canvas.drawCircle(Offset(x, y), s * 0.5, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 3D Disc for Cumulative Review Node with tactile pushdown animation
class _Review3DDisc extends StatefulWidget {
  final bool reviewUnlocked;
  final bool isCompleted;
  final Color color;
  final IconData icon;

  const _Review3DDisc({
    required this.reviewUnlocked,
    required this.isCompleted,
    required this.color,
    required this.icon,
  });

  @override
  State<_Review3DDisc> createState() => _Review3DDiscState();
}

class _Review3DDiscState extends State<_Review3DDisc> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        if (widget.reviewUnlocked) {
          setState(() => _isPressed = true);
          HapticFeedback.lightImpact();
        }
      },
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 90),
        transform: Matrix4.translationValues(0, _isPressed ? 3.0 : 0.0, 0),
        width: 82,
        height: 82,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: widget.reviewUnlocked
              ? const Color(0xFFDCEAFE)
              : const Color(0xFFE2E8F0),
          boxShadow: widget.reviewUnlocked
              ? [
                  BoxShadow(
                    color: widget.color.withValues(
                      alpha: _isPressed ? 0.10 : 0.22,
                    ),
                    blurRadius: _isPressed ? 6 : 14,
                    offset: Offset(0, _isPressed ? 2 : 6),
                  ),
                ]
              : null,
        ),
        child: Padding(
          padding: EdgeInsets.only(bottom: _isPressed ? 1.5 : 5.0),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.reviewUnlocked
                  ? Colors.white
                  : const Color(0xFFF1F5F9),
              border: Border.all(
                color: widget.reviewUnlocked
                    ? const Color(0xFFBFDBFE)
                    : const Color(0xFFCBD5E1),
                width: 2.5,
              ),
            ),
            child: Center(
              child: Icon(widget.icon, color: widget.color, size: 34),
            ),
          ),
        ),
      ),
    );
  }
}
