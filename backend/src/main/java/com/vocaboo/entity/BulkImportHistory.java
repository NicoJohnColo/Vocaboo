package com.vocaboo.entity;

import jakarta.persistence.*;
import lombok.*;
import java.time.OffsetDateTime;
import java.util.UUID;

@Entity
@Table(name = "bulk_import_history")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class BulkImportHistory {

    @Id
    @GeneratedValue(strategy = GenerationType.AUTO)
    @Column(name = "import_id", updatable = false, nullable = false)
    private UUID importId;

    @Column(name = "lesson_id", nullable = false)
    private UUID lessonId;

    @Column(name = "admin_id", nullable = false)
    private UUID adminId;

    @Column(name = "total_rows", nullable = false)
    @Builder.Default
    private Integer totalRows = 0;

    @Column(name = "success_count", nullable = false)
    @Builder.Default
    private Integer successCount = 0;

    @Column(name = "error_count", nullable = false)
    @Builder.Default
    private Integer errorCount = 0;

    @Column(name = "skipped_count", nullable = false)
    @Builder.Default
    private Integer skippedCount = 0;

    @Column(name = "import_date", updatable = false)
    @Builder.Default
    private OffsetDateTime importDate = OffsetDateTime.now();

    @Column(name = "import_status", nullable = false, length = 10)
    @Builder.Default
    private String importStatus = "SUCCESS"; // SUCCESS, PARTIAL, FAILED

    @Column(name = "error_log", columnDefinition = "TEXT")
    private String errorLog; // JSON array of error details

    @PrePersist
    protected void onCreate() {
        importDate = OffsetDateTime.now();
    }
}
