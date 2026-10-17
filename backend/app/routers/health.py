from datetime import date, timedelta
from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from ..database import get_db
from ..models import User, MenstrualEntry, SymptomEntry
from ..schemas import (
    MenstrualEntryCreate, MenstrualEntryResponse,
    SymptomEntryCreate, SymptomEntryResponse
)
from ..auth import get_current_user

router = APIRouter(prefix="/health", tags=["Menstrual & PCOD Health"])

PCOD_EDUCATIONAL_DISCLAIMER = (
    "BloomTrack is a personal wellness tracking tool and does not provide medical diagnosis "
    "or cycle predictions. Because cycles with PCOD or irregular menstruation typically vary "
    "(such as every 2-3 months), standard 28-day cycle predictions are intentionally omitted. "
    "Clinical guideline note: If 90 days pass without a menstrual period, it is recommended "
    "to consult a qualified healthcare professional or gynecologist for personalized medical evaluation."
)


@router.get("/disclaimer")
def get_educational_disclaimer():
    return {
        "disclaimer": PCOD_EDUCATIONAL_DISCLAIMER,
        "is_diagnostic": False,
        "recommended_max_interval_days": 90
    }


@router.get("/menstrual", response_model=List[MenstrualEntryResponse])
def get_menstrual_entries(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    return db.query(MenstrualEntry).filter(
        MenstrualEntry.user_id == current_user.id
    ).order_by(MenstrualEntry.start_date.desc()).all()


@router.post("/menstrual", response_model=MenstrualEntryResponse)
def create_menstrual_entry(
    entry_in: MenstrualEntryCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    entry = MenstrualEntry(
        user_id=current_user.id,
        start_date=entry_in.start_date,
        end_date=entry_in.end_date,
        flow_intensity=entry_in.flow_intensity,
        cramps_severity=entry_in.cramps_severity,
        fatigue_level=entry_in.fatigue_level,
        mood=entry_in.mood,
        notes=entry_in.notes
    )
    db.add(entry)
    db.commit()
    db.refresh(entry)
    return entry


@router.get("/cycle-analysis")
def get_cycle_analysis(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    entries = db.query(MenstrualEntry).filter(
        MenstrualEntry.user_id == current_user.id
    ).order_by(MenstrualEntry.start_date.asc()).all()
    
    if not entries:
        return {
            "has_data": False,
            "days_since_last_period": None,
            "average_interval_days": None,
            "cycle_history": [],
            "needs_consultation_alert": False,
            "disclaimer": PCOD_EDUCATIONAL_DISCLAIMER
        }
        
    last_entry = entries[-1]
    days_since_last = (date.today() - last_entry.start_date).days
    
    # Calculate intervals between consecutive periods
    intervals = []
    cycle_history = []
    for i in range(1, len(entries)):
        diff = (entries[i].start_date - entries[i-1].start_date).days
        intervals.append(diff)
        cycle_history.append({
            "from_date": str(entries[i-1].start_date),
            "to_date": str(entries[i].start_date),
            "interval_days": diff
        })
        
    avg_interval = round(sum(intervals) / len(intervals), 1) if intervals else None
    
    threshold = current_user.preferences.cycle_reminder_threshold_days if current_user.preferences else 60
    needs_alert = days_since_last >= 90
    needs_prompt = days_since_last >= threshold
    
    return {
        "has_data": True,
        "last_period_date": str(last_entry.start_date),
        "days_since_last_period": days_since_last,
        "configured_threshold_days": threshold,
        "tracking_prompt_active": needs_prompt,
        "needs_consultation_alert": needs_alert,
        "average_interval_days": avg_interval,
        "cycle_history": cycle_history,
        "disclaimer": PCOD_EDUCATIONAL_DISCLAIMER
    }


@router.get("/symptoms", response_model=List[SymptomEntryResponse])
def get_symptom_entries(
    limit: int = 30,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    return db.query(SymptomEntry).filter(
        SymptomEntry.user_id == current_user.id
    ).order_by(SymptomEntry.date.desc()).limit(limit).all()


@router.post("/symptoms", response_model=SymptomEntryResponse)
def log_symptom(
    symptom_in: SymptomEntryCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    symptom = SymptomEntry(
        user_id=current_user.id,
        date=symptom_in.date,
        acne_severity=symptom_in.acne_severity,
        mood_rating=symptom_in.mood_rating,
        energy_level=symptom_in.energy_level,
        stress_level=symptom_in.stress_level,
        notes=symptom_in.notes
    )
    db.add(symptom)
    db.commit()
    db.refresh(symptom)
    return symptom
