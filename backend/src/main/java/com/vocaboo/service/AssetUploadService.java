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

import java.io.IOException;
import java.net.HttpURLConnection;
import java.net.URL;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.Map;
import java.util.Set;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class AssetUploadService {

    private static final org.slf4j.Logger log = org.slf4j.LoggerFactory.getLogger(AssetUploadService.class);

    private final AssetUploadRepository assetUploadRepository;

    @Value("${vocaboo.uploads.dir:uploads}")
    private String uploadsDir;

    @Value("${vocaboo.uploads.base-url:http://localhost:8081/uploads}")
    private String baseUrl;

    private static final long MAX_AUDIO_BYTES = 5 * 1024 * 1024; // 5 MB
    private static final long MAX_IMAGE_BYTES = 6 * 1024 * 1024; // 6 MB
    private static final Set<String> AUDIO_TYPES = Set.of("audio/mpeg", "audio/wav", "audio/wave", "audio/x-wav");
    private static final Set<String> IMAGE_TYPES = Set.of("image/png", "image/jpeg");

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
            // Derive local path from URL
            String relativePath = asset.getCdnUrl().replace(baseUrl, "").replace("/uploads", "");
            Path filePath = Paths.get(uploadsDir).resolve(relativePath.startsWith("/") ? relativePath.substring(1) : relativePath);
            Files.deleteIfExists(filePath);
        } catch (IOException e) {
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
        String subDir = "AUDIO".equals(assetType) ? "audio" : "images";
        String originalFilename = sanitizeFilename(file.getOriginalFilename());
        String storedName = (wordId != null ? wordId : UUID.randomUUID()) + "_" + originalFilename;

        Path dir = Paths.get(uploadsDir, "lessons", lessonId.toString(), subDir);
        Files.createDirectories(dir);
        Path dest = dir.resolve(storedName);
        file.transferTo(dest);

        String cdnUrl = baseUrl + "/lessons/" + lessonId + "/" + subDir + "/" + storedName;
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
}
