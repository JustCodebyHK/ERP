-- Assignments belong to a batch+subject (execution layer).
-- Submissions are per-student.
CREATE TABLE assignments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  batch_id UUID NOT NULL REFERENCES batches (id) ON DELETE CASCADE,
  subject_id UUID NOT NULL REFERENCES subjects (id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  description TEXT,
  due_at TIMESTAMPTZ NOT NULL,
  max_score INTEGER NOT NULL DEFAULT 100,
  created_by UUID NOT NULL REFERENCES users (id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_assignments_batch_subject ON assignments (batch_id, subject_id);
CREATE INDEX idx_assignments_due ON assignments (due_at);

CREATE TABLE submissions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  assignment_id UUID NOT NULL REFERENCES assignments (id) ON DELETE CASCADE,
  student_id UUID NOT NULL REFERENCES users (id) ON DELETE CASCADE,
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'submitted', 'late', 'graded')),
  file_path TEXT,
  original_name TEXT,
  mime_type TEXT,
  size_bytes BIGINT,
  submitted_at TIMESTAMPTZ,
  score INTEGER,
  graded_by UUID REFERENCES users (id),
  graded_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (assignment_id, student_id)
);

CREATE INDEX idx_submissions_assignment ON submissions (assignment_id);
CREATE INDEX idx_submissions_student ON submissions (student_id);