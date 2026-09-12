import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/motion/motion.dart';
import '../providers/auth_provider.dart';
import '../providers/lesson_provider.dart';
import '../services/local_storage_service.dart';

class StreakCalendarSheet extends StatefulWidget {
  const StreakCalendarSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const StreakCalendarSheet(),
    );
  }

  @override
  State<StreakCalendarSheet> createState() => _StreakCalendarSheetState();
}

class _StreakCalendarSheetState extends State<StreakCalendarSheet> {
  int _currentStreak = 0;
  Set<String> _activeDates = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStreakData();
  }

  Future<void> _loadStreakData() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final provider = Provider.of<LessonProvider>(context, listen: false);
    final learnerId = auth.learner?.learnerId;

    int streak = 0;
    Set<String> dates = {};

    // 1. Instant load from user-scoped local storage
    if (learnerId != null && learnerId.isNotEmpty) {
      streak = await LocalStorageService.getWeeklyHighestStreak(learnerId: learnerId);
      dates = await LocalStorageService.getActiveActivityDates(learnerId: learnerId);
      if (mounted && (streak > 0 || dates.isNotEmpty)) {
        setState(() {
          _currentStreak = streak;
          _activeDates = dates;
          _isLoading = false;
        });
      }
    }

    // 2. Fetch fresh user data from backend API
    if (learnerId != null && learnerId.isNotEmpty) {
      try {
        final stats = await provider.fetchLearnerActivityStats(learnerId);
        if (stats != null) {
          streak = stats.currentStreak;
          dates = stats.activeDates;
          await LocalStorageService.saveLearnerActivityData(learnerId, stats.activeDates.toList(), stats.currentStreak);
        }
      } catch (e) {
        debugPrint('StreakCalendarSheet fetch error: $e');
      }
    }

    if (mounted) {
      setState(() {
        _currentStreak = streak;
        _activeDates = dates;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final pref = auth.learner?.languagePreference;
    final isCebuano = pref == 'CEBUANO_TO_ENGLISH';

    final now = DateTime.now();
    final monthName = _getMonthName(now.month, isCebuano);
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final firstWeekday = DateTime(now.year, now.month, 1).weekday % 7; // Sunday = 0

    final streakTitle = _currentStreak > 0
        ? (isCebuano ? '$_currentStreak ka Adlaw nga Streak!' : '$_currentStreak Days Streak!')
        : (isCebuano ? 'Pagsugod sa Imong Streak!' : 'Start Your Streak!');

    final streakSubtitle = _currentStreak > 0
        ? (isCebuano
            ? 'Mag-login ug motubag sa mga leksyon kada adlaw aron magpadayon ang imong streak!'
            : 'Log in and answer lesson activities daily to keep your streak burning!')
        : (isCebuano
            ? 'Motubag sa mga leksyon karon aron magsugod ang imong adlaw-adlaw nga streak!'
            : 'Answer lesson activities today to ignite your daily learning streak!');

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Color(0x1F000000),
            blurRadius: 24,
            offset: Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top Handle Bar
            Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 18),

            // Big Flame Header
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('🔥', style: TextStyle(fontSize: 36)),
                const SizedBox(width: 8),
                Text(
                  streakTitle,
                  style: AppTypography.baloo2(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFFEA580C),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              streakSubtitle,
              textAlign: TextAlign.center,
              style: AppTypography.nunito(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 20),

            // ── Calendar Container ──────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
              ),
              child: Column(
                children: [
                  // Month Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '$monthName ${now.year}',
                        style: AppTypography.baloo2(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF7ED),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFFED7AA)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('🔥', style: TextStyle(fontSize: 13)),
                            const SizedBox(width: 4),
                            Text(
                              isCebuano ? 'Aktibo' : 'Active',
                              style: AppTypography.baloo2(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFFEA580C),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Weekday Header Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: ['S', 'M', 'T', 'W', 'T', 'F', 'S'].map((day) {
                      return SizedBox(
                        width: 34,
                        child: Text(
                          day,
                          textAlign: TextAlign.center,
                          style: AppTypography.baloo2(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF94A3B8),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 8),

                  // Calendar Grid (7 columns)
                  if (_isLoading)
                    const Padding(
                      padding: EdgeInsets.all(24.0),
                      child: CircularProgressIndicator(),
                    )
                  else
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 7,
                        childAspectRatio: 1.0,
                        crossAxisSpacing: 6,
                        mainAxisSpacing: 6,
                      ),
                      itemCount: firstWeekday + daysInMonth,
                      itemBuilder: (context, index) {
                        if (index < firstWeekday) {
                          return const SizedBox.shrink(); // Empty slots before 1st of month
                        }
                        final dayNum = index - firstWeekday + 1;
                        final dateKey = '${now.year}-${now.month.toString().padLeft(2, '0')}-${dayNum.toString().padLeft(2, '0')}';
                        final isToday = dayNum == now.day;
                        final hasStreak = _activeDates.contains(dateKey);

                        return Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: hasStreak
                                ? const Color(0xFFEA580C)
                                : isToday
                                    ? const Color(0xFFE0F2FE)
                                    : Colors.transparent,
                            border: isToday && !hasStreak
                                ? Border.all(color: const Color(0xFF0EA5E9), width: 2)
                                : null,
                            boxShadow: hasStreak
                                ? [
                                    BoxShadow(
                                      color: const Color(0xFFEA580C).withValues(alpha: 0.35),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                              : [],
                          ),
                          child: Center(
                            child: hasStreak
                                ? const Text('🔥', style: TextStyle(fontSize: 16))
                                : Text(
                                    '$dayNum',
                                    style: AppTypography.baloo2(
                                      fontSize: 13,
                                      fontWeight: isToday ? FontWeight.w900 : FontWeight.w700,
                                      color: isToday
                                          ? const Color(0xFF0284C7)
                                          : (dayNum > now.day
                                              ? const Color(0xFFCBD5E1)
                                              : const Color(0xFF64748B)),
                                    ),
                                  ),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // ── Streak Stats Cards ──────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF7ED),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFFED7AA)),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '🔥 $_currentStreak',
                          style: AppTypography.baloo2(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFFEA580C),
                          ),
                        ),
                        Text(
                          isCebuano ? 'Adlaw Karon' : 'Current Streak',
                          style: AppTypography.nunito(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF9A3412),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFBBF7D0)),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '📅 ${_activeDates.length}',
                          style: AppTypography.baloo2(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF16A34A),
                          ),
                        ),
                        Text(
                          isCebuano ? 'Tanan Aktibo' : 'Total Active Days',
                          style: AppTypography.nunito(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF166534),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ── Continue Button ─────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0EA5E9),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  isCebuano ? 'MAGPADAYON SA PAGTUON' : 'CONTINUE LEARNING',
                  style: AppTypography.baloo2(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getMonthName(int month, bool isCebuano) {
    const monthsEn = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    const monthsCeb = [
      'Enero', 'Pebrero', 'Marso', 'Abril', 'Mayo', 'Hunyo',
      'Hulyo', 'Agosto', 'Setyembre', 'Oktubre', 'Nobyembre', 'Disyembre'
    ];
    if (month < 1 || month > 12) return '';
    return isCebuano ? monthsCeb[month - 1] : monthsEn[month - 1];
  }
}
