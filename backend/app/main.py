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
