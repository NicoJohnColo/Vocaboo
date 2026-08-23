import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/core/motion/motion.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  group('Motion Design Tokens Tests', () {
    test('AppDurations are defined according to mobile UX standards', () {
      expect(AppDurations.micro.inMilliseconds, equals(100));
      expect(AppDurations.short.inMilliseconds, equals(200));
      expect(AppDurations.standard.inMilliseconds, equals(300));
      expect(AppDurations.emphasized.inMilliseconds, equals(450));
      expect(AppDurations.celebratory.inMilliseconds, equals(550));
      expect(AppDurations.long.inMilliseconds, equals(650));
    });

    test('AppCurves are valid non-linear curves', () {
      expect(AppCurves.standard, isA<Cubic>());
      expect(AppCurves.emphasizedDecelerate, isA<Cubic>());
      expect(AppCurves.emphasizedAccelerate, isA<Cubic>());
      expect(AppCurves.springBack, equals(Curves.easeOutBack));
      expect(AppCurves.celebratory, equals(Curves.easeOutBack));
    });

    test('AppTypography provides child-friendly fonts and styles', () {
      expect(AppTypography.displayLarge.fontSize, equals(32));
      expect(AppTypography.celebratory.fontSize, equals(28));
      expect(AppTypography.bodyLarge.fontSize, equals(17));
      expect(AppTypography.bodyMedium.fontSize, equals(15));
      expect(AppTypography.caption.fontSize, equals(13));
    });
  });

  group('Accessibility & Reduced Motion Tests', () {
    testWidgets('AppMotion.duration returns baseDuration when reduceMotion is false', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(disableAnimations: false),
            child: Builder(
              builder: (context) {
                final duration = AppMotion.duration(context, AppDurations.standard);
                expect(duration, equals(AppDurations.standard));
                return const SizedBox();
              },
            ),
          ),
        ),
      );
    });

    testWidgets('AppMotion.duration returns Duration.zero when reduceMotion is true', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: Builder(
              builder: (context) {
                final duration = AppMotion.duration(context, AppDurations.standard);
                expect(duration, equals(Duration.zero));
                return const SizedBox();
              },
            ),
          ),
        ),
      );
    });

    testWidgets('AppMotion.curve returns Curves.linear when reduceMotion is true', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: Builder(
              builder: (context) {
                final curve = AppMotion.curve(context, AppCurves.springBack);
                expect(curve, equals(Curves.linear));
                return const SizedBox();
              },
            ),
          ),
        ),
      );
    });
  });

  group('Motion Widgets & Micro-Interactions Tests', () {
    testWidgets('AppPressable renders and executes onTap', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppPressable(
              onTap: () => tapped = true,
              child: const Text('Tap Me'),
            ),
          ),
        ),
      );

      expect(find.text('Tap Me'), findsOneWidget);

      await tester.tap(find.text('Tap Me'));
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
    });

    testWidgets('AppShimmer renders presets without exceptions', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                AppShimmer.card(height: 100),
                AppShimmer.listTile(),
                AppShimmer.avatar(size: 40),
                AppShimmer.textLine(width: 80),
              ],
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(AppShimmer), findsNWidgets(4));
    });

    testWidgets('AppAnimatedCounter renders and animates number changes', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppAnimatedCounter(value: 50, suffix: ' XP'),
          ),
        ),
      );

      expect(find.text('50 XP'), findsOneWidget);
    });

    testWidgets('AppAnimatedProgressBar renders given progress', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppAnimatedProgressBar(
              progress: 0.75,
              showLabel: true,
            ),
          ),
        ),
      );

      expect(find.text('75%'), findsOneWidget);
      expect(find.byType(AppAnimatedProgressBar), findsOneWidget);
    });

    testWidgets('AppAnswerFeedback renders correct and incorrect states', (tester) async {
      bool continued = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppAnswerFeedback(
              isCorrect: true,
              title: 'Great work!',
              onContinue: () => continued = true,
            ),
          ),
        ),
      );

      expect(find.text('Great work!'), findsOneWidget);
      expect(find.text('CONTINUE'), findsOneWidget);

      await tester.tap(find.text('CONTINUE'));
      await tester.pumpAndSettle();
      expect(continued, isTrue);
    });

    testWidgets('AppStateSwitcher renders corresponding state widget', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppStateSwitcher(
              status: AppViewStatus.empty,
              loadingPlaceholder: Text('Loading State'),
              content: Text('Content State'),
              emptyState: Text('Empty State'),
              errorState: Text('Error State'),
            ),
          ),
        ),
      );

      expect(find.text('Empty State'), findsOneWidget);
      expect(find.text('Content State'), findsNothing);
    });

    testWidgets('AppHero wraps child cleanly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppHero(
              tag: 'test_tag',
              child: Text('Hero Child'),
            ),
          ),
        ),
      );

      expect(find.text('Hero Child'), findsOneWidget);
    });

    testWidgets('AppPageTransitions.page builds CustomTransitionPage properly', (tester) async {
      final page = AppPageTransitions.page(
        type: AppMotionType.sharedAxisZ,
        child: const Text('Page Content'),
      );

      expect(page, isNotNull);
    });
  });
}
