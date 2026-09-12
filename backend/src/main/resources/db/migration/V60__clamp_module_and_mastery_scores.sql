-- V60: Sanitize legacy module and lesson scores that exceed 100%
UPDATE lesson_module_scores
SET score = 100.00
WHERE score > 100.00;

UPDATE lesson_module_scores
SET correct_count = total_count
WHERE total_count > 0 AND correct_count > total_count;

UPDATE learner_lesson_status
SET mastery_score = 100.00
WHERE mastery_score > 100.00;
