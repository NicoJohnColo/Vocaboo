import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/lesson_provider.dart';
import '../services/localization_service.dart';
import '../widgets/mascot_visual.dart';

class UserDashboardScreen extends StatefulWidget {
  const UserDashboardScreen({super.key});

  @override
  State<UserDashboardScreen> createState() => _UserDashboardScreenState();
}

class _UserDashboardScreenState extends State<UserDashboardScreen> {
  Future<Map<String, dynamic>?>? _dashboardFuture;
  Future<List<Map<String, dynamic>>>? _badgesFuture;

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
            color: Color(0xFF0F172A),
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
            final sandboxHistory = List<Map<String, dynamic>>.from(dashboard['sandboxHistory'] ?? []);

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFE0F2FE),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF38BDF8).withValues(alpha: 0.15),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const MascotVisual(type: MascotType.bibo, size: 104),
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
                    'Age ${learner?.age ?? '-'} • ${learner?.languagePreference ?? 'FULL_ENGLISH'}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 14, color: Color(0xFF64748B)),
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
                        _buildMetricRow('Lessons completed', '$completedLessons / $totalLessons'),
                        const SizedBox(height: 12),
                        _buildMetricRow('Average mastery', '${averageScore.toStringAsFixed(0)}%'),
                        const SizedBox(height: 12),
                        _buildMetricRow('Pronunciation correct', '$correctPronunciations / $pronunciationAttempts'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

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
                              const Text(
                                'Lesson Badges',
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF0F172A),
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
                                      label: 'Perfect Gold',
                                      count: perfectGold,
                                      color: const Color(0xFFCA8A04),
                                      bg: const Color(0xFFFEF9C3),
                                      border: const Color(0xFFFDE047),
                                    ),
                                  if (gold > 0)
                                    _BadgePill(
                                      emoji: '🥇',
                                      label: 'Gold',
                                      count: gold,
                                      color: const Color(0xFFD97706),
                                      bg: const Color(0xFFFFFBEB),
                                      border: const Color(0xFFFCD34D),
                                    ),
                                  if (silver > 0)
                                    _BadgePill(
                                      emoji: '🥈',
                                      label: 'Silver',
                                      count: silver,
                                      color: const Color(0xFF475569),
                                      bg: const Color(0xFFF1F5F9),
                                      border: const Color(0xFFCBD5E1),
                                    ),
                                  if (bronze > 0)
                                    _BadgePill(
                                      emoji: '🥉',
                                      label: 'Bronze',
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

                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                            onPressed: () => GoRouter.of(context).go('/settings'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0F172A),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 0,
                          ),
                          child: const Text('Edit profile'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                            onPressed: () => GoRouter.of(context).go('/sandbox'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF06A6FF),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 0,
                          ),
                          child: const Text('Sandbox'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Wrong answers shortcut
                  GestureDetector(
                    onTap: () => GoRouter.of(context).push('/wrong-answers'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF7ED),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                            color: const Color(0xFFF97316).withValues(alpha: 0.35),
                            width: 1.5),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF97316).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.warning_amber_rounded,
                                color: Color(0xFFF97316), size: 22),
                          ),
                          const SizedBox(width: 14),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Words You Need Help With',
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14,
                                    color: Color(0xFF92400E),
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Review your wrong answers & demerits',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFFC2410C),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right_rounded,
                              color: Color(0xFFF97316)),
                        ],
                      ),
                    ),
                  ),
                  const Text(
                    'Recent sandbox sessions',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                  const SizedBox(height: 12),
                  if (sandboxHistory.isEmpty)
                    const Text('No sandbox sessions yet.', style: TextStyle(color: Color(0xFF64748B)))
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
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF1F5F9),
                      foregroundColor: const Color(0xFF0F172A),
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: Text(LocalizationService.translate(pref, 'back')),
                  ),
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
