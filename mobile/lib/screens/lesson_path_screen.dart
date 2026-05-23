import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
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
                          itemCount: provider.lessons.length,
                          itemBuilder: (context, index) {
                            final lesson = provider.lessons[index];
                            final isLast = index == provider.lessons.length - 1;

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
}
