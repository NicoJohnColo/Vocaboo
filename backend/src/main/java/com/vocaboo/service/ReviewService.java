package com.vocaboo.service;

import com.vocaboo.entity.*;
import com.vocaboo.repository.*;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.RoundingMode;
import java.math.BigDecimal;
import java.time.OffsetDateTime;
import java.util.*;

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
    private final WordPerformanceRepository performanceRepository;
    private final IntroductionSessionRepository introductionSessionRepository;

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
        Optional<ReviewSession> sessionOpt = reviewSessionRepository.findById(sessionId);
        ReviewSession session;
        if (sessionOpt.isPresent()) {
            session = sessionOpt.get();
        } else {
            Optional<IntroductionSession> introOpt = introductionSessionRepository.findById(sessionId);
            if (introOpt.isPresent()) {
                IntroductionSession introSession = introOpt.get();
                UUID learnerId = introSession.getLearner().getLearnerId();
                UUID lessonId = introSession.getLesson().getLessonId();
                List<ReviewSession> reviewSessions = reviewSessionRepository.findByLearnerLearnerIdAndLessonLessonId(learnerId, lessonId);
                if (!reviewSessions.isEmpty()) {
                    session = reviewSessions.get(0);
                } else {
                    session = ReviewSession.builder()
                            .learner(introSession.getLearner())
                            .lesson(introSession.getLesson())
                            .createdAt(OffsetDateTime.now())
                            .updatedAt(OffsetDateTime.now())
                            .build();
                    session = reviewSessionRepository.save(session);
                }
            } else {
                throw new IllegalArgumentException("Session not found");
            }
        }
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

        BigDecimal bdScore = BigDecimal.valueOf(resolvedScore).setScale(2, RoundingMode.HALF_UP);
        moduleScore.setCorrectCount(safeCorrectCount);
        moduleScore.setTotalCount(safeTotalCount);
        moduleScore.setScore(bdScore);
        moduleScore.setStarsEarned(PracticeSessionService.calculateStars(bdScore));
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

        if (score >= 80.0) {
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

                boolean passed = score != null && score >= 80.0;

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

    @Transactional(readOnly = true)
    public List<Map<String, Object>> generateModule4ReviewPayload(UUID learnerId, UUID lessonId) {
        List<VocabularyWord> currentWords = wordRepository.findByLessonLessonIdAndIsDeletedFalseOrderByWordOrderAsc(lessonId);

        List<VocabularyWord> weakWords = performanceRepository.findWeakVocabularyWords(learnerId, java.math.BigDecimal.valueOf(80.0));
        List<VocabularyWord> refresherWords = new ArrayList<>();

        if (weakWords != null) {
            for (VocabularyWord w : weakWords) {
                if (w != null && w.getLesson() != null && !w.getLesson().getLessonId().equals(lessonId) && !w.getIsDeleted()) {
                    refresherWords.add(w);
                    if (refresherWords.size() >= 3) break;
                }
            }
        }

        if (refresherWords.size() < 2) {
            List<WordPerformance> allPerf = performanceRepository.findByLearnerLearnerId(learnerId);
            if (allPerf != null && !allPerf.isEmpty()) {
                List<WordPerformance> sortedPerf = new ArrayList<>(allPerf);
                sortedPerf.sort(Comparator.comparing(p -> p.getAccuracy() != null ? p.getAccuracy() : java.math.BigDecimal.ZERO));
                for (WordPerformance p : sortedPerf) {
                    VocabularyWord w = p.getWord();
                    if (w != null && w.getLesson() != null && !w.getLesson().getLessonId().equals(lessonId) && !Boolean.TRUE.equals(w.getIsDeleted())) {
                        if (!refresherWords.contains(w)) {
                            refresherWords.add(w);
                            if (refresherWords.size() >= 3) break;
                        }
                    }
                }
            }
        }

        // If learner has NO performance history at all (e.g. brand new learner), pull 2-3 words from other published lessons
        if (refresherWords.size() < 2) {
            List<VocabularyWord> otherWords = wordRepository.findAll();
            for (VocabularyWord w : otherWords) {
                if (w != null && w.getLesson() != null && !w.getLesson().getLessonId().equals(lessonId) && !Boolean.TRUE.equals(w.getIsDeleted())) {
                    if (!refresherWords.contains(w)) {
                        refresherWords.add(w);
                        if (refresherWords.size() >= 3) break;
                    }
                }
            }
        }

        List<VocabularyWord> allReviewWords = new ArrayList<>(currentWords);
        allReviewWords.addAll(refresherWords);

        List<String> formats = List.of("MULTIPLE_CHOICE", "FILL_IN_BLANK", "MATCHING", "SENTENCE_RECONSTRUCTION");
        List<String> bag = new ArrayList<>();
        Random random = new Random();

        List<Map<String, Object>> result = new ArrayList<>();

        for (VocabularyWord word : allReviewWords) {
            if (bag.isEmpty()) {
                bag.addAll(formats);
                Collections.shuffle(bag, random);
            }
            String selectedFormat = bag.remove(0);
            boolean isRefresher = !word.getLesson().getLessonId().equals(lessonId);

            Map<String, Object> map = new HashMap<>();
            map.put("wordId", word.getWordId().toString());
            map.put("word", word.getEnglishWord());
            map.put("englishWord", word.getEnglishWord());
            map.put("definition", word.getCebuanoMeaning());
            map.put("cebuanoMeaning", word.getCebuanoMeaning());
            map.put("example", word.getExampleSentenceEnglish());
            map.put("exampleSentenceEnglish", word.getExampleSentenceEnglish());
            map.put("exampleCebuano", word.getExampleSentenceCebuano());
            map.put("imageAssetPath", word.getImageAssetPath());
            map.put("activityFormat", selectedFormat);
            map.put("isRefresher", isRefresher);

            result.add(map);
        }

        return result;
    }
}
