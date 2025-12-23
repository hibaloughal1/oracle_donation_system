class BesoinCreate(BaseModel):
    action_id: int
    nom: str
    description: str
    type_besoin: str
    unite_demande: int
    prix_unitaire: float
