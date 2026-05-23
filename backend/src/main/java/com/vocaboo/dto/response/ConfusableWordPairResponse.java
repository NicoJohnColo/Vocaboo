package com.vocaboo.dto.response;

import lombok.*;
import java.util.UUID;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ConfusableWordPairResponse {
    private UUID pairId;
    private UUID lessonId;
    private VocabularyWordResponse wordA;
    private VocabularyWordResponse wordB;
    private String contrastiveSentenceA;
    private String contrastiveSentenceB;
}
