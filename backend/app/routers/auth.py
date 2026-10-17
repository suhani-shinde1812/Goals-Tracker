from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordRequestForm
from sqlalchemy.orm import Session
from datetime import date
import io
import csv
import json

from ..database import get_db
from ..models import User, UserPreference
from ..schemas import (
    UserCreate, UserResponse, UserLogin, Token,
    UserPreferenceUpdate, UserPreferenceResponse
)
from ..auth import (
    get_password_hash, verify_password,
    create_access_token, get_current_user
)
from ..seed_data import seed_user_initial_data

router = APIRouter(prefix="/auth", tags=["Authentication & Profile"])


@router.post("/register", response_model=Token)
def register(user_in: UserCreate, db: Session = Depends(get_db)):
    existing = db.query(User).filter(User.email == user_in.email).first()
    if existing:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="A user with this email already exists"
        )
    
    hashed_pwd = get_password_hash(user_in.password)
    user = User(
        email=user_in.email,
        hashed_password=hashed_pwd,
        full_name=user_in.full_name
    )
    db.add(user)
    db.commit()
    db.refresh(user)
    
    # Initialize initial user preferences and seed data
    seed_user_initial_data(db, user, date.today())
    
    access_token = create_access_token(
        data={"sub": user.email, "user_id": user.id}
    )
    return {
        "access_token": access_token,
        "token_type": "bearer",
        "user_id": user.id,
        "full_name": user.full_name,
        "email": user.email
    }


@router.post("/login", response_model=Token)
def login(form_data: OAuth2PasswordRequestForm = Depends(), db: Session = Depends(get_db)):
    user = db.query(User).filter(User.email == form_data.username).first()
    if not user or not verify_password(form_data.password, user.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect email or password",
            headers={"WWW-Authenticate": "Bearer"},
        )
    if not user.is_active:
        raise HTTPException(status_code=400, detail="Inactive user")

    access_token = create_access_token(
        data={"sub": user.email, "user_id": user.id}
    )
    return {
        "access_token": access_token,
        "token_type": "bearer",
        "user_id": user.id,
        "full_name": user.full_name,
        "email": user.email
    }


@router.get("/me", response_model=UserResponse)
def get_current_user_profile(current_user: User = Depends(get_current_user)):
    return current_user


@router.put("/me/preferences", response_model=UserPreferenceResponse)
def update_preferences(
    pref_update: UserPreferenceUpdate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    pref = current_user.preferences
    if not pref:
        pref = UserPreference(user_id=current_user.id)
        db.add(pref)
        
    update_data = pref_update.model_dump(exclude_unset=True)
    for field, val in update_data.items():
        setattr(pref, field, val)
        
    db.commit()
    db.refresh(pref)
    return pref


@router.get("/me/export")
def export_user_data(
    format: str = "json",
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    user_data = {
        "user": {
            "email": current_user.email,
            "full_name": current_user.full_name,
            "created_at": str(current_user.created_at)
        },
        "preferences": {
            "height_cm": current_user.preferences.height_cm if current_user.preferences else 162.6,
            "starting_weight_kg": current_user.preferences.starting_weight_kg if current_user.preferences else 66.0,
            "target_weight_kg": current_user.preferences.target_weight_kg if current_user.preferences else 56.0,
            "timezone": current_user.preferences.timezone if current_user.preferences else "Asia/Kolkata",
            "daily_water_target_ml": current_user.preferences.daily_water_target_ml if current_user.preferences else 2200
        },
        "weight_entries": [
            {"date": str(w.date), "weight_kg": w.weight_kg, "waist_cm": w.waist_cm, "notes": w.notes}
            for w in current_user.weight_entries
        ],
        "hydration_entries": [
            {"date": str(h.date), "amount_ml": h.amount_ml}
            for h in current_user.hydration_entries
        ],
        "menstrual_entries": [
            {"start_date": str(m.start_date), "end_date": str(m.end_date) if m.end_date else None, "flow": m.flow_intensity, "cramps": m.cramps_severity}
            for m in current_user.menstrual_entries
        ],
        "digestive_entries": [
            {"date": str(d.date), "bloating": d.bloating_severity, "gas": d.gas_burping_severity, "constipation": d.constipation_severity, "triggers": d.suspected_triggers}
            for d in current_user.digestive_entries
        ]
    }
    
    if format == "csv":
        # Return CSV of weight and hydration
        output = io.StringIO()
        writer = csv.writer(output)
        writer.writerow(["Type", "Date", "Value", "Notes"])
        for w in current_user.weight_entries:
            writer.writerow(["Weight (kg)", w.date, w.weight_kg, w.notes or ""])
        for h in current_user.hydration_entries:
            writer.writerow(["Hydration (ml)", h.date, h.amount_ml, ""])
        return {"csv_data": output.getvalue()}
        
    return user_data


@router.delete("/me")
def delete_account(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    db.delete(current_user)
    db.commit()
    return {"message": "Account and all associated personal data have been completely deleted"}
