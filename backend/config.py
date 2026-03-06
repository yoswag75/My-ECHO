import os

class Settings:
    PROJECT_NAME: str = "AI Diary"
    PROJECT_VERSION: str = "1.0.0"
    
    # Database: Prioritize Env Var (Cloud), fallback to local SQLite
    DATABASE_URL: str = os.getenv("DATABASE_URL", "sqlite:///./diary.db")
    
    # Security
    SECRET_KEY: str = os.getenv("SECRET_KEY", "supersecretkey1234567890")
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60 * 24 * 30  # 30 days

    # AI Config
    USE_REAL_AI: bool = True 
    GEMINI_API_KEY: str = os.getenv("GEMINI_API_KEY", "")

settings = Settings()