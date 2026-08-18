package com.vocaboo.dto.response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.math.BigDecimal;
import java.time.OffsetDateTime;
import java.util.UUID;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class RecentWordProgressResponse {
    private UUID wordId;
    private String englishWord;
    private String cebuanoMeaning;
    private BigDecimal accuracy;
    private String currentLevel; // 'LEARNING', 'FAMILIAR', 'PROFICIENT', 'MASTERED'
    private String partOfSpeech;
    private OffsetDateTime lastPracticedAt;
}
