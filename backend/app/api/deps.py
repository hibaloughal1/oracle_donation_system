import oracledb
from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from jose import JWTError, jwt
from app.core.config import settings  # Assure-toi que config.py existe avec settings

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/api/auth/login")

# Création du pool de connexions Oracle
pool = oracledb.create_pool(
    user=settings.DB_USERNAME,
    password=settings.DB_PASSWORD,
    dsn=settings.DB_DSN,
    min=2,
    max=10,
    increment=1
)

def get_db():
    conn = pool.acquire()
    try:
        yield conn
    finally:
        pool.release(conn)

async def get_current_user(token: str = Depends(oauth2_scheme)):
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Token invalide ou expiré",
        headers={"WWW-Authenticate": "Bearer"},
    )
    try:
        payload = jwt.decode(token, settings.SECRET_KEY, algorithms=[settings.ALGORITHM])
        user_id: int = payload.get("sub")
        role: str = payload.get("role", "USER")
        if user_id is None:
            raise credentials_exception
        return {"user_id": user_id, "role": role}
    except JWTError:
        raise credentials_exception