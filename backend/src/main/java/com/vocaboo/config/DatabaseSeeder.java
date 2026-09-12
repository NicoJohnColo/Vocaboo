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

    private void createSchemaIfNeeded() {
        String[] tableQueries = {
            "CREATE TABLE IF NOT EXISTS review_sessions (" +
            "  session_id UUID PRIMARY KEY," +
            "  learner_id UUID NOT NULL," +
            "  lesson_id UUID NOT NULL REFERENCES lessons(lesson_id) ON DELETE CASCADE," +
            "  mastery_score NUMERIC(5,2) NULL," +
            "  completed_at TIMESTAMPTZ NULL," +
            "  created_at TIMESTAMPTZ DEFAULT NOW()," +
            "  updated_at TIMESTAMPTZ DEFAULT NOW()" +
            ")",
            
            "CREATE TABLE IF NOT EXISTS review_items (" +
            "  item_id UUID PRIMARY KEY," +
            "  session_id UUID NOT NULL REFERENCES review_sessions(session_id) ON DELETE CASCADE," +
            "  word_id UUID NOT NULL REFERENCES vocabulary_words(word_id) ON DELETE CASCADE," +
            "  is_correct BOOLEAN NOT NULL," +
            "  created_at TIMESTAMPTZ DEFAULT NOW()" +
            ")",
            
            "CREATE TABLE IF NOT EXISTS sandbox_sessions (" +
            "  session_id UUID PRIMARY KEY," +
            "  learner_id UUID NOT NULL," +
            "  topic VARCHAR(255) NULL," +
            "  custom_word VARCHAR(100) NULL," +
            "  mastery_score NUMERIC(5,2) NULL," +
            "  completed_at TIMESTAMPTZ NULL," +
            "  created_at TIMESTAMPTZ DEFAULT NOW()," +
            "  updated_at TIMESTAMPTZ DEFAULT NOW()" +
            ")",
            
            "CREATE TABLE IF NOT EXISTS sandbox_words (" +
            "  word_id UUID PRIMARY KEY," +
            "  session_id UUID NOT NULL REFERENCES sandbox_sessions(session_id) ON DELETE CASCADE," +
            "  english_word VARCHAR(100) NOT NULL," +
            "  cebuano_meaning TEXT NOT NULL," +
            "  example_sentence_english TEXT NOT NULL," +
            "  example_sentence_cebuano TEXT NULL," +
            "  phonological_tip_key VARCHAR(100) NULL," +
            "  word_order INTEGER NOT NULL," +
            "  created_at TIMESTAMPTZ DEFAULT NOW()" +
            ")",
            
            "CREATE TABLE IF NOT EXISTS sandbox_word_progress (" +
            "  progress_id UUID PRIMARY KEY," +
            "  session_id UUID NOT NULL REFERENCES sandbox_sessions(session_id) ON DELETE CASCADE," +
            "  word_id UUID NOT NULL REFERENCES sandbox_words(word_id) ON DELETE CASCADE," +
            "  module_number INTEGER NOT NULL CHECK (module_number BETWEEN 1 AND 4)," +
            "  step_completed INTEGER NOT NULL DEFAULT 0 CHECK (step_completed BETWEEN 0 AND 4)," +
            "  status word_status_enum NOT NULL DEFAULT 'INTRODUCED'," +
            "  completed_at TIMESTAMPTZ NULL," +
            "  created_at TIMESTAMPTZ DEFAULT NOW()," +
            "  updated_at TIMESTAMPTZ DEFAULT NOW()," +
            "  UNIQUE(session_id, word_id, module_number)" +
            ")"
        };
        
        for (String query : tableQueries) {
            try {
                jdbcTemplate.execute(query);
            } catch (Exception e) {
                System.err.println("Failed to create table: " + e.getMessage());
            }
        }

        // Enable RLS and setup permissive policies
        String[] rlsQueries = {
            "ALTER TABLE review_sessions ENABLE ROW LEVEL SECURITY",
            "ALTER TABLE review_items ENABLE ROW LEVEL SECURITY",
            "ALTER TABLE sandbox_sessions ENABLE ROW LEVEL SECURITY",
            "ALTER TABLE sandbox_words ENABLE ROW LEVEL SECURITY",
            "ALTER TABLE sandbox_word_progress ENABLE ROW LEVEL SECURITY"
        };
        for (String query : rlsQueries) {
            try {
                jdbcTemplate.execute(query);
            } catch (Exception e) {
                // Ignore
            }
        }

        String[] policyQueries = {
            "CREATE POLICY review_sessions_policy ON review_sessions FOR ALL USING (true)",
            "CREATE POLICY review_items_policy ON review_items FOR ALL USING (true)",
            "CREATE POLICY sandbox_sessions_policy ON sandbox_sessions FOR ALL USING (true)",
            "CREATE POLICY sandbox_words_policy ON sandbox_words FOR ALL USING (true)",
            "CREATE POLICY sandbox_word_progress_policy ON sandbox_word_progress FOR ALL USING (true)"
        };
        for (String query : policyQueries) {
            try {
                jdbcTemplate.execute(query);
            } catch (Exception e) {
                // Policy already exists
            }
        }

        try {
            jdbcTemplate.execute("ALTER TABLE vocabulary_categories ADD COLUMN IF NOT EXISTS teacher_id UUID DEFAULT NULL REFERENCES teachers(teacher_id) ON DELETE CASCADE");
            jdbcTemplate.execute("CREATE INDEX IF NOT EXISTS idx_vocabulary_categories_teacher_id ON vocabulary_categories(teacher_id)");
            jdbcTemplate.execute("ALTER TABLE vocabulary_categories DROP CONSTRAINT IF EXISTS vocabulary_categories_category_name_key");
        } catch (Exception e) {
            // Already updated or constraint absent
        }

        try {
            jdbcTemplate.execute("ALTER TABLE learners ADD COLUMN IF NOT EXISTS user_id VARCHAR(11)");
            jdbcTemplate.execute("CREATE UNIQUE INDEX IF NOT EXISTS idx_learners_user_id ON learners(user_id)");
        } catch (Exception e) {
            // Already updated or index exists
        }
    }

    @Override
    public void run(String... args) {
        try {
            // Ensure enum types exist
            createEnumTypes();
            // Ensure schemas exist on startup
            createSchemaIfNeeded();
        } catch (Exception e) {
            System.err.println("Error initializing database enums/schema: " + e.getMessage());
        }

        if (categoryRepository.count() == 0 && wordRepository.count() == 0) {
            try {
                // Execute SQL migration / seed scripts if present on the classpath
                ResourceDatabasePopulator populator = new ResourceDatabasePopulator();
                populator.addScript(new ClassPathResource("V1__create_tables.sql"));
                populator.execute(dataSource);

                System.out.println("Database tables created successfully!");
            } catch (Exception e) {
                System.err.println("Failed to initialize database tables: " + e.getMessage());
                e.printStackTrace();
            }
        }

        try {
            // Remove hardcoded lessons from V2
            jdbcTemplate.execute("DELETE FROM vocabulary_categories WHERE category_id::text LIKE 'a1000000-%'");
            System.out.println("Removed all hardcoded categories and lessons.");
        } catch (Exception e) {
            System.err.println("Failed to remove hardcoded categories: " + e.getMessage());
            e.printStackTrace();
        }
    }
}
