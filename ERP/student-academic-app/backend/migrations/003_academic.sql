-- Academic structure: subjects are PERMANENT (survive semester rollover),
-- batches are the per-semester execution layer.

-- A batch = one class-group for one semester, e.g. "BSc IT Sem 3 (2026)".
CREATE TABLE batches (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL UNIQUE,
  is_active BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Permanent layer: subjects are never archived.
CREATE TABLE subjects (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  code TEXT NOT NULL UNIQUE,
  name TEXT NOT NULL
);

-- Which subject is taught in which batch, and by which teacher.
CREATE TABLE batch_subjects (
  batch_id UUID NOT NULL REFERENCES batches (id) ON DELETE CASCADE,
  subject_id UUID NOT NULL REFERENCES subjects (id) ON DELETE CASCADE,
  teacher_id UUID NOT NULL REFERENCES users (id),
  PRIMARY KEY (batch_id, subject_id)
);

CREATE INDEX idx_batch_subjects_teacher ON batch_subjects (teacher_id);

-- Which students belong to which batch (per-semester data, archivable).
CREATE TABLE enrollments (
  student_id UUID NOT NULL REFERENCES users (id) ON DELETE CASCADE,
  batch_id UUID NOT NULL REFERENCES batches (id) ON DELETE CASCADE,
  enrolled_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (student_id, batch_id)
);

CREATE INDEX idx_enrollments_batch ON enrollments (batch_id);
