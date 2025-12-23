from pydantic import BaseModel
from datetime import date

class ActionCreate(BaseModel):
    org_id: int
    titre: str
    description: str
    affiche: str
    date_debut: date
    date_fin: date
    montant_objectif: float
