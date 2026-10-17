# BloomTrack — My Life, Health & Goals

> **"Small habits. Better health. Bigger goals."**

BloomTrack is a production-quality, cross-platform productivity and wellness application designed for daily habit tracking, PCOD/PCOS wellness management, gut health and bloating tracking, GATE CS 2027 examination preparation, seventh-semester university study, and ExcelR placement training.

---

## 1. System Architecture

```
                                  +------------------------------------+
                                  |     BloomTrack Frontend Client     |
                                  |  - Flutter (Android, iOS, Web)     |
                                  |  - Responsive Web (FastAPI served) |
                                  +-----------------+------------------+
                                                    |  REST API / JSON
                                                    v
                                  +------------------------------------+
                                  |       FastAPI Backend Engine       |
                                  |  - JWT Authentication & RBAC       |
                                  |  - Pydantic Request Validation     |
                                  |  - Daily Routine Generator         |
                                  +-----------------+------------------+
                                                    |  SQLAlchemy 2.0
                                                    v
                                  +------------------------------------+
                                  |        PostgreSQL Database         |
                                  |  - Alembic Migrations              |
                                  |  - SQLite Fallback for Local Dev   |
                                  +------------------------------------+
```

### Technology Stack:
- **Backend**: Python 3.11+, FastAPI, SQLAlchemy 2.0, Alembic, Pydantic v2, Passlib (Bcrypt), PyJWT.
- **Frontend Web**: Pure HTML5, CSS3 Custom Properties design tokens, Vanilla JavaScript engine, Font Awesome 6, Google Fonts (Plus Jakarta Sans & Outfit).
- **Cross-Platform Mobile**: Flutter 3.22+, Dart 3.3+, Riverpod state management, GoRouter navigation, Material 3 design theme.
- **Database**: PostgreSQL (Production on Render) with seamless local SQLite fallback (`sqlite:///./bloomtrack.db`).
- **DevOps & CI/CD**: GitHub Actions (5 automated workflows), Docker, Render Blueprints (`render.yaml`).

---

## 2. Key Modules & Features

### A. Prepopulated Routine & Tasks (Asia/Kolkata Timezone)
- **Weekday Schedule (Mon–Fri)**: 06:30 Wake up & daylight, 06:45 Home workout, 08:00 GATE CS study, 10:20 Semester study, 13:00 GATE PYQs, 15:00 Revision, 17:00–20:00 ExcelR placement training, 20:30 Post-dinner walk, 21:15 Bedtime routine, 22:15 Sleep.
- **Saturday Schedule**: 06:45 Wake up, 07:00 Exercise, 08:00 GATE CS, 10:30 Semester study, 14:00–17:00 ExcelR training, 18:00 Optional GATE revision.
- **Sunday Recovery**: Recovery-friendly training holiday. Morning GATE mock test, analysis of mistakes, afternoon semester study, meal prep and weekly planning.
- **Interactive Checkboxes**: Clicking any checkbox immediately executes a `PATCH /api/v1/tasks/{id}/toggle` request, persisting completed state and timestamp to the database. Tasks are never auto-completed merely because time has elapsed.

### B. Health, PCOD & Digestive Tracking
- **PCOD & Menstrual Tracker**: Tracks bleeding start/end dates, flow intensity, cramps, fatigue, acne, and mood.
- **Non-Diagnostic Notice**: Recognizes cycles occur approximately every 2–3 months. Standard 28-day predictions are intentionally omitted. Prompts consultation if interval exceeds 90 days.
- **Digestive & Gut Health**: Tracks bloating (0–5), gas, constipation, Bristol Stool scale (Types 1–7), suspected food triggers, and clinical safety red-flag notices.
- **Weight & Hydration**: Initial weight 66 kg, long-term target 56 kg. Weekly tracking, progress metrics toward target. Daily 2.2L hydration ring with quick-add (+250ml, +500ml) buttons.

### C. GATE CS 2027 Syllabus & Semester Exams
- **GATE CS 2027**: Official 12 syllabus sections (Engineering Maths, Discrete Maths, Digital Logic, COA, Programming & DS, Algorithms, TOC, Compiler Design, OS, DBMS, Computer Networks, General Aptitude). Topics status toggle (*Not Started*, *In Progress*, *Completed*, *Needs Revision*), PYQ log, and mock test scores.
- **Semester Exams (Dec 2026)**: Prepopulated with 5 seventh-semester subjects S1–S5. Each subject includes editable names, priority rating, and a 5-unit checklist.
- **ExcelR Placement Training**: Recurring sessions (Mon–Fri 17:00–20:00, Sat 14:00–17:00). Attendance tracking (*Completed*, *Missed*, *Cancelled*) and placement readiness tasks (Resume, DSA, Mock Interviews).

