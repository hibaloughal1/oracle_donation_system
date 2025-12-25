import oracledb
from fastapi import APIRouter, Depends
from app.api.deps import get_db

router = APIRouter()

@router.get("/")
def get_actions(db = Depends(get_db)):
    cursor = db.cursor()
    try:
        cursor.execute("""
            SELECT a.id_action, a.titre_action, a.desc_action, a.date_debut_action, a.date_fin_action, 
                   a.statut_action, a.montant_objectif, o.nom_org
            FROM Action_social a
            JOIN Organisation o ON a.id_org = o.id_org
            WHERE a.statut_action = 'ACTIVE'
            ORDER BY a.date_debut_action DESC
        """)
        columns = [col[0].lower() for col in cursor.description]
        return [dict(zip(columns, row)) for row in cursor.fetchall()]
    except oracledb.Error as e:
        raise HTTPException(
              status_code=400,
              detail=f"Erreur Oracle ORA-{error.code}: {error.message or 'Message non disponible'}"
       )
       
    finally:
        cursor.close()