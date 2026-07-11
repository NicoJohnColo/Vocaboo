package com.vocaboo.service;

import com.vocaboo.dto.response.LearnerWrongAnswersResponse;
import com.vocaboo.dto.response.LearnerWrongAnswersResponse.WrongWordDetail;
import com.vocaboo.dto.response.WrongAnswerAnalysisResponse;
import com.vocaboo.dto.response.WrongAnswerAnalysisResponse.ConfusedPairDetail;
import com.vocaboo.dto.response.WrongAnswerAnalysisResponse.CurriculumGapDetail;
import com.vocaboo.entity.ConfusableWordPair;
import com.vocaboo.entity.ReviewItem;
import com.vocaboo.entity.VocabularyWord;
import com.vocaboo.entity.WordProgress;
import com.vocaboo.entity.WordStatus;
import com.vocaboo.repository.ConfusableWordPairRepository;
import com.vocaboo.repository.ReviewItemRepository;
import com.vocaboo.repository.WordProgressRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.*;
import java.util.stream.Collectors;

/**
 * Computes wrong-answer reports without any new database tables.
 *
 * Learner report  — groups all incorrect ReviewItem entries for the learner by word,
 *                   counts errors, determines whether the latest attempt was correct,
 *                   and calculates demerit points (2 × total errors).
 *
 * Admin report    — class-wide aggregation of incorrect items, cross-referenced with
 *                   ConfusableWordPair entries to surface confusion pair statistics
 *                   and lesson-level curriculum gaps.
 */
@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class WrongAnswerReportingService {

    private static final int DEMERIT_MULTIPLIER = 2;

    private final ReviewItemRepository reviewItemRepository;
    private final ConfusableWordPairRepository confusableWordPairRepository;
    private final WordProgressRepository wordProgressRepository;

    // ─────────────────────────────────────────────────────────────────────────
    // Learner endpoint
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * Returns a summary of words the learner has answered incorrectly, sorted by
     * error frequency (most errors first), together with their total demerit points.
     */
    public LearnerWrongAnswersResponse getLearnerWrongAnswers(UUID learnerId) {
        List<ReviewItem> allItems =
                reviewItemRepository.findAllByLearnerIdOrderByCreatedAtAsc(learnerId);

        // Build: wordId → chronologically ordered list of review items
        Map<UUID, List<ReviewItem>> itemsByWord = new LinkedHashMap<>();
        for (ReviewItem item : allItems) {
            UUID wordId = item.getWord().getWordId();
            itemsByWord.computeIfAbsent(wordId, k -> new ArrayList<>()).add(item);
        }

        Map<UUID, WrongWordDetail> detailsMap = new LinkedHashMap<>();
        int totalErrors = 0;

        for (Map.Entry<UUID, List<ReviewItem>> entry : itemsByWord.entrySet()) {
            List<ReviewItem> items = entry.getValue();

            long errorCount = items.stream()
                    .filter(i -> Boolean.FALSE.equals(i.getIsCorrect()))
                    .count();

            if (errorCount == 0) continue; // never answered wrong — skip

            totalErrors += (int) errorCount;

            // The most-recent attempt determines the "currently correct" badge
            ReviewItem latest = items.get(items.size() - 1);
            boolean currentlyCorrect = Boolean.TRUE.equals(latest.getIsCorrect());

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
     * lesson-level curriculum gaps, based on all review item records.
     */
    public WrongAnswerAnalysisResponse getClassWideWrongAnswerAnalysis() {
        List<ReviewItem> allItems = reviewItemRepository.findAllOrderByCreatedAtAsc();

        // Only incorrect items are relevant for this report
        List<ReviewItem> incorrectItems = allItems.stream()
                .filter(i -> Boolean.FALSE.equals(i.getIsCorrect()))
                .toList();

        int totalClassErrors = incorrectItems.size();

        // Distinct learner count with at least one error
        long learnersWithErrors = incorrectItems.stream()
                .map(i -> i.getSession().getLearner().getLearnerId())
                .distinct()
                .count();

        // ── Confused Pair Analysis ─────────────────────────────────────────
        // Build set of word IDs that appear in incorrect review items
        Set<UUID> incorrectWordIds = incorrectItems.stream()
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
            long pairErrors = incorrectItems.stream()
                    .filter(i -> i.getWord().getWordId().equals(wordAId)
                            || i.getWord().getWordId().equals(wordBId))
                    .count();

            long affectedLearners = incorrectItems.stream()
                    .filter(i -> i.getWord().getWordId().equals(wordAId)
                            || i.getWord().getWordId().equals(wordBId))
                    .map(i -> i.getSession().getLearner().getLearnerId())
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
        // Group incorrect items by lesson
        Map<UUID, List<ReviewItem>> errorsByLesson = incorrectItems.stream()
                .filter(i -> i.getWord().getLesson() != null)
                .collect(Collectors.groupingBy(i -> i.getWord().getLesson().getLessonId()));

        List<CurriculumGapDetail> curriculumGaps = errorsByLesson.entrySet().stream()
                .map(entry -> {
                    List<ReviewItem> lessonErrors = entry.getValue();
                    var lesson = lessonErrors.get(0).getWord().getLesson();

                    long lessonAffectedLearners = lessonErrors.stream()
                            .map(i -> i.getSession().getLearner().getLearnerId())
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
