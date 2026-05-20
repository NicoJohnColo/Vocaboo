import 'package:flutter/material';
import 'package:go_router/go_router.dart';
import 'package:provider/provider';
import '../providers/auth_provider.dart';
import '../providers/lesson_provider.dart';
import '../services/localization_service.dart';

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
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final pref = auth.learner?.languagePreference;

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Text(
          widget.categoryName,
          style: const TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold),
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
                      ? const Center(child: Text('No lessons available in this category.'))
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
                          itemCount: provider.lessons.length,
                          itemBuilder: (context, index) {
                            final lesson = provider.lessons[index];
                            final isLast = index == provider.lessons.length - 1;

                            // Determine colors and icons based on status
                            Color nodeColor;
                            IconData nodeIcon;
                            bool isEnabled = false;

                            if (lesson.status == 'COMPLETED') {
                              nodeColor = theme.colorScheme.tertiary; // Emerald
                              nodeIcon = Icons.check_circle_rounded;
                              isEnabled = true;
                            } else if (lesson.status == 'UNLOCKED') {
                              nodeColor = theme.colorScheme.primary; // Indigo
                              nodeIcon = Icons.play_arrow_rounded;
                              isEnabled = true;
                            } else {
                              nodeColor = const Color(0xFF64748B); // Locked Gray
                              nodeIcon = Icons.lock_rounded;
                              isEnabled = false;
                            }

                            // Alternating left/right positioning to create a playful board-game trail layout
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
                                              context.push('/lesson/${lesson.lessonId}/diagnostic');
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
                                              color: isEnabled ? nodeColor.withOpacity(0.15) : theme.colorScheme.surface,
                                              border: Border.all(
                                                color: nodeColor,
                                                width: 3,
                                              ),
                                              boxShadow: isEnabled
                                                  ? [
                                                      BoxShadow(
                                                        color: nodeColor.withOpacity(0.3),
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
                                          // Title and Details Card
                                          Container(
                                            width: 180,
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: theme.colorScheme.surface,
                                              borderRadius: BorderRadius.circular(16),
                                              border: Border.all(
                                                color: isEnabled ? nodeColor.withOpacity(0.3) : Colors.transparent,
                                              ),
                                            ),
                                            child: Column(
                                              children: [
                                                Text(
                                                  lesson.lessonTitle,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 14,
                                                    color: Colors.white,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  '${lesson.totalWordCount} words',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                                                  ),
                                                ),
                                                if (lesson.status == 'COMPLETED' && lesson.masteryScore != null) ...[
                                                  const SizedBox(height: 6),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: theme.colorScheme.tertiary.withOpacity(0.15),
                                                      borderRadius: BorderRadius.circular(8),
                                                    ),
                                                    child: Text(
                                                      'Score: ${lesson.masteryScore!.toStringAsFixed(0)}%',
                                                      style: TextStyle(
                                                        fontSize: 10,
                                                        color: theme.colorScheme.tertiary,
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
                                  // Connecting dotted / dashed line
                                  Container(
                                    height: 50,
                                    width: 4,
                                    margin: const EdgeInsets.symmetric(vertical: 8),
                                    decoration: BoxDecoration(
                                      color: isEnabled ? nodeColor.withOpacity(0.4) : const Color(0xFF334155),
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
