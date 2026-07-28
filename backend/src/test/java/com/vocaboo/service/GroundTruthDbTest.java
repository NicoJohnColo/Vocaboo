package com.vocaboo.service;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.jdbc.core.JdbcTemplate;

import java.util.List;
import java.util.Map;
import java.util.UUID;

@SpringBootTest
public class GroundTruthDbTest {

    @Autowired
    private JdbcTemplate jdbcTemplate;

    @Test
    public void testGroundTruthDb() {
        UUID lesson1Id = UUID.fromString("b1000000-0000-0000-0000-000000000001");
        System.out.println("=== GROUND TRUTH: ALL ROWS IN VOCABULARY_WORDS FOR LESSON 1 ===");
        String sql = """
            SELECT word_id, english_word, cebuano_meaning, example_sentence_english, 
                   example_sentence_cebuano, is_confusable_pair_member, is_deleted, word_order
            FROM vocabulary_words
            WHERE lesson_id = ?
            ORDER BY word_order ASC, english_word ASC
            """;
        List<Map<String, Object>> rows = jdbcTemplate.queryForList(sql, lesson1Id);
        System.out.println("Total rows in DB for Lesson 1: " + rows.size());
        for (Map<String, Object> r : rows) {
            System.out.println("ROW: " + r);
        }

        System.out.println("\n=== GROUND TRUTH: EVERY 'RULER' ENTRY IN DB (ANY LESSON) ===");
        String sqlRuler = """
            SELECT word_id, lesson_id, english_word, cebuano_meaning, example_sentence_english, 
                   is_confusable_pair_member, is_deleted
            FROM vocabulary_words
            WHERE LOWER(english_word) = 'ruler'
            """;
        List<Map<String, Object>> rulers = jdbcTemplate.queryForList(sqlRuler);
        System.out.println("Total 'Ruler' entries across DB: " + rulers.size());
        for (Map<String, Object> r : rulers) {
            System.out.println("RULER ENTRY: " + r);
        }
    }
}
