from fastapi import APIRouter, Depends
from app.api.deps import get_db

router = APIRouter()

@router.get("/")
def get_actions(db = Depends(get_db)):
    cursor = db.cursor()
    try:
        cursor.execute("""
            SELECT id, name, description, start_date, end_date
            FROM action_social
            WHERE status = 'ACTIVE'
            ORDER BY start_date DESC
        """)
        columns = [col[0].lower() for col in cursor.description]
        return [dict(zip(columns, row)) for row in cursor.fetchall()]
    finally:
        cursor.close()
