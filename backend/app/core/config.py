from pydantic import BaseSettings

class Settings(BaseSettings):
    DB_USER: str
    DB_PASSWORD: str
    DB_DSN: str
    SECRET_KEY: str

    class Config:
        env_file = ".env"

settings = Settings()
