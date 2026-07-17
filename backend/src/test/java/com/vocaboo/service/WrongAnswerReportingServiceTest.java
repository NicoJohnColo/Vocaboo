package com.vocaboo.service;

import com.vocaboo.dto.response.LearnerWrongAnswersResponse;
import com.vocaboo.dto.response.LearnerWrongAnswersResponse.WrongWordDetail;
import com.vocaboo.dto.response.WrongAnswerAnalysisResponse;
import com.vocaboo.dto.response.WrongAnswerAnalysisResponse.ConfusedPairDetail;
import com.vocaboo.dto.response.WrongAnswerAnalysisResponse.CurriculumGapDetail;
import com.vocaboo.entity.*;
import com.vocaboo.repository.*;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.time.OffsetDateTime;
import java.util.*;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class WrongAnswerReportingServiceTest {

    @Mock
    private ReviewItemRepository reviewItemRepository;
    @Mock
    private ConfusableWordPairRepository confusableWordPairRepository;
    @Mock
    private WordProgressRepository wordProgressRepository;
    @Mock
    private PronunciationAttemptRepository pronunciationAttemptRepository;

    @InjectMocks
    private WrongAnswerReportingService service;

    @Test
    void getLearnerWrongAnswers_combinesReviewAndPronunciationErrors() {
        UUID learnerId = UUID.randomUUID();
        UUID wordId1 = UUID.randomUUID();
        UUID wordId2 = UUID.randomUUID();

        Learner learner = Learner.builder().learnerId(learnerId).build();
        VocabularyWord word1 = VocabularyWord.builder().wordId(wordId1).englishWord("Apple").partOfSpeech("Noun").build();
        VocabularyWord word2 = VocabularyWord.builder().wordId(wordId2).englishWord("Banana").partOfSpeech("Noun").build();

        OffsetDateTime now = OffsetDateTime.now();

        // 1. ReviewItems:
        // Word1: Incorrect at now.minusHours(4), Correct at now.minusHours(2)
        ReviewSession session = ReviewSession.builder().learner(learner).build();
        ReviewItem reviewItem1 = ReviewItem.builder()
                .session(session)
                .word(word1)
                .isCorrect(false)
                .createdAt(now.minusHours(4))
                .build();
        ReviewItem reviewItem2 = ReviewItem.builder()
                .session(session)
                .word(word1)
                .isCorrect(true)
                .createdAt(now.minusHours(2))
                .build();

        // 2. PronunciationAttempts:
        // Word1: Incorrect at now.minusHours(1) -> makes latest attempt Incorrect again!
        IntroductionSession introSession = IntroductionSession.builder().learner(learner).build();
        PronunciationAttempt pronAttempt1 = PronunciationAttempt.builder()
                .learner(learner)
                .session(introSession)
                .word(word1)
                .isCorrect(false)
                .isInconclusive(false)
                .recordedAt(now.minusHours(1))
                .build();

        // Word2: Incorrect at now.minusHours(5), Inconclusive at now.minusHours(3) (inconclusive should be ignored)
        PronunciationAttempt pronAttempt2 = PronunciationAttempt.builder()
                .learner(learner)
                .session(introSession)
                .word(word2)
                .isCorrect(false)
                .isInconclusive(false)
                .recordedAt(now.minusHours(5))
                .build();
        PronunciationAttempt pronAttempt3 = PronunciationAttempt.builder()
                .learner(learner)
                .session(introSession)
                .word(word2)
                .isCorrect(false)
                .isInconclusive(true) // inconclusive -> ignored
                .recordedAt(now.minusHours(3))
                .build();

        when(reviewItemRepository.findAllByLearnerIdOrderByCreatedAtAsc(learnerId))
                .thenReturn(List.of(reviewItem1, reviewItem2));
        when(pronunciationAttemptRepository.findByLearnerLearnerIdOrderByRecordedAtAsc(learnerId))
                .thenReturn(List.of(pronAttempt2, pronAttempt3, pronAttempt1));
        when(wordProgressRepository.findByLearnerLearnerId(learnerId))
                .thenReturn(Collections.emptyList());

        LearnerWrongAnswersResponse response = service.getLearnerWrongAnswers(learnerId);

        assertNotNull(response);
        // Word1 errors: reviewItem1 (incorrect), pronAttempt1 (incorrect) = 2 errors
        // Word2 errors: pronAttempt2 (incorrect) = 1 error. (pronAttempt3 is inconclusive and ignored).
        // Total errors: 2 + 1 = 3. Demerits: 3 * 2 = 6 points.
        assertEquals(6, response.getDemeritPoints());
        assertEquals(2, response.getWords().size());

        // Sort check: Word1 should be first because it has 2 errors, Word2 second with 1 error
        WrongWordDetail first = response.getWords().get(0);
        assertEquals(wordId1, first.getWordId());
        assertEquals(2, first.getErrorCount());
        // CurrentlyCorrect determines if the absolute latest attempt was correct.
        // For Word1, the attempts are:
        // - Review (isCorrect=false) at now.minusHours(4)
        // - Review (isCorrect=true) at now.minusHours(2)
        // - Pronunciation (isCorrect=false) at now.minusHours(1)
        // So the latest attempt is Pronunciation (isCorrect=false), so currentlyCorrect should be false.
        assertFalse(first.isCurrentlyCorrect());

        WrongWordDetail second = response.getWords().get(1);
        assertEquals(wordId2, second.getWordId());
        assertEquals(1, second.getErrorCount());
        assertFalse(second.isCurrentlyCorrect());
    }

    @Test
    void getClassWideWrongAnswerAnalysis_aggregatesBothErrors() {
        UUID learner1Id = UUID.randomUUID();
        UUID learner2Id = UUID.randomUUID();
        UUID wordAId = UUID.randomUUID();
        UUID wordBId = UUID.randomUUID();

        Learner learner1 = Learner.builder().learnerId(learner1Id).build();
        Learner learner2 = Learner.builder().learnerId(learner2Id).build();

        Lesson lesson = Lesson.builder().lessonId(UUID.randomUUID()).lessonTitle("Animals").build();
        VocabularyWord wordA = VocabularyWord.builder().wordId(wordAId).englishWord("Dog").lesson(lesson).build();
        VocabularyWord wordB = VocabularyWord.builder().wordId(wordBId).englishWord("Cat").lesson(lesson).build();

        // 1. ReviewItems: Learner1 got Dog incorrect
        ReviewSession session1 = ReviewSession.builder().learner(learner1).build();
        ReviewItem item1 = ReviewItem.builder()
                .session(session1)
                .word(wordA)
                .isCorrect(false)
                .createdAt(OffsetDateTime.now())
                .build();

        // 2. PronAttempts: Learner2 got Cat incorrect
        IntroductionSession session2 = IntroductionSession.builder().learner(learner2).build();
        PronunciationAttempt attempt1 = PronunciationAttempt.builder()
                .learner(learner2)
                .session(session2)
                .word(wordB)
                .isCorrect(false)
                .isInconclusive(false)
                .recordedAt(OffsetDateTime.now())
                .build();

        when(reviewItemRepository.findAllOrderByCreatedAtAsc()).thenReturn(List.of(item1));
        when(pronunciationAttemptRepository.findAll()).thenReturn(List.of(attempt1));

        // Mock confusable word pair
        ConfusableWordPair pair = ConfusableWordPair.builder()
                .wordA(wordA)
                .wordB(wordB)
                .lesson(lesson)
                .build();
        when(confusableWordPairRepository.findAll()).thenReturn(List.of(pair));

        WrongAnswerAnalysisResponse response = service.getClassWideWrongAnswerAnalysis();

        assertNotNull(response);
        // Total class errors: 1 review + 1 pronunciation = 2 errors
        assertEquals(2, response.getTotalClassErrors());
        // Learners with errors: learner1, learner2 = 2 learners
        assertEquals(2, response.getLearnersWithErrors());

        // Confused pair assertions
        assertEquals(1, response.getConfusedPairs().size());
        ConfusedPairDetail pairDetail = response.getConfusedPairs().get(0);
        assertEquals(wordAId, pairDetail.getWordAId());
        assertEquals(wordBId, pairDetail.getWordBId());
        assertEquals(2, pairDetail.getTotalErrors());
        assertEquals(2, pairDetail.getAffectedLearners());

        // Curriculum gap assertions
        assertEquals(1, response.getCurriculumGaps().size());
        CurriculumGapDetail gapDetail = response.getCurriculumGaps().get(0);
        assertEquals(lesson.getLessonId(), gapDetail.getLessonId());
        assertEquals(2, gapDetail.getTotalErrors());
        assertEquals(2, gapDetail.getAffectedLearners());
    }
}
