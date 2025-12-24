from fastapi import APIRouter, Depends, HTTPException
from app.api.deps import get_db, get_current_user

router = APIRouter()

@router.post("/")
def make_donation(besoin_id: int, amount: float, current_user = Depends(get_current_user), db = Depends(get_db)):
    cursor = db.cursor()
    try:
        cursor.callproc("SP_MAKE_DONATION", [current_user["user_id"], besoin_id, amount])
        db.commit()
        return {"message": "Don enregistré avec succès ! Merci ❤️"}
    except oracledb.Error as e:
        db.rollback()
        raise HTTPException(status_code=400, detail=str(e))
    finally:
        cursor.close()