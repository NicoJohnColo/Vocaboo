import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/lesson_provider.dart';
import '../services/localization_service.dart';

class UserDashboardScreen extends StatefulWidget {
  const UserDashboardScreen({super.key});

  @override
  State<UserDashboardScreen> createState() => _UserDashboardScreenState();
}

class _UserDashboardScreenState extends State<UserDashboardScreen> {
  Future<Map<String, dynamic>?>? _dashboardFuture;
  Future<List<Map<String, dynamic>>>? _badgesFuture;

  String _formatLanguagePreference(String? pref) {
    if (pref == 'CEBUANO_TO_ENGLISH') return 'Cebuano';
    if (pref == 'FULL_ENGLISH') return 'English';
    if (pref == 'CEBUANO_ENGLISH_MIXED') return 'Mixed';
    return pref ?? 'English';
  }

  Color _getAvatarColor(String name) {
    if (name.isEmpty) return const Color(0xFF0EA5E9);
    final colors = [
      const Color(0xFF0EA5E9), // Sky Blue
      const Color(0xFF10B981), // Emerald
      const Color(0xFF8B5CF6), // Purple
      const Color(0xFFF59E0B), // Amber
      const Color(0xFFEC4899), // Pink
      const Color(0xFF6366F1), // Indigo
      const Color(0xFF14B8A6), // Teal
      const Color(0xFFF97316), // Orange
    ];
    final hash = name.codeUnits.fold(0, (sum, c) => sum + c);
    return colors[hash % colors.length];
  }

