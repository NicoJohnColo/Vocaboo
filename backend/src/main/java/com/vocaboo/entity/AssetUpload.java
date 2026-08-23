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

    public String getCdnUrl() {
        return cdnUrl;
    }

    public UUID getAssetId() {
        return assetId;
    }

    public static AssetUploadBuilder builder() {
        return new AssetUploadBuilder();
    }

    public static class AssetUploadBuilder {
        private UUID lessonId;
        private UUID wordId;
        private String assetType;
        private String originalFilename;
        private String cdnUrl;
        private Integer fileSizeKb;
        private UUID uploadedByAdminId;

        public AssetUploadBuilder lessonId(UUID lessonId) { this.lessonId = lessonId; return this; }
        public AssetUploadBuilder wordId(UUID wordId) { this.wordId = wordId; return this; }
        public AssetUploadBuilder assetType(String assetType) { this.assetType = assetType; return this; }
        public AssetUploadBuilder originalFilename(String originalFilename) { this.originalFilename = originalFilename; return this; }
        public AssetUploadBuilder cdnUrl(String cdnUrl) { this.cdnUrl = cdnUrl; return this; }
        public AssetUploadBuilder fileSizeKb(Integer fileSizeKb) { this.fileSizeKb = fileSizeKb; return this; }
        public AssetUploadBuilder uploadedByAdminId(UUID uploadedByAdminId) { this.uploadedByAdminId = uploadedByAdminId; return this; }

        public AssetUpload build() {
            AssetUpload a = new AssetUpload();
            a.lessonId = this.lessonId;
            a.wordId = this.wordId;
            a.assetType = this.assetType;
            a.originalFilename = this.originalFilename;
            a.cdnUrl = this.cdnUrl;
            a.fileSizeKb = this.fileSizeKb;
            a.uploadedByAdminId = this.uploadedByAdminId;
            a.uploadDate = OffsetDateTime.now();
            return a;
        }
    }

    @PrePersist
    protected void onCreate() {
        uploadDate = OffsetDateTime.now();
    }
}
