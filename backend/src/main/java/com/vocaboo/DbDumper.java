package com.vocaboo;

import org.springframework.boot.CommandLineRunner;
import org.springframework.stereotype.Component;
import org.springframework.jdbc.core.JdbcTemplate;
import java.util.List;
import java.util.Map;
import java.nio.file.Files;
import java.nio.file.Paths;

@Component
public class DbDumper implements CommandLineRunner {
    private final JdbcTemplate jdbc;
    public DbDumper(JdbcTemplate jdbc) {
        this.jdbc = jdbc;
    }
    public void run(String... args) throws Exception {
        jdbc.update("UPDATE difficulty_progress SET current_level = 'FAMILIAR' WHERE current_level = 'LEARNING'");
        List<Map<String, Object>> rows = jdbc.queryForList(
            "SELECT w.english_word, dp.module_number, dp.current_level, dp.consecutive_correct, dp.recall_in_current_streak " +
            "FROM difficulty_progress dp JOIN vocabulary_words w ON dp.word_id = w.word_id ORDER BY w.english_word, dp.module_number"
        );
        StringBuilder sb = new StringBuilder();
        for(Map<String, Object> r : rows) {
            sb.append(r.get("english_word")).append(" | Mod: ").append(r.get("module_number"))
              .append(" | Level: ").append(r.get("current_level"))
              .append(" | Streak: ").append(r.get("consecutive_correct"))
              .append(" | Recall: ").append(r.get("recall_in_current_streak")).append("\n");
        }
        Files.write(Paths.get("db_dump_progress.txt"), sb.toString().getBytes());
    }
}
