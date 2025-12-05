"""Guide service for interacting with Supabase treatment_guides table."""

import json
import logging
import os
from typing import Any, Dict, List, Optional
from uuid import UUID

import httpx
from dotenv import load_dotenv
from pydantic import ValidationError

from backend.models.treatment_guide import (
    TreatmentGuide,
    TreatmentGuideCreate,
    TreatmentGuideUpdate,
)

load_dotenv()

logger = logging.getLogger(__name__)


class SupabaseError(Exception):
    """Custom exception for Supabase database errors."""

    def __init__(self, message: str, status_code: int = None, response_text: str = None):
        self.status_code = status_code
        self.response_text = response_text
        super().__init__(message)


class GuideServiceError(Exception):
    """Custom exception for GuideService errors."""
    pass


class GuideService:
    """Service for managing treatment guides in Supabase."""

    def __init__(self, raise_on_missing_env: bool = True):
        """
        Initialize Supabase client.

        Args:
            raise_on_missing_env: If True, raise ValueError when env vars are missing.
                                 If False, set client as None (useful for testing).
        """
        self.supabase_url = os.getenv("SUPABASE_URL")
        self.supabase_key = os.getenv("SUPABASE_ANON_KEY")

        if not self.supabase_url or not self.supabase_key:
            if raise_on_missing_env:
                raise ValueError(
                    "SUPABASE_URL and SUPABASE_ANON_KEY must be set in environment variables"
                )
            else:
                # Allow initialization without env vars for testing
                self.supabase_url = None
                self.supabase_key = None
                self.headers = None
                return

        self.headers = {
            "apikey": self.supabase_key,
            "Authorization": f"Bearer {self.supabase_key}",
            "Content-Type": "application/json",
            "Prefer": "return=representation",
        }
        self.base_url = f"{self.supabase_url}/rest/v1"

    def _check_configured(self):
        """Check if service is properly configured."""
        if not self.supabase_url or not self.supabase_key:
            raise ValueError(
                "GuideService not properly configured. "
                "SUPABASE_URL and SUPABASE_ANON_KEY must be set."
            )

    async def get_guide_by_id(self, guide_id: str) -> Optional[TreatmentGuide]:
        """
        Get a treatment guide by its UUID.

        Args:
            guide_id: UUID of the guide

        Returns:
            TreatmentGuide model instance or None if not found

        Raises:
            SupabaseError: If database error occurs
            GuideServiceError: If data parsing fails
        """
        self._check_configured()
        try:
            async with httpx.AsyncClient() as client:
                response = await client.get(
                    f"{self.base_url}/treatment_guides",
                    headers=self.headers,
                    params={"id": f"eq.{guide_id}", "select": "*"},
                )

                if response.status_code == 200:
                    data = response.json()
                    if data and len(data) > 0:
                        guide_data = data[0]
                        # Parse JSONB fields if they're strings
                        if isinstance(guide_data.get("steps"), str):
                            guide_data["steps"] = json.loads(guide_data["steps"])
                        if isinstance(guide_data.get("materials"), str):
                            guide_data["materials"] = json.loads(
                                guide_data["materials"]
                            )

                        # Parse into Pydantic model for type safety
                        try:
                            return TreatmentGuide(**guide_data)
                        except ValidationError as e:
                            logger.error(
                                f"Failed to parse guide {guide_id} into model: {e}"
                            )
                            raise GuideServiceError(
                                f"Invalid guide data from database: {e}"
                            )
                    return None
                elif response.status_code == 404:
                    return None
                else:
                    logger.error(
                        f"Supabase error getting guide {guide_id}: "
                        f"{response.status_code} - {response.text}"
                    )
                    raise SupabaseError(
                        f"Database error while fetching guide",
                        status_code=response.status_code,
                        response_text=response.text,
                    )

        except (SupabaseError, GuideServiceError):
            raise
        except Exception as e:
            logger.error(f"Unexpected error getting guide by ID {guide_id}: {str(e)}")
            raise GuideServiceError(f"Failed to fetch guide: {str(e)}")

    async def get_guides_by_plant_id(
        self,
        plant_id: str,
        disease_name: Optional[str] = None,
        limit: int = 10,
        offset: int = 0,
    ) -> tuple[List[TreatmentGuide], int]:
        """
        Get all treatment guides for a specific plant with total count.

        Args:
            plant_id: Plant identifier
            disease_name: Optional filter by disease name
            limit: Maximum number of results (default 10, max 100)
            offset: Number of results to skip for pagination

        Returns:
            Tuple of (list of TreatmentGuide models, total count)

        Raises:
            SupabaseError: If database error occurs
            GuideServiceError: If data parsing fails
        """
        self._check_configured()
        try:
            # Validate limit
            limit = min(max(1, limit), 100)

            params = {
                "plant_id": f"eq.{plant_id}",
                "select": "*",
                "limit": str(limit),
                "offset": str(offset),
                "order": "created_at.desc",
            }

            if disease_name:
                params["disease_name"] = f"ilike.%{disease_name}%"

            # Add Prefer header to get total count
            headers_with_count = {**self.headers, "Prefer": "count=exact"}

            async with httpx.AsyncClient() as client:
                response = await client.get(
                    f"{self.base_url}/treatment_guides",
                    headers=headers_with_count,
                    params=params,
                )

                # Supabase returns 206 Partial Content when using Prefer: count=exact
                # with pagination, or 200 OK otherwise. Both are success cases.
                if response.status_code in (200, 206):
                    guides_data = response.json()

                    # Extract total count from Content-Range header
                    # Format: "0-9/42" means items 0-9 out of total 42
                    content_range = response.headers.get("Content-Range", "")
                    total_count = 0
                    if content_range:
                        # Parse "0-9/42" -> extract "42"
                        parts = content_range.split("/")
                        if len(parts) == 2:
                            total_count = int(parts[1])
                    else:
                        # Fallback: if no Content-Range header, use response length
                        total_count = len(guides_data)

                    # Parse JSONB fields and convert to Pydantic models
                    guides = []
                    for guide_data in guides_data:
                        # Parse JSONB fields if they're strings
                        if isinstance(guide_data.get("steps"), str):
                            guide_data["steps"] = json.loads(guide_data["steps"])
                        if isinstance(guide_data.get("materials"), str):
                            guide_data["materials"] = json.loads(
                                guide_data["materials"]
                            )

                        # Parse into Pydantic model for type safety
                        try:
                            guides.append(TreatmentGuide(**guide_data))
                        except ValidationError as e:
                            logger.warning(
                                f"Skipping invalid guide data for plant {plant_id}: {e}"
                            )
                            # Continue processing other guides instead of failing completely
                            continue

                    return guides, total_count
                else:
                    logger.error(
                        f"Supabase error getting guides for plant {plant_id}: "
                        f"{response.status_code} - {response.text}"
                    )
                    raise SupabaseError(
                        f"Database error while fetching guides",
                        status_code=response.status_code,
                        response_text=response.text,
                    )

        except SupabaseError:
            raise
        except Exception as e:
            logger.error(
                f"Unexpected error getting guides for plant {plant_id}: {str(e)}"
            )
            raise GuideServiceError(f"Failed to fetch guides: {str(e)}")

    async def create_guide(
        self, guide_data: TreatmentGuideCreate
    ) -> TreatmentGuide:
        """
        Create a new treatment guide.

        Args:
            guide_data: TreatmentGuideCreate model instance with validated data

        Returns:
            Created TreatmentGuide model instance

        Raises:
            SupabaseError: If database error occurs
            GuideServiceError: If data parsing fails
        """
        self._check_configured()

        try:
            # Convert Pydantic model to dict using mode="json" for proper serialization
            data = guide_data.model_dump(mode="json")

            async with httpx.AsyncClient() as client:
                response = await client.post(
                    f"{self.base_url}/treatment_guides",
                    headers=self.headers,
                    json=data,
                )

                if response.status_code in [200, 201]:
                    created_data = response.json()

                    # Extract first item if list
                    guide_dict = created_data[0] if isinstance(created_data, list) else created_data

                    # Parse response into TreatmentGuide model
                    try:
                        return TreatmentGuide(**guide_dict)
                    except ValidationError as e:
                        logger.error(f"Failed to parse created guide: {e}")
                        raise GuideServiceError(
                            f"Invalid guide data returned from database: {e}"
                        )

                else:
                    logger.error(
                        f"Supabase error creating guide: "
                        f"{response.status_code} - {response.text}"
                    )
                    raise SupabaseError(
                        f"Failed to create guide",
                        status_code=response.status_code,
                        response_text=response.text,
                    )

        except SupabaseError:
            raise
        except GuideServiceError:
            raise
        except httpx.RequestError as e:
            logger.error(f"Network error creating guide: {e}")
            raise SupabaseError(f"Network error creating guide: {e}")
        except Exception as e:
            logger.error(f"Unexpected error creating guide: {type(e).__name__}: {e}")
            raise GuideServiceError(f"Unexpected error creating guide: {e}")


    async def update_guide(
        self, guide_id: str, guide_update: TreatmentGuideUpdate
    ) -> Optional[TreatmentGuide]:
        """
        Update an existing treatment guide.

        Args:
            guide_id: UUID of the guide to update
            guide_update: TreatmentGuideUpdate model instance with validated data

        Returns:
            Updated TreatmentGuide model instance or None if not found

        Raises:
            SupabaseError: If database error occurs
            GuideServiceError: If data parsing fails
        """
        self._check_configured()

        try:
            # Pydantic automatically handles serialization with model_dump()
            # Only include fields that were actually set (exclude_unset=True)
            update_data = guide_update.model_dump(mode="json", exclude_unset=True)

            # If no fields to update, return None
            if not update_data:
                logger.warning(f"No fields to update for guide {guide_id}")
                return None

            async with httpx.AsyncClient() as client:
                response = await client.patch(
                    f"{self.base_url}/treatment_guides",
                    headers=self.headers,
                    params={"id": f"eq.{guide_id}"},
                    json=update_data,
                )

                if response.status_code == 200:
                    data = response.json()

                    if not data or (isinstance(data, list) and len(data) == 0):
                        # Guide not found (empty result)
                        return None

                    # Extract first item if list
                    guide_dict = data[0] if isinstance(data, list) else data

                    # Parse response into TreatmentGuide model
                    try:
                        return TreatmentGuide(**guide_dict)
                    except ValidationError as e:
                        logger.error(f"Failed to parse updated guide {guide_id}: {e}")
                        raise GuideServiceError(
                            f"Invalid guide data returned from database: {e}"
                        )

                elif response.status_code == 404:
                    return None
                else:
                    logger.error(
                        f"Supabase error updating guide {guide_id}: "
                        f"{response.status_code} - {response.text}"
                    )
                    raise SupabaseError(
                        f"Failed to update guide {guide_id}",
                        status_code=response.status_code,
                        response_text=response.text,
                    )

        except SupabaseError:
            raise
        except GuideServiceError:
            raise
        except httpx.RequestError as e:
            logger.error(f"Network error updating guide {guide_id}: {e}")
            raise SupabaseError(f"Network error updating guide: {e}")
        except Exception as e:
            logger.error(f"Unexpected error updating guide {guide_id}: {type(e).__name__}: {e}")
            raise GuideServiceError(f"Unexpected error updating guide: {e}")

    async def delete_guide(self, guide_id: str) -> bool:
        """
        Delete a treatment guide (hard delete).

        Args:
            guide_id: UUID of the guide to delete

        Returns:
            True if deleted successfully, False if not found

        Raises:
            SupabaseError: If database error occurs
        """
        self._check_configured()

        try:
            async with httpx.AsyncClient() as client:
                response = await client.delete(
                    f"{self.base_url}/treatment_guides",
                    headers=self.headers,
                    params={"id": f"eq.{guide_id}"},
                )

                if response.status_code in [200, 204]:
                    # Check if any rows were deleted
                    # Supabase returns empty array if nothing was deleted
                    data = response.json() if response.text else []

                    if not data or (isinstance(data, list) and len(data) == 0):
                        # Guide not found
                        return False

                    logger.info(f"Successfully deleted guide {guide_id}")
                    return True

                elif response.status_code == 404:
                    return False
                else:
                    logger.error(
                        f"Supabase error deleting guide {guide_id}: "
                        f"{response.status_code} - {response.text}"
                    )
                    raise SupabaseError(
                        f"Failed to delete guide {guide_id}",
                        status_code=response.status_code,
                        response_text=response.text,
                    )

        except SupabaseError:
            raise
        except httpx.RequestError as e:
            logger.error(f"Network error deleting guide {guide_id}: {e}")
            raise SupabaseError(f"Network error deleting guide: {e}")
        except Exception as e:
            logger.error(
                f"Unexpected error deleting guide {guide_id}: {type(e).__name__}: {e}"
            )
            raise GuideServiceError(f"Unexpected error deleting guide: {e}")


