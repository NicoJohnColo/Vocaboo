package com.vocaboo.service;

import jakarta.annotation.PostConstruct;
import lombok.extern.slf4j.Slf4j;
import org.springframework.core.io.ClassPathResource;
import org.springframework.stereotype.Service;

import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.nio.charset.StandardCharsets;
import java.util.HashSet;
import java.util.Set;

@Service
@Slf4j
public class DictionaryValidationService {

    private final Set<String> dictionary = new HashSet<>();

    private boolean initialized = false;

    private synchronized void ensureInitialized() {
        if (initialized) return;
        log.info("Loading English dictionary into memory...");
        try (BufferedReader reader = new BufferedReader(
                new InputStreamReader(
                        new ClassPathResource("dictionary.txt").getInputStream(),
                        StandardCharsets.UTF_8))) {
            
            String line;
            while ((line = reader.readLine()) != null) {
                if (!line.isBlank()) {
                    dictionary.add(line.trim().toLowerCase());
                }
            }
            log.info("Successfully loaded {} English words.", dictionary.size());
        } catch (Exception e) {
            log.error("Failed to load dictionary.txt. English word validation might be unavailable or inaccurate.", e);
        } finally {
            initialized = true;
        }
    }

    /**
     * Verifies if a given string consists solely of valid English words.
     * It handles phrases by splitting by spaces and hyphens.
     */
    public boolean isValidEnglishWord(String text) {
        ensureInitialized();
        if (text == null || text.isBlank()) {
            return false;
        }

        // Split by whitespace or hyphens
        String[] tokens = text.split("[\\s\\-]+");

        for (String token : tokens) {
            // Remove punctuation from token boundaries
            String cleanToken = token.replaceAll("^[^a-zA-Z]+|[^a-zA-Z]+$", "").toLowerCase();
            
            if (cleanToken.isBlank()) continue;

            if (!dictionary.contains(cleanToken)) {
                return false;
            }
        }

        return true;
    }
}
