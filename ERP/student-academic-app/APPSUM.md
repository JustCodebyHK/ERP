# Student Academic ERP - Application Summary

## Overview
A comprehensive Flutter-based academic management system with role-based access for **Students**, **Teachers**, and **Parents**. Built with modern Material 3 design, offline-first capabilities, and cloud backend integration.

---

## Architecture

### Frontend (Flutter/Dart)
- **Framework**: Flutter 3.x with Material 3
- **State Management**: StatefulWidget + Futures (no external state mgmt)
- **Networking**: `http` package with custom API layer (`lib/api.dart`)
- **Caching**: Local `shared_preferences` for offline-first reads
- **File Handling**: `file_picker`, `path_provider`, `open_file` for uploads/downloads
- **Notifications**: `flutter_local_notifications` + `permission_handler` (group message alerts)
- **Offline Handling**: Network errors mapped to friendly messages (no pre-blocking on flaky connectivity checks)

### Backend (Node.js/Express)
- **Runtime**: Node.js with Express.js
- **Database**: PostgreSQL (hosted on Render)
- **Auth**: JWT-based with role claims (student/teacher/parent)
- **File Storage**: Local filesystem (uploads/), ready for S3/Supabase swap
- **API**: RESTful endpoints under `/api/*`

### Deployment
- **Backend**: Render.com (`https://academic-erp-api-u026.onrender.com`)
- **Database**: Render PostgreSQL
- **Mobile**: Android APK (release builds via `--dart-define=API_BASE`)

---

## Role-Based Features

### 🎓 Student Features
| Module | Description |
|--------|-------------|
| **Subjects Dashboard** | Overview stats, animated subject cards, shimmer loading |
| **Notes** | View/download notes by subject, file-type icons, relative timestamps |
| **Assignments** | View assignments, submit files (PDF/DOC/PPT/IMG), status tracking |
| **Timetable** | Weekly schedule view |
| **Announcements** | Read announcements, unread count badge |
| **Submission Kit** | Access submission templates |
| **Groups** | Join groups via invite code, search/filter, view members |
| **Growth** | Academic growth index visualization |
| **Planner** | Personal task planner with carry-forward |

### 👨‍🏫 Teacher Features
| Module | Description |
|--------|-------------|
| **Classes Dashboard** | Stats cards (classes/students/subjects), bottom-sheet class actions |
| **Notes** | Upload notes (with MIME detection), download, delete |
| **Assignments** | Create assignments, view submissions, grade with scores |
| **Timetable** | Manage class schedules |
| **Announcements** | Post announcements to batches |
| **Submission Kit** | Upload/manage submission templates (front page, index, certificates) |
| **Groups** | Create groups/channels, manage members, invite codes |

### 👨‍👩‍👧 Parent Features
| Module | Description |
|--------|-------------|
| **Children Overview** | Link children, view academic overview |
| **Attendance** | Track child attendance |
| **Marks** | View grades/marks |
| **Assignments** | Monitor child's assignments |
| **Announcements** | Stay informed |

---

## Key Technical Highlights

### 1. Offline-First Architecture
- **Network Guard**: API calls are not pre-blocked by connectivity plugins (they can report false "offline" states); real network failures (`SocketException`, `ClientException`, timeouts) are mapped to friendly messages
- **Graceful Degradation**: Shows "You are offline or not connected to the internet" instead of cryptic errors
- **Cached Reads**: Notes, assignments, timetable, announcements cached via `CacheService`
- **Auto-Sync**: Cache updates on successful network requests

### 2. Robust File Upload System
- **Mobile Compatible**: Uses `withData: true` + byte fallback when `path` is null (Android/iOS)
- **MIME Type Detection**: Automatic detection from extension for backend validation
- **Supported Types**: PDF, DOC, DOCX, PPT, PPTX, TXT, JPG, PNG (25MB limit)
- **Progress Indication**: Upload buttons show spinner during transfer

### 3. Modern UI/UX (Material 3)
- **Shared Widget Library** (`lib/widgets/common_widgets.dart`):
  - `StatCard` - Animated metric cards
  - `EmptyState` - Consistent empty states with actions
  - `LoadingShimmer` - Skeleton loaders
  - `SubjectCard`/`ClassCard`/`NoteCard`/`GroupCard` - Rich data cards
  - `AnimatedListItem` - Staggered entrance animations
  - `SearchField` / `SectionHeader` / `FilterChip`
