from datetime import date, datetime
from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from ..database import get_db
from ..models import User, ScheduledTask
from ..schemas import (
    ScheduledTaskCreate, ScheduledTaskUpdate, ScheduledTaskResponse
)
from ..auth import get_current_user
from ..seed_data import generate_day_tasks

router = APIRouter(prefix="/tasks", tags=["Daily Tasks & Schedule"])


@router.get("", response_model=List[ScheduledTaskResponse])
def get_tasks_for_date(
    target_date: Optional[date] = None,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    if not target_date:
        target_date = date.today()
        
    # Auto-generate schedule if day has no tasks yet
    generate_day_tasks(db, current_user.id, target_date)
    db.commit()
    
    tasks = db.query(ScheduledTask).filter(
        ScheduledTask.user_id == current_user.id,
        ScheduledTask.date == target_date
    ).order_index = ScheduledTask.order_index
    
    return db.query(ScheduledTask).filter(
        ScheduledTask.user_id == current_user.id,
        ScheduledTask.date == target_date
    ).order_by(ScheduledTask.order_index).all()


@router.post("", response_model=ScheduledTaskResponse)
def create_custom_task(
    task_in: ScheduledTaskCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    task = ScheduledTask(
        user_id=current_user.id,
        title=task_in.title,
        category=task_in.category,
        date=task_in.date,
        scheduled_time=task_in.scheduled_time,
        duration_minutes=task_in.duration_minutes,
        priority=task_in.priority,
        notes=task_in.notes,
        recurring_rule=task_in.recurring_rule,
        is_custom=True,
        order_index=task_in.order_index
    )
    db.add(task)
    db.commit()
    db.refresh(task)
    return task


@router.patch("/{task_id}/toggle", response_model=ScheduledTaskResponse)
def toggle_task_completion(
    task_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    task = db.query(ScheduledTask).filter(
        ScheduledTask.id == task_id,
        ScheduledTask.user_id == current_user.id
    ).first()
    
    if not task:
        raise HTTPException(status_code=404, detail="Task not found")
        
    task.is_completed = not task.is_completed
    task.completed_at = datetime.utcnow() if task.is_completed else None
    
    db.commit()
    db.refresh(task)
    return task


@router.put("/{task_id}", response_model=ScheduledTaskResponse)
def update_task(
    task_id: int,
    task_update: ScheduledTaskUpdate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    task = db.query(ScheduledTask).filter(
        ScheduledTask.id == task_id,
        ScheduledTask.user_id == current_user.id
    ).first()
    
    if not task:
        raise HTTPException(status_code=404, detail="Task not found")
        
    update_data = task_update.model_dump(exclude_unset=True)
    if "is_completed" in update_data and update_data["is_completed"] is not None:
        task.completed_at = datetime.utcnow() if update_data["is_completed"] else None
        
    for field, val in update_data.items():
        setattr(task, field, val)
        
    db.commit()
    db.refresh(task)
    return task


@router.post("/{task_id}/reschedule", response_model=ScheduledTaskResponse)
def reschedule_task(
    task_id: int,
    new_date: date,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    task = db.query(ScheduledTask).filter(
        ScheduledTask.id == task_id,
        ScheduledTask.user_id == current_user.id
    ).first()
    
    if not task:
        raise HTTPException(status_code=404, detail="Task not found")
        
    task.date = new_date
    task.is_completed = False
    task.completed_at = None
    
    db.commit()
    db.refresh(task)
    return task


@router.delete("/{task_id}")
def delete_task(
    task_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    task = db.query(ScheduledTask).filter(
        ScheduledTask.id == task_id,
        ScheduledTask.user_id == current_user.id
    ).first()
    
    if not task:
        raise HTTPException(status_code=404, detail="Task not found")
        
    db.delete(task)
    db.commit()
    return {"message": "Task successfully deleted"}
