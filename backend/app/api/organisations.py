from fastapi import APIRouter, Depends, HTTPException
from app.schemas.organisation import OrganisationCreate
from app.core.database import get_connection
from app.api.deps import get_current_user

router = APIRouter(prefix="/organisations", tags=["Organisations"])

@router.post("/")
def create_organisation(data: OrganisationCreate, user=Depends(get_current_user)):
    conn = get_connection()
    cur = conn.cursor()

    p_id_org = cur.var(int)
    p_status = cur.var(str)
    p_message = cur.var(str)

    cur.callproc("SECURITY_PKG.SP_CREATE_ORGANISATION", [
        user["user_id"],
        data.nom,
        data.description,
        data.tel,
        data.patente,
        data.lieu,
        p_id_org,
        p_status,
        p_message
    ])

    if p_status.getvalue() != "OK":
        raise HTTPException(400, p_message.getvalue())

    return {"id_org": p_id_org.getvalue()}
