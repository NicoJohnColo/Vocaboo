package com.vocaboo.service;

import com.vocaboo.entity.DifficultyLevel;
import com.vocaboo.entity.VocabularyWord;
import com.vocaboo.entity.AdaptiveMetric;
import com.vocaboo.repository.VocabularyWordRepository;
import com.vocaboo.repository.AdaptiveMetricRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import java.util.*;

@Service
@RequiredArgsConstructor
public class DynamicQuestionGeneratorService {

    private final DifficultyAdjustmentService difficultyService;
    private final VocabularyWordRepository wordRepository;
    private final AdaptiveMetricRepository metricRepository;

    public Map<String, Object> generateQuestion(UUID learnerId, VocabularyWord word, String formatStr) {
        DifficultyLevel level = difficultyService.getCurrentLevel(learnerId, word.getWordId());
        
        // Fetch adaptive options count and timer constraints from database, or use default rules
        int optionCount = getOptionCountForLevel(learnerId, level);
        int timerLimit = getTimerLimitForLevel(learnerId, level);

        Map<String, Object> q = new HashMap<>();
        q.put("wordId", word.getWordId().toString());
        q.put("englishWord", word.getEnglishWord());
        q.put("cebuanoMeaning", word.getCebuanoMeaning());
        q.put("imageAssetPath", word.getImageAssetPath());
        q.put("difficultyLevel", level.name());
        q.put("timeLimitSeconds", timerLimit);

        String resolvedFormat = formatStr;
        if (resolvedFormat == null) {
            resolvedFormat = selectDefaultFormat(level);
        }
        q.put("activityFormat", resolvedFormat);

        switch (resolvedFormat.toUpperCase()) {
            case "MULTIPLE_CHOICE":
                generateMultipleChoice(q, word, optionCount);
                break;
            case "FILL_IN_BLANK":
                generateFillInBlank(q, word, level, optionCount);
                break;
            case "MATCHING":
                generateMatching(q, word);
                break;
            case "SENTENCE_ARRANGEMENT":
                generateSentenceArrangement(q, word);
                break;
            default:
                generateMultipleChoice(q, word, optionCount);
                break;
        }

        return q;
    }

    private int getOptionCountForLevel(UUID learnerId, DifficultyLevel level) {
        return metricRepository.findByLearnerLearnerIdAndDifficultyLevel(learnerId, level)
                .map(AdaptiveMetric::getOptionCount)
                .orElseGet(() -> {
                    switch (level) {
                        case LEARNING: return 3;
                        case FAMILIAR:
                        case PROFICIENT: return 4;
                        case MASTERED: return 5;
                        default: return 4;
                    }
                });
    }

    private int getTimerLimitForLevel(UUID learnerId, DifficultyLevel level) {
        return metricRepository.findByLearnerLearnerIdAndDifficultyLevel(learnerId, level)
                .map(AdaptiveMetric::getTimeLimitSeconds)
                .orElseGet(() -> {
                    switch (level) {
                        case LEARNING: return 45;
                        case FAMILIAR: return 30;
                        case PROFICIENT: return 20;
                        case MASTERED: return 15;
                        default: return 30;
                    }
                });
    }

    private String selectDefaultFormat(DifficultyLevel level) {
        switch (level) {
            case LEARNING: return "MULTIPLE_CHOICE";
            case FAMILIAR: return "MATCHING";
            case PROFICIENT: return "FILL_IN_BLANK";
            case MASTERED: return "SENTENCE_ARRANGEMENT";
            default: return "MULTIPLE_CHOICE";
        }
    }

    private void generateMultipleChoice(Map<String, Object> q, VocabularyWord word, int count) {
        q.put("questionText", "What is the Cebuano meaning of \"" + word.getEnglishWord() + "\"?");
        q.put("correctAnswer", word.getCebuanoMeaning());

        List<String> options = new ArrayList<>();
        options.add(word.getCebuanoMeaning());

        List<String> distractors = fetchCebuanoDistractors(word, count - 1);
        options.addAll(distractors);
        Collections.shuffle(options);

        q.put("options", options);
    }

