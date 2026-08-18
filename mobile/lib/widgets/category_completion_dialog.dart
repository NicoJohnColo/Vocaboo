import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

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
    final theme = Theme.of(context);
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
              style: const TextStyle(
                fontFamily: 'Outfit',
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'You completed the $currentPos path! What would you like to do next?',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF64748B),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),

            // Choice 1: Continue to another category (Verbs / Adjectives)
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                if (onSelectAnotherCategory != null) {
                  onSelectAnotherCategory!();
                } else {
                  context.go('/category/$categoryId/lessons');
                }
              },
              icon: const Icon(Icons.swap_horiz_rounded, size: 20),
              label: const Text('Continue to another category'),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
                textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 10),

            // Choice 2: Proceed to next lesson
            OutlinedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                if (onProceedToNextLesson != null) {
                  onProceedToNextLesson!();
                } else {
                  context.go('/category/$categoryId/lessons');
                }
              },
              icon: const Icon(Icons.arrow_forward_rounded, size: 20),
              label: const Text('Proceed to next lesson'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF0F172A),
                side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.5),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
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
