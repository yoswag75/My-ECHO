from fastapi import FastAPI, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordRequestForm
from sqlalchemy.orm import Session
from db import engine, Base, get_db
from models import User, UserCreate, UserLogin, Token, PasscodeVerify, UserUpdate
import auth
import journal, people, coach
from config import settings

Base.metadata.create_all(bind=engine)

app = FastAPI(title=settings.PROJECT_NAME)

@app.post("/register", response_model=Token)
def register(user: UserCreate, db: Session = Depends(get_db)):
    db_user = db.query(User).filter(User.username == user.username).first()
    if db_user:
        raise HTTPException(status_code=400, detail="Username already taken")
    
    hashed_pwd = auth.get_password_hash(user.password)
    hashed_passcode = auth.get_passcode_hash(user.passcode)
    
    new_user = User(username=user.username, password_hash=hashed_pwd, passcode_hash=hashed_passcode)
    db.add(new_user)
    db.commit()
    db.refresh(new_user)
    
    access_token = auth.create_access_token(data={"sub": new_user.username})
    return {"access_token": access_token, "token_type": "bearer"}

@app.post("/login", response_model=Token)
def login(user_data: UserLogin, db: Session = Depends(get_db)):
    # Note: Accepting JSON body for login now, not OAuthForm
    user = db.query(User).filter(User.username == user_data.username).first()
    if not user or not auth.verify_password(user_data.password, user.password_hash):
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Incorrect username or password")
    
    access_token = auth.create_access_token(data={"sub": user.username})
    return {"access_token": access_token, "token_type": "bearer"}

@app.post("/verify-passcode")
def verify_passcode_endpoint(data: PasscodeVerify, current_user: User = Depends(auth.get_current_user)):
    if not auth.verify_passcode(data.passcode, current_user.passcode_hash):
        raise HTTPException(status_code=401, detail="Invalid Passcode")
    return {"status": "ok"}

@app.put("/profile")
def update_profile(data: UserUpdate, db: Session = Depends(get_db), current_user: User = Depends(auth.get_current_user)):
    if data.username:
        # Check uniqueness if changing
        if data.username != current_user.username:
            exists = db.query(User).filter(User.username == data.username).first()
            if exists:
                raise HTTPException(status_code=400, detail="Username already taken")
            current_user.username = data.username
            
    if data.password:
        current_user.password_hash = auth.get_password_hash(data.password)
        
    if data.passcode:
        current_user.passcode_hash = auth.get_passcode_hash(data.passcode)
        
    db.commit()
    
    # If username changed, return new token
    new_token = None
    if data.username:
        new_token = auth.create_access_token(data={"sub": current_user.username})
        
    return {"message": "Profile updated", "new_token": new_token}

@app.get("/me")
def get_me(current_user: User = Depends(auth.get_current_user)):
    return {"username": current_user.username}

app.include_router(journal.router, tags=["Journal"])
app.include_router(people.router, tags=["People"])
app.include_router(coach.router, tags=["Coach"])

@app.get("/")
def root():
    return {"message": "AI Diary API Running"}