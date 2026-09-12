package com.vocaboo.dto.request;

import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class InviteLearnerRequest {

    @NotNull(message = "learnerId is required")
    private String learnerId;

    public void setLearnerId(Object id) {
        if (id != null) {
            this.learnerId = id.toString();
        }
    }
}
