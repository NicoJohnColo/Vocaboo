package com.vocaboo.service;

import org.junit.jupiter.api.Test;
import java.util.Base64;
import java.util.Random;
import static org.junit.jupiter.api.Assertions.*;

class AudioPipelineVerificationTest {

    @Test
    void testAudioPipelineDataIntegrity() {
        // 1. Create a mock byte array representing raw audio data (.m4a / AAC-LC format bytes)
        byte[] originalAudioBytes = new byte[1024 * 50]; // 50 KB dummy audio file
        new Random(42).nextBytes(originalAudioBytes); // Seeded random bytes for predictability

        // 2. Encode to raw Base64 (matching what the mobile client sends)
        String rawBase64 = Base64.getEncoder().encodeToString(originalAudioBytes);

        // 3. Instantiate PronunciationService (passing null dependencies as we are only testing local helper methods)
        PronunciationService service = new PronunciationService(null, null, null, null, null, null);

        // 4. Test raw Base64 flow
        String detectedTypeRaw = service.detectContentType(rawBase64);
        String normalizedRaw = service.normalizeAudioBase64(rawBase64);
        byte[] decodedRaw = Base64.getDecoder().decode(normalizedRaw);

        assertNull(detectedTypeRaw, "Raw Base64 should not have a detected MIME type");
        assertEquals(rawBase64, normalizedRaw, "Raw Base64 should remain unchanged after normalization");
        assertArrayEquals(originalAudioBytes, decodedRaw, "Decoded bytes must be byte-for-byte identical to original raw Base64 payload");

        System.out.println("[INFO] Verified raw base64 decode flow. Bytes length = " + decodedRaw.length);

        // 5. Test Data URI prefixed Base64 flow
        String dataUriPrefix = "data:audio/mp4;base64,";
        String prefixedBase64 = dataUriPrefix + rawBase64;

        String detectedTypePrefixed = service.detectContentType(prefixedBase64);
        String normalizedPrefixed = service.normalizeAudioBase64(prefixedBase64);
        byte[] decodedPrefixed = Base64.getDecoder().decode(normalizedPrefixed);

        assertEquals("audio/mp4", detectedTypePrefixed, "Prefixed Base64 should correctly detect 'audio/mp4' MIME type");
        assertEquals(rawBase64, normalizedPrefixed, "Prefixed Base64 should have data prefix removed after normalization");
        assertArrayEquals(originalAudioBytes, decodedPrefixed, "Decoded bytes must be byte-for-byte identical to prefixed Base64 payload");

        System.out.println("[INFO] Verified prefixed base64 decode flow. MIME Type detected = " + detectedTypePrefixed + ", Bytes length = " + decodedPrefixed.length);
    }
}
