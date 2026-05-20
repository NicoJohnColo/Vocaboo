import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app_router.dart';
import 'providers/auth_provider.dart';
import 'providers/lesson_provider.dart';
import 'services/tts_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Text-to-Speech service (Locale English, speech rate 0.4)
  final ttsService = TtsService();
  await ttsService.initialize();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProxyProvider<AuthProvider, LessonProvider>(
          create: (_) => LessonProvider(null),
          update: (_, auth, previous) => LessonProvider(auth),
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
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6366F1), // Premium Indigo
          primary: const Color(0xFF6366F1),
          secondary: const Color(0xFFF59E0B), // Warm Amber
          tertiary: const Color(0xFF10B981), // Success Green
          error: const Color(0xFFEF4444), // Crimson Red
          background: const Color(0xFF0F172A), // Premium Dark Slate
          surface: const Color(0xFF1E293B), // Card Slate
          onPrimary: Colors.white,
          onSecondary: Colors.black,
          onBackground: const Color(0xFFF8FAFC),
          onSurface: const Color(0xFFF8FAFC),
          brightness: Brightness.dark,
        ),
        cardTheme: const CardThemeData(
          color: Color(0xFF1E293B),
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
        ),
        textTheme: const TextTheme(
          displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFFF8FAFC), fontFamily: 'Outfit'),
          titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFFF8FAFC), fontFamily: 'Outfit'),
          bodyLarge: TextStyle(fontSize: 16, color: Color(0xFFCBD5E1), height: 1.5),
          bodyMedium: TextStyle(fontSize: 14, color: Color(0xFF94A3B8), height: 1.4),
        ),
      ),
      routerConfig: AppRouter.router,
    );
  }
}
