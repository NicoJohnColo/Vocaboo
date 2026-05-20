package com.vocaboo.dto.request;

import com.vocaboo.entity.LanguageMedium;
import jakarta.validation.constraints.*;
import lombok.*;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class RegisterRequest {

    @NotBlank(message = "Display name is required")
    @Size(max = 100, message = "Display name cannot exceed 100 characters")
    private String displayName;

    @NotNull(message = "Age is required")
    @Min(value = 9, message = "Age must be between 9 and 12")
    @Max(value = 12, message = "Age must be between 9 and 12")
    private Integer age;

    @NotBlank(message = "PIN is required")
    @Pattern(regexp = "^\\d{4}$", message = "PIN must be exactly 4 digits")
    private String pin;

    @NotNull(message = "Language preference is required")
    private LanguageMedium languagePreference;
}
