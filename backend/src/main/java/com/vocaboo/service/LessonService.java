package com.vocaboo.service;

import com.vocaboo.dto.response.CategoryResponse;
import com.vocaboo.dto.response.LessonResponse;
import com.vocaboo.dto.response.VocabularyWordResponse;
import com.vocaboo.entity.Learner;
import com.vocaboo.entity.LearnerLessonStatus;
import com.vocaboo.entity.Lesson;
import com.vocaboo.entity.LessonStatus;
import com.vocaboo.entity.VocabularyCategory;
import com.vocaboo.entity.VocabularyWord;
import com.vocaboo.repository.LearnerLessonStatusRepository;
import com.vocaboo.repository.LearnerRepository;
import com.vocaboo.repository.LessonRepository;
import com.vocaboo.repository.VocabularyCategoryRepository;
import com.vocaboo.repository.VocabularyWordRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.math.BigDecimal;
import java.util.ArrayList;
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
                .map(word -> VocabularyWordResponse.builder()
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
                        .build())
                .collect(Collectors.toList());
    }
}
