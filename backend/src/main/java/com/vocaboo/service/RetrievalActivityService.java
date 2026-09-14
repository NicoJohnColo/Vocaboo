package com.vocaboo.service;

import com.vocaboo.entity.*;
import com.vocaboo.repository.*;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.util.*;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class RetrievalActivityService {

    private final PracticeSessionRepository sessionRepository;
    private final IntroductionSessionRepository introductionSessionRepository;
    private final ReinforcementQueueRepository queueRepository;
    private final VocabularyWordRepository wordRepository;
    private final DynamicQuestionGeneratorService questionGenerator;
    private final ReinforcementEngineService reinforcementEngine;
    private final PracticeSessionService practiceSessionService;
    private final DifficultyAdjustmentService difficultyService;
    private final WrongAnswerTrackingService wrongAnswerTrackingService;

        private static final List<String> CORE_FORMATS = List.of(
            "MULTIPLE_CHOICE",
            "FILL_IN_BLANK",
            "MATCHING",
            "SENTENCE_ARRANGEMENT",
            "WORD_SCRAMBLE",
            "IMAGE_LABELING",
            "TRUE_OR_FALSE",
            "TRANSLATION_RECALL",
            "HINT_TO_WORD"
        );

    private static class FormatBag {
        private final List<String> available = new ArrayList<>();
        private final Random random;

        public FormatBag(Random random) {
            this.random = random;
            refill();
        }

        private void refill() {
            available.clear();
            available.addAll(CORE_FORMATS);
            Collections.shuffle(available, random);
        }

        public String draw() {
            if (available.isEmpty()) {
                refill();
            }
            return available.remove(0);
        }

        public String drawExcept(String exclude) {
            if (available.isEmpty()) {
                refill();
            }
            for (int i = 0; i < available.size(); i++) {
                if (!available.get(i).equals(exclude)) {
                    return available.remove(i);
                }
            }
            refill();
            for (int i = 0; i < available.size(); i++) {
                if (!available.get(i).equals(exclude)) {
                    return available.remove(i);
                }
            }
            return available.remove(0);
        }
    }

    private PracticeSession resolvePracticeSession(UUID sessionId, boolean createIfMissing) {
        PracticeSession session = sessionRepository.findById(sessionId).orElse(null);
        if (session == null) {
            var introOpt = introductionSessionRepository.findById(sessionId);
            if (introOpt.isPresent()) {
                Learner learner = introOpt.get().getLearner();
                Lesson lesson = introOpt.get().getLesson();
                return sessionRepository.save(PracticeSession.builder()
                        .sessionId(sessionId)
                        .learner(learner)
                        .lesson(lesson)
                        .moduleNumber(2)
                        .classroomContextId(lesson.getClassroom() != null
                            ? lesson.getClassroom().getClassId()
                            : null)
                        .build());
            } else {
                throw new IllegalArgumentException("Session not found: " + sessionId);
            }
        }

        // Retrieval can receive an introduction-session ID or an older
        // practice session created before classroom context was mandatory.
        // Repair the context from the lesson before recording the answer so
        // class activity is not silently written as global activity.
        if (session.getClassroomContextId() == null
                && session.getLesson() != null
                && session.getLesson().getClassroom() != null) {
            session.setClassroomContextId(session.getLesson().getClassroom().getClassId());
            session = sessionRepository.save(session);
        }
        return session;
    }

    /**
     * Returns the formats appropriate for a given difficulty level.
     * Constrains activity types so easier types appear at LEARNING and
     * harder ones dominate at PROFICIENT.
     */
    private List<String> getFormatsForLevel(DifficultyLevel level) {
        switch (level) {
            case LEARNING:
                // Easiest: recognition-based activities + initial recall
                // HINT_TO_WORD eligible at LEARNING (Cebuano sentence clue with audio)
                return new ArrayList<>(Arrays.asList(
                    "MULTIPLE_CHOICE", "FILL_IN_BLANK", "TRUE_OR_FALSE", "IMAGE_LABELING", "TRANSLATION_RECALL", "HINT_TO_WORD"
                ));
            case FAMILIAR:
                // All formats available including HINT_TO_WORD (English definition clue)
                return new ArrayList<>(Arrays.asList(
                    "MULTIPLE_CHOICE", "FILL_IN_BLANK", "MATCHING",
                    "SENTENCE_ARRANGEMENT", "WORD_SCRAMBLE", "IMAGE_LABELING", "TRUE_OR_FALSE", "TRANSLATION_RECALL", "HINT_TO_WORD"
                ));
            case PROFICIENT:
                // All formats available; HINT_TO_WORD requires hintDefinition to be set (gated in generator)
                return new ArrayList<>(Arrays.asList(
                    "MULTIPLE_CHOICE", "FILL_IN_BLANK", "MATCHING",
                    "SENTENCE_ARRANGEMENT", "WORD_SCRAMBLE", "IMAGE_LABELING", "TRUE_OR_FALSE", "TRANSLATION_RECALL", "HINT_TO_WORD"
                ));
            default:
                return new ArrayList<>(Arrays.asList(
                    "MULTIPLE_CHOICE", "FILL_IN_BLANK", "MATCHING",
                    "SENTENCE_ARRANGEMENT", "WORD_SCRAMBLE", "IMAGE_LABELING", "TRUE_OR_FALSE", "TRANSLATION_RECALL"
                ));
        }
    }

    private String getRandomFormatFromPool(VocabularyWord word, UUID learnerId, Random random, Integer moduleNumber) {
        // Use per-word eligible types if set, otherwise fall back to ALL 7 types
        String eligible = word.getEligibleActivityTypes();
        List<String> pool;
        if (eligible == null || eligible.isBlank()) {
            pool = new ArrayList<>(CORE_FORMATS);
        } else {
            pool = Arrays.asList(eligible.split(";"));
        }

        // Filter by per-lesson configured activity formats if present
        if (word.getLesson() != null && word.getLesson().getModule2Activities() != null && !word.getLesson().getModule2Activities().isBlank()) {
            List<String> lessonFormats = Arrays.asList(word.getLesson().getModule2Activities().toUpperCase().split(";"));
            List<String> lessonFiltered = pool.stream()
                .filter(f -> lessonFormats.contains(f.trim().toUpperCase()))
                .collect(Collectors.toList());
            if (!lessonFiltered.isEmpty()) {
                pool = lessonFiltered;
            }
        }

        // Intersect with tier-appropriate formats for this word
        DifficultyLevel level = difficultyService.getCurrentLevel(learnerId, word.getWordId(), moduleNumber);
        List<String> tierFormats = getFormatsForLevel(level);
        List<String> filtered = pool.stream()
            .filter(f -> tierFormats.stream().anyMatch(t -> t.equalsIgnoreCase(f.trim())))
            .collect(Collectors.toList());

        // If intersection is empty (e.g. eligible list has types not in tier), use tier formats directly
        if (filtered.isEmpty()) filtered = tierFormats;

        return filtered.get(random.nextInt(filtered.size()));
    }

    private String getRandomFormatFromPoolExcept(VocabularyWord word, UUID learnerId, String exclude, Random random, Integer moduleNumber) {
        String eligible = word.getEligibleActivityTypes();
        List<String> pool;
        if (eligible == null || eligible.isBlank()) {
            pool = new ArrayList<>(CORE_FORMATS);
        } else {
            pool = Arrays.asList(eligible.split(";"));
        }

        if (word.getLesson() != null && word.getLesson().getModule2Activities() != null && !word.getLesson().getModule2Activities().isBlank()) {
            List<String> lessonFormats = Arrays.asList(word.getLesson().getModule2Activities().toUpperCase().split(";"));
            List<String> lessonFiltered = pool.stream()
                .filter(f -> lessonFormats.contains(f.trim().toUpperCase()))
                .collect(Collectors.toList());
            if (!lessonFiltered.isEmpty()) {
                pool = lessonFiltered;
            }
        }

        DifficultyLevel level = difficultyService.getCurrentLevel(learnerId, word.getWordId(), moduleNumber);
        List<String> tierFormats = getFormatsForLevel(level);
        List<String> filtered = pool.stream()
            .filter(f -> tierFormats.stream().anyMatch(t -> t.equalsIgnoreCase(f.trim())))
            .filter(f -> !f.equalsIgnoreCase(exclude))
            .collect(Collectors.toList());

        if (filtered.isEmpty()) {
            // All formats excluded — pick any except the excluded one
            List<String> fallback = tierFormats.stream()
                .filter(f -> !f.equalsIgnoreCase(exclude))
                .collect(Collectors.toList());
            return fallback.isEmpty() ? exclude : fallback.get(random.nextInt(fallback.size()));
        }

        return filtered.get(random.nextInt(filtered.size()));
    }

    private String getBestDiversifiedFormat(VocabularyWord word, UUID learnerId, Set<String> excludes, Map<String, Integer> globalUsage, Random random, Integer moduleNumber) {
        String eligible = word.getEligibleActivityTypes();
        List<String> pool = (eligible == null || eligible.isBlank())
                ? new ArrayList<>(CORE_FORMATS)
                : Arrays.asList(eligible.split(";"));

        // Strictly enforce per-lesson configured activity formats if set by Admin/Teacher
        if (word.getLesson() != null && word.getLesson().getModule2Activities() != null && !word.getLesson().getModule2Activities().isBlank()) {
            List<String> lessonFormats = Arrays.stream(word.getLesson().getModule2Activities().toUpperCase().split(";"))
                    .map(String::trim)
                    .filter(s -> !s.isBlank())
                    .collect(Collectors.toList());
            List<String> lessonFiltered = pool.stream()
                .map(String::trim)
                .map(String::toUpperCase)
                .filter(lessonFormats::contains)
                .collect(Collectors.toList());
            if (!lessonFiltered.isEmpty()) {
                pool = lessonFiltered;
            } else {
                pool = lessonFormats;
            }
        }

        DifficultyLevel level = difficultyService.getCurrentLevel(learnerId, word.getWordId(), moduleNumber);
        List<String> tierFormats = getFormatsForLevel(level);

        // Candidate formats for this word that haven't been picked for this word yet
        final List<String> lessonPool = pool;
        List<String> candidates = pool.stream()
                .map(String::trim)
                .map(String::toUpperCase)
                .filter(f -> tierFormats.stream().anyMatch(t -> t.equalsIgnoreCase(f)))
                .filter(f -> !excludes.contains(f))
                .filter(f -> !(f.equalsIgnoreCase("MATCHING") && globalUsage.getOrDefault("MATCHING", 0) >= 1))
                .collect(Collectors.toList());

        if (candidates.isEmpty()) {
            candidates = lessonPool.stream()
                    .map(String::trim)
                    .map(String::toUpperCase)
                    .filter(f -> !excludes.contains(f))
                    .collect(Collectors.toList());
            if (candidates.isEmpty()) {
                candidates = lessonPool.stream()
                        .map(String::trim)
                        .map(String::toUpperCase)
                        .collect(Collectors.toList());
            }
        }

        // Pick the candidate format with lowest global usage to ensure all types show up!
        int minUsage = candidates.stream()
                .mapToInt(f -> globalUsage.getOrDefault(f, 0))
                .min()
                .orElse(0);

        List<String> leastUsed = candidates.stream()
                .filter(f -> globalUsage.getOrDefault(f, 0) == minUsage)
                .collect(Collectors.toList());

        return leastUsed.get(random.nextInt(leastUsed.size()));
    }

    @Transactional
    public List<Map<String, Object>> generateSessionQuestions(UUID sessionId) {
        PracticeSession session = resolvePracticeSession(sessionId, true);

        UUID learnerId = session.getLearner().getLearnerId();
        UUID lessonId = session.getLesson().getLessonId();
        Integer moduleNumber = session.getModuleNumber();

        // 1. Fetch all words in the lesson and filter by posFocus
        String posFocus = session.getLearner().getPosFocus();
        List<VocabularyWord> lessonWords = wordRepository.findByLessonLessonIdOrderByWordOrderAsc(lessonId).stream()
                .filter(w -> posFocus == null || "ALL".equalsIgnoreCase(posFocus) || posFocus.equalsIgnoreCase(w.getPartOfSpeech()))
                .filter(w -> {
                    DifficultyLevel level = difficultyService.getCurrentLevel(learnerId, w.getWordId(), moduleNumber);
                    return level != DifficultyLevel.MASTERED;
                })
                .collect(Collectors.toList());

        // 2. Fetch active reinforcement items for this learner, filtered strictly to THIS lesson and POS focus
        List<ReinforcementQueueItem> reinforcementItems = queueRepository
                .findByLearnerLearnerIdAndIsResolvedFalseOrderByScheduledAtAsc(learnerId)
                .stream()
                .filter(item -> item.getWord() != null && 
                                item.getWord().getLesson() != null && 
                                lessonId.equals(item.getWord().getLesson().getLessonId()))
                .filter(item -> posFocus == null || "ALL".equalsIgnoreCase(posFocus) || posFocus.equalsIgnoreCase(item.getWord().getPartOfSpeech()))
                .collect(Collectors.toList());

        List<Map<String, Object>> questionsList = new ArrayList<>();
        Random random = new Random();

        // Global format distribution pool to ensure maximum format variety across the session
        Map<String, Integer> globalFormatUsage = new HashMap<>();
        for (String f : CORE_FORMATS) {
            globalFormatUsage.put(f, 0);
        }

        // 3. Generate questions for lesson words (3 diverse exercises per word)
        boolean pronunciationUnlocked = false;
        if (moduleNumber != null && moduleNumber == 3) {
            boolean allProficient = true;
            for (VocabularyWord w : lessonWords) {
                DifficultyLevel level = difficultyService.getCurrentLevel(learnerId, w.getWordId(), moduleNumber);
                if (level == DifficultyLevel.LEARNING || level == DifficultyLevel.FAMILIAR) {
                    allProficient = false;
                    break;
                }
            }
            pronunciationUnlocked = allProficient && !lessonWords.isEmpty();
        }

        for (int i = 0; i < lessonWords.size(); i++) {
            VocabularyWord word = lessonWords.get(i);
            Set<String> chosenForWord = new HashSet<>();

            DifficultyLevel currentLevel = difficultyService.getCurrentLevel(learnerId, word.getWordId(), moduleNumber);

            if (moduleNumber != null && moduleNumber == 3) {
                List<String> allowedM3 = new ArrayList<>();
                if (word.getLesson() != null && word.getLesson().getModule3Activities() != null && !word.getLesson().getModule3Activities().isBlank()) {
                    allowedM3.addAll(Arrays.stream(word.getLesson().getModule3Activities().toUpperCase().split(";"))
                            .map(String::trim)
                            .filter(s -> !s.isBlank())
                            .collect(Collectors.toList()));
                }
                if (allowedM3.isEmpty()) {
                    allowedM3.add("FILL_IN_BLANK");
                    allowedM3.add("SENTENCE_ARRANGEMENT");
                }

                if (pronunciationUnlocked && currentLevel == DifficultyLevel.PROFICIENT && allowedM3.contains("PRONUNCIATION_FEEDBACK")) {
                    for (int r = 0; r < 3; r++) {
                        String format = allowedM3.get(r % allowedM3.size());
                        questionsList.add(questionGenerator.generateQuestion(learnerId, word, format));
                    }
                } else {
                    List<String> nonPronounce = allowedM3.stream()
                            .filter(f -> !f.contains("PRONUNCIATION"))
                            .collect(Collectors.toList());
                    if (nonPronounce.isEmpty()) nonPronounce = allowedM3;
                    for (int r = 0; r < 3; r++) {
                        String format = nonPronounce.get(random.nextInt(nonPronounce.size()));
                        questionsList.add(questionGenerator.generateQuestion(learnerId, word, format));
                    }
                }
            } else {
                for (int r = 0; r < 3; r++) {
                    String format = getBestDiversifiedFormat(word, learnerId, chosenForWord, globalFormatUsage, random, moduleNumber);
                    chosenForWord.add(format);
                    globalFormatUsage.put(format, globalFormatUsage.getOrDefault(format, 0) + 1);
                    questionsList.add(questionGenerator.generateQuestion(learnerId, word, format));
                }
            }
        }

        // Shuffle base question list so words and formats interleave dynamically
        Collections.shuffle(questionsList, random);

        // 4. Intersperse active reinforcement items
        for (int i = 0; i < reinforcementItems.size(); i++) {
            VocabularyWord rWord = reinforcementItems.get(i).getWord();
            int index = Math.min((i * 3) + 2, questionsList.size());
            String format = getRandomFormatFromPool(rWord, learnerId, random, moduleNumber);
            questionsList.add(index, questionGenerator.generateQuestion(learnerId, rWord, format));
        }

        return questionsList;
    }

    @Transactional
    public Map<String, Object> generateSingleQuestion(UUID sessionId, UUID wordId, String format) {
        PracticeSession session = resolvePracticeSession(sessionId, true);
        
        VocabularyWord word = wordRepository.findById(wordId)
                .orElseThrow(() -> new IllegalArgumentException("Word not found"));

        return questionGenerator.generateQuestion(session.getLearner().getLearnerId(), word, format);
    }

    @Transactional
    public Map<String, Object> generateDiagnosticQuestion(UUID sessionId, UUID wordId) {
        PracticeSession session = resolvePracticeSession(sessionId, true);
        VocabularyWord word = wordRepository.findById(wordId)
                .orElseThrow(() -> new IllegalArgumentException("Word not found"));

        // Use FAMILIAR-tier pool intersected with word's eligible types
        String eligible = word.getEligibleActivityTypes();
        List<String> pool = (eligible == null || eligible.isBlank())
                ? new ArrayList<>(CORE_FORMATS)
                : Arrays.asList(eligible.split(";"));
        List<String> tierFormats = getFormatsForLevel(DifficultyLevel.FAMILIAR);
        List<String> filtered = pool.stream()
                .filter(f -> tierFormats.stream().anyMatch(t -> t.equalsIgnoreCase(f.trim())))
                .collect(Collectors.toList());
        if (filtered.isEmpty()) filtered = tierFormats;

        String format = filtered.get(new Random().nextInt(filtered.size()));

        // Generate at FAMILIAR difficulty config
        Map<String, Object> q = questionGenerator.generateQuestion(
                session.getLearner().getLearnerId(), word, format, DifficultyLevel.FAMILIAR);
        q.put("diagnosticActivityType", format);
        return q;
    }

    @Transactional
    public Map<String, Object> submitAnswer(UUID sessionId, UUID wordId, boolean isCorrect, String wrongAnswer, String activityFormat) {
        PracticeSession session = resolvePracticeSession(sessionId, true);

        UUID learnerId = session.getLearner().getLearnerId();
        UUID actualSessionId = session.getSessionId();
        Integer moduleNumber = session.getModuleNumber();

        // 1. Log the result via PracticeSessionService
        practiceSessionService.record(actualSessionId, wordId, isCorrect, activityFormat, null);

        // 2. Fetch current level before adjustment
        DifficultyLevel oldLevel = difficultyService.getCurrentLevel(learnerId, wordId, moduleNumber);

        // 3. Update adaptive difficulty level via DifficultyAdjustmentService
        var progress = difficultyService.calculateNext(learnerId, wordId, isCorrect, moduleNumber, activityFormat);
        DifficultyLevel newLevel = progress != null && progress.getCurrentLevel() != null
                ? DifficultyLevel.valueOf(progress.getCurrentLevel())
                : oldLevel;

        boolean leveledUp = isCorrect && (newLevel.ordinal() > oldLevel.ordinal());
        boolean demoted = !isCorrect && (newLevel.ordinal() < oldLevel.ordinal());

        // 4. Spaced Repetition Reinforcement updates
        if (isCorrect) {
            reinforcementEngine.resolve(learnerId, wordId);
        } else {
            reinforcementEngine.enqueue(learnerId, wordId);
            wrongAnswerTrackingService.trackWrongAnswer(learnerId, wordId, wrongAnswer, activityFormat);
        }

        Map<String, Object> result = new HashMap<>();
        result.put("sessionId", sessionId.toString());
        result.put("wordId", wordId.toString());
        result.put("isCorrect", isCorrect);
        result.put("oldLevel", oldLevel.name());
        result.put("currentLevel", newLevel.name());
        result.put("leveledUp", leveledUp);
        result.put("demoted", demoted);
        result.put("consecutiveCorrect", progress != null ? progress.getConsecutiveCorrect() : 0);
        result.put("consecutiveIncorrect", progress != null ? progress.getConsecutiveIncorrect() : 0);
        return result;
    }

    private String selectFormat(int index, int phase) {
        String[] formats = {"MULTIPLE_CHOICE", "FILL_IN_BLANK", "MATCHING"};
        return formats[(index + phase) % formats.length];
    }
}
