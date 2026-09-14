import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../core/motion/motion.dart';
import '../models/class_performance_model.dart';
import '../providers/auth_provider.dart';
import '../providers/class_provider.dart';
import '../providers/lesson_provider.dart';
import '../services/localization_service.dart';
import '../widgets/app_avatar.dart';
import '../widgets/app_3d_bottom_nav_bar.dart';
import '../widgets/badges_collection_sheet.dart';
import '../widgets/join_class_dialog.dart';

class UserDashboardScreen extends StatefulWidget {
  final bool isInsideShell;

  const UserDashboardScreen({
    super.key,
    this.isInsideShell = false,
  });

  @override
  State<UserDashboardScreen> createState() => _UserDashboardScreenState();
}

class _UserDashboardScreenState extends State<UserDashboardScreen> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  Future<Map<String, dynamic>?>? _dashboardFuture;
  Future<List<Map<String, dynamic>>>? _badgesFuture;

  String _formatGrade(String? grade) {
    if (grade == null || grade.isEmpty) return 'Grade 4';
    if (grade == 'GRADE_4') return 'Grade 4';
    if (grade == 'GRADE_5') return 'Grade 5';
    if (grade == 'GRADE_6') return 'Grade 6';
    return grade.replaceAll('_', ' ');
  }

  String _formatLanguagePreference(String? pref) {
    if (pref == 'CEBUANO_TO_ENGLISH') return 'Cebuano';
    if (pref == 'FULL_ENGLISH') return 'English';
    if (pref == 'CEBUANO_ENGLISH_MIXED') return 'Bislish (Mixed)';
    return pref ?? 'English';
  }

  void _showEditProfileDialog(BuildContext context, AuthProvider auth, String? pref) {
    final nameController = TextEditingController(text: auth.learner?.displayName ?? '');
    final ageController = TextEditingController(text: '${auth.learner?.age ?? 9}');
    String selectedGrade = auth.learner?.gradeLevel ?? 'GRADE_4';
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text(
            LocalizationService.translate(pref, 'edit_profile'),
            style: AppTypography.baloo2(fontWeight: FontWeight.w800, color: const Color(0xFF0F172A)),
          ),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: LocalizationService.translate(pref, 'display_name'),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return LocalizationService.translate(pref, 'name_empty');
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: ageController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: LocalizationService.translate(pref, 'age'),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (v) {
                    final age = int.tryParse(v ?? '');
                    if (age == null || age < 9 || age > 12) {
                      return 'Age must be between 9 and 12';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: selectedGrade,
                  decoration: InputDecoration(
                    labelText: 'Grade Level',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'GRADE_4', child: Text('Grade 4')),
                    DropdownMenuItem(value: 'GRADE_5', child: Text('Grade 5')),
                    DropdownMenuItem(value: 'GRADE_6', child: Text('Grade 6')),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setDialogState(() => selectedGrade = val);
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(LocalizationService.translate(pref, 'cancel')),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F172A),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                final age = int.parse(ageController.text.trim());
                final success = await auth.updateProfile(
                  nameController.text.trim(),
                  age,
                  gradeLevel: selectedGrade,
                );
                if (!ctx.mounted) return;
                Navigator.of(ctx).pop();
                if (success) {
                  setState(() {});
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(LocalizationService.translate(pref, 'profile_updated'))),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(auth.error ?? 'Error')),
                  );
                }
              },
              child: Text(LocalizationService.translate(pref, 'save_changes')),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final provider = Provider.of<LessonProvider>(context, listen: false);
      final classProvider = Provider.of<ClassProvider>(context, listen: false);
      setState(() {
        _dashboardFuture = provider.fetchDashboardProgress();
        final learnerId = auth.learner?.learnerId;
        _badgesFuture = provider.loadConsolidatedBadges(learnerId);
      });
      if (auth.token != null) {
        classProvider.fetchAllClassPerformances(auth.token);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final auth = Provider.of<AuthProvider>(context);
    final learner = auth.learner;
    final pref = learner?.languagePreference;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'Profile',
          style: AppTypography.baloo2(
            fontWeight: FontWeight.w800,
            fontSize: 24,
            color: const Color(0xFF06A6FF),
          ),
        ),
      ),
      body: SafeArea(
        child: FutureBuilder<Map<String, dynamic>?>(
          future: _dashboardFuture,
          builder: (context, snapshot) {
            if (_dashboardFuture == null || snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final dashboard = snapshot.data;
            if (dashboard == null) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 56),
                      const SizedBox(height: 12),
                      Text(
                        'Profile data could not be loaded.',
                        textAlign: TextAlign.center,
                        style: AppTypography.nunito(fontWeight: FontWeight.w600, color: const Color(0xFF0F172A)),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () {
                          final provider = Provider.of<LessonProvider>(context, listen: false);
                          setState(() {
                            _dashboardFuture = provider.fetchDashboardProgress();
                          });
                        },
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              );
            }

            final completedLessons = dashboard['completedLessons'] ?? 0;
            final totalLessons = dashboard['totalLessons'] ?? 0;
            final averageScore = (dashboard['averageMasteryScore'] as num?)?.toDouble() ?? 0.0;
            final pronunciationAttempts = dashboard['totalPronunciationAttempts'] ?? 0;
            final correctPronunciations = dashboard['correctPronunciationAttempts'] ?? 0;
            final cumulativeReviewsCompleted = dashboard['cumulativeReviewsCompleted'] as int? ?? 0;
            final bestCumulativeBadge = dashboard['bestCumulativeBadge'] as String?;
            final cumulativeHistory = List<Map<String, dynamic>>.from(dashboard['cumulativeReviewHistory'] ?? []);
            final completedCumulativeHistory = cumulativeHistory.where((s) => s['sessionStatus'] == 'COMPLETED').toList();
            final sandboxHistory = List<Map<String, dynamic>>.from(dashboard['sandboxHistory'] ?? []);
            final categoryBreakdowns = List<Map<String, dynamic>>.from(dashboard['categoryBreakdowns'] ?? []);

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: AppAvatar(
                      avatar: learner?.avatar,
                      name: learner?.displayName,
                      size: 110,
                      borderWidth: 3.5,
                      borderColor: const Color(0xFF0EA5E9),
                      showEditBadge: true,
                      onTap: () async {
                        final chosen = await AvatarPickerSheet.show(context);
                        if (chosen != null && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(LocalizationService.translate(pref, 'avatar_updated')),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    learner?.displayName ?? 'Learner',
                    textAlign: TextAlign.center,
                    style: AppTypography.baloo2(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  if (learner?.userId != null && learner!.userId!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFBFDBFE)),
                        ),
                        child: Text(
                          'ID: ${learner.userId}',
                          style: AppTypography.nunito(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF1D4ED8),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    '${_formatGrade(learner?.gradeLevel)}  •  Age ${learner?.age ?? '-'}  •  ${_formatLanguagePreference(learner?.languagePreference)}',
                    textAlign: TextAlign.center,
                    style: AppTypography.nunito(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Center(
                    child: OutlinedButton.icon(
                      onPressed: () => _showEditProfileDialog(context, auth, pref),
                      icon: const Icon(Icons.edit_rounded, size: 16, color: Color(0xFF0F172A)),
                      label: Text(
                        LocalizationService.translate(pref, 'edit_profile'),
                        style: AppTypography.baloo2(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
                        side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Global Performance Header (Blue) ────────────────────
                  Text(
                    'Global Performance',
                    style: AppTypography.baloo2(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF06A6FF),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
                    ),
                    child: Column(
                      children: [
                        _buildMetricRow(
                          icon: Icons.check_rounded,
                          iconBg: const Color(0xFFDCFCE7),
                          iconColor: const Color(0xFF16A34A),
                          label: LocalizationService.translate(pref, 'lessons_completed_metric'),
                          value: '$completedLessons / $totalLessons',
                        ),
                        const Divider(height: 20, color: Color(0xFFF1F5F9)),
                        _buildMetricRow(
                          icon: Icons.star_rounded,
                          iconBg: const Color(0xFFFEF3C7),
                          iconColor: const Color(0xFFD97706),
                          label: LocalizationService.translate(pref, 'avg_mastery_metric'),
                          value: '${averageScore.toStringAsFixed(0)}%',
                        ),
                        const Divider(height: 20, color: Color(0xFFF1F5F9)),
                        _buildMetricRow(
                          icon: Icons.mic_rounded,
                          iconBg: const Color(0xFFE0F2FE),
                          iconColor: const Color(0xFF0284C7),
                          label: LocalizationService.translate(pref, 'pronunciation_correct_metric'),
                          value: '$correctPronunciations / $pronunciationAttempts',
                        ),
                        const Divider(height: 20, color: Color(0xFFF1F5F9)),
                        _buildMetricRow(
                          icon: Icons.emoji_events_rounded,
                          iconBg: const Color(0xFFEFF6FF),
                          iconColor: const Color(0xFF2563EB),
                          label: LocalizationService.translate(pref, 'cumulative_reviews_completed'),
                          value: (bestCumulativeBadge != null && bestCumulativeBadge.isNotEmpty)
                              ? '$cumulativeReviewsCompleted ($bestCumulativeBadge)'
                              : '$cumulativeReviewsCompleted',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Classroom Performance Section (Blue Header) ──────────
                  _buildClassroomPerformanceSection(auth),
                  const SizedBox(height: 24),

                  // ── Category Progress Section ────────────────────────────
                  if (categoryBreakdowns.isNotEmpty) ...[
                    _buildCategoryBreakdownSection(categoryBreakdowns),
                    const SizedBox(height: 24),
                  ],

                  // ── Badges Section ─────────────────────────────────────
                  if (_badgesFuture != null)
                    FutureBuilder<List<Map<String, dynamic>>>(
                      future: _badgesFuture,
                      builder: (context, badgeSnap) {
                        if (badgeSnap.connectionState == ConnectionState.waiting) {
                          return const Padding(
                            padding: EdgeInsets.only(bottom: 24),
                            child: Center(
                                child: CircularProgressIndicator(strokeWidth: 2)),
                          );
                        }
                        final badges = badgeSnap.data ?? [];

                        // Count by tier
                        int perfectGold = 0, gold = 0, silver = 0, bronze = 0;
                        for (final b in badges) {
                          final type = (b['badgeType'] ?? '').toString().toUpperCase();
                          if (type.contains('PERFECT')) {
                            perfectGold++;
                          } else if (type.contains('GOLD')) {
                            gold++;
                          } else if (type.contains('SILVER')) {
                            silver++;
                          } else {
                            bronze++;
                          }
                        }

                        final totalCount = perfectGold + gold + silver + bronze;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    LocalizationService.translate(pref, 'lesson_badges'),
                                    style: AppTypography.baloo2(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                      color: const Color(0xFF06A6FF),
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () => BadgesCollectionSheet.show(context),
                                    child: Text(
                                      'View All',
                                      style: AppTypography.nunito(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFF06A6FF),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              if (totalCount > 0)
                                Wrap(
                                  spacing: 10,
                                  runSpacing: 10,
                                  children: [
                                    if (perfectGold > 0)
                                      App3DBadgePill(
                                        tier: AppBadgeTier.gold,
                                        count: perfectGold,
                                        customLabel: LocalizationService.translate(pref, 'badge_perfect_gold'),
                                        onTap: () => BadgesCollectionSheet.show(context),
                                      ),
                                    if (gold > 0)
                                      App3DBadgePill(
                                        tier: AppBadgeTier.gold,
                                        count: gold,
                                        customLabel: LocalizationService.translate(pref, 'badge_gold'),
                                        onTap: () => BadgesCollectionSheet.show(context),
                                      ),
                                    if (silver > 0)
                                      App3DBadgePill(
                                        tier: AppBadgeTier.silver,
                                        count: silver,
                                        customLabel: LocalizationService.translate(pref, 'badge_silver'),
                                        onTap: () => BadgesCollectionSheet.show(context),
                                      ),
                                    if (bronze > 0)
                                      App3DBadgePill(
                                        tier: AppBadgeTier.bronze,
                                        count: bronze,
                                        customLabel: LocalizationService.translate(pref, 'badge_bronze'),
                                        onTap: () => BadgesCollectionSheet.show(context),
                                      ),
                                  ],
                                )
                              else
                                App3DBadgePill(
                                  tier: AppBadgeTier.gold,
                                  count: 0,
                                  customLabel: LocalizationService.translate(pref, 'badge_gold'),
                                  onTap: () => BadgesCollectionSheet.show(context),
                                ),
                            ],
                          ),
                        );
                      },
                    ),

                  const SizedBox(height: 8),

                  // ── Past Cumulative Review Sessions ───────────────────
                  Text(
                    LocalizationService.translate(pref, 'past_cumulative_sessions'),
                    style: AppTypography.baloo2(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF06A6FF),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (completedCumulativeHistory.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: Text(
                        LocalizationService.translate(pref, 'no_cumulative_sessions'),
                        style: AppTypography.nunito(
                          fontSize: 14,
                          color: const Color(0xFF64748B),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                  else ...[
                    ...completedCumulativeHistory.take(5).map((session) {
                      final status = session['sessionStatus'] as String? ?? 'IN_PROGRESS';
                      final accuracy = (session['accuracyPercent'] as num?)?.toDouble();
                      final badge = session['badgeAwarded'] as String?;
                      final points = session['pointsEarned'] as int? ?? 0;
                      final isAbandoned = status == 'ABANDONED';
                      final isCompleted = status == 'COMPLETED';

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.02),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: isCompleted
                                    ? const Color(0xFFEFF6FF)
                                    : (isAbandoned ? const Color(0xFFFEF2F2) : const Color(0xFFF1F5F9)),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Text(
                                  isCompleted
                                      ? (badge == 'GOLD' ? '🥇' : badge == 'SILVER' ? '🥈' : '🥉')
                                      : (isAbandoned ? '⚠️' : '⏳'),
                                  style: const TextStyle(fontSize: 22),
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isCompleted
                                        ? '${LocalizationService.translate(pref, 'this_attempt')}: ${badge != null ? LocalizationService.translate(pref, badge == 'GOLD' ? 'badge_gold' : badge == 'SILVER' ? 'badge_silver' : 'badge_bronze') : 'Completed'}'
                                        : (isAbandoned ? LocalizationService.translate(pref, 'abandoned') : status),
                                    style: AppTypography.baloo2(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 15,
                                      color: isCompleted ? const Color(0xFF0F172A) : const Color(0xFFEF4444),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    accuracy != null
                                        ? '${accuracy.toStringAsFixed(0)}% accuracy · +$points pts'
                                        : (isAbandoned ? 'Session was not finished' : 'In progress'),
                                    style: AppTypography.nunito(fontSize: 13, color: const Color(0xFF64748B), fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 12),
                  ],

                  Text(
                    LocalizationService.translate(pref, 'recent_sandbox_sessions'),
                    style: AppTypography.baloo2(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF06A6FF),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (sandboxHistory.isEmpty)
                    Text(LocalizationService.translate(pref, 'no_sandbox_sessions'), style: AppTypography.nunito(color: const Color(0xFF64748B)))
                  else
                    ...sandboxHistory.take(3).map((session) {
                      final words = List<String>.from(session['words'] ?? []);
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              session['topic']?.toString() ?? session['customWord']?.toString() ?? 'Sandbox',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              words.join(', '),
                              style: const TextStyle(color: Color(0xFF64748B)),
                            ),
                          ],
                        ),
                      );
                    }),
                ],
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: widget.isInsideShell
          ? null
          : const App3DBottomNavBar(
              currentPath: '/dashboard',
            ),
    );
  }

  Widget _buildMetricRow({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: iconBg,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: AppTypography.nunito(
              color: const Color(0xFF334155),
              fontWeight: FontWeight.w700,
              fontSize: 13.5,
            ),
          ),
        ),
        Text(
          value,
          style: AppTypography.baloo2(
            color: const Color(0xFF0F172A),
            fontWeight: FontWeight.w800,
            fontSize: 15,
          ),
        ),
      ],
    );
  }

  // ── Category Progress Section ──────────────────────────────────────────────
  Widget _buildCategoryBreakdownSection(List<Map<String, dynamic>> breakdowns) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Category Progress',
          style: AppTypography.baloo2(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF06A6FF),
          ),
        ),
        const SizedBox(height: 10),
        ...breakdowns.map((cat) => _buildCategoryCard(cat)),
      ],
    );
  }

  Widget _buildCategoryCard(Map<String, dynamic> cat) {
    final categoryName = cat['categoryName'] as String? ?? 'Category';
    final overallRaw = (cat['overallAccuracy'] as num?)?.toDouble();
    final overallStr = overallRaw != null ? '${overallRaw.toStringAsFixed(0)}%' : '-';
    final cumulativeRaw = (cat['cumulativeAccuracy'] as num?)?.toDouble();
    final cumulativeStr = cumulativeRaw != null ? '${cumulativeRaw.toStringAsFixed(0)}%' : '-';
    final bestBadge = cat['bestCumulativeBadge'] as String?;
    final lessons = List<Map<String, dynamic>>.from(cat['lessons'] ?? []);

    // Badge emoji
    String badgeEmoji = '';
    if (bestBadge == 'GOLD') {
      badgeEmoji = ' 🥇';
    } else if (bestBadge == 'SILVER') {
      badgeEmoji = ' 🥈';
    } else if (bestBadge == 'BRONZE') {
      badgeEmoji = ' 🥉';
    }

    // Overall colour
    Color overallColor = const Color(0xFF64748B);
    if (overallRaw != null) {
      if (overallRaw >= 90) {
        overallColor = const Color(0xFFCA8A04);
      } else if (overallRaw >= 80) {
        overallColor = const Color(0xFF10B981);
      } else if (overallRaw >= 70) {
        overallColor = const Color(0xFF06A6FF);
      } else {
        overallColor = const Color(0xFFEF4444);
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Header: category name + overall ──────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.school_rounded, color: Color(0xFF2563EB), size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    categoryName,
                    style: TextStyle(
                      fontFamily: AppTypography.displayFontFamily,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      overallStr,
                      style: TextStyle(
                        fontFamily: AppTypography.displayFontFamily,
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                        color: overallColor,
                      ),
                    ),
                    Text(
                      'Overall',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: overallColor.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: Color(0xFFF1F5F9)),

          // ── Per-lesson rows ───────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Column(
              children: [
                ...lessons.asMap().entries.map((e) {
                  final idx = e.key;
                  final lesson = e.value;
                  final title = lesson['lessonTitle'] as String? ?? 'Lesson ${idx + 1}';
                  final accRaw = (lesson['lessonAccuracy'] as num?)?.toDouble();
                  final accStr = accRaw != null ? '${accRaw.toStringAsFixed(0)}%' : '—';
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Row(
                      children: [
                        Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            color: accRaw != null
                                ? const Color(0xFF06A6FF).withValues(alpha: 0.12)
                                : const Color(0xFFE2E8F0),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '${idx + 1}',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: accRaw != null
                                    ? const Color(0xFF06A6FF)
                                    : const Color(0xFF94A3B8),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF334155),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: accRaw != null
                                ? const Color(0xFFEFF6FF)
                                : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            accStr,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: accRaw != null
                                  ? const Color(0xFF06A6FF)
                                  : const Color(0xFF94A3B8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),

                // ── Divider before cumulative row ─────────────────────────
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Divider(height: 1, color: Color(0xFFF1F5F9)),
                ),

                // ── Cumulative Review row ─────────────────────────────────
                Row(
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(Icons.assignment_turned_in_rounded,
                          size: 13, color: Color(0xFF10B981)),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Cumulative Review',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: cumulativeRaw != null
                            ? const Color(0xFFF0FDF4)
                            : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        cumulativeStr,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: cumulativeRaw != null
                              ? const Color(0xFF10B981)
                              : const Color(0xFF94A3B8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      badgeEmoji.isNotEmpty ? badgeEmoji.trim() : 'Mod 4',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Classroom Performance Section (Blue Header) ──────────────────────────
  Widget _buildClassroomPerformanceSection(AuthProvider auth) {
    final classProvider = Provider.of<ClassProvider>(context);
    final performances = classProvider.allClassPerformances;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Classroom Performance',
              style: AppTypography.baloo2(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF06A6FF),
              ),
            ),
            if (performances.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFBFDBFE)),
                ),
                child: Text(
                  '${performances.length} ${performances.length == 1 ? "Class" : "Classes"}',
                  style: AppTypography.nunito(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0284C7),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        if (performances.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.school_outlined, color: Color(0xFF64748B), size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Not enrolled in any class yet',
                        style: AppTypography.nunito(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF334155),
                        ),
                      ),
                      Text(
                        'Join your teacher’s class to unlock class scores',
                        style: AppTypography.nunito(
                          fontSize: 11.5,
                          color: const Color(0xFF94A3B8),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () => JoinClassDialog.show(context),
                  child: Text(
                    'Join',
                    style: AppTypography.baloo2(
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF06A6FF),
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          ...performances.map((perf) => _buildClassPerformanceCard(perf)),
      ],
    );
  }

  Widget _buildClassPerformanceCard(ClassPerformanceModel perf) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            context.push('/classes/${perf.classId}?name=${Uri.encodeComponent(perf.className)}');
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF06A6FF), Color(0xFF0284C7)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.school_rounded, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            perf.className,
                            style: AppTypography.nunito(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                          Text(
                            'Class Code: ${perf.classCode}',
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 11,
                              color: Color(0xFF64748B),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8), size: 22),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFF1F5F9)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.stars_rounded, color: Color(0xFF10B981), size: 16),
                          const SizedBox(width: 4),
                          Text(
                            '${perf.classPoints} Class pts',
                            style: AppTypography.nunito(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF059669),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          const Icon(Icons.track_changes_rounded, color: Color(0xFF0284C7), size: 15),
                          const SizedBox(width: 4),
                          Text(
                            '${perf.classAccuracy.toStringAsFixed(0)}% Acc',
                            style: AppTypography.nunito(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF0284C7),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '${perf.classSessionsPlayed} sess',
                        style: AppTypography.nunito(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF64748B),
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
    );
  }
}