- **Responsive Layouts**: CustomScrollView + Slivers for complex screens
- **Bottom Sheets**: Draggable action sheets for class/group operations
- **Pull-to-Refresh**: Consistent refresh indicators across lists

### 4. Group/Chat System
- **Types**: Groups (chat) + Channels (broadcast)
- **Invite Codes**: 8-char uppercase codes for joining
- **Roles**: Owner → Admin → Member permissions
- **Student Access**: Join via code, search/filter, view members
- **Teacher Access**: Full CRUD, member management (add/remove students, promote/demote), role changes
- **Group Chat** (`group_chat.dart`): Bubbles with sender names + role badges, read receipts, pull-to-refresh, older-message pagination, 5s polling for new messages
- **History**: Members see all messages sent before they joined
- **Message Notifications**: `GroupMessageWatcher` polls groups every 20s and pops a system notification for new messages from other members (see section 6)

### 5. Downloads & Storage Permissions
- **Public Downloads folder**: Files are saved to `/storage/emulated/0/Download/Notes` and `/storage/emulated/0/Download/SubmissionKit` so any file manager can find them
- **Android 11+**: Uses the "All files access" (`MANAGE_EXTERNAL_STORAGE`) flow — app explains, opens the system settings page, then verifies the grant
- **Android ≤ 10**: Uses the classic runtime storage permission dialog
- **Fallback**: If the public folder is unavailable, files fall back to app-specific external storage
- **Open Externally**: After download the file is opened with the system "Open with" chooser via `open_file`

### 6. Notifications
- **Permission**: `POST_NOTIFICATIONS` is requested once after login (Android 13+); if denied, the app offers a shortcut to system settings
- **Delivery**: While the app is open, a background watcher polls group messages and shows heads-up notifications ("Sender in Group — message")
- **No self-notifications**: Messages sent by the user are skipped, and the open chat screen suppresses notifications for that group

### 7. Security
- **JWT Auth**: Token stored in `shared_preferences`, auto-attached to requests
- **Role Guards**: Backend enforces role-based access per endpoint
- **Resource Ownership**: Teachers only access assigned subjects/batches
- **Student Enrollment**: Students only see enrolled batch subjects

---

## Project Structure

```
student-academic-app/
├── frontend/                    # Flutter App
│   ├── lib/
│   │   ├── api.dart            # API layer + network guard + file upload
│   │   ├── auth_store.dart     # JWT storage + user state
│   │   ├── main.dart           # App entry + role routing
│   │   ├── widgets/
│   │   │   ├── common_widgets.dart    # Shared UI components
│   │   │   └── stat_card.dart         # Legacy stat card
│   │   ├── models/             # Data models (Note, Group, Assignment, etc.)
│   │   ├── screens/            # All UI screens by role
│   │   │   ├── student_*.dart
│   │   │   ├── teacher_*.dart
│   │   │   ├── parent_*.dart
│   │   │   ├── group_chat.dart
│   │   │   └── login_screen.dart
│   │   ├── services/
│   │   │   ├── cache_service.dart          # Offline caching
│   │   │   ├── notification_service.dart   # Local notifications + permission
│   │   │   └── group_message_watcher.dart  # Group message polling watcher
│   │   └── utils/
│   │       └── download_helper.dart        # Storage permission + Downloads dir
│   ├── pubspec.yaml
│   └── build/app/outputs/flutter-apk/app-release.apk
│
├── backend/                     # Node.js API
│   ├── src/
│   │   ├── index.js            # Express setup + middleware
│   │   ├── db.js               # PostgreSQL pool
│   │   ├── middleware/auth.js  # JWT verification + role guards
│   │   └── routes/             # REST endpoints
│   │       ├── auth.js
│   │       ├── notes.js
│   │       ├── groups.js
│   │       ├── assignments.js
│   │       ├── announcements.js
│   │       ├── submissionKit.js
│   │       ├── timetable.js
│   │       ├── planner.js
│   │       ├── growth.js
│   │       ├── parent.js
│   │       └── academic.js
│   ├── uploads/                # File storage (dev)
│   └── package.json
│
├── docker-compose.yml
├── render.yaml                 # Render.com deployment config
└── APPSUM.md                   # This file
```

