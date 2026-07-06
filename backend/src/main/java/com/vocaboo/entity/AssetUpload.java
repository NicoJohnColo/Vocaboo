package com.vocaboo.entity;

import jakarta.persistence.*;
import lombok.*;
import java.time.OffsetDateTime;
import java.util.UUID;

@Entity
@Table(name = "asset_uploads")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class AssetUpload {

    @Id
    @GeneratedValue(strategy = GenerationType.AUTO)
    @Column(name = "asset_id", updatable = false, nullable = false)
    private UUID assetId;

    @Column(name = "lesson_id")
    private UUID lessonId;

    @Column(name = "word_id")
    private UUID wordId;

    @Column(name = "asset_type", nullable = false, length = 10)
    private String assetType; // "AUDIO" or "IMAGE"

    @Column(name = "original_filename", nullable = false)
    private String originalFilename;

    @Column(name = "cdn_url", nullable = false, columnDefinition = "TEXT")
    private String cdnUrl;

    @Column(name = "file_size_kb")
    private Integer fileSizeKb;

    @Column(name = "upload_date", updatable = false)
    @Builder.Default
    private OffsetDateTime uploadDate = OffsetDateTime.now();

    @Column(name = "uploaded_by_admin_id")
    private UUID uploadedByAdminId;

    @PrePersist
    protected void onCreate() {
        uploadDate = OffsetDateTime.now();
    }
}
