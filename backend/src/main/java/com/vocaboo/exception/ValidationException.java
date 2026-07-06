package com.vocaboo.exception;

import lombok.Getter;
import java.util.List;
import java.util.Map;

/**
 * Thrown when one or more input validation rules fail.
 * Carries a list of field-level error details for API response.
 */
@Getter
public class ValidationException extends RuntimeException {

    private final List<Map<String, String>> details;

    public ValidationException(String field, String message) {
        super("Validation failed");
        this.details = List.of(Map.of("field", field, "error", message));
    }

    public ValidationException(List<Map<String, String>> details) {
        super("Validation failed");
        this.details = details;
    }
}
