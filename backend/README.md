# PrepMate API

Express + MongoDB backend used by the Flutter app (and still compatible with cookie logins).

```bash
npm install
# fill in .env: MONGODB_URL, MONGODB_PASSWORD, JWT_SECRET
npm run dev        # http://localhost:5000
```

`MONGODB_URL` may keep Atlas's `<db_password>` placeholder; `MONGODB_PASSWORD` is inserted automatically. Add your IP (or `0.0.0.0/0` for Render) under Atlas Network Access.

## Deploying on Render

Root Directory: `backend` | Build Command: `npm install` | Start Command: `npm start`
Environment: `MONGODB_URL`, `MONGODB_PASSWORD`, `JWT_SECRET`, optional `GEMINI_API_KEY`, `CORS_ORIGIN`.

## Endpoints

| Method | Route | Purpose |
| --- | --- | --- |
| POST | `/api/auth/signup` | Create account (returns `token`) |
| POST | `/api/auth/login` | Sign in (returns `token`) |
| GET | `/api/auth/me` | Current user |
| GET | `/api/data` | Applications and progress |
| POST / PUT / DELETE | `/api/applications[/:id]` | Manage applications |
| PUT | `/api/progress` | Save progress |
| POST | `/api/gemini` | AI analysis, questions, evaluation |
| GET | `/api/health` | Server and database status |

Send the token as `Authorization: Bearer <token>`.
