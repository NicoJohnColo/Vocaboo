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

    public static AuthResponseBuilder builder() { return new AuthResponseBuilder(); }

    public static class AuthResponseBuilder {
        private String token;
        private UUID learnerId;
        private String displayName;
        private Boolean onboardingComplete;
        private LanguageMedium languagePreference;

        public AuthResponseBuilder token(String token) { this.token = token; return this; }
        public AuthResponseBuilder learnerId(UUID learnerId) { this.learnerId = learnerId; return this; }
        public AuthResponseBuilder displayName(String displayName) { this.displayName = displayName; return this; }
        public AuthResponseBuilder onboardingComplete(Boolean onboardingComplete) { this.onboardingComplete = onboardingComplete; return this; }
        public AuthResponseBuilder languagePreference(LanguageMedium languagePreference) { this.languagePreference = languagePreference; return this; }

        public AuthResponse build() {
            AuthResponse r = new AuthResponse();
            r.token = this.token;
            r.learnerId = this.learnerId;
            r.displayName = this.displayName;
            r.onboardingComplete = this.onboardingComplete;
            r.languagePreference = this.languagePreference;
            return r;
        }
    }
}
