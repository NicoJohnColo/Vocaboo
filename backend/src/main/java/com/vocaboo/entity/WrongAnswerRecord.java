package com.vocaboo.entity;

import jakarta.persistence.*;
import lombok.*;
import java.time.OffsetDateTime;
import java.util.UUID;

@Entity
@Table(name = "wrong_answer_records")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class WrongAnswerRecord {

    @Id
    @GeneratedValue(strategy = GenerationType.AUTO)
    @Column(name = "record_id", updatable = false, nullable = false)
    private UUID recordId;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "learner_id", nullable = false)
    private Learner learner;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "word_id", nullable = false)
    private VocabularyWord word;

    @Column(name = "wrong_answer", nullable = false)
    private String wrongAnswer;

    @Column(name = "activity_format", nullable = false)
    private String activityFormat;

    @Column(name = "recorded_at", updatable = false)
    @Builder.Default
    private OffsetDateTime recordedAt = OffsetDateTime.now();

    @PrePersist
    protected void onCreate() {
        recordedAt = OffsetDateTime.now();
    }
}
