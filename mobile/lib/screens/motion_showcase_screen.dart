import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/motion/motion.dart';

/// An interactive playground screen demonstrating all features of the
/// Vocaboo Motion Design & Mobile UX Performance System.
class MotionShowcaseScreen extends StatefulWidget {
  const MotionShowcaseScreen({super.key});

  @override
  State<MotionShowcaseScreen> createState() => _MotionShowcaseScreenState();
}

class _MotionShowcaseScreenState extends State<MotionShowcaseScreen> {
  AppViewStatus _currentStatus = AppViewStatus.content;
  bool _switchValue = true;
  bool _checkboxValue = false;
  String? _fieldError;
  final TextEditingController _textController = TextEditingController();

  Future<void> _simulateAsyncAction() async {
    await Future.delayed(const Duration(milliseconds: 1500));
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          'Motion System Showcase',
          style: TextStyle(
            fontFamily: 'Outfit',
            fontWeight: FontWeight.w900,
            fontSize: 20,
            color: Color(0xFF0F172A),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline_rounded, color: Color(0xFF0EA5E9)),
            tooltip: 'About Motion System',
            onPressed: () {
              AppModal.showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  title: const Text(
                    'Vocaboo Motion Engine',
                    style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold),
                  ),
                  content: const Text(
                    'All animations run at 60-120fps using compositor-friendly transforms (Scale, Translate, Opacity) isolated in RepaintBoundaries with full Reduce Motion accessibility support.',
                    style: TextStyle(fontFamily: 'Outfit', fontSize: 14, color: Color(0xFF475569)),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Got it!'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: AppRefreshIndicator(
        onRefresh: () async {
          await Future.delayed(const Duration(seconds: 1));
          if (!context.mounted) return;
          AppToast.show(
            context,
            title: 'Refreshed!',
            message: 'Custom pull-to-refresh animation completed.',
            type: ToastType.success,
          );
        },
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Section 1: Tactile Buttons & Morphing Loading States
              _buildSectionHeader('1. Tactile Buttons & Loading Morph'),
              const SizedBox(height: 12),
              AppInlineLoadingButton(
                text: 'Simulate Async Action',
                icon: Icons.bolt_rounded,
                backgroundColor: const Color(0xFF0EA5E9),
                onPressed: _simulateAsyncAction,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: AppPressable(
                      onTap: () {
                        AppToast.show(
                          context,
                          title: 'Spring Tactile Tap',
                          message: 'Pressed with 0.96x scale & spring-back.',
                          type: ToastType.info,
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          'Spring Tap',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppPressable(
                      onTap: () {
                        AppModal.showBottomSheet(
                          context: context,
                          builder: (context) => Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Modal Bottom Sheet',
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Slides up smoothly with spring deceleration and backdrop dimming synced to gesture.',
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 14,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                AppInlineLoadingButton(
                                  text: 'Dismiss Sheet',
                                  onPressed: () async {
                                    Navigator.of(context).pop();
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F172A),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          'Open Bottom Sheet',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // Section 2: Shared Element / Hero Transition Demo
              _buildSectionHeader('2. Glitch-Free Shared Element (AppHero)'),
              const SizedBox(height: 12),
              AppPressable(
                onTap: () {
                  context.push('/category/demo-motion/lessons?name=Motion+Continuity');
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      AppHero(
                        tag: 'category_icon_demo-motion',
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF8B5CF6).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.auto_awesome_rounded,
                            color: Color(0xFF8B5CF6),
                            size: 32,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Shared Element Continuity',
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Tap to see smooth hero flight without text jitter or elevation glitching.',
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 12,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8)),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // Section 3: Floating Toasts & Notifications
              _buildSectionHeader('3. Floating Toast Micro-Interactions'),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildToastButton('Success Toast', const Color(0xFF10B981), ToastType.success),
                  _buildToastButton('Warning Toast', const Color(0xFFF59E0B), ToastType.warning),
                  _buildToastButton('Error Toast', const Color(0xFFEF4444), ToastType.error),
                  _buildToastButton('Info Toast', const Color(0xFF0EA5E9), ToastType.info),
                ],
              ),

              const SizedBox(height: 28),

              // Section 4: Animated Form Controls
              _buildSectionHeader('4. Form Field Focus & Animated Switches'),
              const SizedBox(height: 12),
              AppAnimatedTextField(
                label: 'Animated Input with Focus Glow',
                hint: 'Type here and see smooth border glow...',
                controller: _textController,
                errorText: _fieldError,
                prefixIcon: const Icon(Icons.edit_rounded, color: Color(0xFF64748B), size: 20),
                onChanged: (val) {
                  setState(() {
                    _fieldError = val.isEmpty ? 'This field cannot be empty!' : null;
                  });
                },
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Fluid Spring Switch',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  AppAnimatedSwitch(
                    value: _switchValue,
                    onChanged: (val) => setState(() => _switchValue = val),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Animated Checkbox',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  AppAnimatedCheckbox(
                    value: _checkboxValue,
                    onChanged: (val) => setState(() => _checkboxValue = val),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // Section 5: Animated State Switcher (Loading -> Content -> Empty -> Error)
              _buildSectionHeader('5. Animated State Switcher & Shimmers'),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildStatusChip('Loading', AppViewStatus.loading),
                  const SizedBox(width: 8),
                  _buildStatusChip('Content', AppViewStatus.content),
                  const SizedBox(width: 8),
                  _buildStatusChip('Empty', AppViewStatus.empty),
                  const SizedBox(width: 8),
                  _buildStatusChip('Error', AppViewStatus.error),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                padding: const EdgeInsets.all(16),
                child: AppStateSwitcher(
                  status: _currentStatus,
                  loadingPlaceholder: Column(
                    children: [
                      AppShimmer.listTile(),
                      AppShimmer.listTile(),
                    ],
                  ),
                  content: Column(
                    children: List.generate(
                      2,
                      (i) => AppStaggeredFadeIn(
                        index: i,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981)),
                              const SizedBox(width: 12),
                              Text(
                                'Data Row ${i + 1} Loaded Seamlessly',
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  emptyTitle: 'No Items Found',
                  emptyMessage: 'Try adjusting your search criteria.',
                  errorTitle: 'Failed to Fetch Data',
                  errorMessage: 'Network timeout occurred. Please retry.',
                  onRetry: () => setState(() => _currentStatus = AppViewStatus.loading),
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontFamily: 'Outfit',
        fontSize: 16,
        fontWeight: FontWeight.w800,
        color: Color(0xFF0F172A),
      ),
    );
  }

  Widget _buildToastButton(String label, Color color, ToastType type) {
    return AppPressable(
      onTap: () {
        AppToast.show(
          context,
          title: label,
          message: 'Animated notification delivered with elastic entrance.',
          type: type,
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String label, AppViewStatus status) {
    final isSelected = _currentStatus == status;
    return Expanded(
      child: AppPressable(
        onTap: () => setState(() => _currentStatus = status),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF0EA5E9) : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.white : const Color(0xFF64748B),
            ),
          ),
        ),
      ),
    );
  }
}
