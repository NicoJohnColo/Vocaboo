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
    private Boolean masteryApplyImmediately;
    private String posFocus;

    public static LearnerResponseBuilder builder() { return new LearnerResponseBuilder(); }

    public static class LearnerResponseBuilder {
        private UUID learnerId;
        private String displayName;
        private Integer age;
        private LanguageMedium languagePreference;
        private Boolean onboardingComplete;
        private Boolean masteryApplyImmediately;
        private String posFocus;

        public LearnerResponseBuilder learnerId(UUID learnerId) { this.learnerId = learnerId; return this; }
        public LearnerResponseBuilder displayName(String displayName) { this.displayName = displayName; return this; }
        public LearnerResponseBuilder age(Integer age) { this.age = age; return this; }
        public LearnerResponseBuilder languagePreference(LanguageMedium languagePreference) { this.languagePreference = languagePreference; return this; }
        public LearnerResponseBuilder onboardingComplete(Boolean onboardingComplete) { this.onboardingComplete = onboardingComplete; return this; }
        public LearnerResponseBuilder masteryApplyImmediately(Boolean masteryApplyImmediately) { this.masteryApplyImmediately = masteryApplyImmediately; return this; }
        public LearnerResponseBuilder posFocus(String posFocus) { this.posFocus = posFocus; return this; }

        public LearnerResponse build() {
            LearnerResponse r = new LearnerResponse();
            r.learnerId = this.learnerId;
            r.displayName = this.displayName;
            r.age = this.age;
            r.languagePreference = this.languagePreference;
            r.onboardingComplete = this.onboardingComplete;
            r.masteryApplyImmediately = this.masteryApplyImmediately;
            r.posFocus = this.posFocus;
            return r;
        }
    }
}
