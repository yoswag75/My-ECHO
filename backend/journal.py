from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List
from db import get_db
from models import User, JournalEntry, EntryAnalysis, JournalEntryCreate, JournalEntryResponse, Person, EntryPerson, WeeklyGoal
from auth import get_current_user
import ai
from datetime import date, timedelta

router = APIRouter()

@router.post("/journal", response_model=JournalEntryResponse)
def create_entry(entry: JournalEntryCreate, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    # 1. Create Entry
    db_entry = JournalEntry(user_id=current_user.id, content=entry.content)
    db.add(db_entry)
    db.commit()
    db.refresh(db_entry)
    
    # 2. AI Analysis
    analysis_result = ai.analyze_entry(entry.content)
    
    # 3. Save Analysis
    db_analysis = EntryAnalysis(
        entry_id=db_entry.id,
        emotions=analysis_result["emotions"],
        themes=analysis_result["themes"],
        reflection=analysis_result["reflection"]
    )
    db.add(db_analysis)
    
    # 4. Handle People (Simple extraction and linking)
    # Normalize names to Title Case to treat "yug" and "Yug" as the same person
    raw_people = analysis_result.get("people", [])
    unique_names = {name.strip().title() for name in raw_people}

    for name in unique_names:
        person = db.query(Person).filter(Person.user_id == current_user.id, Person.name == name).first()
        if not person:
            person = Person(user_id=current_user.id, name=name)
            db.add(person)
            db.commit()
            db.refresh(person)
        
        link = EntryPerson(entry_id=db_entry.id, person_id=person.id)
        db.add(link)
    
    # 5. Reset Weekly Goal for the current week
    # Forces Coach to regenerate insights with this new entry included
    today = date.today()
    start_of_week = today - timedelta(days=today.weekday())
    week_str = start_of_week.isoformat()
    
    db.query(WeeklyGoal).filter(
        WeeklyGoal.user_id == current_user.id,
        WeeklyGoal.week_start_date == week_str
    ).delete()

    db.commit()
    db.refresh(db_entry) 
    return db_entry

@router.get("/journal", response_model=List[JournalEntryResponse])
def get_entries(db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    return db.query(JournalEntry).filter(JournalEntry.user_id == current_user.id).order_by(JournalEntry.created_at.desc()).all()

@router.delete("/journal/{entry_id}")
def delete_entry(entry_id: int, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    # 1. Verify existence and ownership
    entry = db.query(JournalEntry).filter(JournalEntry.id == entry_id, JournalEntry.user_id == current_user.id).first()
    if not entry:
        raise HTTPException(status_code=404, detail="Entry not found")
    
    # 2. Identify people associated with this entry
    associated_people_ids = [ep.person_id for ep in entry.entry_people]

    # 3. Delete related analysis and associations
    db.query(EntryAnalysis).filter(EntryAnalysis.entry_id == entry_id).delete()
    db.query(EntryPerson).filter(EntryPerson.entry_id == entry_id).delete()
    
    # 4. Check and delete orphaned people
    for person_id in associated_people_ids:
        remaining_associations = db.query(EntryPerson).filter(EntryPerson.person_id == person_id).count()
        if remaining_associations == 0:
            db.query(Person).filter(Person.id == person_id).delete()

    # 5. Delete the entry itself
    db.delete(entry)
    
    # 6. Reset Weekly Goal for the current week
    today = date.today()
    start_of_week = today - timedelta(days=today.weekday())
    week_str = start_of_week.isoformat()
    
    db.query(WeeklyGoal).filter(
        WeeklyGoal.user_id == current_user.id,
        WeeklyGoal.week_start_date == week_str
    ).delete()

    db.commit()
    
    return {"message": "Entry deleted successfully"}