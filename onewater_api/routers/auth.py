from fastapi import APIRouter, Depends, HTTPException, status
from jose import jwt
from passlib.context import CryptContext
from datetime import datetime, timedelta, timezone
from config import get_settings
from dependencies import get_supabase, get_current_user
from models.user import (
    LoginRequest, TokenResponse, UserResponse,
    ChangePasswordRequest, UpdateProfileRequest,
)
from utils.audit_writer import write_audit
import uuid

router = APIRouter()
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")
settings = get_settings()


def create_access_token(data: dict) -> str:
    to_encode = data.copy()
    expire = datetime.now(timezone.utc) + timedelta(hours=settings.jwt_expiry_hours)
    to_encode.update({"exp": expire, "type": "access"})
    return jwt.encode(to_encode, settings.jwt_secret, algorithm=settings.jwt_algorithm)


def create_refresh_token(data: dict) -> str:
    to_encode = data.copy()
    expire = datetime.now(timezone.utc) + timedelta(days=settings.jwt_refresh_expiry_days)
    to_encode.update({"exp": expire, "type": "refresh"})
    return jwt.encode(to_encode, settings.jwt_secret, algorithm=settings.jwt_algorithm)


@router.post("/login", response_model=TokenResponse)
async def login(request: LoginRequest):
    db = get_supabase()

    # Try finding by phone or email
    result = db.table("users").select("*").or_(
        f"phone.eq.{request.identifier},email.eq.{request.identifier}"
    ).execute()

    if not result.data or len(result.data) == 0:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid credentials")

    user = result.data[0]

    if not user.get("is_active", False):
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Account is deactivated")

    # Verify password from password_hash field
    if not pwd_context.verify(request.password, user.get("password_hash", "")):
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid credentials")

    token_data = {
        "sub": user["id"],
        "role": user["role"],
        "full_name": user["full_name"],
        "phone": user["phone"],
    }

    access_token = create_access_token(token_data)
    refresh_token = create_refresh_token(token_data)

    await write_audit(
        user_id=user["id"],
        user_name=user["full_name"],
        action="LOGIN",
        entity_type="auth",
        entity_id=user["id"],
    )

    user_response = UserResponse(
        id=user["id"],
        full_name=user["full_name"],
        phone=user["phone"],
        email=user.get("email"),
        role=user["role"],
        is_active=user["is_active"],
        avatar_url=user.get("avatar_url"),
        onboarding_done=user.get("onboarding_done", False),
        created_at=user["created_at"],
    )

    return TokenResponse(
        access_token=access_token,
        refresh_token=refresh_token,
        user=user_response,
    )


@router.post("/refresh", response_model=dict)
async def refresh_token(refresh_token: str):
    try:
        payload = jwt.decode(refresh_token, settings.jwt_secret, algorithms=[settings.jwt_algorithm])
        if payload.get("type") != "refresh":
            raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid token type")

        token_data = {
            "sub": payload["sub"],
            "role": payload["role"],
            "full_name": payload["full_name"],
            "phone": payload["phone"],
        }
        new_access = create_access_token(token_data)
        return {"access_token": new_access, "token_type": "bearer"}
    except Exception:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid refresh token")


@router.post("/logout")
async def logout(current_user: dict = Depends(get_current_user)):
    await write_audit(
        user_id=current_user["id"],
        user_name=current_user["full_name"],
        action="LOGOUT",
        entity_type="auth",
        entity_id=current_user["id"],
    )
    return {"message": "Logged out successfully"}


@router.get("/me", response_model=UserResponse)
async def get_me(current_user: dict = Depends(get_current_user)):
    db = get_supabase()
    result = db.table("users").select("*").eq("id", current_user["id"]).execute()
    if not result.data:
        raise HTTPException(status_code=404, detail="User not found")
    u = result.data[0]
    return UserResponse(
        id=u["id"], full_name=u["full_name"], phone=u["phone"],
        email=u.get("email"), role=u["role"], is_active=u["is_active"],
        avatar_url=u.get("avatar_url"),
        onboarding_done=u.get("onboarding_done", False),
        created_at=u["created_at"],
    )


@router.put("/me", response_model=UserResponse)
async def update_me(body: UpdateProfileRequest, current_user: dict = Depends(get_current_user)):
    db = get_supabase()
    update_data = body.model_dump(exclude_none=True)
    update_data["updated_at"] = datetime.now(timezone.utc).isoformat()

    db.table("users").update(update_data).eq("id", current_user["id"]).execute()

    await write_audit(
        user_id=current_user["id"],
        user_name=current_user["full_name"],
        action="UPDATE_PROFILE",
        entity_type="user",
        entity_id=current_user["id"],
        new_value=update_data,
    )

    return await get_me(current_user)


@router.put("/change-password")
async def change_password(body: ChangePasswordRequest, current_user: dict = Depends(get_current_user)):
    db = get_supabase()
    result = db.table("users").select("password_hash").eq("id", current_user["id"]).execute()
    if not result.data:
        raise HTTPException(status_code=404, detail="User not found")

    if not pwd_context.verify(body.current_password, result.data[0]["password_hash"]):
        raise HTTPException(status_code=400, detail="Current password is incorrect")

    new_hash = pwd_context.hash(body.new_password)
    db.table("users").update({
        "password_hash": new_hash,
        "updated_at": datetime.now(timezone.utc).isoformat()
    }).eq("id", current_user["id"]).execute()

    await write_audit(
        user_id=current_user["id"],
        user_name=current_user["full_name"],
        action="PASSWORD_CHANGE",
        entity_type="auth",
        entity_id=current_user["id"],
    )

    return {"message": "Password changed successfully"}
