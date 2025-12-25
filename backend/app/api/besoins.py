import oracledb
from fastapi import APIRouter, Depends ,HTTPException
from app.api.deps import get_db, get_current_user

router = APIRouter()

@router.get("/action/{action_id}")
def get_besoins_by_action(action_id: int, db = Depends(get_db)):
    cursor = db.cursor()
    try:
        cursor.execute("""
            SELECT id_besoin, nom_besoin, description, type_besoin, unite_demande, unite_recue, prix_unitaire
            FROM Besoin
            WHERE id_action = :1
            ORDER BY id_besoin
        """, [action_id])
        columns = [col[0].lower() for col in cursor.description]
        return [dict(zip(columns, row)) for row in cursor.fetchall()]
    except oracledb.Error as e:
        error, = e.args
        raise HTTPException(status_code=400, detail=f"Erreur Oracle : {error.message}")
    finally:
        cursor.close()

# Optionnel : endpoint pour ajouter un besoin (si tu veux)
@router.post("/")
def add_need(
    action_id: int,
    nom_besoin: str,
    description: str,
    type_besoin: str,
    unite_demande: float,
    prix_unitaire: float,
    current_user = Depends(get_current_user),
    db = Depends(get_db)
):
    cursor = db.cursor()
    try:
        id_besoin = cursor.var(oracledb.NUMBER)
        status = cursor.var(oracledb.STRING)
        message = cursor.var(oracledb.STRING)

        cursor.callproc(
            "SECURITY_PKG.SP_ADD_NEED",
            [
                current_user["user_id"],
                action_id,
                nom_besoin,
                description,
                type_besoin,
                unite_demande,
                prix_unitaire,
                id_besoin,
                status,
                message
            ]
        )
        db.commit()

        if status.getvalue() != "OK":
            raise HTTPException(status_code=400, detail=message.getvalue())

        return {"message": "Besoin ajouté avec succès", "besoin_id": int(id_besoin.getvalue())}
    except oracledb.Error as e:
        db.rollback()
        error, = e.args
        raise HTTPException(status_code=400, detail=f"Erreur Oracle : {error.message}")
    finally:
        cursor.close()