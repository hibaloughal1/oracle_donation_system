from fastapi import APIRouter, Depends, HTTPException
from app.schemas.besoin import BesoinCreate
from app.api.deps import get_current_user
from app.core.database import get_connection
import cx_Oracle

router = APIRouter(
    prefix="/besoins",
    tags=["Besoins"]
)

# ============================================================
# CREATE NEED (Besoin)
# ============================================================
@router.post("/", summary="Ajouter un besoin à une action")
def create_besoin(
    data: BesoinCreate,
    user=Depends(get_current_user)
):
    """
    Ajoute un besoin à une action sociale.
    Règles métier :
    - action ACTIVE
    - utilisateur propriétaire ou ADMIN
    - quantités et prix valides
    """

    conn = get_connection()
    cur = conn.cursor()

    p_id_besoin = cur.var(cx_Oracle.NUMBER)
    p_status    = cur.var(cx_Oracle.STRING)
    p_message   = cur.var(cx_Oracle.STRING)

    try:
        cur.callproc(
            "SECURITY_PKG.SP_ADD_NEED",
            [
                user["user_id"],         # p_user_id
                data.action_id,          # p_action_id
                data.nom_besoin,         # p_nom_besoin
                data.description,        # p_description
                data.type_besoin,        # p_type_besoin
                data.unite_demande,      # p_unite_demande
                data.prix_unitaire,      # p_prix_unitaire
                p_id_besoin,             # OUT p_id_besoin
                p_status,                # OUT p_status
                p_message                # OUT p_message
            ]
        )

        if p_status.getvalue() != "OK":
            raise HTTPException(
                status_code=400,
                detail=p_message.getvalue()
            )

        return {
            "status": "success",
            "message": p_message.getvalue(),
            "id_besoin": int(p_id_besoin.getvalue())
        }

    except cx_Oracle.DatabaseError as e:
        raise HTTPException(
            status_code=500,
            detail=str(e)
        )

    finally:
        cur.close()
        conn.close()
