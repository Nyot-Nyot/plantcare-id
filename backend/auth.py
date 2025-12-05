"""Authentication and authorization utilities."""

import logging
from typing import Optional

from fastapi import Depends, Header, HTTPException, status

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


async def require_admin(current_user: str = Depends(verify_auth_token)) -> str:
    """
    Require admin role for sensitive operations.

    This dependency chains from verify_auth_token to ensure the token
    is verified before checking admin permissions.

    Args:
        current_user: User identifier from verify_auth_token dependency

    Returns:
        User ID if admin check passes

    Raises:
        HTTPException: If user is not admin (403 Forbidden)
    """
    # TODO: Implement role checking with Supabase
    # For now, all authenticated users are treated as admins

    # In production:
    # 1. Use current_user to fetch user record from Supabase
    # 2. Check user role/permissions in database or JWT claims
    # 3. Raise 403 Forbidden if not admin:
    #    raise HTTPException(
    #        status_code=status.HTTP_403_FORBIDDEN,
    #        detail="Admin privileges required"
    #    )

    logger.info(f"Admin check passed (placeholder) for user: {current_user[:10]}...")
    return current_user
