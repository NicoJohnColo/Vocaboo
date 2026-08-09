package com.vocaboo.service;

import com.vocaboo.entity.*;
import com.vocaboo.repository.BulkImportHistoryRepository;
import com.vocaboo.repository.LessonRepository;
import com.vocaboo.repository.VocabularyWordRepository;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.util.*;

@Service
@RequiredArgsConstructor
public class BulkImportService {

    private static final String CSV_HEADER =
            "english_word,cebuano_meaning,part_of_speech,grade_level,example_sentence_english,example_sentence_cebuano,audio_path,image_path," +
            "distractor_pool,fill_blank_sentence,tile_sentence,hint_text,audio_text_cebuano,audio_text_english,context_paragraph";

    private final LessonRepository lessonRepository;
    private final VocabularyWordRepository wordRepository;
    private final BulkImportHistoryRepository importHistoryRepository;
    private final ObjectMapper objectMapper;
    private final DictionaryValidationService dictionaryValidationService;

    /**
     * Parse and import CSV vocabulary words for a lesson.
     * Returns summary: { success, skipped, errors, import_id }
     */
    @Transactional
    public Map<String, Object> parseAndImportCSV(UUID lessonId, InputStream csvStream, UUID adminId, boolean dryRun) throws IOException {
        Lesson lesson = lessonRepository.findById(lessonId)
                .filter(l -> !Boolean.TRUE.equals(l.getIsDeleted()))
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Lesson not found"));

        List<Map<String, String>> errors = new ArrayList<>();
        int successCount = 0;
        int skippedCount = 0;
        int rowIndex = 0;

        int nextOrder = wordRepository.findMaxWordOrderByLessonId(lessonId) + 1;

        try (BufferedReader reader = new BufferedReader(new InputStreamReader(csvStream, "UTF-8"))) {
            String headerLine = reader.readLine();
            if (headerLine == null) throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "CSV file is empty");

            String line;
            while ((line = reader.readLine()) != null) {
                rowIndex++;
                if (line.isBlank()) continue;

                String[] cols = parseCsvLine(line);

                // Need at least 6 columns (core fields required; activity fields are optional)
                if (cols.length < 6) {
                    errors.add(Map.of("row", String.valueOf(rowIndex), "error", "Too few columns (expected at least 6, got " + cols.length + ")"));
                    continue;
                }

                String englishWord    = cols[0].trim();
                String cebuanoMeaning = cols[1].trim();
                String partOfSpeech   = cols[2].trim();
                String gradeLevel     = cols[3].trim();
                String exampleEn      = cols[4].trim();
                String exampleCeb     = cols.length > 5  ? cols[5].trim()  : "";
                String audioPath      = cols.length > 6  ? cols[6].trim()  : "";
                String imagePath      = cols.length > 7  ? cols[7].trim()  : "";
                // Per-word activity content fields (columns 8-13, all optional)
                String distractorPool     = cols.length > 8  ? cols[8].trim()  : "";
                String fillBlankSentence  = cols.length > 9  ? cols[9].trim()  : "";
                String tileSentence       = cols.length > 10 ? cols[10].trim() : "";
                String hintText           = cols.length > 11 ? cols[11].trim() : "";
                String audioTextCebuano   = cols.length > 12 ? cols[12].trim() : "";
                String audioTextEnglish   = cols.length > 13 ? cols[13].trim() : "";
                String contextParagraph   = cols.length > 14 ? cols[14].trim() : "";

                // If context_paragraph is provided, we save it to the lesson.
                // We do this for the first row that provides it.
                if (!contextParagraph.isBlank() && !dryRun) {
                    if (lesson.getContextParagraph() == null || lesson.getContextParagraph().isBlank()) {
                        lesson.setContextParagraph(contextParagraph);
                        // Save immediately or wait until the end? The end is fine since we call lessonRepository.save(lesson) later.
                    }
                }

                // Validate required fields
                String rowError = validateRow(rowIndex, englishWord, cebuanoMeaning, partOfSpeech, gradeLevel, exampleEn, exampleCeb, fillBlankSentence);
                if (rowError != null) {
                    errors.add(Map.of("row", String.valueOf(rowIndex), "error", rowError));
                    continue;
                }

                // Duplicate check (allow same english word if meaning is different, for homonyms)
                if (wordRepository.existsByLessonLessonIdAndEnglishWordIgnoreCaseAndCebuanoMeaningIgnoreCaseAndIsDeletedFalse(
                        lessonId, englishWord, cebuanoMeaning)) {
                    skippedCount++;
                    continue;
                }

                VocabularyWord word = VocabularyWord.builder()
                        .lesson(lesson)
                        .englishWord(englishWord)
                        .cebuanoMeaning(cebuanoMeaning)
                        .partOfSpeech(partOfSpeech)
                        .gradeLevel(GradeLevel.valueOf(gradeLevel))
                        .exampleSentenceEnglish(exampleEn)
                        .exampleSentenceCebuano(exampleCeb.isBlank() ? null : exampleCeb)
                        .audioAssetPath(audioPath.isBlank() ? null : audioPath)
                        .imageAssetPath(imagePath.isBlank() ? null : imagePath)
                        .wordOrder(nextOrder++)
                        .isConfusablePairMember(false)
                        .isDeleted(false)
                        .distractorPool(distractorPool.isBlank() ? null : distractorPool)
                        .fillBlankSentence(fillBlankSentence.isBlank() ? null : fillBlankSentence)
                        .tileSentence(tileSentence.isBlank() ? null : tileSentence)
                        .hintText(hintText.isBlank() ? null : hintText)
                        .audioTextCebuano(audioTextCebuano.isBlank() ? null : audioTextCebuano)
                        .audioTextEnglish(audioTextEnglish.isBlank() ? null : audioTextEnglish)
                        .build();

                if (!dryRun) {
                    wordRepository.save(word);
                }
                successCount++;
            }
        }

