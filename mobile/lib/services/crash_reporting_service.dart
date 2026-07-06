import 'package:flutter/foundation.dart';

/// Crash reporting service for the Vocaboo mobile app.
///
/// Currently stubs out Firebase Crashlytics calls — all events are logged
/// to the Flutter debug console in dev, and silently no-op in release.
///
/// To enable real Firebase Crashlytics:
///   1. Run: flutterfire configure
///   2. Add to pubspec.yaml:
///        firebase_core: ^3.x.x
///        firebase_crashlytics: ^4.x.x
///   3. Replace the _log() calls below with FirebaseCrashlytics.instance methods.
class CrashReportingService {
  static final CrashReportingService _instance = CrashReportingService._internal();
  factory CrashReportingService() => _instance;
  CrashReportingService._internal();

  String? _currentUserId;
  final List<String> _breadcrumbs = [];

  // ── Initialization ────────────────────────────────────────────────────────

  /// Call once in main() after Firebase.initializeApp().
  Future<void> initialize() async {
    // TODO: await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(!kDebugMode);
    _log('CrashReportingService initialized (stub mode)');
  }

  /// Sets up Flutter error handling to forward uncaught errors to Crashlytics.
  void registerFlutterErrorHandlers() {
    FlutterError.onError = (FlutterErrorDetails details) {
      recordException(
        details.exception,
        stackTrace: details.stack,
        context: 'FlutterError: ${details.context}',
        fatal: true,
      );
    };

    // Catch async errors not caught by Flutter framework
    PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
      recordException(error, stackTrace: stack, context: 'PlatformDispatcher', fatal: true);
      return true;
    };
  }

  // ── Recording ─────────────────────────────────────────────────────────────

  /// Records a caught exception (non-fatal by default).
  ///
  /// Example:
  ///   try { ... } catch (e, st) {
  ///     crashReporting.recordException(e, stackTrace: st, context: 'SttService.transcribe');
  ///   }
  void recordException(
    Object exception, {
    StackTrace? stackTrace,
    String? context,
    bool fatal = false,
  }) {
    final label = fatal ? '[FATAL]' : '[NON-FATAL]';
    final ctx = context != null ? ' | context: $context' : '';
    _log('$label Exception recorded$ctx: $exception');
    if (stackTrace != null && kDebugMode) {
      debugPrint(stackTrace.toString());
    }

    // TODO: await FirebaseCrashlytics.instance.recordError(
    //   exception, stackTrace, reason: context, fatal: fatal,
    // );
  }

  // ── User Context ──────────────────────────────────────────────────────────

  /// Associates subsequent crash reports with a learner ID.
  /// Call after successful login.
  void setUserContext(String learnerId) {
    _currentUserId = learnerId;
    _log('User context set: $learnerId');
    // TODO: await FirebaseCrashlytics.instance.setUserIdentifier(learnerId);
  }

  /// Clears the user context (call on logout).
  void clearUserContext() {
    _currentUserId = null;
    _log('User context cleared');
    // TODO: await FirebaseCrashlytics.instance.setUserIdentifier('');
  }

  // ── Breadcrumbs ───────────────────────────────────────────────────────────

  /// Records a user action breadcrumb to help trace the sequence of events
  /// leading up to a crash.
  ///
  /// Example:
  ///   crashReporting.recordBreadcrumb('Opened lesson: lesson_id=abc');
  void recordBreadcrumb(String action) {
    final entry = '[${DateTime.now().toIso8601String()}] $action';
    _breadcrumbs.add(entry);

    // Keep last 30 breadcrumbs in memory
    if (_breadcrumbs.length > 30) _breadcrumbs.removeAt(0);

    _log('Breadcrumb: $action');
    // TODO: await FirebaseCrashlytics.instance.log(action);
  }

  // ── Custom Keys ───────────────────────────────────────────────────────────

  /// Attaches a custom key-value pair to subsequent crash reports.
  void setCustomKey(String key, dynamic value) {
    _log('Custom key set — $key: $value');
    // TODO: await FirebaseCrashlytics.instance.setCustomKey(key, value.toString());
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  void _log(String message) {
    if (kDebugMode) {
      debugPrint('[CrashReporting] $message');
    }
  }

  /// Returns collected breadcrumbs (useful for in-app debug screens).
  List<String> get breadcrumbs => List.unmodifiable(_breadcrumbs);

  /// Returns the currently associated user ID (if any).
  String? get currentUserId => _currentUserId;
}
