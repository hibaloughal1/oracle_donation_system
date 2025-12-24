from fastapi import APIRouter, Depends
from app.api.deps import get_db

router = APIRouter()

@router.get("/action/{action_id}")
def get_besoins(action_id: int, db = Depends(get_db)):
    cursor = db.cursor()
    try:
        cursor.execute("""
            SELECT id, item_type_id, quantity_requested, quantity_received, description
            FROM besoin
            WHERE action_id = :1
        """, [action_id])
        columns = [col[0].lower() for col in cursor.description]
        return [dict(zip(columns, row)) for row in cursor.fetchall()]
    finally:
        cursor.close()
