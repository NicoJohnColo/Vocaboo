import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/motion/motion.dart';
import '../widgets/mascot_visual.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              // Title "Vocaboo"
              Text(
                'Vocaboo',
                style: AppTypography.baloo2(
                  fontSize: 48,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  color: const Color(0xFF06A6FF),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Learning English through Cebuano',
                style: AppTypography.nunito(
                  fontSize: 16,
                  color: const Color(0xFF64748B),
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              // Single Get Started mascot image
              Center(
                child: MascotVisual(
                  type: MascotType.group,
                  size: 280,
                ),
              ),
              const Spacer(),
              // GET STARTED Button (3D Primary)
              App3DButton(
                text: 'GET STARTED',
                variant: App3DButtonVariant.primary,
                height: 54,
                onPressed: () => context.push('/profile-setup'),
              ),
              const SizedBox(height: 12),
              // LOGIN Button (3D Secondary Outline)
              App3DButton(
                text: 'I ALREADY HAVE AN ACCOUNT',
                variant: App3DButtonVariant.secondary,
                height: 50,
                depth: 3.0,
                onPressed: () => context.push('/login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
