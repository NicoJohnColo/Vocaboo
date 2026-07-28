package com.vocaboo.service;

import com.vocaboo.config.DeepgramConfig;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;

import java.util.Base64;

@SpringBootTest
public class DeepgramLiveIntegrationTest {

    @Autowired
    private DeepgramConfig deepgramConfig;

    @Autowired
    private DeepgramSpeechService deepgramSpeechService;

    @Autowired
    private PronunciationEvaluationService evaluationService;

    @Test
    public void testLiveDeepgramCall() {
        System.out.println("=========================================================================");
        System.out.println("[LIVE DEEPGRAM SPEECH TEST STARTING]");
        System.out.println("Configured API Key Present: " + (deepgramConfig.getApiKey() != null && !deepgramConfig.getApiKey().isBlank()));
        System.out.println("Target API URL: " + deepgramConfig.getApiUrl());
        System.out.println("Model: " + deepgramConfig.getModel());
        System.out.println("Language: " + deepgramConfig.getLanguage());

        byte[] audioBytes;
        java.io.File audioFile = new java.io.File("pencil.wav");
        if (audioFile.exists()) {
            try {
                audioBytes = java.nio.file.Files.readAllBytes(audioFile.toPath());
                System.out.println("Loaded spoken audio file 'pencil.wav' (" + audioBytes.length + " bytes)");
            } catch (Exception e) {
                System.err.println("Failed to read audio file: " + e.getMessage());
                return;
            }
        } else {
            System.err.println("Audio file 'pencil.wav' not found.");
            return;
        }

        String targetWord = "pencil";
        int attemptNumber = 1;

        try {
            System.out.println("Sending spoken audio payload to live Deepgram API...");
            DeepgramSpeechService.DeepgramResult result = deepgramSpeechService.uploadAudioToDeepgram(audioBytes, "audio/wav");
            
            System.out.println("[LIVE DEEPGRAM API RESPONSE RECEIVED]");
            System.out.println("Transcribed Text from Deepgram: '" + result.getTranscript() + "'");
            System.out.println("Deepgram Confidence Score: " + result.getConfidence());

            // Run evaluation against target word
            PronunciationEvaluationService.EvaluationResult evalResult = 
                    evaluationService.evaluatePronunciation(targetWord, result.getTranscript(), attemptNumber);

            System.out.println("[PHONETIC EVALUATION COMPUTATION RESULT]");
            System.out.println("Target Word: '" + targetWord + "'");
            System.out.println("Evaluated Clean Transcript: '" + result.getTranscript() + "'");
            System.out.println("Phonetic Similarity Score: " + evalResult.getSimilarityScore() + " (" + String.format("%.2f%%", evalResult.getSimilarityScore() * 100) + ")");
            System.out.println("Is Correct (Threshold >= 70%): " + evalResult.isCorrect());

        } catch (DeepgramSpeechService.EmptyTranscriptionException e) {
            System.out.println("[LIVE DEEPGRAM TEST RESULT - TRANSCRIPTION EMPTY]");
            System.out.println("Message: " + e.getMessage());
        } catch (DeepgramSpeechService.DeepgramApiException e) {
            System.out.println("[LIVE DEEPGRAM TEST RESULT - API ERROR]");
            System.out.println("Status Code: " + e.getStatusCode());
            System.out.println("Response Body: " + e.getResponseBody());
        } catch (Exception e) {
            System.out.println("[LIVE DEEPGRAM TEST RESULT - EXCEPTION]");
            System.out.println("Error: " + e.getClass().getName() + ": " + e.getMessage());
            e.printStackTrace();
        }
        System.out.println("=========================================================================");
    }
}
