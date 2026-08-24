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

    public static ApiErrorResponseBuilder builder() { return new ApiErrorResponseBuilder(); }

    public static class ApiErrorResponseBuilder {
        private Integer status;
        private String message;
        private Map<String, String> fieldErrors;
        private OffsetDateTime timestamp;

        public ApiErrorResponseBuilder status(Integer status) { this.status = status; return this; }
        public ApiErrorResponseBuilder message(String message) { this.message = message; return this; }
        public ApiErrorResponseBuilder fieldErrors(Map<String, String> fieldErrors) { this.fieldErrors = fieldErrors; return this; }
        public ApiErrorResponseBuilder timestamp(OffsetDateTime timestamp) { this.timestamp = timestamp; return this; }

        public ApiErrorResponse build() {
            ApiErrorResponse r = new ApiErrorResponse();
            r.status = this.status;
            r.message = this.message;
            r.fieldErrors = this.fieldErrors;
            r.timestamp = this.timestamp != null ? this.timestamp : OffsetDateTime.now();
            return r;
        }
    }
}
