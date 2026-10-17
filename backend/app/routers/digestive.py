from datetime import date
from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from ..database import get_db
from ..models import User, DigestiveEntry
from ..schemas import DigestiveEntryCreate, DigestiveEntryResponse
from ..auth import get_current_user

router = APIRouter(prefix="/digestive", tags=["Digestive & Gut Health Tracker"])

DIGESTIVE_RED_FLAGS = (
    "CLINICAL SAFETY NOTICE: If you experience acute severe, progressive abdominal pain, "
    "persistent vomiting, blood in stool, high fever, or complete inability to pass stool or gas for multiple days, "
    "seek immediate medical evaluation at an emergency clinic or with your doctor. BloomTrack does not diagnose "
    "gastrointestinal pathologies."
)

WELLNESS_GUT_GUIDANCE = [
    "Chew every bite thoroughly (20-30 times) to reduce swallowed air and lessen digestive workload.",
    "Stay hydrated between meals rather than chugging large amounts of cold water during meals.",
    "Take a gentle 10-15 minute walk after lunch and dinner to promote natural gut motility.",
    "Increase fibre gradually (such as soaked chia/flax seeds, cooked vegetables, and oats) while drinking sufficient water.",
    "Notice whether certain foods (e.g. raw cruciferous vegetables, heavy fried foods, unsoaked beans) trigger excess bloating."
]


@router.get("/guidance")
def get_digestive_guidance():
    return {
        "safety_red_flags": DIGESTIVE_RED_FLAGS,
        "tips": WELLNESS_GUT_GUIDANCE
    }


@router.get("/entries", response_model=List[DigestiveEntryResponse])
def get_digestive_entries(
    limit: int = 30,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    return db.query(DigestiveEntry).filter(
        DigestiveEntry.user_id == current_user.id
    ).order_by(DigestiveEntry.date.desc()).limit(limit).all()


@router.post("/entries", response_model=DigestiveEntryResponse)
def log_digestive_entry(
    entry_in: DigestiveEntryCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    entry = DigestiveEntry(
        user_id=current_user.id,
        date=entry_in.date,
        time_of_day=entry_in.time_of_day,
        bloating_severity=entry_in.bloating_severity,
        gas_burping_severity=entry_in.gas_burping_severity,
        constipation_severity=entry_in.constipation_severity,
        bristol_stool_type=entry_in.bristol_stool_type,
        passed_stool=entry_in.passed_stool,
        discomfort_level=entry_in.discomfort_level,
        suspected_triggers=entry_in.suspected_triggers,
        notes=entry_in.notes
    )
    db.add(entry)
    db.commit()
    db.refresh(entry)
    return entry


@router.get("/summary")
def get_digestive_summary(
    days: int = 14,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    entries = db.query(DigestiveEntry).filter(
        DigestiveEntry.user_id == current_user.id
    ).order_by(DigestiveEntry.date.desc()).limit(days).all()
    
    if not entries:
        return {
            "has_data": False,
            "avg_bloating": 0.0,
            "avg_gas": 0.0,
            "avg_constipation": 0.0,
            "trigger_mentions": [],
            "red_flag_alert": False
        }
        
    avg_bloat = round(sum(e.bloating_severity for e in entries) / len(entries), 1)
    avg_gas = round(sum(e.gas_burping_severity for e in entries) / len(entries), 1)
    avg_const = round(sum(e.constipation_severity for e in entries) / len(entries), 1)
    
    triggers = []
    for e in entries:
        if e.suspected_triggers:
            triggers.extend([t.strip() for t in e.suspected_triggers.split(",") if t.strip()])
            
    recent_discomfort_max = max(e.discomfort_level for e in entries)
    
    return {
        "has_data": True,
        "entry_count": len(entries),
        "avg_bloating": avg_bloat,
        "avg_gas": avg_gas,
        "avg_constipation": avg_const,
        "recent_discomfort_max": recent_discomfort_max,
        "trigger_mentions": list(set(triggers)),
        "red_flag_alert": recent_discomfort_max >= 5,
        "safety_notice": DIGESTIVE_RED_FLAGS if recent_discomfort_max >= 4 else None
    }
