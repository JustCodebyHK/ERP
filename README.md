# Student Academic App

A full-stack student academic management system with role-based access for students, teachers, and parents. Built with Node.js/Express backend and Flutter frontend.

## Features

- **Authentication & Authorization** – JWT-based auth (access + refresh tokens), email verification, IP-based rate limiting, bcrypt password hashing
- **Role-Based Access Control** – Student, Teacher, and Parent roles with granular permissions
- **Groups** – Create groups, invite members via 16-character codes, add/remove members, update member roles
- **Assignments** – Teachers upload assignments; students submit and download files with magic-bytes validation
- **Notes** – Subject-based notes with file upload/download and fallback path resolution
- **Submission Kit** – Teachers manage front page, index page, and certificate templates
- **Security** – Baseline security headers, CORS with configurable origins, file magic-bytes validation (F-009)

## Tech Stack

**Backend:** Node.js, Express, PostgreSQL, JWT, bcryptjs, Multer  
**Frontend:** Flutter (Dart)  
**Database:** PostgreSQL  
**Deploy:** Render (see `render.yaml`) / Docker Compose (see `docker-compose.yml`)

## Project Structure

```
student-academic-app/
├── backend/
│   ├── src/
│   │   ├── index.js          # Express app entry point
│   │   ├── db.js             # PostgreSQL connection pool
│   │   ├── middleware/
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
├── security-audit/           # Security audit reports
├── docker-compose.yml        # Local Postgres for development
├── render.yaml               # Render deployment config
├── .gitignore
├── LICENSE
└── README.md
```

## Getting Started

### Prerequisites

- Node.js 18+
- PostgreSQL 16+
- Flutter SDK (for frontend)

### Backend Setup

```bash
cd backend
npm install
cp .env.example .env
# Edit .env with your DATABASE_URL, JWT_SECRET, and CORS_ORIGIN
npm run migrate   # Run database migrations
npm run seed      # Seed initial data (optional)
npm run dev       # Start development server
```

The API runs on `http://localhost:4000` by default.

### Docker (Database Only)

```bash
docker-compose up -d
```

This starts a local PostgreSQL instance for development.

### Frontend Setup

```bash
cd frontend
flutter pub get
flutter run
```

## Environment Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `DATABASE_URL` | PostgreSQL connection string | `postgres://user:pass@localhost:5432/db` |
| `JWT_SECRET` | Secret for signing JWTs | `random-32-char-string` |
| `CORS_ORIGIN` | Allowed CORS origin | `http://localhost:3000` |
| `NODE_ENV` | Environment | `development` or `production` |
| `PORT` | Server port | `4000` |

## API Overview

### Auth
- `POST /api/auth/register` – Create account (email verification required)
- `POST /api/auth/login` – Sign in (verified emails only)
- `GET /api/auth/verify-email?token=` – Verify email
- `POST /api/auth/resend-verification` – Re-send verification token
- `POST /api/auth/refresh` – Refresh access token
- `GET /api/auth/me` – Current user profile

### Groups
- `POST /api/groups` – Create group (teacher)
- `GET /api/groups/:id/members` – List members
- `POST /api/groups/:id/members` – Add member (owner/admin)
- `PUT/PATCH /api/groups/:id/members/:userId` – Update member role

### Assignments / Notes / Submission Kit
- File upload with magic-bytes validation
- Download with path fallback
- Role-based access control

## Security

- JWT access tokens expire in 15 minutes; refresh tokens in 7 days
- Passwords hashed with bcrypt (12 rounds)
- Rate limiting: 10 requests per IP per 60 seconds on auth routes
- File uploads validated by magic bytes, not just MIME type
- Security headers: `X-Content-Type-Options`, `X-Frame-Options`, `Referrer-Policy`

## License

MIT License – see [LICENSE](LICENSE) for details.

## Security Audit

See the [`security-audit/`](security-audit/) directory for security findings and validation reports.