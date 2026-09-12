import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../core/motion/motion.dart';
import '../models/learner_category_progress_model.dart';
import '../models/learner_lesson_progress_model.dart';
import '../models/learner_progress_model.dart';
import '../providers/auth_provider.dart';
import '../providers/lesson_provider.dart';
import '../services/localization_service.dart';
import '../services/local_storage_service.dart';
import '../widgets/badges_collection_sheet.dart';
import '../widgets/streak_calendar_sheet.dart';
import '../widgets/app_avatar.dart';
import '../widgets/app_3d_bottom_nav_bar.dart';
import 'categories_screen.dart';

class HomeScreen extends StatefulWidget {
  final bool isInsideShell;

  const HomeScreen({super.key, this.isInsideShell = false});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  bool _isOnline = true;
  Timer? _connectivityTimer;
  String? _previousLanguagePreference;
  int _weeklyStreak = 1;
  int _badgeCount = 0;

  String _selectedNationality = 'Philippines';
  String _selectedDemonym = 'Filipino';
  String _selectedFlag = '🇵🇭';

  static const List<Map<String, String>> _nationalities = [
    {'name': 'Philippines', 'demonym': 'Filipino', 'flag': '🇵🇭'},
    {'name': 'United States', 'demonym': 'American', 'flag': '🇺🇸'},
    {'name': 'Japan', 'demonym': 'Japanese', 'flag': '🇯🇵'},
    {'name': 'South Korea', 'demonym': 'Korean', 'flag': '🇰🇷'},
    {'name': 'Canada', 'demonym': 'Canadian', 'flag': '🇨🇦'},
    {'name': 'United Kingdom', 'demonym': 'British', 'flag': '🇬🇧'},
    {'name': 'Australia', 'demonym': 'Australian', 'flag': '🇦🇺'},
    {'name': 'Singapore', 'demonym': 'Singaporean', 'flag': '🇸🇬'},
    {'name': 'Germany', 'demonym': 'German', 'flag': '🇩🇪'},
    {'name': 'Spain', 'demonym': 'Spanish', 'flag': '🇪🇸'},
  ];

