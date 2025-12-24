from fastapi import APIRouter
from .health import router as health_router

# Le router du sous-dossier routes (pour health)
router = APIRouter()

router.include_router(health_router)