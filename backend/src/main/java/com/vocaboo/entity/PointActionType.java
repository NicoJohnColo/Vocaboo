package com.vocaboo.entity;

public enum PointActionType {
    CORRECT_ANSWER,
    WORD_MASTERED,
    LESSON_COMPLETE,
    PERFECT_SESSION,
    DAILY_STREAK,
    /** +50 bonus awarded once per word per learner the instant the tier reaches MASTERED. */
    MASTERY_BONUS,
    /** +15 bonus per eligible Sentence Completion/Rearrangement use of a cross-lesson known word. */
    CROSS_LESSON_BONUS
}