  LearnerProgressModel? _learnerProgress;
  List<LearnerCategoryProgressModel> _categoryProgressList = [];
  LearnerLessonProgressModel? _continueLesson;
  String? _continueCategoryName;
  String? _continueCategoryId;

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
    _connectivityTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => _checkConnectivity(),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadHomeData();
    });
  }

  Future<void> _loadHomeData() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final provider = Provider.of<LessonProvider>(context, listen: false);
    final learnerId = auth.learner?.learnerId;

    await provider.loadCategories();
    _loadWeeklyStreak();
    _loadBadgesCount();
    _loadNationality();

    if (learnerId != null) {
      try {
        final results = await Future.wait([
          provider.fetchLearnerProgressDetails(learnerId),
          provider.fetchLearnerCategoryProgress(learnerId),
          provider.fetchLearnerLessonProgress(learnerId),
        ]);
        if (mounted) {
          final progress = results[0] as LearnerProgressModel?;
          final catProgress = results[1] as List<LearnerCategoryProgressModel>;
          final lesProgress = results[2] as List<LearnerLessonProgressModel>;

          // Find the active or next unfinished lesson
          LearnerLessonProgressModel? activeLesson;
          String? catName;
          String? catId;

          for (final lp in lesProgress) {
            if (lp.status != 'COMPLETED') {
              activeLesson = lp;
              break;
            }
          }
          if (activeLesson == null && lesProgress.isNotEmpty) {
            activeLesson = lesProgress.first;
          }

          if (activeLesson != null) {
            for (final cat in provider.categories) {
              if (cat.categoryId == activeLesson.categoryId) {
                catName = cat.categoryName;
                catId = cat.categoryId;
                break;
              }
            }
          }

          setState(() {
            _learnerProgress = progress;
            _categoryProgressList = catProgress;
            _continueLesson = activeLesson;
            _continueCategoryName = catName;
            _continueCategoryId = catId;
          });
        }
      } catch (e) {
        debugPrint('Error loading home dynamic progress: $e');
      }
    }
  }

  Future<void> _loadNationality() async {
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final learnerId = auth.learner?.learnerId;
      final saved = await LocalStorageService.getNationality(
        learnerId: learnerId,
      );
      final item = _nationalities.firstWhere(
        (n) => n['name'] == saved,
        orElse: () => _nationalities.first,
      );
      if (mounted) {
        setState(() {
          _selectedNationality = item['name']!;
          _selectedDemonym = item['demonym']!;
          _selectedFlag = item['flag']!;
        });
      }
    } catch (_) {}
  }

  void _showNationalitySelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 38,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    const Text('🌍', style: TextStyle(fontSize: 22)),
                    const SizedBox(width: 8),
                    Text(
                      'Select Nationality',
                      style: AppTypography.baloo2(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _nationalities.length,
                    itemBuilder: (context, index) {
                      final item = _nationalities[index];
                      final isSelected = item['name'] == _selectedNationality;
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        leading: Text(
                          item['flag']!,
                          style: const TextStyle(fontSize: 24),
                        ),
                        title: Text(
                          item['name']!,
                          style: AppTypography.baloo2(
                            fontSize: 15,
                            fontWeight: isSelected
                                ? FontWeight.w800
                                : FontWeight.w600,
                            color: isSelected
                                ? const Color(0xFF0284C7)
                                : const Color(0xFF1E293B),
                          ),
                        ),
                        subtitle: Text(
                          item['demonym']!,
                          style: AppTypography.nunito(
                            fontSize: 12,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                        trailing: isSelected
                            ? const Icon(
                                Icons.check_circle_rounded,
                                color: Color(0xFF0284C7),
                                size: 22,
                              )
                            : null,
                        onTap: () async {
                          final auth = Provider.of<AuthProvider>(
                            context,
                            listen: false,
                          );
                          final learnerId = auth.learner?.learnerId;
                          final selected = item['name']!;
                          final demonym = item['demonym']!;
                          final flag = item['flag']!;
                          await LocalStorageService.setNationality(
                            selected,
                            learnerId: learnerId,
                          );
                          if (mounted) {
                            setState(() {
                              _selectedNationality = selected;
                              _selectedDemonym = demonym;
                              _selectedFlag = flag;
                            });
                          }
                          if (ctx.mounted) Navigator.pop(ctx);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _loadWeeklyStreak() async {
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final provider = Provider.of<LessonProvider>(context, listen: false);
      final learnerId = auth.learner?.learnerId;

      if (learnerId != null && learnerId.isNotEmpty) {
        // Initial local load for instant UI
        final localStreak = await LocalStorageService.getWeeklyHighestStreak(
          learnerId: learnerId,
        );
        if (mounted) {
          setState(() => _weeklyStreak = localStreak);
        }

        // Fetch fresh stats from backend
        final stats = await provider.fetchLearnerActivityStats(learnerId);
        if (stats != null) {
          await LocalStorageService.saveLearnerActivityData(
            learnerId,
            stats.activeDates.toList(),
            stats.currentStreak,
          );
          if (mounted) {
            setState(() => _weeklyStreak = stats.currentStreak);
          }
        }
      } else {
        final streak = await LocalStorageService.getWeeklyHighestStreak();
        if (mounted) {
          setState(() => _weeklyStreak = streak);
        }
      }
    } catch (_) {}
  }

  Future<void> _loadBadgesCount() async {
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final provider = Provider.of<LessonProvider>(context, listen: false);
      final list = await provider.loadConsolidatedBadges(
        auth.learner?.learnerId,
      );
      if (mounted) {
        setState(() => _badgeCount = list.length);
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _connectivityTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkConnectivity() async {
    try {
      final result = await InternetAddress.lookup(
        'google.com',
      ).timeout(const Duration(seconds: 4));
      final online = result.isNotEmpty && result[0].rawAddress.isNotEmpty;
      if (mounted && online != _isOnline) {
        setState(() => _isOnline = online);
      }
    } on SocketException catch (_) {
      if (mounted && _isOnline) {
        setState(() => _isOnline = false);
      }
    } on TimeoutException catch (_) {
      if (mounted && _isOnline) {
        setState(() => _isOnline = false);
      }
    } catch (_) {
      if (mounted && _isOnline) {
        setState(() => _isOnline = false);
      }
    }
  }

  Color _getCategoryCardBg(int index) {
    const pastelBgs = [
      Color(0xFFEFF6FF), // Soft Blue
      Color(0xFFF0FDF4), // Mint Green
      Color(0xFFFFFBEB), // Warm Cream
      Color(0xFFF0F9FF), // Soft Sky
      Color(0xFFFFF1F2), // Soft Rose
      Color(0xFFF0FDFA), // Soft Teal
    ];
    return pastelBgs[index % pastelBgs.length];
  }

  IconData _getCategoryIcon(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('kitchen') ||
        lower.contains('cook') ||
        lower.contains('food')) {
      return Icons.soup_kitchen_rounded;
    }
    if (lower.contains('school') ||
        lower.contains('class') ||
        lower.contains('study')) {
      return Icons.backpack_rounded;
    }
    if (lower.contains('people') ||
        lower.contains('family') ||
        lower.contains('body')) {
      return Icons.face_rounded;
    }
    if (lower.contains('home') ||
        lower.contains('house') ||
        lower.contains('room')) {
      return Icons.cottage_rounded;
    }
    if (lower.contains('animal') || lower.contains('pet')) {
      return Icons.pets_rounded;
    }
    return Icons.auto_stories_rounded;
  }

  Color _getCategoryAccent(int index) {
    const accents = [
      Color(0xFF0284C7), // Blue
      Color(0xFF16A34A), // Green
      Color(0xFFD97706), // Amber
      Color(0xFF2563EB), // Royal Blue
      Color(0xFFE11D48), // Rose
      Color(0xFF0D9488), // Teal
    ];
    return accents[index % accents.length];
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final auth = Provider.of<AuthProvider>(context);
    final lessons = Provider.of<LessonProvider>(context);

    final learner = auth.learner;
    final pref = learner?.languagePreference;

    if (pref != _previousLanguagePreference) {
      _previousLanguagePreference = pref;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadHomeData();
      });
    }

    // Dynamic Continue Learning values
    final continueCategory =
        _continueCategoryName ??
        (lessons.categories.isNotEmpty
            ? lessons.categories.first.categoryName
            : 'Kitchen');
    final continueLessonTitle = _continueLesson?.lessonTitle ?? 'Lesson 1';
    final continueStars = _continueLesson?.starsEarned ?? 0;
    final continueAccuracy = _continueLesson?.accuracyRate ?? 0.0;
    final continueProgress = continueAccuracy > 0
        ? (continueAccuracy / 100.0).clamp(0.0, 1.0)
        : (_continueLesson != null ? 0.25 : 0.05);
    final continueCatId =
        _continueCategoryId ??
        (lessons.categories.isNotEmpty
            ? lessons.categories.first.categoryId
            : '1');

    // Dynamic Today's Goal values
    final wordsMasteredTotal = _learnerProgress?.wordsMasteredCount ?? 0;
    final todayGoalProgress =
        (wordsMasteredTotal > 0 && wordsMasteredTotal % 10 == 0)
        ? 10
        : (wordsMasteredTotal % 10);
    final goalFraction = (todayGoalProgress / 10.0).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        titleSpacing: 0,
        toolbarHeight: 64,
        title: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0F172A).withValues(alpha: 0.05),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                // ── 1. Nationality Flag (Dropdown on tap) ───────────────
                Expanded(
                  child: GestureDetector(
                    onTap: () => _showNationalitySelector(context),
                    behavior: HitTestBehavior.opaque,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _selectedFlag,
                              style: const TextStyle(fontSize: 22),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.keyboard_arrow_down_rounded,
                              size: 18,
                              color: Color(0xFF64748B),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // ── 2. Fire Streak + Count Number ─────────────────────
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      StreakCalendarSheet.show(
                        context,
                      ).then((_) => _loadWeeklyStreak());
                    },
                    behavior: HitTestBehavior.opaque,
                    child: Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('🔥', style: TextStyle(fontSize: 20)),
                          const SizedBox(width: 6),
                          Text(
                            '$_weeklyStreak',
                            style: AppTypography.baloo2(
                              fontSize: 16.5,
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFFEA580C),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // ── 3. Trophy + Points/Badges Count ───────────────────
                Expanded(
                  child: GestureDetector(
                    onTap: () => BadgesCollectionSheet.show(context),
                    behavior: HitTestBehavior.opaque,
                    child: Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('🏆', style: TextStyle(fontSize: 20)),
                          const SizedBox(width: 6),
                          Text(
                            '$_badgeCount',
                            style: AppTypography.baloo2(
                              fontSize: 16.5,
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFFB45309),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // ── 4. Connectivity Signal Bars ||| ───────────────────
                Expanded(
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        _buildToonyBar(height: 7, isActive: _isOnline),
                        const SizedBox(width: 2.5),
                        _buildToonyBar(height: 11, isActive: _isOnline),
                        const SizedBox(width: 2.5),
                        _buildToonyBar(height: 15, isActive: _isOnline),
                        const SizedBox(width: 2.5),
                        _buildToonyBar(height: 19, isActive: _isOnline),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: AppRefreshIndicator(
        onRefresh: () async {
          await _loadHomeData();
        },
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Greeting Card ──────────────────────────────────────
              AppPressable(
                onTap: () => context.go('/dashboard'),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFFE2E8F0),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0F172A).withValues(alpha: 0.03),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      AppAvatar(
                        avatar: learner?.avatar,
                        name: learner?.displayName,
                        size: 52,
                        showEditBadge: false,
                        onTap: () async {
                          final chosen = await AvatarPickerSheet.show(context);
                          if (chosen != null && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  LocalizationService.translate(
                                    pref,
                                    'avatar_updated',
                                  ),
                                ),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        },
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${LocalizationService.translate(pref, 'hello')}, ${learner?.displayName ?? "Learner"}!',
                              style: AppTypography.baloo2(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 3.5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFEF3C7),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.school_rounded,
                                        size: 13,
                                        color: Color(0xFFD97706),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        (learner?.gradeLevel ?? 'GRADE_4').replaceAll('GRADE_', 'Grade '),
                                        style: AppTypography.baloo2(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w800,
                                          color: const Color(0xFFD97706),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 3.5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEFF6FF),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.person_rounded,
                                        size: 13,
                                        color: Color(0xFF0284C7),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Age: ${learner?.age ?? 10}',
                                        style: AppTypography.baloo2(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w800,
                                          color: const Color(0xFF0284C7),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 3.5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        _selectedFlag,
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        _selectedDemonym,
                                        style: AppTypography.baloo2(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w800,
                                          color: const Color(0xFF475569),
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
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: Color(0xFF94A3B8),
                        size: 24,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // ── Featured Banner: Sandbox Mode ──────────────────────
              AppPressable(
                onTap: () => context.push(
                  '/loading',
                  extra: {
                    'duration': 5000,
                    'redirectPath': '/sandbox',
                  },
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF38BDF8), Color(0xFF0284C7)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0284C7).withValues(alpha: 0.28),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.auto_awesome_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              LocalizationService.translate(
                                pref,
                                'sandbox_title',
                              ),
                              style: AppTypography.baloo2(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Practice custom words and topics',
                              style: AppTypography.nunito(
                                fontSize: 12.5,
                                color: Colors.white.withValues(alpha: 0.9),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // ── Dynamic Continue Learning Card ─────────────────────
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFFE2E8F0),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0F172A).withValues(alpha: 0.03),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Continue Learning',
                          style: AppTypography.baloo2(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right_rounded,
                          color: Color(0xFF94A3B8),
                          size: 20,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF38BDF8), Color(0xFF0284C7)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.menu_book_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '$continueCategory • $continueLessonTitle',
                                style: AppTypography.baloo2(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF0F172A),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (_continueLesson?.className != null &&
                                  _continueLesson!.className!.isNotEmpty) ...[
                                const SizedBox(height: 3),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 7,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEFF6FF),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: const Color(
                                        0xFFBFDBFE,
                                      ).withValues(alpha: 0.4),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.school_rounded,
                                        size: 11,
                                        color: Color(0xFF2563EB),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        _continueLesson!.className!,
                                        style: AppTypography.nunito(
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w700,
                                          color: const Color(0xFF1D4ED8),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              const SizedBox(height: 3),
                              Text(
                                _continueLesson != null
                                    ? '$continueStars / 3 stars · ${continueAccuracy.toStringAsFixed(0)}% accuracy'
                                    : 'In progress · Start learning',
                                style: AppTypography.nunito(
                                  fontSize: 12,
                                  color: const Color(0xFF64748B),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: continueProgress > 0
                                      ? continueProgress
                                      : 0.05,
                                  minHeight: 4.5,
                                  backgroundColor: const Color(0xFFE2E8F0),
                                  valueColor:
                                      const AlwaysStoppedAnimation<Color>(
                                        Color(0xFF0284C7),
                                      ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: () {
                            context.push(
                              '/category/$continueCatId/lessons?name=${Uri.encodeComponent(continueCategory)}',
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFEFF6FF),
                            foregroundColor: const Color(0xFF0284C7),
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: Text(
                            'Continue',
                            style: AppTypography.baloo2(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // ── Dynamic Your Categories Section ────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Your Categories',
                    style: AppTypography.baloo2(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const CategoriesScreen(),
                        ),
                      );
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'View all',
                          style: AppTypography.baloo2(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF0284C7),
                          ),
                        ),
                        const SizedBox(width: 2),
                        const Icon(
                          Icons.chevron_right_rounded,
                          size: 16,
                          color: Color(0xFF0284C7),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // ── Categories Grid (Dynamic from Backend) ─────────────
              if (lessons.isLoading && lessons.categories.isEmpty)
                AppShimmer.grid(itemCount: 4, crossAxisCount: 2)
              else if (lessons.categories.isEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 24,
                    horizontal: 16,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Center(
                    child: Text(
                      'No categories available yet.',
                      style: AppTypography.nunito(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF94A3B8),
                      ),
                    ),
                  ),
                )
              else
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.1,
                  ),
                  itemCount: lessons.categories.length > 4
                      ? 4
                      : lessons.categories.length,
                  itemBuilder: (context, index) {
                    final category = lessons.categories[index];
                    final catName = category.categoryName;
                    final isFirst = index == 0;
                    final icon = _getCategoryIcon(catName);
                    final bg = _getCategoryCardBg(index);
                    final accent = _getCategoryAccent(index);

                    // Find dynamic progress for this category
                    LearnerCategoryProgressModel? catProg;
                    for (final cp in _categoryProgressList) {
                      if (cp.categoryId == category.categoryId) {
                        catProg = cp;
                        break;
                      }
                    }
                    final completedLessons = catProg?.completedLessons ?? 0;
                    final totalLessons = catProg?.totalLessons ?? 0;

                    return GestureDetector(
                      onTap: () {
                        context.push(
                          '/category/${category.categoryId}/lessons?name=${Uri.encodeComponent(category.categoryName)}',
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: bg,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: isFirst
                                ? const Color(0xFF0284C7)
                                : const Color(0xFFE2E8F0),
                            width: isFirst ? 2.0 : 1.0,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: isFirst
                                  ? const Color(
                                      0xFF0284C7,
                                    ).withValues(alpha: 0.08)
                                  : Colors.transparent,
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // 3D-styled theme icon circle
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: accent.withValues(alpha: 0.15),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Icon(icon, color: accent, size: 28),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              catName,
                              style: AppTypography.baloo2(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF0F172A),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '$completedLessons / $totalLessons lessons',
                              style: AppTypography.nunito(
                                fontSize: 11.5,
                                color: const Color(0xFF64748B),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              const SizedBox(height: 18),

              // ── Today's Goal Card (Dynamic from Backend) ────────────
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: const Color(0xFFE2E8F0),
                    width: 1.2,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Today's Goal",
                            style: AppTypography.baloo2(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Container(
                                width: 28,
                                height: 28,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFFEF3C7),
                                  shape: BoxShape.circle,
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.star_rounded,
                                    color: Color(0xFFF59E0B),
                                    size: 18,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Learn 10 new words',
                                  style: AppTypography.nunito(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF334155),
                                  ),
                                ),
                              ),
                              Text(
                                '$todayGoalProgress / 10',
                                style: AppTypography.baloo2(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF0284C7),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: goalFraction > 0 ? goalFraction : 0.05,
                              minHeight: 5.5,
                              backgroundColor: const Color(0xFFCBD5E1),
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                Color(0xFF0284C7),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    // Mascot Illustration Graphic (Turtle thumbs up mascot - noticeably bigger)
                    SizedBox(
                      width: 100,
                      height: 100,
                      child: Image.asset(
                        'assets/images/thumbsup.png',
                        fit: BoxFit.contain,
                        errorBuilder: (_, _, _) => Image.asset(
                          'assets/images/turtle_thumbs_up.png',
                          fit: BoxFit.contain,
                          errorBuilder: (_, _, _) => Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              color: const Color(0xFFDCFCE7),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFF86EFAC),
                                width: 1.5,
                              ),
                            ),
                            child: const Center(
                              child: Text('🐢', style: TextStyle(fontSize: 42)),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: widget.isInsideShell
          ? null
          : const App3DBottomNavBar(currentPath: '/home'),
    );
  }

  Widget _buildToonyBar({required double height, required bool isActive}) {
    return Container(
      width: 3.5,
      height: height,
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF16A34A) : const Color(0xFFEF4444),
        borderRadius: BorderRadius.circular(2.0),
      ),
    );
  }
}
