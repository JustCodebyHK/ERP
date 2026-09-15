require('dotenv').config();
const express = require('express');
const cors = require('cors');

const healthRouter = require('./routes/health');
const authRouter = require('./routes/auth');
const academicRouter = require('./routes/academic');
const notesRouter = require('./routes/notes');
const assignmentsRouter = require('./routes/assignments');
const timetableRouter = require('./routes/timetable');
const announcementsRouter = require('./routes/announcements');
const submissionKitRouter = require('./routes/submissionKit');
const parentRouter = require('./routes/parent');
const growthRouter = require('./routes/growth');
const plannerRouter = require('./routes/planner');
const groupsRouter = require('./routes/groups');
const groupMessagesRouter = require('./routes/groupMessages');
const groupAnnouncementsRouter = require('./routes/groupAnnouncements');

const app = express();
const PORT = process.env.PORT || 4000;

app.use(cors());
app.use(express.json());

app.use('/api/health', healthRouter);
app.use('/api/auth', authRouter);
app.use('/api/academic', academicRouter);
app.use('/api/notes', notesRouter);
app.use('/api/assignments', assignmentsRouter);
app.use('/api/timetable', timetableRouter);
app.use('/api/announcements', announcementsRouter);
app.use('/api/submission-kit', submissionKitRouter);
app.use('/api/parent', parentRouter);
app.use('/api/growth', growthRouter);
app.use('/api/planner', plannerRouter);
app.use('/api/groups', groupsRouter);
app.use('/api/groups', groupMessagesRouter);
app.use('/api/groups', groupAnnouncementsRouter);

app.use((req, res) => {
  res.status(404).json({ error: 'Not found' });
});

// eslint-disable-next-line no-unused-vars
app.use((err, req, res, next) => {
  console.error(err);
  res.status(500).json({ error: 'Internal server error' });
});

app.listen(PORT, () => {
  console.log(`API listening on http://localhost:${PORT}`);
});
