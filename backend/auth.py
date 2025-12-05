"""Authentication and authorization utilities."""

import logging
from typing import Optional

from fastapi import Header, HTTPException, status

logger = logging.getLogger(__name__)


async def verify_auth_token(
    authorization: Optional[str] = Header(None, description="Bearer token for authentication")
) -> str:
    """
    Verify authentication token from Authorization header.

    This is a placeholder implementation that should be replaced with
    actual JWT/Supabase token verification in production.

    Args:
        authorization: Authorization header value (format: "Bearer <token>")

    Returns:
        User ID or token identifier

    Raises:
        HTTPException: If token is missing or invalid (401 Unauthorized)
    """
    # TODO: Implement actual token verification with Supabase Auth
    # For now, this is a placeholder that accepts any Bearer token

    if not authorization:
        logger.warning("Missing Authorization header")
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Missing authentication token",
            headers={"WWW-Authenticate": "Bearer"},
        )

    # Check Bearer format
    parts = authorization.split()
    if len(parts) != 2 or parts[0].lower() != "bearer":
        logger.warning(f"Invalid Authorization header format: {authorization}")
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid authentication token format. Expected: Bearer <token>",
            headers={"WWW-Authenticate": "Bearer"},
        )

    token = parts[1]

    # Placeholder validation - accept any non-empty token
    # In production, verify with Supabase Auth:
    # - supabase.auth.get_user(token)
    # - Check JWT signature and expiration
    # - Validate user permissions

    if not token:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Empty authentication token",
            headers={"WWW-Authenticate": "Bearer"},
        )

    logger.info(f"Authentication successful (placeholder) for token: {token[:10]}...")
    return token  # In production, return user_id or User object


async def require_admin(token: str = Header(..., alias="authorization")) -> str:
    """
    Require admin role for sensitive operations.

    This is a placeholder that should check user roles in production.

    Args:
        token: Authorization token (automatically populated by verify_auth_token)

    Returns:
        User ID

    Raises:
        HTTPException: If user is not admin (403 Forbidden)
    """
    # TODO: Implement role checking with Supabase
    # For now, all authenticated users are treated as admins

    # In production:
    # 1. Get user from token
    # 2. Check user role in database or JWT claims
    # 3. Raise 403 if not admin

    logger.info("Admin check passed (placeholder)")
    return token
