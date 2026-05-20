package com.vocaboo.dto.response;

import com.vocaboo.entity.LanguageMedium;
import lombok.*;
import java.util.UUID;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class AuthResponse {
    private String token;
    private UUID learnerId;
    private String displayName;
    private Boolean onboardingComplete;
    private LanguageMedium languagePreference;
}
