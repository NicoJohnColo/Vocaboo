import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app_router.dart';
import 'core/motion/motion.dart';
import 'providers/auth_provider.dart';
import 'providers/lesson_provider.dart';

import 'services/tts_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Text-to-Speech service (static class - no instance needed)
  // Do not await this so it doesn't block the app from rendering the first frame.
  TTSService.initialize();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProxyProvider<AuthProvider, LessonProvider>(
          create: (_) => LessonProvider(null),
          update: (_, auth, previous) {
            if (previous != null) {
              previous.updateAuth(auth);
              return previous;
            }
            return LessonProvider(auth);
          },
        ),

      ],
      child: const VocabooApp(),
    ),
  );
}

class VocabooApp extends StatelessWidget {
  const VocabooApp({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    AppRouter.setAuth(auth);

    return MaterialApp.router(
      title: 'Vocaboo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Outfit',
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0EA5E9),
          primary: const Color(0xFF0EA5E9),
          secondary: const Color(0xFFF59E0B),
          tertiary: const Color(0xFF10B981),
          error: const Color(0xFFEF4444),
          surface: const Color(0xFFF8FAFC),
          onPrimary: Colors.white,
          onSecondary: Colors.black,
          onSurface: const Color(0xFF0F172A),
          brightness: Brightness.light,
        ),
        cardTheme: const CardThemeData(
          color: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
        ),
        textTheme: AppTypography.createTextTheme(),
      ),
      routerConfig: AppRouter.router,
    );
  }
}
