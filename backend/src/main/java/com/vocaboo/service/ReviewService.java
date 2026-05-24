package com.vocaboo.service;

import com.vocaboo.entity.*;
import com.vocaboo.repository.*;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.RoundingMode;
import java.math.BigDecimal;
import java.time.OffsetDateTime;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import com.vocaboo.dto.response.CategoryReviewResponse;

@Service
@RequiredArgsConstructor
public class ReviewService {

    private final ReviewSessionRepository reviewSessionRepository;
    private final ReviewItemRepository reviewItemRepository;
        private final LessonModuleScoreRepository lessonModuleScoreRepository;
    private final LearnerLessonStatusRepository lessonStatusRepository;
    private final LessonRepository lessonRepository;
        private final VocabularyCategoryRepository categoryRepository;
    private final LearnerRepository learnerRepository;
    private final VocabularyWordRepository wordRepository;

    @Transactional
    public ReviewSession startReview(UUID learnerId, UUID lessonId) {
        Learner learner = learnerRepository.findById(learnerId)
                .orElseThrow(() -> new IllegalArgumentException("Learner not found"));
        Lesson lesson = lessonRepository.findById(lessonId)
                .orElseThrow(() -> new IllegalArgumentException("Lesson not found"));

        ReviewSession session = ReviewSession.builder()
                .learner(learner)
                .lesson(lesson)
                .createdAt(OffsetDateTime.now())
                .updatedAt(OffsetDateTime.now())
                .build();

        return reviewSessionRepository.save(session);
    }

    @Transactional
    public ReviewItem saveReviewItem(UUID sessionId, UUID wordId, Boolean isCorrect) {
        ReviewSession session = reviewSessionRepository.findById(sessionId)
                .orElseThrow(() -> new IllegalArgumentException("Review session not found"));
        VocabularyWord word = wordRepository.findById(wordId)
                .orElseThrow(() -> new IllegalArgumentException("Word not found"));

        ReviewItem item = ReviewItem.builder()
                .session(session)
                .word(word)
                .isCorrect(isCorrect)
                .createdAt(OffsetDateTime.now())
                .build();

        return reviewItemRepository.save(item);
    }

    @Transactional
    public void saveModuleScore(UUID learnerId, UUID lessonId, Integer moduleNumber, Integer correctCount, Integer totalCount, Double score) {
        Learner learner = learnerRepository.findById(learnerId)
                .orElseThrow(() -> new IllegalArgumentException("Learner not found"));
        Lesson lesson = lessonRepository.findById(lessonId)
                .orElseThrow(() -> new IllegalArgumentException("Lesson not found"));

        int safeCorrectCount = correctCount != null ? correctCount : 0;
        int safeTotalCount = totalCount != null ? totalCount : 0;
        double resolvedScore = score != null
                ? score
                : (safeTotalCount > 0 ? ((double) safeCorrectCount / safeTotalCount) * 100.0 : 0.0);

        LessonModuleScore moduleScore = lessonModuleScoreRepository
                .findByLearnerLearnerIdAndLessonLessonIdAndModuleNumber(learnerId, lessonId, moduleNumber)
                .orElseGet(() -> LessonModuleScore.builder()
                        .learner(learner)
                        .lesson(lesson)
                        .moduleNumber(moduleNumber)
                        .build());

        moduleScore.setCorrectCount(safeCorrectCount);
        moduleScore.setTotalCount(safeTotalCount);
        moduleScore.setScore(BigDecimal.valueOf(resolvedScore).setScale(2, RoundingMode.HALF_UP));
        lessonModuleScoreRepository.save(moduleScore);
    }

