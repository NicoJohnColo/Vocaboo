package com.vocaboo.dto.request;

import jakarta.validation.constraints.Pattern;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class RespondInvitationRequest {

    @Pattern(regexp = "ACCEPTED|DECLINED", message = "status must be ACCEPTED or DECLINED")
    private String status;
}
