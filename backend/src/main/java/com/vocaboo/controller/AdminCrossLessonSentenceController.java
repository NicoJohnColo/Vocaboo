package com.vocaboo.controller;

import com.vocaboo.entity.CrossLessonSentence;
import com.vocaboo.repository.CrossLessonSentenceRepository;
import com.vocaboo.repository.VocabularyWordRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/admin/cross-lesson-sentences")
@RequiredArgsConstructor
public class AdminCrossLessonSentenceController {

    private final CrossLessonSentenceRepository repository;
    private final VocabularyWordRepository wordRepository;

    @GetMapping
    public ResponseEntity<List<CrossLessonSentence>> getAll() {
        return ResponseEntity.ok(repository.findAll());
    }

    @PostMapping
    public ResponseEntity<CrossLessonSentence> create(@RequestBody CrossLessonSentence sentence) {
        if (sentence.getWordA() == null || sentence.getWordA().getWordId() == null ||
            sentence.getWordB() == null || sentence.getWordB().getWordId() == null) {
            return ResponseEntity.badRequest().build();
        }
        var wordAOpt = wordRepository.findById(sentence.getWordA().getWordId());
        var wordBOpt = wordRepository.findById(sentence.getWordB().getWordId());
        if (wordAOpt.isEmpty() || wordBOpt.isEmpty()) {
            return ResponseEntity.badRequest().build();
        }
        var wordA = wordAOpt.get();
        var wordB = wordBOpt.get();
        if (wordA.getLesson().getLessonId().equals(wordB.getLesson().getLessonId())) {
            return ResponseEntity.badRequest().build();
        }
        sentence.setWordA(wordA);
        sentence.setWordB(wordB);
        if (sentence.getLessonPairId() == null || sentence.getLessonPairId().isBlank()) {
            sentence.setLessonPairId(wordA.getLesson().getLessonId() + "_" + wordB.getLesson().getLessonId());
        }
        return ResponseEntity.ok(repository.save(sentence));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(@PathVariable UUID id) {
        repository.deleteById(id);
        return ResponseEntity.ok().build();
    }

    @GetMapping("/coverage")
    public ResponseEntity<List<Map<String, Object>>> getCoverageGaps(@RequestParam UUID lesson1Id, @RequestParam UUID lesson2Id) {
        var words1 = wordRepository.findByLessonLessonIdAndIsDeletedFalseOrderByWordOrderAsc(lesson1Id);
        var words2 = wordRepository.findByLessonLessonIdAndIsDeletedFalseOrderByWordOrderAsc(lesson2Id);
        
        words1.addAll(words2);
        
        var gaps = words1.stream().filter(w -> repository.findByWordId(w.getWordId()).isEmpty())
                .map(w -> Map.of(
                        "wordId", (Object) w.getWordId(),
                        "englishWord", (Object) w.getEnglishWord(),
                        "lessonId", (Object) w.getLesson().getLessonId()
                ))
                .collect(Collectors.toList());
                
        return ResponseEntity.ok(gaps);
    }
}