---

## 3. Local Development & Quickstart

### Prerequisites
- Python 3.10+ (Python 3.14 tested and verified)
- Git

### 1. Clone & Set Up Backend
```bash
cd e:/goal-mgmt/backend
python -m pip install -r requirements.txt
```

### 2. Run Database Migrations & Start Server
```bash
# Run backend server (auto-initializes tables & seeds routine, workouts, and GATE syllabus)
python -m uvicorn app.main:app --host 127.0.0.1 --port 8000 --reload
```

### 3. Open Web Application
Navigate to `http://127.0.0.1:8000/` in any browser:
- Full responsive wellness dashboard.
- Interactive checkboxes with instant database persistence.
- Interactive API documentation available at `http://127.0.0.1:8000/docs`.

---

## 4. Automated Testing Results

The backend contains a test suite covering authentication, tasks, habits, hydration, weight, PCOD health, gut tracking, GATE syllabus, semester subjects, ExcelR training, and data export.

To run the automated tests:
```bash
pytest backend/tests -v
```

**Results (14 / 14 Tests Passing):**
```
backend/tests/test_api.py::test_health_check PASSED                   [  7%]
backend/tests/test_api.py::test_register_and_login PASSED             [ 14%]
backend/tests/test_api.py::test_user_profile_and_preferences PASSED   [ 21%]
backend/tests/test_api.py::test_scheduled_tasks_and_instant_checkbox_toggle PASSED [ 28%]
backend/tests/test_api.py::test_habits_and_streak PASSED             [ 35%]
backend/tests/test_api.py::test_hydration_tracking PASSED            [ 42%]
backend/tests/test_api.py::test_weight_tracking PASSED               [ 50%]
backend/tests/test_api.py::test_pcod_and_menstrual_health PASSED      [ 57%]
backend/tests/test_api.py::test_digestive_health_tracking PASSED      [ 64%]
backend/tests/test_api.py::test_gate_syllabus_and_mocks PASSED        [ 71%]
backend/tests/test_api.py::test_semester_subjects PASSED             [ 78%]
backend/tests/test_api.py::test_excelr_and_placement PASSED          [ 85%]
backend/tests/test_api.py::test_dashboard_summary PASSED              [ 92%]
backend/tests/test_api.py::test_export_data PASSED                   [100%]

====================== 14 passed in 11.82s =======================
```

---

## 5. GitHub Actions Workflows

Automated CI/CD pipelines are configured in `.github/workflows/`:
1. `ci.yml`: Runs on push and PR. Executes Python linting, pytest test suite, Dart format validation, Flutter analyze, and Flutter unit tests.
2. `android.yml`: Builds release Android APK and Play Store App Bundle (AAB), uploading artifacts to GitHub Actions. Supports signing through GitHub Secrets.
3. `ios.yml`: Executes on a macOS runner. Builds the iOS release package. Ready for TestFlight and App Store distribution once Apple signing certificates are configured.
4. `backend.yml`: Verifies backend test suite and triggers Render deployment hook.

---

## 6. Render Deployment Guide

The repository includes a complete Render Blueprint (`render.yaml`) orchestrating:
1. **`bloomtrack-postgres`**: Managed PostgreSQL database instance.
2. **`bloomtrack-api`**: Python web service running FastAPI.
3. **`bloomtrack-web`**: Static site hosting for the frontend application.

### Deployment Steps:
1. Push this repository to your GitHub account.
2. Log into [Render](https://render.com) and click **New +** → **Blueprint**.
3. Select your GitHub repository. Render will detect `render.yaml` and configure the database, FastAPI backend, and frontend static site.
4. Set any custom environment variables (or let Render auto-generate `SECRET_KEY`).
5. Click **Apply**. Render will build and deploy the services.

---

## 7. Manual Configuration Checklist

The following items require external accounts and secrets before live store publishing:
- **Render Deployment**: Connect your GitHub repository to Render using the included `render.yaml`.
- **Android Signing (Play Store)**: Add `KEYSTORE_BASE64`, `KEY_ALIAS`, `KEYSTORE_PASSWORD`, and `KEY_PASSWORD` to your GitHub repository secrets if automated APK/AAB signing is desired.
- **Apple iOS Signing (App Store / TestFlight)**: Add `APPLE_CERTIFICATE_BASE64`, `APPLE_PROVISIONING_PROFILE_BASE64`, and Apple Developer Team ID to GitHub Secrets.
- **Firebase Cloud Messaging (FCM)**: Create a Firebase project and add `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) if native mobile push notifications are required.
