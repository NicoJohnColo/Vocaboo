package com.vocaboo.service;

import com.vocaboo.entity.AssetUpload;
import com.vocaboo.repository.AssetUploadRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.server.ResponseStatusException;
import software.amazon.awssdk.auth.credentials.AwsBasicCredentials;
import software.amazon.awssdk.auth.credentials.StaticCredentialsProvider;
import software.amazon.awssdk.core.sync.RequestBody;
import software.amazon.awssdk.regions.Region;
import software.amazon.awssdk.services.s3.S3Client;
import software.amazon.awssdk.services.s3.S3Configuration;
import software.amazon.awssdk.services.s3.model.DeleteObjectRequest;
import software.amazon.awssdk.services.s3.model.PutObjectRequest;

import jakarta.annotation.PostConstruct;
import java.io.IOException;
import java.net.HttpURLConnection;
import java.net.URI;
import java.net.URL;
import java.util.Map;
import java.util.Set;
import java.util.UUID;

@Slf4j
@Service
@RequiredArgsConstructor
public class AssetUploadService {

    private final AssetUploadRepository assetUploadRepository;

    @Value("${vocaboo.uploads.s3.endpoint}")
    private String s3Endpoint;

    @Value("${vocaboo.uploads.s3.access-key}")
    private String s3AccessKey;

    @Value("${vocaboo.uploads.s3.secret-key}")
    private String s3SecretKey;

    @Value("${vocaboo.uploads.s3.bucket}")
    private String s3Bucket;

    @Value("${vocaboo.uploads.s3.public-url-prefix}")
    private String publicUrlPrefix;

    private S3Client s3Client;

    private static final long MAX_AUDIO_BYTES = 5 * 1024 * 1024; // 5 MB
    private static final long MAX_IMAGE_BYTES = 6 * 1024 * 1024; // 6 MB
    private static final Set<String> AUDIO_TYPES = Set.of("audio/mpeg", "audio/wav", "audio/wave", "audio/x-wav");
    private static final Set<String> IMAGE_TYPES = Set.of("image/png", "image/jpeg");

    @PostConstruct
    public void init() {
        if (s3AccessKey == null || s3AccessKey.isBlank() || s3SecretKey == null || s3SecretKey.isBlank()) {
            log.warn("Supabase S3 credentials not provided. Asset uploads will fail.");
            return;
        }
        
        AwsBasicCredentials credentials = AwsBasicCredentials.create(s3AccessKey, s3SecretKey);
        s3Client = S3Client.builder()
                .credentialsProvider(StaticCredentialsProvider.create(credentials))
                .endpointOverride(URI.create(s3Endpoint))
                .region(Region.AP_SOUTHEAST_1) // Supabase usually ignores region for S3 compat, but AWS SDK requires it
                .serviceConfiguration(S3Configuration.builder().pathStyleAccessEnabled(true).build())
                .build();
    }

    /**
     * Upload an audio file for a vocabulary word.
     */
    public Map<String, Object> uploadAudio(MultipartFile file, UUID lessonId, UUID wordId, UUID adminId) throws IOException {
        validateFile(file, "audio");
        return storeFile(file, lessonId, wordId, "AUDIO", adminId);
    }

    /**
     * Upload an image file for a vocabulary word.
     */
    public Map<String, Object> uploadImage(MultipartFile file, UUID lessonId, UUID wordId, UUID adminId) throws IOException {
        validateFile(file, "image");
        return storeFile(file, lessonId, wordId, "IMAGE", adminId);
    }

    /**
     * Verify that an asset URL is accessible (HTTP 200).
     */
    public Map<String, Object> verifyUrl(String url) {
        try {
            HttpURLConnection conn = (HttpURLConnection) new URL(url).openConnection();
            conn.setRequestMethod("HEAD");
            conn.setConnectTimeout(3000);
            conn.setReadTimeout(3000);
            int code = conn.getResponseCode();
            return Map.of("accessible", code == 200, "status_code", code);
        } catch (Exception e) {
            return Map.of("accessible", false, "status_code", 0, "error", e.getMessage());
        }
    }

