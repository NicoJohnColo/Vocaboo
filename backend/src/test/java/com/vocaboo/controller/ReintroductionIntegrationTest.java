package com.vocaboo.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.vocaboo.entity.Learner;
import com.vocaboo.entity.VocabularyWord;
import com.vocaboo.repository.LearnerRepository;
import com.vocaboo.repository.VocabularyWordRepository;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.transaction.annotation.Transactional;

import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@AutoConfigureMockMvc(addFilters = false)
@Transactional
public class ReintroductionIntegrationTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @Autowired
    private LearnerRepository learnerRepository;

    @Autowired
    private VocabularyWordRepository wordRepository;

    @Autowired
    private com.vocaboo.repository.DifficultyProgressRepository difficultyProgressRepository;

    @Test
    void testLearningLevel_fourConsecutiveErrors_reintroductionCycle() throws Exception {
        // 1. Fetch real learner and word from DB
        List<Learner> learners = learnerRepository.findAll();
        List<VocabularyWord> words = wordRepository.findAll();

        Learner learner = learners.get(0);
        VocabularyWord word = words.get(0);
        UUID learnerId = learner.getLearnerId();
        UUID wordId = word.getWordId();

        // Reset difficulty progress for this test pair so it starts clean at LEARNING
        difficultyProgressRepository.findByLearnerLearnerIdAndWordWordId(learnerId, wordId)
                .ifPresent(dp -> difficultyProgressRepository.delete(dp));

        Map<String, Object> reqBody = new HashMap<>();
        reqBody.put("learnerId", learnerId.toString());
        reqBody.put("isCorrect", false);

        // Error 1
        mockMvc.perform(post("/api/v1/words/" + wordId + "/difficulty/adjust")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(reqBody)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.currentLevel").value("LEARNING"))
                .andExpect(jsonPath("$.showExplanations").value(false))
                .andExpect(jsonPath("$.needsReintroduction").value(false));

        // Error 2 -> triggers Short Reintroduction
        mockMvc.perform(post("/api/v1/words/" + wordId + "/difficulty/adjust")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(reqBody)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.currentLevel").value("LEARNING"))
                .andExpect(jsonPath("$.needsReintroduction").value(true))
                .andExpect(jsonPath("$.reintroductionCount").value(1))
                .andExpect(jsonPath("$.consecutiveIncorrect").value(0));

        // GET /api/v1/words/{id}/reintroduction
        mockMvc.perform(get("/api/v1/words/" + wordId + "/reintroduction")
                        .param("learnerId", learnerId.toString()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.wordId").value(wordId.toString()))
                .andExpect(jsonPath("$.englishWord").value(word.getEnglishWord()))
                .andExpect(jsonPath("$.cebuanoMeaning").value(word.getCebuanoMeaning()))
                .andExpect(jsonPath("$.pronunciationThreshold").value(70.0));

        // POST /api/v1/words/{id}/reintroduction/acknowledge
        mockMvc.perform(post("/api/v1/words/" + wordId + "/reintroduction/acknowledge")
                        .param("learnerId", learnerId.toString()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.needsReintroduction").value(false))
                .andExpect(jsonPath("$.consecutiveCorrect").value(0))
                .andExpect(jsonPath("$.consecutiveIncorrect").value(0))
                .andExpect(jsonPath("$.currentLevel").value("LEARNING"));
    }
}
