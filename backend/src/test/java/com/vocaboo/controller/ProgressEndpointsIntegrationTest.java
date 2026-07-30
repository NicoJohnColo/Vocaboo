package com.vocaboo.controller;

import com.vocaboo.VocabooApplication;
import com.vocaboo.entity.*;
import com.vocaboo.repository.*;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.MvcResult;

import java.math.BigDecimal;
import java.time.OffsetDateTime;
import java.util.UUID;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest(classes = VocabooApplication.class)
@AutoConfigureMockMvc(addFilters = false)
class ProgressEndpointsIntegrationTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private LearnerRepository learnerRepository;

    @Autowired
    private VocabularyCategoryRepository categoryRepository;

    @Autowired
    private LessonRepository lessonRepository;

    @Autowired
    private VocabularyWordRepository wordRepository;

    @Autowired
    private LearnerMasteryRepository masteryRepository;

    @Autowired
    private WordPerformanceRepository performanceRepository;

    @Autowired
    private SessionSummaryRepository summaryRepository;

    @Autowired
    private PracticeSessionRepository sessionRepository;

    @Autowired
    private DifficultyProgressRepository difficultyProgressRepository;

    private UUID learnerId;
    private UUID lessonId;
    private UUID wordId;

    @BeforeEach
    void setUp() {
        Learner learner = learnerRepository.findAll().stream().findFirst().orElseGet(() ->
                learnerRepository.save(Learner.builder()
                        .displayName("Progress Tester")
                        .posFocus("NOUNS")
                        .languagePreference(LanguageMedium.CEBUANO_TO_ENGLISH)
                        .build())
        );
        learnerId = learner.getLearnerId();

        VocabularyCategory category = categoryRepository.findAll().stream().findFirst().orElseGet(() ->
                categoryRepository.save(VocabularyCategory.builder()
                        .categoryName("School Objects Test")
                        .build())
        );

        Lesson lesson = lessonRepository.findAll().stream().findFirst().orElseGet(() ->
                lessonRepository.save(Lesson.builder()
                        .category(category)
                        .lessonTitle("Lesson 1 - School Objects Test")
                        .gradeLevel(GradeLevel.GRADE_4)
                        .build())
        );
        lessonId = lesson.getLessonId();

        VocabularyWord word = wordRepository.findAll().stream().findFirst().orElseGet(() ->
                wordRepository.save(VocabularyWord.builder()
                        .lesson(lesson)
                        .englishWord("Pencil")
                        .cebuanoMeaning("Lapis")
                        .gradeLevel(GradeLevel.GRADE_4)
                        .build())
        );
        wordId = word.getWordId();

        // Ensure Mastery record
        masteryRepository.findByLearnerLearnerId(learnerId).orElseGet(() ->
                masteryRepository.save(LearnerMastery.builder()
                        .learner(learner)
                        .totalSessionsPlayed(1)
                        .totalCorrectAnswers(5)
                        .totalQuestionsAnswered(5)
                        .overallAccuracy(BigDecimal.valueOf(100.0))
                        .wordsMasteredCount(1)
                        .totalPoints(100)
                        .masteryLevel("MASTERED")
                        .build())
        );

        // Ensure WordPerformance record
        performanceRepository.findByLearnerLearnerIdAndWordWordId(learnerId, wordId).orElseGet(() ->
                performanceRepository.save(WordPerformance.builder()
                        .learner(learner)
                        .word(word)
                        .totalAttempts(5)
                        .correctCount(5)
                        .incorrectCount(0)
                        .accuracy(BigDecimal.valueOf(100.0))
                        .lastPracticedAt(OffsetDateTime.now())
                        .build())
        );

        // Ensure PracticeSession and SessionSummary
        PracticeSession session = sessionRepository.save(PracticeSession.builder()
                .learner(learner)
                .lesson(lesson)
                .moduleNumber(1)
                .completedAt(OffsetDateTime.now())
                .score(BigDecimal.valueOf(100.0))
                .starsEarned(3)
                .build());

        summaryRepository.findBySessionId(session.getSessionId()).orElseGet(() ->
                summaryRepository.save(SessionSummary.builder()
                        .sessionId(session.getSessionId())
                        .learner(learner)
                        .lesson(lesson)
                        .accuracyRate(BigDecimal.valueOf(100.0))
                        .totalWordsReviewed(5)
                        .correctPronunciations(5)
                        .incorrectPronunciations(0)
                        .totalAttempts(5)
                        .starsEarned(3)
                        .pointsEarned(100)
                        .demeritPoints(0)
                        .completedAt(OffsetDateTime.now())
                        .build())
        );

        // Ensure DifficultyProgress record
        difficultyProgressRepository.findByLearnerLearnerIdAndWordWordId(learnerId, wordId).orElseGet(() ->
                difficultyProgressRepository.save(DifficultyProgress.builder()
                        .learner(learner)
                        .word(word)
                        .currentLevel(DifficultyLevel.MASTERED)
                        .build())
        );
    }

    @Test
    void testGetLearnerProgress_includesMasteryLevel() throws Exception {
        MvcResult result = mockMvc.perform(get("/api/v1/learners/" + learnerId + "/progress")
                        .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.learnerId").value(learnerId.toString()))
                .andExpect(jsonPath("$.masteryLevel").exists())
                .andReturn();

        System.out.println("--- PAYLOAD: GET /api/v1/learners/{id}/progress ---");
        System.out.println(result.getResponse().getContentAsString());
    }

    @Test
    void testGetLessonProgress() throws Exception {
        MvcResult result = mockMvc.perform(get("/api/v1/learners/" + learnerId + "/progress/lessons")
                        .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$").isArray())
                .andReturn();

        System.out.println("--- PAYLOAD: GET /api/v1/learners/{id}/progress/lessons ---");
        System.out.println(result.getResponse().getContentAsString());
    }

    @Test
    void testGetCategoryProgress() throws Exception {
        MvcResult result = mockMvc.perform(get("/api/v1/learners/" + learnerId + "/progress/categories")
                        .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$").isArray())
                .andReturn();

        System.out.println("--- PAYLOAD: GET /api/v1/learners/{id}/progress/categories ---");
        System.out.println(result.getResponse().getContentAsString());
    }

    @Test
    void testGetRecentWordsProgress() throws Exception {
        MvcResult result = mockMvc.perform(get("/api/v1/learners/" + learnerId + "/progress/recent-words?limit=5")
                        .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$").isArray())
                .andReturn();

        System.out.println("--- PAYLOAD: GET /api/v1/learners/{id}/progress/recent-words ---");
        System.out.println(result.getResponse().getContentAsString());
    }
}
