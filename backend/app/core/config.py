<<<<<<< HEAD
from pydantic import BaseSettings

class Settings(BaseSettings):
    DB_USER: str
    DB_PASSWORD: str
    DB_DSN: str
    SECRET_KEY: str

    class Config:
        env_file = ".env"

settings = Settings()
=======
from pydantic_settings import BaseSettings
from functools import lru_cache

class Settings(BaseSettings):
    APP_NAME: str = "OracleDonationBackend"
    ENV: str = "development"
    DATABASE_URL: str

    class Config:
        env_file = ".env"
        env_file_encoding = "utf-8"

@lru_cache
def get_settings():
    return Settings()

settings = get_settings()

>>>>>>> b5bcd160c0527b1a1e1ef0ae33d62e90e4cf7dba
