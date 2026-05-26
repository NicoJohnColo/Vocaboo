package com.vocaboo.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import java.io.IOException;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.time.Duration;
import java.util.ArrayList;
import java.util.Collections;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;

@Service
public class GeminiService {

    private static final String GEMINI_MODEL = "gemini-2.5-flash";

    @Value("${app.gemini.key:${GEMINI_API_KEY:}}")
    private String geminiApiKey;

    private final ObjectMapper objectMapper = new ObjectMapper();
    private final HttpClient httpClient = HttpClient.newBuilder()
            .connectTimeout(Duration.ofSeconds(10))
            .build();

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class SandboxWordDto {
        private String englishWord;
        private String cebuanoMeaning;
        private String exampleSentenceEnglish;
        private String exampleSentenceCebuano;
        private String phonologicalTip;
        private List<String> multipleChoiceDistractors;
        private String fillInTheBlankSentence;
        private List<MatchingEntryDto> matchingSet;
        private List<String> sentenceArrangementTokens;
        private String sentenceCompletionBlank;
        private List<String> sentenceCompletionOptions;
    }

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class MatchingEntryDto {
        private String englishWord;
        private String cebuanoMeaning;
        private String cebuanoTranslation;
    }

    private static final String SANDBOX_SYSTEM_PROMPT = "You generate exactly one child-friendly Cebuano-English vocabulary lesson for Vocaboo.\n"
            + "Return only raw JSON that matches the schema exactly.\n"
            + "The input word will be one English word only. Do not add explanations, markdown, or surrounding text.\n"
            + "The JSON schema is:\n"
            + "{\n"
            + "  \"english_word\": \"string\",\n"
            + "  \"cebuano_meaning\": \"string\",\n"
            + "  \"english_example_sentence\": \"string\",\n"
            + "  \"cebuano_example_sentence\": \"string\",\n"
            + "  \"phonological_tip\": \"string or null\",\n"
            + "  \"multiple_choice_distractors\": [\"string\", \"string\", \"string\"],\n"
            + "  \"fill_in_the_blank_sentence\": \"string\",\n"
            + "  \"matching_set\": [{\"english_word\": \"string\", \"cebuano_meaning\": \"string\"}],\n"
            + "  \"sentence_arrangement_tokens\": [\"string\"],\n"
            + "  \"sentence_completion_blank\": \"string\",\n"
            + "  \"sentence_completion_options\": [\"string\", \"string\", \"string\", \"string\"]\n"
            + "}\n"
            + "Rules: use standard Cebuano orthography, make the Cebuano meaning a real translation, never reuse or transliterate the English word as the meaning, keep content age-appropriate, and ensure the matching set includes the target word plus related words.";

    public SandboxWordDto generateSandboxLesson(String userInput) {
        String normalizedWord = requireSingleWord(userInput);
        String responseBody = callSandboxGemini(normalizedWord);
        SandboxWordDto dto = parseSandboxLesson(responseBody);
        if (dto == null) {
            throw new ResponseStatusException(HttpStatus.BAD_GATEWAY, "Gemini returned invalid sandbox JSON.");
        }

        validateLesson(dto, normalizedWord);
        return dto;
    }

    private String callSandboxGemini(String englishWord) {
        try {
            return callGeminiApi(SANDBOX_SYSTEM_PROMPT, buildPrompt(englishWord));
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            throw new ResponseStatusException(HttpStatus.BAD_GATEWAY, "Sandbox Gemini request failed.", e);
        } catch (IOException e) {
            throw new ResponseStatusException(HttpStatus.BAD_GATEWAY, "Sandbox Gemini request failed.", e);
        }
    }

    private String buildPrompt(String englishWord) {
        return "Generate a complete sandbox lesson for the single English word \"" + englishWord + "\". "
                + "Return one JSON object only. Ensure the Cebuano meaning is a real Cebuano translation, not a reused English word. "
                + "Provide one English example sentence, its Cebuano translation, three multiple-choice distractors, one fill-in-the-blank sentence, a matching set with the target word and related words, shuffled sentence arrangement tokens for the English example sentence, a sentence completion blank, and four completion options.";
    }

