package com.vocaboo.config;

import lombok.Getter;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Configuration;

@Configuration
@Getter
public class DeepgramConfig {

    @Value("${deepgram.api.key}")
    private String apiKey;

    @Value("${deepgram.api.url:https://api.deepgram.com/v1/listen}")
    private String apiUrl;

    @Value("${deepgram.model:nova-3}")
    private String model;

    @Value("${deepgram.language:en}")
    private String language;

    public String getApiKey() { return apiKey; }
    public String getApiUrl() { return apiUrl; }
    public String getModel() { return model; }
    public String getLanguage() { return language; }
}
