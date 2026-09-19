package com.vocaboo.service;

import com.vocaboo.entity.DifficultyLevel;
import com.vocaboo.entity.VocabularyWord;
import com.vocaboo.entity.AdaptiveMetric;
import com.vocaboo.repository.VocabularyWordRepository;
import com.vocaboo.repository.AdaptiveMetricRepository;
import com.vocaboo.repository.WordPerformanceRepository;
import com.vocaboo.entity.Learner;
import com.vocaboo.repository.LearnerRepository;
import com.vocaboo.repository.PracticeResultRepository;
import com.vocaboo.repository.DifficultyProgressRepository;
import com.vocaboo.entity.PracticeResult;
import com.vocaboo.entity.DifficultyProgress;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import java.math.BigDecimal;
import java.util.*;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class DynamicQuestionGeneratorService {

    private static final String DEFAULT_ELIGIBLE_FORMATS = "MULTIPLE_CHOICE;FILL_IN_BLANK;MATCHING;SENTENCE_ARRANGEMENT;WORD_SCRAMBLE;IMAGE_LABELING;TRUE_OR_FALSE;HINT_TO_WORD";

    private final DifficultyAdjustmentService difficultyService;
    private final VocabularyWordRepository wordRepository;
    private final AdaptiveMetricRepository metricRepository;
    private final WordPerformanceRepository wordPerformanceRepository;
    private final LearnerRepository learnerRepository;
    private final PracticeResultRepository practiceResultRepository;
    private final DifficultyProgressRepository progressRepository;

    public Map<String, Object> generateQuestion(UUID learnerId, VocabularyWord word, String formatStr) {
        return generateQuestion(learnerId, word, formatStr, null);
    }

    public Map<String, Object> generateQuestion(UUID learnerId, VocabularyWord word, String formatStr, DifficultyLevel levelOverride) {
        String activityType;
        if (formatStr != null && !formatStr.isBlank()) {
            activityType = formatStr;
        } else {
            String eligible = word.getEligibleActivityTypes();
            if (eligible == null || eligible.isBlank()) {
                eligible = DEFAULT_ELIGIBLE_FORMATS;
            } else {
                eligible = eligible.toUpperCase();
            }
            List<String> typesList = new java.util.ArrayList<>(java.util.Arrays.asList(eligible.split(";")));
            if (word.getLesson() != null && word.getLesson().getModule2Activities() != null && !word.getLesson().getModule2Activities().isBlank()) {
                List<String> lessonFormats = java.util.Arrays.asList(word.getLesson().getModule2Activities().toUpperCase().split(";"));
                List<String> filtered = typesList.stream().filter(f -> lessonFormats.contains(f.trim().toUpperCase())).collect(java.util.stream.Collectors.toList());
                if (!filtered.isEmpty()) {
                    typesList = filtered;
                }
            }
            activityType = typesList.get(new java.util.Random().nextInt(typesList.size()));
        }
        activityType = activityType.toUpperCase();

        // Get the learner's current difficulty tier for THIS word (or use levelOverride if specified)
        DifficultyLevel level = (levelOverride != null) ? levelOverride : difficultyService.getCurrentLevel(learnerId, word.getWordId(), null);
        // Proficient is the highest question difficulty; Mastered is the achieved completion state
        if (level == DifficultyLevel.MASTERED) {
            level = DifficultyLevel.PROFICIENT;
        }

        // Tier-based parameters
        int optionCount   = getOptionCountForLevel(learnerId, level);
        int timerLimit    = getTimerLimitForLevel(learnerId, level);
        boolean showExplanations = (level != DifficultyLevel.PROFICIENT);

        // Hint language: derived from learner's language preference + tier
        // LEARNING: Cebuano / Bisaya hints (unless FULL_ENGLISH explicitly requested)
        // FAMILIAR: English hints (contextual English explanation / example)
        // PROFICIENT: NONE (no hints)
        String hintLanguage;
        try {
            Learner hintLearner = learnerRepository.findById(learnerId).orElse(null);
            com.vocaboo.entity.LanguageMedium langPref = hintLearner != null ? hintLearner.getLanguagePreference() : null;
            if (level == DifficultyLevel.PROFICIENT) {
                hintLanguage = "NONE";
            } else if (level == DifficultyLevel.FAMILIAR) {
                hintLanguage = "ENGLISH";
            } else { // LEARNING
                if (langPref == com.vocaboo.entity.LanguageMedium.FULL_ENGLISH) {
                    hintLanguage = "ENGLISH";
                } else if (langPref == com.vocaboo.entity.LanguageMedium.CEBUANO_ENGLISH_MIXED) {
                    hintLanguage = "CEBUANO_ENGLISH";
                } else {
                    hintLanguage = "CEBUANO";
                }
            }
        } catch (Exception e) {
            hintLanguage = (level == DifficultyLevel.LEARNING) ? "CEBUANO" : (level == DifficultyLevel.FAMILIAR ? "ENGLISH" : "NONE");
        }

        Map<String, Object> q = new HashMap<>();
        q.put("wordId",          word.getWordId().toString());
        q.put("englishWord",     word.getEnglishWord());
        q.put("activityType",    activityType);
        q.put("eligibleActivityTypes", word.getEligibleActivityTypes());
        q.put("difficultyLevel", level.name());
        q.put("timeLimitSeconds", timerLimit);
        q.put("showExplanations",       showExplanations);
        q.put("hintLanguage",    hintLanguage);
        q.put("imageAssetPath",  word.getImageAssetPath());
        q.put("audioAssetPath",  word.getAudioAssetPath());
        // Cebuano meaning MUST always be exposed because it serves as the prompt for Multiple Choice
        // and other activities, regardless of difficulty tier.
        q.put("cebuanoMeaning",  word.getCebuanoMeaning());
        q.put("hintDefinition",         word.getHintDefinition());
        q.put("hintCebuanoSentence",    word.getHintCebuanoSentence());
        String hintText = null;
        if (showExplanations) {
            if ("CEBUANO".equals(hintLanguage)) {
                hintText = (word.getHintCebuanoSentence() != null && !word.getHintCebuanoSentence().isBlank())
                        ? word.getHintCebuanoSentence()
                        : word.getExplanationText();
            } else if ("ENGLISH".equals(hintLanguage)) {
                hintText = (word.getHintDefinition() != null && !word.getHintDefinition().isBlank())
                        ? word.getHintDefinition()
                        : word.getExplanationText();
            }
        }
        q.put("hintText",               hintText);
        q.put("explanationText",        showExplanations ? word.getExplanationText() : null);
        q.put("exampleSentenceEnglish", word.getExampleSentenceEnglish());
        q.put("exampleSentenceCebuano", (word.getExampleSentenceCebuano() != null && !word.getExampleSentenceCebuano().isBlank()) ? word.getExampleSentenceCebuano() : word.getCebuanoMeaning());

        // activityFormat echoes the activityType so the Flutter client can route display
        q.put("activityFormat", activityType);

        switch (activityType) {
            case "MULTIPLE_CHOICE":
                generateMultipleChoice(q, word, learnerId, level, optionCount);
                break;
            case "FILL_IN_BLANK":
                generateFillInBlank(q, word, learnerId, level, optionCount);
                break;
            case "MATCHING":
            case "SENTENCE_MATCHING":
                generateMatching(q, word, learnerId, level);
                break;
            case "SENTENCE_ARRANGEMENT":
                generateSentenceArrangement(q, word, level);
                break;
            case "TYPE_WHAT_YOU_HEAR":
                generateTypeWhatYouHear(q, word);
                break;
            case "TRANSLATION_RECALL":
                generateTranslationRecall(q, word, level);
                break;
            case "WORD_SCRAMBLE":
                generateWordScramble(q, word, level);
                break;
            case "IMAGE_LABELING":
                generateImageLabeling(q, word, learnerId, level, optionCount);
                break;
            case "TRUE_OR_FALSE":
                generateTrueOrFalse(q, word, learnerId, level);
                break;
            case "HINT_TO_WORD":
                generateHintToWord(q, word, learnerId, level, optionCount);
                break;
            case "PRONUNCIATION_FEEDBACK":
                generatePronunciationFeedback(q, word);
                break;
            default:
                generateMultipleChoice(q, word, learnerId, level, optionCount);
                break;
        }

        return q;
    }

    // ---  Tier-based parameter helpers  ---

    private int getOptionCountForLevel(UUID learnerId, DifficultyLevel level) {
        return metricRepository.findByLearnerLearnerIdAndDifficultyLevel(learnerId, level)
                .map(AdaptiveMetric::getOptionCount)
                .orElseGet(() -> {
                    switch (level) {
                        case LEARNING:   return 3;  // 2 distractors + correct = 3 options
                        case FAMILIAR:   return 4;  // 3 distractors + correct = 4 options
                        case PROFICIENT: return 5;  // 4 distractors + correct = 5 options
                        default:         return 4;
                    }
                });
    }

    private int getTimerLimitForLevel(UUID learnerId, DifficultyLevel level) {
        return metricRepository.findByLearnerLearnerIdAndDifficultyLevel(learnerId, level)
                .map(AdaptiveMetric::getTimeLimitSeconds)
                .orElseGet(() -> {
                    switch (level) {
                        case LEARNING:   return 0;  // No timer for LEARNING tier
                        case FAMILIAR:   return 30;
                        case PROFICIENT: return 25;
                        default:         return 30;
                    }
                });
    }

    // ---  Activity generators with 3-tier adaptive logic  ---

    private void generateMultipleChoice(Map<String, Object> q, VocabularyWord word, UUID learnerId, DifficultyLevel level, int count) {
        // Tier behaviour:
        // LEARNING   — 3 options, prompt = Cebuano meaning, target = English word
        // FAMILIAR   — 4 options, INTERTWINED TRANSLATION: prompt = English word, target = Cebuano meaning
        // PROFICIENT — 5 options, prompt = Cebuano meaning, target = English word (phonetically close distractors, NO HINT)
        if (level == DifficultyLevel.FAMILIAR) {
            q.put("questionText", "Select the correct Cebuano word for the English word below.");
            q.put("word", word.getEnglishWord());
            q.put("displayWord", word.getEnglishWord());
            q.put("correctAnswer", word.getCebuanoMeaning());

            List<String> options = new ArrayList<>();
            options.add(word.getCebuanoMeaning());

            List<String> distractors = fetchWeightedCebuanoDistractors(learnerId, word, level, count - 1);
            options.addAll(distractors);
            Collections.shuffle(options);
            q.put("options", options);
            q.put("showCebuanoContext", false);
            q.put("intertwinedTranslation", true);
        } else {
            q.put("questionText", "Select the correct English word for the Cebuano word below.");
            q.put("word", word.getEnglishWord());
            q.put("displayWord", word.getCebuanoMeaning());
            q.put("correctAnswer", word.getEnglishWord());

            List<String> options = new ArrayList<>();
            options.add(word.getEnglishWord());

            List<String> distractors = fetchWeightedEnglishDistractors(learnerId, word, level, count - 1);
            options.addAll(distractors);
            Collections.shuffle(options);
            q.put("options", options);
            q.put("showCebuanoContext", level == DifficultyLevel.LEARNING);
            q.put("intertwinedTranslation", false);
        }
    }

    private void generateFillInBlank(Map<String, Object> q, VocabularyWord word, UUID learnerId, DifficultyLevel level, int count) {
        String target = word.getEnglishWord().trim();
        String rawSentence = (word.getFillBlankSentence() != null && !word.getFillBlankSentence().isEmpty()) ? word.getFillBlankSentence() : word.getExampleSentenceEnglish();
        String[] tokens = rawSentence.split("\\s+");
        int blankPos = -1;
        for (int i = 0; i < tokens.length; i++) {
            String cleanToken = tokens[i].replaceAll("[^a-zA-Z0-9_{}]", "");
            if (cleanToken.equalsIgnoreCase(target) || cleanToken.contains("{BLANK}") || cleanToken.contains("___")) {
                blankPos = i;
                break;
            }
        }
        if (blankPos == -1 && tokens.length > 0) blankPos = 0;

        int distractorCount;
        int timeLimitSeconds;

        switch (level) {
            case LEARNING:   distractorCount = 1; timeLimitSeconds = 0;  break;
            case FAMILIAR:   distractorCount = 2; timeLimitSeconds = 30; break;
            case PROFICIENT: distractorCount = 3; timeLimitSeconds = 20; break;
            default:         distractorCount = 1; timeLimitSeconds = 0;  break;
        }

        int radius = 99;
        int start = Math.max(0, blankPos - radius);
        int end   = Math.min(tokens.length - 1, blankPos + radius);
        StringBuilder sb = new StringBuilder();
        if (start > 0) sb.append("... ");
        for (int i = start; i <= end; i++) {
            sb.append(i == blankPos ? "_______" : tokens[i]);
            if (i < end) sb.append(" ");
        }
        if (end < tokens.length - 1) sb.append(" ...");
        String fitbSentence = sb.toString();

        q.put("questionText", fitbSentence.isEmpty() ? "_______" : fitbSentence);
        q.put("fitbSentence", fitbSentence.isEmpty() ? "_______" : fitbSentence);
        q.put("fitbAnswer",   target);
        q.put("correctAnswer", target);
        q.put("requiresTyping", false);
        q.put("timeLimitSeconds", timeLimitSeconds);

        // NEW DIMENSION — Cebuano sentence context visibility:
        // LEARNING:    show full Cebuano sentence translation below the blank
        // FAMILIAR:    show only first 3 words of Cebuano sentence  
        // PROFICIENT:  no Cebuano context at all
        String cebuanoCtx = word.getExampleSentenceCebuano() != null && !word.getExampleSentenceCebuano().isBlank()
                ? word.getExampleSentenceCebuano() : word.getCebuanoMeaning();
        if (level == DifficultyLevel.LEARNING) {
            q.put("fitbCebuanoContext", cebuanoCtx);
        } else if (level == DifficultyLevel.FAMILIAR) {
            String[] cebWords = cebuanoCtx.split("\\s+");
            String partial = String.join(" ", java.util.Arrays.copyOfRange(cebWords, 0, Math.min(3, cebWords.length))) + "...";
            q.put("fitbCebuanoContext", partial);
        } else {
            q.put("fitbCebuanoContext", null); // No context at PROFICIENT
        }

        List<String> options = new ArrayList<>();
        options.add(target);
        options.addAll(fetchWeightedEnglishDistractors(learnerId, word, level, distractorCount));
        Collections.shuffle(options);
        q.put("options", options);
    }

    private void generateMatching(Map<String, Object> q, VocabularyWord word, UUID learnerId, DifficultyLevel level) {
        // Tier pair counts:
        // LEARNING:              2 pairs (same-POS encountered words)
        // FAMILIAR:              3 pairs (same-POS, full lesson pool)
        // PROFICIENT:            4 pairs (full lesson pool regardless of POS — higher working-memory load)
        int pairCount = (level == DifficultyLevel.LEARNING) ? 2
                      : (level == DifficultyLevel.FAMILIAR)  ? 3
                      : 4; // PROFICIENT

        q.put("questionText", "Match each English word with its Cebuano meaning.");

        String targetPos = word.getPartOfSpeech();
        
        // 1. Try to get same-POS words from the same lesson
        List<VocabularyWord> samePosLessonWords = wordRepository.findByLessonLessonIdOrderByWordOrderAsc(word.getLesson().getLessonId())
                .stream()
                .filter(w -> targetPos == null || targetPos.equalsIgnoreCase(w.getPartOfSpeech()))
                .collect(java.util.stream.Collectors.toList());

        List<VocabularyWord> matchPool = new ArrayList<>();
        matchPool.add(word);
        
        Set<UUID> encounteredWordIds = progressRepository.findByLearnerLearnerIdAndModuleNumber(learnerId, 2).stream()
                .map(dp -> dp.getWord().getWordId())
                .collect(Collectors.toSet());

        // 2. Add encountered same-POS lesson words
        Collections.shuffle(samePosLessonWords);
        for (VocabularyWord w : samePosLessonWords) {
            if (!w.getWordId().equals(word.getWordId()) && encounteredWordIds.contains(w.getWordId()) && matchPool.size() < pairCount) {
                matchPool.add(w);
            }
        }

        // 3. If not enough, add ANY same-POS lesson words
        if (matchPool.size() < pairCount) {
            for (VocabularyWord w : samePosLessonWords) {
                if (!matchPool.stream().anyMatch(m -> m.getWordId().equals(w.getWordId())) && matchPool.size() < pairCount) {
                    matchPool.add(w);
                }
            }
        }
        
        // 4. If still not enough, fetch same-POS words from the ENTIRE repository (global fallback)
        if (matchPool.size() < pairCount) {
            List<VocabularyWord> globalSamePos = wordRepository.findAll().stream()
                .filter(w -> targetPos != null && targetPos.equalsIgnoreCase(w.getPartOfSpeech()))
                .collect(java.util.stream.Collectors.toList());
            Collections.shuffle(globalSamePos);
            for (VocabularyWord w : globalSamePos) {
                if (!matchPool.stream().anyMatch(m -> m.getWordId().equals(w.getWordId())) && matchPool.size() < pairCount) {
                    matchPool.add(w);
                }
            }
        }

        // 5. Final fallback: ANY lesson words regardless of POS
        if (matchPool.size() < pairCount) {
            List<VocabularyWord> allLessonWords = wordRepository.findByLessonLessonIdOrderByWordOrderAsc(word.getLesson().getLessonId());
            Collections.shuffle(allLessonWords);
            for (VocabularyWord w : allLessonWords) {
                if (!matchPool.stream().anyMatch(m -> m.getWordId().equals(w.getWordId())) && matchPool.size() < pairCount) {
                    matchPool.add(w);
                }
            }
        }

        Collections.shuffle(matchPool);

        List<Map<String, String>> pairs = new ArrayList<>();
        for (VocabularyWord mw : matchPool) {
            Map<String, String> pair = new HashMap<>();
            pair.put("wordId", mw.getWordId().toString());
            pair.put("english", mw.getEnglishWord());
            pair.put("cebuano", mw.getCebuanoMeaning());
            pairs.add(pair);
        }
        q.put("matchingPairs", pairs);
        // NEW DIMENSION — at PROFICIENT, signal that pool was drawn from full lesson (not POS-filtered)
        q.put("matchingFullLesson", level == DifficultyLevel.PROFICIENT);
    }

    private void generateSentenceArrangement(Map<String, Object> q, VocabularyWord word, DifficultyLevel level) {
        // Use admin-provided tile_sentence if available, else use example sentence
        String rawSentence = (word.getTileSentence() != null && !word.getTileSentence().isBlank())
                ? word.getTileSentence()
                : word.getExampleSentenceEnglish();

        q.put("questionText", "Arrange the words to form a correct sentence.");
        q.put("correctAnswer", rawSentence);

        String sentence = rawSentence.replaceAll("[.,!?;:]", "");
        String[] tokensArr = sentence.split("\\s+");
        List<String> allTokens = new ArrayList<>(Arrays.asList(tokensArr));

        String targetWord = word.getEnglishWord() != null ? word.getEnglishWord().trim() : "";
        int targetIdx = -1;
        for (int i = 0; i < tokensArr.length; i++) {
            if (tokensArr[i].equalsIgnoreCase(targetWord)) { targetIdx = i; break; }
        }
        if (targetIdx == -1 && tokensArr.length > 0) targetIdx = 0;

        // Tier distractor-tile counts:
        // LEARNING: 2 distractors + first word pre-placed (anchor assist)
        // FAMILIAR: 3 distractors, no anchor
        // PROFICIENT: 4 distractors, no anchor
        List<String> tileBank = new ArrayList<>(allTokens);
        String anchoredWord = null;

        // NEW DIMENSION — Anchor assist at LEARNING: pre-place the first token
        if (level == DifficultyLevel.LEARNING && !allTokens.isEmpty()) {
            anchoredWord = allTokens.get(0);
            tileBank.remove(0); // Remove from scramble pool; it will be pre-placed
        }

        int distractorCount = (level == DifficultyLevel.LEARNING) ? 2
                            : (level == DifficultyLevel.FAMILIAR)  ? 3
                            : 4;

        List<String> extraTiles = new ArrayList<>(Arrays.asList("the", "a", "an", "is", "are", "was", "were", "has", "have", "had", "do", "does", "did", "to", "of", "in", "for", "with", "on", "at", "by", "from"));
        // Remove tiles that are already in the sentence to avoid confusion if possible
        extraTiles.removeIf(t -> allTokens.stream().anyMatch(token -> token.equalsIgnoreCase(t)));
        Collections.shuffle(extraTiles);

        for (int i = 0; i < distractorCount && i < extraTiles.size(); i++) {
            tileBank.add(extraTiles.get(i));
        }

        Collections.shuffle(tileBank);
        int attempts = 0;
        while (tileBank.size() > 1 && tileBank.equals(allTokens) && attempts < 10) {
            Collections.shuffle(tileBank); attempts++;
        }

        q.put("scrambledTokens", tileBank);
        q.put("anchoredWord",    anchoredWord);   // non-null at LEARNING = first word pre-placed
        q.put("correctTokens",  allTokens);
        q.put("sentenceArrangementTokens", tileBank);
    }

    private void generateWordScramble(Map<String, Object> q, VocabularyWord word, DifficultyLevel level) {
        String targetWord = word.getEnglishWord().trim().toUpperCase();
        List<String> targetLetters = new ArrayList<>();
        for (char c : targetWord.toCharArray()) {
            targetLetters.add(String.valueOf(c));
        }

        q.put("questionText", "Fill in the missing letters to spell the English word.");
        q.put("correctAnswer", targetWord);

        int missingCount;
        int distractorCount;

        switch (level) {
            case LEARNING:   missingCount = 1; distractorCount = 1; break;
            case FAMILIAR:   missingCount = 2; distractorCount = 2; break;
            case PROFICIENT: missingCount = 3; distractorCount = 2; break;
            default:         missingCount = 1; distractorCount = 1; break;
        }

        missingCount = Math.min(missingCount, targetLetters.size());

        // NEW DIMENSION — First-letter reveal gating:
        // LEARNING:   first letter is ALWAYS revealed (never in the missing set)
        // FAMILIAR:   first letter is hidden 50% of the time
        // PROFICIENT: first letter is ALWAYS hidden (included in missing set)
        Random revealRand = new Random();
        boolean revealFirstLetter = (level == DifficultyLevel.LEARNING) ||
                                    (level == DifficultyLevel.FAMILIAR && revealRand.nextBoolean());
        // build missing index selection — exclude index 0 if first letter should be revealed
        List<Integer> candidateIndices = new ArrayList<>();
        for (int i = 0; i < targetLetters.size(); i++) {
            if (revealFirstLetter && i == 0) continue; // skip first index if revealed
            candidateIndices.add(i);
        }
        Collections.shuffle(candidateIndices);
        List<Integer> missingIndices = candidateIndices.subList(0, Math.min(missingCount, candidateIndices.size()));

        q.put("firstLetterRevealed", revealFirstLetter);

        List<String> tileBank = new ArrayList<>();
        List<String> anchoredPattern = new ArrayList<>();
        
        for (int i = 0; i < targetLetters.size(); i++) {
            if (missingIndices.contains(i)) {
                anchoredPattern.add("_");
                tileBank.add(targetLetters.get(i));
            } else {
                anchoredPattern.add(targetLetters.get(i));
            }
        }
        
        String alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
        Random rand = new Random();
        
        List<String> otherLessonWords = wordRepository.findByLessonLessonIdOrderByWordOrderAsc(word.getLesson().getLessonId())
                .stream()
                .map(w -> w.getEnglishWord().trim().toUpperCase())
                .filter(w -> !w.equals(targetWord))
                .collect(java.util.stream.Collectors.toList());

        boolean collisionFree = false;
        int regenAttempts = 0;
        List<String> chosenFakeLetters = new ArrayList<>();
        
        while (!collisionFree && regenAttempts < 10) {
            chosenFakeLetters.clear();
            for (int i = 0; i < distractorCount; i++) {
                chosenFakeLetters.add(String.valueOf(alphabet.charAt(rand.nextInt(alphabet.length()))));
            }
            
            Map<Character, Integer> poolFreq = new HashMap<>();
            for (String c : tileBank) {
                poolFreq.put(c.charAt(0), poolFreq.getOrDefault(c.charAt(0), 0) + 1);
            }
            for (String c : chosenFakeLetters) {
                poolFreq.put(c.charAt(0), poolFreq.getOrDefault(c.charAt(0), 0) + 1);
            }
            
            boolean hasCollision = false;
            for (String otherWord : otherLessonWords) {
                boolean canForm = true;
                Map<Character, Integer> wordFreq = new HashMap<>();
                for (char c : otherWord.toCharArray()) {
                    wordFreq.put(c, wordFreq.getOrDefault(c, 0) + 1);
                }
                for (Map.Entry<Character, Integer> entry : wordFreq.entrySet()) {
                    if (poolFreq.getOrDefault(entry.getKey(), 0) < entry.getValue()) {
                        canForm = false;
                        break;
                    }
                }
                if (canForm) {
                    hasCollision = true;
                    break;
                }
            }
            
            if (!hasCollision) {
                collisionFree = true;
            } else {
                regenAttempts++;
            }
        }
        
        tileBank.addAll(chosenFakeLetters);
        Collections.shuffle(tileBank);

        q.put("scrambledTokens", tileBank);
        q.put("anchoredWord", String.join(",", anchoredPattern));
        q.put("correctTokens", targetLetters);
        q.put("sentenceArrangementTokens", tileBank);
    }

    private void generateImageLabeling(Map<String, Object> q, VocabularyWord word, UUID learnerId, DifficultyLevel level, int count) {
        // Tiers: identical option behaviour to MULTIPLE_CHOICE, but UI puts image first.
        // NEW DIMENSION — Audio TTS gating:
        // LEARNING:   Cebuano TTS auto-plays (signal: autoPlayAudio=true, audioLanguage=CEBUANO)
        // FAMILIAR:   tap-to-play audio only (autoPlayAudio=false)
        // PROFICIENT: no audio cue at all (audioCueEnabled=false)
        q.put("questionText", "What is the correct English word for this image?");
        q.put("word", word.getEnglishWord());
        q.put("correctAnswer", word.getEnglishWord());

        boolean audioCueEnabled = (level != DifficultyLevel.PROFICIENT);
        boolean autoPlayAudio   = (level == DifficultyLevel.LEARNING);
        q.put("audioCueEnabled", audioCueEnabled);
        q.put("autoPlayAudio",   autoPlayAudio);
        q.put("audioLanguage",   "CEBUANO");

        List<String> options = new ArrayList<>();
        options.add(word.getEnglishWord());

        List<String> distractors = fetchWeightedEnglishDistractors(learnerId, word, level, count - 1);
        options.addAll(distractors);
        Collections.shuffle(options);
        q.put("options", options);
    }

    private void generateTrueOrFalse(Map<String, Object> q, VocabularyWord word, UUID learnerId, DifficultyLevel level) {
        // Correct-pair probability:
        // LEARNING: 80% correct  |  FAMILIAR: 50%  |  PROFICIENT: 40%
        // NEW DIMENSION — Cebuano visibility per tier:
        // LEARNING:   full example sentence shown with word bolded
        // FAMILIAR:   Cebuano meaning only
        // PROFICIENT: English word only (no Cebuano at all)
        Random rand = new Random();
        double roll = rand.nextDouble();
        boolean isCorrectPair;
        
        if (level == DifficultyLevel.LEARNING) {
            isCorrectPair = roll < 0.80;
        } else if (level == DifficultyLevel.FAMILIAR) {
            isCorrectPair = roll < 0.50;
        } else {
            isCorrectPair = roll < 0.40;
        }

        // Build the Cebuano display string depending on tier
        String cebuanoDisplay;
        if (level == DifficultyLevel.LEARNING) {
            // Show the full example Cebuano sentence if available
            String exCeb = word.getExampleSentenceCebuano();
            cebuanoDisplay = (exCeb != null && !exCeb.isBlank()) ? exCeb : word.getCebuanoMeaning();
        } else if (level == DifficultyLevel.FAMILIAR) {
            cebuanoDisplay = word.getCebuanoMeaning(); // meaning only
        } else {
            cebuanoDisplay = null; // PROFICIENT: no Cebuano shown
        }

        q.put("questionText", "Is this the correct English meaning?");
        q.put("tofCebuanoDisplay", cebuanoDisplay);
        q.put("tofShowCebuano", cebuanoDisplay != null);
        
        if (isCorrectPair) {
            q.put("word", word.getEnglishWord());
            q.put("displayWord", word.getEnglishWord());
            q.put("cebuanoMeaning", word.getCebuanoMeaning());
            q.put("correctAnswer", "True");
        } else {
            List<String> distractors = fetchWeightedEnglishDistractors(learnerId, word, level, 1);
            String wrongEnglish = distractors.isEmpty() ? "unknown" : distractors.get(0);
            q.put("word", wrongEnglish);
            q.put("displayWord", wrongEnglish);
            q.put("cebuanoMeaning", word.getCebuanoMeaning());
            q.put("correctAnswer", "False");
        }

        List<String> options = Arrays.asList("True", "False");
        q.put("options", options);
    }

    private void generatePronunciationFeedback(Map<String, Object> q, VocabularyWord word) {
        q.put("questionText", "Speak the word clearly.");
        q.put("correctAnswer", word.getEnglishWord());
        q.put("word", word.getEnglishWord());
        q.put("displayWord", word.getEnglishWord());
        q.put("options", Collections.emptyList());
        q.put("requiresTyping", false);
    }

    private void generateHintToWord(Map<String, Object> q, VocabularyWord word, UUID learnerId, DifficultyLevel level, int count) {
        // NEW 9th activity type — Hint-to-Word (definition match)
        // Tier mechanics:
        // LEARNING:   Cebuano example sentence with target word blanked + 3 options + auto-play audio
        // FAMILIAR:   Short English definition clue + 4 options
        // PROFICIENT: Single-word English synonym/clue + 5 options + 15s timer
        //
        // Eligibility gate: at FAMILIAR/PROFICIENT, if no hintDefinition is set, this should not be generated.
        // The service caller (RetrievalActivityService) should skip this format for words lacking hintDefinition
        // at those tiers; the generator itself handles a graceful fallback here.

        q.put("correctAnswer", word.getEnglishWord());
        q.put("word", word.getEnglishWord());

        if (level == DifficultyLevel.LEARNING) {
            // Clue = Cebuano example sentence with word blanked
            String cebSentence = (word.getHintCebuanoSentence() != null && !word.getHintCebuanoSentence().isBlank())
                    ? word.getHintCebuanoSentence()
                    : ((word.getExampleSentenceCebuano() != null && !word.getExampleSentenceCebuano().isBlank())
                       ? word.getExampleSentenceCebuano() : word.getCebuanoMeaning());
            q.put("questionText", "Which English word matches this clue?");
            q.put("hintToWordClue", cebSentence);
            q.put("hintToWordClueType", "CEBUANO_SENTENCE");
            q.put("autoPlayAudio", true);
            q.put("audioLanguage", "CEBUANO");
            // No extra timer override at LEARNING
        } else if (level == DifficultyLevel.FAMILIAR) {
            // Clue = short English definition
            String definition = (word.getHintDefinition() != null && !word.getHintDefinition().isBlank())
                    ? word.getHintDefinition() : word.getCebuanoMeaning(); // fallback to Cebuano meaning
            q.put("questionText", "Which English word matches this description?");
            q.put("hintToWordClue", definition);
            q.put("hintToWordClueType", "ENGLISH_DEFINITION");
            q.put("autoPlayAudio", false);
        } else { // PROFICIENT
            // Clue = synonym or single-word English clue (from hintDefinition, or cebuanoMeaning fallback)
            String definition = (word.getHintDefinition() != null && !word.getHintDefinition().isBlank())
                    ? word.getHintDefinition() : word.getCebuanoMeaning();
            q.put("questionText", "Identify the word from the clue:");
            q.put("hintToWordClue", definition);
            q.put("hintToWordClueType", "ENGLISH_SYNONYM");
            q.put("autoPlayAudio", false);
            q.put("timeLimitSeconds", 15); // Override timer at PROFICIENT
        }

        // Build options (correct + distractors)
        List<String> options = new ArrayList<>();
        options.add(word.getEnglishWord());
        List<String> distractors = fetchWeightedEnglishDistractors(learnerId, word, level, count - 1);
        options.addAll(distractors);
        Collections.shuffle(options);
        q.put("options", options);
    }

    private void generateTypeWhatYouHear(Map<String, Object> q, VocabularyWord word) {
        q.put("questionText", "Listen to the word and type what you hear.");
        q.put("correctAnswer", word.getEnglishWord());
        q.put("audioAssetPath", word.getAudioAssetPath());
        q.put("requiresTyping", true);
        q.put("options", Collections.emptyList());
    }

    private void generateTranslationRecall(Map<String, Object> q, VocabularyWord word, DifficultyLevel level) {
        // NEW DIMENSION — Progressive cue removal:
        // LEARNING:   show Cebuano meaning + first letter of the English answer as a starter hint
        // FAMILIAR:   show Cebuano meaning only
        // PROFICIENT: show only the image (if available) or a single audio TTS cue — no Cebuano text
        String firstLetterHint = null;
        if (level == DifficultyLevel.LEARNING && word.getEnglishWord() != null && !word.getEnglishWord().isEmpty()) {
            firstLetterHint = word.getEnglishWord().substring(0, 1).toUpperCase() + "...";
        }
        boolean showCebuanoPrompt = (level != DifficultyLevel.PROFICIENT);

        q.put("questionText", showCebuanoPrompt
                ? "Type the English word for: " + word.getCebuanoMeaning()
                : "Type the English word for this image/word.");
        q.put("cebuanoMeaning", showCebuanoPrompt ? word.getCebuanoMeaning() : null);
        q.put("displayWord", showCebuanoPrompt ? word.getCebuanoMeaning() : word.getEnglishWord());
        q.put("translationFirstLetterHint", firstLetterHint);
        q.put("translationShowCebuano", showCebuanoPrompt);
        q.put("correctAnswer", word.getEnglishWord());
        q.put("requiresTyping", true);
        q.put("options", Collections.emptyList());
    }

    private List<String> fetchWeightedCebuanoDistractors(UUID learnerId, VocabularyWord target, DifficultyLevel level, int count) {
        Learner learner = learnerRepository.findById(learnerId).orElse(null);
        String posFocus = learner != null ? learner.getPosFocus() : null;

        BigDecimal threshold = BigDecimal.valueOf(80.0);
        
        String targetPos = target.getPartOfSpeech();
        
        List<VocabularyWord> allLearnedWords = wordPerformanceRepository.findByLearnerLearnerId(learnerId).stream()
                .map(wp -> wp.getWord())
                .filter(w -> w != null && (posFocus == null || "ALL".equalsIgnoreCase(posFocus) || posFocus.equalsIgnoreCase(w.getPartOfSpeech())))
                .filter(w -> targetPos == null || targetPos.equalsIgnoreCase(w.getPartOfSpeech()))
                .collect(java.util.stream.Collectors.toList());

        List<VocabularyWord> weakWords = new ArrayList<>();
        List<VocabularyWord> knownWords = new ArrayList<>();

        for (VocabularyWord w : allLearnedWords) {
            List<PracticeResult> recentResults = practiceResultRepository.findTop5BySessionLearnerLearnerIdAndWordWordIdOrderByRecordedAtDesc(learnerId, w.getWordId());
            if (recentResults.isEmpty()) {
                continue;
            }
            long correctCount = recentResults.stream().filter(r -> Boolean.TRUE.equals(r.getIsCorrect())).count();
            double recentAccuracy = (double) correctCount / recentResults.size() * 100.0;
            if (recentAccuracy < 70.0) {
                weakWords.add(w);
            } else {
                knownWords.add(w);
            }
        }

        Set<String> pool = new LinkedHashSet<>();
        
        for (VocabularyWord w : weakWords) {
            if (!w.getWordId().equals(target.getWordId()) && !w.getCebuanoMeaning().equalsIgnoreCase(target.getCebuanoMeaning())) {
                pool.add(w.getCebuanoMeaning());
            }
        }
        for (VocabularyWord w : knownWords) {
            if (!w.getWordId().equals(target.getWordId()) && !w.getCebuanoMeaning().equalsIgnoreCase(target.getCebuanoMeaning())) {
                pool.add(w.getCebuanoMeaning());
            }
        }
        
        List<VocabularyWord> lessonWords = wordRepository.findByLessonLessonIdOrderByWordOrderAsc(target.getLesson().getLessonId()).stream()
                .filter(w -> posFocus == null || "ALL".equalsIgnoreCase(posFocus) || posFocus.equalsIgnoreCase(w.getPartOfSpeech()))
                .collect(java.util.stream.Collectors.toList());
        for (VocabularyWord w : lessonWords) {
            if (!w.getWordId().equals(target.getWordId()) && !w.getCebuanoMeaning().equalsIgnoreCase(target.getCebuanoMeaning())) {
                pool.add(w.getCebuanoMeaning());
            }
        }

        List<String> staticFallback = Arrays.asList("saging", "balay", "iro", "iring", "adlaw", "bulan", "kamot", "bata", "mata", "tiyan");
        for (String val : staticFallback) {
            if (!val.equalsIgnoreCase(target.getCebuanoMeaning())) {
                pool.add(val);
            }
        }

        return selectDistractors(target.getCebuanoMeaning(), new ArrayList<>(pool), level, count);
    }

    private List<String> fetchWeightedEnglishDistractors(UUID learnerId, VocabularyWord target, DifficultyLevel level, int count) {
        List<String> csvDistractors = new ArrayList<>();
        if (target.getDistractorPool() != null && !target.getDistractorPool().isBlank()) {
            String[] split = target.getDistractorPool().split(";");
            for (String s : split) {
                String trimmed = s.trim();
                if (!trimmed.isBlank() && !trimmed.equalsIgnoreCase(target.getEnglishWord())) {
                    csvDistractors.add(trimmed);
                }
            }
        }

        if (csvDistractors.size() >= count) {
            Collections.shuffle(csvDistractors);
            return csvDistractors.subList(0, count);
        }

        Learner learner = learnerRepository.findById(learnerId).orElse(null);
        String posFocus = learner != null ? learner.getPosFocus() : null;

        BigDecimal threshold = BigDecimal.valueOf(80.0);
        
        String targetPos = target.getPartOfSpeech();
        
        List<VocabularyWord> allLearnedWords = wordPerformanceRepository.findByLearnerLearnerId(learnerId).stream()
                .map(wp -> wp.getWord())
                .filter(w -> w != null && (posFocus == null || "ALL".equalsIgnoreCase(posFocus) || posFocus.equalsIgnoreCase(w.getPartOfSpeech())))
                .filter(w -> targetPos == null || targetPos.equalsIgnoreCase(w.getPartOfSpeech()))
                .collect(java.util.stream.Collectors.toList());

        List<VocabularyWord> weakWords = new ArrayList<>();
        List<VocabularyWord> knownWords = new ArrayList<>();

        for (VocabularyWord w : allLearnedWords) {
            List<PracticeResult> recentResults = practiceResultRepository.findTop5BySessionLearnerLearnerIdAndWordWordIdOrderByRecordedAtDesc(learnerId, w.getWordId());
            if (recentResults.isEmpty()) {
                continue;
            }
            long correctCount = recentResults.stream().filter(r -> Boolean.TRUE.equals(r.getIsCorrect())).count();
            double recentAccuracy = (double) correctCount / recentResults.size() * 100.0;
            if (recentAccuracy < 70.0) {
                weakWords.add(w);
            } else {
                knownWords.add(w);
            }
        }

        Set<String> pool = new LinkedHashSet<>();
        
        for (VocabularyWord w : weakWords) {
            if (!w.getWordId().equals(target.getWordId()) && !w.getEnglishWord().equalsIgnoreCase(target.getEnglishWord())) {
                pool.add(w.getEnglishWord());
            }
        }
        for (VocabularyWord w : knownWords) {
            if (!w.getWordId().equals(target.getWordId()) && !w.getEnglishWord().equalsIgnoreCase(target.getEnglishWord())) {
                pool.add(w.getEnglishWord());
            }
        }
        
        List<VocabularyWord> lessonWords = wordRepository.findByLessonLessonIdOrderByWordOrderAsc(target.getLesson().getLessonId()).stream()
                .filter(w -> posFocus == null || "ALL".equalsIgnoreCase(posFocus) || posFocus.equalsIgnoreCase(w.getPartOfSpeech()))
                .collect(java.util.stream.Collectors.toList());
        for (VocabularyWord w : lessonWords) {
            if (!w.getWordId().equals(target.getWordId()) && !w.getEnglishWord().equalsIgnoreCase(target.getEnglishWord())) {
                pool.add(w.getEnglishWord());
            }
        }

        List<String> staticFallback = Arrays.asList("banana", "house", "dog", "cat", "sun", "moon", "hand", "child", "eye", "stomach");
        for (String val : staticFallback) {
            if (!val.equalsIgnoreCase(target.getEnglishWord())) {
                pool.add(val);
            }
        }

        int needed = count - csvDistractors.size();
        List<String> additional = selectDistractors(target.getEnglishWord(), new ArrayList<>(pool), level, needed);

        List<String> combined = new ArrayList<>(csvDistractors);
        combined.addAll(additional);
        return combined;
    }

    private static class DistractorScore {
        String word;
        int score;
        DistractorScore(String word, int score) { this.word = word; this.score = score; }
    }

    private int levenshteinDistance(String a, String b) {
        a = a.toLowerCase();
        b = b.toLowerCase();
        int[] costs = new int[b.length() + 1];
        for (int j = 0; j < costs.length; j++) costs[j] = j;
        for (int i = 1; i <= a.length(); i++) {
            costs[0] = i;
            int nw = i - 1;
            for (int j = 1; j <= b.length(); j++) {
                int cj = Math.min(1 + Math.min(costs[j], costs[j - 1]), a.charAt(i - 1) == b.charAt(j - 1) ? nw : nw + 1);
                nw = costs[j];
                costs[j] = cj;
            }
        }
        return costs[b.length()];
    }

    private List<String> selectDistractors(String targetWord, List<String> distractorPool, DifficultyLevel level, int count) {
        List<DistractorScore> ranked = new ArrayList<>();
        for (String distractor : distractorPool) {
            int lenDiff = Math.abs(targetWord.length() - distractor.length());
            int editDist = levenshteinDistance(targetWord, distractor);
            int firstLetterBonus = 0;
            if (!targetWord.isEmpty() && !distractor.isEmpty() && 
                Character.toLowerCase(targetWord.charAt(0)) == Character.toLowerCase(distractor.charAt(0))) {
                firstLetterBonus = -2;
            }
            int score = editDist + lenDiff + firstLetterBonus;
            ranked.add(new DistractorScore(distractor, score));
        }
        
        ranked.sort(Comparator.comparingInt(a -> a.score));
        int poolSize = ranked.size();
        int actualCount = Math.min(count, poolSize);
        if (actualCount == 0) return Collections.emptyList();
        
        List<DistractorScore> candidateBand;
        if (level == DifficultyLevel.LEARNING || level == DifficultyLevel.FAMILIAR) {
            int startIdx = poolSize / 2;
            int endIdx = poolSize;
            candidateBand = new ArrayList<>(ranked.subList(startIdx, endIdx));
        } else {
            int startIdx = 0;
            int endIdx = Math.max(actualCount, (int) Math.ceil(poolSize / 2.0));
            candidateBand = new ArrayList<>(ranked.subList(startIdx, Math.min(endIdx, poolSize)));
        }
        
        if (candidateBand.size() < actualCount) {
            candidateBand = new ArrayList<>(ranked);
        }
        
        Collections.shuffle(candidateBand);
        List<String> result = new ArrayList<>();
        for (int i = 0; i < actualCount; i++) {
            result.add(candidateBand.get(i).word);
        }
        return result;
    }
}
