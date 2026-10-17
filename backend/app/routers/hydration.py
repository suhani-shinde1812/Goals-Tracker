from datetime import date
from typing import List
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from sqlalchemy import func

from ..database import get_db
from ..models import User, HydrationEntry
from ..schemas import HydrationCreate, HydrationResponse
from ..auth import get_current_user

router = APIRouter(prefix="/hydration", tags=["Hydration Tracker"])


@router.get("/today")
def get_today_hydration(
    target_date: date = date.today(),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    pref = current_user.preferences
    target_ml = pref.daily_water_target_ml if pref else 2200
    
    entries = db.query(HydrationEntry).filter(
        HydrationEntry.user_id == current_user.id,
        HydrationEntry.date == target_date
    ).all()
    
    total_ml = sum(e.amount_ml for e in entries)
    pct = min(100.0, round((total_ml / target_ml) * 100, 1)) if target_ml > 0 else 0.0
    remaining_ml = max(0, target_ml - total_ml)
    
    return {
        "date": str(target_date),
        "target_ml": target_ml,
        "total_ml": total_ml,
        "remaining_ml": remaining_ml,
        "percentage": pct,
        "glasses_count": round(total_ml / 250, 1),
        "entries": [
            {"id": e.id, "amount_ml": e.amount_ml, "recorded_at": str(e.recorded_at.strftime("%H:%M"))}
            for e in entries
        ]
    }


@router.post("/add", response_model=HydrationResponse)
def add_water(
    hydration_in: HydrationCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    entry = HydrationEntry(
        user_id=current_user.id,
        date=hydration_in.date,
        amount_ml=hydration_in.amount_ml
    )
    db.add(entry)
    db.commit()
    db.refresh(entry)
    return entry


@router.delete("/reset")
def reset_today_water(
    target_date: date = date.today(),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    db.query(HydrationEntry).filter(
        HydrationEntry.user_id == current_user.id,
        HydrationEntry.date == target_date
    ).delete()
    db.commit()
    return {"message": "Hydration for today reset to 0 ml"}
