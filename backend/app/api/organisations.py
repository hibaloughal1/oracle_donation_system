import oracledb
from fastapi import APIRouter, Depends ,HTTPException
from app.api.deps import get_db
from app.api.deps import get_current_user

router = APIRouter()

@router.get("/")
def get_organisations(db = Depends(get_db)):
    cursor = db.cursor()
    try:
        cursor.execute("""
            SELECT id_org, nom_org, desc_org, tel_org, statut_org
            FROM Organisation
            WHERE statut_org = 'ACTIVE'
            ORDER BY nom_org
        """)
        columns = [col[0].lower() for col in cursor.description]
        return [dict(zip(columns, row)) for row in cursor.fetchall()]
    except oracledb.Error as e:
        error, = e.args
        raise HTTPException(status_code=400, detail=f"Erreur Oracle : {error.message}")
    finally:
        cursor.close()

# Optionnel : création d'organisation
@router.post("/")
def create_organisation(
    nom_org: str,
    desc_org: str,
    tel_org: str,
    num_patente: str,
    lieu_org: str,
    current_user = Depends(get_current_user),
    db = Depends(get_db)
):
    cursor = db.cursor()
    try:
        id_org = cursor.var(oracledb.NUMBER)
        status = cursor.var(oracledb.STRING)
        message = cursor.var(oracledb.STRING)

        cursor.callproc(
            "SECURITY_PKG.SP_CREATE_ORGANISATION",
            [
                current_user["user_id"],
                nom_org,
                desc_org,
                tel_org,
                num_patente,
                lieu_org,
                id_org,
                status,
                message
            ]
        )
        db.commit()

        if status.getvalue() != "OK":
            raise HTTPException(status_code=400, detail=message.getvalue())

        return {"message": "Organisation créée avec succès", "org_id": int(id_org.getvalue())}
    except oracledb.Error as e:
        db.rollback()
        error, = e.args
        raise HTTPException(status_code=400, detail=f"Erreur Oracle : {error.message}")
    finally:
        cursor.close()