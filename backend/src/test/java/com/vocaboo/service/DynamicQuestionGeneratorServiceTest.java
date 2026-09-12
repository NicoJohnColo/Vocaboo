package com.vocaboo.service;

import com.vocaboo.entity.*;
import com.vocaboo.repository.*;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.*;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class DynamicQuestionGeneratorServiceTest {

    @Mock
    private DifficultyAdjustmentService difficultyService;
    @Mock
    private VocabularyWordRepository wordRepository;
    @Mock
    private AdaptiveMetricRepository metricRepository;
    @Mock
    private WordPerformanceRepository wordPerformanceRepository;
    @Mock
    private LearnerRepository learnerRepository;
    @Mock
    private PracticeResultRepository practiceResultRepository;
    @Mock
    private DifficultyProgressRepository progressRepository;

    @InjectMocks
    private DynamicQuestionGeneratorService service;

    private UUID learnerId;
    private VocabularyWord word;
    private Learner learner;

    @BeforeEach
    void setUp() {
        learnerId = UUID.randomUUID();

        Lesson lesson = Lesson.builder()
                .lessonId(UUID.randomUUID())
                .lessonTitle("Animals")
                .build();

        word = VocabularyWord.builder()
                .wordId(UUID.randomUUID())
                .englishWord("butterfly")
                .cebuanoMeaning("alibangbang")
                .partOfSpeech("noun")
                .gradeLevel(GradeLevel.GRADE_4)
                .exampleSentenceEnglish("The butterfly has colorful wings.")
                .exampleSentenceCebuano("Ang alibangbang adunay mabulokong mga pako.")
                .hintDefinition("an insect with large, colorful wings")
                .hintCebuanoSentence("Usa ka insekto nga adunay mabulokong mga pako")
                .distractorPool("caterpillar;dragonfly;beetle;grasshopper;ant;bee")
                .lesson(lesson)
                .eligibleActivityTypes("MULTIPLE_CHOICE;FILL_IN_BLANK;MATCHING;SENTENCE_ARRANGEMENT;WORD_SCRAMBLE;IMAGE_LABELING;TRUE_OR_FALSE;HINT_TO_WORD")
                .build();

        learner = Learner.builder()
                .learnerId(learnerId)
                .displayName("testlearner")
                .languagePreference(LanguageMedium.CEBUANO_TO_ENGLISH)
                .build();

        when(learnerRepository.findById(learnerId)).thenReturn(Optional.of(learner));
    }

    @Test
    void testHintLanguage_CebuanoToEnglish() {
        learner.setLanguagePreference(LanguageMedium.CEBUANO_TO_ENGLISH);

        Map<String, Object> qLearning = service.generateQuestion(learnerId, word, "MULTIPLE_CHOICE", DifficultyLevel.LEARNING);
        assertEquals("CEBUANO", qLearning.get("hintLanguage"));
        assertTrue((Boolean) qLearning.get("showExplanations"));

        Map<String, Object> qFamiliar = service.generateQuestion(learnerId, word, "MULTIPLE_CHOICE", DifficultyLevel.FAMILIAR);
        assertEquals("ENGLISH", qFamiliar.get("hintLanguage"));
        assertTrue((Boolean) qFamiliar.get("showExplanations"));

        Map<String, Object> qProficient = service.generateQuestion(learnerId, word, "MULTIPLE_CHOICE", DifficultyLevel.PROFICIENT);
        assertEquals("NONE", qProficient.get("hintLanguage"));
        assertFalse((Boolean) qProficient.get("showExplanations"));
    }

    @Test
    void testHintLanguage_FullEnglish() {
        learner.setLanguagePreference(LanguageMedium.FULL_ENGLISH);

        Map<String, Object> qLearning = service.generateQuestion(learnerId, word, "MULTIPLE_CHOICE", DifficultyLevel.LEARNING);
        assertEquals("ENGLISH", qLearning.get("hintLanguage"));
        assertTrue((Boolean) qLearning.get("showExplanations"));

        Map<String, Object> qFamiliar = service.generateQuestion(learnerId, word, "MULTIPLE_CHOICE", DifficultyLevel.FAMILIAR);
        assertEquals("ENGLISH", qFamiliar.get("hintLanguage"));
        assertTrue((Boolean) qFamiliar.get("showExplanations"));

        Map<String, Object> qProficient = service.generateQuestion(learnerId, word, "MULTIPLE_CHOICE", DifficultyLevel.PROFICIENT);
        assertEquals("NONE", qProficient.get("hintLanguage"));
        assertFalse((Boolean) qProficient.get("showExplanations"));
    }

    @Test
    void testHintLanguage_CebuanoEnglishMixed() {
        learner.setLanguagePreference(LanguageMedium.CEBUANO_ENGLISH_MIXED);

        Map<String, Object> qLearning = service.generateQuestion(learnerId, word, "MULTIPLE_CHOICE", DifficultyLevel.LEARNING);
        assertEquals("CEBUANO_ENGLISH", qLearning.get("hintLanguage"));
        assertTrue((Boolean) qLearning.get("showExplanations"));

        Map<String, Object> qFamiliar = service.generateQuestion(learnerId, word, "MULTIPLE_CHOICE", DifficultyLevel.FAMILIAR);
        assertEquals("ENGLISH", qFamiliar.get("hintLanguage"));
        assertTrue((Boolean) qFamiliar.get("showExplanations"));

        Map<String, Object> qProficient = service.generateQuestion(learnerId, word, "MULTIPLE_CHOICE", DifficultyLevel.PROFICIENT);
        assertEquals("NONE", qProficient.get("hintLanguage"));
        assertFalse((Boolean) qProficient.get("showExplanations"));
    }

    @Test
    void testMultipleChoice_IntertwinedAtFamiliar() {
        when(wordRepository.findByLessonLessonIdOrderByWordOrderAsc(any())).thenReturn(Collections.emptyList());

        // LEARNING: prompt is Cebuano, correct answer is English
        Map<String, Object> qLearning = service.generateQuestion(learnerId, word, "MULTIPLE_CHOICE", DifficultyLevel.LEARNING);
        assertEquals("alibangbang", qLearning.get("displayWord"));
        assertEquals("butterfly", qLearning.get("correctAnswer"));
        assertEquals(false, qLearning.get("intertwinedTranslation"));

        // FAMILIAR: prompt is English, correct answer is Cebuano (Intertwined)
        Map<String, Object> qFamiliar = service.generateQuestion(learnerId, word, "MULTIPLE_CHOICE", DifficultyLevel.FAMILIAR);
        assertEquals("butterfly", qFamiliar.get("displayWord"));
        assertEquals("alibangbang", qFamiliar.get("correctAnswer"));
        assertEquals(true, qFamiliar.get("intertwinedTranslation"));
        List<?> familiarOptions = (List<?>) qFamiliar.get("options");
        assertTrue(familiarOptions.contains("alibangbang"));

        // PROFICIENT: prompt is Cebuano, correct answer is English, NO HINT
        Map<String, Object> qProficient = service.generateQuestion(learnerId, word, "MULTIPLE_CHOICE", DifficultyLevel.PROFICIENT);
        assertEquals("alibangbang", qProficient.get("displayWord"));
        assertEquals("butterfly", qProficient.get("correctAnswer"));
        assertEquals(false, qProficient.get("intertwinedTranslation"));
        assertEquals("NONE", qProficient.get("hintLanguage"));
    }

    @Test
    void testHintToWord_LearningTier() {
        Map<String, Object> q = service.generateQuestion(learnerId, word, "HINT_TO_WORD", DifficultyLevel.LEARNING);

        assertEquals("HINT_TO_WORD", q.get("activityType"));
        assertEquals("butterfly", q.get("correctAnswer"));
        assertEquals("CEBUANO_SENTENCE", q.get("hintToWordClueType"));
        assertEquals(word.getHintCebuanoSentence(), q.get("hintToWordClue"));
        assertEquals(true, q.get("autoPlayAudio"));
        assertEquals(3, ((List<?>) q.get("options")).size());
    }

    @Test
    void testHintToWord_FamiliarTier() {
        Map<String, Object> q = service.generateQuestion(learnerId, word, "HINT_TO_WORD", DifficultyLevel.FAMILIAR);

        assertEquals("HINT_TO_WORD", q.get("activityType"));
        assertEquals("butterfly", q.get("correctAnswer"));
        assertEquals("ENGLISH_DEFINITION", q.get("hintToWordClueType"));
        assertEquals("an insect with large, colorful wings", q.get("hintToWordClue"));
        assertEquals(false, q.get("autoPlayAudio"));
        assertEquals(4, ((List<?>) q.get("options")).size());
    }

    @Test
    void testHintToWord_ProficientTier() {
        Map<String, Object> q = service.generateQuestion(learnerId, word, "HINT_TO_WORD", DifficultyLevel.PROFICIENT);

        assertEquals("HINT_TO_WORD", q.get("activityType"));
        assertEquals("butterfly", q.get("correctAnswer"));
        assertEquals("ENGLISH_SYNONYM", q.get("hintToWordClueType"));
        assertEquals(15, q.get("timeLimitSeconds"));
        assertEquals(5, ((List<?>) q.get("options")).size());
    }

    @Test
    void testFillInBlank_SentenceContextTiers() {
        // LEARNING: full Cebuano sentence shown
        Map<String, Object> qLearning = service.generateQuestion(learnerId, word, "FILL_IN_BLANK", DifficultyLevel.LEARNING);
        assertNotNull(qLearning.get("fitbCebuanoContext"));
        assertEquals(word.getExampleSentenceCebuano(), qLearning.get("fitbCebuanoContext"));

        // FAMILIAR: first 3 words only
        Map<String, Object> qFamiliar = service.generateQuestion(learnerId, word, "FILL_IN_BLANK", DifficultyLevel.FAMILIAR);
        assertNotNull(qFamiliar.get("fitbCebuanoContext"));
        assertTrue(((String) qFamiliar.get("fitbCebuanoContext")).endsWith("..."));

        // PROFICIENT: no Cebuano context at all
        Map<String, Object> qProficient = service.generateQuestion(learnerId, word, "FILL_IN_BLANK", DifficultyLevel.PROFICIENT);
        assertNull(qProficient.get("fitbCebuanoContext"));
    }

    @Test
    void testTrueOrFalse_CebuanoVisibilityTiers() {
        // LEARNING & FAMILIAR: Cebuano shown
        Map<String, Object> qLearning = service.generateQuestion(learnerId, word, "TRUE_OR_FALSE", DifficultyLevel.LEARNING);
        assertTrue((Boolean) qLearning.get("tofShowCebuano"));
        assertNotNull(qLearning.get("tofCebuanoDisplay"));

        // PROFICIENT: No Cebuano shown
        Map<String, Object> qProficient = service.generateQuestion(learnerId, word, "TRUE_OR_FALSE", DifficultyLevel.PROFICIENT);
        assertFalse((Boolean) qProficient.get("tofShowCebuano"));
        assertNull(qProficient.get("tofCebuanoDisplay"));
    }

    @Test
    void testSentenceArrangement_AnchorAssistAtLearning() {
        // LEARNING: anchor word is set (first token pre-placed)
        Map<String, Object> qLearning = service.generateQuestion(learnerId, word, "SENTENCE_ARRANGEMENT", DifficultyLevel.LEARNING);
        assertNotNull(qLearning.get("anchoredWord"));

        // PROFICIENT: no anchor assist
        Map<String, Object> qProficient = service.generateQuestion(learnerId, word, "SENTENCE_ARRANGEMENT", DifficultyLevel.PROFICIENT);
        assertNull(qProficient.get("anchoredWord"));
    }

    @Test
    void testWordScramble_FirstLetterRevealGating() {
        // LEARNING: first letter always revealed
        Map<String, Object> qLearning = service.generateQuestion(learnerId, word, "WORD_SCRAMBLE", DifficultyLevel.LEARNING);
        assertEquals(true, qLearning.get("firstLetterRevealed"));

        // PROFICIENT: first letter never revealed
        Map<String, Object> qProficient = service.generateQuestion(learnerId, word, "WORD_SCRAMBLE", DifficultyLevel.PROFICIENT);
        assertEquals(false, qProficient.get("firstLetterRevealed"));
    }
}
