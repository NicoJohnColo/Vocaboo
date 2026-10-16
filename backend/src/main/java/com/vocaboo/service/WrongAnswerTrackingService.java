package com.vocaboo.service;

import com.vocaboo.entity.ConfusableWordPair;
import com.vocaboo.entity.Learner;
import com.vocaboo.entity.VocabularyWord;
import com.vocaboo.entity.WrongAnswerRecord;
import com.vocaboo.repository.ConfusableWordPairRepository;
import com.vocaboo.repository.LearnerRepository;
import com.vocaboo.repository.VocabularyWordRepository;
import com.vocaboo.repository.WrongAnswerRecordRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class WrongAnswerTrackingService {

    private final WrongAnswerRecordRepository recordRepository;
    private final LearnerRepository learnerRepository;
    private final VocabularyWordRepository wordRepository;
    private final ConfusableWordPairRepository confusableWordPairRepository;

    @Transactional
    public void trackWrongAnswer(UUID learnerId, UUID wordId, String wrongAnswer, String activityFormat) {
        trackWrongAnswer(learnerId, wordId, wrongAnswer, activityFormat, null);
    }

    @Transactional
    public void trackWrongAnswer(UUID learnerId, UUID wordId, String wrongAnswer, String activityFormat, String explicitErrorType) {
        Learner learner = learnerRepository.findById(learnerId).orElse(null);
        VocabularyWord word = wordRepository.findById(wordId).orElse(null);
        if (learner == null || word == null) {
            return;
        }
        String resolvedErrorType = resolveErrorType(word, wrongAnswer, activityFormat, explicitErrorType);
        WrongAnswerRecord record = WrongAnswerRecord.builder()
                .learner(learner)
                .word(word)
                .wrongAnswer(wrongAnswer != null ? wrongAnswer : "")
                .activityFormat(activityFormat != null ? activityFormat : "")
                .errorType(resolvedErrorType)
                .build();
        recordRepository.save(record);
    }

    private String resolveErrorType(VocabularyWord word, String wrongAnswer, String activityFormat, String explicitErrorType) {
        if (explicitErrorType != null && !explicitErrorType.isBlank()) {
            return explicitErrorType.trim().toUpperCase();
        }
        if (activityFormat != null) {
            String upperFmt = activityFormat.toUpperCase();
            if (upperFmt.contains("PRONUNCIATION") || upperFmt.contains("SPEAK") || upperFmt.contains("VOICE")) {
                return WrongAnswerRecord.ERROR_PHONETIC_MISPRONUNCIATION;
            }
        }
        if (wrongAnswer != null && !wrongAnswer.isBlank()) {
            String cleanWrong = wrongAnswer.trim();
            List<ConfusableWordPair> pairs = confusableWordPairRepository.findByWordAWordIdOrWordBWordId(word.getWordId(), word.getWordId());
            for (ConfusableWordPair pair : pairs) {
                if (pair.getWordA() != null && pair.getWordA().getEnglishWord() != null
                        && pair.getWordA().getEnglishWord().equalsIgnoreCase(cleanWrong)) {
                    return WrongAnswerRecord.ERROR_CONFUSABLE_PAIR;
                }
                if (pair.getWordB() != null && pair.getWordB().getEnglishWord() != null
                        && pair.getWordB().getEnglishWord().equalsIgnoreCase(cleanWrong)) {
                    return WrongAnswerRecord.ERROR_CONFUSABLE_PAIR;
                }
            }
            if (word.getEnglishWord() != null && levenshteinDistance(word.getEnglishWord().toLowerCase(), cleanWrong.toLowerCase()) <= 2) {
                return WrongAnswerRecord.ERROR_NEAR_MISS_SPELLING;
            }
        }
        return WrongAnswerRecord.ERROR_INCORRECT_CHOICE;
    }

    private int levenshteinDistance(String a, String b) {
        int[][] dp = new int[a.length() + 1][b.length() + 1];
        for (int i = 0; i <= a.length(); i++) dp[i][0] = i;
        for (int j = 0; j <= b.length(); j++) dp[0][j] = j;
        for (int i = 1; i <= a.length(); i++) {
            for (int j = 1; j <= b.length(); j++) {
                int cost = a.charAt(i - 1) == b.charAt(j - 1) ? 0 : 1;
                dp[i][j] = Math.min(Math.min(dp[i - 1][j] + 1, dp[i][j - 1] + 1), dp[i - 1][j - 1] + cost);
            }
        }
        return dp[a.length()][b.length()];
    }
}
