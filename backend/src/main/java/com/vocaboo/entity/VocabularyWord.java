package com.vocaboo.entity;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.JdbcType;
import org.hibernate.dialect.PostgreSQLEnumJdbcType;
import java.time.OffsetDateTime;
import java.util.UUID;

@Entity
@Table(
    name = "vocabulary_words",
    uniqueConstraints = {
        @UniqueConstraint(columnNames = {"lesson_id", "word_order"})
    }
)
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class VocabularyWord {

    @Id
    @GeneratedValue(strategy = GenerationType.AUTO)
    @Column(name = "word_id", updatable = false, nullable = false)
    private UUID wordId;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "lesson_id", nullable = false)
    private Lesson lesson;

    @Column(name = "english_word", nullable = false, length = 100)
    private String englishWord;

    @Column(name = "cebuano_meaning", nullable = false, columnDefinition = "TEXT")
    private String cebuanoMeaning;

    @Column(name = "example_sentence_english", nullable = false, columnDefinition = "TEXT")
    private String exampleSentenceEnglish;

    @Column(name = "example_sentence_cebuano", columnDefinition = "TEXT")
    private String exampleSentenceCebuano;

    @Column(name = "audio_asset_path", columnDefinition = "TEXT")
    private String audioAssetPath;

    @Column(name = "image_asset_path", columnDefinition = "TEXT")
    private String imageAssetPath;

    @Column(name = "part_of_speech", length = 50)
    private String partOfSpeech;

    @Enumerated(EnumType.STRING)
    @JdbcType(PostgreSQLEnumJdbcType.class)
    @Column(name = "grade_level", nullable = false, columnDefinition = "grade_level_enum")
    private GradeLevel gradeLevel;

    @Column(name = "word_order", nullable = false)
    private Integer wordOrder;

    @Column(name = "is_confusable_pair_member", nullable = false)
    @Builder.Default
    private Boolean isConfusablePairMember = false;

    @Column(name = "phonological_tip_key", length = 100)
    private String phonologicalTipKey;

    @Column(name = "created_at", updatable = false)
    @Builder.Default
    private OffsetDateTime createdAt = OffsetDateTime.now();

    @Column(name = "updated_at")
    @Builder.Default
    private OffsetDateTime updatedAt = OffsetDateTime.now();

    @PrePersist
    protected void onCreate() {
        createdAt = OffsetDateTime.now();
        updatedAt = OffsetDateTime.now();
    }

    @PreUpdate
    protected void onUpdate() {
        updatedAt = OffsetDateTime.now();
    }
}
