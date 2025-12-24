from pydantic_settings import BaseSettings
from functools import lru_cache

class Settings(BaseSettings):
    APP_NAME: str = "OracleDonationBackend"
    ENV: str = "development"
    DB_USERNAME: str
    DB_PASSWORD: str
    DB_DSN: str
    SECRET_KEY: str
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 30

    model_config = {
        "env_file": ".env",
        "env_file_encoding": "utf-8",
        "case_sensitive": False,  # Optionnel, mais recommandé
        "extra": "forbid"
    }

@lru_cache
def get_settings() -> Settings:
    return Settings()

settings = get_settings()