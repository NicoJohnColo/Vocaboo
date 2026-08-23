package com.vocaboo.service;

import com.vocaboo.dto.response.DifficultyProgressResponse;
import com.vocaboo.entity.*;
import com.vocaboo.repository.*;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import java.util.Optional;
import java.util.UUID;
import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class DifficultyAdjustmentServiceTest {

    @Mock
    private DifficultyProgressRepository progressRepository;
    @Mock
    private DifficultyAuditLogRepository auditLogRepository;
    @Mock
    private LearnerRepository learnerRepository;
    @Mock
    private VocabularyWordRepository wordRepository;
    @Mock
    private PointTransactionRepository pointTransactionRepository;
    @Mock
    private LearnerMasteryRepository masteryRepository;

    @InjectMocks
    private DifficultyAdjustmentService service;

    @Test
    void getCurrentLevel_returnsCorrectLevel() {
        UUID learnerId = UUID.randomUUID();
        UUID wordId = UUID.randomUUID();
        DifficultyProgress progress = DifficultyProgress.builder().currentLevel(DifficultyLevel.FAMILIAR).build();

        when(progressRepository.findByLearnerLearnerIdAndWordWordId(learnerId, wordId))
                .thenReturn(Optional.of(progress));

        DifficultyLevel level = service.getCurrentLevel(learnerId, wordId);

        assertEquals(DifficultyLevel.FAMILIAR, level);
    }

    @Test
    void getCurrentLevel_defaultsToLearning() {
        UUID learnerId = UUID.randomUUID();
        UUID wordId = UUID.randomUUID();

        when(progressRepository.findByLearnerLearnerIdAndWordWordId(learnerId, wordId))
                .thenReturn(Optional.empty());

        DifficultyLevel level = service.getCurrentLevel(learnerId, wordId);

        assertEquals(DifficultyLevel.LEARNING, level);
    }

    @Test
    void calculateNext_learningLevel_oneCorrectAnswer_upgradesToFamiliar() {
        UUID learnerId = UUID.randomUUID();
        UUID wordId = UUID.randomUUID();

        Learner learner = Learner.builder().learnerId(learnerId).build();
        VocabularyWord word = VocabularyWord.builder().wordId(wordId).build();
        DifficultyProgress progress = DifficultyProgress.builder()
                .learner(learner)
                .word(word)
                .currentLevel(DifficultyLevel.LEARNING)
                .consecutiveCorrect(0)
                .consecutiveIncorrect(0)
                .build();

        when(progressRepository.findByLearnerLearnerIdAndWordWordId(learnerId, wordId))
                .thenReturn(Optional.of(progress));
        when(progressRepository.save(any(DifficultyProgress.class))).thenAnswer(invocation -> invocation.getArgument(0));

        DifficultyProgressResponse response = service.calculateNext(learnerId, wordId, true);

        assertNotNull(response);
        assertEquals(DifficultyLevel.FAMILIAR.name(), response.getCurrentLevel());
        assertEquals(0, response.getConsecutiveCorrect());

        verify(auditLogRepository, times(1)).save(argThat(log ->
                log.getOldLevel() == DifficultyLevel.LEARNING &&
                log.getNewLevel() == DifficultyLevel.FAMILIAR &&
                "CONSECUTIVE_CORRECT".equals(log.getReason())
        ));
    }

    @Test
    void calculateNext_proficientLevel_threeCorrectAnswers_upgradesToMasteredAndAwardsPoints() {
        UUID learnerId = UUID.randomUUID();
        UUID wordId = UUID.randomUUID();

        Learner learner = Learner.builder().learnerId(learnerId).build();
        VocabularyWord word = VocabularyWord.builder().wordId(wordId).build();
        DifficultyProgress progress = DifficultyProgress.builder()
                .learner(learner)
                .word(word)
                .currentLevel(DifficultyLevel.PROFICIENT)
                .consecutiveCorrect(1)
                .consecutiveIncorrect(0)
                .build();

        when(progressRepository.findByLearnerLearnerIdAndWordWordId(learnerId, wordId))
                .thenReturn(Optional.of(progress));
        when(progressRepository.save(any(DifficultyProgress.class))).thenAnswer(invocation -> invocation.getArgument(0));
        when(pointTransactionRepository.save(any(PointTransaction.class))).thenAnswer(inv -> inv.getArgument(0));
        when(masteryRepository.findByLearnerLearnerId(learnerId))
                .thenReturn(Optional.of(LearnerMastery.builder().learner(learner).totalPoints(0).build()));
        when(masteryRepository.save(any(LearnerMastery.class))).thenAnswer(inv -> inv.getArgument(0));

        DifficultyProgressResponse response = service.calculateNext(learnerId, wordId, true);

        assertNotNull(response);
        assertEquals(DifficultyLevel.MASTERED.name(), response.getCurrentLevel());
        assertEquals(0, response.getConsecutiveCorrect());

        verify(auditLogRepository, times(1)).save(argThat(log ->
                log.getOldLevel() == DifficultyLevel.PROFICIENT &&
                log.getNewLevel() == DifficultyLevel.MASTERED &&
                "CONSECUTIVE_CORRECT".equals(log.getReason())
        ));
        verify(pointTransactionRepository, times(1)).save(argThat(tx ->
                tx.getActionType() == PointActionType.WORD_MASTERED &&
                tx.getPointsAwarded() == 50
        ));
    }

    @Test
    void calculateNext_familiarLevel_singleIncorrect_downgradesToLearning() {
        UUID learnerId = UUID.randomUUID();
        UUID wordId = UUID.randomUUID();

        Learner learner = Learner.builder().learnerId(learnerId).build();
        VocabularyWord word = VocabularyWord.builder().wordId(wordId).build();
        DifficultyProgress progress = DifficultyProgress.builder()
                .learner(learner)
                .word(word)
                .currentLevel(DifficultyLevel.FAMILIAR)
                .consecutiveCorrect(1)
                .consecutiveIncorrect(0)
                .build();

        when(progressRepository.findByLearnerLearnerIdAndWordWordId(learnerId, wordId))
                .thenReturn(Optional.of(progress));
        when(progressRepository.save(any(DifficultyProgress.class))).thenAnswer(invocation -> invocation.getArgument(0));

        DifficultyProgressResponse response = service.calculateNext(learnerId, wordId, false);

        assertNotNull(response);
        assertEquals(DifficultyLevel.LEARNING.name(), response.getCurrentLevel());
        assertEquals(0, response.getConsecutiveCorrect());
        assertEquals(0, response.getConsecutiveIncorrect());

        verify(auditLogRepository, times(1)).save(argThat(log ->
                log.getOldLevel() == DifficultyLevel.FAMILIAR &&
                log.getNewLevel() == DifficultyLevel.LEARNING &&
                "CONSECUTIVE_INCORRECT".equals(log.getReason())
        ));
    }

    @Test
    void calculateNext_proficientLevel_singleIncorrect_downgradesToFamiliar() {
        UUID learnerId = UUID.randomUUID();
        UUID wordId = UUID.randomUUID();

        Learner learner = Learner.builder().learnerId(learnerId).build();
        VocabularyWord word = VocabularyWord.builder().wordId(wordId).build();
        DifficultyProgress progress = DifficultyProgress.builder()
                .learner(learner)
                .word(word)
                .currentLevel(DifficultyLevel.PROFICIENT)
                .consecutiveCorrect(2)
                .consecutiveIncorrect(0)
                .build();

        when(progressRepository.findByLearnerLearnerIdAndWordWordId(learnerId, wordId))
                .thenReturn(Optional.of(progress));
        when(progressRepository.save(any(DifficultyProgress.class))).thenAnswer(invocation -> invocation.getArgument(0));

        DifficultyProgressResponse response = service.calculateNext(learnerId, wordId, false);

        assertNotNull(response);
        assertEquals(DifficultyLevel.FAMILIAR.name(), response.getCurrentLevel());
        assertEquals(0, response.getConsecutiveCorrect());
        assertEquals(0, response.getConsecutiveIncorrect());

        verify(auditLogRepository, times(1)).save(argThat(log ->
                log.getOldLevel() == DifficultyLevel.PROFICIENT &&
                log.getNewLevel() == DifficultyLevel.FAMILIAR &&
                "CONSECUTIVE_INCORRECT".equals(log.getReason())
        ));
    }

    @Test
    void calculateNext_masteredLevel_singleIncorrect_downgradesToProficient() {
        UUID learnerId = UUID.randomUUID();
        UUID wordId = UUID.randomUUID();

        Learner learner = Learner.builder().learnerId(learnerId).build();
        VocabularyWord word = VocabularyWord.builder().wordId(wordId).build();
        DifficultyProgress progress = DifficultyProgress.builder()
                .learner(learner)
                .word(word)
                .currentLevel(DifficultyLevel.MASTERED)
                .consecutiveCorrect(0)
                .consecutiveIncorrect(0)
                .build();

        when(progressRepository.findByLearnerLearnerIdAndWordWordId(learnerId, wordId))
                .thenReturn(Optional.of(progress));
        when(progressRepository.save(any(DifficultyProgress.class))).thenAnswer(invocation -> invocation.getArgument(0));

        DifficultyProgressResponse response = service.calculateNext(learnerId, wordId, false);

        assertNotNull(response);
        assertEquals(DifficultyLevel.PROFICIENT.name(), response.getCurrentLevel());
        assertEquals(0, response.getConsecutiveCorrect());
        assertEquals(0, response.getConsecutiveIncorrect());

        verify(auditLogRepository, times(1)).save(argThat(log ->
                log.getOldLevel() == DifficultyLevel.MASTERED &&
                log.getNewLevel() == DifficultyLevel.PROFICIENT &&
                "CONSECUTIVE_INCORRECT".equals(log.getReason())
        ));
    }

    @Test
    void calculateNext_learningLevel_singleIncorrect_incrementsCounter() {
        UUID learnerId = UUID.randomUUID();
        UUID wordId = UUID.randomUUID();

        Learner learner = Learner.builder().learnerId(learnerId).build();
        VocabularyWord word = VocabularyWord.builder().wordId(wordId).build();
        DifficultyProgress progress = DifficultyProgress.builder()
                .learner(learner)
                .word(word)
                .currentLevel(DifficultyLevel.LEARNING)
                .consecutiveCorrect(0)
                .consecutiveIncorrect(0)
                .build();

        when(progressRepository.findByLearnerLearnerIdAndWordWordId(learnerId, wordId))
                .thenReturn(Optional.of(progress));
        when(progressRepository.save(any(DifficultyProgress.class))).thenAnswer(invocation -> invocation.getArgument(0));

        DifficultyProgressResponse response = service.calculateNext(learnerId, wordId, false);

        assertNotNull(response);
        assertEquals(DifficultyLevel.LEARNING.name(), response.getCurrentLevel());
        assertEquals(1, response.getConsecutiveIncorrect());
        assertFalse(response.getShowExplanations());
    }

    @Test
    void calculateNext_learningLevel_twoIncorrect_triggersShortReintroduction() {
        UUID learnerId = UUID.randomUUID();
        UUID wordId = UUID.randomUUID();

        Learner learner = Learner.builder().learnerId(learnerId).build();
        VocabularyWord word = VocabularyWord.builder().wordId(wordId).build();
        DifficultyProgress progress = DifficultyProgress.builder()
                .learner(learner)
                .word(word)
                .currentLevel(DifficultyLevel.LEARNING)
                .consecutiveCorrect(0)
                .consecutiveIncorrect(1)
                .reintroductionCount(0)
                .needsReintroduction(false)
                .build();

        when(progressRepository.findByLearnerLearnerIdAndWordWordId(learnerId, wordId))
                .thenReturn(Optional.of(progress));
        when(progressRepository.save(any(DifficultyProgress.class))).thenAnswer(invocation -> invocation.getArgument(0));

        DifficultyProgressResponse response = service.calculateNext(learnerId, wordId, false);

        assertNotNull(response);
        assertEquals(DifficultyLevel.LEARNING.name(), response.getCurrentLevel());
        assertTrue(response.getNeedsReintroduction());
        assertEquals(1, response.getReintroductionCount());
        assertNotNull(response.getLastReintroducedAt());
        assertEquals(0, response.getConsecutiveIncorrect());

        verify(auditLogRepository, times(1)).save(argThat(log ->
                log.getOldLevel() == DifficultyLevel.LEARNING &&
                log.getNewLevel() == DifficultyLevel.LEARNING &&
                "SHORT_REINTRODUCTION_TRIGGERED".equals(log.getReason())
        ));
    }

    @Test
    void completeReintroduction_resetsFlagsAndCounters() {
        UUID learnerId = UUID.randomUUID();
        UUID wordId = UUID.randomUUID();

        Learner learner = Learner.builder().learnerId(learnerId).build();
        VocabularyWord word = VocabularyWord.builder().wordId(wordId).build();
        DifficultyProgress progress = DifficultyProgress.builder()
                .learner(learner)
                .word(word)
                .currentLevel(DifficultyLevel.LEARNING)
                .needsReintroduction(true)
                .reintroductionCount(1)
                .consecutiveCorrect(0)
                .consecutiveIncorrect(0)
                .build();

        when(progressRepository.findByLearnerLearnerIdAndWordWordId(learnerId, wordId))
                .thenReturn(Optional.of(progress));
        when(progressRepository.save(any(DifficultyProgress.class))).thenAnswer(invocation -> invocation.getArgument(0));

        DifficultyProgressResponse response = service.completeReintroduction(learnerId, wordId);

        assertNotNull(response);
        assertFalse(response.getNeedsReintroduction());
        assertEquals(0, response.getConsecutiveCorrect());
        assertEquals(0, response.getConsecutiveIncorrect());

        verify(auditLogRepository, times(1)).save(argThat(log ->
                log.getReason().equals("REINTRODUCTION_COMPLETED")
        ));
    }
}
