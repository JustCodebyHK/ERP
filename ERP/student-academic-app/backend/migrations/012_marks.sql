-- Marks for assignments, tests, exams
CREATE TABLE marks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  batch_id UUID NOT NULL REFERENCES batches (id) ON DELETE CASCADE,
  subject_id UUID NOT NULL REFERENCES subjects (id) ON DELETE CASCADE,
  student_id UUID NOT NULL REFERENCES users (id) ON DELETE CASCADE,
  type TEXT NOT NULL CHECK (type IN ('assignment', 'quiz', 'midterm', 'final', 'project', 'other')),
  title TEXT NOT NULL,
  score INTEGER NOT NULL,
  max_score INTEGER NOT NULL,
  created_by UUID REFERENCES users (id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_marks_batch_subject ON marks (batch_id, subject_id);
CREATE INDEX idx_marks_student ON marks (student_id);