from datetime import datetime, date, time
from sqlalchemy import (
    Column, Integer, String, Float, Boolean, Date, Time, DateTime, ForeignKey, Text
)
from sqlalchemy.orm import relationship
from .database import Base


class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    email = Column(String(255), unique=True, index=True, nullable=False)
    hashed_password = Column(String(255), nullable=False)
    full_name = Column(String(255), nullable=False, default="BloomTrack User")
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    # Relationships
    preferences = relationship("UserPreference", back_populates="user", uselist=False, cascade="all, delete-orphan")
    tasks = relationship("ScheduledTask", back_populates="user", cascade="all, delete-orphan")
    goals = relationship("Goal", back_populates="user", cascade="all, delete-orphan")
    habits = relationship("HabitDefinition", back_populates="user", cascade="all, delete-orphan")
    habit_completions = relationship("HabitCompletion", back_populates="user", cascade="all, delete-orphan")
    weight_entries = relationship("WeightEntry", back_populates="user", cascade="all, delete-orphan")
    meal_entries = relationship("MealEntry", back_populates="user", cascade="all, delete-orphan")
    hydration_entries = relationship("HydrationEntry", back_populates="user", cascade="all, delete-orphan")
    workout_sessions = relationship("WorkoutSession", back_populates="user", cascade="all, delete-orphan")
    menstrual_entries = relationship("MenstrualEntry", back_populates="user", cascade="all, delete-orphan")
    symptom_entries = relationship("SymptomEntry", back_populates="user", cascade="all, delete-orphan")
    digestive_entries = relationship("DigestiveEntry", back_populates="user", cascade="all, delete-orphan")
    study_sessions = relationship("StudySession", back_populates="user", cascade="all, delete-orphan")
    mock_tests = relationship("MockTest", back_populates="user", cascade="all, delete-orphan")
    semester_subjects = relationship("SemesterSubject", back_populates="user", cascade="all, delete-orphan")
    training_sessions = relationship("TrainingSession", back_populates="user", cascade="all, delete-orphan")
    placement_tasks = relationship("PlacementTask", back_populates="user", cascade="all, delete-orphan")
    notification_preferences = relationship("NotificationPreference", back_populates="user", cascade="all, delete-orphan")
    notifications = relationship("NotificationHistory", back_populates="user", cascade="all, delete-orphan")


class UserPreference(Base):
    __tablename__ = "user_preferences"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), unique=True, nullable=False)
    
    height_cm = Column(Float, default=162.6)  # 5ft 4in
    starting_weight_kg = Column(Float, default=66.0)
    target_weight_kg = Column(Float, default=56.0)
    current_weight_kg = Column(Float, default=66.0)
    
    timezone = Column(String(50), default="Asia/Kolkata")
    quiet_hours_start = Column(String(10), default="22:15")
    quiet_hours_end = Column(String(10), default="06:30")
    
    diet_preference = Column(String(50), default="Veg & Non-Veg with Eggs")
    workout_preference = Column(String(50), default="Home Workouts")
    
    pcod_history = Column(String(255), default="PCOD / Irregular cycles (2-3 months)")
    cycle_reminder_threshold_days = Column(Integer, default=60)
    previous_hemoglobin_g_dl = Column(Float, default=11.4)
    previous_hemoglobin_date = Column(Date, nullable=True)
    
    daily_water_target_ml = Column(Integer, default=2200)
    daily_sleep_target_hours = Column(Float, default=8.0)
    
    notifications_enabled = Column(Boolean, default=True)
    sound_enabled = Column(Boolean, default=True)

    user = relationship("User", back_populates="preferences")


