# Architecture — Student Academic ERP

## Overview
A role-based academic management system (Students, Teachers, Parents) with a Flutter mobile frontend and a Node.js/Express REST backend backed by PostgreSQL. Deployed on Render; dev database via docker-compose.

## Trust boundaries

| Boundary | Direction | Control | Notes |
|---|---|---|---|
| Mobile app → API | outbound, client-to-server | Bearer JWT in `Authorization` header | JWT stored in `shared_preferences` (plaintext) |
| API → PostgreSQL | outbound, server-to-DB | `pg` Pool with `DATABASE_URL` | `ssl: { rejectUnauthorized: false }` in production |
| API → local filesystem | outbound, server-to-disk | `multer.diskStorage` into `uploads/` | File name = `uuidv4() + ext` from `originalname` |
| Browser/Flutter Web → API | cross-origin | `cors()` with no options | Allows all origins |
| Parent ↔ Student linking | cross-user | Email-based link via `/api/parent/link` | No verification email |

## Authentication & session
- `POST /api/auth/login` — email + password → JWT (`sub`, `role`, `name`), 7-day expiry, HS256 with `JWT_SECRET`
- `POST /api/auth/register` — open registration; student/teacher require `@ybit.ac.in`, parent allows any domain
- `GET /api/auth/me` — `authRequired` middleware verifies JWT
- Token stored in Flutter `shared_preferences`, auto-attached to every request (`lib/api.dart`)
- No refresh tokens, no rotation, no revocation list, no account lockout

## Authorization
- Role-based: `requireRole('student'|'teacher'|'parent')`
- Resource ownership: teachers access only assigned subjects/batches; students only enrolled batches; parents only linked children
- All writes checked against DB (`batch_subjects`, `enrollments`, `group_members`) — parameterized queries (`pg` `$n`)

## File handling
- Upload: `multer` disk storage, 25 MB limit, MIME allow-list from client-provided `file.mimetype` (no magic-byte validation)
- Download: `fs.createReadStream(file_path)` where `file_path` is server-generated (UUID + ext); `Content-Disposition: attachment`

## Groups / messaging
- Invite code: 8 uppercase hex chars from UUID slice (~32 bits entropy)
- Membership enforced via `group_members` table
- Messages: polling (5s) from Flutter, no WebSocket

## Deployment
- Backend: Render.com Node, free plan, `NODE_ENV=production`
- Database: Render PostgreSQL 16, Oregon
- CORS: `app.use(cors())` unrestricted
- No security headers (no Helmet)

## Data flow summary
1. User enters credentials in Flutter login screen
2. `apiPost('/api/auth/login', {email, password})` sends JSON to API
3. API validates against PostgreSQL (`bcrypt.compare`), issues JWT
4. Flutter persists JWT + user in `shared_preferences`
5. Subsequent API calls attach `Bearer <jwt>`
6. Route handlers verify JWT (`authRequired`), then check role/resource ownership via parameterized SQL
7. File uploads/downloads go through `multer`/`fs` to `uploads/`

## Components not in scope (out of scope for this run)
- Mobile client certificate pinning (not implemented)
- iOS build (not tested)
- Push notifications (not implemented)
- CI/CD (manual build)
