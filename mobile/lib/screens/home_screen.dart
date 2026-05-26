import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/lesson_provider.dart';
import '../services/localization_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _previousLanguagePreference;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      _previousLanguagePreference = auth.learner?.languagePreference;
      Provider.of<LessonProvider>(context, listen: false).loadCategories();
    });
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
            color: Color(0xFF0F172A),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.dashboard_rounded, color: Color(0xFF0F172A)),
            tooltip: LocalizationService.translate(pref, 'dashboard'),
            onPressed: () {
              context.push('/dashboard');
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings_rounded, color: Color(0xFF0F172A)),
            tooltip: LocalizationService.translate(pref, 'settings'),
            onPressed: () {
              context.push('/settings');
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Color(0xFFEF4444)),
            tooltip: LocalizationService.translate(pref, 'logout'),
            onPressed: () {
              auth.logout();
            },
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: RefreshIndicator(
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
                const SizedBox(height: 28),
                GestureDetector(
                  onTap: () => context.push('/sandbox'),
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
                          color: const Color(0xFF06A6FF).withValues(alpha: 0.18),
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
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Sandbox Mode',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Practice a custom topic before choosing a category lesson.',
                                style: TextStyle(
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
                const SizedBox(height: 16),
                Text(
                  LocalizationService.translate(pref, 'your_categories'),
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 16),

                // Categories Grid
                Expanded(
                  child: lessons.isLoading
                      ? const Center(child: CircularProgressIndicator())
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

                                return GestureDetector(
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
                                          color: Colors.black.withValues(alpha: 0.01),
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
                                        Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: color.withValues(alpha: 0.1),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(icon, color: color, size: 28),
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
}
