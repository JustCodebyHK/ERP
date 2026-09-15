-- Attendance tracking per lecture
CREATE TABLE attendance (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  batch_id UUID NOT NULL REFERENCES batches (id) ON DELETE CASCADE,
  subject_id UUID NOT NULL REFERENCES subjects (id) ON DELETE CASCADE,
  student_id UUID NOT NULL REFERENCES users (id) ON DELETE CASCADE,
  date DATE NOT NULL,
  start_time TIME NOT NULL,
  end_time TIME NOT NULL,
  present BOOLEAN NOT NULL DEFAULT false,
  marked_by UUID REFERENCES users (id),
  marked_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (batch_id, subject_id, student_id, date, start_time)
);

CREATE INDEX idx_attendance_batch_subject ON attendance (batch_id, subject_id);
CREATE INDEX idx_attendance_student ON attendance (student_id);
CREATE INDEX idx_attendance_date ON attendance (date);