    /**
     * Delete an uploaded asset record and file.
     */
    public void deleteAsset(UUID assetId) {
        AssetUpload asset = assetUploadRepository.findById(assetId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Asset not found"));
        try {
            String objectKey = extractObjectKey(asset.getCdnUrl());
            if (s3Client != null && objectKey != null) {
                DeleteObjectRequest deleteReq = DeleteObjectRequest.builder()
                        .bucket(s3Bucket)
                        .key(objectKey)
                        .build();
                s3Client.deleteObject(deleteReq);
            }
        } catch (Exception e) {
            log.warn("Could not delete file for asset {}: {}", assetId, e.getMessage());
        }
        assetUploadRepository.delete(asset);
    }

    // ─── helpers ──────────────────────────────────────────────────────────────

    private void validateFile(MultipartFile file, String type) {
        if (file == null || file.isEmpty()) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "File is empty");
        }
        String contentType = file.getContentType() != null ? file.getContentType().toLowerCase() : "";
        String filename = file.getOriginalFilename() != null ? file.getOriginalFilename().toLowerCase() : "";

        if ("audio".equals(type)) {
            boolean isValidAudioType = AUDIO_TYPES.contains(contentType) || contentType.equals("audio/mp3") || filename.endsWith(".mp3") || filename.endsWith(".wav");
            if (!isValidAudioType) throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Invalid audio type. Allowed: MP3, WAV");
            if (file.getSize() > MAX_AUDIO_BYTES) throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Audio file exceeds 5 MB limit");
        } else {
            boolean isValidImageType = IMAGE_TYPES.contains(contentType) || filename.endsWith(".png") || filename.endsWith(".jpg") || filename.endsWith(".jpeg");
            if (!isValidImageType) throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Invalid image type. Allowed: PNG, JPG");
            if (file.getSize() > MAX_IMAGE_BYTES) throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Image file exceeds 6 MB limit");
        }
    }

    private Map<String, Object> storeFile(MultipartFile file, UUID lessonId, UUID wordId, String assetType, UUID adminId) throws IOException {
        if (s3Client == null) {
            throw new ResponseStatusException(HttpStatus.INTERNAL_SERVER_ERROR, "S3 client is not configured.");
        }

        String subDir = "AUDIO".equals(assetType) ? "audio" : "images";
        String originalFilename = sanitizeFilename(file.getOriginalFilename());
        String storedName = (wordId != null ? wordId : UUID.randomUUID()) + "_" + originalFilename;

        // Path inside bucket: lessons/{lessonId}/{subDir}/{filename}
        String objectKey = "lessons/" + lessonId + "/" + subDir + "/" + storedName;
        String contentType = file.getContentType();

        try {
            PutObjectRequest putObj = PutObjectRequest.builder()
                    .bucket(s3Bucket)
                    .key(objectKey)
                    .contentType(contentType)
                    .build();

            s3Client.putObject(putObj, RequestBody.fromInputStream(file.getInputStream(), file.getSize()));
        } catch (Exception e) {
            log.error("Failed to upload to S3", e);
            throw new ResponseStatusException(HttpStatus.INTERNAL_SERVER_ERROR, "Failed to upload file to cloud storage.");
        }

        String cdnUrl = publicUrlPrefix + objectKey;
        int sizeKb = (int) (file.getSize() / 1024);

        AssetUpload record = AssetUpload.builder()
                .lessonId(lessonId)
                .wordId(wordId)
                .assetType(assetType)
                .originalFilename(originalFilename)
                .cdnUrl(cdnUrl)
                .fileSizeKb(sizeKb)
                .uploadedByAdminId(adminId)
                .build();

        assetUploadRepository.save(record);

        return Map.of(
                "asset_url", cdnUrl,
                "file_type", assetType.toLowerCase(),
                "size_kb", sizeKb,
                "asset_id", record.getAssetId()
        );
    }

    private String sanitizeFilename(String name) {
        if (name == null) return "file";
        return name.replaceAll("[^a-zA-Z0-9._-]", "_").toLowerCase();
    }
    
    private String extractObjectKey(String url) {
        if (url == null) return null;
        if (url.startsWith(publicUrlPrefix)) {
            return url.substring(publicUrlPrefix.length());
        }
        return null;
    }
}
