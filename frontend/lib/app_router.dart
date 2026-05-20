import 'package:flutter/material';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'screens/welcome_screen.dart';
import 'screens/login_screen.dart';
import 'screens/profile_setup_screen.dart';
import 'screens/pin_setup_screen.dart';
import 'screens/language_preference_screen.dart';
import 'screens/success_screen.dart';
import 'screens/home_screen.dart';
import 'screens/lesson_path_screen.dart';
import 'screens/vocabulary_introduction_screen.dart';
import 'screens/diagnostic_check_screen.dart';
import 'screens/diagnostic_summary_screen.dart';
import 'screens/round_one_completed_screen.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/',
    redirect: (BuildContext context, GoRouterState state) async {
      final auth = Provider.of<AuthProvider>(context, listen: false);

      // Try auto-login on first load
      if (!auth.isInitialized) {
        await auth.tryAutoLogin();
      }

      final isLoggedIn = auth.isAuthenticated;
      final isGoingToAuth = state.matchedLocation == '/' ||
          state.matchedLocation == '/login' ||
          state.matchedLocation == '/profile-setup' ||
          state.matchedLocation == '/pin-setup' ||
          state.matchedLocation == '/language-preference' ||
          state.matchedLocation == '/success';

      // If logged in and trying to access auth screens, redirect to home
      if (isLoggedIn && (state.matchedLocation == '/' || state.matchedLocation == '/login')) {
        return '/home';
      }

      // If not logged in and trying to access protected screens, redirect to welcome
      if (!isLoggedIn && !isGoingToAuth) {
        return '/';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/profile-setup',
        builder: (context, state) => const ProfileSetupScreen(),
      ),
      GoRoute(
        path: '/pin-setup',
        builder: (context, state) {
          final data = state.extra as Map<String, dynamic>;
          return PinSetupScreen(learnerData: data);
        },
      ),
      GoRoute(
        path: '/language-preference',
        builder: (context, state) {
          final data = state.extra as Map<String, dynamic>;
          return LanguagePreferenceScreen(learnerData: data);
        },
      ),
      GoRoute(
        path: '/success',
        builder: (context, state) => const SuccessScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/category/:categoryId/lessons',
        builder: (context, state) {
          final categoryId = state.pathParameters['categoryId']!;
          final categoryName = state.uri.queryParameters['name'] ?? 'Lessons';
          return LessonPathScreen(
            categoryId: categoryId,
            categoryName: categoryName,
          );
        },
      ),
      GoRoute(
        path: '/lesson/:lessonId/diagnostic',
        builder: (context, state) {
          final lessonId = state.pathParameters['lessonId']!;
          return DiagnosticCheckScreen(lessonId: lessonId);
        },
      ),
      GoRoute(
        path: '/lesson/:lessonId/diagnostic-summary',
        builder: (context, state) {
          final lessonId = state.pathParameters['lessonId']!;
          final extra = state.extra as Map<String, dynamic>;
          return DiagnosticSummaryScreen(
            lessonId: lessonId,
            knownWords: extra['knownWords'] as List<Map<String, dynamic>>,
            unknownWords: extra['unknownWords'] as List<Map<String, dynamic>>,
            allWords: extra['allWords'] as List<Map<String, dynamic>>,
          );
        },
      ),
      GoRoute(
        path: '/session/:sessionId/introduction',
        builder: (context, state) {
          final sessionId = state.pathParameters['sessionId']!;
          final extra = state.extra as Map<String, dynamic>;
          return VocabularyIntroductionScreen(
            sessionId: sessionId,
            lessonId: extra['lessonId'] as String,
            knownWordIds: extra['knownWordIds'] as List<String>,
            unknownWordIds: extra['unknownWordIds'] as List<String>,
            allWords: extra['allWords'] as List<Map<String, dynamic>>,
          );
        },
      ),
      GoRoute(
        path: '/session/:sessionId/round-completed',
        builder: (context, state) {
          final sessionId = state.pathParameters['sessionId']!;
          final extra = state.extra as Map<String, dynamic>;
          return RoundOneCompletedScreen(
            sessionId: sessionId,
            introducedCount: extra['introducedCount'] as int,
            knownCount: extra['knownCount'] as int,
          );
        },
      ),
    ],
  );
}
