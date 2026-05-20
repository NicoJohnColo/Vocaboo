package com.vocaboo.dto.response;

import com.vocaboo.entity.LanguageMedium;
import lombok.*;
import java.util.UUID;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class LearnerResponse {
    private UUID learnerId;
    private String displayName;
    private Integer age;
    private LanguageMedium languagePreference;
    private Boolean onboardingComplete;
}
