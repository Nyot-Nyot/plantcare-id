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

    def __init__(self):
        """Initialize Supabase client."""
        self.supabase_url = os.getenv("SUPABASE_URL")
        self.supabase_key = os.getenv("SUPABASE_ANON_KEY")

        if not self.supabase_url or not self.supabase_key:
            raise ValueError(
                "SUPABASE_URL and SUPABASE_ANON_KEY must be set in environment variables"
            )

        self.headers = {
            "apikey": self.supabase_key,
            "Authorization": f"Bearer {self.supabase_key}",
            "Content-Type": "application/json",
            "Prefer": "return=representation",
        }
        self.base_url = f"{self.supabase_url}/rest/v1"

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
    ) -> List[Dict[str, Any]]:
        """
        Get all treatment guides for a specific plant.

        Args:
            plant_id: Plant identifier
            disease_name: Optional filter by disease name
            limit: Maximum number of results (default 10, max 100)
            offset: Number of results to skip for pagination

        Returns:
            List of guide data dictionaries

        Raises:
            HTTPException: If database error occurs
        """
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

            async with httpx.AsyncClient() as client:
                response = await client.get(
                    f"{self.base_url}/treatment_guides",
                    headers=self.headers,
                    params=params,
                )

                if response.status_code == 200:
                    guides = response.json()
                    # Parse JSONB fields for each guide
                    for guide in guides:
                        if isinstance(guide.get("steps"), str):
                            guide["steps"] = json.loads(guide["steps"])
                        if isinstance(guide.get("materials"), str):
                            guide["materials"] = json.loads(guide["materials"])
                    return guides
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
