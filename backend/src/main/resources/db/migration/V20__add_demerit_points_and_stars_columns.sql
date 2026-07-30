-- V20__add_demerit_points_and_stars_columns.sql
-- Add physical demerit_points and stars_earned storage

-- 1. Add demerit_points to word_performance
ALTER TABLE word_performance ADD COLUMN IF NOT EXISTS demerit_points INTEGER NOT NULL DEFAULT 0;

-- 2. Add stars_earned to practice_sessions, session_summaries, and lesson_module_scores
ALTER TABLE practice_sessions ADD COLUMN IF NOT EXISTS stars_earned INTEGER NOT NULL DEFAULT 0;
ALTER TABLE session_summaries ADD COLUMN IF NOT EXISTS stars_earned INTEGER NOT NULL DEFAULT 0;
ALTER TABLE lesson_module_scores ADD COLUMN IF NOT EXISTS stars_earned INTEGER NOT NULL DEFAULT 0;

-- 3. Backfill demerit_points on word_performance (2 x incorrect_count)
UPDATE word_performance 
SET demerit_points = incorrect_count * 2 
WHERE demerit_points = 0 AND incorrect_count > 0;

-- 4. Backfill stars_earned based on accuracy/score thresholds (<70 = 0, 70-79 = 1, 80-89 = 2, >=90 = 3)
UPDATE practice_sessions 
SET stars_earned = CASE 
    WHEN score >= 90.0 THEN 3 
    WHEN score >= 80.0 THEN 2 
    WHEN score >= 70.0 THEN 1 
    ELSE 0 END 
WHERE score IS NOT NULL;

UPDATE session_summaries 
SET stars_earned = CASE 
    WHEN accuracy_rate >= 90.0 THEN 3 
    WHEN accuracy_rate >= 80.0 THEN 2 
    WHEN accuracy_rate >= 70.0 THEN 1 
    ELSE 0 END;

UPDATE lesson_module_scores 
SET stars_earned = CASE 
    WHEN score >= 90.0 THEN 3 
    WHEN score >= 80.0 THEN 2 
    WHEN score >= 70.0 THEN 1 
    ELSE 0 END;
