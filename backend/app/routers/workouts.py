from datetime import date, timedelta
from typing import List
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from ..database import get_db
from ..models import User, WorkoutDefinition, WorkoutSession
from ..schemas import (
    WorkoutDefinitionResponse, WorkoutSessionCreate, WorkoutSessionResponse
)
from ..auth import get_current_user

router = APIRouter(prefix="/workouts", tags=["Workouts & Exercise"])


@router.get("/library", response_model=List[WorkoutDefinitionResponse])
def get_workout_library(db: Session = Depends(get_db)):
    return db.query(WorkoutDefinition).all()


@router.get("/sessions", response_model=List[WorkoutSessionResponse])
def get_workout_sessions(
    limit: int = 30,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    return db.query(WorkoutSession).filter(
        WorkoutSession.user_id == current_user.id
    ).order_by(WorkoutSession.date.desc()).limit(limit).all()


@router.post("/sessions", response_model=WorkoutSessionResponse)
def log_workout_session(
    session_in: WorkoutSessionCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    session = WorkoutSession(
        user_id=current_user.id,
        workout_def_id=session_in.workout_def_id,
        date=session_in.date,
        duration_mins=session_in.duration_mins,
        completed=session_in.completed,
        exercises_completed=session_in.exercises_completed,
        perceived_exertion=session_in.perceived_exertion,
        notes=session_in.notes
    )
    db.add(session)
    db.commit()
    db.refresh(session)
    return session


@router.get("/weekly-progress")
def get_weekly_workout_progress(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    # Last 7 days
    start_date = date.today() - timedelta(days=6)
    sessions = db.query(WorkoutSession).filter(
        WorkoutSession.user_id == current_user.id,
        WorkoutSession.date >= start_date,
        WorkoutSession.completed == True
    ).all()
    
    total_mins = sum(s.duration_mins for s in sessions)
    target_mins = 150  # Recommended 150 min moderate activity per week
    progress_pct = min(100.0, round((total_mins / target_mins) * 100, 1))
    
    return {
        "weekly_minutes_active": total_mins,
        "weekly_target_minutes": target_mins,
        "progress_percentage": progress_pct,
        "sessions_count": len(sessions),
        "target_met": total_mins >= target_mins
    }
