package com.vocaboo.service;

import com.vocaboo.entity.VocabularyWord;
import com.vocaboo.entity.WordPerformance;
import com.vocaboo.repository.WordPerformanceRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import java.util.Comparator;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class DynamicReviewSequenceService {

    private final WordPerformanceRepository performanceRepository;

    public List<VocabularyWord> prioritizeWords(UUID learnerId, List<VocabularyWord> words) {
        if (words == null || words.isEmpty()) {
            return List.of();
        }

        return words.stream()
                .sorted((w1, w2) -> {
                    WordPerformance p1 = performanceRepository.findByLearnerLearnerIdAndWordWordId(learnerId, w1.getWordId())
                            .orElse(null);
                    WordPerformance p2 = performanceRepository.findByLearnerLearnerIdAndWordWordId(learnerId, w2.getWordId())
                            .orElse(null);

                    int demerits1 = p1 != null && p1.getDemeritPoints() != null ? p1.getDemeritPoints() : (p1 != null ? p1.getIncorrectCount() * 2 : 0);
                    int demerits2 = p2 != null && p2.getDemeritPoints() != null ? p2.getDemeritPoints() : (p2 != null ? p2.getIncorrectCount() * 2 : 0);

                    // Most demerits first
                    return Integer.compare(demerits2, demerits1);
                })
                .collect(Collectors.toList());
    }
}
