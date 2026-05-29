from pydantic_settings import BaseSettings
from functools import lru_cache


class Settings(BaseSettings):
    supabase_url: str
    supabase_service_key: str
    supabase_anon_key: str = ""
    jwt_secret: str
    jwt_algorithm: str = "HS256"
    jwt_expiry_hours: int = 24
    jwt_refresh_expiry_days: int = 30
    business_name: str = "OneWater Pakistan"
    business_phone: str = ""
    business_address: str = ""
    invoice_prefix: str = "OW"
    invoice_start_number: int = 1
    environment: str = "development"
    # Cloudinary
    cloudinary_cloud_name: str = ""
    cloudinary_api_key: str = ""
    cloudinary_api_secret: str = ""

    class Config:
        env_file = ".env"
        case_sensitive = False


@lru_cache()
def get_settings() -> Settings:
    return Settings()
