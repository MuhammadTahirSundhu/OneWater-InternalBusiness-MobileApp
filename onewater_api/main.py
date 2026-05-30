from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
import logging

from config import get_settings
from routers import auth, users, customers, products, transactions, reports, notifications, audit, settings, expenses

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

settings_obj = get_settings()

app = FastAPI(
    title="OneWater Pakistan API",
    description="Internal Business Management API for OneWater Pakistan",
    version="1.0.0",
    docs_url="/docs" if settings_obj.environment == "development" else None,
    redoc_url=None,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include routers
app.include_router(auth.router, prefix="/api/v1/auth", tags=["Auth"])
app.include_router(users.router, prefix="/api/v1/users", tags=["Users"])
app.include_router(customers.router, prefix="/api/v1/customers", tags=["Customers"])
app.include_router(products.router, prefix="/api/v1/products", tags=["Products"])
app.include_router(transactions.router, prefix="/api/v1/transactions", tags=["Transactions"])
app.include_router(reports.router, prefix="/api/v1/reports", tags=["Reports"])
app.include_router(notifications.router, prefix="/api/v1/notifications", tags=["Notifications"])
app.include_router(audit.router, prefix="/api/v1/audit-logs", tags=["Audit"])
app.include_router(settings.router, prefix="/api/v1/settings", tags=["Settings"])
app.include_router(expenses.router, prefix="/api/v1/expenses", tags=["Expenses"])


@app.get("/health")
async def health_check():
    return {"status": "ok", "service": "OneWater Pakistan API"}


@app.exception_handler(Exception)
async def global_exception_handler(request: Request, exc: Exception):
    logger.error(f"Unhandled exception: {exc}", exc_info=True)
    return JSONResponse(
        status_code=500,
        content={"detail": "Internal server error"},
    )


# Start APScheduler on startup
@app.on_event("startup")
async def startup_event():
    from scheduler.weekly_jobs import start_scheduler
    start_scheduler()
    logger.info("OneWater API started successfully")


@app.on_event("shutdown")
async def shutdown_event():
    from scheduler.weekly_jobs import stop_scheduler
    stop_scheduler()