    private void generateFillInBlank(Map<String, Object> q, VocabularyWord word, DifficultyLevel level, int count) {
        String sentence = word.getExampleSentenceEnglish();
        String target = word.getEnglishWord();

        // Simple regex replace to insert blank
        String fitbSentence = sentence.replaceAll("(?i)" + target, "_______");
        q.put("questionText", "Complete the sentence: " + fitbSentence);
        q.put("correctAnswer", target);

        // Proficient and Mastered levels require typing without options
        if (level == DifficultyLevel.PROFICIENT || level == DifficultyLevel.MASTERED) {
            q.put("requiresTyping", true);
            q.put("options", Collections.emptyList());
        } else {
            q.put("requiresTyping", false);
            List<String> options = new ArrayList<>();
            options.add(target);
            List<String> distractors = fetchEnglishDistractors(word, count - 1);
            options.addAll(distractors);
            Collections.shuffle(options);
            q.put("options", options);
        }
    }

    private void generateMatching(Map<String, Object> q, VocabularyWord word) {
        q.put("questionText", "Match the English words with their Cebuano meanings.");
        
        List<VocabularyWord> words = wordRepository.findByLessonLessonIdOrderByWordOrderAsc(word.getLesson().getLessonId());
        if (words.size() < 4) {
            words = wordRepository.findAll();
        }

        // Select up to 4 words including the target
        List<VocabularyWord> matchPool = new ArrayList<>();
        matchPool.add(word);
        for (VocabularyWord w : words) {
            if (!w.getWordId().equals(word.getWordId()) && matchPool.size() < 4) {
                matchPool.add(w);
            }
        }

        List<Map<String, String>> pairs = new ArrayList<>();
        for (VocabularyWord mw : matchPool) {
            Map<String, String> pair = new HashMap<>();
            pair.put("english", mw.getEnglishWord());
            pair.put("cebuano", mw.getCebuanoMeaning());
            pairs.add(pair);
        }

        q.put("matchingPairs", pairs);
    }

    private void generateSentenceArrangement(Map<String, Object> q, VocabularyWord word) {
        q.put("questionText", "Arrange the words to form the correct example sentence.");
        q.put("correctAnswer", word.getExampleSentenceEnglish());

        // Split sentence by spaces, remove punctuation, and scramble
        String sentence = word.getExampleSentenceEnglish().replaceAll("[.,!?;:]", "");
        String[] tokens = sentence.split("\\s+");
        List<String> scrambled = new ArrayList<>(Arrays.asList(tokens));
        Collections.shuffle(scrambled);

        q.put("scrambledTokens", scrambled);
        q.put("correctTokens", Arrays.asList(tokens));
    }

    private List<String> fetchCebuanoDistractors(VocabularyWord target, int count) {
        List<VocabularyWord> candidates = wordRepository.findByLessonLessonIdOrderByWordOrderAsc(target.getLesson().getLessonId());
        List<String> distractors = new ArrayList<>();
        for (VocabularyWord w : candidates) {
            if (!w.getWordId().equals(target.getWordId()) && !w.getCebuanoMeaning().equals(target.getCebuanoMeaning())) {
                distractors.add(w.getCebuanoMeaning());
            }
        }
        if (distractors.size() < count) {
            distractors.addAll(Arrays.asList("saging", "balay", "iro", "iring", "adlaw", "bulan", "kamot", "bata"));
        }
        Collections.shuffle(distractors);
        return distractors.subList(0, Math.min(count, distractors.size()));
    }

    private List<String> fetchEnglishDistractors(VocabularyWord target, int count) {
        List<VocabularyWord> candidates = wordRepository.findByLessonLessonIdOrderByWordOrderAsc(target.getLesson().getLessonId());
        List<String> distractors = new ArrayList<>();
        for (VocabularyWord w : candidates) {
            if (!w.getWordId().equals(target.getWordId()) && !w.getEnglishWord().equals(target.getEnglishWord())) {
                distractors.add(w.getEnglishWord());
            }
        }
        if (distractors.size() < count) {
            distractors.addAll(Arrays.asList("banana", "house", "dog", "cat", "sun", "moon", "hand", "child"));
        }
        Collections.shuffle(distractors);
        return distractors.subList(0, Math.min(count, distractors.size()));
    }
}
