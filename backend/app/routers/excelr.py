from datetime import date, timedelta
from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from ..database import get_db
from ..models import User, TrainingSession, PlacementTask
from ..schemas import (
    TrainingSessionCreate, TrainingSessionUpdate, TrainingSessionResponse,
    PlacementTaskCreate, PlacementTaskUpdate, PlacementTaskResponse
)
from ..auth import get_current_user

router = APIRouter(prefix="/excelr", tags=["ExcelR Training & Placements"])


@router.get("/today-session", response_model=Optional[TrainingSessionResponse])
def get_today_training_session(
    target_date: date = date.today(),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    session = db.query(TrainingSession).filter(
        TrainingSession.user_id == current_user.id,
        TrainingSession.session_date == target_date
    ).first()
    
    if not session:
        # Auto-create if Mon-Sat
        weekday = target_date.weekday()
        if weekday < 5:  # Mon-Fri 17:00-20:00
            session = TrainingSession(
                user_id=current_user.id,
                session_date=target_date,
                start_time="17:00",
                end_time="20:00",
                status="Scheduled"
            )
            db.add(session)
            db.commit()
            db.refresh(session)
        elif weekday == 5:  # Sat 14:00-17:00
            session = TrainingSession(
                user_id=current_user.id,
                session_date=target_date,
                start_time="14:00",
                end_time="17:00",
                status="Scheduled"
            )
            db.add(session)
            db.commit()
            db.refresh(session)
            
    return session


@router.patch("/sessions/{session_id}/status", response_model=TrainingSessionResponse)
def update_training_status(
    session_id: int,
    status_str: str,  # Completed, Missed, Cancelled
    notes: Optional[str] = None,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    session = db.query(TrainingSession).filter(
        TrainingSession.id == session_id,
        TrainingSession.user_id == current_user.id
    ).first()
    if not session:
        raise HTTPException(status_code=404, detail="Training session not found")
        
    session.status = status_str
    if notes:
        session.notes = notes
    db.commit()
    db.refresh(session)
    return session


@router.get("/tasks", response_model=List[PlacementTaskResponse])
def get_placement_tasks(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    # Ensure default tasks exist
    tasks = db.query(PlacementTask).filter(PlacementTask.user_id == current_user.id).all()
    if not tasks:
        defaults = [
            ("Update Resume with Spring Boot & Python Projects", "Resume", "In Progress"),
            ("DSA LeetCode 75 Problems Tracker", "Coding Practice", "In Progress"),
            ("Mock HR & Technical Interview Prep", "Interview Prep", "Pending"),
            ("Portfolio Website & GitHub Profile Polish", "Project", "Pending")
        ]
        for title, cat, st in defaults:
            t = PlacementTask(
                user_id=current_user.id,
                title=title,
                category=cat,
                status=st
            )
            db.add(t)
        db.commit()
        tasks = db.query(PlacementTask).filter(PlacementTask.user_id == current_user.id).all()
        
    return tasks


@router.post("/tasks", response_model=PlacementTaskResponse)
def create_placement_task(
    task_in: PlacementTaskCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    task = PlacementTask(
        user_id=current_user.id,
        title=task_in.title,
        category=task_in.category,
        status=task_in.status,
        deadline=task_in.deadline,
        company_name=task_in.company_name,
        notes=task_in.notes
    )
    db.add(task)
    db.commit()
    db.refresh(task)
    return task


@router.patch("/tasks/{task_id}", response_model=PlacementTaskResponse)
def update_placement_task(
    task_id: int,
    task_in: PlacementTaskUpdate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    task = db.query(PlacementTask).filter(
        PlacementTask.id == task_id,
        PlacementTask.user_id == current_user.id
    ).first()
    if not task:
        raise HTTPException(status_code=404, detail="Task not found")
        
    update_data = task_in.model_dump(exclude_unset=True)
    for field, val in update_data.items():
        setattr(task, field, val)
        
    db.commit()
    db.refresh(task)
    return task
