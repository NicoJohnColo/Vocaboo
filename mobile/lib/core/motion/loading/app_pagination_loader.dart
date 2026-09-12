import 'package:flutter/material.dart';
import '../motion_tokens.dart';
import '../typography_tokens.dart';

/// A smooth, animated pagination loading indicator for infinite scroll lists.
///
/// Smoothly expands when loading more items and collapses cleanly without
/// jumpy layout shifts.
class AppPaginationLoader extends StatelessWidget {
  final bool isLoading;
  final bool hasReachedEnd;
  final String endOfListMessage;
  final Color indicatorColor;

  const AppPaginationLoader({
    super.key,
    required this.isLoading,
    this.hasReachedEnd = false,
    this.endOfListMessage = "You've reached the end! 🎉",
    this.indicatorColor = const Color(0xFF0EA5E9),
  });

  @override
  Widget build(BuildContext context) {
    if (!isLoading && !hasReachedEnd) {
      return const SizedBox.shrink();
    }

    return AnimatedSize(
      duration: AppDurations.standard,
      curve: AppCurves.emphasizedDecelerate,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20),
        alignment: Alignment.center,
        child: isLoading
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      valueColor: AlwaysStoppedAnimation<Color>(indicatorColor),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Loading more...',
                    style: AppTypography.nunito(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: indicatorColor,
                    ),
                  ),
                ],
              )
            : Text(
                endOfListMessage,
                style: AppTypography.nunito(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF94A3B8),
                ),
              ),
      ),
    );
  }
}
