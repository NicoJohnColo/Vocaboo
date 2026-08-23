package com.vocaboo.dto.request;

import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.*;

import java.util.UUID;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class AssignSectionRequest {

    @JsonProperty("section_id")
    private UUID sectionId;
}
