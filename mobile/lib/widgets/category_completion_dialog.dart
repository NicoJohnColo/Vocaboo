import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../core/motion/typography_tokens.dart';
import '../providers/auth_provider.dart';
import 'app_3d_button.dart';

class CategoryCompletionDialog extends StatelessWidget {
  final String categoryName;
  final String categoryId;
  final VoidCallback? onSelectAnotherCategory;
  final VoidCallback? onProceedToNextLesson;

  const CategoryCompletionDialog({
    super.key,
    required this.categoryName,
    required this.categoryId,
    this.onSelectAnotherCategory,
    this.onProceedToNextLesson,
  });

  static Future<void> show(
    BuildContext context, {
    required String categoryName,
    required String categoryId,
    VoidCallback? onSelectAnotherCategory,
    VoidCallback? onProceedToNextLesson,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => CategoryCompletionDialog(
        categoryName: categoryName,
        categoryId: categoryId,
        onSelectAnotherCategory: onSelectAnotherCategory,
        onProceedToNextLesson: onProceedToNextLesson,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final currentPos = auth.learner?.posFocus ?? 'NOUN';

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Mascot celebration header icon
            Center(
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFA7F3D0), width: 2),
                ),
                child: const Icon(
                  Icons.stars_rounded,
                  color: Color(0xFF10B981),
                  size: 44,
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Great job with ${categoryName.toUpperCase()}!',
              textAlign: TextAlign.center,
              style: AppTypography.baloo2(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'You completed the $currentPos path! What would you like to do next?',
              textAlign: TextAlign.center,
              style: AppTypography.nunito(
                fontSize: 14,
                color: const Color(0xFF64748B),
                height: 1.4,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 24),

            // Choice 1: Continue to another category (Verbs / Adjectives)
            App3DButton(
              onPressed: () {
                Navigator.of(context).pop();
                if (onSelectAnotherCategory != null) {
                  onSelectAnotherCategory!();
                } else {
                  context.go('/category/$categoryId/lessons');
                }
              },
              icon: Icons.swap_horiz_rounded,
              text: 'Continue to another category',
              variant: App3DButtonVariant.primary,
              height: 52.0,
              depth: 4.5,
              isFullWidth: true,
              borderRadius: 16,
            ),
            const SizedBox(height: 12),

            // Choice 2: Proceed to next lesson
            App3DButton(
              onPressed: () {
                Navigator.of(context).pop();
                if (onProceedToNextLesson != null) {
                  onProceedToNextLesson!();
                } else {
                  context.go('/category/$categoryId/lessons');
                }
              },
              icon: Icons.arrow_forward_rounded,
              text: 'Proceed to next lesson',
              variant: App3DButtonVariant.secondary,
              height: 52.0,
              depth: 4.5,
              isFullWidth: true,
              borderRadius: 16,
            ),
            const SizedBox(height: 10),

            // Choice 3: Go Home
            TextButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                context.go('/home');
              },
              icon: const Icon(Icons.home_rounded, size: 20),
              label: const Text('Go Home'),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF64748B),
                padding: const EdgeInsets.symmetric(vertical: 12),
                textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
