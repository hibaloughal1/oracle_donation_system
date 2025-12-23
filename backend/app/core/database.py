import cx_Oracle
from app.core.config import settings

def get_connection():
    return cx_Oracle.connect(
        user=settings.DB_USER,
        password=settings.DB_PASSWORD,
        dsn=settings.DB_DSN,
        encoding="UTF-8"
    )
