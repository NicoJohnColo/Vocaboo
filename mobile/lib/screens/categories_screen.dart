import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/motion/motion.dart';
import '../models/learner_category_progress_model.dart';
import '../providers/auth_provider.dart';
import '../providers/class_provider.dart';
import '../providers/lesson_provider.dart';
import '../widgets/app_3d_bottom_nav_bar.dart';

class CategoriesScreen extends StatefulWidget {
  final String? classId;
  final String? className;

  const CategoriesScreen({
    super.key,
    this.classId,
    this.className,
  });

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isLoadingClassCategories = false;
  List<Map<String, dynamic>> _classCategories = [];
  List<LearnerCategoryProgressModel> _categoryProgressList = [];

  bool get isClassMode => widget.classId != null && widget.classId!.isNotEmpty;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final lessonProvider = Provider.of<LessonProvider>(context, listen: false);

    if (isClassMode) {
      setState(() => _isLoadingClassCategories = true);
      try {
        final classProvider = Provider.of<ClassProvider>(context, listen: false);
        final cats = await classProvider.fetchClassCategories(widget.classId!, auth.token);
        if (mounted) {
          setState(() {
            _classCategories = cats;
            _isLoadingClassCategories = false;
          });
        }
      } catch (_) {
        if (mounted) setState(() => _isLoadingClassCategories = false);
      }
    } else {
      await lessonProvider.loadCategories();
      final learnerId = auth.learner?.learnerId;
      if (learnerId != null) {
        try {
          final catProgress = await lessonProvider.fetchLearnerCategoryProgress(learnerId);
          if (mounted) {
            setState(() {
              _categoryProgressList = catProgress;
            });
          }
        } catch (_) {}
      }
    }
  }

  Color _getCategoryCardBg(int index) {
    const pastelBgs = [
      Color(0xFFEFF6FF), // Soft Blue
      Color(0xFFF0FDF4), // Soft Green
      Color(0xFFFFFBEB), // Warm Cream
      Color(0xFFFAF5FF), // Soft Purple
      Color(0xFFFFF1F2), // Soft Rose
      Color(0xFFF0FDFA), // Soft Teal
    ];
    return pastelBgs[index % pastelBgs.length];
  }

  Color _getCategoryAccent(int index) {
    const accents = [
      Color(0xFF0284C7), // Sky Blue
      Color(0xFF16A34A), // Green
      Color(0xFFD97706), // Amber
      Color(0xFF7C3AED), // Purple
      Color(0xFFE11D48), // Rose
      Color(0xFF0D9488), // Teal
    ];
    return accents[index % accents.length];
  }

  IconData _getCategoryIcon(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('kitchen') || lower.contains('cook') || lower.contains('food')) {
      return Icons.soup_kitchen_rounded;
    }
    if (lower.contains('school') || lower.contains('class') || lower.contains('study')) {
      return Icons.backpack_rounded;
    }
    if (lower.contains('people') || lower.contains('family') || lower.contains('body')) {
      return Icons.face_rounded;
    }
    if (lower.contains('home') || lower.contains('house') || lower.contains('room')) {
      return Icons.cottage_rounded;
    }
    if (lower.contains('animal') || lower.contains('pet')) {
      return Icons.pets_rounded;
    }
    if (lower.contains('color') || lower.contains('paint') || lower.contains('art')) {
      return Icons.palette_rounded;
    }
    if (lower.contains('number') || lower.contains('math')) {
      return Icons.calculate_rounded;
    }
    if (lower.contains('place') || lower.contains('travel') || lower.contains('city')) {
      return Icons.place_rounded;
    }
    return Icons.auto_stories_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final lessonProvider = Provider.of<LessonProvider>(context);

    final List<_CategoryItem> allItems;
    final bool loading;

    if (isClassMode) {
      loading = _isLoadingClassCategories;
      allItems = _classCategories.map((c) {
        return _CategoryItem(
          id: c['categoryId']?.toString() ?? '',
          name: c['categoryName']?.toString() ?? 'Category',
          description: c['description']?.toString(),
          completedLessons: 0,
          totalLessons: 0,
        );
      }).toList();
    } else {
      loading = lessonProvider.isLoading && lessonProvider.categories.isEmpty;
      allItems = lessonProvider.categories.map((c) {
        LearnerCategoryProgressModel? prog;
        for (final cp in _categoryProgressList) {
          if (cp.categoryId == c.categoryId) {
            prog = cp;
            break;
          }
        }
        return _CategoryItem(
          id: c.categoryId,
          name: c.categoryName,
          description: c.description,
          completedLessons: prog?.completedLessons ?? 0,
          totalLessons: prog?.totalLessons ?? 0,
        );
      }).toList();
    }

    final filteredItems = _searchQuery.trim().isEmpty
        ? allItems
        : allItems.where((item) {
            final q = _searchQuery.trim().toLowerCase();
            return item.name.toLowerCase().contains(q) ||
                (item.description != null && item.description!.toLowerCase().contains(q));
          }).toList();

    final screenTitle = isClassMode
        ? (widget.className != null ? '${widget.className!} Categories' : 'Classroom Categories')
        : 'All Categories';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 1,
        shadowColor: const Color(0xFF0F172A).withValues(alpha: 0.06),
        leading: Padding(
          padding: const EdgeInsets.only(left: 12.0),
          child: Center(
            child: AppPressable(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: const Icon(
                  Icons.arrow_back_rounded,
                  color: Color(0xFF0284C7),
                  size: 20,
                ),
              ),
            ),
          ),
        ),
        title: Text(
          screenTitle,
          style: AppTypography.baloo2(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF0284C7),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isClassMode ? const Color(0xFFEEF2FF) : const Color(0xFFE0F2FE),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isClassMode ? const Color(0xFFC7D2FE) : const Color(0xFFBAE6FD),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isClassMode ? '🏫 ' : '📁 ',
                      style: const TextStyle(fontSize: 12),
                    ),
                    Text(
                      '${filteredItems.length} ${filteredItems.length == 1 ? 'Category' : 'Categories'}',
                      style: AppTypography.nunito(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: isClassMode ? const Color(0xFF4338CA) : const Color(0xFF0369A1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const App3DBottomNavBar(currentPath: '/categories'),
      body: AppRefreshIndicator(
        onRefresh: _loadData,
        child: Column(
          children: [
            // ── Search & Header Banner ──────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    isClassMode
                        ? 'Explore lessons designed for your classroom.'
                        : 'Choose a category below to practice words and level up!',
                    style: AppTypography.nunito(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Search Bar
                  Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (val) => setState(() => _searchQuery = val),
                      style: AppTypography.nunito(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF0F172A),
                      ),
                      decoration: InputDecoration(
                        hintText: 'Search categories...',
                        hintStyle: AppTypography.nunito(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF94A3B8),
                        ),
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          size: 20,
                          color: Color(0xFF94A3B8),
                        ),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? GestureDetector(
                                onTap: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                },
                                child: const Icon(
                                  Icons.close_rounded,
                                  size: 18,
                                  color: Color(0xFF94A3B8),
                                ),
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFE2E8F0)),

            // ── Grid of Categories ──────────────────────────────────────
            Expanded(
              child: loading
                  ? Padding(
                      padding: const EdgeInsets.all(16),
                      child: AppShimmer.grid(itemCount: 6, crossAxisCount: 2),
                    )
                  : filteredItems.isEmpty
                      ? Center(
                          child: SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 72,
                                  height: 72,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF1F5F9),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Center(
                                    child: Icon(
                                      Icons.search_off_rounded,
                                      size: 36,
                                      color: Color(0xFF94A3B8),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 14),
                                Text(
                                  _searchQuery.isNotEmpty
                                      ? 'No matching categories'
                                      : 'No categories available yet',
                                  style: AppTypography.baloo2(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF334155),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  _searchQuery.isNotEmpty
                                      ? 'Try searching with a different keyword.'
                                      : (isClassMode
                                          ? 'Your teacher will add lessons and categories soon!'
                                          : 'Categories will appear once lessons are created.'),
                                  textAlign: TextAlign.center,
                                  style: AppTypography.nunito(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF94A3B8),
                                  ),
                                ),
                                if (_searchQuery.isNotEmpty) ...[
                                  const SizedBox(height: 16),
                                  TextButton.icon(
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() => _searchQuery = '');
                                    },
                                    icon: const Icon(Icons.clear_all_rounded, size: 18),
                                    label: const Text('Clear search'),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        )
                      : GridView.builder(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 14,
                            mainAxisSpacing: 14,
                            childAspectRatio: 0.88,
                          ),
                          itemCount: filteredItems.length,
                          itemBuilder: (context, index) {
                            final item = filteredItems[index];
                            final bg = _getCategoryCardBg(index);
                            final accent = _getCategoryAccent(index);
                            final icon = _getCategoryIcon(item.name);
                            final isCompleted = item.totalLessons > 0 &&
                                item.completedLessons >= item.totalLessons;

                            return AppPressable(
                              onTap: () {
                                HapticFeedback.selectionClick();
                                if (isClassMode) {
                                  lessonProvider.setActiveClassroom(
                                    widget.classId!,
                                    widget.className ?? 'Classroom',
                                  );
                                  context.push(
                                    '/category/${item.id}/lessons'
                                    '?name=${Uri.encodeComponent(item.name)}'
                                    '&classId=${widget.classId}',
                                  );
                                } else {
                                  lessonProvider.clearActiveClassroom();
                                  context.push(
                                    '/category/${item.id}/lessons'
                                    '?name=${Uri.encodeComponent(item.name)}',
                                  );
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: bg,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: accent.withValues(alpha: 0.28),
                                    width: 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: accent.withValues(alpha: 0.08),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Icon Circle & Completion Badge
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Container(
                                          width: 46,
                                          height: 46,
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                color: accent.withValues(alpha: 0.2),
                                                blurRadius: 8,
                                                offset: const Offset(0, 3),
                                              ),
                                            ],
                                          ),
                                          child: Center(
                                            child: Icon(
                                              icon,
                                              size: 24,
                                              color: accent,
                                            ),
                                          ),
                                        ),
                                        if (isCompleted)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 3,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFDCFCE7),
                                              borderRadius: BorderRadius.circular(10),
                                              border: Border.all(
                                                color: const Color(0xFF86EFAC),
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(
                                                  Icons.check_circle_rounded,
                                                  size: 12,
                                                  color: Color(0xFF16A34A),
                                                ),
                                                const SizedBox(width: 2),
                                                Text(
                                                  'Done',
                                                  style: AppTypography.nunito(
                                                    fontSize: 9.5,
                                                    fontWeight: FontWeight.w800,
                                                    color: const Color(0xFF16A34A),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          )
                                        else
                                          Icon(
                                            Icons.chevron_right_rounded,
                                            size: 20,
                                            color: accent.withValues(alpha: 0.6),
                                          ),
                                      ],
                                    ),
                                    const Spacer(),

                                    // Category Name
                                    Text(
                                      item.name,
                                      style: AppTypography.baloo2(
                                        fontSize: 15.5,
                                        fontWeight: FontWeight.w800,
                                        color: const Color(0xFF0F172A),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),

                                    // Lesson Count / Progress
                                    if (item.totalLessons > 0) ...[
                                      Text(
                                        '${item.completedLessons} / ${item.totalLessons} lessons',
                                        style: AppTypography.nunito(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w700,
                                          color: const Color(0xFF64748B),
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(4),
                                        child: LinearProgressIndicator(
                                          value: item.totalLessons > 0
                                              ? (item.completedLessons / item.totalLessons)
                                                  .clamp(0.0, 1.0)
                                              : 0.0,
                                          minHeight: 4.5,
                                          backgroundColor: Colors.white.withValues(alpha: 0.6),
                                          valueColor: AlwaysStoppedAnimation<Color>(accent),
                                        ),
                                      ),
                                    ] else ...[
                                      Text(
                                        item.description != null && item.description!.isNotEmpty
                                            ? item.description!
                                            : 'Explore lessons',
                                        style: AppTypography.nunito(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w600,
                                          color: const Color(0xFF64748B),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
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
    );
  }
}

class _CategoryItem {
  final String id;
  final String name;
  final String? description;
  final int completedLessons;
  final int totalLessons;

  _CategoryItem({
    required this.id,
    required this.name,
    this.description,
    required this.completedLessons,
    required this.totalLessons,
  });
}
