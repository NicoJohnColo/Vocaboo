package com.vocaboo.service;

import org.springframework.stereotype.Service;

@Service
public class PhoneticComparisonService {

    public String normalizePhonetically(String word) {
        if (word == null) {
            return "";
        }
        // Clean word: lowercase, strip non-alphanumeric except spaces
        String clean = word.toLowerCase().replaceAll("[^a-z0-9\\s]", "").trim();

        // Apply Cebuano phonetic substitution rules
        clean = clean.replace("ph", "p");
        clean = clean.replace("f", "p");
        clean = clean.replace("v", "b");
        clean = clean.replace("th", "d");
        clean = clean.replace("sh", "s");
        clean = clean.replace("ch", "ts");

        // Vowel mergers (e/i, o/u, y/i)
        clean = clean.replace("e", "i");
        clean = clean.replace("o", "u");
        clean = clean.replace("y", "i");

        return clean;
    }
}
