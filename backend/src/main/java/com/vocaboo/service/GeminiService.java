package com.vocaboo.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.io.IOException;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.time.Duration;
import java.util.*;

@Service
public class GeminiService {

    private static final Map<String, String> CEBUANO_WORD_MAP = new HashMap<>();

    static {
        CEBUANO_WORD_MAP.put("push", "itulak");
        CEBUANO_WORD_MAP.put("pull", "hugot");
        CEBUANO_WORD_MAP.put("run", "dagan");
        CEBUANO_WORD_MAP.put("jump", "lukso");
        CEBUANO_WORD_MAP.put("play", "dula");
        CEBUANO_WORD_MAP.put("open", "abli");
        CEBUANO_WORD_MAP.put("close", "sirado");
        CEBUANO_WORD_MAP.put("take", "kuha");
        CEBUANO_WORD_MAP.put("give", "hatag");
        CEBUANO_WORD_MAP.put("eat", "kaon");
        CEBUANO_WORD_MAP.put("drink", "inom");
        CEBUANO_WORD_MAP.put("read", "basa");
        CEBUANO_WORD_MAP.put("write", "sulat");
        CEBUANO_WORD_MAP.put("walk", "lakaw");
        CEBUANO_WORD_MAP.put("look", "tan-aw");
    }

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
        private String phonologicalTipKey;
        private Boolean isConfusable;
        private String confusablePairWord;
        private String confusableSentenceA;
        private String confusableSentenceB;
        private List<String> multipleChoiceDistractors;
        private String fillInTheBlankSentence;
        private List<Map<String, String>> matchingSet;
        private List<String> sentenceArrangementTokens;
        private String sentenceCompletionBlank;
        private List<String> sentenceCompletionOptions;

