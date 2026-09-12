-- Migration V45: Add Teacher Class Management System
-- Creates tables for Classes, Enrollments, Invitations, and Join Requests,
-- and adds nullable class_id to lessons for class-scoped lesson authorship.

-- 1. Classes table
CREATE TABLE IF NOT EXISTS classes (
    class_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(100) NOT NULL,
    class_code VARCHAR(10) NOT NULL UNIQUE,
    teacher_id UUID NOT NULL REFERENCES teachers(teacher_id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_classes_teacher_id ON classes(teacher_id);
CREATE INDEX IF NOT EXISTS idx_classes_class_code ON classes(class_code);

-- 2. Class enrollments table
CREATE TABLE IF NOT EXISTS class_enrollments (
    enrollment_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    class_id UUID NOT NULL REFERENCES classes(class_id) ON DELETE CASCADE,
    learner_id UUID NOT NULL REFERENCES learners(learner_id) ON DELETE CASCADE,
    status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE',
    invited_by_teacher_id UUID REFERENCES teachers(teacher_id) ON DELETE SET NULL,
    enrolled_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_class_learner UNIQUE (class_id, learner_id)
);

CREATE INDEX IF NOT EXISTS idx_enrollments_class_id ON class_enrollments(class_id);
CREATE INDEX IF NOT EXISTS idx_enrollments_learner_id ON class_enrollments(learner_id);

-- 3. Class invitations table
CREATE TABLE IF NOT EXISTS class_invitations (
    invitation_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    class_id UUID NOT NULL REFERENCES classes(class_id) ON DELETE CASCADE,
    learner_id UUID NOT NULL REFERENCES learners(learner_id) ON DELETE CASCADE,
    status VARCHAR(20) NOT NULL DEFAULT 'PENDING',
    sent_by_teacher_id UUID NOT NULL REFERENCES teachers(teacher_id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    responded_at TIMESTAMPTZ DEFAULT NULL
);

CREATE INDEX IF NOT EXISTS idx_invitations_class_id ON class_invitations(class_id);
CREATE INDEX IF NOT EXISTS idx_invitations_learner_id ON class_invitations(learner_id);
CREATE INDEX IF NOT EXISTS idx_invitations_status ON class_invitations(status);

-- 4. Class join requests table
CREATE TABLE IF NOT EXISTS class_join_requests (
    request_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    class_id UUID NOT NULL REFERENCES classes(class_id) ON DELETE CASCADE,
    learner_id UUID NOT NULL REFERENCES learners(learner_id) ON DELETE CASCADE,
    status VARCHAR(20) NOT NULL DEFAULT 'PENDING',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    reviewed_at TIMESTAMPTZ DEFAULT NULL
);

CREATE INDEX IF NOT EXISTS idx_join_requests_class_id ON class_join_requests(class_id);
CREATE INDEX IF NOT EXISTS idx_join_requests_learner_id ON class_join_requests(learner_id);
CREATE INDEX IF NOT EXISTS idx_join_requests_status ON class_join_requests(status);

-- 5. Add nullable class_id to lessons
ALTER TABLE lessons ADD COLUMN IF NOT EXISTS class_id UUID DEFAULT NULL REFERENCES classes(class_id) ON DELETE SET NULL;
CREATE INDEX IF NOT EXISTS idx_lessons_class_id ON lessons(class_id) WHERE class_id IS NOT NULL;
