import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/motion/motion.dart';
import '../providers/auth_provider.dart';
import '../providers/lesson_provider.dart';
import '../services/localization_service.dart';

class BadgesCollectionSheet extends StatefulWidget {
  const BadgesCollectionSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const BadgesCollectionSheet(),
    );
  }

  @override
  State<BadgesCollectionSheet> createState() => _BadgesCollectionSheetState();
}

class _BadgesCollectionSheetState extends State<BadgesCollectionSheet> {
  Future<_BadgesSheetData>? _dataFuture;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final provider = Provider.of<LessonProvider>(context, listen: false);
      setState(() {
        _dataFuture = _loadData(provider, auth.learner?.learnerId);
      });
    });
  }

  Future<_BadgesSheetData> _loadData(LessonProvider provider, String? learnerId) async {
    final dashData = await provider.fetchDashboardProgress();
    final lessonBadges = await provider.loadConsolidatedBadges(learnerId);
    final categoryBreakdowns = List<Map<String, dynamic>>.from(dashData?['categoryBreakdowns'] ?? []);
    final cumulativeHistory = List<Map<String, dynamic>>.from(dashData?['cumulativeReviewHistory'] ?? []);

    int perfectGold = 0;
    int gold = 0;
    int silver = 0;
    int bronze = 0;

    // Count lesson badges
    for (final b in lessonBadges) {
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

    // Count cumulative review medals
    for (final cat in categoryBreakdowns) {
      final cumAcc = (cat['cumulativeAccuracy'] as num?)?.toDouble();
      final bestBadge = (cat['bestCumulativeBadge'] as String?)?.toUpperCase();
      if (bestBadge == 'PERFECT_GOLD' || (cumAcc != null && cumAcc >= 100)) {
        perfectGold++;
      } else if (bestBadge == 'GOLD' || (cumAcc != null && cumAcc >= 90)) {
        gold++;
      } else if (bestBadge == 'SILVER' || (cumAcc != null && cumAcc >= 75)) {
        silver++;
      } else if (bestBadge != null || (cumAcc != null && cumAcc > 0)) {
        bronze++;
      }
    }

    final total = perfectGold + gold + silver + bronze;

    return _BadgesSheetData(
      totalBadges: total,
      perfectGoldCount: perfectGold,
      goldCount: gold,
      silverCount: silver,
      bronzeCount: bronze,
      lessonBadges: lessonBadges,
      categoryBreakdowns: categoryBreakdowns,
      cumulativeHistory: cumulativeHistory,
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final learner = auth.learner;
    final pref = learner?.languagePreference;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 16, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const App3DMiniBadgeDisc(tier: AppBadgeTier.gold, size: 26),
                    const SizedBox(width: 10),
                    Text(
                      LocalizationService.translate(pref, 'lesson_badges'),
                      style: AppTypography.baloo2(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF06A6FF),
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B), size: 22),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          Expanded(
            child: FutureBuilder<_BadgesSheetData>(
              future: _dataFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final data = snapshot.data ??
                    _BadgesSheetData(
                      totalBadges: 0,
                      perfectGoldCount: 0,
                      goldCount: 0,
                      silverCount: 0,
                      bronzeCount: 0,
                      lessonBadges: [],
                      categoryBreakdowns: [],
                      cumulativeHistory: [],
                    );

                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Banner Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFEF9C3), Color(0xFFFEF08A)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFFDE047), width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFF59E0B).withValues(alpha: 0.25),
                              offset: const Offset(0, 4),
                              blurRadius: 0,
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFCA8A04).withValues(alpha: 0.2),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Center(
                                child: App3DMiniBadgeDisc(tier: AppBadgeTier.gold, size: 36),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Gold Collection',
                                  style: AppTypography.baloo2(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF854D0E),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  (data.goldCount + data.perfectGoldCount) > 0
                                      ? 'You have collected ${data.goldCount + data.perfectGoldCount} gold ${(data.goldCount + data.perfectGoldCount) == 1 ? 'badge' : 'badges'}!'
                                      : (data.totalBadges > 0
                                          ? 'You have collected ${data.totalBadges} mastery badges! Reach 90%+ for Gold!'
                                          : 'Complete lessons with 90%+ score to earn gold badges!'),
                                  style: AppTypography.nunito(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFFA16207),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Badge Tier Counts Grid
                    Text(
                      'BADGE TIERS',
                      style: AppTypography.baloo2(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF94A3B8),
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 10),

                    Row(
                      children: [
                        Expanded(
                          child: _badgeTierCard(
                            tier: AppBadgeTier.gold,
                            title: 'Perfect Gold',
                            count: data.perfectGoldCount,
                            color: const Color(0xFFCA8A04),
                            bg: const Color(0xFFFEF9C3),
                            border: const Color(0xFFFDE047),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _badgeTierCard(
                            tier: AppBadgeTier.gold,
                            title: 'Gold (90%+)',
                            count: data.goldCount,
                            color: const Color(0xFFD97706),
                            bg: const Color(0xFFFFFBEB),
                            border: const Color(0xFFFCD34D),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _badgeTierCard(
                            tier: AppBadgeTier.silver,
                            title: 'Silver (75-89%)',
                            count: data.silverCount,
                            color: const Color(0xFF475569),
                            bg: const Color(0xFFF1F5F9),
                            border: const Color(0xFFCBD5E1),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _badgeTierCard(
                            tier: AppBadgeTier.bronze,
                            title: 'Bronze (<75%)',
                            count: data.bronzeCount,
                            color: const Color(0xFF92400E),
                            bg: const Color(0xFFFFF7ED),
                            border: const Color(0xFFFED7AA),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // ── Earned Lesson Badges List ──────────────────────────
                    if (data.lessonBadges.isNotEmpty) ...[
                      Text(
                        'EARNED LESSON BADGES (${data.lessonBadges.length})',
                        style: AppTypography.baloo2(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF94A3B8),
                          letterSpacing: 1.1,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ...data.lessonBadges.map((badge) {
                        final title = (badge['lessonTitle'] ?? 'Lesson').toString();
                        final type = (badge['badgeType'] ?? 'BRONZE').toString().toUpperCase();
                        final score = (badge['score'] as num?)?.toDouble();
                        final category = (badge['categoryName'] ?? '').toString();

                        final tier = type.contains('GOLD')
                            ? AppBadgeTier.gold
                            : (type.contains('SILVER') ? AppBadgeTier.silver : AppBadgeTier.bronze);

                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.03),
                                offset: const Offset(0, 3),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              App3DMiniBadgeDisc(tier: tier, size: 38),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      title,
                                      style: AppTypography.baloo2(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w800,
                                        color: const Color(0xFF0F172A),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      score != null
                                          ? 'Accuracy: ${score.toStringAsFixed(0)}%${category.isNotEmpty ? ' • $category' : ''}'
                                          : (category.isNotEmpty ? category : 'Mastered'),
                                      style: AppTypography.nunito(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF64748B),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              App3DBadgePill(
                                tier: tier,
                                count: 1,
                                customLabel: tier == AppBadgeTier.gold ? 'GOLD' : (tier == AppBadgeTier.silver ? 'SILVER' : 'BRONZE'),
                              ),
                            ],
                          ),
                        );
                      }),
                      const SizedBox(height: 16),
                    ],

                    // ── Cumulative Review Medals ───────────────────────────
                    if (data.categoryBreakdowns.isNotEmpty) ...[
                      Text(
                        'CUMULATIVE REVIEW MEDALS',
                        style: AppTypography.baloo2(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF94A3B8),
                          letterSpacing: 1.1,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ...data.categoryBreakdowns.map((cat) {
                        final name = cat['categoryName'] ?? 'Category';
                        final cumAcc = (cat['cumulativeAccuracy'] as num?)?.toDouble();
                        final bestBadge = (cat['bestCumulativeBadge'] as String?)?.toUpperCase();
                        final cumCompleted = cumAcc != null || bestBadge != null;

                        final tier = (bestBadge == 'PERFECT_GOLD' || (cumAcc != null && cumAcc >= 90))
                            ? AppBadgeTier.gold
                            : ((bestBadge == 'SILVER' || (cumAcc != null && cumAcc >= 75))
                                ? AppBadgeTier.silver
                                : AppBadgeTier.bronze);

                        final scoreStr = cumAcc != null ? '${cumAcc.round()}%' : (cumCompleted ? 'Completed' : 'Pending');

                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
                          ),
                          child: Row(
                            children: [
                              App3DMiniBadgeDisc(tier: tier, size: 36),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name,
                                      style: AppTypography.baloo2(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w800,
                                        color: const Color(0xFF0F172A),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      cumCompleted ? 'Cumulative Review Completed' : 'Cumulative Review Pending',
                                      style: AppTypography.nunito(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF64748B),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: cumCompleted ? const Color(0xFFECFDF5) : const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  scoreStr,
                                  style: AppTypography.baloo2(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: cumCompleted ? const Color(0xFF059669) : const Color(0xFF94A3B8),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],

                    // Empty state when no badges at all
                    if (data.totalBadges == 0) ...[
                      const SizedBox(height: 20),
                      Center(
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.emoji_events_outlined, size: 48, color: Color(0xFF94A3B8)),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No Badges Earned Yet',
                              style: AppTypography.baloo2(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Complete lessons with 90%+ score to earn your first Gold Badge!',
                              textAlign: TextAlign.center,
                              style: AppTypography.nunito(
                                fontSize: 13,
                                color: const Color(0xFF64748B),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        ),
      ],
    ),
  );
}

  Widget _badgeTierCard({
    required AppBadgeTier tier,
    required String title,
    required int count,
    required Color color,
    required Color bg,
    required Color border,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: border, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: tier.primaryColor.withValues(alpha: 0.15),
            offset: const Offset(0, 3),
            blurRadius: 0,
          ),
        ],
      ),
      child: Row(
        children: [
          App3DMiniBadgeDisc(tier: tier, size: 34),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.nunito(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$count',
                  style: AppTypography.baloo2(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BadgesSheetData {
  final int totalBadges;
  final int perfectGoldCount;
  final int goldCount;
  final int silverCount;
  final int bronzeCount;
  final List<Map<String, dynamic>> lessonBadges;
  final List<Map<String, dynamic>> categoryBreakdowns;
  final List<Map<String, dynamic>> cumulativeHistory;

  const _BadgesSheetData({
    required this.totalBadges,
    required this.perfectGoldCount,
    required this.goldCount,
    required this.silverCount,
    required this.bronzeCount,
    required this.lessonBadges,
    required this.categoryBreakdowns,
    required this.cumulativeHistory,
  });
}

