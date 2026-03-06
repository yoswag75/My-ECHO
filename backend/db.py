from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, declarative_base
from config import settings
import os

# Check if we are using the default SQLite or a Cloud Postgres URL
database_url = settings.DATABASE_URL

# Fix for Render/Heroku URLs starting with "postgres://" -> needs "postgresql://" for SQLAlchemy
if database_url and database_url.startswith("postgres://"):
    database_url = database_url.replace("postgres://", "postgresql://", 1)

# SQLite specific args
connect_args = {}
if "sqlite" in database_url:
    connect_args = {"check_same_thread": False}

engine = create_engine(
    database_url, 
    connect_args=connect_args
)

SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

Base = declarative_base()

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()