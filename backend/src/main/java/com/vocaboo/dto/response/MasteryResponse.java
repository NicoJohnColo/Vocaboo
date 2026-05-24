package com.vocaboo.dto.response;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class MasteryResponse {
    private boolean success;
    private String message;
    private double finalScore;
    private boolean passed;
    private int totalItems;
    private int masteredCount;
    private List<String> missedWordIds;
}
