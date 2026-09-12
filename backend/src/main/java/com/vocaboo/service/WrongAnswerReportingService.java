package com.vocaboo.service;

import com.vocaboo.dto.response.LearnerWrongAnswersResponse;
import com.vocaboo.dto.response.LearnerWrongAnswersResponse.WrongWordDetail;
import com.vocaboo.dto.response.WrongAnswerAnalysisResponse;
import com.vocaboo.dto.response.WrongAnswerAnalysisResponse.ConfusedPairDetail;
import com.vocaboo.dto.response.WrongAnswerAnalysisResponse.CurriculumGapDetail;
import com.vocaboo.dto.response.WrongAnswerAnalysisResponse.ProblemWordDetail;
import com.vocaboo.entity.*;
import com.vocaboo.repository.*;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.*;
import java.util.stream.Collectors;

/**
 * Computes wrong-answer reports based on unified WordPerformance metrics
 * across all active learners in the curriculum.
 *
 * WordPerformance is the single source of truth for learner accuracy, struggle demerits,
 * and error counts across all lesson modules (Module 1, 2, 3, Diagnostic, and Sandbox).
 */
@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class WrongAnswerReportingService {

    private final WordPerformanceRepository wordPerformanceRepository;
    private final ReviewItemRepository reviewItemRepository;
    private final ConfusableWordPairRepository confusableWordPairRepository;
    private final PronunciationAttemptRepository pronunciationAttemptRepository;
    private final LearnerRepository learnerRepository;
    private final com.vocaboo.repository.ClassEnrollmentRepository classEnrollmentRepository;

    // ─────────────────────────────────────────────────────────────────────────
    // Learner endpoint
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * Returns a summary of words the learner has answered incorrectly, sorted by
     * struggle severity (demerits first), together with their total demerit points.
     */
    public LearnerWrongAnswersResponse getLearnerWrongAnswers(UUID learnerId) {
        List<WordPerformance> wordPerformances = wordPerformanceRepository.findByLearnerLearnerId(learnerId);

        Map<UUID, WrongWordDetail> detailsMap = new LinkedHashMap<>();
        int totalDemeritsAccumulated = 0;

        for (WordPerformance wp : wordPerformances) {
            if (wp.getWord() == null) continue;
            UUID wordId = wp.getWord().getWordId();

            int demerits = wp.getDemeritPoints() != null ? wp.getDemeritPoints() : 0;
            if (demerits <= 0) {
                continue; // only include active struggling words with demerits
            }

            totalDemeritsAccumulated += demerits;

            boolean currentlyCorrect = wp.getAccuracy() != null && wp.getAccuracy().compareTo(BigDecimal.valueOf(70.0)) >= 0;

            VocabularyWord word = wp.getWord();
            String lessonTitle = word.getLesson() != null ? word.getLesson().getLessonTitle() : "";
            String categoryName = (word.getLesson() != null && word.getLesson().getCategory() != null)
                    ? word.getLesson().getCategory().getCategoryName() : "";

            detailsMap.put(wordId, WrongWordDetail.builder()
                    .wordId(wordId)
                    .englishWord(word.getEnglishWord())
                    .cebuanoMeaning(word.getCebuanoMeaning())
                    .partOfSpeech(word.getPartOfSpeech())
                    .lessonTitle(lessonTitle)
                    .categoryName(categoryName)
                    .errorCount(demerits)
                    .currentlyCorrect(currentlyCorrect)
                    .build());
        }

        List<WrongWordDetail> wrongWords = new ArrayList<>(detailsMap.values());
        wrongWords.sort(Comparator.comparingInt(WrongWordDetail::getErrorCount).reversed());

        return LearnerWrongAnswersResponse.builder()
                .demeritPoints(totalDemeritsAccumulated)
                .words(wrongWords)
                .build();
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Admin endpoint
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * Returns class-wide wrong-answer analysis: confused word pair statistics and
     * lesson-level curriculum gaps, based on unified WordPerformance records across
     * all active learners in the selected cohort.
     */
    public WrongAnswerAnalysisResponse getClassWideWrongAnswerAnalysis() {
        return getClassWideWrongAnswerAnalysis(null, null, null, null);
    }

    public WrongAnswerAnalysisResponse getClassWideWrongAnswerAnalysis(UUID sectionId, GradeLevel gradeLevel, String cohortType) {
        return getClassWideWrongAnswerAnalysis(sectionId, gradeLevel, cohortType, null);
    }

    public WrongAnswerAnalysisResponse getClassWideWrongAnswerAnalysis(UUID sectionId, GradeLevel gradeLevel, String cohortType, UUID teacherId) {
        // 1. Resolve filtered active learners
        List<Learner> learners;
        if (sectionId != null) {
            List<UUID> classEnrolledIds = classEnrollmentRepository.findEnrolledLearnerIdsByClassId(sectionId);
            if (!classEnrolledIds.isEmpty()) {
                learners = learnerRepository.findAllById(classEnrolledIds).stream()
                        .filter(Learner::getIsActive)
                        .collect(Collectors.toList());
            } else {
                learners = learnerRepository.findBySectionSectionIdAndIsActiveTrue(sectionId);
            }
        } else if ("INDEPENDENT".equalsIgnoreCase(cohortType) && teacherId == null) {
            learners = learnerRepository.findBySectionIsNullAndIsActiveTrue();
        } else if ("ENROLLED".equalsIgnoreCase(cohortType) && teacherId == null) {
            learners = learnerRepository.findBySectionIsNotNullAndIsActiveTrue();
        } else {
            learners = learnerRepository.findByIsActiveTrue();
        }

        if (teacherId != null) {
            List<UUID> teacherEnrolledIds = classEnrollmentRepository.findEnrolledLearnerIdsByTeacherId(teacherId);
            learners = learners.stream()
                    .filter(l -> teacherEnrolledIds.contains(l.getLearnerId()))
                    .collect(Collectors.toList());
        }

        if (gradeLevel != null) {
            learners = learners.stream()
                    .filter(l -> l.getGradeLevel() == gradeLevel)
                    .collect(Collectors.toList());
        }

        Set<UUID> cohortLearnerIds = learners.stream()
                .map(Learner::getLearnerId)
                .collect(Collectors.toSet());

        // 2. Fetch all WordPerformance records for cohort learners (single source of truth)
        List<WordPerformance> allPerformances = wordPerformanceRepository.findAll();
        List<WordPerformance> cohortPerformances = allPerformances.stream()
                .filter(wp -> wp.getLearner() != null && cohortLearnerIds.contains(wp.getLearner().getLearnerId()))
                .collect(Collectors.toList());

        // Build per-learner, per-word struggle tracking: Map<WordId, Map<LearnerId, Integer>>
        Map<UUID, Map<UUID, Integer>> errorsByWordAndLearner = new HashMap<>();
        Map<UUID, VocabularyWord> wordEntityMap = new HashMap<>();

        for (WordPerformance wp : cohortPerformances) {
            if (wp.getWord() == null || wp.getLearner() == null) continue;
            UUID wordId = wp.getWord().getWordId();
            UUID learnerId = wp.getLearner().getLearnerId();
            wordEntityMap.put(wordId, wp.getWord());

            int demerits = wp.getDemeritPoints() != null ? wp.getDemeritPoints() : 0;
            if (demerits > 0) {
                errorsByWordAndLearner.computeIfAbsent(wordId, k -> new HashMap<>())
                        .put(learnerId, demerits);
            }
        }

        // 3. Compute class-wide totals
        int totalClassErrors = 0;
        Set<UUID> learnersWithErrorsSet = new HashSet<>();

        for (Map<UUID, Integer> learnerErrors : errorsByWordAndLearner.values()) {
            for (Map.Entry<UUID, Integer> entry : learnerErrors.entrySet()) {
                totalClassErrors += entry.getValue();
                learnersWithErrorsSet.add(entry.getKey());
            }
        }

        // ── Confused Pair Analysis (strictly scoped) ───────────────────────
        List<ConfusableWordPair> allPairs = confusableWordPairRepository.findAll();
        List<ConfusedPairDetail> confusedPairs = new ArrayList<>();

        for (ConfusableWordPair pair : allPairs) {
            if (pair.getWordA() == null || pair.getWordB() == null) continue;
            Lesson l = pair.getLesson();
            if (teacherId != null) {
                if (l == null || l.getClassroom() == null) continue;
                if (l.getClassroom().getTeacher() != null && !teacherId.equals(l.getClassroom().getTeacher().getTeacherId())) continue;
                if (sectionId != null && !sectionId.equals(l.getClassroom().getClassId())) continue;
            } else if (sectionId != null) {
                if (l == null || l.getClassroom() == null || !sectionId.equals(l.getClassroom().getClassId())) continue;
            }

            UUID wordAId = pair.getWordA().getWordId();
            UUID wordBId = pair.getWordB().getWordId();

            Map<UUID, Integer> errorsA = errorsByWordAndLearner.getOrDefault(wordAId, Map.of());
            Map<UUID, Integer> errorsB = errorsByWordAndLearner.getOrDefault(wordBId, Map.of());

            int totalPairErrors = errorsA.values().stream().mapToInt(Integer::intValue).sum()
                    + errorsB.values().stream().mapToInt(Integer::intValue).sum();

            Set<UUID> affectedLearners = new HashSet<>();
            affectedLearners.addAll(errorsA.keySet());
            affectedLearners.addAll(errorsB.keySet());

            String lessonTitle = pair.getLesson() != null ? pair.getLesson().getLessonTitle() : "";

            if (totalPairErrors > 0) {
                confusedPairs.add(ConfusedPairDetail.builder()
                        .wordAId(wordAId)
                        .wordAEnglish(pair.getWordA().getEnglishWord())
                        .wordACebuano(pair.getWordA().getCebuanoMeaning())
                        .wordBId(wordBId)
                        .wordBEnglish(pair.getWordB().getEnglishWord())
                        .wordBCebuano(pair.getWordB().getCebuanoMeaning())
                        .lessonTitle(lessonTitle)
                        .affectedLearners(affectedLearners.size())
                        .totalErrors(totalPairErrors)
                        .build());
            }
        }

        confusedPairs.sort(Comparator.comparingInt(ConfusedPairDetail::getTotalErrors).reversed());

        // Group words with active demerits by their lesson (strictly scoped to class/teacher)
        Map<UUID, List<UUID>> wordsByLesson = new HashMap<>();
        for (UUID wordId : errorsByWordAndLearner.keySet()) {
            VocabularyWord word = wordEntityMap.get(wordId);
            if (word != null && word.getLesson() != null && word.getLesson().getLessonId() != null) {
                Lesson l = word.getLesson();
                if (teacherId != null) {
                    if (l.getClassroom() == null) {
                        continue; // Skip global lessons in teacher POV
                    }
                    if (l.getClassroom().getTeacher() != null && !teacherId.equals(l.getClassroom().getTeacher().getTeacherId())) {
                        continue; // Skip lessons from other teachers
                    }
                    if (sectionId != null && !sectionId.equals(l.getClassroom().getClassId())) {
                        continue; // Skip lessons from other classes
                    }
                } else if (sectionId != null) {
                    if (l.getClassroom() == null || !sectionId.equals(l.getClassroom().getClassId())) {
                        continue; // Skip lessons from other classes or global when section is specified
                    }
                }
                wordsByLesson.computeIfAbsent(l.getLessonId(), k -> new ArrayList<>()).add(wordId);
            }
        }

        List<CurriculumGapDetail> curriculumGaps = new ArrayList<>();

        for (Map.Entry<UUID, List<UUID>> entry : wordsByLesson.entrySet()) {
            UUID lessonId = entry.getKey();
            List<UUID> lessonWordIds = entry.getValue();

            int lessonTotalErrors = 0;
            Set<UUID> lessonAffectedLearners = new HashSet<>();
            List<ProblemWordDetail> problemWords = new ArrayList<>();
            Lesson lesson = null;

            for (UUID wid : lessonWordIds) {
                VocabularyWord word = wordEntityMap.get(wid);
                if (word == null) continue;
                if (lesson == null) lesson = word.getLesson();

                Map<UUID, Integer> wordErrors = errorsByWordAndLearner.getOrDefault(wid, Map.of());
                int wordDemerits = wordErrors.values().stream().mapToInt(Integer::intValue).sum();
                int wordLearnerCount = wordErrors.size();

                if (wordDemerits > 0) {
                    lessonTotalErrors += wordDemerits;
                    lessonAffectedLearners.addAll(wordErrors.keySet());

                    int wordMistakes = Math.max(1, wordDemerits / 2);
                    problemWords.add(ProblemWordDetail.builder()
                            .wordId(wid)
                            .englishWord(word.getEnglishWord())
                            .cebuanoMeaning(word.getCebuanoMeaning())
                            .errorCount(wordDemerits)
                            .demeritPoints(wordDemerits)
                            .mistakeCount(wordMistakes)
                            .affectedLearners(wordLearnerCount)
                            .build());
                }
            }

            if (lessonTotalErrors > 0 && lesson != null) {
                problemWords.sort(Comparator.comparingInt(ProblemWordDetail::getErrorCount).reversed());

                String categoryName = lesson.getCategory() != null ? lesson.getCategory().getCategoryName() : "";
                String recommendation;
                if (lessonTotalErrors >= 30) {
                    recommendation = String.format(
                            "High Error Density: Review \"%s\" core vocabulary and contextual usage — %d learner(s) made %d demerit error points.",
                            lesson.getLessonTitle(), lessonAffectedLearners.size(), lessonTotalErrors);
                } else if (lessonTotalErrors >= 10) {
                    recommendation = String.format(
                            "Moderate Errors: Reinforce \"%s\" vocabulary distinction — %d learner(s) made %d demerit error points.",
                            lesson.getLessonTitle(), lessonAffectedLearners.size(), lessonTotalErrors);
                } else {
                    recommendation = String.format(
                            "Review \"%s\" vocabulary — %d learner(s) had struggle signals here.",
                            lesson.getLessonTitle(), lessonAffectedLearners.size());
                }

                curriculumGaps.add(CurriculumGapDetail.builder()
                        .lessonId(lessonId)
                        .lessonTitle(lesson.getLessonTitle())
                        .categoryName(categoryName)
                        .problemWords(problemWords)
                        .affectedLearners(lessonAffectedLearners.size())
                        .totalErrors(lessonTotalErrors)
                        .recommendation(recommendation)
                        .build());
            }
        }

        curriculumGaps.sort(Comparator.comparingInt(CurriculumGapDetail::getTotalErrors).reversed());

        return WrongAnswerAnalysisResponse.builder()
                .totalClassErrors(totalClassErrors)
                .learnersWithErrors(learnersWithErrorsSet.size())
                .confusedPairs(confusedPairs)
                .curriculumGaps(curriculumGaps)
                .build();
    }
}
