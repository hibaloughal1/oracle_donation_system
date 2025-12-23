<<<<<<< HEAD
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.api import auth, organisations, actions, besoins, donations

app = FastAPI(title="Donation Management API")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],   # Lovable
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth.router)
app.include_router(organisations.router)
app.include_router(actions.router)
app.include_router(besoins.router)
app.include_router(donations.router)
=======
from fastapi import FastAPI
from app.core.config import settings
from app.api.routes.health import router as health_router

app = FastAPI(title=settings.APP_NAME)

@app.get("/")
def root():
    return {"message": f"Welcome to {settings.APP_NAME}"}

app.include_router(health_router, prefix="/api/health", tags=["health"])
>>>>>>> b5bcd160c0527b1a1e1ef0ae33d62e90e4cf7dba
