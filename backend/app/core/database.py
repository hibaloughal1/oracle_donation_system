import oracledb
from app.core.config import settings

def get_connection():
    return oracledb.connect(
        user=settings.DB_USERNAME,
        password=settings.DB_PASSWORD,
        dsn=settings.DB_DSN,
        encoding="UTF-8"
    )
