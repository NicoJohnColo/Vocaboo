import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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
              const Text(
                'Vocaboo',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1.0,
                  color: Color(0xFF0F172A),
                  fontFamily: 'Outfit',
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Learning English through Cebuano',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              // Single Get Started mascot image
              Center(
                child: MascotVisual(
                  type: MascotType.group,
                  size: 400,
                ),
              ),
              const Spacer(),
              // GET STARTED Button (black)
              ElevatedButton(
                onPressed: () => context.push('/profile-setup'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F172A), // Black
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'GET STARTED',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // LOGIN Button / Link (optional, styled as simple link text button)
              TextButton(
                onPressed: () => context.push('/login'),
                child: const Text(
                  'I ALREADY HAVE AN ACCOUNT',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF475569),
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
