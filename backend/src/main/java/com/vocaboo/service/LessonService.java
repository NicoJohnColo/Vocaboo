package com.vocaboo.service;

import com.vocaboo.dto.response.CategoryResponse;
import com.vocaboo.dto.response.CategoryReviewResponse;
import com.vocaboo.dto.response.LessonWordActivityResponse;
import com.vocaboo.dto.response.MatchingSetEntryResponse;
import com.vocaboo.dto.response.LessonResponse;
import com.vocaboo.dto.response.VocabularyWordResponse;
import com.vocaboo.dto.response.ConfusableWordPairResponse;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.vocaboo.entity.Learner;
import com.vocaboo.entity.LearnerLessonStatus;
import com.vocaboo.entity.Lesson;
import com.vocaboo.entity.LessonStatus;
import com.vocaboo.entity.VocabularyCategory;
import com.vocaboo.entity.VocabularyWord;
import com.vocaboo.entity.ConfusableWordPair;
import com.vocaboo.entity.VocabularyCategory;
import com.vocaboo.repository.LearnerLessonStatusRepository;
import com.vocaboo.repository.LearnerRepository;
import com.vocaboo.repository.LessonRepository;
import com.vocaboo.repository.VocabularyCategoryRepository;
import com.vocaboo.repository.VocabularyWordRepository;
import com.vocaboo.repository.ConfusableWordPairRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class LessonService {

    private final VocabularyCategoryRepository categoryRepository;
    private final LessonRepository lessonRepository;
    private final VocabularyWordRepository wordRepository;
    private final LearnerLessonStatusRepository lessonStatusRepository;
    private final LearnerRepository learnerRepository;
    private final ConfusableWordPairRepository confusableRepository;
        private final JdbcTemplate jdbcTemplate;
        private final ObjectMapper objectMapper;

    public List<CategoryResponse> getCategories() {
        return categoryRepository.findAllByOrderBySortOrderAsc().stream()
                .map(cat -> CategoryResponse.builder()
                        .categoryId(cat.getCategoryId())
                        .categoryName(cat.getCategoryName())
                        .description(cat.getDescription())
                        .sortOrder(cat.getSortOrder())
                        .build())
                .collect(Collectors.toList());
    }

    @Transactional
    public List<LessonResponse> getLessonsForCategory(UUID categoryId, UUID learnerId) {
        List<Lesson> lessons = lessonRepository.findByCategoryCategoryIdOrderByLessonOrderAsc(categoryId);
        List<LearnerLessonStatus> statuses = lessonStatusRepository.findByLearnerLearnerId(learnerId);

        Map<UUID, LearnerLessonStatus> statusMap = statuses.stream()
                .collect(Collectors.toMap(
                        status -> status.getLesson().getLessonId(),
                        status -> status
                ));

        List<LessonResponse> responses = new ArrayList<>();
        boolean previousCompleted = true; // First lesson is unlocked by default

        for (Lesson lesson : lessons) {
            LearnerLessonStatus statusObj = statusMap.get(lesson.getLessonId());
            LessonStatus status = LessonStatus.LOCKED;
            BigDecimal masteryScore = null;

            if (statusObj != null) {
                status = statusObj.getStatus();
                masteryScore = statusObj.getMasteryScore();
            } else {
                // If no row exists, determine if it should be UNLOCKED
                if (lesson.getLessonOrder() == 1 || previousCompleted) {
                    status = LessonStatus.UNLOCKED;
                    
                    Learner learner = learnerRepository.findById(learnerId)
                            .orElseThrow(() -> new IllegalArgumentException("Learner not found"));
                    
                    // Create the default unlocked status in DB
                    LearnerLessonStatus newStatus = LearnerLessonStatus.builder()
                            .learner(learner)
                            .lesson(lesson)
                            .status(LessonStatus.UNLOCKED)
                            .build();
                    lessonStatusRepository.save(newStatus);
                }
            }

            responses.add(LessonResponse.builder()
                    .lessonId(lesson.getLessonId())
                    .categoryId(lesson.getCategory().getCategoryId())
                    .lessonTitle(lesson.getLessonTitle())
                    .lessonDescription(lesson.getLessonDescription())
                    .gradeLevel(lesson.getGradeLevel())
                    .lessonOrder(lesson.getLessonOrder())
                    .totalWordCount(lesson.getTotalWordCount())
                    .status(status)
                    .masteryScore(masteryScore)
                    .build());

            // Track completion for subsequent lessons
            previousCompleted = (status == LessonStatus.COMPLETED);
        }

        return responses;
    }

    public List<VocabularyWordResponse> getVocabularyForLesson(UUID lessonId) {
        List<VocabularyWord> words = wordRepository.findByLessonLessonIdOrderByWordOrderAsc(lessonId);
        return words.stream()
                .map(this::mapToVocabularyWordResponse)
                .collect(Collectors.toList());
    }

        public List<LessonWordActivityResponse> getCategoryActivityForCategory(UUID categoryId) {
                List<Lesson> lessons = lessonRepository.findByCategoryCategoryIdOrderByLessonOrderAsc(categoryId);
                List<VocabularyWord> words = lessons.stream()
                                .flatMap(lesson -> wordRepository.findByLessonLessonIdOrderByWordOrderAsc(lesson.getLessonId()).stream())
                                .collect(Collectors.toList());

                List<LessonWordActivityResponse> responses = new ArrayList<>();
                for (VocabularyWord word : words) {
                        responses.add(mapToLessonWordActivityResponse(word, null));
                }
                return responses;
        }

        public List<LessonWordActivityResponse> getLessonActivityForLesson(UUID lessonId) {
                List<VocabularyWord> words = wordRepository.findByLessonLessonIdOrderByWordOrderAsc(lessonId);

                List<Map<String, Object>> activityRows = jdbcTemplate.queryForList("""
                                SELECT wa.word_id,
                                           wa.mc_distractor_1,
                                           wa.mc_distractor_2,
                                           wa.mc_distractor_3,
                                           wa.fitb_sentence,
                                           wa.fitb_answer,
                                           wa.matching_set,
                                           wa.sentence_arrangement_tokens,
                                           wa.sentence_completion_sentence,
                                           wa.sentence_completion_answer,
                                           wa.sentence_completion_option_1,
                                           wa.sentence_completion_option_2,
                                           wa.sentence_completion_option_3
                                FROM word_activity_data wa
                                INNER JOIN vocabulary_words vw ON vw.word_id = wa.word_id
                                WHERE vw.lesson_id = ?
                                ORDER BY vw.word_order ASC
                                """, lessonId);

                Map<UUID, Map<String, Object>> activityByWordId = new HashMap<>();
                for (Map<String, Object> row : activityRows) {
                        Object wordIdValue = row.get("word_id");
                        if (wordIdValue != null) {
                                activityByWordId.put(UUID.fromString(wordIdValue.toString()), row);
                        }
                }

                return words.stream()
                                .map(word -> mapToLessonWordActivityResponse(word, activityByWordId.get(word.getWordId())))
                                .collect(Collectors.toList());
        }

    public List<ConfusableWordPairResponse> getConfusablePairsForLesson(UUID lessonId) {
        List<ConfusableWordPair> pairs = confusableRepository.findByLessonLessonId(lessonId);
        return pairs.stream()
                .map(pair -> ConfusableWordPairResponse.builder()
                        .pairId(pair.getPairId())
                        .lessonId(pair.getLesson().getLessonId())
                        .wordA(mapToVocabularyWordResponse(pair.getWordA()))
                        .wordB(mapToVocabularyWordResponse(pair.getWordB()))
                        .contrastiveSentenceA(pair.getContrastiveSentenceA())
                        .contrastiveSentenceB(pair.getContrastiveSentenceB())
                        .build())
                .collect(Collectors.toList());
    }

    private VocabularyWordResponse mapToVocabularyWordResponse(VocabularyWord word) {
        return VocabularyWordResponse.builder()
                .wordId(word.getWordId())
                .lessonId(word.getLesson().getLessonId())
                .englishWord(word.getEnglishWord())
                .cebuanoMeaning(word.getCebuanoMeaning())
                .exampleSentenceEnglish(word.getExampleSentenceEnglish())
                .exampleSentenceCebuano(word.getExampleSentenceCebuano())
                .audioAssetPath(word.getAudioAssetPath())
                .partOfSpeech(word.getPartOfSpeech())
                .gradeLevel(word.getGradeLevel())
                .wordOrder(word.getWordOrder())
                .isConfusablePairMember(word.getIsConfusablePairMember())
                .phonologicalTipKey(word.getPhonologicalTipKey())
                .build();
    }

        private LessonWordActivityResponse mapToLessonWordActivityResponse(VocabularyWord word, Map<String, Object> activityRow) {
                return LessonWordActivityResponse.builder()
                                .wordId(word.getWordId())
                                .lessonId(word.getLesson().getLessonId())
                                .englishWord(word.getEnglishWord())
                                .cebuanoMeaning(word.getCebuanoMeaning())
                                .exampleSentenceEnglish(word.getExampleSentenceEnglish())
                                .exampleSentenceCebuano(word.getExampleSentenceCebuano())
                                .audioAssetPath(word.getAudioAssetPath())
                                .partOfSpeech(word.getPartOfSpeech())
                                .gradeLevel(word.getGradeLevel())
                                .wordOrder(word.getWordOrder())
                                .isConfusablePairMember(word.getIsConfusablePairMember())
                                .phonologicalTipKey(word.getPhonologicalTipKey())
                                .mcDistractor1(readString(activityRow, "mc_distractor_1"))
                                .mcDistractor2(readString(activityRow, "mc_distractor_2"))
                                .mcDistractor3(readString(activityRow, "mc_distractor_3"))
                                .fitbSentence(readString(activityRow, "fitb_sentence"))
                                .fitbAnswer(readString(activityRow, "fitb_answer"))
                                .matchingSet(readMatchingSet(activityRow, "matching_set"))
                                .sentenceArrangementTokens(readStringList(activityRow, "sentence_arrangement_tokens"))
                                .sentenceCompletionSentence(readString(activityRow, "sentence_completion_sentence"))
                                .sentenceCompletionAnswer(readString(activityRow, "sentence_completion_answer"))
                                .sentenceCompletionOption1(readString(activityRow, "sentence_completion_option_1"))
                                .sentenceCompletionOption2(readString(activityRow, "sentence_completion_option_2"))
                                .sentenceCompletionOption3(readString(activityRow, "sentence_completion_option_3"))
                                .build();
        }

        public CategoryReviewResponse completeCategoryReview(UUID learnerId, UUID categoryId, Double score) {
                List<Lesson> lessons = lessonRepository.findByCategoryCategoryIdOrderByLessonOrderAsc(categoryId);
                if (lessons.isEmpty()) {
                        throw new IllegalArgumentException("Category not found");
                }

                Learner learner = learnerRepository.findById(learnerId)
                                .orElseThrow(() -> new IllegalArgumentException("Learner not found"));

                boolean passed = score != null && score >= 70.0;
                for (Lesson lesson : lessons) {
                        LearnerLessonStatus status = lessonStatusRepository.findByLearnerLearnerIdAndLessonLessonId(learnerId, lesson.getLessonId())
                                        .orElseGet(() -> LearnerLessonStatus.builder()
                                                        .learner(learner)
                                                        .lesson(lesson)
                                                        .attempts(0)
                                                        .build());

                        status.setAttempts(status.getAttempts() + 1);
                        status.setMasteryScore(BigDecimal.valueOf(score != null ? score : 0.0));
                        status.setUpdatedAt(java.time.OffsetDateTime.now());
                        if (passed) {
                                status.setStatus(LessonStatus.COMPLETED);
                                status.setCompletedAt(java.time.OffsetDateTime.now());
                        } else if (status.getStatus() != LessonStatus.COMPLETED) {
                                status.setStatus(LessonStatus.UNLOCKED);
                        }
                        lessonStatusRepository.save(status);
                }

                UUID nextCategoryId = unlockNextCategory(categoryId, learnerId, learner);
                return CategoryReviewResponse.builder()
                                .categoryId(categoryId)
                                .score(score)
                                .passed(passed)
                                .nextCategoryId(nextCategoryId)
                                .build();
        }

        private UUID unlockNextCategory(UUID categoryId, UUID learnerId, Learner learner) {
                List<VocabularyCategory> categories = categoryRepository.findAllByOrderBySortOrderAsc();
                int currentIndex = -1;
                for (int i = 0; i < categories.size(); i++) {
                        if (categories.get(i).getCategoryId().equals(categoryId)) {
                                currentIndex = i;
                                break;
                        }
                }

                if (currentIndex == -1 || currentIndex + 1 >= categories.size()) {
                        return null;
                }

                VocabularyCategory nextCategory = categories.get(currentIndex + 1);
                List<Lesson> nextLessons = lessonRepository.findByCategoryCategoryIdOrderByLessonOrderAsc(nextCategory.getCategoryId());
                if (nextLessons.isEmpty()) {
                        return nextCategory.getCategoryId();
                }

                Lesson firstLesson = nextLessons.get(0);
                LearnerLessonStatus firstStatus = lessonStatusRepository.findByLearnerLearnerIdAndLessonLessonId(learnerId, firstLesson.getLessonId())
                                .orElseGet(() -> LearnerLessonStatus.builder()
                                                .learner(learner)
                                                .lesson(firstLesson)
                                                .attempts(0)
                                                .build());

                if (firstStatus.getStatus() == LessonStatus.LOCKED) {
                        firstStatus.setStatus(LessonStatus.UNLOCKED);
                        firstStatus.setUnlockedAt(java.time.OffsetDateTime.now());
                }
                lessonStatusRepository.save(firstStatus);
                return nextCategory.getCategoryId();
        }

        private String readString(Map<String, Object> row, String key) {
                if (row == null) {
                        return null;
                }
                Object value = row.get(key);
                return value == null ? null : value.toString();
        }

        private List<String> readStringList(Map<String, Object> row, String key) {
                String raw = readString(row, key);
                if (raw == null || raw.isBlank()) {
                        return List.of();
                }

                try {
                        JsonNode node = objectMapper.readTree(raw);
                        List<String> values = new ArrayList<>();
                        if (node.isArray()) {
                                for (JsonNode entry : node) {
                                        values.add(entry.asText());
                                }
                        }
                        return values;
                } catch (Exception ex) {
                        return List.of();
                }
        }

        private List<MatchingSetEntryResponse> readMatchingSet(Map<String, Object> row, String key) {
                String raw = readString(row, key);
                if (raw == null || raw.isBlank()) {
                        return List.of();
                }

                try {
                        JsonNode node = objectMapper.readTree(raw);
                        List<MatchingSetEntryResponse> values = new ArrayList<>();
                        if (node.isArray()) {
                                for (JsonNode entry : node) {
                                        values.add(MatchingSetEntryResponse.builder()
                                                        .englishWord(entry.path("english_word").asText(""))
                                                        .cebuanoMeaning(entry.path("cebuano_meaning").asText(""))
                                                        .build());
                                }
                        }
                        return values;
                } catch (Exception ex) {
                        return List.of();
                }
        }
}