---

## API Endpoints Summary

### Authentication
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/auth/login` | Email/password → JWT |
| POST | `/api/auth/register` | Register (teacher only) |

### Academic
| Method | Endpoint | Roles |
|--------|----------|-------|
| GET | `/api/academic/my-subjects` | Student |
| GET | `/api/academic/my-classes` | Teacher |
| POST | `/api/academic/batches` | Teacher |
| DELETE | `/api/academic/batches/:id` | Teacher |

### Notes
| Method | Endpoint | Roles |
|--------|----------|-------|
| POST | `/api/notes` (multipart) | Teacher |
| GET | `/api/notes?subject_id=` | Student, Teacher |
| GET | `/api/notes/:id/download` | Student, Teacher |

### Assignments
| Method | Endpoint | Roles |
|--------|----------|-------|
| POST | `/api/assignments` | Teacher |
| GET | `/api/assignments?batch_id=&subject_id=` | Teacher |
| GET | `/api/assignments/my` | Student |
| POST | `/api/assignments/:id/submit` (multipart) | Student |
| POST | `/api/assignments/:id/grade` | Teacher |

### Groups
| Method | Endpoint | Roles |
|--------|----------|-------|
| POST | `/api/groups` | Teacher |
| GET | `/api/groups` | Student (joined), Teacher (owned) |
| POST | `/api/groups/join` | Student, Teacher |
| POST | `/api/groups/:id/members` | Owner/Admin (add by email) |
| GET | `/api/groups/:id/members` | Members |
| PUT | `/api/groups/:id/members/:userId` | Owner/Admin |
| DELETE | `/api/groups/:id/members/:userId` | Owner/Admin |
| GET | `/api/groups/:id/messages` | Members (full history) |
| POST | `/api/groups/:id/messages` | Members (send) |

### Submission Kit
| Method | Endpoint | Roles |
|--------|----------|-------|
| POST | `/api/submission-kit` (multipart) | Teacher |
| GET | `/api/submission-kit` | Teacher |
| GET | `/api/submission-kit/:type/current` | Student |

---

## Build & Install

### Development
```bash
cd frontend
flutter pub get
flutter run --dart-define=API_BASE=https://academic-erp-api-u026.onrender.com
```

### Release APK (Production)
```bash
cd frontend
flutter build apk --release --dart-define=API_BASE=https://academic-erp-api-u026.onrender.com
# Output: build/app/outputs/flutter-apk/app-release.apk
```

### Install on Device
```bash
adb install frontend/build/app/outputs/flutter-apk/app-release.apk
```

---

## Configuration

### Environment Variables (Backend)
```env
DATABASE_URL=postgresql://user:pass@host/db
JWT_SECRET=your-secret-key
PORT=4000
UPLOAD_DIR=./uploads
```

### Flutter Build Config
- **API Base**: Injected at build via `--dart-define=API_BASE=...`
- **Default**: `http://localhost:4000` (dev)
- **Production**: `https://academic-erp-api-u026.onrender.com`

---

## Known Limitations / Future Work

| Area | Status | Notes |
|------|--------|-------|
| Real-time chat | ❌ | Groups have messaging endpoints but no WebSocket UI |
| Push notifications | ❌ | Not implemented |
| iOS build | ⚠️ | Not tested (no macOS CI) |
| File storage | 🔄 | Local FS only; needs S3/Supabase for scale |
| Parent linking | ⚠️ | Email-based linking only |
| Tests | ❌ | No unit/widget tests yet |
| CI/CD | ⚠️ | Manual build only |

---

## Version Info
- **Flutter**: 3.x
- **Dart**: 3.x
- **Android Min SDK**: 21 (API 21+)
- **Target SDK**: 34
- **APK Size**: ~54 MB (release)
- **Backend**: Node.js 20+, Express 4.x, PostgreSQL 15+

---

## Support
- **Backend URL**: https://academic-erp-api-u026.onrender.com
- **Database**: Render PostgreSQL (Oregon)
- **Issues**: Check Render logs for backend, `flutter logs` for mobile