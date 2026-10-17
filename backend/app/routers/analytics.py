from datetime import date, timedelta
from typing import Dict, Any, List
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from sqlalchemy import func

from ..database import get_db
from ..models import (
    User, ScheduledTask, HydrationEntry, WeightEntry,
    WorkoutSession, GateTopic, SemesterSubject,
    MenstrualEntry, DigestiveEntry, TrainingSession
)
from ..schemas import DashboardSummaryResponse
from ..auth import get_current_user
from ..seed_data import generate_day_tasks

router = APIRouter(prefix="/analytics", tags=["Dashboard & Analytics"])


@router.get("/dashboard-summary", response_model=DashboardSummaryResponse)
def get_dashboard_summary(
    target_date: date = date.today(),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    # Ensure tasks are generated for target date
    generate_day_tasks(db, current_user.id, target_date)
    db.commit()
    
    # 1. Tasks
    tasks = db.query(ScheduledTask).filter(
        ScheduledTask.user_id == current_user.id,
        ScheduledTask.date == target_date
    ).all()
    
    total_tasks = len(tasks)
    completed_tasks = sum(1 for t in tasks if t.is_completed)
    pending_tasks = total_tasks - completed_tasks
    completion_pct = round((completed_tasks / total_tasks) * 100, 1) if total_tasks > 0 else 0.0
    
    # 2. Water
    pref = current_user.preferences
    water_target = pref.daily_water_target_ml if pref else 2200
    water_entries = db.query(HydrationEntry).filter(
        HydrationEntry.user_id == current_user.id,
        HydrationEntry.date == target_date
    ).all()
    water_intake = sum(w.amount_ml for w in water_entries)
    
    # 3. Weight
    current_wt = pref.current_weight_kg if pref else 66.0
    target_wt = pref.target_weight_kg if pref else 56.0
    
    # 4. Workout today
    workout_today = db.query(WorkoutSession).filter(
        WorkoutSession.user_id == current_user.id,
        WorkoutSession.date == target_date,
        WorkoutSession.completed == True
    ).first() is not None
    
    # 5. GATE Topics
    gate_total = db.query(GateTopic).count()
    gate_completed = db.query(GateTopic).filter(GateTopic.status == "Completed").count()
    
    # 6. Semester Average
    sem_subjects = db.query(SemesterSubject).filter(SemesterSubject.user_id == current_user.id).all()
    sem_avg = (
        round(sum(s.syllabus_completion_pct for s in sem_subjects) / len(sem_subjects), 1)
        if sem_subjects else 0.0
    )
    
    # 7. ExcelR Session Today
    excelr_session = db.query(TrainingSession).filter(
        TrainingSession.user_id == current_user.id,
        TrainingSession.session_date == target_date
    ).first()
    
    # 8. Menstrual cycle days since last
    last_period = db.query(MenstrualEntry).filter(
        MenstrualEntry.user_id == current_user.id
    ).order_by(MenstrualEntry.start_date.desc()).first()
    days_since_period = (date.today() - last_period.start_date).days if last_period else None
    
    # 9. Recent bloating
    recent_digestive = db.query(DigestiveEntry).filter(
        DigestiveEntry.user_id == current_user.id
    ).order_by(DigestiveEntry.date.desc()).first()
    recent_bloat = recent_digestive.bloating_severity if recent_digestive else 0
    
    name = current_user.full_name.split()[0] if current_user.full_name else "there"
    welcome = f"Welcome back, {name}! Let's make today count."
    
    return DashboardSummaryResponse(
        welcome_message=welcome,
        today_date=target_date,
        completion_percentage=completion_pct,
        total_tasks_today=total_tasks,
        completed_tasks_today=completed_tasks,
        pending_tasks_today=pending_tasks,
        water_intake_today_ml=water_intake,
        water_target_ml=water_target,
        current_weight_kg=current_wt,
        target_weight_kg=target_wt,
        workout_completed_today=workout_today,
        gate_topics_completed=gate_completed,
        gate_total_topics=gate_total,
        semester_avg_completion_pct=sem_avg,
        excelr_session_today=excelr_session,
        days_since_last_period=days_since_period,
        recent_bloating_level=recent_bloat
    )


@router.get("/weekly-consistency")
def get_weekly_consistency(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    today = date.today()
    start_date = today - timedelta(days=6)
    
    days_data = []
    for i in range(7):
        day = start_date + timedelta(days=i)
        tasks = db.query(ScheduledTask).filter(
            ScheduledTask.user_id == current_user.id,
            ScheduledTask.date == day
        ).all()
        
        total = len(tasks)
        done = sum(1 for t in tasks if t.is_completed)
        pct = round((done / total) * 100, 1) if total > 0 else 0.0
        
        days_data.append({
            "date": str(day),
            "day_name": day.strftime("%a"),
            "total_tasks": total,
            "completed_tasks": done,
            "completion_percentage": pct
        })
        
    return days_data
