class DonationCreate(BaseModel):
    besoin_id: int
    montant: float
    preuve: str
