import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../core/motion/motion.dart';
import '../providers/auth_provider.dart';
import '../providers/lesson_provider.dart';
import '../services/localization_service.dart';
import '../widgets/more_options_sheet.dart';
import '../widgets/badges_collection_sheet.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _previousLanguagePreference;
  bool _isOnline = true;
  int _badgeCount = 0;
  Timer? _connectivityTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final lessonProvider = Provider.of<LessonProvider>(context, listen: false);
      _previousLanguagePreference = auth.learner?.languagePreference;
      lessonProvider.loadCategories();
      _checkConnectivity();
      _loadBadges(lessonProvider, auth.learner?.learnerId);
    });

    _connectivityTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      _checkConnectivity();
    });
  }

  @override
  void dispose() {
    _connectivityTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkConnectivity() async {
    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 3));
      if (mounted) {
        setState(() {
          _isOnline = result.isNotEmpty && result[0].rawAddress.isNotEmpty;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isOnline = false;
        });
      }
    }
  }

  Future<void> _loadBadges(LessonProvider provider, String? learnerId) async {
    if (learnerId == null) return;
    try {
      final badges = await provider.fetchLearnerBadges(learnerId);
      if (mounted) {
        setState(() {
          _badgeCount = badges.length;
        });
      }
    } catch (_) {}
  }

  String _formatLanguagePreference(String pref) {
    if (pref == 'CEBUANO_TO_ENGLISH') return 'Cebuano';
    if (pref == 'FULL_ENGLISH') return 'English';
    if (pref == 'CEBUANO_ENGLISH_MIXED') return 'Mixed';
    return pref;
  }

  IconData _getCategoryIcon(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('color')) return Icons.palette_rounded;
    if (lower.contains('body')) return Icons.accessibility_new_rounded;
    if (lower.contains('animal')) return Icons.pets_rounded;
    if (lower.contains('food')) return Icons.restaurant_rounded;
    if (lower.contains('place')) return Icons.storefront_rounded;
    return Icons.menu_book_rounded;
  }

  Color _getCategoryColor(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('color')) return const Color(0xFFEC4899); // Pink
    if (lower.contains('body')) return const Color(0xFF0EA5E9); // Turquoise Blue
    if (lower.contains('animal')) return const Color(0xFF10B981); // Emerald
    if (lower.contains('food')) return const Color(0xFFF59E0B); // Amber
    if (lower.contains('place')) return const Color(0xFF8B5CF6); // Purple
    return const Color(0xFF6366F1); // Indigo
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final lessons = Provider.of<LessonProvider>(context);

    final learner = auth.learner;
    final pref = learner?.languagePreference;

    // Check if language preference changed and reload categories
    if (pref != _previousLanguagePreference) {
      _previousLanguagePreference = pref;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Provider.of<LessonProvider>(context, listen: false).loadCategories();
      });
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // Premium Light Background
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          LocalizationService.translate(pref, 'app_title'),
          style: const TextStyle(
            fontFamily: 'Outfit',
            fontWeight: FontWeight.w900,
            fontSize: 24,
            color: Color(0xFF06A6FF),
          ),
        ),
        actions: [
          // Cellular / Signal indicator (| | | |)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: _isOnline ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _isOnline ? const Color(0xFFBBF7D0) : const Color(0xFFFECACA),
                width: 1.2,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildSignalBars(_isOnline),
                const SizedBox(width: 5),
                Text(
                  _isOnline ? 'Online' : 'Offline',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: _isOnline ? const Color(0xFF059669) : const Color(0xFFDC2626),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Badges / Gold Collection indicator pill
          AppPressable(
            onTap: () => BadgesCollectionSheet.show(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF9C3),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFFDE047), width: 1.2),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🏆', style: TextStyle(fontSize: 13)),
                  const SizedBox(width: 4),
                  Text(
                    '$_badgeCount',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFFB45309),
                      fontFamily: 'Outfit',
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: AppRefreshIndicator(
        onRefresh: () => lessons.loadCategories(),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Profile Header Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${LocalizationService.translate(pref, 'hello')}, ${learner?.displayName ?? "Learner"}!',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Age: ${learner?.age ?? 9}  •  ${_formatLanguagePreference(learner?.languagePreference ?? "")}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Sandbox Mode Banner with Spring Press Feedback
                AppPressable(
                  onTap: () => context.push('/loading', extra: {
                    'duration': 2200,
                    'redirectPath': '/sandbox',
                  }),
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF06A6FF), Color(0xFF38BDF8)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF06A6FF).withValues(alpha: 0.22),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.auto_awesome_rounded, color: Color(0xFF06A6FF)),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                LocalizationService.translate(pref, 'sandbox_mode'),
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                LocalizationService.translate(pref, 'sandbox_desc'),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.white,
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded, color: Colors.white),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  LocalizationService.translate(pref, 'your_categories'),
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF06A6FF),
                  ),
                ),
                const SizedBox(height: 14),

                // Categories Grid with Shimmer & Staggered Entrance
                Expanded(
                  child: lessons.isLoading
                      ? AppShimmer.grid(itemCount: 6, crossAxisCount: 2)
                      : lessons.error != null
                          ? Center(
                              child: Text(
                                lessons.error!,
                                style: const TextStyle(color: Colors.red),
                              ),
                            )
                          : GridView.builder(
                              physics: const BouncingScrollPhysics(),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                                childAspectRatio: 1.0,
                              ),
                              itemCount: lessons.categories.length,
                              itemBuilder: (context, index) {
                                final category = lessons.categories[index];
                                final icon = _getCategoryIcon(category.categoryName);
                                final color = _getCategoryColor(category.categoryName);

                                return AppStaggeredFadeIn(
                                  index: index,
                                  child: AppPressable(
                                    onTap: () {
                                      context.push(
                                        '/category/${category.categoryId}/lessons?name=${Uri.encodeComponent(category.categoryName)}',
                                      );
                                    },
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(24),
                                        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: 0.02),
                                            blurRadius: 8,
                                            offset: const Offset(0, 4),
                                          )
                                        ],
                                      ),
                                      padding: const EdgeInsets.all(16),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          AppHero(
                                            tag: 'category_icon_${category.categoryId}',
                                            borderRadius: BorderRadius.circular(20),
                                            child: Container(
                                              padding: const EdgeInsets.all(10),
                                              decoration: BoxDecoration(
                                                color: color.withValues(alpha: 0.1),
                                                shape: BoxShape.circle,
                                              ),
                                              child: Icon(icon, color: color, size: 28),
                                            ),
                                          ),
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                category.categoryName,
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: Color(0xFF0F172A),
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                category.description,
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  color: Color(0xFF64748B),
                                                  fontWeight: FontWeight.w500,
                                                ),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: Color(0xFFE2E8F0), width: 1.5),
          ),
        ),
        child: SafeArea(
          child: Theme(
            data: Theme.of(context).copyWith(
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
            ),
            child: BottomNavigationBar(
              currentIndex: 0,
              elevation: 0,
              backgroundColor: Colors.white,
              type: BottomNavigationBarType.fixed,
              selectedItemColor: const Color(0xFF0EA5E9),
              unselectedItemColor: const Color(0xFF94A3B8),
              selectedLabelStyle: const TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
              unselectedLabelStyle: const TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.home_rounded),
                  label: 'Home',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.leaderboard_rounded),
                  label: 'Leaderboard',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.person_rounded),
                  label: 'Profile',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.more_horiz_rounded),
                  label: 'More',
                ),
              ],
              onTap: (index) {
                if (index == 0) {
                  // Home
                } else if (index == 1) {
                  context.push('/leaderboard');
                } else if (index == 2) {
                  context.push('/dashboard');
                } else if (index == 3) {
                  MoreOptionsSheet.show(context);
                }
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSignalBars(bool isOnline) {
    final activeColor = isOnline ? const Color(0xFF10B981) : const Color(0xFFEF4444);
    final inactiveColor = const Color(0xFFCBD5E1);
    final heights = [4.0, 7.0, 10.0, 13.0];
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(4, (index) {
        final isBarActive = isOnline;
        return Container(
          margin: EdgeInsets.only(right: index < 3 ? 2.0 : 0.0),
          width: 3.0,
          height: heights[index],
          decoration: BoxDecoration(
            color: isBarActive ? activeColor : inactiveColor,
            borderRadius: BorderRadius.circular(1.5),
          ),
        );
      }),
    );
  }
}
