package com.vocaboo.service;

import com.vocaboo.dto.request.AddVocabularyRequest;
import com.vocaboo.dto.request.UpdateVocabularyRequest;
import com.vocaboo.dto.response.AdminVocabularyResponse;
import com.vocaboo.entity.*;
import com.vocaboo.exception.ValidationException;
import com.vocaboo.repository.LessonRepository;
import com.vocaboo.repository.VocabularyWordRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import jakarta.annotation.PostConstruct;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Slf4j
public class VocabularyManagementService {

    private final VocabularyWordRepository wordRepository;
    private final LessonRepository lessonRepository;
    private final JdbcTemplate jdbcTemplate;

    @PostConstruct
    @Transactional
    public void cleanupSoftDeletedWords() {
        log.info("Cleaning up previously soft-deleted words from Supabase...");
        List<VocabularyWord> deletedWords = wordRepository.findAll().stream()
                .filter(w -> Boolean.TRUE.equals(w.getIsDeleted()))
                .toList();

        for (VocabularyWord word : deletedWords) {
            UUID wordId = word.getWordId();
            jdbcTemplate.update("DELETE FROM diagnostic_results WHERE word_id = ?", wordId);
            jdbcTemplate.update("DELETE FROM pronunciation_attempts WHERE word_id = ?", wordId);
            jdbcTemplate.update("DELETE FROM word_progress WHERE word_id = ?", wordId);
            jdbcTemplate.update("DELETE FROM confusable_word_pairs WHERE word_a_id = ? OR word_b_id = ?", wordId, wordId);
            jdbcTemplate.update("DELETE FROM review_items WHERE word_id = ?", wordId);
            
            wordRepository.delete(word);
        }
        log.info("Successfully permanently deleted {} previously soft-deleted words.", deletedWords.size());
    }

    @Transactional(readOnly = true)
    public List<AdminVocabularyResponse> getWordsForLesson(UUID lessonId) {
        findActiveLesson(lessonId); // validate lesson exists
        return wordRepository.findByLessonLessonIdAndIsDeletedFalseOrderByWordOrderAsc(lessonId)
                .stream()
                .map(this::toAdminResponse)
                .collect(Collectors.toList());
    }

    @Transactional
    public AdminVocabularyResponse addWord(UUID lessonId, AddVocabularyRequest req) {
        Lesson lesson = findActiveLesson(lessonId);

        // Duplicate check (allow same english word if meaning is different, for homonyms)
        if (wordRepository.existsByLessonLessonIdAndEnglishWordIgnoreCaseAndCebuanoMeaningIgnoreCaseAndIsDeletedFalse(
                lessonId, req.getEnglishWord(), req.getCebuanoMeaning())) {
            throw new ValidationException("english_word", "A word with this English name and meaning already exists in this lesson");
        }

        int nextOrder = wordRepository.findMaxWordOrderByLessonId(lessonId) + 1;

        VocabularyWord word = VocabularyWord.builder()
                .lesson(lesson)
                .englishWord(req.getEnglishWord().trim())
                .cebuanoMeaning(req.getCebuanoMeaning().trim())
                .partOfSpeech(req.getPartOfSpeech())
                .gradeLevel(GradeLevel.valueOf(req.getGradeLevel()))
                .exampleSentenceEnglish(req.getExampleSentenceEnglish().trim())
                .exampleSentenceCebuano(req.getExampleSentenceCebuano() != null ? req.getExampleSentenceCebuano().trim() : null)
                .audioAssetPath(req.getAudioAssetPath())
                .imageAssetPath(req.getImageAssetPath())
                .wordOrder(nextOrder)
                .isConfusablePairMember(req.getIsConfusablePairMember() != null ? req.getIsConfusablePairMember() : false)
                .isDeleted(false)
                .distractorPool(req.getDistractorPool())
                .fillBlankSentence(req.getFillBlankSentence())
                .tileSentence(req.getTileSentence())
                .explanationText(req.getExplanationText())
                .audioTextCebuano(req.getAudioTextCebuano())
                .audioTextEnglish(req.getAudioTextEnglish())
                .phonologicalTipKey(req.getPhonologicalTipKey())
                .build();

        if (req.getEligibleActivityTypes() != null) {
            word.setEligibleActivityTypes(req.getEligibleActivityTypes());
        }

        VocabularyWord saved = wordRepository.save(word);

        // Update lesson word count
        lesson.setTotalWordCount((int) wordRepository.countByLessonLessonIdAndIsDeletedFalse(lessonId));
        lessonRepository.save(lesson);

        return toAdminResponse(saved);
    }

