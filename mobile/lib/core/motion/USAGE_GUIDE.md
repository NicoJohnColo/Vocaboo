# Vocaboo Motion Design, Typography & Performance System — Developer Guide

This module provides a unified, high-performance motion design and typography system tailored specifically for **young learners (ages 9-12)** on Flutter (iOS + Android).

---

## 1. Motion & Typography Philosophy (Ages 9-12)

1. **Encouraging, Not Corporate**:
   - Uses mild spring/overshoot curves (`Curves.easeOutBack` at low amplitude) for rewarding moments (correct answer, level complete, badge earned).
   - Feels like a warm, supportive "yay!" without jarring cartoon delay.
2. **Predictable Navigation**:
   - Screen navigation is calm and spatial (`SharedAxisZ` for depth drill-downs, `FadeThrough` for top-level tabs) to prevent cognitive fatigue during study sessions.
3. **Gentle, Non-Punishing Feedback**:
   - Correct answers trigger sparkling stars and checkmarks with a satisfying 450ms pulse.
   - Incorrect answers trigger a gentle soft horizontal nudge with warm amber styling (no harsh red flashes or alarming buzzers).
4. **Child-Centric Typography**:
   - **Headers & Celebrations**: `Fredoka` (rounded, expressive, energetic).
   - **Body & Instructions**: `Nunito` (high letter distinction between `l`, `1`, `I` and `0`, `O` to support developing readers).
5. **Universal Accessibility**:
   - Automatically supports OS-level `Reduce Motion` (`MediaQuery.disableAnimations`).
   - Colorblind-safe with distinct shapes, icons, and text labels.

---

## 2. Centralized Design Tokens

Never use magic numbers. Use `AppDurations`, `AppCurves`, and `AppTypography`:

```dart
import 'package:mobile/core/motion/motion.dart';

// Durations
AppDurations.micro        // 100ms: Checkbox toggles, button press-down
AppDurations.short        // 200ms: Tooltips, chip selections, focus glows
AppDurations.standard     // 300ms: Bottom sheets, dialogs, tab indicators
AppDurations.emphasized   // 450ms: Screen transitions, hero flights, container morphs
AppDurations.celebratory  // 550ms: Correct answer pops, streak celebrations
AppDurations.long         // 650ms: Shimmer sweeps, badge unlocks, cold-start splash

// Curves
AppCurves.standard             // Material 3 Standard easing: Cubic(0.2, 0.0, 0.0, 1.0)
AppCurves.emphasizedDecelerate // Incoming views: Cubic(0.05, 0.7, 0.1, 1.0)
AppCurves.celebratory          // Gentle spring overshoot for kids: Curves.easeOutBack
AppCurves.springBack           // Tactile button bounce release: Curves.easeOutBack

// Typography Tokens
AppTypography.displayLarge     // Fredoka 32pt bold (Main headers)
AppTypography.celebratory      // Fredoka 28pt bold (Level complete, gold badges)
AppTypography.titleLarge       // Fredoka 22pt semi-bold (Section cards)
AppTypography.bodyLarge        // Nunito 17pt (Instructions, lesson sentences)
AppTypography.bodyMedium       // Nunito 15pt (Meanings, helper hints)
```

---

## 3. Screen-to-Screen Navigation (GoRouter)

Wrap all route destinations with `AppPageTransitions.page()` in `app_router.dart`:

```dart
GoRoute(
  path: '/category/:id/lessons',
  pageBuilder: (context, state) => AppPageTransitions.page(
    type: AppMotionType.sharedAxisZ, // Depth drill-down navigation
    child: LessonPathScreen(categoryId: state.pathParameters['id']!),
  ),
),
```

### Transition Types Reference:
- `AppMotionType.sharedAxisZ`: **Parent-Child Depth Navigation** (e.g. Category Card -> Lesson Path -> Active Practice).
- `AppMotionType.sharedAxisX`: **Sibling / Tab Navigation** (e.g. Onboarding steps, swipeable lesson modules).
- `AppMotionType.sharedAxisY`: **Sequential Step Workflows** (e.g. Question-to-question diagnostic flows).
- `AppMotionType.fadeThrough`: **Top-Level Navigation** (e.g. switching between Home, Leaderboard, Dashboard).
- `AppMotionType.modalSheet`: **Modal / Summary Navigation** (slides up from bottom with spring deceleration).

---

## 4. Celebratory Rewards & Feedback

### Answer Feedback (`AppAnswerFeedback`)
```dart
// Correct answer with star burst:
AppAnswerFeedback(
  isCorrect: true,
  title: 'Awesome job! 🎉',
  subtitle: 'You mastered this word with zero mistakes!',
  onContinue: _nextQuestion,
)

// Incorrect answer with gentle soft nudge:
AppAnswerFeedback(
  isCorrect: false,
  title: "Don't worry! Let's try again! 🌟",
  subtitle: 'The correct answer is: Dagat (Sea)',
  onContinue: _retryQuestion,
)
```

### Milestone & Badge Celebration Dialog (`AppBadgeCelebration`)
```dart
AppBadgeCelebration.show(
  context,
  title: 'Lesson Mastered! 🏆',
  badgeName: 'PERFECT GOLD',
  subtitle: 'You completed all 9 words with 100% accuracy!',
  scoreEarned: 150,
  scoreSuffix: ' XP',
);
```

### Animated Counters & Smooth Progress Bars
```dart
// Smooth number ticker (scores, streaks, XP)
AppAnimatedCounter(
  value: currentScore,
  suffix: '%',
  style: AppTypography.displayLarge,
)

// Smooth spring-fill progress bar
AppAnimatedProgressBar(
  progress: completedCount / totalCount,
  height: 12,
  showLabel: true,
)
```

---

## 5. Micro-Interactions & Form Controls

### Tactile Button Feedback (`AppPressable`)
Wrap any card, chip, or button for spring scale (`0.96x`) on tap:
```dart
AppPressable(
  onTap: () => startLesson(),
  child: LessonCard(lesson: lesson),
)
```

### Animated Text Field & Form Controls
```dart
// Animated glow & floating label:
AppAnimatedTextField(
  controller: _textController,
  labelText: 'Enter Topic or Word',
  prefixIcon: Icons.edit_rounded,
)

// Spring Switch & Checkbox:
AppAnimatedSwitch(
  value: _isAudioEnabled,
  onChanged: (val) => setState(() => _isAudioEnabled = val),
)
```

---

## 6. Shimmer Loading & Skeletons

```dart
// Built-in presets:
AppShimmer.card(height: 160)
AppShimmer.listTile()
AppShimmer.avatar(size: 56)
AppShimmer.grid(itemCount: 4)

// State Switcher (Loading, Content, Empty, Error):
AppStateSwitcher(
  state: _uiState,
  loading: AppShimmer.grid(itemCount: 4),
  content: CategoryGrid(categories: data),
  empty: EmptyStateWidget(),
  error: FriendlyErrorWidget(),
)
```

---

## 7. Performance & Verification Checklist

- **Hardware Acceleration**: Transform & Opacity animations run on the GPU compositor thread.
- **RepaintBoundary**: Applied automatically around animated routes, sheets, and shimmers.
- **No Layout Thrashing**: Uses `Transform.scale` and `Transform.translate` instead of changing layout size/padding during animation.
- **Reduce Motion Support**: Automatically collapses animations to `Duration.zero` / `Curves.linear` when requested by the OS.
