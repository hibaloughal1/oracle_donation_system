from fastapi import APIRouter
from .auth import router as auth_router
from .organisations import router as organisations_router
from .actions import router as actions_router
from .besoins import router as besoins_router
from .donations import router as donations_router
from .routes import router as routes_router  # Le sous-router health

api_router = APIRouter(prefix="/api")

api_router.include_router(auth_router, prefix="/auth", tags=["auth"])
api_router.include_router(organisations_router, prefix="/organisations", tags=["organisations"])
api_router.include_router(actions_router, prefix="/actions", tags=["actions"])
api_router.include_router(besoins_router, prefix="/besoins", tags=["besoins"])
api_router.include_router(donations_router, prefix="/donations", tags=["donations"])
api_router.include_router(routes_router)  # Pour /api/health