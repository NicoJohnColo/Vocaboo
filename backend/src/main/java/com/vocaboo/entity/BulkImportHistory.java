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

    public UUID getImportId() {
        return importId;
    }

    public static BulkImportHistoryBuilder builder() {
        return new BulkImportHistoryBuilder();
    }

    public static class BulkImportHistoryBuilder {
        private UUID lessonId;
        private UUID adminId;
        private Integer totalRows = 0;
        private Integer successCount = 0;
        private Integer errorCount = 0;
        private Integer skippedCount = 0;
        private String importStatus = "SUCCESS";
        private String errorLog;

        public BulkImportHistoryBuilder lessonId(UUID lessonId) { this.lessonId = lessonId; return this; }
        public BulkImportHistoryBuilder adminId(UUID adminId) { this.adminId = adminId; return this; }
        public BulkImportHistoryBuilder totalRows(Integer totalRows) { this.totalRows = totalRows; return this; }
        public BulkImportHistoryBuilder successCount(Integer successCount) { this.successCount = successCount; return this; }
        public BulkImportHistoryBuilder errorCount(Integer errorCount) { this.errorCount = errorCount; return this; }
        public BulkImportHistoryBuilder skippedCount(Integer skippedCount) { this.skippedCount = skippedCount; return this; }
        public BulkImportHistoryBuilder importStatus(String importStatus) { this.importStatus = importStatus; return this; }
        public BulkImportHistoryBuilder errorLog(String errorLog) { this.errorLog = errorLog; return this; }

        public BulkImportHistory build() {
            BulkImportHistory b = new BulkImportHistory();
            b.lessonId = this.lessonId;
            b.adminId = this.adminId;
            b.totalRows = this.totalRows;
            b.successCount = this.successCount;
            b.errorCount = this.errorCount;
            b.skippedCount = this.skippedCount;
            b.importStatus = this.importStatus;
            b.errorLog = this.errorLog;
            b.importDate = OffsetDateTime.now();
            return b;
        }
    }

    @PrePersist
    protected void onCreate() {
        importDate = OffsetDateTime.now();
    }
}
