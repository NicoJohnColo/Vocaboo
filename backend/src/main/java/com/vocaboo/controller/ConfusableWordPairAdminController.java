package com.vocaboo.controller;

import com.vocaboo.entity.ConfusableWordPair;
import com.vocaboo.entity.Lesson;
import com.vocaboo.entity.VocabularyWord;
import com.vocaboo.repository.ConfusableWordPairRepository;
import com.vocaboo.repository.LessonRepository;
import com.vocaboo.repository.VocabularyWordRepository;
import com.vocaboo.service.ConfusableWordValidationService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;

import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/admin/lessons/{lessonId}")
@RequiredArgsConstructor
@PreAuthorize("hasRole('ADMIN')")
public class ConfusableWordPairAdminController {

    private final ConfusableWordPairRepository pairRepository;
    private final ConfusableWordValidationService validationService;
    private final LessonRepository lessonRepository;
    private final VocabularyWordRepository wordRepository;

    /** GET /api/admin/lessons/{lessonId}/confusable-pairs — List all pairs */
    @GetMapping("/confusable-pairs")
    public ResponseEntity<List<Map<String, Object>>> listPairs(@PathVariable UUID lessonId) {
        List<Map<String, Object>> pairs = pairRepository.findByLessonLessonId(lessonId)
                .stream()
                .map(p -> Map.<String, Object>of(
                        "pair_id", p.getPairId(),
                        "lesson_id", p.getLesson().getLessonId(),
                        "word_a", Map.of(
                                "word_id", p.getWordA().getWordId(),
                                "english_word", p.getWordA().getEnglishWord(),
                                "cebuano_meaning", p.getWordA().getCebuanoMeaning()
                        ),
                        "word_b", Map.of(
                                "word_id", p.getWordB().getWordId(),
                                "english_word", p.getWordB().getEnglishWord(),
                                "cebuano_meaning", p.getWordB().getCebuanoMeaning()
                        ),
                        "contrastive_sentence_a", p.getContrastiveSentenceA(),
                        "contrastive_sentence_b", p.getContrastiveSentenceB(),
                        "created_at", p.getCreatedAt()
                ))
                .collect(Collectors.toList());
        return ResponseEntity.ok(pairs);
    }

    /** GET /api/admin/lessons/{lessonId}/confusable-pairs/words — Word selector list */
    @GetMapping("/confusable-pairs/words")
    public ResponseEntity<List<Map<String, Object>>> getWordSelector(@PathVariable UUID lessonId) {
        return ResponseEntity.ok(validationService.getWordsForPairSelector(lessonId));
    }

    /**
     * GET /api/admin/lessons/{lessonId}/confusable-pairs/suggest
     * Returns heuristic-based confusable pair suggestions for the lesson vocabulary.
     */
    @GetMapping("/confusable-pairs/suggest")
    public ResponseEntity<List<Map<String, Object>>> getSuggestions(@PathVariable UUID lessonId) {
        return ResponseEntity.ok(validationService.suggestConfusablePairs(lessonId));
    }

    /** POST /api/admin/lessons/{lessonId}/confusable-pairs — Create pair */
    @PostMapping("/confusable-pairs")
    public ResponseEntity<Map<String, Object>> createPair(
            @PathVariable UUID lessonId,
            @RequestBody Map<String, String> body) {

        String wordAIdStr = body.get("word_a_id");
        String wordBIdStr = body.get("word_b_id");
        String sentenceA  = body.get("contrastive_sentence_a");
        String sentenceB  = body.get("contrastive_sentence_b");

        if (wordAIdStr == null || wordAIdStr.isBlank()) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "word_a_id is required");
        }
        if (wordBIdStr == null || wordBIdStr.isBlank()) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "word_b_id is required");
        }
        if (sentenceA == null || sentenceA.isBlank() || sentenceB == null || sentenceB.isBlank()) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST,
                    "Both contrastive sentences are required");
        }

        UUID wordAId, wordBId;
        try {
            wordAId = UUID.fromString(wordAIdStr);
            wordBId = UUID.fromString(wordBIdStr);
        } catch (IllegalArgumentException e) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Invalid word ID format");
        }

        // Validate both words exist in lesson, are not deleted, and not already paired
        validationService.validateBothWordsExist(wordAId, wordBId, lessonId);

        Lesson lesson = lessonRepository.findById(lessonId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND,
                        "Lesson not found"));
        VocabularyWord wordA = wordRepository.findById(wordAId).orElseThrow();
        VocabularyWord wordB = wordRepository.findById(wordBId).orElseThrow();

        // Mark both words as confusable pair members
        wordA.setIsConfusablePairMember(true);
        wordB.setIsConfusablePairMember(true);
        wordRepository.save(wordA);
        wordRepository.save(wordB);

        ConfusableWordPair pair = ConfusableWordPair.builder()
                .lesson(lesson)
                .wordA(wordA)
                .wordB(wordB)
                .contrastiveSentenceA(sentenceA)
                .contrastiveSentenceB(sentenceB)
                .build();

        ConfusableWordPair saved = pairRepository.save(pair);
        return ResponseEntity.status(HttpStatus.CREATED).body(Map.of(
                "pair_id", saved.getPairId(),
                "status", "created",
                "word_a", wordA.getEnglishWord(),
                "word_b", wordB.getEnglishWord()
        ));
    }

    /** DELETE /api/admin/lessons/{lessonId}/confusable-pairs/{pairId} — Delete pair */
    @DeleteMapping("/confusable-pairs/{pairId}")
    public ResponseEntity<Void> deletePair(
            @PathVariable UUID lessonId,
            @PathVariable UUID pairId) {

        ConfusableWordPair pair = pairRepository.findById(pairId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND,
                        "Pair not found"));

        VocabularyWord wordA = pair.getWordA();
        VocabularyWord wordB = pair.getWordB();
        pairRepository.delete(pair);

        // Re-evaluate confusable pair membership using dedicated repository query
        boolean aHasPairs = !pairRepository
                .findByLessonAndWord(lessonId, wordA.getWordId())
                .isEmpty();
        boolean bHasPairs = !pairRepository
                .findByLessonAndWord(lessonId, wordB.getWordId())
                .isEmpty();

        wordA.setIsConfusablePairMember(aHasPairs);
        wordB.setIsConfusablePairMember(bHasPairs);
        wordRepository.save(wordA);
        wordRepository.save(wordB);

        return ResponseEntity.noContent().build();
    }
}
