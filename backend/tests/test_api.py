import pytest
from datetime import date
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

from app.main import app
from app.database import Base, get_db
from app.config import settings

# Test database
TEST_DATABASE_URL = "sqlite:///./test_bloomtrack.db"
test_engine = create_engine(TEST_DATABASE_URL, connect_args={"check_same_thread": False})
TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=test_engine)


def override_get_db():
    db = TestingSessionLocal()
    try:
        yield db
    finally:
        db.close()


app.dependency_overrides[get_db] = override_get_db
client = TestClient(app)


@pytest.fixture(scope="session", autouse=True)
def setup_database():
    Base.metadata.drop_all(bind=test_engine)
    Base.metadata.create_all(bind=test_engine)
    from app.seed_data import seed_gate_and_workouts
    db = TestingSessionLocal()
    seed_gate_and_workouts(db)
    db.close()
    yield
    Base.metadata.drop_all(bind=test_engine)


def test_health_check():
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json()["status"] == "healthy"


def test_register_and_login():
    reg_payload = {
        "email": "user@bloomtrack.com",
        "password": "SecretPassword123!",
        "full_name": "Antigravity Bloom"
    }
    reg_res = client.post("/api/v1/auth/register", json=reg_payload)
    assert reg_res.status_code == 200
    token_data = reg_res.json()
    assert "access_token" in token_data
    assert token_data["email"] == "user@bloomtrack.com"
    token = token_data["access_token"]
    
    # Login check
    login_res = client.post(
        "/api/v1/auth/login",
        data={"username": "user@bloomtrack.com", "password": "SecretPassword123!"}
    )
    assert login_res.status_code == 200
    assert "access_token" in login_res.json()


def get_auth_headers():
    login_res = client.post(
        "/api/v1/auth/login",
        data={"username": "user@bloomtrack.com", "password": "SecretPassword123!"}
    )
    token = login_res.json()["access_token"]
    return {"Authorization": f"Bearer {token}"}


def test_user_profile_and_preferences():
    headers = get_auth_headers()
    res = client.get("/api/v1/auth/me", headers=headers)
    assert res.status_code == 200
    data = res.json()
    assert data["email"] == "user@bloomtrack.com"
    assert data["preferences"]["height_cm"] == 162.6
    assert data["preferences"]["starting_weight_kg"] == 66.0
    assert data["preferences"]["target_weight_kg"] == 56.0

    # Update preferences
    pref_update = {
        "daily_water_target_ml": 2500,
        "target_weight_kg": 55.0
    }
    update_res = client.put("/api/v1/auth/me/preferences", json=pref_update, headers=headers)
    assert update_res.status_code == 200
    assert update_res.json()["daily_water_target_ml"] == 2500
    assert update_res.json()["target_weight_kg"] == 55.0


def test_scheduled_tasks_and_instant_checkbox_toggle():
    headers = get_auth_headers()
    today_str = str(date.today())
    
    # Fetch tasks
    tasks_res = client.get(f"/api/v1/tasks?target_date={today_str}", headers=headers)
    assert tasks_res.status_code == 200
    tasks = tasks_res.json()
    assert len(tasks) > 0
    first_task = tasks[0]
    task_id = first_task["id"]
    assert first_task["is_completed"] is False
    
    # Toggle complete
    toggle_res = client.patch(f"/api/v1/tasks/{task_id}/toggle", headers=headers)
    assert toggle_res.status_code == 200
    assert toggle_res.json()["is_completed"] is True
    assert toggle_res.json()["completed_at"] is not None
    
    # Toggle back
    toggle_back = client.patch(f"/api/v1/tasks/{task_id}/toggle", headers=headers)
    assert toggle_back.status_code == 200
    assert toggle_back.json()["is_completed"] is False


def test_habits_and_streak():
    headers = get_auth_headers()
    today_str = str(date.today())
    
    res = client.get(f"/api/v1/habits?target_date={today_str}", headers=headers)
    assert res.status_code == 200
    habits = res.json()
    assert len(habits) >= 8
    
    first_habit = habits[0]
    toggle_res = client.post("/api/v1/habits/toggle", json={
        "habit_id": first_habit["id"],
        "date": today_str,
        "completed": True
    }, headers=headers)
    assert toggle_res.status_code == 200
    assert toggle_res.json()["completed"] is True
    assert toggle_res.json()["current_streak"] == 1


def test_hydration_tracking():
    headers = get_auth_headers()
    today_str = str(date.today())
    
    # Add water
    add_res = client.post("/api/v1/hydration/add", json={
        "date": today_str,
        "amount_ml": 500
    }, headers=headers)
    assert add_res.status_code == 200
    
    # Get summary
    sum_res = client.get(f"/api/v1/hydration/today?target_date={today_str}", headers=headers)
    assert sum_res.status_code == 200
    data = sum_res.json()
    assert data["total_ml"] >= 500
    assert data["percentage"] > 0


