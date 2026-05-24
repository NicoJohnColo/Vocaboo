import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../models/lesson_model.dart';
import '../providers/lesson_provider.dart';

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
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<LessonProvider>(context, listen: false).loadLessons(widget.categoryId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = Provider.of<LessonProvider>(context);
    
    // Find composite review lesson if present
    final compositeReviewLesson = provider.lessons.cast<LessonModel?>().firstWhere(
      (lesson) => lesson?.isCompositeReview ?? false,
      orElse: () => null,
    );
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
        sourceLessonIds.every((id) => 
            provider.lessons.firstWhere((l) => l.lessonId == id, orElse: () => provider.lessons.first).status == 'COMPLETED'
        );
    
    final totalItems = provider.lessons.length + (hasReviewNode ? 1 : 0);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF0F172A)),
          onPressed: () => context.pop(),
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
        onRefresh: () => provider.loadLessons(widget.categoryId),
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
                                              context.push(
                                                '/lesson/${lesson.lessonId}/diagnostic',
                                                extra: {
                                                  'categoryId': widget.categoryId,
                                                },
                                              );
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
                                                if (lesson.status == 'COMPLETED' && lesson.masteryScore != null) ...[
                                                  const SizedBox(height: 6),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: nodeColor.withValues(alpha: 0.12),
                                                      borderRadius: BorderRadius.circular(8),
                                                    ),
                                                    child: Text(
                                                      'Score: ${lesson.masteryScore!.toStringAsFixed(0)}%',
                                                      style: TextStyle(
                                                        fontSize: 10,
                                                        color: nodeColor,
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

  Widget _buildReviewNode(BuildContext context, ThemeData theme, bool reviewUnlocked, List<String> lessonIds) {
    final color = reviewUnlocked ? const Color(0xFF10B981) : const Color(0xFFCBD5E1);
    final icon = reviewUnlocked ? Icons.auto_graph_rounded : Icons.lock_rounded;
    
    // Generate dynamic label based on lesson IDs
    String reviewLabel = 'Review';
    if (lessonIds.length == 2) {
      reviewLabel = 'Review: Lessons 1–2';
    } else if (lessonIds.isNotEmpty) {
      reviewLabel = 'Review: ${lessonIds.length} Lessons';
    }
    
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
                  ? () {
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
}
