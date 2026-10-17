from datetime import date, datetime, time
from typing import Optional, List
from pydantic import BaseModel, EmailStr, Field


# Auth & User
class Token(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user_id: int
    full_name: str
    email: str


class TokenData(BaseModel):
    email: Optional[str] = None
    user_id: Optional[int] = None


class UserCreate(BaseModel):
    email: EmailStr
    password: str = Field(..., min_length=6)
    full_name: str = "BloomTrack User"


class UserLogin(BaseModel):
    email: EmailStr
    password: str


class UserPreferenceUpdate(BaseModel):
    height_cm: Optional[float] = None
    starting_weight_kg: Optional[float] = None
    target_weight_kg: Optional[float] = None
    current_weight_kg: Optional[float] = None
    timezone: Optional[str] = None
    quiet_hours_start: Optional[str] = None
    quiet_hours_end: Optional[str] = None
    diet_preference: Optional[str] = None
    workout_preference: Optional[str] = None
    pcod_history: Optional[str] = None
    cycle_reminder_threshold_days: Optional[int] = None
    previous_hemoglobin_g_dl: Optional[float] = None
    previous_hemoglobin_date: Optional[date] = None
    daily_water_target_ml: Optional[int] = None
    daily_sleep_target_hours: Optional[float] = None
    notifications_enabled: Optional[bool] = None
    sound_enabled: Optional[bool] = None


class UserPreferenceResponse(BaseModel):
    id: int
    user_id: int
    height_cm: float
    starting_weight_kg: float
    target_weight_kg: float
    current_weight_kg: float
    timezone: str
    quiet_hours_start: str
    quiet_hours_end: str
    diet_preference: str
    workout_preference: str
    pcod_history: Optional[str]
    cycle_reminder_threshold_days: int
    previous_hemoglobin_g_dl: Optional[float]
    previous_hemoglobin_date: Optional[date]
    daily_water_target_ml: int
    daily_sleep_target_hours: float
    notifications_enabled: bool
    sound_enabled: bool

    class Config:
        from_attributes = True


class UserResponse(BaseModel):
    id: int
    email: str
    full_name: str
    is_active: bool
    created_at: datetime
    preferences: Optional[UserPreferenceResponse] = None

    class Config:
        from_attributes = True


# Scheduled Tasks
class ScheduledTaskCreate(BaseModel):
    title: str
    category: str = "General"
    date: date
    scheduled_time: Optional[str] = None
    duration_minutes: int = 30
    priority: str = "medium"
    notes: Optional[str] = None
    recurring_rule: Optional[str] = None
    order_index: int = 0


class ScheduledTaskUpdate(BaseModel):
    title: Optional[str] = None
    category: Optional[str] = None
    date: Optional[date] = None
    scheduled_time: Optional[str] = None
    duration_minutes: Optional[int] = None
    priority: Optional[str] = None
    is_completed: Optional[bool] = None
    notes: Optional[str] = None
    order_index: Optional[int] = None


class ScheduledTaskResponse(BaseModel):
    id: int
    user_id: int
    title: str
    category: str
    date: date
    scheduled_time: Optional[str]
    duration_minutes: int
    priority: str
    is_completed: bool
    completed_at: Optional[datetime]
    notes: Optional[str]
    recurring_rule: Optional[str]
    is_custom: bool
    order_index: int

    class Config:
        from_attributes = True


# Goals & Habits
class GoalCreate(BaseModel):
    title: str
    category: str
    frequency: str = "daily"
    target_value: float = 1.0
    unit: str = "times"
    start_date: date = Field(default_factory=date.today)
    end_date: Optional[date] = None
    reminder_time: Optional[str] = None
    notes: Optional[str] = None


class GoalUpdate(BaseModel):
    title: Optional[str] = None
    category: Optional[str] = None
    frequency: Optional[str] = None
    target_value: Optional[float] = None
    current_value: Optional[float] = None
    unit: Optional[str] = None
    is_completed: Optional[bool] = None
    status: Optional[str] = None
    notes: Optional[str] = None


class GoalResponse(BaseModel):
    id: int
    user_id: int
    title: str
    category: str
    frequency: str
    target_value: float
    current_value: float
    unit: str
    start_date: date
    end_date: Optional[date]
    reminder_time: Optional[str]
    is_completed: bool
    status: str
    notes: Optional[str]

    class Config:
        from_attributes = True


class HabitCreate(BaseModel):
    title: str
    category: str = "Health"
    icon: str = "check_circle"
    target_days_per_week: int = 7
    reminder_time: Optional[str] = None


class HabitResponse(BaseModel):
    id: int
    user_id: int
    title: str
    category: str
    icon: str
    target_days_per_week: int
    reminder_time: Optional[str]
    current_streak: int
    best_streak: int
    today_completed: bool = False

    class Config:
        from_attributes = True


class HabitCompletionCreate(BaseModel):
    habit_id: int
    date: date
    completed: bool = True
    notes: Optional[str] = None


# Weight, Meals, Hydration
class WeightEntryCreate(BaseModel):
    date: date
    weight_kg: float
    waist_cm: Optional[float] = None
    notes: Optional[str] = None
    energy_level: Optional[str] = None


class WeightEntryResponse(BaseModel):
    id: int
    user_id: int
    date: date
    weight_kg: float
    waist_cm: Optional[float]
    notes: Optional[str]
    energy_level: Optional[str]

    class Config:
        from_attributes = True


class MealEntryCreate(BaseModel):
    date: date
    meal_type: str
    description: str
    portion_notes: Optional[str] = None
    is_veg: bool = True
    contains_egg: bool = False
    protein_g_est: float = 0.0
    fiber_g_est: float = 0.0
    calories_est: float = 0.0


class MealEntryResponse(BaseModel):
    id: int
    user_id: int
    date: date
    meal_type: str
    description: str
    portion_notes: Optional[str]
    is_veg: bool
    contains_egg: bool
    protein_g_est: float
    fiber_g_est: float
    calories_est: float

    class Config:
        from_attributes = True


class HydrationCreate(BaseModel):
    date: date
    amount_ml: int


class HydrationResponse(BaseModel):
    id: int
    user_id: int
    date: date
    amount_ml: int
    recorded_at: datetime

    class Config:
        from_attributes = True


# Workouts
class WorkoutDefinitionResponse(BaseModel):
    id: int
    name: str
    category: str
    difficulty: str
    duration_mins: int
    description: Optional[str]
    instructions: Optional[str]
    image_url: Optional[str]
    target_body_parts: Optional[str]

    class Config:
        from_attributes = True


class WorkoutSessionCreate(BaseModel):
    workout_def_id: Optional[int] = None
    date: date
    duration_mins: int = 25
    completed: bool = True
    exercises_completed: Optional[str] = None
    perceived_exertion: int = 5
    notes: Optional[str] = None


class WorkoutSessionResponse(BaseModel):
    id: int
    user_id: int
    workout_def_id: Optional[int]
    date: date
    duration_mins: int
    completed: bool
    exercises_completed: Optional[str]
    perceived_exertion: int
    notes: Optional[str]

    class Config:
        from_attributes = True


# Menstrual & Digestive
class MenstrualEntryCreate(BaseModel):
    start_date: date
    end_date: Optional[date] = None
    flow_intensity: str = "Medium"
    cramps_severity: int = 0
    fatigue_level: int = 0
    mood: Optional[str] = None
    notes: Optional[str] = None


class MenstrualEntryResponse(BaseModel):
    id: int
    user_id: int
    start_date: date
    end_date: Optional[date]
    flow_intensity: str
    cramps_severity: int
    fatigue_level: int
    mood: Optional[str]
    notes: Optional[str]

    class Config:
        from_attributes = True


class SymptomEntryCreate(BaseModel):
    date: date
    acne_severity: int = 0
    mood_rating: str = "Good"
    energy_level: int = 3
    stress_level: int = 2
    notes: Optional[str] = None


class SymptomEntryResponse(BaseModel):
    id: int
    user_id: int
    date: date
    acne_severity: int
    mood_rating: str
    energy_level: int
    stress_level: int
    notes: Optional[str]

    class Config:
        from_attributes = True


class DigestiveEntryCreate(BaseModel):
    date: date
    time_of_day: str = "Evening"
    bloating_severity: int = 0
    gas_burping_severity: int = 0
    constipation_severity: int = 0
    bristol_stool_type: Optional[int] = None
    passed_stool: bool = True
    discomfort_level: int = 0
    suspected_triggers: Optional[str] = None
    notes: Optional[str] = None


class DigestiveEntryResponse(BaseModel):
    id: int
    user_id: int
    date: date
    time_of_day: str
    bloating_severity: int
    gas_burping_severity: int
    constipation_severity: int
    bristol_stool_type: Optional[int]
    passed_stool: bool
    discomfort_level: int
    suspected_triggers: Optional[str]
    notes: Optional[str]

    class Config:
        from_attributes = True


# GATE CS
class GateTopicUpdate(BaseModel):
    status: Optional[str] = None
    pyq_completed: Optional[int] = None
    accuracy_pct: Optional[float] = None
    formula_notes: Optional[str] = None
    notes: Optional[str] = None


class GateTopicResponse(BaseModel):
    id: int
    subject_id: int
    name: str
    status: str
    pyq_completed: int
    accuracy_pct: float
    formula_notes: Optional[str]
    notes: Optional[str]
    updated_at: datetime

    class Config:
        from_attributes = True


class GateSubjectResponse(BaseModel):
    id: int
    code: str
    name: str
    order_index: int
    topics: List[GateTopicResponse] = []

    class Config:
        from_attributes = True


class StudySessionCreate(BaseModel):
    category: str = "GATE"
    subject_name: str
    date: date
    duration_minutes: int = 60
    topics_covered: Optional[str] = None
    questions_solved: int = 0
    notes: Optional[str] = None


class StudySessionResponse(BaseModel):
    id: int
    user_id: int
    category: str
    subject_name: str
    date: date
    duration_minutes: int
    topics_covered: Optional[str]
    questions_solved: int
    notes: Optional[str]

    class Config:
        from_attributes = True


class MockTestCreate(BaseModel):
    test_type: str = "GATE Mock"
    title: str
    date: date
    score: float
    total_marks: float = 100.0
    time_taken_mins: int = 180
    accuracy_pct: float = 0.0
    weak_topics_identified: Optional[str] = None
    notes: Optional[str] = None


class MockTestResponse(BaseModel):
    id: int
    user_id: int
    test_type: str
    title: str
    date: date
    score: float
    total_marks: float
    time_taken_mins: int
    accuracy_pct: float
    weak_topics_identified: Optional[str]
    notes: Optional[str]

    class Config:
        from_attributes = True


# Semester
class SemesterUnitUpdate(BaseModel):
    is_completed: Optional[bool] = None
    revision_count: Optional[int] = None
    notes: Optional[str] = None


class SemesterUnitResponse(BaseModel):
    id: int
    subject_id: int
    unit_number: int
    title: str
    is_completed: bool
    revision_count: int
    notes: Optional[str]

    class Config:
        from_attributes = True


class SemesterSubjectCreate(BaseModel):
    code: str
    name: str
    priority: str = "Medium"
    difficulty: str = "Medium"
    exam_date: Optional[date] = None
    important_questions: Optional[str] = None
    notes: Optional[str] = None


class SemesterSubjectUpdate(BaseModel):
    name: Optional[str] = None
    priority: Optional[str] = None
    difficulty: Optional[str] = None
    exam_date: Optional[date] = None
    syllabus_completion_pct: Optional[float] = None
    important_questions: Optional[str] = None
    notes: Optional[str] = None


class SemesterSubjectResponse(BaseModel):
    id: int
    user_id: int
    code: str
    name: str
    priority: str
    difficulty: str
    exam_date: Optional[date]
    syllabus_completion_pct: float
    important_questions: Optional[str]
    notes: Optional[str]
    units: List[SemesterUnitResponse] = []

    class Config:
        from_attributes = True


# Training & Placements
class TrainingSessionCreate(BaseModel):
    session_date: date
    start_time: str = "17:00"
    end_time: str = "20:00"
    status: str = "Scheduled"
    topics_covered: Optional[str] = None
    assignments_given: Optional[str] = None
    notes: Optional[str] = None


class TrainingSessionUpdate(BaseModel):
    status: Optional[str] = None
    topics_covered: Optional[str] = None
    assignments_given: Optional[str] = None
    notes: Optional[str] = None


class TrainingSessionResponse(BaseModel):
    id: int
    user_id: int
    session_date: date
    start_time: str
    end_time: str
    status: str
    topics_covered: Optional[str]
    assignments_given: Optional[str]
    notes: Optional[str]

    class Config:
        from_attributes = True


class PlacementTaskCreate(BaseModel):
    title: str
    category: str = "Resume"
    status: str = "Pending"
    deadline: Optional[date] = None
    company_name: Optional[str] = None
    notes: Optional[str] = None


class PlacementTaskUpdate(BaseModel):
    title: Optional[str] = None
    category: Optional[str] = None
    status: Optional[str] = None
    deadline: Optional[date] = None
    company_name: Optional[str] = None
    notes: Optional[str] = None


class PlacementTaskResponse(BaseModel):
    id: int
    user_id: int
    title: str
    category: str
    status: str
    deadline: Optional[date]
    company_name: Optional[str]
    notes: Optional[str]

    class Config:
        from_attributes = True


# Dashboard Summary
class DashboardSummaryResponse(BaseModel):
    welcome_message: str
    today_date: date
    completion_percentage: float
    total_tasks_today: int
    completed_tasks_today: int
    pending_tasks_today: int
    water_intake_today_ml: int
    water_target_ml: int
    current_weight_kg: float
    target_weight_kg: float
    workout_completed_today: bool
    gate_topics_completed: int
    gate_total_topics: int
    semester_avg_completion_pct: float
    excelr_session_today: Optional[TrainingSessionResponse] = None
    days_since_last_period: Optional[int] = None
    recent_bloating_level: int = 0