        public SandboxWordDto(String englishWord, String cebuanoMeaning, String exampleSentenceEnglish, String exampleSentenceCebuano, String phonologicalTipKey) {
            this.englishWord = englishWord;
            this.cebuanoMeaning = cebuanoMeaning;
            this.exampleSentenceEnglish = exampleSentenceEnglish;
            this.exampleSentenceCebuano = exampleSentenceCebuano;
            this.phonologicalTipKey = phonologicalTipKey;
        }
    }

    private static final String SANDBOX_SYSTEM_PROMPT = "You are a vocabulary lesson generator for Vocaboo, a Cebuano Mother Tongue-First English vocabulary learning app for Filipino children aged 9 to 12 in Cebu City.\n\nWhen the user provides a topic or English word, generate a complete structured vocabulary lesson for exactly ONE English word related to that topic. The word must be age-appropriate, educationally relevant, and suitable for Grade 4 to Grade 6 learners.\n\nYou must respond ONLY with a valid JSON object. Do not include any explanation, preamble, markdown formatting, or text outside the JSON object. The JSON must follow this exact structure:\n\n{\n  \"english_word\": \"string\",\n  \"cebuano_meaning\": \"string\",\n  \"english_example_sentence\": \"string\",\n  \"phonological_tip\": \"string or null\",\n  \"is_confusable\": \"boolean\",\n  \"confusable_pair_word\": \"string or null\",\n  \"confusable_sentence_a\": \"string or null\",\n  \"confusable_sentence_b\": \"string or null\",\n  \"multiple_choice_distractors\": [\"string\", \"string\", \"string\"],\n  \"fill_in_the_blank_sentence\": \"string\",\n  \"matching_set\": [{\"english_word\": \"string\", \"cebuano_meaning\": \"string\"}],\n  \"sentence_arrangement_tokens\": [\"string\"],\n  \"sentence_completion_blank\": \"string\",\n  \"sentence_completion_options\": [\"string\", \"string\", \"string\", \"string\"]\n}\n\nRules you must follow:\n- All Cebuano text must use standardized formal Cebuano orthography.\n- All English sentences must be simple, clear, and appropriate for children aged 9 to 12.\n- The matching_set must always include the target word as one of its entries plus 2 to 3 additional vocabulary words with their Cebuano meanings.\n- The sentence_arrangement_tokens array must contain every word of the english_example_sentence, each as a separate string, in shuffled order.\n- The fill_in_the_blank_sentence and sentence_completion_blank must be different sentences from each other and from the english_example_sentence.\n- Never generate content that is violent, sexual, politically sensitive, religiously offensive, or otherwise inappropriate for child learners.\n- If the user's input is unclear or too vague, choose the most educationally appropriate English word you can derive from the input and generate the full lesson for it.\n- Respond with the JSON object only. No other text.";

    public SandboxWordDto generateSandboxLesson(String userInput) {
        String normalized = userInput == null ? "" : userInput.trim();
        if (geminiApiKey == null || geminiApiKey.trim().isEmpty()) {
            return getOfflineFallbackWord(normalized);
        }

        String userPrompt = normalized.isEmpty() ? "Generate a lesson for a useful child-friendly vocabulary word." : normalized;
        try {
            String responseBody = callGeminiApi(SANDBOX_SYSTEM_PROMPT, userPrompt);
            SandboxWordDto parsed = parseSandboxLesson(responseBody);
            return parsed != null ? parsed : getOfflineFallbackWord(normalized);
        } catch (Exception e) {
            System.err.println("Error calling Gemini API for sandbox lesson: " + e.getMessage());
            return getOfflineFallbackWord(normalized);
        }
    }

    public List<SandboxWordDto> generateTopicWords(String topic) {
        String normalizedTopic = topic.toLowerCase().trim();
        if (geminiApiKey == null || geminiApiKey.trim().isEmpty()) {
            System.out.println("Gemini API key not configured. Using offline fallback for topic: " + topic);
            return getOfflineFallbackTopic(normalizedTopic);
        }

        String prompt = "Generate exactly 5 child-friendly vocabulary words for 9-12 year old Filipino children learning English/Cebuano related to the topic: \"" + topic + "\". " +
                "For each word, return a JSON object with keys: " +
                "\"englishWord\" (string), \"cebuanoMeaning\" (string), \"exampleSentenceEnglish\" (string, Grade 4 level), \"exampleSentenceCebuano\" (string), and \"phonologicalTipKey\" (string, one of: 'th_sound', 'f_sound', 'v_sound', 'sh_sound', 'short_i', or null/empty if none applies). " +
                "Return the result as a raw JSON array of objects. Do not include markdown backticks or formatting. Only raw JSON.";

        try {
            String responseBody = callGeminiApi(prompt);
            List<SandboxWordDto> parsed = parseJsonArray(responseBody);
            return parsed.isEmpty() ? getOfflineFallbackTopic(normalizedTopic) : parsed;
        } catch (Exception e) {
            System.err.println("Error calling Gemini API for topic \"" + topic + "\": " + e.getMessage() + ". Using fallback.");
            return getOfflineFallbackTopic(normalizedTopic);
        }
    }

    public SandboxWordDto generateCustomWord(String word) {
        String normalizedWord = word.trim();
        if (geminiApiKey == null || geminiApiKey.trim().isEmpty()) {
            System.out.println("Gemini API key not configured. Using offline fallback for word: " + word);
            return getOfflineFallbackWord(normalizedWord);
        }

        String prompt = "Generate child-friendly vocabulary details for the single English word: \"" + word + "\". " +
                "Return a JSON object with keys: " +
                "\"englishWord\" (string, exact word), \"cebuanoMeaning\" (string, Cebuano translation/meaning), \"exampleSentenceEnglish\" (string, Grade 4 level containing the word), \"exampleSentenceCebuano\" (string, Cebuano translation of the example sentence), and \"phonologicalTipKey\" (string, one of: 'th_sound', 'f_sound', 'v_sound', 'sh_sound', 'short_i', or null/empty if none applies). " +
                "Return only the raw JSON object. Do not include markdown backticks or formatting. Only raw JSON.";

        try {
            String responseBody = callGeminiApi(prompt);
            SandboxWordDto parsed = parseJsonObject(responseBody);
            return parsed != null ? parsed : getOfflineFallbackWord(normalizedWord);
        } catch (Exception e) {
            System.err.println("Error calling Gemini API for word \"" + word + "\": " + e.getMessage() + ". Using fallback.");
            return getOfflineFallbackWord(normalizedWord);
        }
    }

    private String callGeminiApi(String prompt) throws IOException, InterruptedException {
        return callGeminiApi(null, prompt);
    }

    private String callGeminiApi(String systemPrompt, String prompt) throws IOException, InterruptedException {
        String url = "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=" + geminiApiKey;

        // Build Gemini payload
        Map<String, Object> textPart = Map.of("text", prompt);
        Map<String, Object> parts = Map.of("parts", List.of(textPart));
        Map<String, Object> payload = new LinkedHashMap<>();
        if (systemPrompt != null && !systemPrompt.isBlank()) {
            payload.put("system_instruction", Map.of("parts", List.of(Map.of("text", systemPrompt))));
        }
        payload.put("contents", List.of(parts));
        String requestBody = objectMapper.writeValueAsString(payload);

        HttpRequest request = HttpRequest.newBuilder()
                .uri(URI.create(url))
                .header("Content-Type", "application/json")
                .POST(HttpRequest.BodyPublishers.ofString(requestBody))
                .build();

        HttpResponse<String> response = httpClient.send(request, HttpResponse.BodyHandlers.ofString());

        if (response.statusCode() != 200) {
            throw new IOException("Gemini API returned status " + response.statusCode() + ": " + response.body());
        }

        // Parse text field from response
        JsonNode root = objectMapper.readTree(response.body());
        String rawText = root.path("candidates")
                .path(0)
                .path("content")
                .path("parts")
                .path(0)
                .path("text")
                .asText();

        // Clean up markdown block if present
        if (rawText != null) {
            rawText = rawText.trim();
            if (rawText.startsWith("```json")) {
                rawText = rawText.substring(7);
            } else if (rawText.startsWith("```")) {
                rawText = rawText.substring(3);
            }
            if (rawText.endsWith("```")) {
                rawText = rawText.substring(0, rawText.length() - 3);
            }
            rawText = rawText.trim();
        }

        return rawText;
    }

    private SandboxWordDto parseSandboxLesson(String json) {
        try {
            JsonNode root = objectMapper.readTree(json);
            SandboxWordDto dto = new SandboxWordDto();
            dto.setEnglishWord(root.path("english_word").asText(null));
            dto.setCebuanoMeaning(root.path("cebuano_meaning").asText(null));
            dto.setExampleSentenceEnglish(root.path("english_example_sentence").asText(null));
            JsonNode tip = root.get("phonological_tip");
            dto.setPhonologicalTipKey(tip == null || tip.isNull() ? null : tip.asText(null));
            dto.setIsConfusable(root.path("is_confusable").asBoolean(false));
            dto.setConfusablePairWord(root.path("confusable_pair_word").asText(null));
            dto.setConfusableSentenceA(root.path("confusable_sentence_a").asText(null));
            dto.setConfusableSentenceB(root.path("confusable_sentence_b").asText(null));
            dto.setMultipleChoiceDistractors(readStringList(root.get("multiple_choice_distractors")));
            dto.setFillInTheBlankSentence(root.path("fill_in_the_blank_sentence").asText(null));
            dto.setMatchingSet(readMatchingSet(root.get("matching_set")));
            dto.setSentenceArrangementTokens(readStringList(root.get("sentence_arrangement_tokens")));
            dto.setSentenceCompletionBlank(root.path("sentence_completion_blank").asText(null));
            dto.setSentenceCompletionOptions(readStringList(root.get("sentence_completion_options")));
            return dto.getEnglishWord() == null || dto.getEnglishWord().isBlank() ? null : dto;
        } catch (Exception e) {
            return null;
        }
    }

    private List<String> readStringList(JsonNode node) {
        if (node == null || !node.isArray()) {
            return Collections.emptyList();
        }
        List<String> values = new ArrayList<>();
        for (JsonNode item : node) {
            values.add(item.asText());
        }
        return values;
    }

    private List<Map<String, String>> readMatchingSet(JsonNode node) {
        if (node == null || !node.isArray()) {
            return Collections.emptyList();
        }
        List<Map<String, String>> values = new ArrayList<>();
        for (JsonNode item : node) {
            Map<String, String> entry = new LinkedHashMap<>();
            entry.put("english_word", item.path("english_word").asText(""));
            entry.put("cebuano_meaning", item.path("cebuano_meaning").asText(""));
            values.add(entry);
        }
        return values;
    }

    private SandboxWordDto parseJsonObject(String json) {
        try {
            SandboxWordDto dto = objectMapper.readValue(json, SandboxWordDto.class);
            if (dto.getEnglishWord() == null || dto.getEnglishWord().trim().isEmpty()) {
                return null;
            }
            return dto;
        } catch (Exception e) {
            System.err.println("Failed to parse JSON object: " + e.getMessage());
            return null;
        }
    }

    private List<SandboxWordDto> parseJsonArray(String json) {
        try {
            List<SandboxWordDto> list = Arrays.asList(objectMapper.readValue(json, SandboxWordDto[].class));
            list.removeIf(dto -> dto == null || dto.getEnglishWord() == null || dto.getEnglishWord().trim().isEmpty());
            return list;
        } catch (Exception e) {
            System.err.println("Failed to parse JSON array: " + e.getMessage());
            return Collections.emptyList();
        }
    }

    private List<SandboxWordDto> getOfflineFallbackTopic(String topic) {
        List<SandboxWordDto> list = new ArrayList<>();
        if (topic.contains("weather")) {
            list.add(new SandboxWordDto("Rain", "Ulan", "The rain watered the green grass.", "Ang ulan nagbisibis sa lunhaw nga sagbot.", null));
            list.add(new SandboxWordDto("Sun", "Adlaw", "The sun shines brightly in the sky.", "Ang adlaw misidlak sa langit.", null));
            list.add(new SandboxWordDto("Cloud", "Panganod", "I see a white cloud in the sky.", "Nakakita ko og puti nga panganod sa langit.", null));
            list.add(new SandboxWordDto("Wind", "Hangin", "The strong wind blew the leaves away.", "Ang kusog nga hangin nagpalid sa mga dahon.", null));
            list.add(new SandboxWordDto("Storm", "Bagyo", "The heavy storm made a loud sound.", "Ang kusog nga bagyo naghimo og kusog nga tingog.", null));
        } else if (topic.contains("colors")) {
            list.add(new SandboxWordDto("Red", "Pula", "The red apple is sweet.", "Pula ug tam-is ang mansanas.", null));
            list.add(new SandboxWordDto("Blue", "Asul", "The sky is clear and blue today.", "Ang langit tinaw ug asul karon.", null));
            list.add(new SandboxWordDto("Green", "Berde", "The grass is green and tall.", "Ang sagbot berde ug taas.", null));
            list.add(new SandboxWordDto("Yellow", "Dalag", "The yellow banana tastes sweet.", "Lami ug dalag ang saging.", null));
            list.add(new SandboxWordDto("Black", "Itom", "The black cat is very cute.", "Cute kaayo ang itom nga iring.", null));
        } else if (topic.contains("sports")) {
            list.add(new SandboxWordDto("Ball", "Bola", "He kicked the red ball into the goal.", "Iyang gisipa ang pula nga bola ngadto sa tumong.", null));
            list.add(new SandboxWordDto("Run", "Dagan", "I like to run in the big playground.", "Ganahan ko modagan sa dako nga dulaanan.", null));
            list.add(new SandboxWordDto("Jump", "Layat", "The kids jump high in the air.", "Ang mga bata naglukso-lukso sa hangin.", null));
            list.add(new SandboxWordDto("Swim", "Langoy", "I can swim in the cool pool.", "Makahimo ko sa paglangoy sa bugnaw nga pool.", null));
            list.add(new SandboxWordDto("Play", "Dula", "We play basketball with my friends.", "Nagdula kami og basketball uban sa akong mga higala.", null));
        } else if (topic.contains("family")) {
            list.add(new SandboxWordDto("Mother", "Inahan", "My mother teaches me how to read.", "Ang akong inahan nagtudlo kanako unsaon pagbasa.", null));
            list.add(new SandboxWordDto("Father", "Amahan", "My father builds a nice wooden house.", "Ang akong amahan naghimo og nindot nga balay nga kahoy.", "f_sound"));
            list.add(new SandboxWordDto("Sister", "Igsoon nga babaye", "My sister shares her toys with me.", "Ang akong igsoon nga babaye nagpaambit sa iyang mga dulaan kanako.", null));
            list.add(new SandboxWordDto("Brother", "Igsoon nga lalaki", "My brother helps me tie my shoes.", "Ang akong igsoon nga lalaki motabang nako sa paghigot sa akong sapatos.", "th_sound"));
            list.add(new SandboxWordDto("Baby", "Bata", "The baby sleeps peacefully in the crib.", "Ang bata malinawong natulog sa kuna.", null));
        } else {
            // Default animals fallback
            list.add(new SandboxWordDto("Dog", "Iro", "The dog barks at the mailman.", "Ang iro motiyabaw sa kartero.", null));
            list.add(new SandboxWordDto("Cat", "Iring", "The cat sleeps on the soft mat.", "Ang iring matulog sa humok nga banig.", null));
            list.add(new SandboxWordDto("Bird", "Langgam", "The bird sings a beautiful song.", "Ang langgam nag-awit og matahum nga kanta.", null));
            list.add(new SandboxWordDto("Fish", "Isda", "The fish swims in the clear water.", "Ang isda naglangoy sa tinaw nga tubig.", "f_sound"));
            list.add(new SandboxWordDto("Lion", "Liyon", "The lion has a loud roar.", "Ang liyon adunay kusog nga ngulob.", null));
        }
        return list;
    }

    private SandboxWordDto getOfflineFallbackWord(String word) {
        String lowerWord = word.toLowerCase().trim();
        if (lowerWord.equals("telescope")) {
            return new SandboxWordDto("Telescope", "Teleskopyo", "I use a telescope to see the stars.", "Gigamit nako ang teleskopyo aron makita ang mga bituon.", null);
        } else if (lowerWord.equals("computer")) {
            return new SandboxWordDto("Computer", "Kompyuter", "I play educational games on the computer.", "Nagdula ko og mga dula nga pang-edukasyon sa kompyuter.", null);
        } else if (lowerWord.equals("microphone")) {
            return new SandboxWordDto("Microphone", "Maikropono", "Speak clearly into the microphone.", "Isulti sa klaro ngadto sa microphone.", "f_sound");
        } else if (lowerWord.equals("airplane")) {
            return new SandboxWordDto("Airplane", "Eroplano", "The big airplane flies high above the clouds.", "Naglupad ang dakong eroplano sa ibabaw sa mga panganod.", null);
        } else if (lowerWord.equals("ocean")) {
            return new SandboxWordDto("Ocean", "Dagat", "The ocean is deep and blue.", "Lalum ug asul ang dagat.", "sh_sound");
        }

        // Generic mock generation rules
        String cebuanoMeaning = resolveCebuanoMeaning(lowerWord, word);
        String exampleSentenceEnglish = "This is a sentence showing the word " + word + ".";
        String exampleSentenceCebuano = "Kini usa ka sentence nga nagpakita sa pulong nga " + cebuanoMeaning + ".";
        String phonologicalTipKey = null;
        if (lowerWord.contains("th")) {
            phonologicalTipKey = "th_sound";
        } else if (lowerWord.contains("f")) {
            phonologicalTipKey = "f_sound";
        } else if (lowerWord.contains("v")) {
            phonologicalTipKey = "v_sound";
        } else if (lowerWord.contains("sh")) {
            phonologicalTipKey = "sh_sound";
        }

        SandboxWordDto dto = new SandboxWordDto(word, cebuanoMeaning, exampleSentenceEnglish, exampleSentenceCebuano, phonologicalTipKey);
        dto.setIsConfusable(false);
        dto.setMultipleChoiceDistractors(List.of("apple", "house", "water"));
        dto.setFillInTheBlankSentence("I saw a " + word + " today.");
        dto.setMatchingSet(List.of(
                Map.of("english_word", word, "cebuano_meaning", cebuanoMeaning),
                Map.of("english_word", "apple", "cebuano_meaning", "mansanas"),
                Map.of("english_word", "house", "cebuano_meaning", "balay")
        ));
        dto.setSentenceArrangementTokens(Arrays.asList("I", "saw", "a", word, "today."));
        dto.setSentenceCompletionBlank("I saw a ___ today.");
        dto.setSentenceCompletionOptions(List.of(word, "apple", "house", "water"));
        return dto;
    }

    private String resolveCebuanoMeaning(String lowerWord, String originalWord) {
        String mapped = CEBUANO_WORD_MAP.get(lowerWord);
        if (mapped != null && !mapped.isBlank()) {
            return mapped;
        }
        return originalWord + " (Binisaya)";
    }
}
