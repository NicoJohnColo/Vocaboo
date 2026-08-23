package com.vocaboo.dto.request;

import com.fasterxml.jackson.annotation.JsonProperty;
import com.vocaboo.entity.GradeLevel;
import com.vocaboo.entity.LanguageMedium;
import lombok.*;

import java.util.UUID;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class UpdateLearnerAdminRequest {

    @JsonProperty("display_name")
    private String displayName;

    @JsonProperty("age")
    private Integer age;

    @JsonProperty("grade_level")
    private GradeLevel gradeLevel;

    @JsonProperty("section_id")
    private UUID sectionId;

    @JsonProperty("language_preference")
    private LanguageMedium languagePreference;

    @JsonProperty("pos_focus")
    private String posFocus;

    @JsonProperty("is_active")
    private Boolean isActive;
}
