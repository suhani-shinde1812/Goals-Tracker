from datetime import date, timedelta
from typing import List
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from ..database import get_db
from ..models import User, HabitDefinition, HabitCompletion
from ..schemas import HabitCreate, HabitResponse, HabitCompletionCreate
from ..auth import get_current_user

router = APIRouter(prefix="/habits", tags=["Habits & Streaks"])


@router.get("", response_model=List[HabitResponse])
def get_habits(
    target_date: date = date.today(),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    habits = db.query(HabitDefinition).filter(HabitDefinition.user_id == current_user.id).all()
    results = []
    
    for h in habits:
        completion = db.query(HabitCompletion).filter(
            HabitCompletion.habit_id == h.id,
            HabitCompletion.date == target_date,
            HabitCompletion.completed == True
        ).first()
        
        results.append(HabitResponse(
            id=h.id,
            user_id=h.user_id,
            title=h.title,
            category=h.category,
            icon=h.icon,
            target_days_per_week=h.target_days_per_week,
            reminder_time=h.reminder_time,
            current_streak=h.current_streak,
            best_streak=h.best_streak,
            today_completed=bool(completion)
        ))
    return results


@router.post("", response_model=HabitResponse)
def create_habit(
    habit_in: HabitCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    habit = HabitDefinition(
        user_id=current_user.id,
        title=habit_in.title,
        category=habit_in.category,
        icon=habit_in.icon,
        target_days_per_week=habit_in.target_days_per_week,
        reminder_time=habit_in.reminder_time,
        current_streak=0,
        best_streak=0
    )
    db.add(habit)
    db.commit()
    db.refresh(habit)
    return HabitResponse(
        id=habit.id,
        user_id=habit.user_id,
        title=habit.title,
        category=habit.category,
        icon=habit.icon,
        target_days_per_week=habit.target_days_per_week,
        reminder_time=habit.reminder_time,
        current_streak=0,
        best_streak=0,
        today_completed=False
    )


@router.post("/toggle")
def toggle_habit_completion(
    completion_in: HabitCompletionCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    habit = db.query(HabitDefinition).filter(
        HabitDefinition.id == completion_in.habit_id,
        HabitDefinition.user_id == current_user.id
    ).first()
    if not habit:
        raise HTTPException(status_code=404, detail="Habit not found")
        
    completion = db.query(HabitCompletion).filter(
        HabitCompletion.habit_id == habit.id,
        HabitCompletion.date == completion_in.date
    ).first()
    
    if completion:
        completion.completed = not completion.completed
        is_done = completion.completed
    else:
        completion = HabitCompletion(
            habit_id=habit.id,
            user_id=current_user.id,
            date=completion_in.date,
            completed=True,
            notes=completion_in.notes
        )
        db.add(completion)
        is_done = True
        
    db.flush()
    # Recalculate streak
    today = date.today()
    streak = 0
    check_day = today
    while True:
        c = db.query(HabitCompletion).filter(
            HabitCompletion.habit_id == habit.id,
            HabitCompletion.date == check_day,
            HabitCompletion.completed == True
        ).first()
        if c:
            streak += 1
            check_day = check_day - timedelta(days=1)
        else:
            break
            
    habit.current_streak = streak
    if streak > habit.best_streak:
        habit.best_streak = streak
        
    db.commit()
    return {"habit_id": habit.id, "completed": is_done, "current_streak": habit.current_streak}


@router.get("/heatmap")
def get_habit_heatmap(
    days: int = 28,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    start_date = date.today() - timedelta(days=days - 1)
    completions = db.query(HabitCompletion).filter(
        HabitCompletion.user_id == current_user.id,
        HabitCompletion.date >= start_date,
        HabitCompletion.completed == True
    ).all()
    
    heatmap = {}
    for d in range(days):
        day_str = str(start_date + timedelta(days=d))
        heatmap[day_str] = 0
        
    for c in completions:
        day_str = str(c.date)
        if day_str in heatmap:
            heatmap[day_str] += 1
            
    return [{"date": k, "count": v} for k, v in heatmap.items()]
