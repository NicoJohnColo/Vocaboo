package com.vocaboo.service;

import com.vocaboo.dto.response.LearnerWrongAnswersResponse;
import com.vocaboo.dto.response.LearnerWrongAnswersResponse.WrongWordDetail;
import com.vocaboo.dto.response.WrongAnswerAnalysisResponse;
import com.vocaboo.dto.response.WrongAnswerAnalysisResponse.ConfusedPairDetail;
import com.vocaboo.dto.response.WrongAnswerAnalysisResponse.CurriculumGapDetail;
import com.vocaboo.entity.*;
import com.vocaboo.repository.*;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.OffsetDateTime;
import java.util.*;
import java.util.stream.Collectors;

/**
 * Computes wrong-answer reports without any new database tables.
 *
 * Learner report  — groups all incorrect ReviewItem entries and PronunciationAttempt entries
 *                   for the learner by word, counts errors, determines whether the latest attempt
 *                   was correct, and calculates demerit points (2 × total errors).
 *
 * Admin report    — class-wide aggregation of incorrect items and pronunciation attempts,
 *                   cross-referenced with ConfusableWordPair entries to surface confusion
 *                   pair statistics and lesson-level curriculum gaps.
 */
@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class WrongAnswerReportingService {

    private static final int DEMERIT_MULTIPLIER = 2;

    private final ReviewItemRepository reviewItemRepository;
    private final ConfusableWordPairRepository confusableWordPairRepository;
    private final WordProgressRepository wordProgressRepository;
    private final PronunciationAttemptRepository pronunciationAttemptRepository;

    private static class CombinedAttempt {
        private final VocabularyWord word;
        private final boolean isCorrect;
        private final OffsetDateTime timestamp;

        public CombinedAttempt(VocabularyWord word, boolean isCorrect, OffsetDateTime timestamp) {
            this.word = word;
            this.isCorrect = isCorrect;
            this.timestamp = timestamp;
        }

        public VocabularyWord getWord() { return word; }
        public boolean getIsCorrect() { return isCorrect; }
        public OffsetDateTime getTimestamp() { return timestamp; }
    }

    private static class ClassWideError {
        private final UUID learnerId;
        private final VocabularyWord word;

        public ClassWideError(UUID learnerId, VocabularyWord word) {
            this.learnerId = learnerId;
            this.word = word;
        }

        public UUID getLearnerId() { return learnerId; }
        public VocabularyWord getWord() { return word; }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Learner endpoint
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * Returns a summary of words the learner has answered incorrectly, sorted by
     * error frequency (most errors first), together with their total demerit points.
     */
    public LearnerWrongAnswersResponse getLearnerWrongAnswers(UUID learnerId) {
        List<ReviewItem> reviewItems =
                reviewItemRepository.findAllByLearnerIdOrderByCreatedAtAsc(learnerId);

        List<PronunciationAttempt> pronAttempts =
                pronunciationAttemptRepository.findByLearnerLearnerIdOrderByRecordedAtAsc(learnerId);

        // Map both types of attempts to a unified representation
        List<CombinedAttempt> attemptsList = new ArrayList<>();
        for (ReviewItem item : reviewItems) {
            attemptsList.add(new CombinedAttempt(
                    item.getWord(),
                    Boolean.TRUE.equals(item.getIsCorrect()),
                    item.getCreatedAt()
            ));
        }
        for (PronunciationAttempt attempt : pronAttempts) {
            // Include only non-inconclusive attempts in wrong-answers demerit aggregation
            if (attempt.getIsCorrect() != null && !Boolean.TRUE.equals(attempt.getIsInconclusive())) {
                attemptsList.add(new CombinedAttempt(
                        attempt.getWord(),
                        Boolean.TRUE.equals(attempt.getIsCorrect()),
                        attempt.getRecordedAt()
                ));
            }
        }

        // Sort chronologically ascending so the latest attempt is last in list
        attemptsList.sort(Comparator.comparing(CombinedAttempt::getTimestamp));

        // Build: wordId → chronologically ordered list of attempts
        Map<UUID, List<CombinedAttempt>> attemptsByWord = new LinkedHashMap<>();
        for (CombinedAttempt attempt : attemptsList) {
            UUID wordId = attempt.getWord().getWordId();
            attemptsByWord.computeIfAbsent(wordId, k -> new ArrayList<>()).add(attempt);
        }

        Map<UUID, WrongWordDetail> detailsMap = new LinkedHashMap<>();
        int totalErrors = 0;

        for (Map.Entry<UUID, List<CombinedAttempt>> entry : attemptsByWord.entrySet()) {
            List<CombinedAttempt> items = entry.getValue();

            long errorCount = items.stream()
                    .filter(i -> !i.getIsCorrect())
                    .count();

            if (errorCount == 0) continue; // never answered wrong — skip

            totalErrors += (int) errorCount;

            // The most-recent attempt determines the "currently correct" badge
            CombinedAttempt latest = items.get(items.size() - 1);
            boolean currentlyCorrect = latest.getIsCorrect();

            VocabularyWord word = items.get(0).getWord();
            String lessonTitle = word.getLesson() != null ? word.getLesson().getLessonTitle() : "";
            String categoryName = (word.getLesson() != null && word.getLesson().getCategory() != null)
                    ? word.getLesson().getCategory().getCategoryName() : "";

            detailsMap.put(word.getWordId(), WrongWordDetail.builder()
                    .wordId(word.getWordId())
                    .englishWord(word.getEnglishWord())
                    .cebuanoMeaning(word.getCebuanoMeaning())
                    .partOfSpeech(word.getPartOfSpeech())
                    .lessonTitle(lessonTitle)
                    .categoryName(categoryName)
                    .errorCount((int) errorCount)
                    .currentlyCorrect(currentlyCorrect)
                    .build());
        }

        // Incorporate words that are unmastered or need review in WordProgress
        List<WordProgress> progressList = wordProgressRepository.findByLearnerLearnerId(learnerId);
        for (WordProgress progress : progressList) {
            if (progress.getStatus() != WordStatus.MASTERED) {
                VocabularyWord word = progress.getWord();
                UUID wordId = word.getWordId();

                if (!detailsMap.containsKey(wordId)) {
                    String lessonTitle = word.getLesson() != null ? word.getLesson().getLessonTitle() : "";
                    String categoryName = (word.getLesson() != null && word.getLesson().getCategory() != null)
                            ? word.getLesson().getCategory().getCategoryName() : "";

                    // Since it is unmastered / needs practice, set errorCount to 1, currentlyCorrect = false
                    totalErrors += 1;

                    detailsMap.put(wordId, WrongWordDetail.builder()
                            .wordId(wordId)
                            .englishWord(word.getEnglishWord())
                            .cebuanoMeaning(word.getCebuanoMeaning())
                            .partOfSpeech(word.getPartOfSpeech())
                            .lessonTitle(lessonTitle)
                            .categoryName(categoryName)
                            .errorCount(1)
                            .currentlyCorrect(false)
                            .build());
                } else {
                    // Force currentlyCorrect to false if it is still unmastered
                    detailsMap.get(wordId).setCurrentlyCorrect(false);
                }
            }
        }

        List<WrongWordDetail> wrongWords = new ArrayList<>(detailsMap.values());

        // Sort: most errors first
        wrongWords.sort(Comparator.comparingInt(WrongWordDetail::getErrorCount).reversed());

        int demeritPoints = totalErrors * DEMERIT_MULTIPLIER;

        return LearnerWrongAnswersResponse.builder()
                .demeritPoints(demeritPoints)
                .words(wrongWords)
                .build();
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Admin endpoint
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * Returns class-wide wrong-answer analysis: confused word pair statistics and
     * lesson-level curriculum gaps, based on all review item and pronunciation attempt records.
     */
    public WrongAnswerAnalysisResponse getClassWideWrongAnswerAnalysis() {
        List<ReviewItem> allReviewItems = reviewItemRepository.findAllOrderByCreatedAtAsc();
        List<PronunciationAttempt> allPronAttempts = pronunciationAttemptRepository.findAll();

        List<ClassWideError> incorrectAttempts = new ArrayList<>();
        for (ReviewItem item : allReviewItems) {
            if (Boolean.FALSE.equals(item.getIsCorrect())) {
                incorrectAttempts.add(new ClassWideError(
                        item.getSession().getLearner().getLearnerId(),
                        item.getWord()
                ));
            }
        }
        for (PronunciationAttempt attempt : allPronAttempts) {
            if (Boolean.FALSE.equals(attempt.getIsCorrect()) && !Boolean.TRUE.equals(attempt.getIsInconclusive())) {
                incorrectAttempts.add(new ClassWideError(
                        attempt.getLearner().getLearnerId(),
                        attempt.getWord()
                ));
            }
        }

        int totalClassErrors = incorrectAttempts.size();

        // Distinct learner count with at least one error
        long learnersWithErrors = incorrectAttempts.stream()
                .map(ClassWideError::getLearnerId)
                .distinct()
                .count();

        // ── Confused Pair Analysis ─────────────────────────────────────────
        // Build set of word IDs that appear in incorrect attempts
        Set<UUID> incorrectWordIds = incorrectAttempts.stream()
                .map(i -> i.getWord().getWordId())
                .collect(Collectors.toSet());

        // Fetch all confusable pairs and intersect
        List<ConfusableWordPair> allPairs = confusableWordPairRepository.findAll();

        List<ConfusedPairDetail> confusedPairs = new ArrayList<>();

        for (ConfusableWordPair pair : allPairs) {
            UUID wordAId = pair.getWordA().getWordId();
            UUID wordBId = pair.getWordB().getWordId();

            boolean wordAInErrors = incorrectWordIds.contains(wordAId);
            boolean wordBInErrors = incorrectWordIds.contains(wordBId);

            if (!wordAInErrors && !wordBInErrors) continue;

            // Count errors for either word in this pair
            long pairErrors = incorrectAttempts.stream()
                    .filter(i -> i.getWord().getWordId().equals(wordAId)
                            || i.getWord().getWordId().equals(wordBId))
                    .count();

            long affectedLearners = incorrectAttempts.stream()
                    .filter(i -> i.getWord().getWordId().equals(wordAId)
                            || i.getWord().getWordId().equals(wordBId))
                    .map(ClassWideError::getLearnerId)
                    .distinct()
                    .count();

            String lessonTitle = pair.getLesson() != null ? pair.getLesson().getLessonTitle() : "";

            confusedPairs.add(ConfusedPairDetail.builder()
                    .wordAId(wordAId)
                    .wordAEnglish(pair.getWordA().getEnglishWord())
                    .wordACebuano(pair.getWordA().getCebuanoMeaning())
                    .wordBId(wordBId)
                    .wordBEnglish(pair.getWordB().getEnglishWord())
                    .wordBCebuano(pair.getWordB().getCebuanoMeaning())
                    .lessonTitle(lessonTitle)
                    .affectedLearners((int) affectedLearners)
                    .totalErrors((int) pairErrors)
                    .build());
        }

        // Sort: most errors first
        confusedPairs.sort(Comparator.comparingInt(ConfusedPairDetail::getTotalErrors).reversed());

        // ── Curriculum Gap Analysis ────────────────────────────────────────
        // Group incorrect attempts by lesson
        Map<UUID, List<ClassWideError>> errorsByLesson = incorrectAttempts.stream()
                .filter(i -> i.getWord().getLesson() != null)
                .collect(Collectors.groupingBy(i -> i.getWord().getLesson().getLessonId()));

        List<CurriculumGapDetail> curriculumGaps = errorsByLesson.entrySet().stream()
                .map(entry -> {
                    List<ClassWideError> lessonErrors = entry.getValue();
                    var lesson = lessonErrors.get(0).getWord().getLesson();

                    long lessonAffectedLearners = lessonErrors.stream()
                            .map(ClassWideError::getLearnerId)
                            .distinct()
                            .count();

                    String categoryName = lesson.getCategory() != null
                            ? lesson.getCategory().getCategoryName() : "";

                    String recommendation = String.format(
                            "Review \"%s\" vocabulary — %d learner(s) made errors here.",
                            lesson.getLessonTitle(), lessonAffectedLearners);

                    return CurriculumGapDetail.builder()
                            .lessonId(lesson.getLessonId())
                            .lessonTitle(lesson.getLessonTitle())
                            .categoryName(categoryName)
                            .affectedLearners((int) lessonAffectedLearners)
                            .totalErrors(lessonErrors.size())
                            .recommendation(recommendation)
                            .build();
                })
                .sorted(Comparator.comparingInt(CurriculumGapDetail::getTotalErrors).reversed())
                .collect(Collectors.toList());

        return WrongAnswerAnalysisResponse.builder()
                .totalClassErrors(totalClassErrors)
                .learnersWithErrors((int) learnersWithErrors)
                .confusedPairs(confusedPairs)
                .curriculumGaps(curriculumGaps)
                .build();
    }
}
