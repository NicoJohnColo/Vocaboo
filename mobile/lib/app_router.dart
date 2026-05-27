// app_router.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'models/vocabulary_word_model.dart';
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
import 'screens/active_practice_screen.dart';
import 'screens/sentence_building_screen.dart';
import 'screens/confusable_words_distinction_screen.dart';
import 'screens/cumulative_mixed_review_screen.dart';
import 'screens/mastery_result_screen.dart';
import 'screens/sandbox_mode_screen.dart';
import 'screens/user_dashboard_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/lesson_score_screen.dart';

class _AuthListenable extends ChangeNotifier {
  final AuthProvider _auth;
  _AuthListenable(this._auth) {
    _auth.addListener(() => notifyListeners());
  }
}

class AppRouter {
  static late final _AuthListenable _authListenable;

  static void setAuth(AuthProvider auth) {
    _authListenable = _AuthListenable(auth);
  }

  static final GoRouter router = GoRouter(
    initialLocation: '/',
    refreshListenable: _authListenable,
    redirect: (BuildContext context, GoRouterState state) async {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      if (!auth.isInitialized) {
        // Start auto-login but don't block the router redirect on network IO.
        // AuthProvider will call notifyListeners() when it completes, which
        // will trigger the router to re-evaluate redirects.
        auth.tryAutoLogin();
      }
      final isLoggedIn = auth.isAuthenticated;
      final isGoingToAuth = state.matchedLocation == '/' ||
          state.matchedLocation == '/login' ||
          state.matchedLocation == '/profile-setup' ||
          state.matchedLocation == '/pin-setup' ||
          state.matchedLocation == '/language-preference' ||
          state.matchedLocation == '/success';
      if (isLoggedIn && (state.matchedLocation == '/' || state.matchedLocation == '/login')) {
        return '/home';
      }
      if (!isLoggedIn && !isGoingToAuth) {
        return '/';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (c, s) => const WelcomeScreen()),
      GoRoute(path: '/login', builder: (c, s) => const LoginScreen()),
      GoRoute(path: '/profile-setup', builder: (c, s) => const ProfileSetupScreen()),
      GoRoute(
        path: '/pin-setup',
        builder: (c, s) => PinSetupScreen(learnerData: s.extra as Map<String, dynamic>),
      ),
      GoRoute(
        path: '/language-preference',
        builder: (c, s) => LanguagePreferenceScreen(learnerData: s.extra as Map<String, dynamic>?),
      ),
      GoRoute(path: '/success', builder: (c, s) => const SuccessScreen()),
      GoRoute(path: '/home', builder: (c, s) => const HomeScreen()),
      GoRoute(
        path: '/category/:categoryId/lessons',
        builder: (c, s) => LessonPathScreen(
          categoryId: s.pathParameters['categoryId']!,
          categoryName: s.uri.queryParameters['name'] ?? 'Lessons',
        ),
      ),
      GoRoute(
        path: '/lesson/:lessonId/diagnostic',
        builder: (c, s) {
          final e = s.extra as Map<String, dynamic>?;
          return DiagnosticCheckScreen(
            lessonId: s.pathParameters['lessonId']!,
            categoryId: e?['categoryId']?.toString() ?? '',
          );
        },
      ),
      GoRoute(
        path: '/lesson/:lessonId/diagnostic-summary',
        builder: (c, s) {
          final e = s.extra as Map<String, dynamic>;
          return DiagnosticSummaryScreen(
            lessonId: s.pathParameters['lessonId']!,
            categoryId: e['categoryId']?.toString() ?? '',
            knownWords: e['knownWords'] as List<Map<String, dynamic>>,
            unknownWords: e['unknownWords'] as List<Map<String, dynamic>>,
            allWords: e['allWords'] as List<Map<String, dynamic>>,
          );
        },
      ),
      GoRoute(
        path: '/session/:sessionId/introduction',
        builder: (c, s) {
          final e = s.extra as Map<String, dynamic>;
          return VocabularyIntroductionScreen(
            sessionId: s.pathParameters['sessionId']!,
            lessonId: e['lessonId'] as String,
            categoryId: e['categoryId']?.toString() ?? '',
            knownWordIds: List<String>.from(e['knownWordIds']),
            unknownWordIds: List<String>.from(e['unknownWordIds']),
            allWords: List<Map<String, dynamic>>.from(e['allWords']),
            returnToPractice: e['returnToPractice'] as bool? ?? false,
            isSandbox: e['isSandbox'] as bool? ?? false,
          );
        },
      ),
      GoRoute(
        path: '/session/:sessionId/practice',
        builder: (c, s) {
          final e = s.extra as Map<String, dynamic>;
          return ActivePracticeScreen(
            sessionId: s.pathParameters['sessionId']!,
            lessonId: e['lessonId'] as String,
            categoryId: e['categoryId']?.toString() ?? '',
            lessonTitle: e['lessonTitle'] as String?,
            knownWordIds: List<String>.from(e['knownWordIds']),
            unknownWordIds: List<String>.from(e['unknownWordIds']),
            allWords: List<Map<String, dynamic>>.from(e['allWords']),
            isSandbox: e['isSandbox'] as bool? ?? false,
          );
        },
      ),
      GoRoute(
        path: '/session/:sessionId/sentence-building',
        builder: (c, s) {
          final e = s.extra as Map<String, dynamic>;
          return SentenceBuildingScreen(
            sessionId: s.pathParameters['sessionId']!,
            lessonId: e['lessonId'] as String,
            categoryId: e['categoryId']?.toString() ?? '',
            lessonTitle: e['lessonTitle'] as String?,
            allWords: List<Map<String, dynamic>>.from(e['allWords'] ?? const []),
            moduleNumber: 3,
            isSandbox: e['isSandbox'] as bool? ?? false,
          );
        },
      ),
      GoRoute(
        path: '/session/:sessionId/lesson-score',
        builder: (c, s) {
          final e = s.extra as Map<String, dynamic>;
          return LessonScoreScreen(
            sessionId: s.pathParameters['sessionId']!,
            lessonId: e['lessonId'] as String,
            categoryId: e['categoryId']?.toString() ?? '',
            lessonTitle: e['lessonTitle'] as String,
            allWords: List<VocabularyWordModel>.from(e['allWords'].map((w) => VocabularyWordModel.fromJson(w as Map<String, dynamic>))),
            wordPronunciationCorrect: Map<String, bool>.from(e['wordPronunciationCorrect']),
            wordPronunciationAttempts: Map<String, int>.from(e['wordPronunciationAttempts']),
            failedSentenceWordIds: Set<String>.from(e['failedSentenceWordIds']),
            overallScore: (e['overallScore'] as num).toDouble(),
            isSandbox: e['isSandbox'] as bool? ?? false,
            masteredCount: e['masteredCount'] as int?,
            needsReviewWords: e['needsReviewWords'] != null ? List<String>.from(e['needsReviewWords']) : null,
          );
        },
      ),
      GoRoute(
        path: '/session/:sessionId/confusable-distinction',
        builder: (c, s) {
          final e = s.extra as Map<String, dynamic>;
          return ConfusableWordsDistinctionScreen(
            sessionId: s.pathParameters['sessionId']!,
            lessonId: e['lessonId'] as String,
            confusablePairs: List<Map<String, dynamic>>.from(e['confusablePairs']),
          );
        },
      ),
      GoRoute(
        path: '/session/:sessionId/round-completed',
        builder: (c, s) {
          final e = s.extra as Map<String, dynamic>;
          return RoundOneCompletedScreen(
            sessionId: s.pathParameters['sessionId']!,
            introducedCount: e['introducedCount'] as int,
            knownCount: e['knownCount'] as int,
            lessonId: e['lessonId'] as String? ?? '',
            categoryId: e['categoryId']?.toString() ?? '',
            knownWordIds: List<String>.from(e['knownWordIds'] ?? []),
            unknownWordIds: List<String>.from(e['unknownWordIds'] ?? []),
            allWords: List<Map<String, dynamic>>.from(e['allWords'] ?? []),
            isSandbox: e['isSandbox'] as bool? ?? false,
          );
        },
      ),
      GoRoute(
        path: '/session/:sessionId/cumulative-review',
        builder: (c, s) {
          final e = s.extra as Map<String, dynamic>?;
          return CumulativeMixedReviewScreen(
            sessionId: s.pathParameters['sessionId']!,
            allWords: List<Map<String, dynamic>>.from(e?['allWords'] ?? const []),
            categoryId: e?['categoryId']?.toString() ?? '',
            isSandbox: e?['isSandbox'] as bool? ?? false,
            lessonIds: List<String>.from(e?['lessonIds'] ?? const []),
            priorityWordIds: List<String>.from(e?['priorityWordIds'] ?? const []),
          );
        },
      ),
      GoRoute(
        path: '/session/:sessionId/mastery-result',
        builder: (c, s) {
          final e = s.extra as Map<String, dynamic>;
          return MasteryResultScreen(
            sessionId: s.pathParameters['sessionId']!,
            categoryId: e['categoryId']?.toString() ?? '',
            isSandbox: e['isSandbox'] as bool? ?? false,
            totalItems: e['totalItems'] as int,
            masteredCount: e['masteredCount'] as int,
            allWords: List<Map<String, dynamic>>.from(e['allWords'] ?? const []),
          );
        },
      ),
      GoRoute(path: '/sandbox', builder: (c, s) => const SandboxModeScreen()),
      GoRoute(path: '/dashboard', builder: (c, s) => const UserDashboardScreen()),
      GoRoute(path: '/settings', builder: (c, s) => const SettingsScreen()),
    ],
  );
}