    @Transactional
    public LearnerLessonStatus completeReview(UUID learnerId, UUID lessonId, UUID sessionId, Double score) {
        ReviewSession session = reviewSessionRepository.findById(sessionId)
                .orElseThrow(() -> new IllegalArgumentException("Review session not found"));
        Learner learner = learnerRepository.findById(learnerId)
                .orElseThrow(() -> new IllegalArgumentException("Learner not found"));
        Lesson lesson = lessonRepository.findById(lessonId)
                .orElseThrow(() -> new IllegalArgumentException("Lesson not found"));

        // Update ReviewSession
        session.setMasteryScore(score);
        session.setCompletedAt(OffsetDateTime.now());
        session.setUpdatedAt(OffsetDateTime.now());
        reviewSessionRepository.save(session);

        // Retrieve or create lesson status
        LearnerLessonStatus status = lessonStatusRepository
                .findByLearnerLearnerIdAndLessonLessonId(learnerId, lessonId)
                .orElseGet(() -> LearnerLessonStatus.builder()
                        .learner(learner)
                        .lesson(lesson)
                        .attempts(0)
                        .build());

        status.setAttempts(status.getAttempts() + 1);
        status.setMasteryScore(BigDecimal.valueOf(score));
        status.setUpdatedAt(OffsetDateTime.now());

        if (score >= 70.0) {
            status.setStatus(LessonStatus.COMPLETED);
            status.setCompletedAt(OffsetDateTime.now());

            // Unlock next lesson in the category
            Optional<Lesson> nextLessonOpt = lessonRepository.findByCategoryCategoryIdAndLessonOrder(
                    lesson.getCategory().getCategoryId(),
                    lesson.getLessonOrder() + 1
            );

            if (nextLessonOpt.isPresent()) {
                Lesson nextLesson = nextLessonOpt.get();
                LearnerLessonStatus nextStatus = lessonStatusRepository
                        .findByLearnerLearnerIdAndLessonLessonId(learnerId, nextLesson.getLessonId())
                        .orElseGet(() -> LearnerLessonStatus.builder()
                                .learner(learner)
                                .lesson(nextLesson)
                                .attempts(0)
                                .build());

                if (nextStatus.getStatus() == LessonStatus.LOCKED) {
                    nextStatus.setStatus(LessonStatus.UNLOCKED);
                    nextStatus.setUnlockedAt(OffsetDateTime.now());
                    nextStatus.setUpdatedAt(OffsetDateTime.now());
                    lessonStatusRepository.save(nextStatus);
                }
            }
        } else {
            // Keep status as UNLOCKED if they haven't passed yet
            if (status.getStatus() != LessonStatus.COMPLETED) {
                status.setStatus(LessonStatus.UNLOCKED);
            }
        }

        return lessonStatusRepository.save(status);
    }

        @Transactional
        public CategoryReviewResponse completeCategoryReview(UUID learnerId, UUID categoryId, UUID sessionId, Double score) {
                List<Lesson> lessons = lessonRepository.findByCategoryCategoryIdOrderByLessonOrderAsc(categoryId);
                if (lessons.isEmpty()) {
                        throw new IllegalArgumentException("Category not found");
                }

                Learner learner = learnerRepository.findById(learnerId)
                                .orElseThrow(() -> new IllegalArgumentException("Learner not found"));

                boolean passed = score != null && score >= 70.0;

                for (Lesson lesson : lessons) {
                        LearnerLessonStatus status = lessonStatusRepository
                                        .findByLearnerLearnerIdAndLessonLessonId(learnerId, lesson.getLessonId())
                                        .orElseGet(() -> LearnerLessonStatus.builder()
                                                        .learner(learner)
                                                        .lesson(lesson)
                                                        .attempts(0)
                                                        .build());

                        status.setAttempts(status.getAttempts() + 1);
                        status.setMasteryScore(BigDecimal.valueOf(score != null ? score : 0.0));
                        status.setUpdatedAt(OffsetDateTime.now());

                        if (passed) {
                                status.setStatus(LessonStatus.COMPLETED);
                                status.setCompletedAt(OffsetDateTime.now());
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
                if (categories.isEmpty()) {
                        return null;
                }

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
                LearnerLessonStatus firstStatus = lessonStatusRepository
                                .findByLearnerLearnerIdAndLessonLessonId(learnerId, firstLesson.getLessonId())
                                .orElseGet(() -> LearnerLessonStatus.builder()
                                                .learner(learner)
                                                .lesson(firstLesson)
                                                .attempts(0)
                                                .build());

                if (firstStatus.getStatus() == LessonStatus.LOCKED) {
                        firstStatus.setStatus(LessonStatus.UNLOCKED);
                        firstStatus.setUnlockedAt(OffsetDateTime.now());
                }
                lessonStatusRepository.save(firstStatus);
                return nextCategory.getCategoryId();
        }
}
