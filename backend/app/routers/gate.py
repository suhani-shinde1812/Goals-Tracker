from datetime import date, timedelta
from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from sqlalchemy import func

from ..database import get_db
from ..models import User, GateSubject, GateTopic, StudySession, MockTest
from ..schemas import (
    GateSubjectResponse, GateTopicResponse, GateTopicUpdate,
    StudySessionCreate, StudySessionResponse,
    MockTestCreate, MockTestResponse
)
from ..auth import get_current_user
from ..seed_data import seed_gate_and_workouts

router = APIRouter(prefix="/gate", tags=["GATE CS Preparation"])


@router.get("/subjects", response_model=List[GateSubjectResponse])
def get_gate_syllabus(db: Session = Depends(get_db)):
    # Ensure GATE syllabus is seeded
    count = db.query(GateSubject).count()
    if count == 0:
        seed_gate_and_workouts(db)
        
    return db.query(GateSubject).order_by(GateSubject.order_index).all()


@router.patch("/topics/{topic_id}", response_model=GateTopicResponse)
def update_gate_topic(
    topic_id: int,
    topic_in: GateTopicUpdate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    topic = db.query(GateTopic).filter(GateTopic.id == topic_id).first()
    if not topic:
        raise HTTPException(status_code=404, detail="Topic not found")
        
    update_data = topic_in.model_dump(exclude_unset=True)
    for field, val in update_data.items():
        setattr(topic, field, val)
        
    db.commit()
    db.refresh(topic)
    return topic


@router.get("/progress")
def get_gate_progress(db: Session = Depends(get_db)):
    total_topics = db.query(GateTopic).count()
    completed = db.query(GateTopic).filter(GateTopic.status == "Completed").count()
    in_progress = db.query(GateTopic).filter(GateTopic.status == "In Progress").count()
    needs_revision = db.query(GateTopic).filter(GateTopic.status == "Needs Revision").count()
    not_started = total_topics - (completed + in_progress + needs_revision)
    
    pct = round((completed / total_topics) * 100, 1) if total_topics > 0 else 0.0
    
    return {
        "total_topics": total_topics,
        "completed": completed,
        "in_progress": in_progress,
        "needs_revision": needs_revision,
        "not_started": not_started,
        "completion_percentage": pct
    }


@router.post("/sessions", response_model=StudySessionResponse)
def log_study_session(
    session_in: StudySessionCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    session = StudySession(
        user_id=current_user.id,
        category=session_in.category,
        subject_name=session_in.subject_name,
        date=session_in.date,
        duration_minutes=session_in.duration_minutes,
        topics_covered=session_in.topics_covered,
        questions_solved=session_in.questions_solved,
        notes=session_in.notes
    )
    db.add(session)
    db.commit()
    db.refresh(session)
    return session


@router.get("/sessions", response_model=List[StudySessionResponse])
def get_study_sessions(
    limit: int = 30,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    return db.query(StudySession).filter(
        StudySession.user_id == current_user.id
    ).order_by(StudySession.date.desc()).limit(limit).all()


@router.get("/mocks", response_model=List[MockTestResponse])
def get_mock_tests(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    return db.query(MockTest).filter(
        MockTest.user_id == current_user.id
    ).order_by(MockTest.date.desc()).all()


@router.post("/mocks", response_model=MockTestResponse)
def log_mock_test(
    mock_in: MockTestCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    accuracy = round((mock_in.score / mock_in.total_marks) * 100, 1) if mock_in.total_marks > 0 else 0.0
    mock = MockTest(
        user_id=current_user.id,
        test_type=mock_in.test_type,
        title=mock_in.title,
        date=mock_in.date,
        score=mock_in.score,
        total_marks=mock_in.total_marks,
        time_taken_mins=mock_in.time_taken_mins,
        accuracy_pct=accuracy,
        weak_topics_identified=mock_in.weak_topics_identified,
        notes=mock_in.notes
    )
    db.add(mock)
    db.commit()
    db.refresh(mock)
    return mock
