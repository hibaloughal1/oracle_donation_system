from fastapi import APIRouter, Depends
from app.api.deps import get_db
from app.core.database import get_connection

router = APIRouter()

@router.get("/")
def get_organisations(db = Depends(get_db)):
    cursor = db.cursor()
    try:
        cursor.execute("SELECT id, name, description FROM organisation WHERE status = 'ACTIVE'")
        columns = [col[0].lower() for col in cursor.description]
        return [dict(zip(columns, row)) for row in cursor.fetchall()]
    finally:
        cursor.close()
