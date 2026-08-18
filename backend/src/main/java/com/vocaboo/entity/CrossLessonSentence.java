package com.vocaboo.entity;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import jakarta.persistence.*;
import lombok.*;
import java.time.OffsetDateTime;
import java.util.UUID;

@Entity
@Table(name = "cross_lesson_sentences")
@JsonIgnoreProperties({"hibernateLazyInitializer", "handler"})
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class CrossLessonSentence {

    @Id
    @GeneratedValue(strategy = GenerationType.AUTO)
    private UUID id;

    @Column(name = "sentence_text", nullable = false, columnDefinition = "TEXT")
    private String sentenceText;

    @Column(name = "sentence_translation", nullable = false, columnDefinition = "TEXT")
    private String sentenceTranslation;

    @JsonIgnoreProperties({"hibernateLazyInitializer", "handler", "lesson"})
    @ManyToOne(fetch = FetchType.EAGER)
    @JoinColumn(name = "word_a_id", nullable = false)
    private VocabularyWord wordA;

    @JsonIgnoreProperties({"hibernateLazyInitializer", "handler", "lesson"})
    @ManyToOne(fetch = FetchType.EAGER)
    @JoinColumn(name = "word_b_id", nullable = false)
    private VocabularyWord wordB;

    @Column(name = "lesson_pair_id", nullable = false, length = 100)
    private String lessonPairId;

    @Column(name = "created_at", updatable = false)
    @Builder.Default
    private OffsetDateTime createdAt = OffsetDateTime.now();

    @Column(name = "created_by")
    private UUID createdBy;
}
