package com.vocaboo.dto.response;

import com.vocaboo.entity.Pathway;
import com.vocaboo.entity.WordStatus;
import lombok.*;
import java.time.OffsetDateTime;
import java.util.UUID;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ProgressResponse {
    private UUID progressId;
    private UUID sessionId;
    private UUID wordId;
    private Pathway pathway;
    private Integer stepCompleted;
    private WordStatus status;
    private OffsetDateTime completedAt;
}
