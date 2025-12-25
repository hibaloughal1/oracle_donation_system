import oracledb
from fastapi import APIRouter, Depends, HTTPException
from app.api.deps import get_db, get_current_user

router = APIRouter()

@router.post("/")
def make_donation(
    besoin_id: int,
    amount: float,
    current_user = Depends(get_current_user),
    db = Depends(get_db)
):
    cursor = db.cursor()
    try:
        id_don = cursor.var(oracledb.NUMBER)
        status = cursor.var(oracledb.STRING)
        message = cursor.var(oracledb.STRING)

        cursor.callproc(
            "SECURITY_PKG.SP_MAKE_DONATION",
            [
                current_user["user_id"],
                besoin_id,
                amount,
                None,  # p_preuve_don (NULL pour l'instant)
                'PENDING',  # p_statut_don
                id_don,
                status,
                message
            ]
        )
        db.commit()

        if status.getvalue() != "OK":
            raise HTTPException(status_code=400, detail=message.getvalue() or "Erreur lors du don")

        return {"message": "Don enregistré avec succès ! Merci ❤️", "don_id": int(id_don.getvalue())}
    except oracledb.Error as e:
        db.rollback()
        error, = e.args
        raise HTTPException(status_code=400, detail=f"Erreur Oracle : {error.message}")
    finally:
        cursor.close()