"""Guide service for interacting with Supabase treatment_guides table."""

import json
import logging
import os
from typing import Any, Dict, List, Optional
from uuid import UUID

import httpx
from dotenv import load_dotenv

from backend.models.treatment_guide import TreatmentGuide, TreatmentGuideCreate

load_dotenv()

logger = logging.getLogger(__name__)


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

    async def get_guide_by_id(self, guide_id: str) -> Optional[Dict[str, Any]]:
        """
        Get a treatment guide by its UUID.

        Args:
            guide_id: UUID of the guide

        Returns:
            Guide data as dict or None if not found

        Raises:
            HTTPException: If database error occurs
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
                    if data:
                        guide_data = data[0]
                        # Parse JSONB fields
                        if isinstance(guide_data.get("steps"), str):
                            guide_data["steps"] = json.loads(guide_data["steps"])
                        if isinstance(guide_data.get("materials"), str):
                            guide_data["materials"] = json.loads(guide_data["materials"])
                        return guide_data
                    return None
                elif response.status_code == 404:
                    return None
                else:
                    logger.error(
                        f"Supabase error getting guide {guide_id}: "
                        f"{response.status_code} - {response.text}"
                    )
                    raise Exception(f"Database error: {response.status_code}")

        except Exception as e:
            logger.error(f"Error getting guide by ID {guide_id}: {str(e)}")
            raise

    async def get_guides_by_plant_id(
        self,
        plant_id: str,
        disease_name: Optional[str] = None,
        limit: int = 10,
        offset: int = 0,
    ) -> tuple[List[Dict[str, Any]], int]:
        """
        Get all treatment guides for a specific plant with total count.

        Args:
            plant_id: Plant identifier
            disease_name: Optional filter by disease name
            limit: Maximum number of results (default 10, max 100)
            offset: Number of results to skip for pagination

        Returns:
            Tuple of (list of guide data dictionaries, total count)

        Raises:
            HTTPException: If database error occurs
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
            headers_with_count = {
                **self.headers,
                "Prefer": "count=exact"
            }

            async with httpx.AsyncClient() as client:
                response = await client.get(
                    f"{self.base_url}/treatment_guides",
                    headers=headers_with_count,
                    params=params,
                )

                # Supabase returns 206 Partial Content when using Prefer: count=exact
                # with pagination, or 200 OK otherwise. Both are success cases.
                if response.status_code in (200, 206):
                    guides = response.json()
                    
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
                        total_count = len(guides)
                    
                    # Parse JSONB fields for each guide
                    for guide in guides:
                        if isinstance(guide.get("steps"), str):
                            guide["steps"] = json.loads(guide["steps"])
                        if isinstance(guide.get("materials"), str):
                            guide["materials"] = json.loads(guide["materials"])
                    
                    return guides, total_count
                else:
                    logger.error(
                        f"Supabase error getting guides for plant {plant_id}: "
                        f"{response.status_code} - {response.text}"
                    )
                    raise Exception(f"Database error: {response.status_code}")

        except Exception as e:
            logger.error(
                f"Error getting guides for plant {plant_id}: {str(e)}"
            )
            raise

    async def create_guide(
        self, guide_data: TreatmentGuideCreate
    ) -> Dict[str, Any]:
        """
        Create a new treatment guide.

        Args:
            guide_data: Guide data to create

        Returns:
            Created guide data

        Raises:
            HTTPException: If database error occurs
        """
        try:
            # Convert Pydantic model to dict
            data = guide_data.model_dump()

            # Ensure JSONB fields are properly formatted
            data["steps"] = [step.model_dump() for step in guide_data.steps]
            data["materials"] = guide_data.materials

            async with httpx.AsyncClient() as client:
                response = await client.post(
                    f"{self.base_url}/treatment_guides",
                    headers=self.headers,
                    json=data,
                )

                if response.status_code in [200, 201]:
                    created_guide = response.json()
                    if isinstance(created_guide, list):
                        created_guide = created_guide[0]
                    return created_guide
                else:
                    logger.error(
                        f"Supabase error creating guide: "
                        f"{response.status_code} - {response.text}"
                    )
                    raise Exception(f"Database error: {response.status_code}")

        except Exception as e:
            logger.error(f"Error creating guide: {str(e)}")
            raise

    async def update_guide(
        self, guide_id: str, guide_data: Dict[str, Any]
    ) -> Optional[Dict[str, Any]]:
        """
        Update an existing treatment guide.

        Args:
            guide_id: UUID of the guide to update
            guide_data: Updated guide data

        Returns:
            Updated guide data or None if not found

        Raises:
            HTTPException: If database error occurs
        """
        try:
            # Convert steps to dict if present
            if "steps" in guide_data and guide_data["steps"]:
                guide_data["steps"] = [
                    step.model_dump() if hasattr(step, "model_dump") else step
                    for step in guide_data["steps"]
                ]

            async with httpx.AsyncClient() as client:
                response = await client.patch(
                    f"{self.base_url}/treatment_guides",
                    headers=self.headers,
                    params={"id": f"eq.{guide_id}"},
                    json=guide_data,
                )

                if response.status_code == 200:
                    updated = response.json()
                    if updated:
                        return updated[0] if isinstance(updated, list) else updated
                    return None
                elif response.status_code == 404:
                    return None
                else:
                    logger.error(
                        f"Supabase error updating guide {guide_id}: "
                        f"{response.status_code} - {response.text}"
                    )
                    raise Exception(f"Database error: {response.status_code}")

        except Exception as e:
            logger.error(f"Error updating guide {guide_id}: {str(e)}")
            raise
