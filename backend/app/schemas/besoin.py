
from pydantic import BaseModel
from typing import Optional

class BesoinBase(BaseModel):
    item_type_id: int
    quantity_requested: float
    description: Optional[str] = None

class BesoinCreate(BaseModel):
    action_id: int
    nom: str
    description: str
    type_besoin: str
    unite_demande: int
    prix_unitaire: float

class Besoin(BesoinBase):
    id: int
    action_id: int
    quantity_received: float = 0.0

    class Config:
        from_attributes = True