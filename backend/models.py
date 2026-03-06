from sqlalchemy import Column, Integer, String, ForeignKey, Text, JSON, DateTime
from sqlalchemy.orm import relationship
from datetime import datetime
from pydantic import BaseModel
from typing import List, Optional, Dict
from db import Base

# --- SQLAlchemy Models ---

class User(Base):
    __tablename__ = "users"
    id = Column(Integer, primary_key=True, index=True)
    username = Column(String, unique=True, index=True) # Changed from email
    password_hash = Column(String)
    passcode_hash = Column(String) # New 4-digit safe code hash
    
    entries = relationship("JournalEntry", back_populates="user")
    people = relationship("Person", back_populates="user")
    core_profile = relationship("UserCoreProfile", back_populates="user", uselist=False)
    weekly_goals = relationship("WeeklyGoal", back_populates="user")

class JournalEntry(Base):
    __tablename__ = "journal_entries"
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"))
    content = Column(Text)
    created_at = Column(DateTime, default=datetime.utcnow)
    
    user = relationship("User", back_populates="entries")
    analysis = relationship("EntryAnalysis", back_populates="entry", uselist=False)
    entry_people = relationship("EntryPerson", back_populates="entry")

class EntryAnalysis(Base):
    __tablename__ = "entry_analyses"
    id = Column(Integer, primary_key=True, index=True)
    entry_id = Column(Integer, ForeignKey("journal_entries.id"))
    emotions = Column(JSON) # List of strings
    themes = Column(JSON)   # List of strings
    reflection = Column(Text)
    
    entry = relationship("JournalEntry", back_populates="analysis")

class Person(Base):
    __tablename__ = "people"
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"))
    name = Column(String)
    
    user = relationship("User", back_populates="people")
    entry_associations = relationship("EntryPerson", back_populates="person")

class EntryPerson(Base):
    __tablename__ = "entry_people"
    id = Column(Integer, primary_key=True, index=True)
    entry_id = Column(Integer, ForeignKey("journal_entries.id"))
    person_id = Column(Integer, ForeignKey("people.id"))
    
    entry = relationship("JournalEntry", back_populates="entry_people")
    person = relationship("Person", back_populates="entry_associations")

class UserCoreProfile(Base):
    __tablename__ = "user_core_profiles"
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"))
    patterns = Column(JSON)
    
    user = relationship("User", back_populates="core_profile")

class WeeklyGoal(Base):
    __tablename__ = "weekly_goals"
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"))
    week_start_date = Column(String) 
    title = Column(String)
    insight = Column(Text) 
    advice = Column(Text)
    created_at = Column(DateTime, default=datetime.utcnow)

    user = relationship("User", back_populates="weekly_goals")

# --- Pydantic Schemas ---

class UserCreate(BaseModel):
    username: str
    password: str
    passcode: str # 4 digits

class UserLogin(BaseModel):
    username: str
    password: str

class PasscodeVerify(BaseModel):
    passcode: str

class UserUpdate(BaseModel):
    username: Optional[str] = None
    password: Optional[str] = None
    passcode: Optional[str] = None

class Token(BaseModel):
    access_token: str
    token_type: str

class JournalEntryCreate(BaseModel):
    content: str

class EntryAnalysisSchema(BaseModel):
    emotions: List[str]
    themes: List[str]
    reflection: str

class JournalEntryResponse(BaseModel):
    id: int
    content: str
    created_at: datetime
    analysis: Optional[EntryAnalysisSchema] = None
    
    class Config:
        from_attributes = True

class PersonResponse(BaseModel):
    id: int
    name: str
    
    class Config:
        from_attributes = True

class SentimentPoint(BaseModel):
    date: str
    score: int 

class PersonAnalyticsResponse(BaseModel):
    person_id: int
    name: str
    entry_count: int
    net_emotional_effect: str 
    common_emotions: List[str]
    relationship_tone: str
    consistency_score: int 
    history: List[SentimentPoint] 

class WeeklyCoachResponse(BaseModel):
    week_start: str
    title: str
    insight: str
    advice: str
    is_new: bool
    has_data: bool