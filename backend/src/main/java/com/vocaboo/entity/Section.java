package com.vocaboo.entity;

import jakarta.persistence.*;
import lombok.*;

import java.time.OffsetDateTime;
import java.util.UUID;

@Entity
@Table(name = "sections")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Section {

    @Id
    @GeneratedValue(strategy = GenerationType.AUTO)
    @Column(name = "section_id", updatable = false, nullable = false)
    private UUID sectionId;

    @Column(name = "section_name", nullable = false, unique = true, length = 100)
    private String sectionName;

    @Column(name = "created_at", updatable = false)
    @Builder.Default
    private OffsetDateTime createdAt = OffsetDateTime.now();

    @Column(name = "updated_at")
    @Builder.Default
    private OffsetDateTime updatedAt = OffsetDateTime.now();

    public UUID getSectionId() {
        return sectionId;
    }

    public String getSectionName() {
        return sectionName;
    }

    public void setSectionName(String sectionName) {
        this.sectionName = sectionName;
    }

    public OffsetDateTime getCreatedAt() {
        return createdAt;
    }

    public OffsetDateTime getUpdatedAt() {
        return updatedAt;
    }

    public static SectionBuilder builder() {
        return new SectionBuilder();
    }

    public static class SectionBuilder {
        private UUID sectionId;
        private String sectionName;

        public SectionBuilder sectionId(UUID sectionId) { this.sectionId = sectionId; return this; }
        public SectionBuilder sectionName(String sectionName) { this.sectionName = sectionName; return this; }

        public Section build() {
            Section s = new Section();
            s.sectionId = this.sectionId;
            s.sectionName = this.sectionName;
            s.createdAt = OffsetDateTime.now();
            s.updatedAt = OffsetDateTime.now();
            return s;
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
