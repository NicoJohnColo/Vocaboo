-- Create lesson_word_accuracy table to track best accuracy per word per lesson
CREATE TABLE lesson_word_accuracy (
    accuracy_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    learner_id UUID NOT NULL,
    lesson_id UUID NOT NULL,
    word_id UUID NOT NULL,
    best_accuracy DECIMAL(5,2) NOT NULL DEFAULT 0.00,
    attempts INTEGER NOT NULL DEFAULT 0,
    last_practiced_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT fk_lesson_word_accuracy_learner FOREIGN KEY (learner_id) REFERENCES learners(learner_id) ON DELETE CASCADE,
    CONSTRAINT fk_lesson_word_accuracy_lesson FOREIGN KEY (lesson_id) REFERENCES lessons(lesson_id) ON DELETE CASCADE,
    CONSTRAINT fk_lesson_word_accuracy_word FOREIGN KEY (word_id) REFERENCES vocabulary_words(word_id) ON DELETE CASCADE,
    CONSTRAINT uq_learner_lesson_word UNIQUE (learner_id, lesson_id, word_id)
);

-- Create index for faster lookups
CREATE INDEX idx_lesson_word_accuracy_learner_lesson ON lesson_word_accuracy(learner_id, lesson_id);
CREATE INDEX idx_lesson_word_accuracy_learner ON lesson_word_accuracy(learner_id);

-- Add trigger to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_lesson_word_accuracy_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_lesson_word_accuracy_updated_at
    BEFORE UPDATE ON lesson_word_accuracy
    FOR EACH ROW
    EXECUTE FUNCTION update_lesson_word_accuracy_updated_at();