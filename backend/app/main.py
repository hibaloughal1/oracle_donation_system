from fastapi import FastAPI
from app.api.auth import router as auth_router
from app.api.actions import router as actions_router
from app.api.besoins import router as besoins_router
from app.api.donations import router as donations_router
from app.api.organisations import router as organisations_router

app = FastAPI(
    title="Oracle Donation System",
    description="Système de gestion des dons avec Oracle PL/SQL",
    version="1.0.0"
)

# Inclure les routers avec prefix /api
app.include_router(auth_router, prefix="/api/auth", tags=["auth"])
app.include_router(actions_router, prefix="/api/actions", tags=["actions"])
app.include_router(besoins_router, prefix="/api/besoins", tags=["besoins"])
app.include_router(donations_router, prefix="/api/donations", tags=["donations"])
app.include_router(organisations_router, prefix="/api/organisations", tags=["organisations"])

@app.get("/")
def root():
    return {"message": "API prête ! Docs sur /docs"}