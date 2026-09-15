-- Notes belong to a SUBJECT (permanent layer), not a batch.
-- Uploaded by teachers, readable by enrolled students and the teacher.
CREATE TABLE notes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  subject_id UUID NOT NULL REFERENCES subjects (id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  file_path TEXT NOT NULL,
  original_name TEXT NOT NULL,
  mime_type TEXT,
  size_bytes BIGINT NOT NULL,
  uploaded_by UUID NOT NULL REFERENCES users (id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_notes_subject ON notes (subject_id);
CREATE INDEX idx_notes_uploader ON notes (uploaded_by);