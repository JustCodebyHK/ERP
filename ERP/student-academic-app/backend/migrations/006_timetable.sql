-- Timetable entries belong to a batch + subject (execution layer).
-- One entry = one lecture slot per week.
CREATE TABLE timetable_entries (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  batch_id UUID NOT NULL REFERENCES batches (id) ON DELETE CASCADE,
  subject_id UUID NOT NULL REFERENCES subjects (id) ON DELETE CASCADE,
  day_of_week INTEGER NOT NULL CHECK (day_of_week BETWEEN 0 AND 6), -- 0=Sun .. 6=Sat
  start_time TIME NOT NULL,
  end_time TIME NOT NULL,
  room TEXT,
  teacher_id UUID NOT NULL REFERENCES users (id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (batch_id, day_of_week, start_time) -- no overlapping slots in same batch
);

CREATE INDEX idx_timetable_batch ON timetable_entries (batch_id);
CREATE INDEX idx_timetable_teacher ON timetable_entries (teacher_id);
CREATE INDEX idx_timetable_batch_day ON timetable_entries (batch_id, day_of_week);