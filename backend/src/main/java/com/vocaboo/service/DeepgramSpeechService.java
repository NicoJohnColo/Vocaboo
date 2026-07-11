package com.vocaboo.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.vocaboo.config.DeepgramConfig;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.io.IOException;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.time.Duration;

@Service
public class DeepgramSpeechService {

    private final DeepgramConfig deepgramConfig;
    private final HttpClient httpClient;
    private final ObjectMapper objectMapper = new ObjectMapper();

    @Autowired
    public DeepgramSpeechService(DeepgramConfig deepgramConfig) {
        this.deepgramConfig = deepgramConfig;
        this.httpClient = HttpClient.newBuilder()
                .connectTimeout(Duration.ofSeconds(10))
                .build();
    }

    public DeepgramSpeechService(DeepgramConfig deepgramConfig, HttpClient httpClient) {
        this.deepgramConfig = deepgramConfig;
        this.httpClient = httpClient;
    }

    public static class DeepgramSpeechException extends RuntimeException {
        public DeepgramSpeechException(String message) {
            super(message);
        }
        public DeepgramSpeechException(String message, Throwable cause) {
            super(message, cause);
        }
    }

    public static class DeepgramConnectionException extends DeepgramSpeechException {
        public DeepgramConnectionException(String message, Throwable cause) {
            super(message, cause);
        }
    }

    public static class DeepgramApiException extends DeepgramSpeechException {
        private final int statusCode;
        private final String responseBody;

        public DeepgramApiException(int statusCode, String responseBody) {
            super("Deepgram API returned status " + statusCode + ": " + responseBody);
            this.statusCode = statusCode;
            this.responseBody = responseBody;
        }

        public int getStatusCode() { return statusCode; }
        public String getResponseBody() { return responseBody; }
    }

    public static class DeepgramResult {
        private final String transcript;
        private final Double confidence;

        public DeepgramResult(String transcript, Double confidence) {
            this.transcript = transcript;
            this.confidence = confidence;
        }

        public String getTranscript() { return transcript; }
        public Double getConfidence() { return confidence; }
    }

    public static class EmptyTranscriptionException extends DeepgramSpeechException {
        public EmptyTranscriptionException(String message) {
            super(message);
        }
    }

    public DeepgramResult uploadAudioToDeepgram(byte[] audioBytes) {
        return uploadAudioToDeepgram(audioBytes, "audio/mp4");
    }

    public DeepgramResult uploadAudioToDeepgram(byte[] audioBytes, String contentType) {
        String apiKey = deepgramConfig.getApiKey();
        if (apiKey == null || apiKey.trim().isEmpty()) {
            throw new DeepgramSpeechException("Deepgram API key is not configured.");
        }

        HttpClient client = this.httpClient;

        String queryParams = String.format("model=%s&language=%s", 
                deepgramConfig.getModel(), 
                deepgramConfig.getLanguage());
        String delimiter = deepgramConfig.getApiUrl().contains("?") ? "&" : "?";
        URI requestUri = URI.create(deepgramConfig.getApiUrl() + delimiter + queryParams);

        HttpRequest request = HttpRequest.newBuilder()
                .uri(requestUri)
                .timeout(Duration.ofSeconds(30))
                .header("Authorization", "Token " + apiKey)
                .header("Content-Type", contentType != null ? contentType : "audio/mp4")
                .POST(HttpRequest.BodyPublishers.ofByteArray(audioBytes))
                .build();

        HttpResponse<String> response = null;
        int maxRetries = 1;
        int attempts = 0;
        Exception lastException = null;

        while (attempts <= maxRetries) {
            attempts++;
            try {
                response = client.send(request, HttpResponse.BodyHandlers.ofString());
                if (response.statusCode() == 200) {
                    break;
                }
            } catch (IOException e) {
                lastException = e;
            } catch (InterruptedException e) {
                Thread.currentThread().interrupt();
                throw new DeepgramConnectionException("Connection to Deepgram was interrupted", e);
            }

            if (attempts <= maxRetries) {
                System.out.println("[DEEPGRAM] Request failed, retrying once...");
                try {
                    Thread.sleep(200);
                } catch (InterruptedException e) {
                    Thread.currentThread().interrupt();
                }
            }
        }

        if (response == null) {
            throw new DeepgramConnectionException("Network failure while connecting to Deepgram after retries", lastException);
        }

        int status = response.statusCode();
        String body = response.body();

        if (status != 200) {
            throw new DeepgramApiException(status, body);
        }

        DeepgramResult result = parseDeepgramResponse(body);
        if (result == null || result.getTranscript() == null || result.getTranscript().trim().isEmpty()) {
            throw new EmptyTranscriptionException("Deepgram returned an empty or missing transcription.");
        }

        return result;
    }

    private DeepgramResult parseDeepgramResponse(String body) {
        try {
            if (body == null || body.isBlank()) {
                return null;
            }
            JsonNode root = objectMapper.readTree(body);
            if (root.has("results")) {
                JsonNode results = root.get("results");
                if (results.has("channels") && results.get("channels").isArray() && !results.get("channels").isEmpty()) {
                    JsonNode channel = results.get("channels").get(0);
                    if (channel.has("alternatives") && channel.get("alternatives").isArray() && !channel.get("alternatives").isEmpty()) {
                        JsonNode alternative = channel.get("alternatives").get(0);
                        if (alternative.hasNonNull("transcript")) {
                            String transcript = alternative.get("transcript").asText();
                            Double confidence = alternative.has("confidence") ? alternative.get("confidence").asDouble() : null;
                            return new DeepgramResult(transcript, confidence);
                        }
                    }
                }
            }
        } catch (Exception ex) {
            System.err.println("Failed to parse Deepgram response JSON: " + ex.getClass().getSimpleName() + ": " + ex.getMessage());
        }
        return null;
    }
}