  String _getInitials(String name) {
    if (name.isEmpty) return '?';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2 && parts[1].isNotEmpty) {
      return '${parts[0][0].toUpperCase()}${parts[1][0].toUpperCase()}';
    }
    return parts[0][0].toUpperCase();
  }

  void _showEditProfileDialog(BuildContext context, AuthProvider auth, String? pref) {
    final nameController = TextEditingController(text: auth.learner?.displayName ?? '');
    final ageController = TextEditingController(text: '${auth.learner?.age ?? 9}');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          LocalizationService.translate(pref, 'edit_profile'),
          style: const TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
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
                  if (age == null || age < 1 || age > 99) {
                    return 'Please enter a valid age';
                  }
                  return null;
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
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final provider = Provider.of<LessonProvider>(context, listen: false);
      setState(() {
        _dashboardFuture = provider.fetchDashboardProgress();
        final learnerId = auth.learner?.learnerId;
        if (learnerId != null) {
          _badgesFuture = provider.fetchLearnerBadges(learnerId);
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final learner = auth.learner;
    final pref = learner?.languagePreference;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Profile',
          style: const TextStyle(
            fontFamily: 'Outfit',
            fontWeight: FontWeight.w900,
            fontSize: 24,
            color: Color(0xFF06A6FF),
          ),
        ),
        actions: const [SizedBox(width: 12)],
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
                      const Text(
                        'Profile data could not be loaded.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
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
            final sandboxHistory = List<Map<String, dynamic>>.from(dashboard['sandboxHistory'] ?? []);
            final categoryBreakdowns = List<Map<String, dynamic>>.from(dashboard['categoryBreakdowns'] ?? []);

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _getAvatarColor(learner?.displayName ?? ''),
                        boxShadow: [
                          BoxShadow(
                            color: _getAvatarColor(learner?.displayName ?? '').withValues(alpha: 0.25),
                            blurRadius: 18,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          _getInitials(learner?.displayName ?? ''),
                          style: const TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    learner?.displayName ?? 'Learner',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Age ${learner?.age ?? '-'} • ${_formatLanguagePreference(learner?.languagePreference)}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 14, color: Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: OutlinedButton.icon(
                      onPressed: () => _showEditProfileDialog(context, auth, pref),
                      icon: const Icon(Icons.edit_rounded, size: 16, color: Color(0xFF0F172A)),
                      label: Text(
                        LocalizationService.translate(pref, 'edit_profile'),
                        style: const TextStyle(
                          fontFamily: 'Outfit',
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.2),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
                    ),
                    child: Column(
                      children: [
                        _buildMetricRow(LocalizationService.translate(pref, 'lessons_completed_metric'), '$completedLessons / $totalLessons'),
                        const SizedBox(height: 12),
                        _buildMetricRow(LocalizationService.translate(pref, 'avg_mastery_metric'), '${averageScore.toStringAsFixed(0)}%'),
                        const SizedBox(height: 12),
                        _buildMetricRow(LocalizationService.translate(pref, 'pronunciation_correct_metric'), '$correctPronunciations / $pronunciationAttempts'),
                        const SizedBox(height: 12),
                        _buildMetricRow(
                          LocalizationService.translate(pref, 'cumulative_reviews_completed'),
                          bestCumulativeBadge != null
                              ? '$cumulativeReviewsCompleted · ${LocalizationService.translate(pref, bestCumulativeBadge == 'GOLD' ? 'badge_gold' : bestCumulativeBadge == 'SILVER' ? 'badge_silver' : 'badge_bronze')}'
                              : '$cumulativeReviewsCompleted',
                        ),
                      ],
                    ),
                  ),
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
                        if (badges.isEmpty) return const SizedBox.shrink();

                        // Count by tier
                        int perfectGold = 0, gold = 0, silver = 0, bronze = 0;
                        for (final b in badges) {
                          switch (b['badgeType']) {
                            case 'PERFECT_GOLD': perfectGold++; break;
                            case 'GOLD': gold++; break;
                            case 'SILVER': silver++; break;
                            default: bronze++;
                          }
                        }

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                LocalizationService.translate(pref, 'lesson_badges'),
                                style: const TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF06A6FF),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 10,
                                runSpacing: 10,
                                children: [
                                  if (perfectGold > 0)
                                    _BadgePill(
                                      emoji: '🏆',
                                      label: LocalizationService.translate(pref, 'badge_perfect_gold'),
                                      count: perfectGold,
                                      color: const Color(0xFFCA8A04),
                                      bg: const Color(0xFFFEF9C3),
                                      border: const Color(0xFFFDE047),
                                    ),
                                  if (gold > 0)
                                    _BadgePill(
                                      emoji: '🥇',
                                      label: LocalizationService.translate(pref, 'badge_gold'),
                                      count: gold,
                                      color: const Color(0xFFD97706),
                                      bg: const Color(0xFFFFFBEB),
                                      border: const Color(0xFFFCD34D),
                                    ),
                                  if (silver > 0)
                                    _BadgePill(
                                      emoji: '🥈',
                                      label: LocalizationService.translate(pref, 'badge_silver'),
                                      count: silver,
                                      color: const Color(0xFF475569),
                                      bg: const Color(0xFFF1F5F9),
                                      border: const Color(0xFFCBD5E1),
                                    ),
                                  if (bronze > 0)
                                    _BadgePill(
                                      emoji: '🥉',
                                      label: LocalizationService.translate(pref, 'badge_bronze'),
                                      count: bronze,
                                      color: const Color(0xFF92400E),
                                      bg: const Color(0xFFFFF7ED),
                                      border: const Color(0xFFFED7AA),
                                    ),
                                ],
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
                    style: const TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF06A6FF),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (cumulativeHistory.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: Text(LocalizationService.translate(pref, 'no_cumulative_sessions'), style: const TextStyle(color: Color(0xFF64748B))),
                    )
                  else ...[
                    ...cumulativeHistory.take(5).map((session) {
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
                                    style: TextStyle(
                                      fontFamily: 'Outfit',
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: isCompleted ? const Color(0xFF0F172A) : const Color(0xFFEF4444),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    accuracy != null
                                        ? '${accuracy.toStringAsFixed(0)}% accuracy · +$points pts'
                                        : (isAbandoned ? 'Session was not finished' : 'In progress'),
                                    style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
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
                    style: const TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF06A6FF),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (sandboxHistory.isEmpty)
                    Text(LocalizationService.translate(pref, 'no_sandbox_sessions'), style: const TextStyle(color: Color(0xFF64748B)))
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
    );
  }

  Widget _buildMetricRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
        Text(value, style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold)),
      ],
    );
  }

  // ── Category Progress Section ──────────────────────────────────────────────
  Widget _buildCategoryBreakdownSection(List<Map<String, dynamic>> breakdowns) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Category Progress',
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: Color(0xFF06A6FF),
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
                    color: const Color(0xFF4338CA).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.school_rounded, color: Color(0xFF4338CA), size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    categoryName,
                    style: const TextStyle(
                      fontFamily: 'Outfit',
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      overallStr,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontWeight: FontWeight.w900,
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
}

// ────────────────────────────────────────────────────────────────
// Badge Pill chip widget
// ────────────────────────────────────────────────────────────────
class _BadgePill extends StatelessWidget {
  final String emoji;
  final String label;
  final int count;
  final Color color;
  final Color bg;
  final Color border;

  const _BadgePill({
    required this.emoji,
    required this.label,
    required this.count,
    required this.color,
    required this.bg,
    required this.border,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: border, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 6),
          Text(
            '$count × $label',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