class ScheduledTask(Base):
    __tablename__ = "scheduled_tasks"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    
    title = Column(String(255), nullable=False)
    category = Column(String(50), default="General")  # Morning, Study, Training, Evening, Health
    date = Column(Date, nullable=False, index=True)
    scheduled_time = Column(String(20), nullable=True)  # e.g., "06:30", "08:00 - 10:00"
    duration_minutes = Column(Integer, default=30)
    priority = Column(String(20), default="medium")  # low, medium, high
    
    is_completed = Column(Boolean, default=False, index=True)
    completed_at = Column(DateTime, nullable=True)
    
    notes = Column(Text, nullable=True)
    recurring_rule = Column(String(50), nullable=True)  # daily, weekday, weekend, custom
    is_custom = Column(Boolean, default=False)
    order_index = Column(Integer, default=0)

    user = relationship("User", back_populates="tasks")


class Goal(Base):
    __tablename__ = "goals"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    
    title = Column(String(255), nullable=False)
    category = Column(String(50), nullable=False)  # Health, GATE, Semester, Placement, etc.
    frequency = Column(String(20), default="daily")  # daily, weekly, one_time
    target_value = Column(Float, default=1.0)
    current_value = Column(Float, default=0.0)
    unit = Column(String(50), default="times")
    
    start_date = Column(Date, default=date.today)
    end_date = Column(Date, nullable=True)
    reminder_time = Column(String(10), nullable=True)
    
    is_completed = Column(Boolean, default=False)
    status = Column(String(20), default="active")  # active, paused, archived
    notes = Column(Text, nullable=True)

    user = relationship("User", back_populates="goals")


class HabitDefinition(Base):
    __tablename__ = "habit_definitions"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    
    title = Column(String(255), nullable=False)
    category = Column(String(50), default="Health")
    icon = Column(String(50), default="check_circle")
    target_days_per_week = Column(Integer, default=7)
    reminder_time = Column(String(10), nullable=True)
    current_streak = Column(Integer, default=0)
    best_streak = Column(Integer, default=0)

    user = relationship("User", back_populates="habits")
    completions = relationship("HabitCompletion", back_populates="habit", cascade="all, delete-orphan")


class HabitCompletion(Base):
    __tablename__ = "habit_completions"

    id = Column(Integer, primary_key=True, index=True)
    habit_id = Column(Integer, ForeignKey("habit_definitions.id", ondelete="CASCADE"), nullable=False, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    date = Column(Date, nullable=False, index=True)
    completed = Column(Boolean, default=True)
    notes = Column(String(255), nullable=True)

    habit = relationship("HabitDefinition", back_populates="completions")
    user = relationship("User", back_populates="habit_completions")


class WeightEntry(Base):
    __tablename__ = "weight_entries"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    date = Column(Date, nullable=False, index=True)
    weight_kg = Column(Float, nullable=False)
    waist_cm = Column(Float, nullable=True)
    notes = Column(Text, nullable=True)
    energy_level = Column(String(50), nullable=True)  # low, normal, high

    user = relationship("User", back_populates="weight_entries")


class MealEntry(Base):
    __tablename__ = "meal_entries"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    date = Column(Date, nullable=False, index=True)
    meal_type = Column(String(50), nullable=False)  # Breakfast, Lunch, Snack, Dinner
    description = Column(String(255), nullable=False)
    portion_notes = Column(String(255), nullable=True)
    is_veg = Column(Boolean, default=True)
    contains_egg = Column(Boolean, default=False)
    protein_g_est = Column(Float, default=0.0)
    fiber_g_est = Column(Float, default=0.0)
    calories_est = Column(Float, default=0.0)

    user = relationship("User", back_populates="meal_entries")


class HydrationEntry(Base):
    __tablename__ = "hydration_entries"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    date = Column(Date, nullable=False, index=True)
    amount_ml = Column(Integer, nullable=False)
    recorded_at = Column(DateTime, default=datetime.utcnow)

    user = relationship("User", back_populates="hydration_entries")


class WorkoutDefinition(Base):
    __tablename__ = "workout_definitions"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(255), nullable=False)
    category = Column(String(50), default="Home Workout")
    difficulty = Column(String(50), default="Beginner")
    duration_mins = Column(Integer, default=20)
    description = Column(Text, nullable=True)
    instructions = Column(Text, nullable=True)
    image_url = Column(String(255), nullable=True)
    target_body_parts = Column(String(255), nullable=True)


