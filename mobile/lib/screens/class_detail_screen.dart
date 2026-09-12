import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/class_provider.dart';
import '../providers/lesson_provider.dart';
import '../models/class_performance_model.dart';
import '../models/learner_progress_model.dart';
import '../models/learner_lesson_progress_model.dart';
import '../models/lesson_model.dart';
import '../core/motion/typography_tokens.dart';

/// A detail screen for a single classroom.
///
/// Shows three tabs:
///   1. Overview — dual score card (Global Score + Class Score) + class info
///   2. Lessons  — class lessons list
///   3. Class Leaderboard — class-only ranked leaderboard (independent from global)
class ClassDetailScreen extends StatefulWidget {
  final String classId;
  final String className;

  const ClassDetailScreen({
    super.key,
    required this.classId,
    required this.className,
  });

  @override
  State<ClassDetailScreen> createState() => _ClassDetailScreenState();
}

class _ClassDetailScreenState extends State<ClassDetailScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  // Overview state
  ClassPerformanceModel? _classPerf;
  bool _perfLoading = true;
  LearnerProgressModel? _globalProgress;
  List<LessonModel> _classLessons = [];
  List<LearnerLessonProgressModel> _lessonProgress = [];
  Map<String, dynamic>? _dashboardProgress;

  // Leaderboard state
  List<Map<String, dynamic>> _leaderboard = [];
  bool _lbLoading = true;
  String _lbRange = 'weekly';

  // Categories state (for the Lessons tab)
  List<Map<String, dynamic>> _classCategories = [];
  bool _categoriesLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadAll());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final classProvider = Provider.of<ClassProvider>(context, listen: false);
    final lessonProvider = Provider.of<LessonProvider>(context, listen: false);
    final token = auth.token;
    final learnerId = auth.learner?.learnerId;

    final futures = <Future>[
      classProvider
          .fetchClassPerformance(widget.classId, token)
          .then(
            (p) => setState(() {
              _classPerf = p;
              _perfLoading = false;
            }),
          ),
      classProvider
          .fetchClassLeaderboard(widget.classId, token, range: _lbRange)
          .then(
            (lb) => setState(() {
              _leaderboard = lb;
              _lbLoading = false;
            }),
          ),
      classProvider
          .fetchClassCategories(widget.classId, token)
          .then(
            (cats) => setState(() {
              _classCategories = cats;
              _categoriesLoading = false;
            }),
          ),
      _fetchClassLessonsWithFallback(classProvider, token),
    ];

    if (learnerId != null && learnerId.isNotEmpty) {
      futures.add(
        lessonProvider.fetchLearnerProgressDetails(learnerId).then((gp) {
          if (mounted) setState(() => _globalProgress = gp);
        }),
      );
      futures.add(
        lessonProvider.fetchLearnerLessonProgress(learnerId).then((progress) {
          if (mounted) setState(() => _lessonProgress = progress);
        }),
      );
      futures.add(
        lessonProvider.fetchDashboardProgress().then((dashboard) {
          if (mounted) setState(() => _dashboardProgress = dashboard);
        }),
      );
    }

    await Future.wait(futures);
  }

  Future<void> _fetchClassLessonsWithFallback(
    ClassProvider classProvider,
    String? token,
  ) async {
    var lessons = await classProvider.fetchClassLessons(widget.classId, token);
    var categories = _classCategories;
    if (lessons.isEmpty && categories.isEmpty) {
      categories = await classProvider.fetchClassCategories(
        widget.classId,
        token,
      );
    }
    if (lessons.isEmpty && categories.isNotEmpty) {
      final categoryLessons = await Future.wait(
        categories.map((category) {
          return classProvider.fetchClassLessons(
            widget.classId,
            token,
            categoryId: category['categoryId']?.toString(),
          );
        }),
      );
      lessons = categoryLessons.expand((items) => items).toList();
    }
    if (mounted) setState(() => _classLessons = lessons);
  }

  Future<void> _reloadLeaderboard() async {
    setState(() => _lbLoading = true);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final classProvider = Provider.of<ClassProvider>(context, listen: false);
    final lb = await classProvider.fetchClassLeaderboard(
      widget.classId,
      auth.token,
      range: _lbRange,
    );
    if (mounted) {
      setState(() {
        _leaderboard = lb;
        _lbLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final globalPoints =
        _globalProgress?.totalPoints ?? auth.learner?.totalPoints ?? 0;
    final globalMastery =
        _globalProgress?.masteryLevel ??
        auth.learner?.masteryLevel ??
        'LEARNING';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: NestedScrollView(
        headerSliverBuilder: (_, _) => [_buildSliverAppBar()],
        body: Column(
          children: [
            // Tab bar
            Container(
              color: Colors.white,
              child: TabBar(
                controller: _tabController,
                indicatorColor: const Color(0xFF2563EB),
                indicatorWeight: 3,
                labelColor: const Color(0xFF2563EB),
                unselectedLabelColor: const Color(0xFF94A3B8),
                labelStyle: AppTypography.nunito(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
                tabs: const [
                  Tab(text: 'Overview'),
                  Tab(text: 'Lessons'),
                  Tab(text: 'Leaderboard'),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildOverviewTab(globalPoints, globalMastery),
                  _buildLessonsTab(),
                  _buildLeaderboardTab(auth.learner?.learnerId),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Sliver App Bar ──────────────────────────────────────────────────────────

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 130,
      pinned: true,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.school_rounded,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.className,
                          style: AppTypography.baloo2(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Class Details',
                          style: AppTypography.nunito(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      backgroundColor: const Color(0xFF1D4ED8),
      iconTheme: const IconThemeData(color: Colors.white),
    );
  }

  double? _calculateClassCompositeAccuracy() {
    final classLessonIds = _classLessons.map((lesson) => lesson.lessonId).toSet();
    if (classLessonIds.isEmpty) return null;

    final progressByLesson = <String, LearnerLessonProgressModel>{
      for (final progress in _lessonProgress)
        if (classLessonIds.contains(progress.lessonId))
          progress.lessonId: progress,
    };

    final pairBreakdowns =
        ((_dashboardProgress?['categoryBreakdowns'] as List?) ?? const [])
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .where((item) {
              final lessonIds = ((item['lessons'] as List?) ?? const [])
                  .whereType<Map>()
                  .map((lesson) => lesson['lessonId']?.toString())
                  .whereType<String>()
                  .toSet();
              return lessonIds.intersection(classLessonIds).isNotEmpty;
            })
            .toList();

    final combinedScores = pairBreakdowns
        .map((item) => (item['overallAccuracy'] as num?)?.toDouble())
        .whereType<double>()
        .toList();

    if (combinedScores.isNotEmpty) {
      return combinedScores.reduce((a, b) => a + b) / combinedScores.length;
    }

    final lessonScores = _classLessons
        .map(
          (lesson) =>
              progressByLesson[lesson.lessonId]?.accuracyRate ??
              lesson.masteryScore,
        )
        .whereType<double>()
        .where((s) => s > 0)
        .toList();

    if (lessonScores.isNotEmpty) {
      return lessonScores.reduce((a, b) => a + b) / lessonScores.length;
    }

    return null;
  }

  // ── Overview Tab ────────────────────────────────────────────────────────────

  Widget _buildOverviewTab(int globalPoints, String globalMastery) {
    final compositeAcc = _calculateClassCompositeAccuracy();
    final classAccuracy = compositeAcc ?? _classPerf?.classAccuracy;
    final classMastery = classAccuracy != null
        ? (classAccuracy >= 90
            ? 'MASTERED'
            : (classAccuracy >= 75
                ? 'PROFICIENT'
                : (classAccuracy >= 50 ? 'FAMILIAR' : 'LEARNING')))
        : (_classPerf?.classMasteryLevel ?? 'LEARNING');

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Section header
        Text(
          'PERFORMANCE SCORES',
          style: AppTypography.nunito(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF94A3B8),
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 12),

        // ── Dual Score Card ──────────────────────────────────────────────────
        Row(
          children: [
            Expanded(
              child: _buildScoreCard(
                label: '🌍  Global Score',
                points: globalPoints,
                mastery: globalMastery,
                accuracy: _globalProgress?.overallAccuracy,
                gradientColors: const [Color(0xFF0EA5E9), Color(0xFF0284C7)],
                subtitle: 'All-time app score',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _perfLoading
                  ? _loadingCard()
                  : _buildScoreCard(
                      label: '🏫  Class Score',
                      points: _classPerf?.classPoints ?? 0,
                      mastery: classMastery,
                      accuracy: classAccuracy,
                      gradientColors: const [
                        Color(0xFF2563EB),
                        Color(0xFF1D4ED8),
                      ],
                      subtitle: 'This class only',
                    ),
            ),
          ],
        ),

        // Explanation chip
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: const Color(0xFFF0FDF4),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFBBF7D0)),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.info_outline_rounded,
                size: 15,
                color: Color(0xFF16A34A),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Class activity counts toward BOTH scores. Your class score shows '
                  'progress exclusive to this classroom.',
                  style: AppTypography.nunito(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF15803D),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Class session stats
        if (!_perfLoading && _classPerf != null) ...[
          Text(
            'CLASS ACTIVITY',
            style: AppTypography.nunito(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF94A3B8),
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          _buildStatRow([
            _statChip(
              icon: Icons.play_circle_outline_rounded,
              value: '${_classPerf!.classSessionsPlayed}',
              label: 'Sessions',
              color: const Color(0xFF2563EB),
            ),
            _statChip(
              icon: Icons.check_circle_outline_rounded,
              value: '${_classPerf!.classCorrectAnswers}',
              label: 'Correct',
              color: const Color(0xFF22C55E),
            ),
            _statChip(
              icon: Icons.quiz_outlined,
              value: '${_classPerf!.classTotalQuestions}',
              label: 'Questions',
              color: const Color(0xFFF59E0B),
            ),
          ]),
          const SizedBox(height: 24),
          _buildLessonProgressSection(),
        ],
      ],
    );
  }

  Widget _buildLessonProgressSection() {
    final classLessonIds = _classLessons
        .map((lesson) => lesson.lessonId)
        .toSet();
    final progressByLesson = <String, LearnerLessonProgressModel>{
      for (final progress in _lessonProgress)
        if (classLessonIds.contains(progress.lessonId))
          progress.lessonId: progress,
    };
    final lessons = [..._classLessons]
      ..sort((a, b) => a.lessonOrder.compareTo(b.lessonOrder));
    final fallbackProgress = _lessonProgress
        .where((progress) => progress.classId == widget.classId)
        .toList();

    final pairBreakdowns =
        ((_dashboardProgress?['categoryBreakdowns'] as List?) ?? const [])
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .where((item) {
              final lessonIds = ((item['lessons'] as List?) ?? const [])
                  .whereType<Map>()
                  .map((lesson) => lesson['lessonId']?.toString())
                  .whereType<String>()
                  .toSet();
              return lessonIds.intersection(classLessonIds).isNotEmpty;
            })
            .toList();

    final cumulativeScores = pairBreakdowns
        .map((item) => (item['cumulativeAccuracy'] as num?)?.toDouble())
        .whereType<double>()
        .toList();
    final lessonScores = lessons
        .map(
          (lesson) =>
              progressByLesson[lesson.lessonId]?.accuracyRate ??
              lesson.masteryScore,
        )
        .whereType<double>()
        .toList();
    final combinedScores = pairBreakdowns
        .map((item) => (item['overallAccuracy'] as num?)?.toDouble())
        .whereType<double>()
        .toList();
    final cumulativeAverage = cumulativeScores.isEmpty
        ? null
        : cumulativeScores.reduce((a, b) => a + b) / cumulativeScores.length;
    final lessonAverage = lessonScores.isEmpty
        ? null
        : lessonScores.reduce((a, b) => a + b) / lessonScores.length;
    final combinedAverage = combinedScores.isEmpty
        ? null
        : combinedScores.reduce((a, b) => a + b) / combinedScores.length;

    if (lessons.isEmpty && fallbackProgress.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'LESSON PROGRESS',
          style: AppTypography.nunito(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF94A3B8),
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        ...lessons.asMap().entries.map((entry) {
          final index = entry.key;
          final lesson = entry.value;
          final progress = progressByLesson[lesson.lessonId];
          final accuracy = progress?.accuracyRate ?? lesson.masteryScore ?? 0.0;
          final mastered = lesson.masteredWordCount;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: const Color(0xFFEFF6FF),
                    child: Text(
                      '${index + 1}',
                      style: AppTypography.nunito(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF2563EB),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          lesson.lessonTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.nunito(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '$mastered/${lesson.totalWordCount} words mastered',
                          style: AppTypography.nunito(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${accuracy.toStringAsFixed(0)}%',
                    style: AppTypography.baloo2(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF2563EB),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
        if (lessons.isEmpty)
          ...fallbackProgress.map(
            (progress) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.menu_book_rounded,
                      color: Color(0xFF2563EB),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        progress.lessonTitle,
                        style: AppTypography.nunito(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                    ),
                    Text(
                      '${progress.accuracyRate.toStringAsFixed(0)}%',
                      style: AppTypography.baloo2(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF2563EB),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        _buildProgressSummaryRow(
          'Lesson 1 + Lesson 2 average',
          lessonAverage,
          Icons.menu_book_rounded,
          const Color(0xFF2563EB),
        ),
        const SizedBox(height: 8),
        _buildProgressSummaryRow(
          'Cumulative review average',
          cumulativeAverage,
          Icons.all_inclusive_rounded,
          const Color(0xFF9333EA),
        ),
        const SizedBox(height: 8),
        _buildProgressSummaryRow(
          'Overall lesson + cumulative average',
          combinedAverage,
          Icons.analytics_outlined,
          const Color(0xFF059669),
        ),
      ],
    );
  }

  Widget _buildProgressSummaryRow(
    String label,
    double? value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: AppTypography.nunito(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF475569),
              ),
            ),
          ),
          Text(
            value == null ? '--' : '${value.toStringAsFixed(0)}%',
            style: AppTypography.nunito(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreCard({
    required String label,
    required int points,
    required String mastery,
    required double? accuracy,
    required List<Color> gradientColors,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: gradientColors.last.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTypography.nunito(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$points pts',
            style: AppTypography.baloo2(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          if (accuracy != null) ...[
            const SizedBox(height: 2),
            Text(
              '${accuracy.toStringAsFixed(0)}% accuracy',
              style: AppTypography.nunito(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Colors.white.withValues(alpha: 0.8),
              ),
            ),
          ],
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${_masteryEmoji(mastery)} ${_masteryCap(mastery)}',
              style: AppTypography.nunito(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: AppTypography.nunito(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.65),
            ),
          ),
        ],
      ),
    );
  }

  Widget _loadingCard() {
    return Container(
      height: 160,
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
    );
  }

  Widget _buildStatRow(List<Widget> chips) {
    return Row(
      children:
          chips
              .map((c) => Expanded(child: c))
              .expand((w) => [w, const SizedBox(width: 10)])
              .toList()
            ..removeLast(),
    );
  }

  Widget _statChip({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 6),
          Text(
            value,
            style: AppTypography.baloo2(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          Text(
            label,
            style: AppTypography.nunito(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }

  // ── Lessons Tab (Category-First) ─────────────────────────────────────────────

  IconData _categoryIcon(String name) {
    final l = name.toLowerCase();
    if (l.contains('kitchen') || l.contains('cook') || l.contains('food')) {
      return Icons.soup_kitchen_rounded;
    }
    if (l.contains('school') || l.contains('class') || l.contains('study')) {
      return Icons.backpack_rounded;
    }
    if (l.contains('people') || l.contains('family') || l.contains('body')) {
      return Icons.face_rounded;
    }
    if (l.contains('home') || l.contains('house') || l.contains('room')) {
      return Icons.cottage_rounded;
    }
    if (l.contains('animal') || l.contains('pet')) return Icons.pets_rounded;
    if (l.contains('number') || l.contains('math')) {
      return Icons.calculate_rounded;
    }
    if (l.contains('color') || l.contains('colour')) {
      return Icons.palette_rounded;
    }
    if (l.contains('sport') || l.contains('game')) return Icons.sports_rounded;
    return Icons.auto_stories_rounded;
  }

  Color _categoryColor(int index) {
    const colors = [
      Color(0xFF2563EB),
      Color(0xFF16A34A),
      Color(0xFFD97706),
      Color(0xFF9333EA),
      Color(0xFFE11D48),
      Color(0xFF0D9488),
    ];
    return colors[index % colors.length];
  }

  Color _categoryBg(int index) {
    const bgs = [
      Color(0xFFEFF6FF),
      Color(0xFFF0FDF4),
      Color(0xFFFFFBEB),
      Color(0xFFFAF5FF),
      Color(0xFFFFF1F2),
      Color(0xFFF0FDFA),
    ];
    return bgs[index % bgs.length];
  }

  Widget _buildLessonsTab() {
    if (_categoriesLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_classCategories.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.menu_book_rounded,
              size: 48,
              color: Color(0xFFCBD5E1),
            ),
            const SizedBox(height: 12),
            Text(
              'No categories in this class yet.',
              style: AppTypography.nunito(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF94A3B8),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Your teacher will add lessons soon!',
              style: AppTypography.nunito(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: const Color(0xFFCBD5E1),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      itemCount: _classCategories.length,
      itemBuilder: (_, i) {
        final cat = _classCategories[i];
        final catId = cat['categoryId']?.toString() ?? '';
        final catName = cat['categoryName']?.toString() ?? 'Category';
        final accent = _categoryColor(i);
        final bg = _categoryBg(i);
        final icon = _categoryIcon(catName);

        return GestureDetector(
          onTap: () {
            // Set active classroom context
            Provider.of<LessonProvider>(
              context,
              listen: false,
            ).setActiveClassroom(widget.classId, widget.className);
            // Navigate: category → lessons, with classId so LessonPathScreen loads class lessons
            context.push(
              '/category/$catId/lessons'
              '?name=${Uri.encodeComponent(catName)}'
              '&classId=${widget.classId}',
            );
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: accent.withValues(alpha: 0.25),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: accent.withValues(alpha: 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                // Icon circle
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: accent.withValues(alpha: 0.18),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Icon(icon, color: accent, size: 26),
                ),
                const SizedBox(width: 16),
                // Name & subtitle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        catName,
                        style: AppTypography.baloo2(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: accent.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.school_rounded,
                                  size: 11,
                                  color: accent,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Class Activity',
                                  style: AppTypography.nunito(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: accent,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Arrow
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: accent.withValues(alpha: 0.6),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Leaderboard Tab ─────────────────────────────────────────────────────────

  Widget _buildLeaderboardTab(String? currentLearnerId) {
    return Column(
      children: [
        // Range toggle
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Row(
            children: [
              Expanded(child: _rangeButton('weekly', 'Weekly')),
              const SizedBox(width: 10),
              Expanded(child: _rangeButton('all', 'All Time')),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFBBF7D0)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.people_alt_rounded,
                  size: 14,
                  color: Color(0xFF16A34A),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Class Leaderboard — only your classmates appear here.',
                    style: AppTypography.nunito(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF15803D),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: _lbLoading
              ? const Center(child: CircularProgressIndicator())
              : _leaderboard.isEmpty
              ? _buildEmptyLeaderboard()
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                  itemCount: _leaderboard.length,
                  itemBuilder: (_, i) => _buildLeaderboardEntry(
                    _leaderboard[i],
                    i,
                    currentLearnerId,
                  ),
                ),
        ),
      ],
    );
  }

  Widget _rangeButton(String value, String label) {
    final selected = _lbRange == value;
    return GestureDetector(
      onTap: () {
        if (_lbRange != value) {
          setState(() => _lbRange = value);
          _reloadLeaderboard();
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF2563EB) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: AppTypography.nunito(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: selected ? Colors.white : const Color(0xFF64748B),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyLeaderboard() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.leaderboard_rounded,
            size: 48,
            color: Color(0xFFCBD5E1),
          ),
          const SizedBox(height: 12),
          Text(
            'No class activity yet.',
            style: AppTypography.nunito(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Complete lessons from the class\nto appear on the leaderboard!',
            textAlign: TextAlign.center,
            style: AppTypography.nunito(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: const Color(0xFFCBD5E1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboardEntry(
    Map<String, dynamic> entry,
    int index,
    String? currentLearnerId,
  ) {
    final rank = (entry['rank'] as num?)?.toInt() ?? (index + 1);
    final name = entry['displayName']?.toString() ?? '—';
    final points = (entry['points'] as num?)?.toInt() ?? 0;
    final tier = entry['tier']?.toString() ?? 'BRONZE';
    final learnerId = entry['learnerId']?.toString();
    final isMe = learnerId != null && learnerId == currentLearnerId;

    final rankColors = {
      1: const Color(0xFFFBBF24),
      2: const Color(0xFF94A3B8),
      3: const Color(0xFFCD7F32),
    };
    final rankColor = rankColors[rank] ?? const Color(0xFF2563EB);

    return AnimatedOpacity(
      opacity: 1.0,
      duration: Duration(milliseconds: 150 + index * 30),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isMe ? const Color(0xFFEFF6FF) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isMe ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0),
            width: isMe ? 1.5 : 1,
          ),
          boxShadow: isMe
              ? [
                  BoxShadow(
                    color: const Color(0xFF2563EB).withValues(alpha: 0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Row(
          children: [
            // Rank
            SizedBox(
              width: 36,
              child: rank <= 3
                  ? Icon(Icons.emoji_events_rounded, color: rankColor, size: 24)
                  : Text(
                      '#$rank',
                      style: AppTypography.baloo2(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF94A3B8),
                      ),
                    ),
            ),
            const SizedBox(width: 10),
            // Avatar placeholder
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: _tierColor(tier).withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: AppTypography.baloo2(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: _tierColor(tier),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Name
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        isMe ? '$name (You)' : name,
                        style: AppTypography.nunito(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isMe
                              ? const Color(0xFF2563EB)
                              : const Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    _tierLabel(tier),
                    style: AppTypography.nunito(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: _tierColor(tier),
                    ),
                  ),
                ],
              ),
            ),
            // Points
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$points',
                  style: AppTypography.baloo2(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                Text(
                  'pts',
                  style: AppTypography.nunito(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Helper methods ──────────────────────────────────────────────────────────

  String _masteryEmoji(String level) {
    switch (level.toUpperCase()) {
      case 'MASTERED':
        return '🏆';
      case 'PROFICIENT':
        return '⭐';
      case 'FAMILIAR':
        return '📈';
      default:
        return '📚';
    }
  }

  String _masteryCap(String level) {
    switch (level.toUpperCase()) {
      case 'MASTERED':
        return 'Mastered';
      case 'PROFICIENT':
        return 'Proficient';
      case 'FAMILIAR':
        return 'Familiar';
      default:
        return 'Learning';
    }
  }

  Color _tierColor(String tier) {
    switch (tier.toUpperCase()) {
      case 'DIAMOND':
        return const Color(0xFF06B6D4);
      case 'GOLD':
        return const Color(0xFFF59E0B);
      case 'SILVER':
        return const Color(0xFF94A3B8);
      default:
        return const Color(0xFFCD7F32);
    }
  }

  String _tierLabel(String tier) {
    switch (tier.toUpperCase()) {
      case 'DIAMOND':
        return '💎 Diamond';
      case 'GOLD':
        return '🥇 Gold';
      case 'SILVER':
        return '🥈 Silver';
      default:
        return '🥉 Bronze';
    }
  }
}
