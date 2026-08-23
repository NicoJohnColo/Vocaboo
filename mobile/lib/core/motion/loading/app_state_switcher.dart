import 'package:flutter/material.dart';
import '../motion_tokens.dart';
import 'app_shimmer.dart';

enum AppViewStatus { loading, content, empty, error }

/// An animated state switcher widget that smoothly transitions between
/// loading skeletons, content, empty states, and error states.
class AppStateSwitcher extends StatelessWidget {
  final AppViewStatus status;
  final Widget content;
  final Widget? loadingPlaceholder;
  final Widget? emptyState;
  final Widget? errorState;
  final String? emptyTitle;
  final String? emptyMessage;
  final String? errorTitle;
  final String? errorMessage;
  final VoidCallback? onRetry;

  const AppStateSwitcher({
    super.key,
    required this.status,
    required this.content,
    this.loadingPlaceholder,
    this.emptyState,
    this.errorState,
    this.emptyTitle,
    this.emptyMessage,
    this.errorTitle,
    this.errorMessage,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: AppDurations.standard,
      switchInCurve: AppCurves.emphasizedDecelerate,
      switchOutCurve: AppCurves.emphasizedAccelerate,
      layoutBuilder: (currentChild, previousChildren) {
        return Stack(
          alignment: Alignment.topCenter,
          children: <Widget>[
            ...previousChildren,
            ?currentChild,
          ],
        );
      },
      child: _buildCurrentState(),
    );
  }

  Widget _buildCurrentState() {
    switch (status) {
      case AppViewStatus.loading:
        return KeyedSubtree(
          key: const ValueKey('state_loading'),
          child: loadingPlaceholder ??
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 4,
                itemBuilder: (context, index) => AppShimmer.listTile(),
              ),
        );

      case AppViewStatus.content:
        return KeyedSubtree(
          key: const ValueKey('state_content'),
          child: content,
        );

      case AppViewStatus.empty:
        return KeyedSubtree(
          key: const ValueKey('state_empty'),
          child: emptyState ?? _buildDefaultEmpty(),
        );

      case AppViewStatus.error:
        return KeyedSubtree(
          key: const ValueKey('state_error'),
          child: errorState ?? _buildDefaultError(),
        );
    }
  }

  Widget _buildDefaultEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 48.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.inbox_rounded,
                size: 48,
                color: Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              emptyTitle ?? 'Nothing Here Yet',
              style: const TextStyle(
                fontFamily: 'Outfit',
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              emptyMessage ?? 'There is no data available to display right now.',
              style: const TextStyle(
                fontFamily: 'Outfit',
                fontSize: 14,
                color: Color(0xFF64748B),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDefaultError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 48.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFFEE2E2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: Color(0xFFEF4444),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              errorTitle ?? 'Oops! Something went wrong',
              style: const TextStyle(
                fontFamily: 'Outfit',
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              errorMessage ?? 'Failed to load content. Please check your connection and try again.',
              style: const TextStyle(
                fontFamily: 'Outfit',
                fontSize: 14,
                color: Color(0xFF64748B),
              ),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Try Again'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0EA5E9),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
