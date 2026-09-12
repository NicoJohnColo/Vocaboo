import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/class_provider.dart';
import '../services/localization_service.dart';
import '../core/motion/motion.dart';
import 'more_options_sheet.dart';

enum AppNavTab {
  learn,
  ranking,
  classes,
  profile,
  settings,
}

class App3DBottomNavBar extends StatelessWidget {
  final String currentPath;
  final ValueChanged<int>? onTabSelected;

  const App3DBottomNavBar({
    super.key,
    required this.currentPath,
    this.onTabSelected,
  });

  int _getTabIndex(String path) {
    if (path.startsWith('/category') || path == '/home') {
      return 0; // Learn / Home
    } else if (path == '/leaderboard') {
      return 1; // Ranking / Leaderboard
    } else if (path == '/classes') {
      return 2; // Classes
    } else if (path == '/dashboard' || path == '/progress' || path == '/wrong-answers' || path == '/sandbox') {
      return 3; // Profile / Dashboard
    } else if (path == '/settings' || path == '/vowels-phonics') {
      return 4; // More / Settings
    }
    return 0;
  }

  void _handleNavigation(BuildContext context, int index) {
    if (onTabSelected != null) {
      onTabSelected!(index);
    }
    switch (index) {
      case 0:
        if (currentPath != '/home') {
          context.go('/home');
        }
        break;
      case 1:
        if (currentPath != '/leaderboard') {
          context.go('/leaderboard');
        }
        break;
      case 2:
        if (currentPath != '/classes') {
          context.go('/classes');
        }
        break;
      case 3:
        if (currentPath != '/dashboard') {
          context.go('/dashboard');
        }
        break;
      case 4:
        if (currentPath != '/settings') {
          MoreOptionsSheet.show(context);
        }
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeIndex = _getTabIndex(currentPath);
    final mediaQuery = MediaQuery.of(context);
    final bottomPadding = mediaQuery.padding.bottom;
    String? pref;
    int pendingInvites = 0;
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      pref = auth.learner?.languagePreference;
      final classProvider = Provider.of<ClassProvider>(context);
      pendingInvites = classProvider.pendingInvitationCount;
    } catch (_) {}

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(
          top: BorderSide(color: Color(0xFFF1F5F9), width: 1.5),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 8, 16, bottomPadding > 0 ? bottomPadding : 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildTabItem(
              context: context,
              index: 0,
              label: LocalizationService.translate(pref, 'nav_learn'),
              isActive: activeIndex == 0,
              icon: Icons.home_rounded,
            ),
            _buildTabItem(
              context: context,
              index: 1,
              label: LocalizationService.translate(pref, 'nav_ranking'),
              isActive: activeIndex == 1,
              icon: Icons.emoji_events_rounded,
            ),
            _buildTabItem(
              context: context,
              index: 2,
              label: 'Classes',
              isActive: activeIndex == 2,
              icon: Icons.school_rounded,
              badgeCount: pendingInvites,
            ),
            _buildTabItem(
              context: context,
              index: 3,
              label: LocalizationService.translate(pref, 'nav_profile'),
              isActive: activeIndex == 3,
              icon: Icons.person_rounded,
              isProfile: true,
            ),
            _buildTabItem(
              context: context,
              index: 4,
              label: LocalizationService.translate(pref, 'nav_more'),
              isActive: activeIndex == 4,
              icon: Icons.grid_view_rounded,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabItem({
    required BuildContext context,
    required int index,
    required String label,
    required bool isActive,
    required IconData icon,
    bool isProfile = false,
    int badgeCount = 0,
  }) {
    const activeColor = Color(0xFF2563EB); // Vocaboo Blue matching UI theme
    const inactiveColor = Color(0xFF94A3B8); // Muted Slate

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          HapticFeedback.lightImpact();
          if (onTabSelected != null) {
            onTabSelected!(index);
          } else {
            _handleNavigation(context, index);
          }
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon container (with soft circular highlight for active Profile like in mockups)
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: (isActive && isProfile)
                    ? const Color(0xFFEFF6FF)
                    : Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: badgeCount > 0
                    ? Badge(
                        label: Text(
                          '$badgeCount',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        backgroundColor: const Color(0xFFEF4444),
                        child: Icon(
                          icon,
                          size: 24,
                          color: isActive ? activeColor : inactiveColor,
                        ),
                      )
                    : Icon(
                        icon,
                        size: 24,
                        color: isActive ? activeColor : inactiveColor,
                      ),
              ),
            ),
            const SizedBox(height: 2),

            // Typography Label
            Text(
              label,
              style: AppTypography.baloo2(
                fontSize: 12,
                fontWeight: isActive ? FontWeight.w800 : FontWeight.w700,
                color: isActive ? activeColor : inactiveColor,
                letterSpacing: 0.1,
              ),
            ),
            const SizedBox(height: 3),

            // Active underline indicator pill
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: isActive ? 16 : 0,
              height: 3,
              decoration: BoxDecoration(
                color: isActive ? activeColor : Colors.transparent,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