class WorkoutSession(Base):
    __tablename__ = "workout_sessions"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    workout_def_id = Column(Integer, ForeignKey("workout_definitions.id"), nullable=True)
    date = Column(Date, nullable=False, index=True)
    duration_mins = Column(Integer, default=25)
    completed = Column(Boolean, default=True)
    exercises_completed = Column(Text, nullable=True)  # JSON or comma-separated
    perceived_exertion = Column(Integer, default=5)  # 1-10
    notes = Column(Text, nullable=True)

    user = relationship("User", back_populates="workout_sessions")


class MenstrualEntry(Base):
    __tablename__ = "menstrual_entries"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    start_date = Column(Date, nullable=False, index=True)
    end_date = Column(Date, nullable=True)
    flow_intensity = Column(String(50), default="Medium")  # Spotting, Light, Medium, Heavy
    cramps_severity = Column(Integer, default=0)  # 0 to 5
    fatigue_level = Column(Integer, default=0)   # 0 to 5
    mood = Column(String(50), nullable=True)
    notes = Column(Text, nullable=True)

    user = relationship("User", back_populates="menstrual_entries")


class SymptomEntry(Base):
    __tablename__ = "symptom_entries"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    date = Column(Date, nullable=False, index=True)
    acne_severity = Column(Integer, default=0)      # 0 to 5
    mood_rating = Column(String(50), default="Good") # Happy, Calm, Anxious, Low, Irritable
    energy_level = Column(Integer, default=3)      # 1 to 5
    stress_level = Column(Integer, default=2)      # 1 to 5
    notes = Column(Text, nullable=True)

    user = relationship("User", back_populates="symptom_entries")


class DigestiveEntry(Base):
    __tablename__ = "digestive_entries"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    date = Column(Date, nullable=False, index=True)
    time_of_day = Column(String(50), default="Evening")
    bloating_severity = Column(Integer, default=0)     # 0 to 5
    gas_burping_severity = Column(Integer, default=0)  # 0 to 5
    constipation_severity = Column(Integer, default=0) # 0 to 5
    bristol_stool_type = Column(Integer, nullable=True) # 1 to 7
    passed_stool = Column(Boolean, default=True)
    discomfort_level = Column(Integer, default=0)       # 0 to 5
    suspected_triggers = Column(String(255), nullable=True) # e.g. "Dairy, pulses, late dinner"
    notes = Column(Text, nullable=True)

    user = relationship("User", back_populates="digestive_entries")


class GateSubject(Base):
    __tablename__ = "gate_subjects"

    id = Column(Integer, primary_key=True, index=True)
    code = Column(String(20), unique=True, nullable=False)
    name = Column(String(255), nullable=False)
    order_index = Column(Integer, default=0)

    topics = relationship("GateTopic", back_populates="subject", cascade="all, delete-orphan")


class GateTopic(Base):
    __tablename__ = "gate_topics"

    id = Column(Integer, primary_key=True, index=True)
    subject_id = Column(Integer, ForeignKey("gate_subjects.id", ondelete="CASCADE"), nullable=False, index=True)
    name = Column(String(255), nullable=False)
    status = Column(String(50), default="Not Started")  # Not Started, In Progress, Completed, Needs Revision
    pyq_completed = Column(Integer, default=0)
    accuracy_pct = Column(Float, default=0.0)
    formula_notes = Column(Text, nullable=True)
    notes = Column(Text, nullable=True)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    subject = relationship("GateSubject", back_populates="topics")


