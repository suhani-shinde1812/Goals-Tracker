from datetime import datetime
from typing import List, Optional
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from pydantic import BaseModel

from ..database import get_db
from ..models import User, NotificationPreference, NotificationHistory
from ..auth import get_current_user

router = APIRouter(prefix="/notifications", tags=["Notifications & Reminders"])


class NotificationPrefUpdate(BaseModel):
    category: str
    enabled: bool
    reminder_time: Optional[str] = None


class NotificationSendRequest(BaseModel):
    title: str
    body: str
    category: str = "General"


@router.get("/preferences")
def get_notification_preferences(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    prefs = db.query(NotificationPreference).filter(
        NotificationPreference.user_id == current_user.id
    ).all()
    
    if not prefs:
        defaults = [
            ("Morning Routine", True, "06:30"),
            ("Home Workout", True, "06:40"),
            ("Hydration Check-ins", True, "09:00"),
            ("GATE Study Block", True, "08:00"),
            ("Semester Study Block", True, "10:20"),
            ("ExcelR Placement Training", True, "16:45"),
            ("Digestive & Evening Routine", True, "21:00")
        ]
        for cat, en, t in defaults:
            p = NotificationPreference(
                user_id=current_user.id,
                category=cat,
                enabled=en,
                reminder_time=t
            )
            db.add(p)
        db.commit()
        prefs = db.query(NotificationPreference).filter(
            NotificationPreference.user_id == current_user.id
        ).all()
        
    return prefs


@router.put("/preferences")
def update_notification_preference(
    pref_in: NotificationPrefUpdate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    pref = db.query(NotificationPreference).filter(
        NotificationPreference.user_id == current_user.id,
        NotificationPreference.category == pref_in.category
    ).first()
    
    if not pref:
        pref = NotificationPreference(
            user_id=current_user.id,
            category=pref_in.category,
            enabled=pref_in.enabled,
            reminder_time=pref_in.reminder_time
        )
        db.add(pref)
    else:
        pref.enabled = pref_in.enabled
        if pref_in.reminder_time:
            pref.reminder_time = pref_in.reminder_time
            
    db.commit()
    db.refresh(pref)
    return pref


@router.get("/history")
def get_notification_history(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    return db.query(NotificationHistory).filter(
        NotificationHistory.user_id == current_user.id
    ).order_by(NotificationHistory.sent_at.desc()).limit(20).all()


@router.post("/test-send")
def send_test_notification(
    req: NotificationSendRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    notif = NotificationHistory(
        user_id=current_user.id,
        title=req.title,
        body=req.body,
        category=req.category,
        sent_at=datetime.utcnow()
    )
    db.add(notif)
    db.commit()
    db.refresh(notif)
    return {
        "status": "success",
        "notification_id": notif.id,
        "message": f"Simulated {req.category} notification sent."
    }
