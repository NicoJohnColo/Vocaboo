import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
  Future<List<Map<String, dynamic>>>? _badgesFuture;
  Future<Map<String, dynamic>?>? _dashboardFuture;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final provider = Provider.of<LessonProvider>(context, listen: false);
      final learnerId = auth.learner?.learnerId;
      if (learnerId != null) {
        setState(() {
          _badgesFuture = provider.fetchLearnerBadges(learnerId);
          _dashboardFuture = provider.fetchDashboardProgress();
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final learner = auth.learner;
    final pref = learner?.languagePreference;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.80,
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
                    const Text('🏆', style: TextStyle(fontSize: 22)),
                    const SizedBox(width: 8),
                    Text(
                      LocalizationService.translate(pref, 'lesson_badges'),
                      style: const TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF06A6FF),
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
          const Divider(height: 1, color: Color(0xFFE2E8F0)),

          // Content
          Flexible(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _badgesFuture,
              builder: (context, badgeSnap) {
                if (badgeSnap.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                  );
                }

                final badges = badgeSnap.data ?? [];

                // Count by tier
                int perfectGold = 0, gold = 0, silver = 0, bronze = 0;
                for (final b in badges) {
                  switch (b['badgeType']) {
                    case 'PERFECT_GOLD':
                      perfectGold++;
                      break;
                    case 'GOLD':
                      gold++;
                      break;
                    case 'SILVER':
                      silver++;
                      break;
                    default:
                      bronze++;
                  }
                }

                final totalBadges = badges.length;

                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Gold Collection Banner
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFEF08A), Color(0xFFFDE047)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFDE047).withValues(alpha: 0.35),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 56,
                              height: 56,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: const Center(
                                child: Text('🥇', style: TextStyle(fontSize: 30)),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Gold Collection',
                                    style: TextStyle(
                                      fontFamily: 'Outfit',
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900,
                                      color: Color(0xFF854D0E),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    totalBadges > 0
                                        ? 'You have collected $totalBadges mastery badges!'
                                        : 'Complete Cumulative Reviews to earn gold badges!',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFFA16207),
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
                      const Text(
                        'BADGE TIERS',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF94A3B8),
                          letterSpacing: 1.1,
                        ),
                      ),
                      const SizedBox(height: 10),

                      Row(
                        children: [
                          Expanded(
                            child: _badgeTierCard(
                              emoji: '🏆',
                              title: 'Perfect Gold',
                              count: perfectGold,
                              color: const Color(0xFFCA8A04),
                              bg: const Color(0xFFFEF9C3),
                              border: const Color(0xFFFDE047),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _badgeTierCard(
                              emoji: '🥇',
                              title: 'Gold',
                              count: gold,
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
                              emoji: '🥈',
                              title: 'Silver',
                              count: silver,
                              color: const Color(0xFF475569),
                              bg: const Color(0xFFF1F5F9),
                              border: const Color(0xFFCBD5E1),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _badgeTierCard(
                              emoji: '🥉',
                              title: 'Bronze',
                              count: bronze,
                              color: const Color(0xFF92400E),
                              bg: const Color(0xFFFFF7ED),
                              border: const Color(0xFFFED7AA),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Cumulative Review Badges & Categories List
                      FutureBuilder<Map<String, dynamic>?>(
                        future: _dashboardFuture,
                        builder: (context, dashSnap) {
                          final dashData = dashSnap.data;
                          final categoryBreakdowns = (dashData?['categoryBreakdowns'] as List<dynamic>?) ?? [];
                          final cumulativeHistory = (dashData?['cumulativeReviewHistory'] as List<dynamic>?) ?? [];

                          if (categoryBreakdowns.isEmpty && cumulativeHistory.isEmpty) {
                            return const SizedBox.shrink();
                          }

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (categoryBreakdowns.isNotEmpty) ...[
                                const Text(
                                  'CUMULATIVE REVIEW MEDALS',
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF94A3B8),
                                    letterSpacing: 1.1,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                ...categoryBreakdowns.map((cat) {
                                  final name = cat['categoryName'] ?? 'Category';
                                  final cumAcc = (cat['cumulativeAccuracy'] as num?)?.toDouble();
                                  final bestBadge = cat['bestCumulativeBadge'] as String?;
                                  final cumCompleted = cumAcc != null || bestBadge != null;

                                  String medal = '🎖️';
                                  Color medalBg = const Color(0xFFF8FAFC);
                                  String scoreStr = 'Incomplete';

                                  if (cumCompleted) {
                                    final accVal = cumAcc != null ? '${cumAcc.round()}%' : 'Completed';
                                    if (bestBadge == 'PERFECT_GOLD' || (cumAcc != null && cumAcc >= 100)) {
                                      medal = '🏆';
                                      medalBg = const Color(0xFFFEF9C3);
                                      scoreStr = '$accVal 🏆';
                                    } else if (bestBadge == 'GOLD' || (cumAcc != null && cumAcc >= 90)) {
                                      medal = '🥇';
                                      medalBg = const Color(0xFFFFFBEB);
                                      scoreStr = '$accVal 🥇';
                                    } else if (bestBadge == 'SILVER' || (cumAcc != null && cumAcc >= 80)) {
                                      medal = '🥈';
                                      medalBg = const Color(0xFFF1F5F9);
                                      scoreStr = '$accVal 🥈';
                                    } else {
                                      medal = '🥉';
                                      medalBg = const Color(0xFFFFF7ED);
                                      scoreStr = '$accVal 🥉';
                                    }
                                  }

                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 10),
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: const Color(0xFFE2E8F0)),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 40,
                                          height: 40,
                                          decoration: BoxDecoration(
                                            color: medalBg,
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Center(
                                            child: Text(medal, style: const TextStyle(fontSize: 20)),
                                          ),
                                        ),
                                        const SizedBox(width: 14),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                name,
                                                style: const TextStyle(
                                                  fontFamily: 'Outfit',
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w700,
                                                  color: Color(0xFF0F172A),
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                cumCompleted
                                                    ? 'Cumulative Review Completed'
                                                    : 'Cumulative Review Pending',
                                                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
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
                                            style: TextStyle(
                                              fontFamily: 'Outfit',
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
                              if (cumulativeHistory.isNotEmpty) ...[
                                const SizedBox(height: 16),
                                const Text(
                                  'PAST REVIEW SESSIONS',
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF94A3B8),
                                    letterSpacing: 1.1,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                ...cumulativeHistory.map((s) {
                                  final acc = (s['accuracyPercent'] as num?)?.toDouble();
                                  final badge = s['badgeAwarded'] as String?;
                                  final points = s['pointsEarned'] as int? ?? 0;

                                  String badgeEmoji = '🥇';
                                  Color medalBg = const Color(0xFFFFFBEB);
                                  if (badge == 'PERFECT_GOLD' || (acc != null && acc >= 100)) {
                                    badgeEmoji = '🏆';
                                    medalBg = const Color(0xFFFEF9C3);
                                  } else if (badge == 'GOLD' || (acc != null && acc >= 90)) {
                                    badgeEmoji = '🥇';
                                    medalBg = const Color(0xFFFFFBEB);
                                  } else if (badge == 'SILVER' || (acc != null && acc >= 80)) {
                                    badgeEmoji = '🥈';
                                    medalBg = const Color(0xFFF1F5F9);
                                  } else if (badge == 'BRONZE') {
                                    badgeEmoji = '🥉';
                                    medalBg = const Color(0xFFFFF7ED);
                                  }

                                  final scoreDisplay = acc != null ? '${acc.round()}%' : 'Completed';

                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 10),
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: const Color(0xFFE2E8F0)),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 40,
                                          height: 40,
                                          decoration: BoxDecoration(
                                            color: medalBg,
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Center(
                                            child: Text(badgeEmoji, style: const TextStyle(fontSize: 20)),
                                          ),
                                        ),
                                        const SizedBox(width: 14),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const Text(
                                                'Cumulative Review',
                                                style: TextStyle(
                                                  fontFamily: 'Outfit',
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w700,
                                                  color: Color(0xFF0F172A),
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                points > 0 ? '$points XP Earned' : 'Session Finished',
                                                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFECFDF5),
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: Text(
                                            '$scoreDisplay $badgeEmoji',
                                            style: const TextStyle(
                                              fontFamily: 'Outfit',
                                              fontSize: 13,
                                              fontWeight: FontWeight.w800,
                                              color: Color(0xFF059669),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                              ],
                            ],
                          );
                        },
                      ),
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
    required String emoji,
    required String title,
    required int count,
    required Color color,
    required Color bg,
    required Color border,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border, width: 1.2),
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$count',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
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
