-- Announcements can be global (all batches) or batch-specific.
-- Types: holiday, exam, deadline, general, alert
CREATE TABLE announcements (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  batch_id UUID REFERENCES batches (id) ON DELETE CASCADE, -- NULL = global
  type TEXT NOT NULL CHECK (type IN ('holiday', 'exam', 'deadline', 'general', 'alert')),
  title TEXT NOT NULL,
  body TEXT NOT NULL,
  published_by UUID NOT NULL REFERENCES users (id),
  published_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  is_active BOOLEAN NOT NULL DEFAULT true
);

CREATE INDEX idx_announcements_batch ON announcements (batch_id);
CREATE INDEX idx_announcements_published ON announcements (published_at DESC);
CREATE INDEX idx_announcements_type ON announcements (type);