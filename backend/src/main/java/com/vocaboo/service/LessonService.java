package com.vocaboo.service;

import com.vocaboo.dto.request.MasteryRequest;
import com.vocaboo.dto.response.CategoryResponse;
import com.vocaboo.dto.response.LessonWordActivityResponse;
import com.vocaboo.dto.response.MatchingSetEntryResponse;
import com.vocaboo.dto.response.LessonResponse;
import com.vocaboo.dto.response.MasteryResponse;
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
import java.util.Set;
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
        List<Lesson> lessons = lessonRepository.findByCategoryCategoryIdAndContentStatusAndIsDeletedFalseOrderByLessonOrderAsc(categoryId, "PUBLISHED");
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
                if (status == LessonStatus.LOCKED && (lesson.getLessonOrder() == 1 || previousCompleted)) {
                    status = LessonStatus.UNLOCKED;
                    statusObj.setStatus(LessonStatus.UNLOCKED);
                    statusObj.setUnlockedAt(java.time.OffsetDateTime.now());
                    lessonStatusRepository.save(statusObj);
                }
            } else {
                if (lesson.getLessonOrder() == 1 || previousCompleted) {
                    status = LessonStatus.UNLOCKED;
                    
                    Learner learner = learnerRepository.findById(learnerId)
                            .orElseThrow(() -> new IllegalArgumentException("Learner not found"));
                    
                    LearnerLessonStatus newStatus = LearnerLessonStatus.builder()
                            .learner(learner)
                            .lesson(lesson)
                            .status(LessonStatus.UNLOCKED)
                            .unlockedAt(java.time.OffsetDateTime.now())
                            .build();
                    lessonStatusRepository.save(newStatus);
                }
            }

            int actualWordCount = (int) wordRepository.countByLessonLessonIdAndIsDeletedFalse(lesson.getLessonId());

            responses.add(LessonResponse.builder()
                    .lessonId(lesson.getLessonId())
                    .categoryId(lesson.getCategory().getCategoryId())
                    .lessonTitle(lesson.getLessonTitle())
                    .lessonDescription(lesson.getLessonDescription())
                    .gradeLevel(lesson.getGradeLevel())
                    .lessonOrder(lesson.getLessonOrder())
                    .totalWordCount(actualWordCount > 0 ? actualWordCount : (lesson.getTotalWordCount() != null ? lesson.getTotalWordCount() : 0))
                    .status(status)
                    .masteryScore(masteryScore)
                    .lessonType(lesson.getLessonType() != null ? lesson.getLessonType().name() : "REGULAR")
                    .sourceLessonIds(lesson.getSourceLessonIds())
                    .compositeReviewAfterLessonId(lesson.getCompositeReviewAfterLessonId())
                    .contextParagraph(lesson.getContextParagraph())
                    .build());

            previousCompleted = (status == LessonStatus.COMPLETED);
        }

        return responses;
    }

    public List<VocabularyWordResponse> getVocabularyForLesson(UUID lessonId, String partOfSpeech) {
        return wordRepository.findByLessonLessonIdAndIsDeletedFalseOrderByWordOrderAsc(lessonId).stream()
                .filter(word -> partOfSpeech == null || partOfSpeech.equalsIgnoreCase(word.getPartOfSpeech()))
                .map(word -> VocabularyWordResponse.builder()
                        .wordId(word.getWordId())
                        .englishWord(word.getEnglishWord())
                        .cebuanoMeaning(word.getCebuanoMeaning())
                        .partOfSpeech(word.getPartOfSpeech())
                        .imageAssetPath(word.getImageAssetPath())
                        .audioAssetPath(word.getAudioAssetPath())
                        .exampleSentenceEnglish(word.getExampleSentenceEnglish())
                        .exampleSentenceCebuano(word.getExampleSentenceCebuano())
                        .phonologicalTipKey(word.getPhonologicalTipKey())
                        .distractorPool(word.getDistractorPool())
                        .fillBlankSentence(word.getFillBlankSentence())
                        .tileSentence(word.getTileSentence())
                        .hintText(word.getHintText())
                        .audioTextCebuano(word.getAudioTextCebuano())
                        .audioTextEnglish(word.getAudioTextEnglish())
                        .build())
                .collect(Collectors.toList());
    }

    public List<LessonWordActivityResponse> getCategoryActivityForCategory(UUID categoryId) {
        String sql = """
            SELECT
                vw.word_id,
                vw.english_word,
                vw.cebuano_meaning,
                vw.part_of_speech,
                vw.image_asset_path,
                vw.audio_asset_path,
                vw.example_sentence_english,
                vw.example_sentence_cebuano,
                vw.phonological_tip_key,
                wfa.sentence_completion_sentence,
                wfa.sentence_completion_answer,
                wfa.sentence_completion_option1,
                wfa.sentence_completion_option2,
                wfa.sentence_completion_option3,
                wfa.sentence_arrangement_tokens,
                wfa.matching_set,
                l.lesson_id,
                vw.word_order
            FROM vocabulary_words vw
            JOIN lessons l ON l.lesson_id = vw.lesson_id
            LEFT JOIN word_format_activities wfa ON wfa.word_id = vw.word_id
            WHERE l.category_id = ?
              AND l.content_status = 'PUBLISHED'
              AND l.is_deleted = false
              AND vw.is_deleted = false
            ORDER BY l.lesson_order ASC, vw.word_order ASC
            """;

        List<Map<String, Object>> rows = jdbcTemplate.queryForList(sql, categoryId);
        List<LessonWordActivityResponse> responses = new ArrayList<>();

        for (Map<String, Object> row : rows) {
            responses.add(LessonWordActivityResponse.builder()
                    .wordId((UUID) row.get("word_id"))
                    .lessonId((UUID) row.get("lesson_id"))
                    .englishWord(readString(row, "english_word"))
                    .cebuanoMeaning(readString(row, "cebuano_meaning"))
                    .partOfSpeech(readString(row, "part_of_speech"))
                    .imageAssetPath(readString(row, "image_asset_path"))
                    .audioAssetPath(readString(row, "audio_asset_path"))
                    .exampleSentenceEnglish(readString(row, "example_sentence_english"))
                    .exampleSentenceCebuano(readString(row, "example_sentence_cebuano"))
                    .phonologicalTipKey(readString(row, "phonological_tip_key"))
                    .sentenceCompletionSentence(readString(row, "sentence_completion_sentence"))
                    .sentenceCompletionAnswer(readString(row, "sentence_completion_answer"))
                    .sentenceCompletionOption1(readString(row, "sentence_completion_option1"))
                    .sentenceCompletionOption2(readString(row, "sentence_completion_option2"))
                    .sentenceCompletionOption3(readString(row, "sentence_completion_option3"))
                    .sentenceArrangementTokens(readStringList(row, "sentence_arrangement_tokens"))
                    .matchingSet(readMatchingSet(row, "matching_set"))
                    .build());
        }

        return responses;
    }

    public List<LessonWordActivityResponse> getLessonActivityForLesson(UUID lessonId, String partOfSpeech) {
        String sql = """
            SELECT
                vw.word_id,
                vw.english_word,
                vw.cebuano_meaning,
                vw.part_of_speech,
                vw.image_asset_path,
                vw.audio_asset_path,
                vw.example_sentence_english,
                vw.example_sentence_cebuano,
                vw.phonological_tip_key,
                wfa.sentence_completion_sentence,
                wfa.sentence_completion_answer,
                wfa.sentence_completion_option1,
                wfa.sentence_completion_option2,
                wfa.sentence_completion_option3,
                wfa.sentence_arrangement_tokens,
                wfa.matching_set,
                l.lesson_id,
                vw.word_order
            FROM vocabulary_words vw
            JOIN lessons l ON l.lesson_id = vw.lesson_id
            LEFT JOIN word_format_activities wfa ON wfa.word_id = vw.word_id
            WHERE l.lesson_id = ?
              AND l.content_status = 'PUBLISHED'
              AND l.is_deleted = false
              AND vw.is_deleted = false
            ORDER BY vw.word_order ASC
            """;

        List<Map<String, Object>> rows = jdbcTemplate.queryForList(sql, lessonId);
        List<LessonWordActivityResponse> responses = new ArrayList<>();

        for (Map<String, Object> row : rows) {
            String pos = readString(row, "part_of_speech");
            if (partOfSpeech != null && !partOfSpeech.equalsIgnoreCase(pos)) {
                continue;
            }

            responses.add(LessonWordActivityResponse.builder()
                    .wordId((UUID) row.get("word_id"))
                    .lessonId((UUID) row.get("lesson_id"))
                    .englishWord(readString(row, "english_word"))
                    .cebuanoMeaning(readString(row, "cebuano_meaning"))
                    .partOfSpeech(readString(row, "part_of_speech"))
                    .imageAssetPath(readString(row, "image_asset_path"))
                    .audioAssetPath(readString(row, "audio_asset_path"))
                    .exampleSentenceEnglish(readString(row, "example_sentence_english"))
                    .exampleSentenceCebuano(readString(row, "example_sentence_cebuano"))
                    .phonologicalTipKey(readString(row, "phonological_tip_key"))
                    .sentenceCompletionSentence(readString(row, "sentence_completion_sentence"))
                    .sentenceCompletionAnswer(readString(row, "sentence_completion_answer"))
                    .sentenceCompletionOption1(readString(row, "sentence_completion_option1"))
                    .sentenceCompletionOption2(readString(row, "sentence_completion_option2"))
                    .sentenceCompletionOption3(readString(row, "sentence_completion_option3"))
                    .sentenceArrangementTokens(readStringList(row, "sentence_arrangement_tokens"))
                    .matchingSet(readMatchingSet(row, "matching_set"))
                    .build());
        }

        return responses;
    }

    public List<ConfusableWordPairResponse> getConfusablePairsForLesson(UUID lessonId) {
        List<ConfusableWordPair> pairs = confusableRepository.findByLessonLessonId(lessonId);
        return pairs.stream()
                .map(pair -> ConfusableWordPairResponse.builder()
                        .pairId(pair.getPairId())
                        .lessonId(pair.getLesson().getLessonId())
                        .wordA(VocabularyWordResponse.builder()
                                .wordId(pair.getWordA().getWordId())
                                .englishWord(pair.getWordA().getEnglishWord())
                                .cebuanoMeaning(pair.getWordA().getCebuanoMeaning())
                                .partOfSpeech(pair.getWordA().getPartOfSpeech())
                                .imageAssetPath(pair.getWordA().getImageAssetPath())
                                .audioAssetPath(pair.getWordA().getAudioAssetPath())
                                .exampleSentenceEnglish(pair.getWordA().getExampleSentenceEnglish())
                                .exampleSentenceCebuano(pair.getWordA().getExampleSentenceCebuano())
                                .phonologicalTipKey(pair.getWordA().getPhonologicalTipKey())
                                .build())
                        .wordB(VocabularyWordResponse.builder()
                                .wordId(pair.getWordB().getWordId())
                                .englishWord(pair.getWordB().getEnglishWord())
                                .cebuanoMeaning(pair.getWordB().getCebuanoMeaning())
                                .partOfSpeech(pair.getWordB().getPartOfSpeech())
                                .imageAssetPath(pair.getWordB().getImageAssetPath())
                                .audioAssetPath(pair.getWordB().getAudioAssetPath())
                                .exampleSentenceEnglish(pair.getWordB().getExampleSentenceEnglish())
                                .exampleSentenceCebuano(pair.getWordB().getExampleSentenceCebuano())
                                .phonologicalTipKey(pair.getWordB().getPhonologicalTipKey())
                                .build())
                        .contrastiveSentenceA(pair.getContrastiveSentenceA())
                        .contrastiveSentenceB(pair.getContrastiveSentenceB())
                        .build())
                .collect(Collectors.toList());
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
                            .imageAssetPath(entry.path("image_asset_path").asText(""))
                            .build());
                }
            }
            return values;
        } catch (Exception ex) {
            return List.of();
        }
    }

    @Transactional
    public MasteryResponse submitMastery(MasteryRequest request, UUID learnerId) {
        final double PASSING_THRESHOLD = 70.0;
        
        if (request.getCumulativeReviewScore() == null || request.getCumulativeReviewScore() < 0) {
            return MasteryResponse.builder()
                    .success(false)
                    .message("Cumulative review must be completed before category can be passed")
                    .finalScore(0.0)
                    .passed(false)
                    .totalItems(request.getTotalItems())
                    .masteredCount(request.getMasteredCount())
                    .missedWordIds(request.getMissedWordIds())
                    .build();
        }
        
        double serverFinalScore = (0.6 * request.getLessonScore()) + (0.4 * request.getCumulativeReviewScore());
        boolean serverPassed = serverFinalScore >= PASSING_THRESHOLD;
        
        if (request.isPassed() && !serverPassed) {
            return MasteryResponse.builder()
                    .success(false)
                    .message("Score validation failed: Server calculated score does not meet passing threshold")
                    .finalScore(serverFinalScore)
                    .passed(false)
                    .totalItems(request.getTotalItems())
                    .masteredCount(request.getMasteredCount())
                    .missedWordIds(request.getMissedWordIds())
                    .build();
        }
        
        if (serverPassed && request.getLessonIds() != null) {
            Learner learner = learnerRepository.findById(learnerId)
                    .orElseThrow(() -> new IllegalArgumentException("Learner not found"));
            
            for (UUID lessonId : request.getLessonIds()) {
                Lesson lesson = lessonRepository.findById(lessonId)
                        .orElseThrow(() -> new IllegalArgumentException("Lesson not found: " + lessonId));
                
                LearnerLessonStatus status = lessonStatusRepository
                        .findByLearnerLearnerIdAndLessonLessonId(learnerId, lessonId)
                        .orElseGet(() -> LearnerLessonStatus.builder()
                                .learner(learner)
                                .lesson(lesson)
                                .attempts(0)
                                .build());
                
                status.setAttempts(status.getAttempts() + 1);
                status.setMasteryScore(BigDecimal.valueOf(serverFinalScore));
                status.setStatus(LessonStatus.COMPLETED);
                status.setCompletedAt(java.time.OffsetDateTime.now());
                status.setUpdatedAt(java.time.OffsetDateTime.now());
                lessonStatusRepository.save(status);
                unlockNextLesson(lesson, learner);
            }
        }
        
        return MasteryResponse.builder()
                .success(true)
                .message(serverPassed ? "Mastery achieved" : "Review needed")
                .finalScore(serverFinalScore)
                .passed(serverPassed)
                .totalItems(request.getTotalItems())
                .masteredCount(request.getMasteredCount())
                .missedWordIds(request.getMissedWordIds())
                .build();
    }

    private void unlockNextLesson(Lesson completedLesson, Learner learner) {
        List<Lesson> lessons = lessonRepository.findByCategoryCategoryIdOrderByLessonOrderAsc(completedLesson.getCategory().getCategoryId());
        int nextOrder = completedLesson.getLessonOrder() + 1;
        lessons.stream()
                .filter(l -> l.getLessonOrder() == nextOrder)
                .findFirst()
                .ifPresent(nextLesson -> {
                    LearnerLessonStatus nextStatus = lessonStatusRepository
                            .findByLearnerLearnerIdAndLessonLessonId(learner.getLearnerId(), nextLesson.getLessonId())
                            .orElseGet(() -> LearnerLessonStatus.builder()
                                    .learner(learner)
                                    .lesson(nextLesson)
                                    .status(LessonStatus.LOCKED)
                                    .attempts(0)
                                    .build());

                    if (nextStatus.getStatus() == LessonStatus.LOCKED) {
                        nextStatus.setStatus(LessonStatus.UNLOCKED);
                        nextStatus.setUnlockedAt(java.time.OffsetDateTime.now());
                        lessonStatusRepository.save(nextStatus);
                    }
                });
    }
}