        if (!dryRun) {
            // Update lesson total word count
            lesson.setTotalWordCount((int) wordRepository.countByLessonLessonIdAndIsDeletedFalse(lessonId));
            lessonRepository.save(lesson);
        }

        // Save import history
        String status = errors.isEmpty() ? (skippedCount > 0 ? "PARTIAL" : "SUCCESS") : "PARTIAL";
        if (successCount == 0 && errors.size() > 0) status = "FAILED";

        BulkImportHistory history = BulkImportHistory.builder()
                .lessonId(lessonId)
                .adminId(adminId)
                .totalRows(rowIndex)
                .successCount(successCount)
                .skippedCount(skippedCount)
                .errorCount(errors.size())
                .importStatus(status)
                .errorLog(errors.isEmpty() ? null : objectMapper.writeValueAsString(errors))
                .build();

        BulkImportHistory saved = null;
        if (!dryRun) {
            saved = importHistoryRepository.save(history);
        }

        Map<String, Object> result = new LinkedHashMap<>();
        result.put("success", successCount);
        result.put("skipped", skippedCount);
        result.put("errors", errors);
        result.put("import_id", saved != null ? saved.getImportId() : null);
        return result;
    }

    /** Returns CSV template as a string */
    public String getCsvTemplate() {
        return CSV_HEADER + "\n" +
               "Pencil,Lapis,NOUN,GRADE_4," +
               "\"I use a pencil to write in class.\",\"Naggamit ko og lapis sa pagsulat sa klase.\",,," +
               "eraser;ruler;scissors," +
               "\"I use a {BLANK} to write in class.\"," +
               "\"I use a pencil to write in class.\"," +
               "\"Think of a long thin writing tool.\"," +
               "\"Lapis. Naggamit ko og lapis sa pagsulat sa klase.\"," +
               "\"Pencil. I use a pencil to write in class.\"," +
               "\"I prepare my school bag before leaving. I put my pencil and notebook inside it.\"\n" +
               "Notebook,Kuwaderno,NOUN,GRADE_4," +
               "\"I write my lessons in a notebook.\",\"Nagsulat ko sa akong kuwaderno.\",,," +
               "journal;folder;binder," +
               "\"I write my lessons in a {BLANK}.\"," +
               "\"I write my lessons in a notebook.\"," +
               "\"Think of a book you write notes in.\"," +
               "\"Kuwaderno. Nagsulat ko sa akong kuwaderno.\"," +
               "\"Notebook. I write my lessons in a notebook.\",\"\"\n";
    }

    // ─── helpers ──────────────────────────────────────────────────────────────

    private String validateRow(int rowIndex, String english, String cebuano, String pos, String grade,
                                String exampleEn, String exampleCeb, String fillBlankSentence) {
        List<String> rowErrors = new ArrayList<>();
        if (english.isEmpty() || english.length() < 2 || english.length() > 100) rowErrors.add("english_word must be 2-100 chars");
        if (!english.isEmpty() && !dictionaryValidationService.isValidEnglishWord(english)) rowErrors.add("'" + english + "' is not recognized as a valid English word");
        if (cebuano.isEmpty() || cebuano.length() < 2 || cebuano.length() > 200) rowErrors.add("cebuano_meaning must be 2-200 chars");
        // Note: we do NOT check cebuano_meaning against the English dictionary — many valid Cebuano
        // words (e.g. lapis, bag, nota, hait) coincidentally appear in English dictionaries.
        if (!Set.of("NOUN","VERB","ADJECTIVE").contains(pos)) rowErrors.add("part_of_speech must be NOUN, VERB, or ADJECTIVE");
        if (!Set.of("GRADE_4","GRADE_5","GRADE_6").contains(grade)) rowErrors.add("grade_level must be GRADE_4, GRADE_5, or GRADE_6");
        if (exampleEn.length() < 10 || exampleEn.length() > 500) rowErrors.add("example_sentence_english must be 10-500 chars");

        // Validate English example sentence: meaningful words must be in English dictionary
        if (exampleEn.length() >= 10) {
            List<String> nonEnglish = extractMeaningfulWords(exampleEn).stream()
                    .filter(w -> !dictionaryValidationService.isValidEnglishWord(w))
                    .limit(3)
                    .collect(java.util.stream.Collectors.toList());
            if (!nonEnglish.isEmpty()) {
                rowErrors.add("example_sentence_english contains non-English word(s): " + String.join(", ", nonEnglish));
            }
        }

        // Validate Cebuano example sentence: length only.
        // We intentionally do NOT scan for English words — many common Cebuano words (nako, lapis,
        // nota, among, hait, etc.) hit the English dictionary, causing mass false positives.
        // Code-switching (English words in Cebuano sentences) is also normal in PH classrooms.
        if (!exampleCeb.isEmpty()) {
            if (exampleCeb.length() < 5 || exampleCeb.length() > 500)
                rowErrors.add("example_sentence_cebuano must be 5-500 chars");
        }

        // Validate fill_blank_sentence: must contain {BLANK} placeholder if provided
        if (!fillBlankSentence.isEmpty() && !fillBlankSentence.contains("{BLANK}")) {
            rowErrors.add("fill_blank_sentence must contain the {BLANK} placeholder (e.g. \"I sharpen my {BLANK} before class.\")");
        }

        if (rowErrors.isEmpty()) return null;
        return String.join(" | ", rowErrors);
    }

    /** Extract words with 4+ letters from a sentence for language validation (ignores short/ambiguous words) */
    private List<String> extractMeaningfulWords(String sentence) {
        return java.util.Arrays.stream(sentence.replaceAll("[^a-zA-Z ]", " ").split("\\s+"))
                .map(String::toLowerCase)
                .filter(w -> w.length() >= 4)
                .collect(java.util.stream.Collectors.toList());
    }

    private String[] parseCsvLine(String line) {
        List<String> result = new ArrayList<>();
        boolean inQuotes = false;
        StringBuilder current = new StringBuilder();
        for (char c : line.toCharArray()) {
            if (c == '"') { inQuotes = !inQuotes; }
            else if (c == ',' && !inQuotes) { result.add(current.toString()); current = new StringBuilder(); }
            else { current.append(c); }
        }
        result.add(current.toString());
        return result.toArray(new String[0]);
    }
}
