package com.vocaboo.entity;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
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
@JsonIgnoreProperties({"hibernateLazyInitializer", "handler"})
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

    /** Eligible activity types for this word (semicolon-separated).
     *  e.g. MULTIPLE_CHOICE;FILL_IN_BLANK;MATCHING;SENTENCE_ARRANGEMENT;WORD_SCRAMBLE;IMAGE_LABELING;TRUE_OR_FALSE
     *  Determines which activity formats the learner sees across all difficulty tiers.
     */
    @Column(name = "eligible_activity_types", nullable = false, length = 255)
    @Builder.Default
    private String eligibleActivityTypes = "MULTIPLE_CHOICE;FILL_IN_BLANK;MATCHING;SENTENCE_ARRANGEMENT;WORD_SCRAMBLE;IMAGE_LABELING;TRUE_OR_FALSE";

    public String getActivityType() {
        if (eligibleActivityTypes == null || eligibleActivityTypes.isBlank()) return "MULTIPLE_CHOICE";
        return eligibleActivityTypes.split(";")[0];
    }

    @JsonIgnoreProperties({"hibernateLazyInitializer", "handler", "category", "vocabularyWords"})
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

    // ── Admin Content Management Fields ──────────────────────────────────────

    @Column(name = "is_deleted", nullable = false)
    @Builder.Default
    private Boolean isDeleted = false;

    @Column(name = "audio_verified", nullable = false)
    @Builder.Default
    private Boolean audioVerified = false;

    @Column(name = "image_verified", nullable = false)
    @Builder.Default
    private Boolean imageVerified = false;

    // ── Per-word Activity Content Fields ─────────────────────────────────────

    /** Comma-separated wrong-answer candidates (same POS), e.g. "eraser,ruler,scissors" */
    @Column(name = "distractor_pool", columnDefinition = "TEXT")
    private String distractorPool;

    /** Sentence with {BLANK} placeholder for Fill-in-the-Blank, e.g. "I sharpen my {BLANK}." */
    @Column(name = "fill_blank_sentence", columnDefinition = "TEXT")
    private String fillBlankSentence;

    /** Full correct sentence for Word Tile Arrangement (app scrambles at runtime) */
    @Column(name = "tile_sentence", columnDefinition = "TEXT")
    private String tileSentence;

    /** Optional hint shown only at LEARNING difficulty level */
    @Column(name = "explanation_text", columnDefinition = "TEXT")
    private String explanationText;

    /** Exact text fed to Cebuano TTS (distinct from audio_asset_path file path) */
    @Column(name = "audio_text_cebuano", columnDefinition = "TEXT")
    private String audioTextCebuano;

    /** Exact text fed to English TTS */
    @Column(name = "audio_text_english", columnDefinition = "TEXT")
    private String audioTextEnglish;

    public Lesson getLesson() {
        return lesson;
    }

    public UUID getWordId() {
        return wordId;
    }

    public String getEnglishWord() {
        return englishWord;
    }

    public String getCebuanoMeaning() {
        return cebuanoMeaning;
    }

    public GradeLevel getGradeLevel() {
        return gradeLevel;
    }

    public Boolean getIsDeleted() {
        return isDeleted;
    }

    public String getPartOfSpeech() { return partOfSpeech; }
    public Integer getWordOrder() { return wordOrder; }
    public String getExampleSentenceEnglish() { return exampleSentenceEnglish; }
    public String getExampleSentenceCebuano() { return exampleSentenceCebuano; }
    public String getAudioAssetPath() { return audioAssetPath; }
    public String getImageAssetPath() { return imageAssetPath; }
    public Boolean getAudioVerified() { return audioVerified; }
    public Boolean getImageVerified() { return imageVerified; }
    public Boolean getIsConfusablePairMember() { return isConfusablePairMember; }
    public String getPhonologicalTipKey() { return phonologicalTipKey; }
    public OffsetDateTime getCreatedAt() { return createdAt; }
    public OffsetDateTime getUpdatedAt() { return updatedAt; }
    public String getDistractorPool() { return distractorPool; }
    public String getFillBlankSentence() { return fillBlankSentence; }
    public String getTileSentence() { return tileSentence; }
    public String getExplanationText() { return explanationText; }
    public String getAudioTextCebuano() { return audioTextCebuano; }
    public String getAudioTextEnglish() { return audioTextEnglish; }
    public String getEligibleActivityTypes() { return eligibleActivityTypes; }

    public void setEnglishWord(String englishWord) { this.englishWord = englishWord; }
    public void setCebuanoMeaning(String cebuanoMeaning) { this.cebuanoMeaning = cebuanoMeaning; }
    public void setPartOfSpeech(String partOfSpeech) { this.partOfSpeech = partOfSpeech; }
    public void setExampleSentenceEnglish(String exampleSentenceEnglish) { this.exampleSentenceEnglish = exampleSentenceEnglish; }
    public void setExampleSentenceCebuano(String exampleSentenceCebuano) { this.exampleSentenceCebuano = exampleSentenceCebuano; }
    public void setAudioAssetPath(String audioAssetPath) { this.audioAssetPath = audioAssetPath; }
    public void setImageAssetPath(String imageAssetPath) { this.imageAssetPath = imageAssetPath; }
    public void setDistractorPool(String distractorPool) { this.distractorPool = distractorPool; }
    public void setFillBlankSentence(String fillBlankSentence) { this.fillBlankSentence = fillBlankSentence; }
    public void setTileSentence(String tileSentence) { this.tileSentence = tileSentence; }
    public void setExplanationText(String explanationText) { this.explanationText = explanationText; }
    public void setAudioTextCebuano(String audioTextCebuano) { this.audioTextCebuano = audioTextCebuano; }
    public void setAudioTextEnglish(String audioTextEnglish) { this.audioTextEnglish = audioTextEnglish; }
    public void setEligibleActivityTypes(String eligibleActivityTypes) { this.eligibleActivityTypes = eligibleActivityTypes; }
    public void setPhonologicalTipKey(String phonologicalTipKey) { this.phonologicalTipKey = phonologicalTipKey; }
    public void setIsConfusablePairMember(Boolean isConfusablePairMember) { this.isConfusablePairMember = isConfusablePairMember; }

    public static VocabularyWordBuilder builder() {
        return new VocabularyWordBuilder();
    }

    public static class VocabularyWordBuilder {
        private Lesson lesson;
        private String englishWord;
        private String cebuanoMeaning;
        private String exampleSentenceEnglish;
        private String exampleSentenceCebuano;
        private GradeLevel gradeLevel;
        private Integer wordOrder = 1;
        private String partOfSpeech;
        private String audioAssetPath;
        private String imageAssetPath;
        private String distractorPool;
        private String fillBlankSentence;
        private String tileSentence;
        private String explanationText;
        private String audioTextCebuano;
        private String audioTextEnglish;
        private String phonologicalTipKey;
        private Boolean isConfusablePairMember = false;
        private Boolean isDeleted = false;
        private String eligibleActivityTypes;

        public VocabularyWordBuilder lesson(Lesson lesson) { this.lesson = lesson; return this; }
        public VocabularyWordBuilder englishWord(String englishWord) { this.englishWord = englishWord; return this; }
        public VocabularyWordBuilder cebuanoMeaning(String cebuanoMeaning) { this.cebuanoMeaning = cebuanoMeaning; return this; }
        public VocabularyWordBuilder exampleSentenceEnglish(String exampleSentenceEnglish) { this.exampleSentenceEnglish = exampleSentenceEnglish; return this; }
        public VocabularyWordBuilder exampleSentenceCebuano(String exampleSentenceCebuano) { this.exampleSentenceCebuano = exampleSentenceCebuano; return this; }
        public VocabularyWordBuilder gradeLevel(GradeLevel gradeLevel) { this.gradeLevel = gradeLevel; return this; }
        public VocabularyWordBuilder wordOrder(Integer wordOrder) { this.wordOrder = wordOrder; return this; }
        public VocabularyWordBuilder partOfSpeech(String partOfSpeech) { this.partOfSpeech = partOfSpeech; return this; }
        public VocabularyWordBuilder audioAssetPath(String audioAssetPath) { this.audioAssetPath = audioAssetPath; return this; }
        public VocabularyWordBuilder imageAssetPath(String imageAssetPath) { this.imageAssetPath = imageAssetPath; return this; }
        public VocabularyWordBuilder distractorPool(String distractorPool) { this.distractorPool = distractorPool; return this; }
        public VocabularyWordBuilder fillBlankSentence(String fillBlankSentence) { this.fillBlankSentence = fillBlankSentence; return this; }
        public VocabularyWordBuilder tileSentence(String tileSentence) { this.tileSentence = tileSentence; return this; }
        public VocabularyWordBuilder explanationText(String explanationText) { this.explanationText = explanationText; return this; }
        public VocabularyWordBuilder audioTextCebuano(String audioTextCebuano) { this.audioTextCebuano = audioTextCebuano; return this; }
        public VocabularyWordBuilder audioTextEnglish(String audioTextEnglish) { this.audioTextEnglish = audioTextEnglish; return this; }
        public VocabularyWordBuilder phonologicalTipKey(String phonologicalTipKey) { this.phonologicalTipKey = phonologicalTipKey; return this; }
        public VocabularyWordBuilder isConfusablePairMember(Boolean isConfusablePairMember) { this.isConfusablePairMember = isConfusablePairMember; return this; }
        public VocabularyWordBuilder isDeleted(Boolean isDeleted) { this.isDeleted = isDeleted; return this; }
        public VocabularyWordBuilder eligibleActivityTypes(String eligibleActivityTypes) { this.eligibleActivityTypes = eligibleActivityTypes; return this; }

        public VocabularyWord build() {
            VocabularyWord w = new VocabularyWord();
            w.lesson = this.lesson;
            w.englishWord = this.englishWord;
            w.cebuanoMeaning = this.cebuanoMeaning;
            w.exampleSentenceEnglish = this.exampleSentenceEnglish;
            w.exampleSentenceCebuano = this.exampleSentenceCebuano;
            w.gradeLevel = this.gradeLevel;
            w.wordOrder = this.wordOrder;
            w.partOfSpeech = this.partOfSpeech;
            w.audioAssetPath = this.audioAssetPath;
            w.imageAssetPath = this.imageAssetPath;
            w.distractorPool = this.distractorPool;
            w.fillBlankSentence = this.fillBlankSentence;
            w.tileSentence = this.tileSentence;
            w.explanationText = this.explanationText;
            w.audioTextCebuano = this.audioTextCebuano;
            w.audioTextEnglish = this.audioTextEnglish;
            w.phonologicalTipKey = this.phonologicalTipKey;
            w.isConfusablePairMember = this.isConfusablePairMember != null ? this.isConfusablePairMember : false;
            w.isDeleted = this.isDeleted != null ? this.isDeleted : false;
            w.createdAt = OffsetDateTime.now();
            w.updatedAt = OffsetDateTime.now();
            return w;
        }
    }

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
