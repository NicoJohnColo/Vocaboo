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
public class ReviewJoinRequestDto {

    @Pattern(regexp = "APPROVED|REJECTED", message = "status must be APPROVED or REJECTED")
    private String status;
}
