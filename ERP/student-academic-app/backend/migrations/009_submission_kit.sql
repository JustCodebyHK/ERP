-- Submission Kit: versioned templates for front pages, indexes, certificates.
-- Teachers upload new versions; students always get the current one.
CREATE TABLE submission_templates (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  type TEXT NOT NULL CHECK (type IN ('front_page', 'index_page', 'certificate')),
  title TEXT NOT NULL,
  file_path TEXT NOT NULL,
  original_name TEXT NOT NULL,
  mime_type TEXT,
  size_bytes BIGINT NOT NULL,
  version INTEGER NOT NULL DEFAULT 1,
  is_current BOOLEAN NOT NULL DEFAULT false,
  uploaded_by UUID NOT NULL REFERENCES users (id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (type, version)
);

CREATE INDEX idx_templates_type_current ON submission_templates (type, is_current);