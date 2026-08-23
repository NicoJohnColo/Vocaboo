import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/motion/motion.dart';
import '../providers/auth_provider.dart';
import '../providers/lesson_provider.dart';
import '../services/localization_service.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  String _currentRange = 'weekly';
  bool _isLoading = false;
  String? _error;
  List<Map<String, dynamic>> _leaderboardData = [];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final lessonProvider = Provider.of<LessonProvider>(context, listen: false);
      final list = await lessonProvider.fetchLeaderboard(_currentRange);
      if (mounted) {
        setState(() {
          _leaderboardData = list;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Failed to load leaderboard data.';
        });
      }
    }
  }

  void _onRangeChanged(String range) {
    if (_currentRange == range) return;
    setState(() {
      _currentRange = range;
    });
    _fetchData();
  }

  AppViewStatus _resolveStatus() {
    if (_isLoading) return AppViewStatus.loading;
    if (_error != null) return AppViewStatus.error;
    if (_leaderboardData.isEmpty) return AppViewStatus.empty;
    return AppViewStatus.content;
  }

  Color _getAvatarColor(String name) {
    final colors = [
      const Color(0xFF0EA5E9),
      const Color(0xFF8B5CF6),
      const Color(0xFFEC4899),
      const Color(0xFF10B981),
      const Color(0xFFF59E0B),
      const Color(0xFF6366F1),
    ];
    final hash = name.codeUnits.fold(0, (sum, char) => sum + char);
    return colors[hash % colors.length];
  }

  String _getInitials(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '?';
    final parts = trimmed.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return trimmed.substring(0, trimmed.length >= 2 ? 2 : 1).toUpperCase();
  }

  Widget _buildToggle(String? pref) {
    final isWeekly = _currentRange == 'weekly';
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Expanded(
            child: AppPressable(
              onTap: () => _onRangeChanged('weekly'),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  gradient: isWeekly
                      ? const LinearGradient(
                          colors: [Color(0xFF06A6FF), Color(0xFF0284C7)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  color: isWeekly ? null : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: isWeekly
                      ? [
                          BoxShadow(
                            color: const Color(0xFF06A6FF).withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          )
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '⚡ ',
                      style: const TextStyle(fontSize: 14),
                    ),
                    Text(
                      LocalizationService.translate(pref, 'this_week'),
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: isWeekly ? Colors.white : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: AppPressable(
              onTap: () => _onRangeChanged('all_time'),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  gradient: !isWeekly
                      ? const LinearGradient(
                          colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  color: !isWeekly ? null : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: !isWeekly
                      ? [
                          BoxShadow(
                            color: const Color(0xFF8B5CF6).withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          )
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '👑 ',
                      style: const TextStyle(fontSize: 14),
                    ),
                    Text(
                      LocalizationService.translate(pref, 'all_time'),
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: !isWeekly ? Colors.white : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPodium(List<Map<String, dynamic>> topThree) {
    if (topThree.isEmpty) return const SizedBox.shrink();

    final first = topThree.isNotEmpty ? topThree[0] : null;
    final second = topThree.length >= 2 ? topThree[1] : null;
    final third = topThree.length >= 3 ? topThree[2] : null;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      padding: const EdgeInsets.fromLTRB(12, 20, 12, 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFEFF6FF), Color(0xFFF0FDF4)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFDBEAFE), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0284C7).withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // 2nd Place (Silver - Left)
          if (second != null)
            Expanded(
              child: _buildPodiumStep(
                entry: second,
                rank: 2,
                height: 110,
                crownEmoji: '🥈',
                borderColor: const Color(0xFF94A3B8),
                badgeColor: const Color(0xFF64748B),
                gradient: const LinearGradient(
                  colors: [Color(0xFFE2E8F0), Color(0xFFCBD5E1)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            )
          else
            const Spacer(),

          const SizedBox(width: 8),

          // 1st Place (Gold - Center)
          if (first != null)
            Expanded(
              child: _buildPodiumStep(
                entry: first,
                rank: 1,
                height: 140,
                crownEmoji: '👑 🥇',
                borderColor: const Color(0xFFF59E0B),
                badgeColor: const Color(0xFFD97706),
                gradient: const LinearGradient(
                  colors: [Color(0xFFFEF3C7), Color(0xFFFDE68A)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                isFirst: true,
              ),
            )
          else
            const Spacer(),

          const SizedBox(width: 8),

          // 3rd Place (Bronze - Right)
          if (third != null)
            Expanded(
              child: _buildPodiumStep(
                entry: third,
                rank: 3,
                height: 90,
                crownEmoji: '🥉',
                borderColor: const Color(0xFFD97706),
                badgeColor: const Color(0xFFB45309),
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFEDD5), Color(0xFFFED7AA)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            )
          else
            const Spacer(),
        ],
      ),
    );
  }

  Widget _buildPodiumStep({
    required Map<String, dynamic> entry,
    required int rank,
    required double height,
    required String crownEmoji,
    required Color borderColor,
    required Color badgeColor,
    required LinearGradient gradient,
    bool isFirst = false,
  }) {
    final name = entry['displayName']?.toString() ?? 'Learner';
    final points = entry['points'] ?? 0;
    final initials = _getInitials(name);
    final avatarBg = _getAvatarColor(name);

    return AppPressable(
      onTap: () {
        AppToast.show(
          context,
          title: '$crownEmoji $name',
          message: 'Rank #$rank with $points total points!',
          type: ToastType.info,
        );
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Crown / Medal Icon
          Text(
            isFirst ? '👑' : crownEmoji,
            style: TextStyle(fontSize: isFirst ? 26 : 20),
          ),
          const SizedBox(height: 2),

          // Avatar Circle with Ring
          Container(
            padding: EdgeInsets.all(isFirst ? 3.5 : 2.5),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              border: Border.all(color: borderColor, width: isFirst ? 3 : 2),
              boxShadow: [
                BoxShadow(
                  color: borderColor.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: CircleAvatar(
              radius: isFirst ? 24 : 19,
              backgroundColor: avatarBg,
              child: Text(
                initials,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w900,
                  fontSize: isFirst ? 16 : 13,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),

          // Name Label
          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w800,
              fontSize: isFirst ? 14 : 12,
              color: const Color(0xFF0F172A),
            ),
          ),

          // Points Chip
          Container(
            margin: const EdgeInsets.only(top: 3, bottom: 6),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor.withValues(alpha: 0.4)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('⭐', style: TextStyle(fontSize: 10)),
                const SizedBox(width: 3),
                Text(
                  '$points',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w900,
                    fontSize: isFirst ? 12 : 11,
                    color: badgeColor,
                  ),
                ),
              ],
            ),
          ),

          // Podium Pedestal Box
          Container(
            height: height,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '#$rank',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w900,
                    fontSize: isFirst ? 18 : 15,
                    color: badgeColor,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRankItem(
    BuildContext context,
    Map<String, dynamic> entry,
    int index,
    String? currentUserId,
  ) {
    final rank = entry['rank'] as int;
    final displayName = entry['displayName']?.toString() ?? 'Learner';
    final points = entry['points'] ?? 0;
    final tier = entry['tier']?.toString() ?? 'Learning';
    final entryId = entry['learnerId']?.toString();

    final isMe = currentUserId != null &&
        entryId != null &&
        currentUserId.toLowerCase() == entryId.toLowerCase();

    final initials = _getInitials(displayName);
    final avatarColor = _getAvatarColor(displayName);

    Color tierBgColor;
    Color tierTextColor;
    String tierLabel;
    switch (tier.toUpperCase()) {
      case 'MASTERED':
        tierBgColor = const Color(0xFFF3E8FF);
        tierTextColor = const Color(0xFF7E22CE);
        tierLabel = '🌟 Mastered';
        break;
      case 'PROFICIENT':
        tierBgColor = const Color(0xFFECFDF5);
        tierTextColor = const Color(0xFF047857);
        tierLabel = '⚡ Proficient';
        break;
      default:
        tierBgColor = const Color(0xFFF0F9FF);
        tierTextColor = const Color(0xFF0369A1);
        tierLabel = '🎈 Learning';
        break;
    }

    return AppStaggeredFadeIn(
      index: index,
      child: AppPressable(
        onTap: () {
          AppToast.show(
            context,
            title: displayName,
            message: '$points points earned in $tier!',
            type: ToastType.info,
          );
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isMe ? const Color(0xFFEFF6FF) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isMe ? const Color(0xFF06A6FF) : const Color(0xFFE2E8F0),
              width: isMe ? 2.0 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: isMe
                    ? const Color(0xFF06A6FF).withValues(alpha: 0.12)
                    : Colors.black.withValues(alpha: 0.02),
                blurRadius: isMe ? 10 : 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              // Rank Badge
              () {
                Color rankBg;
                Color rankTextClr;
                String rankStr;
                if (rank == 1) {
                  rankBg = const Color(0xFFFEF3C7);
                  rankTextClr = const Color(0xFFD97706);
                  rankStr = '🥇';
                } else if (rank == 2) {
                  rankBg = const Color(0xFFE2E8F0);
                  rankTextClr = const Color(0xFF475569);
                  rankStr = '🥈';
                } else if (rank == 3) {
                  rankBg = const Color(0xFFFFEDD5);
                  rankTextClr = const Color(0xFFC2410C);
                  rankStr = '🥉';
                } else if (isMe) {
                  rankBg = const Color(0xFF06A6FF);
                  rankTextClr = Colors.white;
                  rankStr = '#$rank';
                } else {
                  rankBg = const Color(0xFFF1F5F9);
                  rankTextClr = const Color(0xFF64748B);
                  rankStr = '#$rank';
                }

                return Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: rankBg,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      rankStr,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontWeight: FontWeight.w900,
                        fontSize: rank <= 3 ? 16 : 13,
                        color: rankTextClr,
                      ),
                    ),
                  ),
                );
              }(),
              const SizedBox(width: 12),

              // Avatar Circle
              CircleAvatar(
                radius: 20,
                backgroundColor: avatarColor,
                child: Text(
                  initials,
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Name & Tier
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                              color: isMe ? const Color(0xFF0284C7) : const Color(0xFF0F172A),
                            ),
                          ),
                        ),
                        if (isMe) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF06A6FF),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'YOU! 🚀',
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontWeight: FontWeight.w900,
                                fontSize: 9,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: tierBgColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        tierLabel,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: tierTextColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Points Chip
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFEF3C7), Color(0xFFFDE68A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('⭐', style: TextStyle(fontSize: 12)),
                    const SizedBox(width: 4),
                    Text(
                      '$points',
                      style: const TextStyle(
                        fontFamily: 'Outfit',
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                        color: Color(0xFFB45309),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final pref = auth.learner?.languagePreference;
    final currentUserId = auth.learner?.learnerId;

    final topThree = _leaderboardData.take(3).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🏆 ', style: TextStyle(fontSize: 22)),
            Text(
              LocalizationService.translate(pref, 'leaderboard_title'),
              style: const TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w900,
                fontSize: 22,
                color: Color(0xFF06A6FF),
              ),
            ),
          ],
        ),
      ),
      body: AppRefreshIndicator(
        onRefresh: _fetchData,
        child: Column(
          children: [
            _buildToggle(pref),
            Expanded(
              child: AppStateSwitcher(
                status: _resolveStatus(),
                loadingPlaceholder: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  itemCount: 6,
                  itemBuilder: (context, index) => AppShimmer.listTile(),
                ),
                emptyTitle: LocalizationService.translate(pref, 'no_leaderboard_data'),
                emptyMessage: 'Complete lessons to earn points and appear on the leaderboard!',
                errorTitle: 'Unable to Load Leaderboard',
                errorMessage: _error,
                onRetry: _fetchData,
                content: ListView(
                  physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  children: [
                    // Top 3 3D Podium (if available)
                    if (topThree.isNotEmpty) _buildPodium(topThree),

                    // Full Rankings List (shows ALL players)
                    if (_leaderboardData.isNotEmpty) ...[
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        child: Text(
                          'ALL RANKINGS',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: Color(0xFF94A3B8),
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                      ..._leaderboardData.asMap().entries.map((e) {
                        return _buildRankItem(context, e.value, e.key, currentUserId);
                      }),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
