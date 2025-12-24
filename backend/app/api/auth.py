from fastapi import APIRouter, Depends, HTTPException
from fastapi.security import OAuth2PasswordRequestForm
from jose import jwt
from app.api.deps import get_db
from app.core.config import settings
import oracledb

router = APIRouter()

@router.post("/register")
def register(email: str, password: str, phone: str, db = Depends(get_db)):
    cursor = db.cursor()
    try:
        user_id = cursor.var(oracledb.NUMBER)
        cursor.callproc("SP_REGISTER_USER", [email, password, phone, user_id])
        db.commit()
        return {"message": "Inscription réussie", "user_id": int(user_id.getvalue())}
    except oracledb.Error as e:
        raise HTTPException(status_code=400, detail=str(e))
    finally:
        cursor.close()

@router.post("/login")
def login(form_data: OAuth2PasswordRequestForm = Depends(), db = Depends(get_db)):
    cursor = db.cursor()
    try:
        status = cursor.var(oracledb.STRING)
        role = cursor.var(oracledb.STRING)
        user_id = cursor.var(oracledb.NUMBER)
        cursor.callproc("SP_LOGIN", [form_data.username, form_data.password, status, role, user_id])
        if status.getvalue() != "SUCCESS":
            raise HTTPException(status_code=401, detail="Identifiants incorrects")
        token = jwt.encode(
            {"sub": int(user_id.getvalue()), "role": role.getvalue()},
            settings.SECRET_KEY,
            algorithm=settings.ALGORITHM
        )
        return {"access_token": token, "token_type": "bearer", "role": role.getvalue()}
    except oracledb.Error as e:
        print(e)
        raise HTTPException(status_code=400, detail=str(e))
    finally:
        cursor.close()
