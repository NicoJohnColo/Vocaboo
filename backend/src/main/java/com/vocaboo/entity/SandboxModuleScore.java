package com.vocaboo.entity;

import com.fasterxml.jackson.annotation.JsonIgnore;
import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import jakarta.persistence.*;
import lombok.*;

import java.math.BigDecimal;
import java.time.OffsetDateTime;
import java.util.UUID;

@Entity
@Table(
    name = "sandbox_module_scores",
    uniqueConstraints = {
        @UniqueConstraint(columnNames = {"session_id", "module_number"})
    }
)
@JsonIgnoreProperties({"hibernateLazyInitializer", "handler"})
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class SandboxModuleScore {

    @Id
    @GeneratedValue(strategy = GenerationType.AUTO)
    @Column(name = "score_id", updatable = false, nullable = false)
    private UUID scoreId;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "session_id", nullable = false)
    @JsonIgnore
    private SandboxSession session;

    @Column(name = "module_number", nullable = false)
    private Integer moduleNumber;

    @Column(name = "correct", nullable = false)
    @Builder.Default
    private Integer correct = 0;

    @Column(name = "total", nullable = false)
    @Builder.Default
    private Integer total = 0;

    @Column(name = "score", precision = 5, scale = 2, nullable = false)
    @Builder.Default
    private BigDecimal score = BigDecimal.ZERO;

    @Column(name = "recorded_at", updatable = false)
    @Builder.Default
    private OffsetDateTime recordedAt = OffsetDateTime.now();

    @Column(name = "updated_at")
    @Builder.Default
    private OffsetDateTime updatedAt = OffsetDateTime.now();

    public UUID getScoreId() { return scoreId; }
    public Integer getModuleNumber() { return moduleNumber; }
    public Integer getCorrect() { return correct; }
    public Integer getTotal() { return total; }
    public BigDecimal getScore() { return score; }
    public OffsetDateTime getRecordedAt() { return recordedAt; }
    public OffsetDateTime getUpdatedAt() { return updatedAt; }

    public void setCorrect(Integer correct) { this.correct = correct; }
    public void setTotal(Integer total) { this.total = total; }
    public void setScore(BigDecimal score) { this.score = score; }

    public static SandboxModuleScoreBuilder builder() { return new SandboxModuleScoreBuilder(); }

    public static class SandboxModuleScoreBuilder {
        private SandboxSession session;
        private Integer moduleNumber;
        private Integer correct = 0;
        private Integer total = 0;
        private BigDecimal score = BigDecimal.ZERO;

        public SandboxModuleScoreBuilder session(SandboxSession session) { this.session = session; return this; }
        public SandboxModuleScoreBuilder moduleNumber(Integer moduleNumber) { this.moduleNumber = moduleNumber; return this; }
        public SandboxModuleScoreBuilder correct(Integer correct) { this.correct = correct; return this; }
        public SandboxModuleScoreBuilder total(Integer total) { this.total = total; return this; }
        public SandboxModuleScoreBuilder score(BigDecimal score) { this.score = score; return this; }

        public SandboxModuleScore build() {
            SandboxModuleScore s = new SandboxModuleScore();
            s.session = this.session;
            s.moduleNumber = this.moduleNumber;
            s.correct = this.correct;
            s.total = this.total;
            s.score = this.score;
            s.recordedAt = OffsetDateTime.now();
            s.updatedAt = OffsetDateTime.now();
            return s;
        }
    }

    @PrePersist
    protected void onCreate() {
        recordedAt = OffsetDateTime.now();
        updatedAt = OffsetDateTime.now();
    }

    @PreUpdate
    protected void onUpdate() {
        updatedAt = OffsetDateTime.now();
    }
}
