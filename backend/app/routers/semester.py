from datetime import date
from typing import List
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from ..database import get_db
from ..models import User, SemesterSubject, SemesterUnit
from ..schemas import (
    SemesterSubjectCreate, SemesterSubjectUpdate, SemesterSubjectResponse,
    SemesterUnitUpdate, SemesterUnitResponse
)
from ..auth import get_current_user

router = APIRouter(prefix="/semester", tags=["Semester Examinations"])


@router.get("/subjects", response_model=List[SemesterSubjectResponse])
def get_semester_subjects(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    return db.query(SemesterSubject).filter(
        SemesterSubject.user_id == current_user.id
    ).all()


@router.put("/subjects/{subject_id}", response_model=SemesterSubjectResponse)
def update_semester_subject(
    subject_id: int,
    subject_in: SemesterSubjectUpdate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    subject = db.query(SemesterSubject).filter(
        SemesterSubject.id == subject_id,
        SemesterSubject.user_id == current_user.id
    ).first()
    if not subject:
        raise HTTPException(status_code=404, detail="Semester subject not found")
        
    update_data = subject_in.model_dump(exclude_unset=True)
    for field, val in update_data.items():
        setattr(subject, field, val)
        
    db.commit()
    db.refresh(subject)
    return subject


@router.patch("/units/{unit_id}", response_model=SemesterUnitResponse)
def update_semester_unit(
    unit_id: int,
    unit_in: SemesterUnitUpdate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    unit = db.query(SemesterUnit).join(SemesterSubject).filter(
        SemesterUnit.id == unit_id,
        SemesterSubject.user_id == current_user.id
    ).first()
    if not unit:
        raise HTTPException(status_code=404, detail="Semester unit not found")
        
    update_data = unit_in.model_dump(exclude_unset=True)
    for field, val in update_data.items():
        setattr(unit, field, val)
        
    db.commit()
    
    # Recalculate subject completion percentage
    subject = unit.subject
    total_units = len(subject.units)
    completed_units = sum(1 for u in subject.units if u.is_completed)
    subject.syllabus_completion_pct = round((completed_units / total_units) * 100, 1) if total_units > 0 else 0.0
    
    db.commit()
    db.refresh(unit)
    return unit


@router.get("/countdown")
def get_exam_countdown(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    subjects = db.query(SemesterSubject).filter(
        SemesterSubject.user_id == current_user.id
    ).all()
    
    today = date.today()
    countdown_list = []
    
    for s in subjects:
        days_left = (s.exam_date - today).days if s.exam_date else None
        countdown_list.append({
            "subject_id": s.id,
            "code": s.code,
            "name": s.name,
            "priority": s.priority,
            "exam_date": str(s.exam_date) if s.exam_date else "Not Scheduled",
            "days_remaining": days_left,
            "syllabus_completion_pct": s.syllabus_completion_pct
        })
        
    countdown_list.sort(key=lambda x: (x["days_remaining"] is None, x["days_remaining"]))
    return countdown_list