    private String requireSingleWord(String input) {
        if (input == null || input.trim().isEmpty()) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "customWord is required.");
        }

        String trimmed = input.trim();
        if (trimmed.chars().anyMatch(Character::isWhitespace) || trimmed.split("\\s+").length != 1) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Sandbox accepts exactly one English word.");
        }

        if (!trimmed.matches("[A-Za-z][A-Za-z'\\-]*")) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Sandbox word must contain only English letters.");
        }

        return trimmed;
    }

    private String callGeminiApi(String systemPrompt, String prompt) throws IOException, InterruptedException {
        if (geminiApiKey == null || geminiApiKey.trim().isEmpty()) {
            throw new ResponseStatusException(HttpStatus.INTERNAL_SERVER_ERROR, "Gemini API key is not configured.");
        }

        String url = "https://generativelanguage.googleapis.com/v1beta/models/" + GEMINI_MODEL + ":generateContent?key=" + geminiApiKey.trim();
        Map<String, Object> payload = new LinkedHashMap<>();
        payload.put("system_instruction", Map.of("parts", List.of(Map.of("text", systemPrompt))));
        payload.put("contents", List.of(Map.of("parts", List.of(Map.of("text", prompt)))));

        HttpRequest request = HttpRequest.newBuilder()
                .uri(URI.create(url))
                .header("Content-Type", "application/json")
                .POST(HttpRequest.BodyPublishers.ofString(objectMapper.writeValueAsString(payload)))
                .build();

        HttpResponse<String> response = httpClient.send(request, HttpResponse.BodyHandlers.ofString());
        if (response.statusCode() != 200) {
            if (response.statusCode() == 404) {
                throw new ResponseStatusException(HttpStatus.BAD_GATEWAY, "Gemini model " + GEMINI_MODEL + " was not found or is unavailable.");
            }
            throw new ResponseStatusException(HttpStatus.BAD_GATEWAY, "Gemini API returned status " + response.statusCode());
        }

        JsonNode root = objectMapper.readTree(response.body());
        JsonNode textNode = root.path("candidates").path(0).path("content").path("parts").path(0).path("text");
        if (textNode.isMissingNode() || textNode.isNull()) {
            throw new ResponseStatusException(HttpStatus.BAD_GATEWAY, "Gemini response did not include lesson text.");
        }

        return stripMarkdownFence(textNode.asText().trim());
    }

    private String stripMarkdownFence(String text) {
        String rawText = text == null ? "" : text.trim();
        if (rawText.startsWith("```json")) {
            rawText = rawText.substring(7);
        } else if (rawText.startsWith("```") ) {
            rawText = rawText.substring(3);
        }
        if (rawText.endsWith("```")) {
            rawText = rawText.substring(0, rawText.length() - 3);
        }
        return rawText.trim();
    }

    private SandboxWordDto parseSandboxLesson(String json) {
        try {
            JsonNode root = objectMapper.readTree(json);
            SandboxWordDto dto = new SandboxWordDto();
            dto.setEnglishWord(readText(root, "english_word", "englishWord"));
            dto.setCebuanoMeaning(readText(root, "cebuano_meaning", "cebuanoMeaning"));
            dto.setExampleSentenceEnglish(readText(root, "english_example_sentence", "exampleSentenceEnglish"));
            dto.setExampleSentenceCebuano(readText(root, "cebuano_example_sentence", "exampleSentenceCebuano", "cebuano_translation"));
            dto.setPhonologicalTip(readNullableText(root, "phonological_tip", "phonologicalTip", "phonological_tip_key"));
            dto.setMultipleChoiceDistractors(readStringList(root, "multiple_choice_distractors", "multipleChoiceDistractors", "multiple_choice_distractor_sets"));
            dto.setFillInTheBlankSentence(readNullableText(root, "fill_in_the_blank_sentence", "fillInTheBlankSentence"));
            dto.setMatchingSet(readMatchingSet(root.path("matching_set"), root.path("matchingSet")));
            dto.setSentenceArrangementTokens(readStringList(root, "sentence_arrangement_tokens", "sentenceArrangementTokens"));
            dto.setSentenceCompletionBlank(readNullableText(root, "sentence_completion_blank", "sentenceCompletionBlank"));
            dto.setSentenceCompletionOptions(readStringList(root, "sentence_completion_options", "sentenceCompletionOptions"));
            return dto;
        } catch (Exception e) {
            return null;
        }
    }

    private String readText(JsonNode root, String... fieldNames) {
        String value = readNullableText(root, fieldNames);
        return value == null ? "" : value;
    }

    private String readNullableText(JsonNode root, String... fieldNames) {
        for (String fieldName : fieldNames) {
            JsonNode node = root.path(fieldName);
            if (!node.isMissingNode() && !node.isNull()) {
                String value = node.asText(null);
                if (value != null) {
                    value = value.trim();
                    if (!value.isEmpty()) {
                        return value;
                    }
                }
            }
        }
        return null;
    }

    private List<String> readStringList(JsonNode root, String... fieldNames) {
        for (String fieldName : fieldNames) {
            JsonNode node = root.path(fieldName);
            if (node.isArray()) {
                List<String> values = new ArrayList<>();
                for (JsonNode item : node) {
                    if (item.isArray()) {
                        for (JsonNode nested : item) {
                            String text = nested.asText(null);
                            if (text != null && !text.trim().isEmpty()) {
                                values.add(text.trim());
                            }
                        }
                    } else {
                        String text = item.asText(null);
                        if (text != null && !text.trim().isEmpty()) {
                            values.add(text.trim());
                        }
                    }
                }
                return values;
            }
        }
        return Collections.emptyList();
    }

    private List<MatchingEntryDto> readMatchingSet(JsonNode... nodes) {
        for (JsonNode node : nodes) {
            if (node == null || !node.isArray()) {
                continue;
            }

            List<MatchingEntryDto> values = new ArrayList<>();
            for (JsonNode item : node) {
                if (!item.isObject()) {
                    continue;
                }

                String englishWord = readText(item, "english_word", "englishWord", "word");
                String cebuanoMeaning = readText(item, "cebuano_meaning", "cebuanoMeaning", "cebuano_translation", "cebuanoTranslation", "translation");
                if (!englishWord.isEmpty() || !cebuanoMeaning.isEmpty()) {
                    values.add(MatchingEntryDto.builder()
                            .englishWord(englishWord)
                            .cebuanoMeaning(cebuanoMeaning)
                            .cebuanoTranslation(cebuanoMeaning)
                            .build());
                }
            }
            if (!values.isEmpty()) {
                return values;
            }
        }
        return Collections.emptyList();
    }

    private void validateLesson(SandboxWordDto dto, String requestedWord) {
        if (dto.getEnglishWord() == null || dto.getEnglishWord().trim().isEmpty()) {
            throw new ResponseStatusException(HttpStatus.BAD_GATEWAY, "Gemini returned a sandbox lesson without an English word.");
        }

        if (!dto.getEnglishWord().trim().equalsIgnoreCase(requestedWord)) {
            throw new ResponseStatusException(HttpStatus.BAD_GATEWAY, "Gemini returned the wrong sandbox word.");
        }

        if (dto.getCebuanoMeaning() == null || dto.getCebuanoMeaning().trim().isEmpty()) {
            throw new ResponseStatusException(HttpStatus.BAD_GATEWAY, "Gemini returned an empty Cebuano meaning.");
        }

        if (looksLikeReusedEnglish(dto.getCebuanoMeaning(), requestedWord)) {
            throw new ResponseStatusException(HttpStatus.BAD_GATEWAY, "Gemini returned an invalid Cebuano meaning.");
        }

        if (dto.getExampleSentenceEnglish() == null || dto.getExampleSentenceEnglish().trim().isEmpty()) {
            throw new ResponseStatusException(HttpStatus.BAD_GATEWAY, "Gemini returned an empty English example sentence.");
        }

        if (dto.getExampleSentenceCebuano() == null || dto.getExampleSentenceCebuano().trim().isEmpty()) {
            throw new ResponseStatusException(HttpStatus.BAD_GATEWAY, "Gemini returned an empty Cebuano example sentence.");
        }

        if (dto.getMultipleChoiceDistractors() == null || dto.getMultipleChoiceDistractors().size() < 3) {
            throw new ResponseStatusException(HttpStatus.BAD_GATEWAY, "Gemini returned incomplete multiple choice distractors.");
        }

        if (dto.getMatchingSet() == null || dto.getMatchingSet().size() < 3) {
            throw new ResponseStatusException(HttpStatus.BAD_GATEWAY, "Gemini returned an incomplete matching set.");
        }

        if (dto.getSentenceArrangementTokens() == null || dto.getSentenceArrangementTokens().size() < 2) {
            throw new ResponseStatusException(HttpStatus.BAD_GATEWAY, "Gemini returned invalid sentence arrangement tokens.");
        }

        if (dto.getSentenceCompletionBlank() == null || dto.getSentenceCompletionBlank().trim().isEmpty()) {
            throw new ResponseStatusException(HttpStatus.BAD_GATEWAY, "Gemini returned an empty sentence completion blank.");
        }

        if (dto.getSentenceCompletionOptions() == null || dto.getSentenceCompletionOptions().size() < 4) {
            throw new ResponseStatusException(HttpStatus.BAD_GATEWAY, "Gemini returned incomplete sentence completion options.");
        }
    }

    private boolean looksLikeReusedEnglish(String cebuanoMeaning, String englishWord) {
        String normalizedMeaning = normalizeText(cebuanoMeaning);
        String normalizedEnglish = normalizeText(englishWord);
        if (normalizedMeaning.isEmpty() || normalizedEnglish.isEmpty()) {
            return true;
        }

        if (normalizedMeaning.equals(normalizedEnglish) || normalizedMeaning.contains(normalizedEnglish)) {
            return true;
        }

        double similarity = similarityRatio(normalizedMeaning, normalizedEnglish);
        return similarity >= 0.80;
    }

    private String normalizeText(String value) {
        return value == null ? "" : value.toLowerCase(Locale.ROOT).replaceAll("[^a-z]", "");
    }

    private double similarityRatio(String left, String right) {
        int maxLength = Math.max(left.length(), right.length());
        if (maxLength == 0) {
            return 1.0;
        }

        int distance = levenshteinDistance(left, right);
        return 1.0 - ((double) distance / maxLength);
    }

    private int levenshteinDistance(String left, String right) {
        int[][] table = new int[left.length() + 1][right.length() + 1];
        for (int i = 0; i <= left.length(); i++) {
            table[i][0] = i;
        }
        for (int j = 0; j <= right.length(); j++) {
            table[0][j] = j;
        }
        for (int i = 1; i <= left.length(); i++) {
            for (int j = 1; j <= right.length(); j++) {
                int cost = left.charAt(i - 1) == right.charAt(j - 1) ? 0 : 1;
                table[i][j] = Math.min(Math.min(
                        table[i - 1][j] + 1,
                        table[i][j - 1] + 1),
                        table[i - 1][j - 1] + cost);
            }
        }
        return table[left.length()][right.length()];
    }
}
