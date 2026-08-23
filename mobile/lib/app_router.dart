// app_router.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'core/motion/motion.dart';
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
import 'screens/cumulative_review_screen.dart';
import 'screens/cumulative_review_summary_screen.dart';
import 'screens/diagnostic_check_screen.dart';
import 'screens/diagnostic_summary_screen.dart';
import 'screens/round_one_completed_screen.dart';
import 'screens/active_practice_screen.dart';
import 'screens/sentence_building_screen.dart';
import 'screens/confusable_words_distinction_screen.dart';
import 'screens/mastery_result_screen.dart';
import 'screens/sandbox_mode_screen.dart';
import 'screens/user_dashboard_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/lesson_score_screen.dart';
import 'screens/wrong_answers_screen.dart';
import 'screens/progress_screen.dart';
import 'screens/leaderboard_screen.dart';
import 'screens/loading_screen.dart';
import 'screens/motion_showcase_screen.dart';

class _AuthListenable extends ChangeNotifier {
  final AuthProvider _auth;
  _AuthListenable(this._auth) {
    _auth.addListener(() => notifyListeners());
  }
}

class AppRouter {
  static _AuthListenable? _authListenable;

  static void setAuth(AuthProvider auth) {
    _authListenable = _AuthListenable(auth);
  }

  static final GoRouter router = GoRouter(
    initialLocation: '/',
    refreshListenable: _authListenable ?? ChangeNotifier(),
    redirect: (BuildContext context, GoRouterState state) async {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      if (!auth.isInitialized) {
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
      GoRoute(
        path: '/',
        pageBuilder: (c, s) => AppPageTransitions.page(
          key: s.pageKey,
          type: AppMotionType.fadeThrough,
          child: const WelcomeScreen(),
        ),
      ),
      GoRoute(
        path: '/login',
        pageBuilder: (c, s) => AppPageTransitions.page(
          key: s.pageKey,
          type: AppMotionType.sharedAxisX,
          child: const LoginScreen(),
        ),
      ),
      GoRoute(
        path: '/profile-setup',
        pageBuilder: (c, s) => AppPageTransitions.page(
          key: s.pageKey,
          type: AppMotionType.sharedAxisX,
          child: const ProfileSetupScreen(),
        ),
      ),
      GoRoute(
        path: '/pin-setup',
        pageBuilder: (c, s) => AppPageTransitions.page(
          key: s.pageKey,
          type: AppMotionType.sharedAxisX,
          child: PinSetupScreen(learnerData: s.extra as Map<String, dynamic>),
        ),
      ),
      GoRoute(
        path: '/language-preference',
        pageBuilder: (c, s) => AppPageTransitions.page(
          key: s.pageKey,
          type: AppMotionType.sharedAxisX,
          child: LanguagePreferenceScreen(learnerData: s.extra as Map<String, dynamic>?),
        ),
      ),
      GoRoute(
        path: '/success',
        pageBuilder: (c, s) => AppPageTransitions.page(
          key: s.pageKey,
          type: AppMotionType.modalSheet,
          child: const SuccessScreen(),
        ),
      ),
      GoRoute(
        path: '/loading',
        pageBuilder: (c, s) {
          final e = s.extra as Map<String, dynamic>?;
          final duration = e?['duration'] != null
              ? Duration(milliseconds: e!['duration'] as int)
              : const Duration(seconds: 13);
          final redirectPath = e?['redirectPath'] as String? ?? '/home';
          final extraParams = Map<String, dynamic>.from(e ?? {});
          extraParams.remove('duration');
          extraParams.remove('redirectPath');
          return AppPageTransitions.page(
            key: s.pageKey,
            type: AppMotionType.fadeThrough,
            child: LoadingScreen(
              duration: duration,
              redirectPath: redirectPath,
              extraParams: extraParams.isNotEmpty ? extraParams : null,
            ),
          );
        },
      ),
      GoRoute(
        path: '/home',
        pageBuilder: (c, s) => AppPageTransitions.page(
          key: s.pageKey,
          type: AppMotionType.fadeThrough,
          child: const HomeScreen(),
        ),
      ),
      GoRoute(
        path: '/motion-showcase',
        pageBuilder: (c, s) => AppPageTransitions.page(
          key: s.pageKey,
          type: AppMotionType.sharedAxisZ,
          child: const MotionShowcaseScreen(),
        ),
      ),
      GoRoute(
        path: '/leaderboard',
        pageBuilder: (c, s) => AppPageTransitions.page(
          key: s.pageKey,
          type: AppMotionType.fadeThrough,
          child: const LeaderboardScreen(),
        ),
      ),
      GoRoute(
        path: '/category/:categoryId/lessons',
        pageBuilder: (c, s) => AppPageTransitions.page(
          key: s.pageKey,
          type: AppMotionType.sharedAxisZ,
          child: LessonPathScreen(
            categoryId: s.pathParameters['categoryId']!,
            categoryName: s.uri.queryParameters['name'] ?? 'Lessons',
          ),
        ),
      ),
      GoRoute(
        path: '/lesson/:lessonId/diagnostic',
        pageBuilder: (c, s) {
          final e = s.extra as Map<String, dynamic>?;
          return AppPageTransitions.page(
            key: s.pageKey,
            type: AppMotionType.sharedAxisY,
            child: DiagnosticCheckScreen(
              lessonId: s.pathParameters['lessonId']!,
              categoryId: e?['categoryId']?.toString() ?? '',
            ),
          );
        },
      ),
      GoRoute(
        path: '/lesson/:lessonId/diagnostic-summary',
        pageBuilder: (c, s) {
          final e = s.extra as Map<String, dynamic>? ?? {};
          return AppPageTransitions.page(
            key: s.pageKey,
            type: AppMotionType.modalSheet,
            child: DiagnosticSummaryScreen(
              lessonId: s.pathParameters['lessonId']!,
              categoryId: e['categoryId']?.toString() ?? '',
              knownWords: (e['knownWords'] as List<dynamic>?)?.map((x) => Map<String, dynamic>.from(x as Map)).toList() ?? const [],
              unknownWords: (e['unknownWords'] as List<dynamic>?)?.map((x) => Map<String, dynamic>.from(x as Map)).toList() ?? const [],
              allWords: (e['allWords'] as List<dynamic>?)?.map((x) => Map<String, dynamic>.from(x as Map)).toList() ?? const [],
            ),
          );
        },
      ),
      GoRoute(
        path: '/session/:sessionId/introduction',
        pageBuilder: (c, s) {
          final e = s.extra as Map<String, dynamic>? ?? {};
          return AppPageTransitions.page(
            key: s.pageKey,
            type: AppMotionType.sharedAxisZ,
            child: VocabularyIntroductionScreen(
              sessionId: s.pathParameters['sessionId']!,
              lessonId: e['lessonId']?.toString() ?? '',
              categoryId: e['categoryId']?.toString() ?? '',
              knownWordIds: (e['knownWordIds'] as List<dynamic>?)?.map((x) => x.toString()).toList() ?? const [],
              unknownWordIds: (e['unknownWordIds'] as List<dynamic>?)?.map((x) => x.toString()).toList() ?? const [],
              allWords: (e['allWords'] as List<dynamic>?)?.map((x) => Map<String, dynamic>.from(x as Map)).toList() ?? const [],
              returnToPractice: e['returnToPractice'] as bool? ?? false,
              isSandbox: e['isSandbox'] as bool? ?? false,
            ),
          );
        },
      ),
      GoRoute(
        path: '/session/:sessionId/practice',
        pageBuilder: (c, s) {
          final e = s.extra as Map<String, dynamic>? ?? {};
          return AppPageTransitions.page(
            key: s.pageKey,
            type: AppMotionType.sharedAxisZ,
            child: ActivePracticeScreen(
              sessionId: s.pathParameters['sessionId']!,
              lessonId: e['lessonId']?.toString() ?? '',
              categoryId: e['categoryId']?.toString() ?? '',
              lessonTitle: e['lessonTitle'] as String?,
              knownWordIds: (e['knownWordIds'] as List<dynamic>?)?.map((x) => x.toString()).toList() ?? const [],
              unknownWordIds: (e['unknownWordIds'] as List<dynamic>?)?.map((x) => x.toString()).toList() ?? const [],
              allWords: (e['allWords'] as List<dynamic>?)?.map((x) => Map<String, dynamic>.from(x as Map)).toList() ?? const [],
              isSandbox: e['isSandbox'] as bool? ?? false,
            ),
          );
        },
      ),
      GoRoute(
        path: '/session/:sessionId/sentence-building',
        pageBuilder: (c, s) {
          final e = s.extra as Map<String, dynamic>;
          return AppPageTransitions.page(
            key: s.pageKey,
            type: AppMotionType.sharedAxisZ,
            child: SentenceBuildingScreen(
              sessionId: s.pathParameters['sessionId']!,
              lessonId: e['lessonId'] as String,
              categoryId: e['categoryId']?.toString() ?? '',
              lessonTitle: e['lessonTitle'] as String?,
              allWords: List<Map<String, dynamic>>.from(e['allWords'] ?? const []),
              moduleNumber: 3,
              isSandbox: e['isSandbox'] as bool? ?? false,
            ),
          );
        },
      ),
      GoRoute(
        path: '/session/:sessionId/lesson-score',
        pageBuilder: (c, s) {
          final e = s.extra as Map<String, dynamic>;
          return AppPageTransitions.page(
            key: s.pageKey,
            type: AppMotionType.modalSheet,
            child: LessonScoreScreen(
              sessionId: s.pathParameters['sessionId']!,
              lessonId: e['lessonId'] as String,
              categoryId: e['categoryId']?.toString() ?? '',
              lessonTitle: e['lessonTitle'] as String,
              allWords: List<VocabularyWordModel>.from((e['allWords'] as List<dynamic>? ?? []).map((w) => VocabularyWordModel.fromJson(w as Map<String, dynamic>))),
              wordPronunciationCorrect: Map<String, bool>.from(e['wordPronunciationCorrect'] ?? {}),
              wordPronunciationAttempts: Map<String, int>.from(e['wordPronunciationAttempts'] ?? {}),
              failedSentenceWordIds: Set<String>.from(e['failedSentenceWordIds'] ?? {}),
              overallScore: (e['overallScore'] as num? ?? 0.0).toDouble(),
              isSandbox: e['isSandbox'] as bool? ?? false,
              masteredCount: e['masteredCount'] as int?,
              needsReviewWords: e['needsReviewWords'] != null ? List<String>.from(e['needsReviewWords']) : null,
              isPerfectFirstAttempt: e['isPerfectFirstAttempt'] as bool? ?? false,
            ),
          );
        },
      ),
      GoRoute(
        path: '/session/:sessionId/confusable-distinction',
        pageBuilder: (c, s) {
          final e = s.extra as Map<String, dynamic>;
          return AppPageTransitions.page(
            key: s.pageKey,
            type: AppMotionType.sharedAxisZ,
            child: ConfusableWordsDistinctionScreen(
              sessionId: s.pathParameters['sessionId']!,
              lessonId: e['lessonId'] as String,
              confusablePairs: List<Map<String, dynamic>>.from(e['confusablePairs']),
            ),
          );
        },
      ),
      GoRoute(
        path: '/session/:sessionId/round-completed',
        pageBuilder: (c, s) {
          final e = s.extra as Map<String, dynamic>;
          return AppPageTransitions.page(
            key: s.pageKey,
            type: AppMotionType.modalSheet,
            child: RoundOneCompletedScreen(
              sessionId: s.pathParameters['sessionId']!,
              introducedCount: e['introducedCount'] as int,
              knownCount: e['knownCount'] as int,
              lessonId: e['lessonId'] as String? ?? '',
              categoryId: e['categoryId']?.toString() ?? '',
              knownWordIds: List<String>.from(e['knownWordIds'] ?? []),
              unknownWordIds: List<String>.from(e['unknownWordIds'] ?? []),
              allWords: List<Map<String, dynamic>>.from(e['allWords'] ?? []),
              isSandbox: e['isSandbox'] as bool? ?? false,
            ),
          );
        },
      ),
      GoRoute(
        path: '/session/:sessionId/cumulative-review',
        pageBuilder: (c, s) {
          final e = s.extra as Map<String, dynamic>?;
          return AppPageTransitions.page(
            key: s.pageKey,
            type: AppMotionType.sharedAxisZ,
            child: CumulativeReviewScreen(
              sessionId: s.pathParameters['sessionId']!,
              lessonIds: List<String>.from(e?['lessonIds'] ?? const []),
              categoryId: e?['categoryId'] ?? '',
            ),
          );
        },
      ),
      GoRoute(
        path: '/session/:sessionId/cumulative-summary',
        pageBuilder: (c, s) {
          final e = s.extra as Map<String, dynamic>;
          return AppPageTransitions.page(
            key: s.pageKey,
            type: AppMotionType.modalSheet,
            child: CumulativeReviewSummaryScreen(
              sessionId: s.pathParameters['sessionId']!,
              correct: e['correct'] as int,
              total: e['total'] as int,
            ),
          );
        },
      ),
      GoRoute(
        path: '/cumulative-mixed-review',
        pageBuilder: (c, s) {
          final e = s.extra as Map<String, dynamic>?;
          return AppPageTransitions.page(
            key: s.pageKey,
            type: AppMotionType.sharedAxisZ,
            child: CumulativeReviewScreen(
              sessionId: e?['sessionId'] as String? ?? '',
              lessonId: e?['lessonId'] as String? ?? (e?['lesson_id'] as String?),
              allWords: List<Map<String, dynamic>>.from(e?['allWords'] ?? const []),
              categoryId: e?['categoryId'] as String? ?? '',
              isSandbox: e?['isSandbox'] as bool? ?? false,
            ),
          );
        },
      ),
      GoRoute(
        path: '/session/:sessionId/mastery-result',
        pageBuilder: (c, s) {
          final e = s.extra as Map<String, dynamic>;
          return AppPageTransitions.page(
            key: s.pageKey,
            type: AppMotionType.modalSheet,
            child: MasteryResultScreen(
              sessionId: s.pathParameters['sessionId']!,
              categoryId: e['categoryId']?.toString() ?? '',
              isSandbox: e['isSandbox'] as bool? ?? false,
              totalItems: e['totalItems'] as int,
              masteredCount: e['masteredCount'] as int,
              allWords: List<Map<String, dynamic>>.from(e['allWords'] ?? const []),
            ),
          );
        },
      ),
      GoRoute(
        path: '/sandbox',
        pageBuilder: (c, s) => AppPageTransitions.page(
          key: s.pageKey,
          type: AppMotionType.sharedAxisZ,
          child: const SandboxModeScreen(),
        ),
      ),
      GoRoute(
        path: '/dashboard',
        pageBuilder: (c, s) => AppPageTransitions.page(
          key: s.pageKey,
          type: AppMotionType.fadeThrough,
          child: const UserDashboardScreen(),
        ),
      ),
      GoRoute(
        path: '/settings',
        pageBuilder: (c, s) => AppPageTransitions.page(
          key: s.pageKey,
          type: AppMotionType.fadeThrough,
          child: const SettingsScreen(),
        ),
      ),
      GoRoute(
        path: '/wrong-answers',
        pageBuilder: (c, s) => AppPageTransitions.page(
          key: s.pageKey,
          type: AppMotionType.sharedAxisZ,
          child: const WrongAnswersScreen(),
        ),
      ),
      GoRoute(
        path: '/progress',
        pageBuilder: (c, s) => AppPageTransitions.page(
          key: s.pageKey,
          type: AppMotionType.fadeThrough,
          child: const ProgressScreen(),
        ),
      ),
    ],
  );
}
