package com.vocaboo.service;

import com.vocaboo.entity.Learner;
import com.vocaboo.entity.ReinforcementQueueItem;
import com.vocaboo.entity.VocabularyWord;
import com.vocaboo.repository.LearnerRepository;
import com.vocaboo.repository.ReinforcementQueueRepository;
import com.vocaboo.repository.VocabularyWordRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.time.OffsetDateTime;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class ReinforcementEngineService {

    private final ReinforcementQueueRepository queueRepository;
    private final LearnerRepository learnerRepository;
    private final VocabularyWordRepository wordRepository;

    @Transactional
    public void enqueue(UUID learnerId, UUID wordId) {
        ReinforcementQueueItem item = queueRepository.findByLearnerLearnerIdAndWordWordId(learnerId, wordId)
                .orElseGet(() -> {
                    Learner learner = learnerRepository.findById(learnerId)
                            .orElseThrow(() -> new IllegalArgumentException("Learner not found"));
                    VocabularyWord word = wordRepository.findById(wordId)
                            .orElseThrow(() -> new IllegalArgumentException("Word not found"));
                    return ReinforcementQueueItem.builder()
                            .learner(learner)
                            .word(word)
                            .attemptsCount(0)
                            .isResolved(false)
                            .build();
                });

        item.setIsResolved(false);
        item.setScheduledAt(OffsetDateTime.now());
        item.setAttemptsCount(0); // Reset count to track new reinforcement progress
        queueRepository.save(item);
    }

    @Transactional
    public void resolve(UUID learnerId, UUID wordId) {
        queueRepository.findByLearnerLearnerIdAndWordWordId(learnerId, wordId).ifPresent(item -> {
            if (!item.getIsResolved()) {
                item.setAttemptsCount(item.getAttemptsCount() + 1);
                // Requires 2 consecutive correct answers in spaced review to be resolved
                if (item.getAttemptsCount() >= 2) {
                    item.setIsResolved(true);
                }
                queueRepository.save(item);
            }
        });
    }
}
