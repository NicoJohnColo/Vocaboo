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
import java.util.stream.Collectors;

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
    private final PracticeSessionRepository practiceSessionRepository;
    private final CumulativeReviewSessionRepository cumulativeReviewSessionRepository;

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
        ReviewItem savedItem = reviewItemRepository.save(item);

        final Learner targetLearner = session != null ? session.getLearner() : null;

        if (targetLearner != null) {
            WordPerformance perf = performanceRepository
                    .findByLearnerLearnerIdAndWordWordId(targetLearner.getLearnerId(), word.getWordId())
                    .orElseGet(() -> WordPerformance.builder()
                            .learner(targetLearner)
                            .word(word)
                            .build());

            perf.setTotalAttempts(perf.getTotalAttempts() + 1);
            if (Boolean.TRUE.equals(isCorrect)) {
                perf.setCorrectCount(perf.getCorrectCount() + 1);
            } else {
                perf.setIncorrectCount(perf.getIncorrectCount() + 1);
            }
            double wordAcc = (double) perf.getCorrectCount() / perf.getTotalAttempts() * 100.0;
            perf.setAccuracy(BigDecimal.valueOf(wordAcc).setScale(2, RoundingMode.HALF_UP));
            perf.setLastPracticedAt(OffsetDateTime.now());
            performanceRepository.save(perf);
        }

        return savedItem;
    }

    @Transactional
    public void saveModuleScore(UUID learnerId, UUID lessonId, Integer moduleNumber, Integer correctCount, Integer totalCount, Double score) {
        saveModuleScore(learnerId, lessonId, moduleNumber, correctCount, totalCount, score, null);
    }

    @Transactional
    public void saveModuleScore(UUID learnerId, UUID lessonId, Integer moduleNumber, Integer correctCount, Integer totalCount, Double score, Integer timeSeconds) {
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
        if (moduleScore.getScore() == null || bdScore.compareTo(moduleScore.getScore()) > 0) {
            moduleScore.setCorrectCount(safeCorrectCount);
            moduleScore.setTotalCount(safeTotalCount);
            moduleScore.setScore(bdScore);
            moduleScore.setStarsEarned(PracticeSessionService.calculateStars(bdScore));
            if (timeSeconds != null) {
                moduleScore.setTimeSeconds(timeSeconds);
            }
            lessonModuleScoreRepository.save(moduleScore);
        }
    }

    @Transactional
    public void savePartialModuleTime(UUID learnerId, UUID lessonId, UUID sessionId, Integer moduleNumber, Integer timeSeconds) {
        if (learnerId == null || moduleNumber == null || timeSeconds == null) return;
        UUID targetLessonId = lessonId;
        if (targetLessonId == null && sessionId != null) {
            var practiceOpt = practiceSessionRepository.findById(sessionId);
            if (practiceOpt.isPresent() && practiceOpt.get().getLesson() != null) {
                targetLessonId = practiceOpt.get().getLesson().getLessonId();
            } else {
                var introOpt = introductionSessionRepository.findById(sessionId);
                if (introOpt.isPresent() && introOpt.get().getLesson() != null) {
                    targetLessonId = introOpt.get().getLesson().getLessonId();
                } else {
                    var reviewOpt = reviewSessionRepository.findById(sessionId);
                    if (reviewOpt.isPresent() && reviewOpt.get().getLesson() != null) {
                        targetLessonId = reviewOpt.get().getLesson().getLessonId();
                    }
                }
            }
        }
        if (targetLessonId == null) return;

        Learner learner = learnerRepository.findById(learnerId)
                .orElseThrow(() -> new IllegalArgumentException("Learner not found"));
        Lesson lesson = lessonRepository.findById(targetLessonId)
                .orElseThrow(() -> new IllegalArgumentException("Lesson not found"));

        LessonModuleScore moduleScore = lessonModuleScoreRepository
                .findByLearnerLearnerIdAndLessonLessonIdAndModuleNumber(learnerId, targetLessonId, moduleNumber)
                .orElseGet(() -> LessonModuleScore.builder()
                        .learner(learner)
                        .lesson(lesson)
                        .moduleNumber(moduleNumber)
                        .correctCount(0)
                        .totalCount(0)
                        .score(BigDecimal.ZERO)
                        .starsEarned(0)
                        .build());

        moduleScore.setTimeSeconds(timeSeconds);
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
        BigDecimal newScore = BigDecimal.valueOf(score);
        if (status.getMasteryScore() == null || newScore.compareTo(status.getMasteryScore()) > 0) {
            status.setMasteryScore(newScore);
        }
        status.setUpdatedAt(OffsetDateTime.now());

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
                        BigDecimal newScore = BigDecimal.valueOf(score != null ? score : 0.0);
                        if (status.getMasteryScore() == null || newScore.compareTo(status.getMasteryScore()) > 0) {
                            status.setMasteryScore(newScore);
                        }
                        status.setUpdatedAt(OffsetDateTime.now());

                        if (passed) {
                            if (status.getStatus() != LessonStatus.COMPLETED) {
                                status.setStatus(LessonStatus.COMPLETED);
                                status.setCompletedAt(OffsetDateTime.now());
                            }
                        }

                        lessonStatusRepository.save(status);
                }

                // Also record in CumulativeReviewSession table for analytics and diagnostic roster
                try {
                    String lessonPairId = lessons.stream()
                            .map(l -> l.getLessonId().toString())
                            .collect(Collectors.joining("_"));

                    String badgeAwarded = "BRONZE";
                    if (score != null) {
                        if (score >= 100.0) badgeAwarded = "PERFECT_GOLD";
                        else if (score >= 90.0) badgeAwarded = "GOLD";
                        else if (score >= 80.0) badgeAwarded = "SILVER";
                    }

                    CumulativeReviewSession cumSession = CumulativeReviewSession.builder()
                            .learner(learner)
                            .lessonPairId(lessonPairId)
                            .sessionStatus("COMPLETED")
                            .accuracyPercent(BigDecimal.valueOf(score != null ? score : 0.0))
                            .badgeAwarded(badgeAwarded)
                            .pointsEarned((int) Math.round((score != null ? score : 0.0) * 1.5))
                            .startTime(OffsetDateTime.now().minusMinutes(5))
                            .endTime(OffsetDateTime.now())
                            .build();
                    cumulativeReviewSessionRepository.save(cumSession);
                } catch (Exception e) {
                    // Non-fatal
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

        List<String> formats = List.of("MULTIPLE_CHOICE", "FILL_IN_BLANK", "MATCHING", "SENTENCE_RECONSTRUCTION");
        List<String> bag = new ArrayList<>();
        Random random = new Random();

        List<Map<String, Object>> result = new ArrayList<>();

        for (VocabularyWord word : currentWords) {
            if (bag.isEmpty()) {
                bag.addAll(formats);
                Collections.shuffle(bag, random);
            }
            String selectedFormat = bag.remove(0);

            Map<String, Object> map = new HashMap<>();
            map.put("wordId", word.getWordId().toString());
            map.put("word", word.getEnglishWord());
            map.put("englishWord", word.getEnglishWord());
            map.put("definition", word.getCebuanoMeaning());
            map.put("cebuanoMeaning", word.getCebuanoMeaning());
            map.put("example", word.getExampleSentenceEnglish());
            map.put("exampleSentenceEnglish", word.getExampleSentenceEnglish());
            map.put("exampleCebuano", word.getExampleSentenceCebuano());
            map.put("exampleSentenceCebuano", word.getExampleSentenceCebuano());
            map.put("cebuanoSentence", word.getExampleSentenceCebuano());
            map.put("sentenceCebuano", word.getExampleSentenceCebuano());
            map.put("audioTextCebuano", word.getAudioTextCebuano());
            map.put("audioTextEnglish", word.getAudioTextEnglish());
            map.put("tileSentence", word.getTileSentence());
            map.put("fillBlankSentence", word.getFillBlankSentence());
            map.put("distractorPool", word.getDistractorPool());
            map.put("explanationText", word.getExplanationText());
            map.put("partOfSpeech", word.getPartOfSpeech());
            map.put("imageAssetPath", word.getImageAssetPath());
            map.put("activityFormat", selectedFormat);
            map.put("isRefresher", false);

            result.add(map);
        }

        return result;
    }
}
