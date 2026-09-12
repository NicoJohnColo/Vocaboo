-- Backfill class analytics for classroom-owned lesson activity created before
-- classroom_context_id became authoritative on practice sessions.

-- 1. Attribute old practice sessions to the classroom that owns their lesson.
UPDATE practice_sessions ps
SET classroom_context_id = l.classroom_id
FROM lessons l
WHERE ps.lesson_id = l.lesson_id
  AND ps.classroom_context_id IS NULL
  AND l.classroom_id IS NOT NULL;

-- 2. Attribute points from those sessions to the same classroom.
UPDATE point_transactions pt
SET context_type = 'CLASS',
    classroom_id = ps.classroom_context_id
FROM practice_sessions ps
WHERE pt.related_session_id = ps.session_id
  AND ps.classroom_context_id IS NOT NULL
  AND (pt.context_type IS DISTINCT FROM 'CLASS' OR pt.classroom_id IS DISTINCT FROM ps.classroom_context_id);

-- 3. Rebuild class aggregates from the authoritative answer and point records.
-- Excluded activities are deliberately omitted from accuracy, matching the live
-- PracticeSessionService scoring contract.
WITH answer_totals AS (
    SELECT
        ps.learner_id,
        ps.classroom_context_id AS classroom_id,
        COUNT(*) FILTER (
            WHERE pr.activity_type IS NULL
               OR UPPER(pr.activity_type) NOT IN ('CONFUSABLE_DISTINCTION', 'PRONUNCIATION_FEEDBACK')
        )::INTEGER AS total_questions,
        COUNT(*) FILTER (
            WHERE (pr.activity_type IS NULL
               OR UPPER(pr.activity_type) NOT IN ('CONFUSABLE_DISTINCTION', 'PRONUNCIATION_FEEDBACK'))
              AND pr.is_correct = TRUE
        )::INTEGER AS correct_answers,
        COUNT(DISTINCT ps.session_id)::INTEGER AS sessions_played
    FROM practice_sessions ps
    JOIN practice_results pr ON pr.session_id = ps.session_id
    WHERE ps.classroom_context_id IS NOT NULL
    GROUP BY ps.learner_id, ps.classroom_context_id
),
point_totals AS (
    SELECT
        pt.learner_id,
        pt.classroom_id,
        COALESCE(SUM(pt.points_awarded), 0)::INTEGER AS class_points
    FROM point_transactions pt
    WHERE pt.context_type = 'CLASS'
      AND pt.classroom_id IS NOT NULL
    GROUP BY pt.learner_id, pt.classroom_id
),
aggregate_rows AS (
    SELECT
        COALESCE(a.learner_id, p.learner_id) AS learner_id,
        COALESCE(a.classroom_id, p.classroom_id) AS classroom_id,
        COALESCE(p.class_points, 0) AS class_points,
        COALESCE(a.correct_answers, 0) AS class_correct_answers,
        COALESCE(a.total_questions, 0) AS class_total_questions,
        COALESCE(a.sessions_played, 0) AS class_sessions_played
    FROM answer_totals a
    FULL OUTER JOIN point_totals p
      ON p.learner_id = a.learner_id
     AND p.classroom_id = a.classroom_id
)
INSERT INTO class_performance (
    learner_id,
    classroom_id,
    class_points,
    class_correct_answers,
    class_total_questions,
    class_accuracy,
    class_sessions_played,
    class_mastery_level,
    created_at,
    updated_at
)
SELECT
    learner_id,
    classroom_id,
    class_points,
    class_correct_answers,
    class_total_questions,
    CASE WHEN class_total_questions > 0
         THEN ROUND((class_correct_answers * 100.0 / class_total_questions)::NUMERIC, 2)
         ELSE 0.00
    END AS class_accuracy,
    class_sessions_played,
    CASE
        WHEN class_total_questions > 0 AND class_correct_answers * 100.0 / class_total_questions >= 90 THEN 'MASTERED'
        WHEN class_total_questions > 0 AND class_correct_answers * 100.0 / class_total_questions >= 75 THEN 'PROFICIENT'
        WHEN class_total_questions > 0 AND class_correct_answers * 100.0 / class_total_questions >= 50 THEN 'FAMILIAR'
        ELSE 'LEARNING'
    END AS class_mastery_level,
    NOW(),
    NOW()
FROM aggregate_rows
ON CONFLICT (learner_id, classroom_id) DO UPDATE SET
    class_points = EXCLUDED.class_points,
    class_correct_answers = EXCLUDED.class_correct_answers,
    class_total_questions = EXCLUDED.class_total_questions,
    class_accuracy = EXCLUDED.class_accuracy,
    class_sessions_played = EXCLUDED.class_sessions_played,
    class_mastery_level = EXCLUDED.class_mastery_level,
    updated_at = NOW();