    @Transactional
    public AdminVocabularyResponse updateWord(UUID lessonId, UUID wordId, UpdateVocabularyRequest req) {
        findActiveLesson(lessonId);
        VocabularyWord word = findActiveWord(lessonId, wordId);

        if (req.getEnglishWord() != null && !req.getEnglishWord().isBlank()) {
            word.setEnglishWord(req.getEnglishWord().trim());
        }
        if (req.getCebuanoMeaning() != null && !req.getCebuanoMeaning().isBlank()) {
            word.setCebuanoMeaning(req.getCebuanoMeaning().trim());
        }
        if (req.getPartOfSpeech() != null && !req.getPartOfSpeech().isBlank()) {
            word.setPartOfSpeech(req.getPartOfSpeech());
        }
        if (req.getExampleSentenceEnglish() != null && !req.getExampleSentenceEnglish().isBlank()) {
            word.setExampleSentenceEnglish(req.getExampleSentenceEnglish().trim());
        }
        if (req.getExampleSentenceCebuano() != null) {
            word.setExampleSentenceCebuano(req.getExampleSentenceCebuano().trim());
        }
        if (req.getAudioAssetPath() != null) {
            word.setAudioAssetPath(req.getAudioAssetPath());
        }
        if (req.getImageAssetPath() != null) {
            word.setImageAssetPath(req.getImageAssetPath());
        }
        if (req.getDistractorPool() != null) {
            word.setDistractorPool(req.getDistractorPool());
        }
        if (req.getFillBlankSentence() != null) {
            word.setFillBlankSentence(req.getFillBlankSentence());
        }
        if (req.getTileSentence() != null) {
            word.setTileSentence(req.getTileSentence());
        }
        if (req.getExplanationText() != null) {
            word.setExplanationText(req.getExplanationText());
        }
        if (req.getAudioTextCebuano() != null) {
            word.setAudioTextCebuano(req.getAudioTextCebuano());
        }
        if (req.getAudioTextEnglish() != null) {
            word.setAudioTextEnglish(req.getAudioTextEnglish());
        }
        if (req.getEligibleActivityTypes() != null) {
            word.setEligibleActivityTypes(req.getEligibleActivityTypes());
        }
        if (req.getPhonologicalTipKey() != null) {
            word.setPhonologicalTipKey(req.getPhonologicalTipKey());
        }
        if (req.getIsConfusablePairMember() != null) {
            word.setIsConfusablePairMember(req.getIsConfusablePairMember());
        }

        return toAdminResponse(wordRepository.save(word));
    }

    @Transactional
    public void deleteWord(UUID lessonId, UUID wordId) {
        Lesson lesson = findActiveLesson(lessonId);
        VocabularyWord word = findActiveWord(lessonId, wordId);

        // Manually cascade delete to bypass rogue foreign keys
        jdbcTemplate.update("DELETE FROM diagnostic_results WHERE word_id = ?", wordId);
        jdbcTemplate.update("DELETE FROM pronunciation_attempts WHERE word_id = ?", wordId);
        jdbcTemplate.update("DELETE FROM word_progress WHERE word_id = ?", wordId);
        jdbcTemplate.update("DELETE FROM confusable_word_pairs WHERE word_a_id = ? OR word_b_id = ?", wordId, wordId);
        jdbcTemplate.update("DELETE FROM review_items WHERE word_id = ?", wordId);
        
        // Hard delete the word
        wordRepository.delete(word);

        // Update lesson word count
        lesson.setTotalWordCount((int) wordRepository.countByLessonLessonIdAndIsDeletedFalse(lessonId));
        lessonRepository.save(lesson);
    }

    // ─── helpers ──────────────────────────────────────────────────────────────

    private Lesson findActiveLesson(UUID lessonId) {
        return lessonRepository.findById(lessonId)
                .filter(l -> !Boolean.TRUE.equals(l.getIsDeleted()))
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Lesson not found"));
    }

    private VocabularyWord findActiveWord(UUID lessonId, UUID wordId) {
        VocabularyWord word = wordRepository.findById(wordId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Word not found"));
        if (Boolean.TRUE.equals(word.getIsDeleted())) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Word not found");
        }
        if (!word.getLesson().getLessonId().equals(lessonId)) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Word does not belong to this lesson");
        }
        return word;
    }

    private AdminVocabularyResponse toAdminResponse(VocabularyWord w) {
        return AdminVocabularyResponse.builder()
                .wordId(w.getWordId())
                .lessonId(w.getLesson().getLessonId())
                .englishWord(w.getEnglishWord())
                .cebuanoMeaning(w.getCebuanoMeaning())
                .partOfSpeech(w.getPartOfSpeech())
                .gradeLevel(w.getGradeLevel() != null ? w.getGradeLevel().name() : null)
                .wordOrder(w.getWordOrder())
                .exampleSentenceEnglish(w.getExampleSentenceEnglish())
                .exampleSentenceCebuano(w.getExampleSentenceCebuano())
                .audioAssetPath(w.getAudioAssetPath())
                .imageAssetPath(w.getImageAssetPath())
                .audioVerified(w.getAudioVerified())
                .imageVerified(w.getImageVerified())
                .isConfusablePairMember(w.getIsConfusablePairMember())
                .phonologicalTipKey(w.getPhonologicalTipKey())
                .createdAt(w.getCreatedAt())
                .updatedAt(w.getUpdatedAt())
                .distractorPool(w.getDistractorPool())
                .fillBlankSentence(w.getFillBlankSentence())
                .tileSentence(w.getTileSentence())
                .explanationText(w.getExplanationText())
                .audioTextCebuano(w.getAudioTextCebuano())
                .audioTextEnglish(w.getAudioTextEnglish())
                .build();
    }
}
