import 'dart:ui';
import 'package:flutter/material.dart';
import '../motion_tokens.dart';
import '../typography_tokens.dart';

/// A full-screen blocking loading overlay with smooth backdrop blur and opacity fade.
class AppFullScreenOverlay extends StatelessWidget {
  final bool isVisible;
  final String? message;
  final Widget? customIndicator;
  final Widget child;

  const AppFullScreenOverlay({
    super.key,
    required this.isVisible,
    required this.child,
    this.message,
    this.customIndicator,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        child,
        AnimatedSwitcher(
          duration: AppDurations.standard,
          switchInCurve: AppCurves.emphasizedDecelerate,
          switchOutCurve: AppCurves.emphasizedAccelerate,
          child: isVisible ? _buildOverlay(context) : const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildOverlay(BuildContext context) {
    return Stack(
      key: const ValueKey('fullscreen_overlay'),
      fit: StackFit.expand,
      children: [
        // Backdrop Blur & Scrim
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
          child: Container(
            color: const Color(0xFF0F172A).withValues(alpha: 0.45),
          ),
        ),
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                customIndicator ??
                    const SizedBox(
                      width: 44,
                      height: 44,
                      child: CircularProgressIndicator(
                        strokeWidth: 3.5,
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0EA5E9)),
                      ),
                    ),
                if (message != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    message!,
                    style: AppTypography.nunito(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF0F172A),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
