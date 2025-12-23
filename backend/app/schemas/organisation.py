from pydantic import BaseModel

class OrganisationCreate(BaseModel):
    nom: str
    description: str
    tel: str
    patente: str
    lieu: str
