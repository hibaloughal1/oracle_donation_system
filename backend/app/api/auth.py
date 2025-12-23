from fastapi import APIRouter, HTTPException
from app.core.database import get_connection
from app.core.security import create_access_token
from app.schemas.auth import LoginRequest

router = APIRouter(prefix="/auth", tags=["Auth"])

@router.post("/login")
def login(data: LoginRequest):
    conn = get_connection()
    cur = conn.cursor()

    p_id_user = cur.var(int)
    p_role = cur.var(str)
    p_status = cur.var(str)
    p_message = cur.var(str)

    cur.callproc("SECURITY_PKG.SP_LOGIN", [
        data.email,
        data.password,
        p_id_user,
        p_role,
        p_status,
        p_message
    ])

    if p_status.getvalue() != "OK":
        raise HTTPException(401, p_message.getvalue())

    token = create_access_token({
        "user_id": p_id_user.getvalue(),
        "role": p_role.getvalue()
    })

    return {
        "token": token,
        "role": p_role.getvalue()
    }