class StudySession(Base):
    __tablename__ = "study_sessions"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    category = Column(String(50), default="GATE")  # GATE, Semester, Placement
    subject_name = Column(String(255), nullable=False)
    date = Column(Date, nullable=False, index=True)
    duration_minutes = Column(Integer, default=60)
    topics_covered = Column(String(255), nullable=True)
    questions_solved = Column(Integer, default=0)
    notes = Column(Text, nullable=True)

    user = relationship("User", back_populates="study_sessions")


class MockTest(Base):
    __tablename__ = "mock_tests"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    test_type = Column(String(50), default="GATE Mock")  # GATE Full, GATE Topic, Semester Mock
    title = Column(String(255), nullable=False)
    date = Column(Date, nullable=False, index=True)
    score = Column(Float, nullable=False)
    total_marks = Column(Float, default=100.0)
    time_taken_mins = Column(Integer, default=180)
    accuracy_pct = Column(Float, default=0.0)
    weak_topics_identified = Column(Text, nullable=True)
    notes = Column(Text, nullable=True)

    user = relationship("User", back_populates="mock_tests")


class SemesterSubject(Base):
    __tablename__ = "semester_subjects"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    code = Column(String(20), nullable=False)  # S1, S2, S3, S4, S5
    name = Column(String(255), nullable=False)
    priority = Column(String(20), default="Medium")  # High, Medium, Low
    difficulty = Column(String(20), default="Medium")
    exam_date = Column(Date, nullable=True)
    syllabus_completion_pct = Column(Float, default=0.0)
    important_questions = Column(Text, nullable=True)
    notes = Column(Text, nullable=True)

    units = relationship("SemesterUnit", back_populates="subject", cascade="all, delete-orphan")
    user = relationship("User", back_populates="semester_subjects")


class SemesterUnit(Base):
    __tablename__ = "semester_units"

    id = Column(Integer, primary_key=True, index=True)
    subject_id = Column(Integer, ForeignKey("semester_subjects.id", ondelete="CASCADE"), nullable=False, index=True)
    unit_number = Column(Integer, nullable=False)
    title = Column(String(255), nullable=False)
    is_completed = Column(Boolean, default=False)
    revision_count = Column(Integer, default=0)
    notes = Column(Text, nullable=True)

    subject = relationship("SemesterSubject", back_populates="units")


class TrainingSession(Base):
    __tablename__ = "training_sessions"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    session_date = Column(Date, nullable=False, index=True)
    start_time = Column(String(10), default="17:00")
    end_time = Column(String(10), default="20:00")
    status = Column(String(50), default="Scheduled")  # Scheduled, Completed, Missed, Cancelled
    topics_covered = Column(Text, nullable=True)
    assignments_given = Column(Text, nullable=True)
    notes = Column(Text, nullable=True)

    user = relationship("User", back_populates="training_sessions")


class PlacementTask(Base):
    __tablename__ = "placement_tasks"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    title = Column(String(255), nullable=False)
    category = Column(String(50), default="Resume")  # Resume, Project, Coding Practice, Interview Prep, Application
    status = Column(String(50), default="Pending")    # Pending, In Progress, Completed
    deadline = Column(Date, nullable=True)
    company_name = Column(String(255), nullable=True)
    notes = Column(Text, nullable=True)

    user = relationship("User", back_populates="placement_tasks")


class NotificationPreference(Base):
    __tablename__ = "notification_preferences"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    category = Column(String(50), nullable=False)  # Morning, Study, Training, Hydration, Symptom, Exam
    enabled = Column(Boolean, default=True)
    reminder_time = Column(String(10), nullable=True)

    user = relationship("User", back_populates="notification_preferences")


class NotificationHistory(Base):
    __tablename__ = "notification_history"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    title = Column(String(255), nullable=False)
    body = Column(Text, nullable=False)
    category = Column(String(50), default="General")
    sent_at = Column(DateTime, default=datetime.utcnow)
    read_at = Column(DateTime, nullable=True)

    user = relationship("User", back_populates="notifications")
