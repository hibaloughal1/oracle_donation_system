from fastapi import APIRouter, Depends, HTTPException
from app.schemas.action import ActionCreate
from app.api.deps import get_current_user
from app.core.database import get_connection
import cx_Oracle

router = APIRouter(
    prefix="/actions",
    tags=["Actions"]
)

# ============================================================
# CREATE ACTION (Campaign)
# ============================================================
@router.post("/", summary="Créer une action sociale")
def create_action(
    data: ActionCreate,
    user=Depends(get_current_user)
):
    """
    Crée une action sociale pour une organisation.
    Règles gérées par Oracle :
    - organisation ACTIVE
    - utilisateur propriétaire ou ADMIN
    - dates valides
    """

    conn = get_connection()
    cur = conn.cursor()

    p_id_action = cur.var(cx_Oracle.NUMBER)
    p_status    = cur.var(cx_Oracle.STRING)
    p_message   = cur.var(cx_Oracle.STRING)

    try:
        cur.callproc(
            "SECURITY_PKG.SP_CREATE_ACTION",
            [
                user["user_id"],          # p_user_id
                data.org_id,               # p_org_id
                data.titre,                # p_titre_action
                data.description,          # p_desc_action
                data.affiche,              # p_affiche_action
                data.date_debut,           # p_date_debut_action
                data.date_fin,             # p_date_fin_action
                data.montant_objectif,     # p_montant_objectif
                p_id_action,               # OUT p_id_action
                p_status,                  # OUT p_status
                p_message                  # OUT p_message
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
            "id_action": int(p_id_action.getvalue())
        }

    except cx_Oracle.DatabaseError as e:
        raise HTTPException(
            status_code=500,
            detail=str(e)
        )

    finally:
        cur.close()
        conn.close()


# ============================================================
# UPDATE ACTION STATUS
# ============================================================
@router.put("/{action_id}/status", summary="Changer le statut d'une action")
def update_action_status(
    action_id: int,
    new_status: str,
    user=Depends(get_current_user)
):
    """
    Met à jour le statut d'une action :
    DRAFT -> ACTIVE
    ACTIVE -> CLOSED | COMPLETED
    """

    conn = get_connection()
    cur = conn.cursor()

    p_status  = cur.var(cx_Oracle.STRING)
    p_message = cur.var(cx_Oracle.STRING)

    try:
        cur.callproc(
            "SECURITY_PKG.SP_UPDATE_ACTION_STATUS",
            [
                user["user_id"],    # p_user_id
                action_id,          # p_action_id
                new_status,         # p_new_status
                p_status,           # OUT p_status
                p_message           # OUT p_message
            ]
        )

        if p_status.getvalue() != "OK":
            raise HTTPException(
                status_code=400,
                detail=p_message.getvalue()
            )

        return {
            "status": "success",
            "message": p_message.getvalue()
        }

    except cx_Oracle.DatabaseError as e:
        raise HTTPException(
            status_code=500,
            detail=str(e)
        )

    finally:
        cur.close()
        conn.close()
