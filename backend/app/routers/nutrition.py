from datetime import date
from typing import List
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from ..database import get_db
from ..models import User, MealEntry
from ..schemas import MealEntryCreate, MealEntryResponse
from ..auth import get_current_user

router = APIRouter(prefix="/nutrition", tags=["Nutrition & Indian Meal Planner"])

INDIAN_MEAL_IDEAS = [
    {
        "category": "Breakfast",
        "title": "Moong Dal Cheela with Mint Chutney & Boiled Egg",
        "description": "High-protein yellow moong batter spiced with ginger and cumin, stuffed with paneer, plus 1 whole boiled egg.",
        "fiber": "High",
        "protein": "18g est.",
        "pcod_friendly_note": "Complex carbs + protein to prevent morning insulin spikes."
    },
    {
        "category": "Breakfast",
        "title": "Vegetable Oats Upma with Peanuts & Boiled Eggs",
        "description": "Rolled oats tempered with mustard seeds, curry leaves, carrots, peas, beans, and 2 eggs.",
        "fiber": "High",
        "protein": "16g est.",
        "pcod_friendly_note": "Beta-glucan soluble fibre helps regulate blood glucose and satiety."
    },
    {
        "category": "Lunch",
        "title": "Multigrain Roti, Dal Tadka, Bhindi Sabzi & Cucumber Salad",
        "description": "2 jowar/wheat rotis, 1 bowl toor or masoor dal, spiced okra, and fresh cucumber salad.",
        "fiber": "Very High",
        "protein": "15g est.",
        "pcod_friendly_note": "Bhindi (okra) provides gentle mucilage fibre that supports healthy digestion."
    },
    {
        "category": "Lunch",
        "title": "Egg Curry or Grilled Chicken with Brown Rice & Stir-fried Beans",
        "description": "Light onion-tomato gravy with 2 boiled eggs or lean chicken breast, brown rice, and french beans.",
        "fiber": "Moderate",
        "protein": "22g est.",
        "pcod_friendly_note": "Protein anchors fullness during afternoon study sessions."
    },
    {
        "category": "Snack",
        "title": "Roasted Makhana (Foxnuts) & Roasted Chana with Green Tea",
        "description": "Crunchy roasted lotus seeds tossed in ghee and pinch of turmeric/black pepper with tender Bengal gram.",
        "fiber": "High",
        "protein": "8g est.",
        "pcod_friendly_note": "Low glycemic index, rich in antioxidants and easy on sensitive stomachs."
    },
    {
        "category": "Dinner",
        "title": "Palak Paneer / Tofu with 1 Phulka & Warm Vegetable Soup",
        "description": "Pureed spinach with paneer/tofu, single whole wheat phulka, and clear vegetable broth.",
        "fiber": "High",
        "protein": "17g est.",
        "pcod_friendly_note": "Light, warm evening meal prevents night-time bloating and acid reflux."
    }
]


@router.get("/ideas")
def get_meal_ideas():
    return {
        "disclaimer": "Nutritional counts are approximate wellness estimates and not clinical medical prescriptions.",
        "meal_ideas": INDIAN_MEAL_IDEAS
    }


@router.get("/meals", response_model=List[MealEntryResponse])
def get_meals_for_date(
    target_date: date = date.today(),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    return db.query(MealEntry).filter(
        MealEntry.user_id == current_user.id,
        MealEntry.date == target_date
    ).all()


@router.post("/meals", response_model=MealEntryResponse)
def log_meal(
    meal_in: MealEntryCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    meal = MealEntry(
        user_id=current_user.id,
        date=meal_in.date,
        meal_type=meal_in.meal_type,
        description=meal_in.description,
        portion_notes=meal_in.portion_notes,
        is_veg=meal_in.is_veg,
        contains_egg=meal_in.contains_egg,
        protein_g_est=meal_in.protein_g_est,
        fiber_g_est=meal_in.fiber_g_est,
        calories_est=meal_in.calories_est
    )
    db.add(meal)
    db.commit()
    db.refresh(meal)
    return meal


@router.delete("/meals/{meal_id}")
def delete_meal(
    meal_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    meal = db.query(MealEntry).filter(
        MealEntry.id == meal_id,
        MealEntry.user_id == current_user.id
    ).first()
    if not meal:
        raise HTTPException(status_code=404, detail="Meal not found")
    db.delete(meal)
    db.commit()
    return {"message": "Meal deleted"}
