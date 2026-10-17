from datetime import date, timedelta
from typing import List
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from ..database import get_db
from ..models import User, WeightEntry, UserPreference
from ..schemas import WeightEntryCreate, WeightEntryResponse
from ..auth import get_current_user

router = APIRouter(prefix="/weight", tags=["Weight & Body Metrics"])


@router.get("", response_model=List[WeightEntryResponse])
def get_weight_entries(
    limit: int = 50,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    return db.query(WeightEntry).filter(
        WeightEntry.user_id == current_user.id
    ).order_by(WeightEntry.date.desc()).limit(limit).all()


@router.post("", response_model=WeightEntryResponse)
def log_weight(
    entry_in: WeightEntryCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    entry = WeightEntry(
        user_id=current_user.id,
        date=entry_in.date,
        weight_kg=entry_in.weight_kg,
        waist_cm=entry_in.waist_cm,
        notes=entry_in.notes,
        energy_level=entry_in.energy_level
    )
    db.add(entry)
    
    # Update current weight in user preferences
    if current_user.preferences:
        current_user.preferences.current_weight_kg = entry_in.weight_kg
        
    db.commit()
    db.refresh(entry)
    return entry


@router.get("/progress")
def get_weight_progress(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    pref = current_user.preferences
    start_wt = pref.starting_weight_kg if pref else 66.0
    target_wt = pref.target_weight_kg if pref else 56.0
    
    latest_entry = db.query(WeightEntry).filter(
        WeightEntry.user_id == current_user.id
    ).order_by(WeightEntry.date.desc()).first()
    
    current_wt = latest_entry.weight_kg if latest_entry else (pref.current_weight_kg if pref else 66.0)
    
    total_to_lose = start_wt - target_wt
    lost_so_far = max(0.0, start_wt - current_wt)
    progress_pct = min(100.0, round((lost_so_far / total_to_lose) * 100, 1)) if total_to_lose > 0 else 0.0
    
    # Recent history for charts
    history = db.query(WeightEntry).filter(
        WeightEntry.user_id == current_user.id
    ).order_by(WeightEntry.date.asc()).limit(30).all()
    
    chart_data = [{"date": str(h.date), "weight_kg": h.weight_kg, "waist_cm": h.waist_cm} for h in history]
    
    return {
        "starting_weight_kg": start_wt,
        "target_weight_kg": target_wt,
        "current_weight_kg": current_wt,
        "weight_lost_kg": round(lost_so_far, 1),
        "remaining_kg": round(max(0.0, current_wt - target_wt), 1),
        "progress_percentage": progress_pct,
        "chart_data": chart_data,
        "philosophy": "Sustainable, gradual wellness progression without restrictive or crash dieting."
    }
