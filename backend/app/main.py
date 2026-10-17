from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager

from .config import settings
from .database import engine, Base, SessionLocal
from .seed_data import seed_gate_and_workouts

# Import routers
from .routers import (
    auth, tasks, habits, health, weight, nutrition,
    hydration, digestive, workouts, gate, semester,
    excelr, analytics, notifications
)


@asynccontextmanager
async def lifespan(app: FastAPI):
    # Initialize database tables
    Base.metadata.create_all(bind=engine)
    # Seed initial general data (GATE topics, workouts)
    db = SessionLocal()
    try:
        seed_gate_and_workouts(db)
    finally:
        db.close()
    yield


app = FastAPI(
    title=settings.APP_NAME,
    version=settings.APP_VERSION,
    description="BloomTrack API: Personal Life, Health, PCOD, Workout, GATE CS, Semester, and Placement Tracker",
    lifespan=lifespan
)

# CORS setup
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origins if settings.cors_origins else ["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Healthcheck
@app.get("/health", tags=["System"])
def health_check():
    return {
        "status": "healthy",
        "app": settings.APP_NAME,
        "version": settings.APP_VERSION,
        "database": "connected"
    }


# Include all v1 routers
api_prefix = "/api/v1"
app.include_router(auth.router, prefix=api_prefix)
app.include_router(tasks.router, prefix=api_prefix)
app.include_router(habits.router, prefix=api_prefix)
app.include_router(health.router, prefix=api_prefix)
app.include_router(weight.router, prefix=api_prefix)
app.include_router(nutrition.router, prefix=api_prefix)
app.include_router(hydration.router, prefix=api_prefix)
app.include_router(digestive.router, prefix=api_prefix)
app.include_router(workouts.router, prefix=api_prefix)
app.include_router(gate.router, prefix=api_prefix)
app.include_router(semester.router, prefix=api_prefix)
app.include_router(excelr.router, prefix=api_prefix)
app.include_router(analytics.router, prefix=api_prefix)
app.include_router(notifications.router, prefix=api_prefix)

# Mount frontend directory for seamless local web experience
import os
from fastapi.staticfiles import StaticFiles

frontend_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", "frontend"))
if os.path.isdir(frontend_dir):
    app.mount("/", StaticFiles(directory=frontend_dir, html=True), name="frontend")