def test_weight_tracking():
    headers = get_auth_headers()
    today_str = str(date.today())
    
    log_res = client.post("/api/v1/weight", json={
        "date": today_str,
        "weight_kg": 65.2,
        "waist_cm": 74.0,
        "notes": "First week progress"
    }, headers=headers)
    assert log_res.status_code == 200
    
    prog_res = client.get("/api/v1/weight/progress", headers=headers)
    assert prog_res.status_code == 200
    prog = prog_res.json()
    assert prog["current_weight_kg"] == 65.2
    assert prog["weight_lost_kg"] > 0


def test_pcod_and_menstrual_health():
    headers = get_auth_headers()
    
    # Disclaimer test
    disc_res = client.get("/api/v1/health/disclaimer")
    assert disc_res.status_code == 200
    assert disc_res.json()["is_diagnostic"] is False
    
    # Log menstrual entry
    log_res = client.post("/api/v1/health/menstrual", json={
        "start_date": "2026-08-10",
        "end_date": "2026-08-15",
        "flow_intensity": "Medium",
        "cramps_severity": 2,
        "fatigue_level": 3,
        "notes": "Light exercise helped cramps"
    }, headers=headers)
    assert log_res.status_code == 200
    
    # Check cycle analysis
    analysis_res = client.get("/api/v1/health/cycle-analysis", headers=headers)
    assert analysis_res.status_code == 200
    data = analysis_res.json()
    assert data["has_data"] is True


def test_digestive_health_tracking():
    headers = get_auth_headers()
    today_str = str(date.today())
    
    log_res = client.post("/api/v1/digestive/entries", json={
        "date": today_str,
        "time_of_day": "Evening",
        "bloating_severity": 2,
        "gas_burping_severity": 1,
        "constipation_severity": 1,
        "bristol_stool_type": 3,
        "passed_stool": True,
        "discomfort_level": 1,
        "suspected_triggers": "Late night meal, cabbage",
        "notes": "Ginger tea relieved bloating"
    }, headers=headers)
    assert log_res.status_code == 200
    
    sum_res = client.get("/api/v1/digestive/summary", headers=headers)
    assert sum_res.status_code == 200
    assert sum_res.json()["has_data"] is True


def test_gate_syllabus_and_mocks():
    headers = get_auth_headers()
    
    subjs_res = client.get("/api/v1/gate/subjects")
    assert subjs_res.status_code == 200
    subjects = subjs_res.json()
    assert len(subjects) == 12  # 12 official GATE CS subjects
    
    # Update topic status
    first_topic = subjects[0]["topics"][0]
    update_res = client.patch(f"/api/v1/gate/topics/{first_topic['id']}", json={
        "status": "In Progress",
        "pyq_completed": 15,
        "accuracy_pct": 80.0
    }, headers=headers)
    assert update_res.status_code == 200
    assert update_res.json()["status"] == "In Progress"
    
    # Log mock test
    mock_res = client.post("/api/v1/gate/mocks", json={
        "test_type": "GATE Topic Test",
        "title": "Linear Algebra Practice Test 1",
        "date": str(date.today()),
        "score": 21.5,
        "total_marks": 25.0,
        "time_taken_mins": 45,
        "weak_topics_identified": "Eigenvalue calculations"
    }, headers=headers)
    assert mock_res.status_code == 200
    assert mock_res.json()["accuracy_pct"] == 86.0


def test_semester_subjects():
    headers = get_auth_headers()
    
    sem_res = client.get("/api/v1/semester/subjects", headers=headers)
    assert sem_res.status_code == 200
    subjects = sem_res.json()
    assert len(subjects) == 5  # S1 to S5
    
    # Update first subject name
    first_subj = subjects[0]
    upd_res = client.put(f"/api/v1/semester/subjects/{first_subj['id']}", json={
        "name": "Cloud Computing & Microservices",
        "priority": "High"
    }, headers=headers)
    assert upd_res.status_code == 200
    assert upd_res.json()["name"] == "Cloud Computing & Microservices"
    
    # Complete unit 1
    unit = first_subj["units"][0]
    unit_res = client.patch(f"/api/v1/semester/units/{unit['id']}", json={
        "is_completed": True
    }, headers=headers)
    assert unit_res.status_code == 200
    assert unit_res.json()["is_completed"] is True


def test_excelr_and_placement():
    headers = get_auth_headers()
    
    sess_res = client.get("/api/v1/excelr/today-session", headers=headers)
    assert sess_res.status_code == 200
    
    tasks_res = client.get("/api/v1/excelr/tasks", headers=headers)
    assert tasks_res.status_code == 200
    assert len(tasks_res.json()) >= 4


def test_dashboard_summary():
    headers = get_auth_headers()
    today_str = str(date.today())
    
    res = client.get(f"/api/v1/analytics/dashboard-summary?target_date={today_str}", headers=headers)
    assert res.status_code == 200
    data = res.json()
    assert "welcome_message" in data
    assert "completion_percentage" in data
    assert data["water_intake_today_ml"] >= 500


def test_export_data():
    headers = get_auth_headers()
    res_json = client.get("/api/v1/auth/me/export?format=json", headers=headers)
    assert res_json.status_code == 200
    assert "weight_entries" in res_json.json()
    
    res_csv = client.get("/api/v1/auth/me/export?format=csv", headers=headers)
    assert res_csv.status_code == 200
    assert "csv_data" in res_csv.json()
