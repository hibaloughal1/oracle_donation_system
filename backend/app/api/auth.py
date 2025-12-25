from fastapi import APIRouter, Depends, HTTPException
from fastapi.security import OAuth2PasswordRequestForm
from jose import jwt
from app.api.deps import get_db
from app.core.config import settings
import oracledb
from pydantic import BaseModel

router = APIRouter()



class RegisterRequest(BaseModel):
    email: str
    password: str
    phone: str

@router.post("/register")
def register(request: RegisterRequest, db = Depends(get_db)):
    cursor = db.cursor()
    try:
        user_id = cursor.var(oracledb.NUMBER)
        status = cursor.var(oracledb.STRING, 50)
        message = cursor.var(oracledb.STRING, 500)

        cursor.callproc(
            "SECURITY_PKG.SP_REGISTER_USER",
            [
                "Utilisateur",               # p_nom (NULL, pas utilisé dans le form)
                request.email,      # p_email
                request.phone,      # p_tel
                None,               # p_adresse (NULL)
                request.password,   # p_password
                user_id,            # p_id_user OUT
                status,             # p_status OUT
                message             # p_message OUT
            ]
        )
        db.commit()

        result_status = status.getvalue()
        result_message = message.getvalue() or "Inscription réussie"

        if result_status != "OK":
            raise HTTPException(status_code=400, detail=result_message)

        return {"message": result_message, "user_id": int(user_id.getvalue())}
    except oracledb.Error as e:
        db.rollback()
        error, = e.args
        raise HTTPException(
            status_code=400,
            detail=f"Erreur Oracle ORA-{error.code}: {error.message.strip() if error.message else 'Erreur inconnue'}"
        )
    finally:
        cursor.close()






class LoginRequest(BaseModel):
    email: str
    password: str

@router.post("/login")
def login(request: LoginRequest, db = Depends(get_db)):
    cursor = db.cursor()
    try:
        user_id = cursor.var(oracledb.NUMBER)
        main_role = cursor.var(oracledb.STRING)
        status = cursor.var(oracledb.STRING, 50)
        message = cursor.var(oracledb.STRING, 500)

        cursor.callproc(
            "SECURITY_PKG.SP_LOGIN",
            [
                request.email,
                request.password,
                user_id,
                main_role,
                status,
                message
            ]
        )

        result_status = status.getvalue()

        if result_status != "OK":
            raise HTTPException(status_code=401, detail=message.getvalue() or "Identifiants incorrects")

        # Si on arrive ici, l'auth a réussi – on génère le token
        token = jwt.encode(
            {
                "sub": int(user_id.getvalue()),
                "role": main_role.getvalue() or "USER"
            },
            settings.SECRET_KEY,
            algorithm=settings.ALGORITHM
        )

        return {
            "access_token": token,
            "token_type": "bearer",
            "role": main_role.getvalue() or "USER"
        }

    except oracledb.Error as e:
        error, = e.args
        # Si c'est ORA-01031 (privilèges insuffisants pour set_app_user)
        # on ignore l’erreur car l’auth a déjà réussi
        if error.code == 1031:
            token = jwt.encode(
                {
                    "sub": int(user_id.getvalue()),
                    "role": main_role.getvalue() or "USER"
                },
                settings.SECRET_KEY,
                algorithm=settings.ALGORITHM
            )
            return {
                "access_token": token,
                "token_type": "bearer",
                "role": main_role.getvalue() or "USER"
            }

        # Autres erreurs (ex. mauvais mot de passe)
        raise HTTPException(
            status_code=400,
            detail=f"Erreur Oracle ORA-{error.code}: {error.message.strip() if error.message else 'Erreur inconnue'}"
        )
    finally:
        cursor.close()