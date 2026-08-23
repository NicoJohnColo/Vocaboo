package com.vocaboo.dto.request;

import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import java.util.UUID;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class RetrievalSubmissionRequest {
    private UUID wordId;
    private Boolean correct;
    private String wrongAnswer;
    private String activityFormat;

    public UUID getWordId() { return wordId; }
    public Boolean getCorrect() { return correct; }
    public String getWrongAnswer() { return wrongAnswer; }
    public String getActivityFormat() { return activityFormat; }
}
