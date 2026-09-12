package com.vocaboo.dto.response;

import com.vocaboo.entity.LanguageMedium;
import com.vocaboo.entity.GradeLevel;
import lombok.*;
import java.util.UUID;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class LearnerResponse {
    private UUID learnerId;
    @com.fasterxml.jackson.annotation.JsonProperty("user_id")
    private String userId;
    private String displayName;
    private Integer age;
    private LanguageMedium languagePreference;
    private GradeLevel gradeLevel;
    private Boolean onboardingComplete;
    private Boolean masteryApplyImmediately;
    private String posFocus;
    private String avatar;

    public static LearnerResponseBuilder builder() { return new LearnerResponseBuilder(); }

    public static class LearnerResponseBuilder {
        private UUID learnerId;
        private String userId;
        private String displayName;
        private Integer age;
        private LanguageMedium languagePreference;
        private GradeLevel gradeLevel;
        private Boolean onboardingComplete;
        private Boolean masteryApplyImmediately;
        private String posFocus;
        private String avatar;

        public LearnerResponseBuilder learnerId(UUID learnerId) { this.learnerId = learnerId; return this; }
        public LearnerResponseBuilder userId(String userId) { this.userId = userId; return this; }
        public LearnerResponseBuilder displayName(String displayName) { this.displayName = displayName; return this; }
        public LearnerResponseBuilder age(Integer age) { this.age = age; return this; }
        public LearnerResponseBuilder languagePreference(LanguageMedium languagePreference) { this.languagePreference = languagePreference; return this; }
        public LearnerResponseBuilder gradeLevel(GradeLevel gradeLevel) { this.gradeLevel = gradeLevel; return this; }
        public LearnerResponseBuilder onboardingComplete(Boolean onboardingComplete) { this.onboardingComplete = onboardingComplete; return this; }
        public LearnerResponseBuilder masteryApplyImmediately(Boolean masteryApplyImmediately) { this.masteryApplyImmediately = masteryApplyImmediately; return this; }
        public LearnerResponseBuilder posFocus(String posFocus) { this.posFocus = posFocus; return this; }
        public LearnerResponseBuilder avatar(String avatar) { this.avatar = avatar; return this; }

        public LearnerResponse build() {
            LearnerResponse r = new LearnerResponse();
            r.learnerId = this.learnerId;
            r.userId = this.userId;
            r.displayName = this.displayName;
            r.age = this.age;
            r.languagePreference = this.languagePreference;
            r.gradeLevel = this.gradeLevel;
            r.onboardingComplete = this.onboardingComplete;
            r.masteryApplyImmediately = this.masteryApplyImmediately;
            r.posFocus = this.posFocus;
            r.avatar = this.avatar != null ? this.avatar : "prof1.jpg";
            return r;
        }
    }
}
