from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List
from db import get_db
from models import User, Person, PersonResponse, PersonAnalyticsResponse, EntryPerson, JournalEntry, SentimentPoint
from auth import get_current_user
from collections import Counter
import math

router = APIRouter()

@router.get("/people", response_model=List[PersonResponse])
def get_people(db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    return db.query(Person).filter(Person.user_id == current_user.id).all()

@router.get("/people/{id}", response_model=PersonResponse)
def get_person(id: int, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    person = db.query(Person).filter(Person.id == id, Person.user_id == current_user.id).first()
    if not person:
        raise HTTPException(status_code=404, detail="Person not found")
    return person

@router.get("/people/{id}/analytics", response_model=PersonAnalyticsResponse)
def get_person_analytics(id: int, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    person = db.query(Person).filter(Person.id == id, Person.user_id == current_user.id).first()
    if not person:
        raise HTTPException(status_code=404, detail="Person not found")
        
    # Get all entries associated with this person
    associations = db.query(EntryPerson).filter(EntryPerson.person_id == id).all()
    entry_ids = [a.entry_id for a in associations]
    
    entries = db.query(JournalEntry).filter(JournalEntry.id.in_(entry_ids)).order_by(JournalEntry.created_at).all()
    
    emotions = []
    history = []
    
    # Enhanced scoring for graph (Case-insensitive & broader lexicon)
    # Positive set
    pos_words = {
        "happy", "joy", "excited", "grateful", "love", "calm", "proud", 
        "hopeful", "inspired", "content", "peaceful", "confident", "relief",
        "supported", "appreciated", "energetic", "safe", "valued", "optimistic",
        "amused", "delighted", "cheerful", "blissful", "enthusiastic", "loving",
        "relaxed", "comfortable", "satisfied", "thankful", "secure", "brave"
    }
    # Negative set
    neg_words = {
        "sadness", "anger", "anxiety", "fear", "frustrated", "lonely", 
        "stressed", "overwhelmed", "guilty", "ashamed", "tired", "hurt",
        "annoyed", "disappointed", "jealous", "insecure", "resentful", "bored",
        "confused", "worried", "nervous", "irritated", "angry", "sad", "depressed",
        "exhausted", "uneasy", "tense", "heartbroken", "gloomy"
    }

    for e in entries:
        if e.analysis and e.analysis.emotions:
            # Normalize emotions to lowercase for consistent matching
            entry_emotions_raw = e.analysis.emotions
            entry_emotions = [em.lower().strip() for em in entry_emotions_raw]
            
            # Store original string for UI chips (Title Case mostly) but use lowercase for analysis
            emotions.extend([em.title() for em in entry_emotions])
            
            # Calculate score for this entry
            score = 0
            for em in entry_emotions:
                if em in pos_words: 
                    score += 1
                elif em in neg_words: 
                    score -= 1
                else:
                    # Fuzzy match fallback (e.g. "happiness" -> "happy")
                    if any(p in em for p in pos_words): score += 1
                    if any(n in em for n in neg_words): score -= 1
            
            # Normalize score to a range of -5 to 5 for the graph
            # If score is > 0 it's positive, < 0 negative
            # We cap it at +/- 5 to keep graph scaled
            if score > 0: score = min(5, score + 1) # Boost slight positive to visible range
            if score < 0: score = max(-5, score - 1) # Boost slight negative
            
            history.append(SentimentPoint(date=e.created_at.strftime("%Y-%m-%d"), score=score))
            
    emotion_counts = Counter(emotions)
    common_emotions = [e[0] for e in emotion_counts.most_common(3)]
    
    # Recalculate counts based on the matched sets for Net Effect
    # We loop through the accumulated 'emotions' list (which is title cased now)
    pos_count = 0
    neg_count = 0
    
    for em in emotions:
        em_lower = em.lower()
        if em_lower in pos_words or any(p in em_lower for p in pos_words):
            pos_count += 1
        elif em_lower in neg_words or any(n in em_lower for n in neg_words):
            neg_count += 1
    
    net_effect = "Mixed"
    if len(entries) == 0:
        net_effect = "Neutral"
    elif pos_count > neg_count * 1.5: 
        net_effect = "Positive"
    elif neg_count > pos_count * 1.5: 
        net_effect = "Draining"
    elif pos_count > neg_count:
        net_effect = "Leaning Positive"
    elif neg_count > pos_count:
        net_effect = "Leaning Negative"
    
    tone = "Balanced"
    # Tone logic based on specific triggers
    normalized_common = [c.lower() for c in common_emotions]
    
    if any(x in normalized_common for x in ["joy", "happy", "excited", "delighted", "cheerful"]): tone = "Vibrant"
    elif any(x in normalized_common for x in ["love", "loving", "supported", "appreciated"]): tone = "Deep"
    elif any(x in normalized_common for x in ["calm", "peaceful", "safe", "relaxed", "content"]): tone = "Comfortable"
    elif any(x in normalized_common for x in ["anger", "frustrated", "annoyed", "irritated", "resentful"]): tone = "Conflict"
    elif any(x in normalized_common for x in ["anxiety", "fear", "stressed", "worried", "nervous"]): tone = "Tense"
    elif any(x in normalized_common for x in ["sadness", "lonely", "hurt", "depressed", "heartbroken"]): tone = "Melancholy"
    elif any(x in normalized_common for x in ["tired", "exhausted", "overwhelmed"]): tone = "Draining"
    
    # Consistency (Statistical Variance Approach)
    if len(history) < 2:
        consistency = 100
    else:
        # Calculate Variance of scores
        scores = [h.score for h in history]
        mean_score = sum(scores) / len(scores)
        variance = sum((x - mean_score) ** 2 for x in scores) / len(scores)
        std_dev = math.sqrt(variance)
        # Max meaningful std_dev is roughly 5 (e.g., oscillating -5 to 5)
        # Map 0 -> 100%, 5 -> 0%
        consistency = max(0, min(100, int(100 - (std_dev * 20))))
    
    return PersonAnalyticsResponse(
        person_id=person.id,
        name=person.name,
        entry_count=len(entries),
        net_emotional_effect=net_effect,
        common_emotions=common_emotions,
        relationship_tone=tone,
        consistency_score=consistency,
        history=history
    )