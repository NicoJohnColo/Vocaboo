import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../core/motion/motion.dart';
import '../providers/auth_provider.dart';
import '../services/localization_service.dart';
import '../widgets/app_avatar.dart';
import '../widgets/mascot_bubble.dart';

class SuccessScreen extends StatelessWidget {
  const SuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final displayName = auth.learner?.displayName ?? 'Learner';
    final pref = auth.learner?.languagePreference;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        leading: const SizedBox(width: 48),
        title: const App3DProgressBar(value: 1.0, height: 18.0),
        actions: const [SizedBox(width: 48)],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              // Mascot Bubble for Starry (isCelebrating = true)
              MascotBubble(
                mascotName: 'starry',
                speechText: LocalizationService.translate(
                  pref,
                  'profile_success',
                ),
                isCelebrating: true,
              ),
              const SizedBox(height: 16),

              // Success Subtitle
              Text(
                LocalizationService.translate(pref, 'success_subtitle'),
                textAlign: TextAlign.center,
                style: AppTypography.nunito(
                  color: const Color(0xFF64748B),
                  height: 1.5,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),

              // Premium display of registered user name and avatar
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 24,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: const Color(0xFFE2E8F0),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    AppAvatar(
                      avatar: auth.learner?.avatar,
                      name: displayName,
                      size: 80,
                      borderColor: const Color(0xFF0EA5E9),
                      borderWidth: 3.5,
                      showShadow: true,
                    ),
                    const SizedBox(height: 14),
                    Text(
                      LocalizationService.translate(pref, 'learner_id'),
                      style: AppTypography.baloo2(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF94A3B8),
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      displayName,
                      style: AppTypography.baloo2(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0F172A),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const Spacer(),

              // START LEARNING Button (3D Primary)
              App3DButton(
                text: LocalizationService.translate(pref, 'start_learning'),
                variant: App3DButtonVariant.primary,
                height: 54,
                onPressed: () {
                  context.go(
                    '/loading',
                    extra: {'duration': 5000, 'redirectPath': '/home'},
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
