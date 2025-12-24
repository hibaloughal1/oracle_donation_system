from fastapi import FastAPI
from app.api import api_router

app = FastAPI(
    title="Oracle Donation System",
    description="Système complet de gestion des dons avec Oracle PL/SQL",
    version="1.0.0"
)

app.include_router(api_router)

@app.get("/")
def root():
    return {"message": "API prête ! Accédez à /docs pour tester les endpoints."}