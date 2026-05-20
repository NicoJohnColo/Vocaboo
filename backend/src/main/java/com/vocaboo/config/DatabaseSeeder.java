package com.vocaboo.config;

import com.vocaboo.repository.VocabularyCategoryRepository;
import com.vocaboo.repository.VocabularyWordRepository;
import org.springframework.boot.CommandLineRunner;
import org.springframework.core.io.ClassPathResource;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.datasource.init.ResourceDatabasePopulator;
import org.springframework.stereotype.Component;

import javax.sql.DataSource;

@Component
public class DatabaseSeeder implements CommandLineRunner {

    private final VocabularyCategoryRepository categoryRepository;
    private final VocabularyWordRepository wordRepository;
    private final DataSource dataSource;
    private final JdbcTemplate jdbcTemplate;

    public DatabaseSeeder(
            VocabularyCategoryRepository categoryRepository, 
            VocabularyWordRepository wordRepository,
            DataSource dataSource,
            JdbcTemplate jdbcTemplate) {
        this.categoryRepository = categoryRepository;
        this.wordRepository = wordRepository;
        this.dataSource = dataSource;
        this.jdbcTemplate = jdbcTemplate;
    }

    private void createEnumTypes() {
        String[] enumQueries = {
            "CREATE TYPE language_medium_enum AS ENUM ('CEBUANO_TO_ENGLISH', 'FULL_ENGLISH', 'CEBUANO_ENGLISH_MIXED')",
            "CREATE TYPE grade_level_enum AS ENUM ('GRADE_4', 'GRADE_5', 'GRADE_6')",
            "CREATE TYPE word_status_enum AS ENUM ('INTRODUCED', 'NEEDS_PRONUNCIATION_REVIEW', 'PRONUNCIATION_PENDING', 'PRACTICED', 'MASTERED')",
            "CREATE TYPE pathway_enum AS ENUM ('FULL', 'ACCELERATED')",
            "CREATE TYPE lesson_status_enum AS ENUM ('LOCKED', 'UNLOCKED', 'COMPLETED')"
        };
        
        for (String query : enumQueries) {
            try {
                jdbcTemplate.execute(query);
                System.out.println("Custom enum type created successfully.");
            } catch (Exception e) {
                // Type already exists, which is expected and fine on subsequent runs
            }
        }
    }

    @Override
    public void run(String... args) throws Exception {
        long categoryCount = 0;
        long wordCount = 0;
        
        try {
            categoryCount = categoryRepository.count();
            wordCount = wordRepository.count();
            System.out.println("Checking database state... Categories: " + categoryCount + ", Words: " + wordCount);
        } catch (Exception e) {
            System.out.println("Tables may not fully exist yet: " + e.getMessage());
        }
        
        if (categoryCount == 0 || wordCount == 0) {
            System.out.println("Database is incomplete (missing categories or vocabulary words). Seeding types and data...");
            try {
                // 1. Programmatically create the custom PostgreSQL ENUM types safely
                createEnumTypes();

                // 2. Direct seed categories, lessons, and vocabulary words
                System.out.println("Executing V2__seed_content.sql against Hibernate-generated schema...");
                ResourceDatabasePopulator dataPopulator = new ResourceDatabasePopulator();
                dataPopulator.addScript(new ClassPathResource("V2__seed_content.sql"));
                dataPopulator.execute(dataSource);
                System.out.println("Database data seeded successfully!");
                
                System.out.println("Database initialization and seeding completed successfully!");
            } catch (Exception e) {
                System.err.println("Failed to seed database: " + e.getMessage());
                e.printStackTrace();
            }
        } else {
            System.out.println("Database already contains seeded categories and vocabulary words. Skipping seeding.");
        }
    }
}
