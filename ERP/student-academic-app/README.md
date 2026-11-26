# Student Academic App

A full-stack student academic management system with role-based access for students, teachers, and parents. Built with Node.js/Express backend and Flutter frontend.

## Mobile App (APK)

Download the latest release from the Releases page:

- app-release.apk — Signed release build (v1.0.0)
- app-debug.apk — Debug build for development

See frontend/releases/ for installation guide, checksums, and release notes.

## Features

- Authentication & Authorization – JWT-based auth (access + refresh tokens), email verification, IP-based rate limiting, bcrypt password hashing
- Role-Based Access Control – Student, Teacher, and Parent roles with granular permissions
- Groups – Create groups, invite members via 16-character codes, add/remove members, update member roles
- Assignments – Teachers upload assignments; students submit and download files with magic-bytes validation
- Notes – Subject-based notes with file upload/download and fallback path resolution
- Submission Kit – Teachers manage front page, index page, and certificate templates
- Security – Baseline security headers, CORS with configurable origins, file magic-bytes validation (F-009)

## Tech Stack

Backend: Node.js, Express, PostgreSQL, JWT, bcryptjs, Multer
Frontend: Flutter (Dart)
Database: PostgreSQL
Deploy: Render (see render.yaml) / Docker Compose (see docker-compose.yml)

## Project Structure

student-academic-app/
├── backend/
│   ├── src/
│   │   ├── index.js          # Express app entry point
│   │   ├── db.js             # PostgreSQL connection pool
│   │   ├── middleware/
│   │   │   ├── auth.js       # JWT auth middleware (authRequired)
│   │   │   ├── validation.js # Input validation middleware
│   │   │   ├── fileValidation.js  # Magic-bytes file validator
│   │   │   └── logger.js     # Error logger
│   │   └── routes/
│   │       ├── auth.js       # Auth (register, login, verify, refresh)
│   │       ├── groups.js     # Group CRUD and membership
│   │       ├── assignments.js
│   │       ├── notes.js
│   │       └── submissionKit.js
│   ├── migrations/
│   ├── scripts/
│   ├── uploads/
│   ├── package.json
│   └── .env.example
├── frontend/                 # Flutter mobile app
│   ├── lib/
│   │   ├── api.dart          # HTTP client with JWT Bearer token support
│   │   ├── auth_store.dart   # Secure token storage
│   │   ├── config.dart       # API base URL configuration
│   │   └── screens/
│   │       └── teacher_groups.dart  # Group Details screen
├── security-audit/           # Security audit reports
├── docker-compose.yml        # Local Postgres for development
├── render.yaml               # Render deployment config
├── .gitignore
├── LICENSE
└── README.md

## Getting Started

### Prerequisites

- Node.js 18+
- PostgreSQL 16+
- Flutter SDK (for frontend)

### Backend Setup

cd backend
npm install
cp .env.example .env
# Edit .env with your DATABASE_URL, JWT_SECRET, and CORS_ORIGIN
npm run migrate   # Run database migrations
npm run seed      # Seed initial data (optional)
npm run dev       # Start development server

The API runs on http://localhost:4000 by default.

### Docker (Database Only)

docker-compose up -d

This starts a local PostgreSQL instance for development.

### Frontend Setup

cd frontend
flutter pub get
flutter run

For an Android emulator, the app connects to the backend on the host through
`http://10.0.2.2:4000` by default. Start PostgreSQL and the backend first (see
Backend Setup). On a physical phone, use your computer's LAN IP instead:

```sh
flutter run --dart-define=API_BASE_URL=http://YOUR_COMPUTER_LAN_IP:4000
```

### Authentication

The app requires a valid JWT Bearer token for all protected API endpoints.
The authentication flow is:

1. **Register** — POST `/api/auth/register` (email must end with `@ybit.ac.in`, password ≥ 12 chars)
2. **Verify email** — GET `/api/auth/verify-email?token=<token>`
3. **Login** — POST `/api/auth/login` → returns `token` and `refreshToken`
4. The token is stored in secure storage and attached to every subsequent API request as `Authorization: Bearer <token>`

### Android Emulator Troubleshooting

**ADB authorization:** On first launch, accept the ADB authorization dialog on the emulator screen.

**Gradle build failure:** If Gradle fails with "Several environment variables and/or system properties contain different paths to the Android Preferences folder," unset `ANDROID_PREFS_ROOT`:

```powershell
$env:ANDROID_PREFS_ROOT = $null
```

**Flutter run:** If `flutter run` fails to connect to the device, launch the emulator first:

```sh
flutter emulators --launch Medium_Phone_API_36.0
```
