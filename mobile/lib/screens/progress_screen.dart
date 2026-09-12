import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/motion/typography_tokens.dart';
import '../models/learner_category_progress_model.dart';
import '../models/learner_lesson_progress_model.dart';
import '../models/learner_progress_model.dart';
import '../models/recent_word_progress_model.dart';
import '../providers/auth_provider.dart';
import '../providers/lesson_provider.dart';
import '../widgets/app_3d_bottom_nav_bar.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  bool _isLoading = true;
  String? _error;

  LearnerProgressModel? _progress;
  List<LearnerLessonProgressModel> _lessons = [];
  List<LearnerCategoryProgressModel> _categories = [];
  List<RecentWordProgressModel> _recentWords = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final provider = Provider.of<LessonProvider>(context, listen: false);
    final learnerId = auth.learner?.learnerId;

    if (learnerId == null) {
      setState(() {
        _isLoading = false;
        _error = 'No logged in learner found.';
      });
      return;
    }

    try {
      final results = await Future.wait([
        provider.fetchLearnerProgressDetails(learnerId),
        provider.fetchLearnerLessonProgress(learnerId),
        provider.fetchLearnerCategoryProgress(learnerId),
        provider.fetchLearnerRecentWords(learnerId, limit: 500),
      ]);

      if (!mounted) return;

      setState(() {
        _progress = results[0] as LearnerProgressModel?;
        _lessons = results[1] as List<LearnerLessonProgressModel>;
        _categories = results[2] as List<LearnerCategoryProgressModel>;
        _recentWords = results[3] as List<RecentWordProgressModel>;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'Failed to load progress data. Please try again.';
      });
    }
  }

  String _getMasteryDescriptor(double accuracy, String currentLevel) {
    if (accuracy >= 90) return 'Excellent';
    if (accuracy >= 80) return 'Good';
    if (accuracy >= 70) return 'Fair';
    if (accuracy > 0) return 'Needs Practice';

    switch (currentLevel.toUpperCase()) {
      case 'MASTERED':
        return 'Excellent';
      case 'PROFICIENT':
        return 'Good';
      case 'FAMILIAR':
        return 'Fair';
      case 'LEARNING':
      default:
        return 'Needs Practice';
    }
  }

  Color _masteryColor(String descriptor) {
    switch (descriptor) {
      case 'Excellent':
        return const Color(0xFF10B981); // Emerald Green
      case 'Good':
        return const Color(0xFF06A6FF); // Blue
      case 'Fair':
        return const Color(0xFFF59E0B); // Amber
      case 'Needs Practice':
      default:
        return const Color(0xFFEF4444); // Red/Rose
    }
  }

  Color _levelBgColor(String level) {
    switch (level.toUpperCase()) {
      case 'MASTERED':
        return const Color(0xFFDCFCE7);
      case 'PROFICIENT':
        return const Color(0xFFEFF6FF);
      case 'FAMILIAR':
        return const Color(0xFFFEF3C7);
      case 'LEARNING':
      default:
        return const Color(0xFFF1F5F9);
    }
  }

  Color _levelTextColor(String level) {
    switch (level.toUpperCase()) {
      case 'MASTERED':
        return const Color(0xFF16A34A);
      case 'PROFICIENT':
        return const Color(0xFF1D4ED8);
      case 'FAMILIAR':
        return const Color(0xFFD97706);
      case 'LEARNING':
      default:
        return const Color(0xFF64748B);
    }
  }

  @override
  Widget build(BuildContext context) {
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
              icon: const Icon(
                Icons.arrow_back_rounded,
                color: Color(0xFF0F172A),
                size: 20,
              ),
              onPressed: () => Navigator.of(context).maybePop(),
              padding: EdgeInsets.zero,
            ),
          ),
        ),
        title: Text(
          'Learning Progress',
          style: AppTypography.baloo2(
            fontWeight: FontWeight.w800,
            fontSize: 21,
            color: const Color(0xFF06A6FF),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      color: Colors.redAccent,
                      size: 56,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: AppTypography.nunito(
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadData,
                      child: Text(
                        'Retry',
                        style: AppTypography.baloo2(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20.0, 78.0, 20.0, 32.0),
                children: [
                  _buildHeaderSection(),
                  const SizedBox(height: 24),
                  _buildPerLessonSection(),
                  const SizedBox(height: 24),
                  _buildPerCategorySection(),
                  const SizedBox(height: 24),
                  _buildPOSProgressSection(),
                  const SizedBox(height: 24),
                  _buildRecentWordsSection(),
                  const SizedBox(height: 32),
                ],
              ),
            ),
      bottomNavigationBar: const App3DBottomNavBar(currentPath: '/progress'),
    );
  }

  // 1. Header: 18 Words card with mascot popping out from behind on the top right
  Widget _buildHeaderSection() {
    final masteredCount = _progress?.wordsMasteredCount ?? 0;
    final level = _progress?.masteryLevel ?? 'LEARNING';
    final accuracy = _progress?.overallAccuracy ?? 0.0;
    final points = _progress?.totalPoints ?? 0;
    final sessions = _progress?.totalSessionsPlayed ?? 0;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // ── Mascot illustration popping out high on the top-right behind the card ──
        Positioned(
          top: -88,
          right: 10,
          child: SizedBox(
            width: 124,
            height: 124,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Celebration confetti & sparkles
                const Positioned(
                  top: 8,
                  left: -8,
                  child: Text('✨', style: TextStyle(fontSize: 15)),
                ),
                const Positioned(
                  top: -4,
                  right: 2,
                  child: Text('🎉', style: TextStyle(fontSize: 15)),
                ),
                const Positioned(
                  top: 42,
                  right: -10,
                  child: Text('✨', style: TextStyle(fontSize: 13)),
                ),
                // Celebrating Mascot
                Center(
                  child: SizedBox(
                    width: 108,
                    height: 108,
                    child: Image.asset(
                      'assets/images/scoremascot.png',
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) => Image.asset(
                        'assets/images/turtle_celebrate.png',
                        fit: BoxFit.contain,
                        errorBuilder: (_, _, _) =>
                            const Text('🐢', style: TextStyle(fontSize: 60)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // ── Foreground 18 Words Summary Card ──
        Container(
          padding: const EdgeInsets.all(22.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24.0),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F172A).withValues(alpha: 0.05),
                blurRadius: 18,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$masteredCount Words',
                        style: AppTypography.baloo2(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF0F172A),
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Total Mastered So Far',
                        style: AppTypography.nunito(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: _levelBgColor(level),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      level.toUpperCase(),
                      style: AppTypography.baloo2(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: _levelTextColor(level),
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Expanded(
                    child: _buildHeaderStat(
                      'Accuracy',
                      '${accuracy.toStringAsFixed(1)}%',
                      Icons.adjust_rounded,
                      const Color(0xFF0284C7),
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 38,
                    color: const Color(0xFFF1F5F9),
                  ),
                  Expanded(
                    child: _buildHeaderStat(
                      'Points',
                      '$points',
                      Icons.star_rounded,
                      const Color(0xFFF59E0B),
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 38,
                    color: const Color(0xFFF1F5F9),
                  ),
                  Expanded(
                    child: _buildHeaderStat(
                      'Sessions',
                      '$sessions',
                      Icons.play_circle_fill_rounded,
                      const Color(0xFF10B981),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderStat(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Center(child: Icon(icon, color: color, size: 20)),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: AppTypography.baloo2(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 1),
        Text(
          label,
          style: AppTypography.nunito(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF64748B),
          ),
        ),
      ],
    );
  }

  // 2. Per-lesson breakdown list
  Widget _buildPerLessonSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Lesson Progress Breakdown',
          style: AppTypography.baloo2(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 12),
        if (_lessons.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0),
            child: Text(
              'No lesson progress recorded yet.',
              style: AppTypography.nunito(color: const Color(0xFF64748B)),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _lessons.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final lesson = _lessons[index];
              return Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16.0),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: lesson.status == 'COMPLETED'
                            ? const Color(0xFF10B981).withValues(alpha: 0.12)
                            : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        lesson.status == 'COMPLETED'
                            ? Icons.check_circle_rounded
                            : (lesson.status == 'LOCKED'
                                  ? Icons.lock_rounded
                                  : Icons.menu_book_rounded),
                        color: lesson.status == 'COMPLETED'
                            ? const Color(0xFF10B981)
                            : const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            lesson.lessonTitle,
                            style: AppTypography.baloo2(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            lesson.categoryName,
                            style: AppTypography.nunito(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Row(
                          children: List.generate(
                            3,
                            (i) => Icon(
                              i < lesson.starsEarned
                                  ? Icons.star_rounded
                                  : Icons.star_border_rounded,
                              size: 16,
                              color: i < lesson.starsEarned
                                  ? const Color(0xFFF59E0B)
                                  : const Color(0xFFCBD5E1),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${lesson.accuracyRate.toStringAsFixed(0)}% accuracy',
                          style: AppTypography.baloo2(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: lesson.accuracyRate >= 80
                                ? const Color(0xFF10B981)
                                : const Color(0xFFF59E0B),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  // 3. Per-category accuracy breakdown
  Widget _buildPerCategorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Category Mastery Breakdown',
          style: AppTypography.baloo2(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 12),
        if (_categories.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0),
            child: Text(
              'No category data available.',
              style: AppTypography.nunito(color: const Color(0xFF64748B)),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _categories.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final cat = _categories[index];
              final accuracy = cat.categoryAccuracy;
              return Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16.0),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          cat.categoryName,
                          style: AppTypography.baloo2(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          '${cat.completedLessons}/${cat.totalLessons} Lessons',
                          style: AppTypography.nunito(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: (accuracy / 100.0).clamp(0.0, 1.0),
                        minHeight: 8,
                        backgroundColor: const Color(0xFFF1F5F9),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          accuracy >= 80
                              ? const Color(0xFF10B981)
                              : const Color(0xFF06A6FF),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildPOSProgressSection() {
    final Map<String, List<RecentWordProgressModel>> groupedByPOS = {
      'NOUN': [],
      'VERB': [],
      'ADJECTIVE': [],
    };
    for (var w in _recentWords) {
      final rawPos = (w.partOfSpeech ?? '').trim().toUpperCase();
      if (rawPos.isEmpty) continue;

      String normalizedPos = rawPos;
      if (rawPos.startsWith('N')) {
        normalizedPos = 'NOUN';
      } else if (rawPos.startsWith('V')) {
        normalizedPos = 'VERB';
      } else if (rawPos.startsWith('ADJ')) {
        normalizedPos = 'ADJECTIVE';
      }

      if (!groupedByPOS.containsKey(normalizedPos)) {
        groupedByPOS[normalizedPos] = [];
      }
      groupedByPOS[normalizedPos]!.add(w);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Part of Speech Progress',
          style: AppTypography.baloo2(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 12),
        if (groupedByPOS.values.every((list) => list.isEmpty))
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0),
            child: Text(
              'No POS data available.',
              style: AppTypography.nunito(color: const Color(0xFF64748B)),
            ),
          )
        else
          ...groupedByPOS.entries.where((e) => e.value.isNotEmpty).map((e) {
            final pos = e.key;
            final words = e.value;
            final totalAttempts = words.fold<int>(0, (sum, w) => sum + w.safeTotalAttempts);
            final totalCorrect = words.fold<int>(0, (sum, w) => sum + w.safeCorrectCount);
            final avgAccuracy = totalAttempts > 0
                ? (totalCorrect * 100.0 / totalAttempts)
                : (words.isEmpty ? 0.0 : (words.fold(0.0, (sum, w) => sum + w.accuracy) / words.length));

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.category_rounded,
                      color: Color(0xFF06A6FF),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          pos,
                          style: AppTypography.baloo2(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${words.length} words introduced',
                          style: AppTypography.nunito(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${avgAccuracy.toStringAsFixed(0)}% accuracy',
                        style: AppTypography.baloo2(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: avgAccuracy >= 80
                              ? const Color(0xFF10B981)
                              : const Color(0xFFF59E0B),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }

  // 4. Recently learned/practiced words
  Widget _buildRecentWordsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recently Practiced Words',
          style: AppTypography.baloo2(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 12),
        if (_recentWords.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0),
            child: Text(
              'No recently practiced words found.',
              style: AppTypography.nunito(color: const Color(0xFF64748B)),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _recentWords.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final word = _recentWords[index];
              final descriptor = _getMasteryDescriptor(
                word.accuracy,
                word.currentLevel,
              );
              final descColor = _masteryColor(descriptor);
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14.0),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            word.englishWord,
                            style: AppTypography.baloo2(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            word.cebuanoMeaning,
                            style: AppTypography.nunito(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: descColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            descriptor,
                            style: AppTypography.baloo2(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: descColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Text(
                            '${word.accuracy.toStringAsFixed(0)}%',
                            style: AppTypography.baloo2(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: descColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }
}
