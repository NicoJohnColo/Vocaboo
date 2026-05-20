package com.vocaboo.dto.response;

import lombok.*;
import java.time.OffsetDateTime;
import java.util.Map;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ApiErrorResponse {
    private Integer status;
    private String message;
    private Map<String, String> fieldErrors;
    @Builder.Default
    private OffsetDateTime timestamp = OffsetDateTime.now();
}
