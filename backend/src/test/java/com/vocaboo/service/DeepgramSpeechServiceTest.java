package com.vocaboo.service;

import com.vocaboo.config.DeepgramConfig;
import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

import java.io.IOException;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;

class DeepgramSpeechServiceTest {

    @Test
    void testUploadAudioToDeepgram_MissingApiKeyThrowsException() {
        DeepgramConfig config = mock(DeepgramConfig.class);
        when(config.getApiKey()).thenReturn(null);

        DeepgramSpeechService service = new DeepgramSpeechService(config);

        DeepgramSpeechService.DeepgramSpeechException exception = assertThrows(
                DeepgramSpeechService.DeepgramSpeechException.class,
                () -> service.uploadAudioToDeepgram(new byte[]{1, 2, 3})
        );
        assertEquals("Deepgram API key is not configured.", exception.getMessage());
    }

    @Test
    void testUploadAudioToDeepgram_EmptyApiKeyThrowsException() {
        DeepgramConfig config = mock(DeepgramConfig.class);
        when(config.getApiKey()).thenReturn("   ");

        DeepgramSpeechService service = new DeepgramSpeechService(config);

        DeepgramSpeechService.DeepgramSpeechException exception = assertThrows(
                DeepgramSpeechService.DeepgramSpeechException.class,
                () -> service.uploadAudioToDeepgram(new byte[]{1, 2, 3})
        );
        assertEquals("Deepgram API key is not configured.", exception.getMessage());
    }

    @Test
    void testUploadAudioToDeepgram_RetriesOnceOnNetworkFailure() throws Exception {
        DeepgramConfig config = mock(DeepgramConfig.class);
        when(config.getApiKey()).thenReturn("mock-api-key");
        when(config.getApiUrl()).thenReturn("https://api.deepgram.com/v1/listen");
        when(config.getModel()).thenReturn("nova-3");
        when(config.getLanguage()).thenReturn("en");

        HttpClient httpClient = mock(HttpClient.class);
        // Throw IOException on send calls
        when(httpClient.send(any(HttpRequest.class), any(HttpResponse.BodyHandler.class)))
                .thenThrow(new IOException("Simulated network error"));

        DeepgramSpeechService service = new DeepgramSpeechService(config, httpClient);

        assertThrows(DeepgramSpeechService.DeepgramConnectionException.class, () -> {
            service.uploadAudioToDeepgram(new byte[]{1, 2, 3});
        });

        // Verify it was called exactly twice (1 initial + 1 retry)
        verify(httpClient, times(2)).send(any(HttpRequest.class), any(HttpResponse.BodyHandler.class));
    }

    @Test
    void testUploadAudioToDeepgram_RetriesOnceOnHttpErrorAndThenThrowsApiException() throws Exception {
        DeepgramConfig config = mock(DeepgramConfig.class);
        when(config.getApiKey()).thenReturn("mock-api-key");
        when(config.getApiUrl()).thenReturn("https://api.deepgram.com/v1/listen");
        when(config.getModel()).thenReturn("nova-3");
        when(config.getLanguage()).thenReturn("en");

        HttpClient httpClient = mock(HttpClient.class);
        HttpResponse<String> httpResponse = mock(HttpResponse.class);
        when(httpResponse.statusCode()).thenReturn(502);
        when(httpResponse.body()).thenReturn("Bad Gateway");

        // Return 502 status response on send calls
        when(httpClient.send(any(HttpRequest.class), any(HttpResponse.BodyHandler.class)))
                .thenReturn(httpResponse);

        DeepgramSpeechService service = new DeepgramSpeechService(config, httpClient);

        assertThrows(DeepgramSpeechService.DeepgramApiException.class, () -> {
            service.uploadAudioToDeepgram(new byte[]{1, 2, 3});
        });

        // Verify it was called exactly twice (1 initial + 1 retry)
        verify(httpClient, times(2)).send(any(HttpRequest.class), any(HttpResponse.BodyHandler.class));
    }
}
