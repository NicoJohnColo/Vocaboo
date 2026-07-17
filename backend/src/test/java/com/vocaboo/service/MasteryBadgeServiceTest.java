package com.vocaboo.service;

import com.vocaboo.entity.*;
import com.vocaboo.repository.*;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.*;

import java.util.*;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

class MasteryBadgeServiceTest {

    @Mock WordPerformanceRepository performanceRepo;
    @Mock DifficultyProgressRepository difficultyRepo;
    @Mock RewardDataRepository rewardRepo;
    @Mock LearnerRepository learnerRepo;
    @Mock LessonRepository lessonRepo;
    @Mock VocabularyWordRepository wordRepo;

    MasteryBadgeService service;

    UUID learnerId = UUID.randomUUID();
    UUID lessonId  = UUID.randomUUID();
    UUID wordId    = UUID.randomUUID();

    Learner learner;
    Lesson  lesson;
    VocabularyWord word;

    @BeforeEach
    void setUp() {
        MockitoAnnotations.openMocks(this);
        service = new MasteryBadgeService(
                performanceRepo, difficultyRepo, rewardRepo,
                learnerRepo, lessonRepo, wordRepo);

        learner = new Learner();
        lesson  = new Lesson();
        word    = new VocabularyWord();

        setField(word, "wordId", wordId);

        when(learnerRepo.findById(learnerId)).thenReturn(Optional.of(learner));
        when(lessonRepo.findById(lessonId)).thenReturn(Optional.of(lesson));
        when(wordRepo.findByLessonLessonIdOrderByWordOrderAsc(lessonId)).thenReturn(List.of(word));
        when(rewardRepo.findByLearnerLearnerIdAndLessonLessonId(any(), any())).thenReturn(List.of());
        when(rewardRepo.save(any())).thenAnswer(i -> i.getArgument(0));
    }

    private void setField(Object target, String fieldName, Object value) {
        try {
            java.lang.reflect.Field f = target.getClass().getDeclaredField(fieldName);
            f.setAccessible(true);
            f.set(target, value);
        } catch (Exception e) {
            throw new RuntimeException(e);
        }
    }

    private WordPerformance makePerf(int correct, int incorrect) {
        WordPerformance p = new WordPerformance();
        setField(p, "correctCount", correct);
        setField(p, "incorrectCount", incorrect);
        setField(p, "totalAttempts", correct + incorrect);
        return p;
    }

    private DifficultyProgress makeDiff(DifficultyLevel level) {
        DifficultyProgress d = new DifficultyProgress();
        setField(d, "currentLevel", level);
        return d;
    }

    @Test
    void perfectGold_zeroErrors_allMastered() {
        when(performanceRepo.findByLearnerLearnerIdAndWordWordId(learnerId, wordId))
                .thenReturn(Optional.of(makePerf(5, 0)));
        when(difficultyRepo.findByLearnerLearnerIdAndWordWordId(learnerId, wordId))
                .thenReturn(Optional.of(makeDiff(DifficultyLevel.MASTERED)));

        String badge = service.calculateAndSaveBadge(learnerId, lessonId);

        assertThat(badge).isEqualTo("PERFECT_GOLD");
    }

    @Test
    void gold_twoErrors_allProficientOrMastered() {
        when(performanceRepo.findByLearnerLearnerIdAndWordWordId(learnerId, wordId))
                .thenReturn(Optional.of(makePerf(5, 2))); // 4 demerits
        when(difficultyRepo.findByLearnerLearnerIdAndWordWordId(learnerId, wordId))
                .thenReturn(Optional.of(makeDiff(DifficultyLevel.PROFICIENT)));

        String badge = service.calculateAndSaveBadge(learnerId, lessonId);

        assertThat(badge).isEqualTo("GOLD");
    }

    @Test
    void silver_fiveErrors_allFamiliarOrAbove() {
        when(performanceRepo.findByLearnerLearnerIdAndWordWordId(learnerId, wordId))
                .thenReturn(Optional.of(makePerf(3, 5))); // 10 demerits
        when(difficultyRepo.findByLearnerLearnerIdAndWordWordId(learnerId, wordId))
                .thenReturn(Optional.of(makeDiff(DifficultyLevel.FAMILIAR)));

        String badge = service.calculateAndSaveBadge(learnerId, lessonId);

        assertThat(badge).isEqualTo("SILVER");
    }

    @Test
    void bronze_manyErrors() {
        when(performanceRepo.findByLearnerLearnerIdAndWordWordId(learnerId, wordId))
                .thenReturn(Optional.of(makePerf(1, 6))); // 12 demerits
        when(difficultyRepo.findByLearnerLearnerIdAndWordWordId(learnerId, wordId))
                .thenReturn(Optional.of(makeDiff(DifficultyLevel.LEARNING)));

        String badge = service.calculateAndSaveBadge(learnerId, lessonId);

        assertThat(badge).isEqualTo("BRONZE");
    }

    @Test
    void emptyWordList_returnsBronze() {
        when(wordRepo.findByLessonLessonIdOrderByWordOrderAsc(lessonId)).thenReturn(List.of());

        String badge = service.calculateAndSaveBadge(learnerId, lessonId);

        assertThat(badge).isEqualTo("BRONZE");
    }
}
