import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mobile/screens/sentence_building_screen.dart';
import 'package:mobile/providers/lesson_provider.dart';
import 'package:mobile/providers/auth_provider.dart';

void main() {
  testWidgets('SentenceBuildingScreen Tile Arrangement, Wrong-Answer Feedback & Format Swap Test', (WidgetTester tester) async {
    final testWords = [
      {
        'wordId': 'word-1',
        'englishWord': 'book',
        'cebuanoMeaning': 'libro',
        'exampleSentenceEnglish': 'She reads a book.',
        'exampleSentenceCebuano': 'Nabasag libro siya.',
        'sentenceCompletionSentence': 'She reads a ___ .',
        'sentenceCompletionAnswer': 'book',
        'sentenceCompletionOption1': 'cat',
        'sentenceCompletionOption2': 'sun',
        'sentenceCompletionOption3': 'dog',
        'sentenceArrangementTokens': ['She', 'reads', 'a', 'book'],
      },
    ];

    print('=========================================================================');
    print('[FLUTTER WIDGET TEST: MODULE 3 TILE ARRANGEMENT & FORMAT SWAP]');

    final authProvider = AuthProvider();
    final lessonProvider = LessonProvider(authProvider);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: authProvider),
          ChangeNotifierProvider.value(value: lessonProvider),
        ],
        child: MaterialApp(
          home: SentenceBuildingScreen(
            sessionId: 'test-session-123',
            lessonId: 'test-lesson-123',
            categoryId: 'test-category-123',
            lessonTitle: 'Objects Lesson',
            allWords: testWords,
            isSandbox: true,
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // 1. Initial Format Verification (Completion)
    print('STEP 1: Initial format loaded (Completion). Instruction text verified.');
    expect(find.textContaining('Select the correct word'), findsOneWidget);

    // 2. Tap Wrong Option ('cat' instead of 'book')
    print('STEP 2: Tapping WRONG completion option tile ("cat")...');
    final wrongTile = find.text('cat');
    expect(wrongTile, findsOneWidget);
    await tester.ensureVisible(wrongTile);
    await tester.pumpAndSettle();
    await tester.tap(wrongTile);
    await tester.pumpAndSettle();

    // 3. Tap Check Answer
    print('STEP 3: Tapping "CHECK ANSWER" button...');
    final checkButton = find.text('CHECK ANSWER');
    expect(checkButton, findsOneWidget);
    await tester.ensureVisible(checkButton);
    await tester.pumpAndSettle();
    await tester.tap(checkButton);
    await tester.pumpAndSettle();

    // 4. Verify Wrong Answer Feedback Screen
    print('STEP 4: Verifying wrong answer red feedback banner on screen...');
    expect(find.text("Let's review the correct structure:"), findsOneWidget);
    expect(find.textContaining("Remember: 'book' means 'libro'"), findsOneWidget);

    // 5. Tap CONTINUE button to trigger format swap
    print('STEP 5: Tapping "CONTINUE" button to advance and trigger format swap...');
    final continueButton = find.text('CONTINUE');
    expect(continueButton, findsOneWidget);
    await tester.ensureVisible(continueButton);
    await tester.pumpAndSettle();
    await tester.tap(continueButton);
    await tester.pumpAndSettle();

    // 6. Verify Format Swap to Rearrangement & WORD BANK display
    print('STEP 6: Verifying format swapped to Rearrangement with WORD BANK...');
    expect(find.text('WORD BANK'), findsOneWidget);
    expect(find.textContaining('Drag or tap the words'), findsOneWidget);

    // 7. Tap chips from WORD BANK to assemble sentence
    print('STEP 7: Tapping word chips from WORD BANK into sentence assembly row...');
    final chipShe = find.widgetWithText(ActionChip, 'She');
    final chipReads = find.widgetWithText(ActionChip, 'reads');
    final chipA = find.widgetWithText(ActionChip, 'a');
    final chipBook = find.widgetWithText(ActionChip, 'book');

    if (chipShe.evaluate().isNotEmpty) {
      await tester.ensureVisible(chipShe);
      await tester.pumpAndSettle();
      await tester.tap(chipShe);
      await tester.pumpAndSettle();
      print('  -> Tapped tile "She"');
    }
    if (chipReads.evaluate().isNotEmpty) {
      await tester.ensureVisible(chipReads);
      await tester.pumpAndSettle();
      await tester.tap(chipReads);
      await tester.pumpAndSettle();
      print('  -> Tapped tile "reads"');
    }
    if (chipA.evaluate().isNotEmpty) {
      await tester.ensureVisible(chipA);
      await tester.pumpAndSettle();
      await tester.tap(chipA);
      await tester.pumpAndSettle();
      print('  -> Tapped tile "a"');
    }
    if (chipBook.evaluate().isNotEmpty) {
      await tester.ensureVisible(chipBook);
      await tester.pumpAndSettle();
      await tester.tap(chipBook);
      await tester.pumpAndSettle();
      print('  -> Tapped tile "book"');
    }

    print('STEP 8: Tapping check button for assembled tiles...');
    final checkSentenceBtn = find.byType(ElevatedButton).last;
    expect(checkSentenceBtn, findsOneWidget);
    await tester.ensureVisible(checkSentenceBtn);
    await tester.pumpAndSettle();
    await tester.tap(checkSentenceBtn);
    await tester.pumpAndSettle();

    print('STEP 9: Verifying correct green feedback banner for assembled sentence...');
    expect(find.text('Correct!'), findsOneWidget);

    print('[ALL TILE INTERACTIONS, WRONG-ANSWER FEEDBACK, FORMAT-SWAP, AND REARRANGEMENT ASSEMBLE VERIFIED 100%]');
    print('=========================================================================');
  });
}
