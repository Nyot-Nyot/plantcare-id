"""Treatment guide API routes."""

import logging
from typing import Optional
from uuid import UUID

from fastapi import APIRouter, HTTPException, Query
from fastapi.responses import JSONResponse

from backend.models.treatment_guide import TreatmentGuideResponse
from backend.services.cache_service import cache_service
from backend.services.guide_service import GuideService, SupabaseError, GuideServiceError

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api/guides", tags=["guides"])

# Lazy initialization of guide service
_guide_service = None


def get_guide_service() -> GuideService:
    """Get or create guide service instance (lazy loading)."""
    global _guide_service
    if _guide_service is None:
        _guide_service = GuideService()
    return _guide_service


@router.get("/{guide_id}", response_model=TreatmentGuideResponse)
async def get_guide_by_id(guide_id: str):
    """
    Get a treatment guide by its ID.

    This endpoint returns detailed information about a specific treatment guide,
    including all steps, materials needed, and estimated duration.

    - **guide_id**: UUID of the guide to retrieve
    - **Returns**: Complete guide information with steps
    - **Cache**: Response cached for 24 hours
    """
    try:
        # Validate UUID format
        try:
            UUID(guide_id)
        except ValueError:
            raise HTTPException(
                status_code=400,
                detail=f"Invalid UUID format: '{guide_id}'",
            )

        # Generate cache key
        cache_key = f"guide:id:{guide_id}"

        # Try to get from cache first
        cached_guide = await cache_service.get(cache_key)
        if cached_guide:
            logger.info(f"Returning cached guide: {guide_id}")
            return JSONResponse(content=cached_guide)

        # Cache miss, fetch from database
        logger.info(f"Fetching guide from database: {guide_id}")
        guide = await get_guide_service().get_guide_by_id(guide_id)

        if not guide:
            raise HTTPException(
                status_code=404,
                detail=f"Treatment guide with ID '{guide_id}' not found",
            )

        # Convert Pydantic model to dict for JSON response
        response_data = guide.model_dump(mode="json")

        # Cache the response for 24 hours (86400 seconds)
        await cache_service.set(cache_key, response_data, ttl_seconds=86400)

        return JSONResponse(content=response_data)

    except HTTPException:
        raise
    except SupabaseError as e:
        logger.error(f"Database error retrieving guide {guide_id}: {str(e)}")
        raise HTTPException(
            status_code=503,
            detail="Database service temporarily unavailable",
        )
    except GuideServiceError as e:
        logger.error(f"Service error retrieving guide {guide_id}: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail="Internal server error while processing guide data",
        )
    except Exception as e:
        logger.error(f"Unexpected error retrieving guide {guide_id}: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail="Internal server error while retrieving guide",
        )


@router.get("/by-plant/{plant_id}")
async def get_guides_by_plant(
    plant_id: str,
    disease_name: Optional[str] = Query(
        None, description="Filter by disease name (case-insensitive partial match)"
    ),
    limit: int = Query(10, ge=1, le=100, description="Number of results to return"),
    offset: int = Query(0, ge=0, description="Number of results to skip"),
):
    """
    Get all treatment guides for a specific plant.

    This endpoint returns a list of guides for a plant, with optional filtering
    by disease name and pagination support.

    - **plant_id**: Plant identifier (e.g., 'monstera_deliciosa', 'general')
    - **disease_name**: Optional filter for disease name (case-insensitive)
    - **limit**: Maximum results to return (1-100, default 10)
    - **offset**: Results to skip for pagination (default 0)
    - **Cache**: Response cached for 24 hours
    """
    try:
        # Generate cache key including all parameters
        cache_key = (
            f"guide:plant:{plant_id}:"
            f"disease:{disease_name or 'all'}:"
            f"limit:{limit}:offset:{offset}"
        )

        # Try to get from cache first
        cached_guides = await cache_service.get(cache_key)
        if cached_guides:
            logger.info(f"Returning cached guides for plant: {plant_id}")
            return JSONResponse(content=cached_guides)

        # Cache miss, fetch from database
        logger.info(
            f"Fetching guides from database for plant: {plant_id} "
            f"(disease: {disease_name}, limit: {limit}, offset: {offset})"
        )

        guides, total_count = await get_guide_service().get_guides_by_plant_id(
            plant_id=plant_id,
            disease_name=disease_name,
            limit=limit,
            offset=offset,
        )

        # Convert Pydantic models to dicts for JSON response
        response_guides = [guide.model_dump(mode="json") for guide in guides]

        response_data = {
            "plant_id": plant_id,
            "disease_filter": disease_name,
            "total_results": total_count,
            "limit": limit,
            "offset": offset,
            "guides": response_guides,
        }

        # Cache the response for 24 hours
        await cache_service.set(cache_key, response_data, ttl_seconds=86400)

        return JSONResponse(content=response_data)

    except HTTPException:
        raise
    except SupabaseError as e:
        logger.error(
            f"Database error retrieving guides for plant {plant_id}: {str(e)}"
        )
        raise HTTPException(
            status_code=503,
            detail="Database service temporarily unavailable",
        )
    except GuideServiceError as e:
        logger.error(
            f"Service error retrieving guides for plant {plant_id}: {str(e)}"
        )
        raise HTTPException(
            status_code=500,
            detail="Internal server error while processing guides data",
        )
    except Exception as e:
        logger.error(
            f"Unexpected error retrieving guides for plant {plant_id}: {str(e)}"
        )
        raise HTTPException(
            status_code=500,
            detail="Internal server error while retrieving guides",
        )
