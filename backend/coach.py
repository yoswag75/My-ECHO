from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from db import get_db
from models import User, JournalEntry, WeeklyGoal, WeeklyCoachResponse
from auth import get_current_user
import ai
from datetime import datetime, timedelta, date

router = APIRouter()

@router.get("/coach/weekly", response_model=WeeklyCoachResponse)
def get_weekly_coach(db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    # 1. Determine current week start (Monday)
    today = date.today()
    start_of_week = today - timedelta(days=today.weekday())
    week_str = start_of_week.isoformat()

    # 2. Check if goal exists for this week
    existing_goal = db.query(WeeklyGoal).filter(
        WeeklyGoal.user_id == current_user.id,
        WeeklyGoal.week_start_date == week_str
    ).first()

    if existing_goal:
        # Check if the goal was generated on a previous day. 
        # If so, regenerate to ensure the "last 7 days" window is current.
        if existing_goal.created_at.date() < today:
            db.delete(existing_goal)
            db.commit()
            existing_goal = None # Proceed to regeneration
        else:
            return WeeklyCoachResponse(
                week_start=existing_goal.week_start_date,
                title=existing_goal.title,
                insight=existing_goal.insight,
                advice=existing_goal.advice,
                is_new=False,
                has_data=True
            )

    # 3. Generate new goal if none exists (or was just deleted)
    # Fetch last 7 days of entries
    last_week = datetime.utcnow() - timedelta(days=7)
    entries = db.query(JournalEntry).filter(
        JournalEntry.user_id == current_user.id,
        JournalEntry.created_at >= last_week
    ).all()
    
    # If NO data in last 7 days, return empty state
    if not entries:
        return WeeklyCoachResponse(
            week_start=week_str,
            title="Waiting for Data",
            insight="",
            advice="",
            is_new=True,
            has_data=False
        )
    
    # If data exists, generate insights
    all_emotions = []
    all_themes = []
    
    for e in entries:
        if e.analysis:
            all_emotions.extend(e.analysis.emotions or [])
            all_themes.extend(e.analysis.themes or [])
            
    ai_result = ai.generate_weekly_goal(all_emotions, all_themes)
    
    # 4. Save to DB
    new_goal = WeeklyGoal(
        user_id=current_user.id,
        week_start_date=week_str,
        title=ai_result.get("title", "Weekly Insight"),
        insight=ai_result.get("insight", "You've been tracking your journey."),
        advice=ai_result.get("advice", "Keep going."),
    )
    db.add(new_goal)
    db.commit()
    db.refresh(new_goal)
    
    return WeeklyCoachResponse(
        week_start=new_goal.week_start_date,
        title=new_goal.title,
        insight=new_goal.insight,
        advice=new_goal.advice,
        is_new=True,
        has_data=True
    )