-- Add parent role to users table (extend CHECK constraint)
-- First drop the old constraint, then add new one with 'parent'
ALTER TABLE users DROP CONSTRAINT IF EXISTS users_role_check;
ALTER TABLE users ADD CONSTRAINT users_role_check CHECK (role IN ('student', 'teacher', 'parent'));

-- Parent-student linkage
CREATE TABLE parent_student_links (
  parent_id UUID NOT NULL REFERENCES users (id) ON DELETE CASCADE,
  student_id UUID NOT NULL REFERENCES users (id) ON DELETE CASCADE,
  relationship TEXT NOT NULL DEFAULT 'parent', -- 'parent', 'guardian', etc.
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (parent_id, student_id)
);

CREATE INDEX idx_parent_student_links_student ON parent_student_links (student_id);