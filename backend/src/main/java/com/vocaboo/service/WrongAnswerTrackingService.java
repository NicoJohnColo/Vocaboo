package com.vocaboo.service;

import com.vocaboo.entity.Learner;
import com.vocaboo.entity.VocabularyWord;
import com.vocaboo.entity.WrongAnswerRecord;
import com.vocaboo.repository.LearnerRepository;
import com.vocaboo.repository.VocabularyWordRepository;
import com.vocaboo.repository.WrongAnswerRecordRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class WrongAnswerTrackingService {

    private final WrongAnswerRecordRepository recordRepository;
    private final LearnerRepository learnerRepository;
    private final VocabularyWordRepository wordRepository;

    @Transactional
    public void trackWrongAnswer(UUID learnerId, UUID wordId, String wrongAnswer, String activityFormat) {
        Learner learner = learnerRepository.findById(learnerId).orElse(null);
        VocabularyWord word = wordRepository.findById(wordId).orElse(null);
        if (learner == null || word == null) {
            return;
        }
        WrongAnswerRecord record = WrongAnswerRecord.builder()
                .learner(learner)
                .word(word)
                .wrongAnswer(wrongAnswer != null ? wrongAnswer : "")
                .activityFormat(activityFormat != null ? activityFormat : "")
                .build();
        recordRepository.save(record);
    }
}
