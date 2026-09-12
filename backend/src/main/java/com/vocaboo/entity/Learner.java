package com.vocaboo.entity;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.JdbcType;
import org.hibernate.dialect.PostgreSQLEnumJdbcType;
import java.time.OffsetDateTime;
import java.util.UUID;

@Entity
@Table(name = "learners")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Learner {

    @Id
    @GeneratedValue(strategy = GenerationType.AUTO)
    @Column(name = "learner_id", updatable = false, nullable = false)
    private UUID learnerId;

    @Column(name = "user_id", unique = true, length = 11)
    private String userId;

    @Column(name = "display_name", nullable = false, length = 100)
    private String displayName;

    @Column(name = "age", nullable = false)
    private Integer age;

    @Column(name = "pin_hash", nullable = false, columnDefinition = "TEXT")
    private String pinHash;

    @Enumerated(EnumType.STRING)
    @JdbcType(PostgreSQLEnumJdbcType.class)
    @Column(name = "language_preference", nullable = false, columnDefinition = "language_medium_enum")
    private LanguageMedium languagePreference;

    @Column(name = "onboarding_complete", nullable = false)
    @Builder.Default
    private Boolean onboardingComplete = false;

    @Column(name = "mastery_apply_immediately", nullable = false)
    @Builder.Default
    private Boolean masteryApplyImmediately = true;

    @Column(name = "pos_focus", length = 50)
    @Builder.Default
    private String posFocus = "ALL";

    @Enumerated(EnumType.STRING)
    @JdbcType(PostgreSQLEnumJdbcType.class)
    @Column(name = "grade_level", columnDefinition = "grade_level_enum")
    @Builder.Default
    private GradeLevel gradeLevel = GradeLevel.GRADE_4;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "section_id")
    private Section section;

    @Column(name = "avatar", length = 100)
    private String avatar;

    @Column(name = "is_active", nullable = false)
    @Builder.Default
    private Boolean isActive = true;

    @Column(name = "created_at", updatable = false)
    @Builder.Default
    private OffsetDateTime createdAt = OffsetDateTime.now();

    @Column(name = "updated_at")
    @Builder.Default
    private OffsetDateTime updatedAt = OffsetDateTime.now();

    public UUID getLearnerId() {
        return learnerId;
    }

    public String getUserId() {
        return userId;
    }

    public void setUserId(String userId) {
        this.userId = userId;
    }

    public LanguageMedium getLanguagePreference() {
        return languagePreference;
    }

    public GradeLevel getGradeLevel() {
        return gradeLevel;
    }

    public OffsetDateTime getUpdatedAt() {
        return updatedAt;
    }

    public String getDisplayName() {
        return displayName;
    }

    public Section getSection() {
        return section;
    }

    public Integer getAge() {
        return age;
    }

    public String getPosFocus() {
        return posFocus;
    }

    public Boolean getIsActive() {
        return isActive;
    }

    public OffsetDateTime getCreatedAt() {
        return createdAt;
    }

    public void setDisplayName(String displayName) {
        this.displayName = displayName;
    }

    public void setAge(Integer age) {
        this.age = age;
    }

    public void setGradeLevel(GradeLevel gradeLevel) {
        this.gradeLevel = gradeLevel;
    }

    public void setSection(Section section) {
        this.section = section;
    }

    public void setLanguagePreference(LanguageMedium languagePreference) {
        this.languagePreference = languagePreference;
    }

    public void setPosFocus(String posFocus) {
        this.posFocus = posFocus;
    }

    public String getAvatar() {
        if (avatar != null && !avatar.trim().isEmpty()) {
            return avatar;
        }
        if (learnerId != null) {
            return "prof" + (Math.abs(learnerId.hashCode()) % 9 + 1) + ".jpg";
        }
        if (displayName != null && !displayName.trim().isEmpty()) {
            return "prof" + (Math.abs(displayName.hashCode()) % 9 + 1) + ".jpg";
        }
        return "prof" + (java.util.concurrent.ThreadLocalRandom.current().nextInt(9) + 1) + ".jpg";
    }
    public void setAvatar(String avatar) { this.avatar = avatar; }
    public void setIsActive(Boolean isActive) { this.isActive = isActive; }
    public String getPinHash() { return pinHash; }
    public void setPinHash(String pinHash) { this.pinHash = pinHash; }
    public Boolean getOnboardingComplete() { return onboardingComplete; }
    public Boolean getMasteryApplyImmediately() { return masteryApplyImmediately; }
    public void setMasteryApplyImmediately(Boolean masteryApplyImmediately) { this.masteryApplyImmediately = masteryApplyImmediately; }

    public static LearnerBuilder builder() { return new LearnerBuilder(); }

    public static class LearnerBuilder {
        private UUID learnerId;
        private String userId;
        private String displayName;
        private Integer age;
        private String pinHash;
        private GradeLevel gradeLevel;
        private Section section;
        private String avatar;
        private LanguageMedium languagePreference = LanguageMedium.FULL_ENGLISH;
        private String posFocus = "ALL";
        private Boolean isActive = true;
        private Boolean onboardingComplete = false;
        private Boolean masteryApplyImmediately = true;
        private OffsetDateTime createdAt;
        private OffsetDateTime updatedAt;

        public LearnerBuilder learnerId(UUID learnerId) { this.learnerId = learnerId; return this; }
        public LearnerBuilder userId(String userId) { this.userId = userId; return this; }
        public LearnerBuilder displayName(String displayName) { this.displayName = displayName; return this; }
        public LearnerBuilder age(Integer age) { this.age = age; return this; }
        public LearnerBuilder pinHash(String pinHash) { this.pinHash = pinHash; return this; }
        public LearnerBuilder gradeLevel(GradeLevel gradeLevel) { this.gradeLevel = gradeLevel; return this; }
        public LearnerBuilder section(Section section) { this.section = section; return this; }
        public LearnerBuilder avatar(String avatar) { this.avatar = avatar; return this; }
        public LearnerBuilder languagePreference(LanguageMedium languagePreference) { this.languagePreference = languagePreference; return this; }
        public LearnerBuilder posFocus(String posFocus) { this.posFocus = posFocus; return this; }
        public LearnerBuilder isActive(Boolean isActive) { this.isActive = isActive; return this; }
        public LearnerBuilder onboardingComplete(Boolean onboardingComplete) { this.onboardingComplete = onboardingComplete; return this; }
        public LearnerBuilder masteryApplyImmediately(Boolean masteryApplyImmediately) { this.masteryApplyImmediately = masteryApplyImmediately; return this; }
        public LearnerBuilder createdAt(OffsetDateTime createdAt) { this.createdAt = createdAt; return this; }
        public LearnerBuilder updatedAt(OffsetDateTime updatedAt) { this.updatedAt = updatedAt; return this; }

        public Learner build() {
            Learner l = new Learner();
            l.learnerId = this.learnerId;
            l.userId = this.userId;
            l.displayName = this.displayName;
            l.age = this.age;
            l.pinHash = this.pinHash;
            l.gradeLevel = this.gradeLevel;
            l.section = this.section;
            if (this.avatar != null && !this.avatar.trim().isEmpty()) {
                l.avatar = this.avatar;
            } else if (this.learnerId != null) {
                l.avatar = "prof" + (Math.abs(this.learnerId.hashCode()) % 9 + 1) + ".jpg";
            } else if (this.displayName != null && !this.displayName.trim().isEmpty()) {
                l.avatar = "prof" + (Math.abs(this.displayName.hashCode()) % 9 + 1) + ".jpg";
            } else {
                l.avatar = "prof" + (java.util.concurrent.ThreadLocalRandom.current().nextInt(9) + 1) + ".jpg";
            }
            l.languagePreference = this.languagePreference;
            l.posFocus = this.posFocus;
            l.isActive = this.isActive;
            l.onboardingComplete = this.onboardingComplete;
            l.masteryApplyImmediately = this.masteryApplyImmediately;
            l.createdAt = this.createdAt != null ? this.createdAt : OffsetDateTime.now();
            l.updatedAt = this.updatedAt != null ? this.updatedAt : OffsetDateTime.now();
            return l;
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
