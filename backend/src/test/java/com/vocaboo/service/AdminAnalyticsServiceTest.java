package com.vocaboo.service;

import com.vocaboo.dto.response.AdminAnalyticsDashboardResponse;
import com.vocaboo.dto.response.AdminDemographicsResponse;
import com.vocaboo.dto.response.AdminLeaderboardStatsResponse;
import com.vocaboo.entity.*;
import com.vocaboo.repository.*;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.time.OffsetDateTime;
import java.util.*;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class AdminAnalyticsServiceTest {

    @Mock
    private LearnerRepository learnerRepository;
    @Mock
    private SectionRepository sectionRepository;
    @Mock
    private LearnerMasteryRepository masteryRepository;
    @Mock
    private LearnerLessonStatusRepository lessonStatusRepository;
    @Mock
    private LessonRepository lessonRepository;
    @Mock
    private WordPerformanceRepository wordPerformanceRepository;
    @Mock
    private VocabularyWordRepository vocabularyWordRepository;
    @Mock
    private PracticeSessionRepository practiceSessionRepository;
    @Mock
    private SessionSummaryRepository sessionSummaryRepository;
    @Mock
    private PointTransactionRepository pointTransactionRepository;
    @Mock
    private RewardDataRepository rewardDataRepository;
    @Mock
    private CumulativeReviewSessionRepository cumulativeReviewSessionRepository;

    private AdminAnalyticsService analyticsService;

    private Learner learner1;
    private Learner learner2;
    private Learner independentLearner;
    private Section section1;
    private LearnerMastery mastery1;
    private LearnerMastery mastery2;
    private LearnerMastery masteryIndep;
    private VocabularyWord word1;
    private VocabularyWord word2;
    private Lesson lesson1;

    @BeforeEach
    void setUp() {
        analyticsService = new AdminAnalyticsService(
                learnerRepository,
                sectionRepository,
                masteryRepository,
                lessonStatusRepository,
                lessonRepository,
                wordPerformanceRepository,
                vocabularyWordRepository,
                practiceSessionRepository,
                sessionSummaryRepository,
                pointTransactionRepository,
                rewardDataRepository,
                cumulativeReviewSessionRepository
        );

        section1 = Section.builder()
                .sectionId(UUID.randomUUID())
                .sectionName("Grade 3 - Rose")
                .build();

        learner1 = Learner.builder()
                .learnerId(UUID.randomUUID())
                .displayName("Maria")
                .gradeLevel(GradeLevel.GRADE_3_4)
                .languagePreference(LanguageMedium.CEBUANO_TO_ENGLISH)
                .section(section1)
                .isActive(true)
                .updatedAt(OffsetDateTime.now().minusDays(1))
                .build();

        learner2 = Learner.builder()
                .learnerId(UUID.randomUUID())
                .displayName("Juan")
                .gradeLevel(GradeLevel.GRADE_3_4)
                .languagePreference(LanguageMedium.CEBUANO_TO_ENGLISH)
                .section(section1)
                .isActive(true)
                .updatedAt(OffsetDateTime.now().minusDays(20))
                .build();

        independentLearner = Learner.builder()
                .learnerId(UUID.randomUUID())
                .displayName("SelfPacedAlex")
                .gradeLevel(GradeLevel.GRADE_5_6)
                .languagePreference(LanguageMedium.FULL_ENGLISH)
                .section(null) // Independent
                .isActive(true)
                .updatedAt(OffsetDateTime.now().minusDays(1))
                .build();

        mastery1 = LearnerMastery.builder()
                .masteryId(UUID.randomUUID())
                .learner(learner1)
                .totalPoints(1500)
                .overallAccuracy(BigDecimal.valueOf(85.50))
                .wordsMasteredCount(12)
                .totalQuestionsAnswered(50)
                .totalCorrectAnswers(43)
                .totalSessionsPlayed(10)
                .masteryLevel("MASTERED")
                .build();

        mastery2 = LearnerMastery.builder()
                .masteryId(UUID.randomUUID())
                .learner(learner2)
                .totalPoints(200)
                .overallAccuracy(BigDecimal.valueOf(55.00))
                .wordsMasteredCount(2)
                .totalQuestionsAnswered(30)
                .totalCorrectAnswers(16)
                .totalSessionsPlayed(4)
                .masteryLevel("LEARNING")
                .build();

        masteryIndep = LearnerMastery.builder()
                .masteryId(UUID.randomUUID())
                .learner(independentLearner)
                .totalPoints(2200)
                .overallAccuracy(BigDecimal.valueOf(92.00))
                .wordsMasteredCount(18)
                .totalQuestionsAnswered(80)
                .totalCorrectAnswers(74)
                .totalSessionsPlayed(15)
                .masteryLevel("MASTERED")
                .build();

        lesson1 = Lesson.builder()
                .lessonId(UUID.randomUUID())
                .lessonTitle("Animals")
                .gradeLevel(GradeLevel.GRADE_3_4)
                .build();

        word1 = VocabularyWord.builder()
                .wordId(UUID.randomUUID())
                .englishWord("Dog")
                .cebuanoMeaning("Iro")
                .lesson(lesson1)
                .build();

        word2 = VocabularyWord.builder()
                .wordId(UUID.randomUUID())
                .englishWord("Cat")
                .cebuanoMeaning("Iring")
                .lesson(lesson1)
                .build();
    }

    @Test
    void getDashboardAnalytics_calculatesKpisAndFlagsStrugglingLearners() {
        when(learnerRepository.findByIsActiveTrue()).thenReturn(List.of(learner1, learner2));
        when(masteryRepository.findByLearnerLearnerId(learner1.getLearnerId())).thenReturn(Optional.of(mastery1));
        when(masteryRepository.findByLearnerLearnerId(learner2.getLearnerId())).thenReturn(Optional.of(mastery2));

        LearnerLessonStatus status1 = LearnerLessonStatus.builder()
                .statusId(UUID.randomUUID())
                .learner(learner1)
                .lesson(lesson1)
                .status(LessonStatus.COMPLETED)
                .completedAt(OffsetDateTime.now().minusDays(1))
                .build();

        when(lessonStatusRepository.findByLearnerLearnerId(learner1.getLearnerId())).thenReturn(List.of(status1));
        when(lessonStatusRepository.findByLearnerLearnerId(learner2.getLearnerId())).thenReturn(List.of());

        WordPerformance wp1 = WordPerformance.builder()
                .performanceId(UUID.randomUUID())
                .learner(learner1)
                .word(word1)
                .totalAttempts(20)
                .correctCount(18)
                .incorrectCount(2)
                .demeritPoints(1)
                .tierDropCount(0)
                .fallbackCount(0)
                .accuracy(BigDecimal.valueOf(90.00))
                .lastPracticedAt(OffsetDateTime.now().minusDays(1))
                .build();

        WordPerformance wp2 = WordPerformance.builder()
                .performanceId(UUID.randomUUID())
                .learner(learner2)
                .word(word2)
                .totalAttempts(20)
                .correctCount(10)
                .incorrectCount(10)
                .demeritPoints(8)
                .tierDropCount(3)
                .fallbackCount(2)
                .accuracy(BigDecimal.valueOf(50.00))
                .lastPracticedAt(OffsetDateTime.now().minusDays(2))
                .build();

        when(wordPerformanceRepository.findByLearnerLearnerId(learner1.getLearnerId())).thenReturn(List.of(wp1));
        when(wordPerformanceRepository.findByLearnerLearnerId(learner2.getLearnerId())).thenReturn(List.of(wp2));

        when(vocabularyWordRepository.findAll()).thenReturn(List.of(word1, word2));
        when(lessonRepository.findAll()).thenReturn(List.of(lesson1));
        when(cumulativeReviewSessionRepository.findAll()).thenReturn(List.of());

        AdminAnalyticsDashboardResponse response = analyticsService.getDashboardAnalytics(null, null, "7d", "ALL");

        assertNotNull(response);
        assertNotNull(response.getKpis());
        assertEquals(2, response.getKpis().getTotalLearners());
        assertEquals(2, response.getKpis().getWeeklyActiveLearners());
        assertEquals(1, response.getKpis().getLessonsCompleted());
        assertEquals(14, response.getKpis().getTotalWordsMastered());

        // Check struggling learners
        assertFalse(response.getStrugglingLearners().isEmpty());
        assertEquals(learner2.getLearnerId(), response.getStrugglingLearners().get(0).getLearnerId());
        assertTrue(response.getStrugglingLearners().get(0).getDemeritPoints() >= 5);

        // Check curriculum analytics
        assertNotNull(response.getCurriculumAnalytics());
        assertFalse(response.getCurriculumAnalytics().getHardestWords().isEmpty());
        assertEquals(word2.getWordId(), response.getCurriculumAnalytics().getHardestWords().get(0).getWordId());

        assertFalse(response.getCurriculumAnalytics().getFallbackFrequency().isEmpty());
        assertEquals(2, response.getCurriculumAnalytics().getFallbackFrequency().get(0).getFallbackCount());
    }

    @Test
    void getGlobalDemographics_calculatesRatiosAndDistributions() {
        when(learnerRepository.countByIsActiveTrue()).thenReturn(3L);
        when(learnerRepository.countBySectionIsNullAndIsActiveTrue()).thenReturn(1L);
        when(learnerRepository.countBySectionIsNotNullAndIsActiveTrue()).thenReturn(2L);
        when(learnerRepository.findByIsActiveTrue()).thenReturn(List.of(learner1, learner2, independentLearner));
        when(masteryRepository.findAll()).thenReturn(List.of(mastery1, mastery2, masteryIndep));

        AdminDemographicsResponse demographics = analyticsService.getGlobalDemographics();

        assertNotNull(demographics);
        assertEquals(3L, demographics.getTotalLearners());
        assertEquals(1L, demographics.getIndependentLearnersCount());
        assertEquals(2L, demographics.getEnrolledLearnersCount());
        assertEquals(33.3, demographics.getIndependentPercentage(), 0.5);
        assertEquals(66.7, demographics.getEnrolledPercentage(), 0.5);

        assertNotNull(demographics.getLanguagePreferenceDistribution());
        assertEquals(2L, demographics.getLanguagePreferenceDistribution().get("CEBUANO_TO_ENGLISH"));
        assertEquals(1L, demographics.getLanguagePreferenceDistribution().get("FULL_ENGLISH"));
    }

    @Test
    void getLeaderboardStats_returnsRankingsAndGamificationKpis() {
        when(learnerRepository.findByIsActiveTrue()).thenReturn(List.of(learner1, learner2, independentLearner));
        when(masteryRepository.findAll()).thenReturn(List.of(mastery1, mastery2, masteryIndep));

        RewardData reward1 = RewardData.builder()
                .rewardId(UUID.randomUUID())
                .learner(learner1)
                .badgeType("GOLD")
                .build();
        RewardData reward2 = RewardData.builder()
                .rewardId(UUID.randomUUID())
                .learner(independentLearner)
                .badgeType("PERFECT_GOLD")
                .build();

        when(rewardDataRepository.findAll()).thenReturn(List.of(reward1, reward2));

        AdminLeaderboardStatsResponse stats = analyticsService.getLeaderboardStats("all_time", "ALL", null);

        assertNotNull(stats);
        assertEquals("all_time", stats.getRange());
        assertEquals(3, stats.getLeaderboard().size());

        // Top rank should be independentLearner with 2200 points
        assertEquals(1, stats.getLeaderboard().get(0).getRank());
        assertEquals(independentLearner.getLearnerId(), stats.getLeaderboard().get(0).getLearnerId());
        assertTrue(stats.getLeaderboard().get(0).isIndependent());
        assertEquals(2200, stats.getLeaderboard().get(0).getPoints());

        // Second rank should be learner1 with 1500 points
        assertEquals(2, stats.getLeaderboard().get(1).getRank());
        assertEquals(learner1.getLearnerId(), stats.getLeaderboard().get(1).getLearnerId());
        assertFalse(stats.getLeaderboard().get(1).isIndependent());
        assertEquals("Grade 3 - Rose", stats.getLeaderboard().get(1).getSectionName());

        // Gamification summary
        assertNotNull(stats.getGamificationSummary());
        assertEquals(3900L, stats.getGamificationSummary().getTotalPointsAwarded());
        assertEquals(29L, stats.getGamificationSummary().getTotalSessionsPlayed());
        assertEquals(2L, stats.getGamificationSummary().getTotalBadgesUnlocked());
    }
}
