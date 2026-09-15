-- Daily planner tasks, linked to timetable entries (lecture-wise) or free-floating
CREATE TABLE planner_tasks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  student_id UUID NOT NULL REFERENCES users (id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  description TEXT,
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'in_progress', 'completed', 'deferred', 'cancelled')),
  priority INTEGER NOT NULL DEFAULT 1 CHECK (priority BETWEEN 1 AND 3), -- 1=low, 2=medium, 3=high
  due_at TIMESTAMPTZ,
  scheduled_for DATE, -- the day this task is planned for
  timetable_entry_id UUID REFERENCES timetable_entries (id) ON DELETE SET NULL,
  subject_id UUID REFERENCES subjects (id) ON DELETE SET NULL,
  completed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_planner_student_scheduled ON planner_tasks (student_id, scheduled_for);
CREATE INDEX idx_planner_student_status ON planner_tasks (student_id, status);
CREATE INDEX idx_planner_timetable ON planner_tasks (timetable_entry_id);

-- Digest reports (daily/weekly summaries generated for students/parents)
CREATE TABLE digest_reports (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  student_id UUID NOT NULL REFERENCES users (id) ON DELETE CASCADE,
  type TEXT NOT NULL CHECK (type IN ('daily', 'weekly')),
  period_start DATE NOT NULL,
  period_end DATE NOT NULL,
  content JSONB NOT NULL, -- structured digest content
  generated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (student_id, type, period_start)
);

CREATE INDEX idx_digest_student_period ON digest_reports (student_id, type, period_start);