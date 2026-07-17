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
    void calculateNext_correctResult_incrementsStreakAndUpgradesLevel() {
        UUID learnerId = UUID.randomUUID();
        UUID wordId = UUID.randomUUID();

        Learner learner = Learner.builder().learnerId(learnerId).build();
        VocabularyWord word = VocabularyWord.builder().wordId(wordId).build();
        DifficultyProgress progress = DifficultyProgress.builder()
                .learner(learner)
                .word(word)
                .currentLevel(DifficultyLevel.LEARNING)
                .consecutiveCorrect(2) // 2 correct streak before this
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
        assertEquals(DifficultyLevel.FAMILIAR.name(), response.getCurrentLevel());
        assertEquals(0, response.getConsecutiveCorrect()); // reset after promotion

        verify(auditLogRepository, times(1)).save(argThat(log ->
                log.getOldLevel() == DifficultyLevel.LEARNING &&
                log.getNewLevel() == DifficultyLevel.FAMILIAR &&
                "CONSECUTIVE_CORRECT".equals(log.getReason())
        ));
        verify(pointTransactionRepository, times(1)).save(argThat(tx ->
                tx.getActionType() == PointActionType.WORD_MASTERED &&
                tx.getPointsAwarded() == 50
        ));
    }

    @Test
    void calculateNext_correctResult_noUpgrade() {
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
                .build();

        when(progressRepository.findByLearnerLearnerIdAndWordWordId(learnerId, wordId))
                .thenReturn(Optional.of(progress));
        when(progressRepository.save(any(DifficultyProgress.class))).thenAnswer(invocation -> invocation.getArgument(0));

        DifficultyProgressResponse response = service.calculateNext(learnerId, wordId, true);

        assertNotNull(response);
        assertEquals(DifficultyLevel.LEARNING.name(), response.getCurrentLevel());
        assertEquals(1, response.getConsecutiveCorrect());
        assertEquals(0, response.getConsecutiveIncorrect()); // reset incorrect

        verifyNoInteractions(auditLogRepository);
    }

    @Test
    void calculateNext_incorrectResult_demotesLevel() {
        UUID learnerId = UUID.randomUUID();
        UUID wordId = UUID.randomUUID();

        Learner learner = Learner.builder().learnerId(learnerId).build();
        VocabularyWord word = VocabularyWord.builder().wordId(wordId).build();
        DifficultyProgress progress = DifficultyProgress.builder()
                .learner(learner)
                .word(word)
                .currentLevel(DifficultyLevel.PROFICIENT)
                .consecutiveCorrect(2)
                .consecutiveIncorrect(1) // already has 1 incorrect
                .build();

        when(progressRepository.findByLearnerLearnerIdAndWordWordId(learnerId, wordId))
                .thenReturn(Optional.of(progress));
        when(progressRepository.save(any(DifficultyProgress.class))).thenAnswer(invocation -> invocation.getArgument(0));

        DifficultyProgressResponse response = service.calculateNext(learnerId, wordId, false);

        assertNotNull(response);
        assertEquals(DifficultyLevel.FAMILIAR.name(), response.getCurrentLevel()); // demoted
        assertEquals(0, response.getConsecutiveCorrect()); // reset correct
        assertEquals(0, response.getConsecutiveIncorrect()); // reset incorrect after demotion

        verify(auditLogRepository, times(1)).save(argThat(log -> 
                log.getOldLevel() == DifficultyLevel.PROFICIENT &&
                log.getNewLevel() == DifficultyLevel.FAMILIAR &&
                "CONSECUTIVE_INCORRECT".equals(log.getReason())
        ));
    }

    @Test
    void calculateNext_incorrectResult_noDemotion() {
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

        DifficultyProgressResponse response = service.calculateNext(learnerId, wordId, false);

        assertNotNull(response);
        assertEquals(DifficultyLevel.PROFICIENT.name(), response.getCurrentLevel());
        assertEquals(0, response.getConsecutiveCorrect()); // reset correct
        assertEquals(1, response.getConsecutiveIncorrect()); // increment incorrect

        verifyNoInteractions(auditLogRepository);
    }

    @Test
    void increment_upgradesLevelDirectly() {
        UUID learnerId = UUID.randomUUID();
        UUID wordId = UUID.randomUUID();

        Learner learner = Learner.builder().learnerId(learnerId).build();
        VocabularyWord word = VocabularyWord.builder().wordId(wordId).build();
        DifficultyProgress progress = DifficultyProgress.builder()
                .learner(learner)
                .word(word)
                .currentLevel(DifficultyLevel.FAMILIAR)
                .consecutiveCorrect(1)
                .consecutiveIncorrect(1)
                .build();

        when(progressRepository.findByLearnerLearnerIdAndWordWordId(learnerId, wordId))
                .thenReturn(Optional.of(progress));
        when(progressRepository.save(any(DifficultyProgress.class))).thenAnswer(invocation -> invocation.getArgument(0));

        DifficultyProgressResponse response = service.increment(learnerId, wordId);

        assertNotNull(response);
        assertEquals(DifficultyLevel.PROFICIENT.name(), response.getCurrentLevel());
        assertEquals(0, response.getConsecutiveCorrect());
        assertEquals(0, response.getConsecutiveIncorrect());

        verify(auditLogRepository, times(1)).save(argThat(log -> 
                log.getOldLevel() == DifficultyLevel.FAMILIAR &&
                log.getNewLevel() == DifficultyLevel.PROFICIENT &&
                "MANUAL_INCREMENT".equals(log.getReason())
        ));
    }

    @Test
    void decrement_downgradesLevelDirectly() {
        UUID learnerId = UUID.randomUUID();
        UUID wordId = UUID.randomUUID();

        Learner learner = Learner.builder().learnerId(learnerId).build();
        VocabularyWord word = VocabularyWord.builder().wordId(wordId).build();
        DifficultyProgress progress = DifficultyProgress.builder()
                .learner(learner)
                .word(word)
                .currentLevel(DifficultyLevel.FAMILIAR)
                .build();

        when(progressRepository.findByLearnerLearnerIdAndWordWordId(learnerId, wordId))
                .thenReturn(Optional.of(progress));
        when(progressRepository.save(any(DifficultyProgress.class))).thenAnswer(invocation -> invocation.getArgument(0));

        DifficultyProgressResponse response = service.decrement(learnerId, wordId);

        assertNotNull(response);
        assertEquals(DifficultyLevel.LEARNING.name(), response.getCurrentLevel());

        verify(auditLogRepository, times(1)).save(argThat(log -> 
                log.getOldLevel() == DifficultyLevel.FAMILIAR &&
                log.getNewLevel() == DifficultyLevel.LEARNING &&
                "MANUAL_DECREMENT".equals(log.getReason())
        ));
    }
}
