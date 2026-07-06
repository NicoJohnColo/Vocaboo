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
            "english_word,cebuano_meaning,part_of_speech,grade_level,example_sentence_english,example_sentence_cebuano,audio_path,image_path";

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

                // Need at least 6 columns
                if (cols.length < 6) {
                    errors.add(Map.of("row", String.valueOf(rowIndex), "error", "Too few columns (expected 8, got " + cols.length + ")"));
                    continue;
                }

                String englishWord = cols[0].trim();
                String cebuanoMeaning = cols[1].trim();
                String partOfSpeech = cols[2].trim();
                String gradeLevel = cols[3].trim();
                String exampleEn = cols[4].trim();
                String exampleCeb = cols.length > 5 ? cols[5].trim() : "";
                String audioPath = cols.length > 6 ? cols[6].trim() : "";
                String imagePath = cols.length > 7 ? cols[7].trim() : "";

                // Validate required fields
                String rowError = validateRow(rowIndex, englishWord, cebuanoMeaning, partOfSpeech, gradeLevel, exampleEn, exampleCeb);
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
               "Pencil,Lapis,NOUN,GRADE_4,I write with a pencil.,Nagsulat ko og lapis.,,\n" +
               "Notebook,Kuwaderno,NOUN,GRADE_4,I store notes in my notebook.,Gitipigan ko ang akong mga nota sa kuwaderno.,,\n";
    }

    // ─── helpers ──────────────────────────────────────────────────────────────

    private String validateRow(int rowIndex, String english, String cebuano, String pos, String grade, String exampleEn, String exampleCeb) {
        List<String> rowErrors = new ArrayList<>();
        if (english.isEmpty() || english.length() < 2 || english.length() > 100) rowErrors.add("english_word must be 2-100 chars");
        if (!english.isEmpty() && !dictionaryValidationService.isValidEnglishWord(english)) rowErrors.add("'" + english + "' is not recognized as a valid English word");
        if (cebuano.isEmpty() || cebuano.length() < 2 || cebuano.length() > 200) rowErrors.add("cebuano_meaning must be 2-200 chars");
        if (!cebuano.isEmpty() && dictionaryValidationService.isValidEnglishWord(cebuano)) rowErrors.add("'" + cebuano + "' appears to be an English word, not Cebuano");
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

        // Validate Cebuano example sentence: meaningful words must NOT be English words
        if (!exampleCeb.isEmpty()) {
            if (exampleCeb.length() < 5 || exampleCeb.length() > 500)
                rowErrors.add("example_sentence_cebuano must be 5-500 chars");
            List<String> englishInCeb = extractMeaningfulWords(exampleCeb).stream()
                    .filter(w -> dictionaryValidationService.isValidEnglishWord(w))
                    .limit(3)
                    .collect(java.util.stream.Collectors.toList());
            if (!englishInCeb.isEmpty()) {
                rowErrors.add("example_sentence_cebuano appears to contain English word(s): " + String.join(", ", englishInCeb));
            }
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
