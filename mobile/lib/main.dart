import 'package:flutter/material.dart';
import 'screens/onboarding/welcome_screen.dart';
import 'utils/local_storage.dart';

void main() {
  runApp(const VocabooApp());
}

class VocabooApp extends StatelessWidget {
  const VocabooApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vocaboo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const SplashRouter(),
      routes: {
        '/home': (context) => const HomeScreen(),
      },
    );
  }
}

class SplashRouter extends StatefulWidget {
  const SplashRouter({super.key});

  @override
  State<SplashRouter> createState() => _SplashRouterState();
}

class _SplashRouterState extends State<SplashRouter> {
  @override
  void initState() {
    super.initState();
    checkOnboarding();
  }

  Future<void> checkOnboarding() async {
    final onboarded = await LocalStorage.isOnboarded();
    if (mounted) {
      if (onboarded) {
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const WelcomeScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vocaboo Home'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Welcome to Vocaboo!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text('Your onboarding is complete.'),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () async {
                await LocalStorage.clearProfile();
                if (context.mounted) {
                  Navigator.pushReplacementNamed(context, '/');
                }
              },
              child: const Text('Logout'),
            ),
          ],
        ),
      ),
    );
  }
}
