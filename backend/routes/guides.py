"""Treatment guide API routes."""

import logging
from typing import Optional
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, Query

from backend.auth import verify_auth_token
from backend.models.treatment_guide import (
    TreatmentGuideResponse,
    TreatmentGuideListResponse,
    TreatmentGuideCreate,
    TreatmentGuideUpdate,
)
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
async def get_guide_by_id(guide_id: UUID):
    """
    Get a treatment guide by its ID.

    This endpoint returns detailed information about a specific treatment guide,
    including all steps, materials needed, and estimated duration.

    - **guide_id**: UUID of the guide to retrieve
    - **Returns**: Complete guide information with steps
    - **Cache**: Response cached for 24 hours
    """
    try:
        # Convert UUID to string for service layer
        guide_id_str = str(guide_id)

        # Generate cache key
        cache_key = f"guide:id:{guide_id_str}"

        # Try to get from cache first
        cached_guide = await cache_service.get(cache_key)
        if cached_guide:
            logger.info(f"Returning cached guide: {guide_id_str}")
            # Return Pydantic model instance from cached dict
            return TreatmentGuideResponse(**cached_guide)

        # Cache miss, fetch from database
        logger.info(f"Fetching guide from database: {guide_id_str}")
        guide = await get_guide_service().get_guide_by_id(guide_id_str)

        if not guide:
            raise HTTPException(
                status_code=404,
                detail=f"Treatment guide with ID '{guide_id_str}' not found",
            )

        # Convert Pydantic model to dict for caching
        response_data = guide.model_dump(mode="json")

        # Cache the response for 24 hours (86400 seconds)
        await cache_service.set(cache_key, response_data, ttl_seconds=86400)

        # Return Pydantic model instance (FastAPI handles serialization)
        return TreatmentGuideResponse(**response_data)

    except HTTPException:
        raise
    except SupabaseError as e:
        logger.error(f"Database error retrieving guide {guide_id_str}: {str(e)}")
        raise HTTPException(
            status_code=503,
            detail="Database service temporarily unavailable",
        )
    except GuideServiceError as e:
        logger.error(f"Service error retrieving guide {guide_id_str}: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail="Internal server error while processing guide data",
        )
    except Exception as e:
        logger.error(f"Unexpected error retrieving guide {guide_id_str}: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail="Internal server error while retrieving guide",
        )


@router.get("/by-plant/{plant_id}", response_model=TreatmentGuideListResponse)
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
            # Return Pydantic model instance from cached dict
            return TreatmentGuideListResponse(**cached_guides)

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

        # Convert Pydantic models to response models
        response_guides = [
            TreatmentGuideResponse(**guide.model_dump(mode="json"))
            for guide in guides
        ]

        # Create response model instance
        response = TreatmentGuideListResponse(
            plant_id=plant_id,
            disease_filter=disease_name,
            total_results=total_count,
            limit=limit,
            offset=offset,
            guides=response_guides,
        )

        # Cache the response dict for 24 hours
        await cache_service.set(
            cache_key, response.model_dump(mode="json"), ttl_seconds=86400
        )

        # Return Pydantic model instance (FastAPI handles serialization)
        return response

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


@router.post("", response_model=TreatmentGuideResponse, status_code=201)
async def create_guide(
    guide_data: TreatmentGuideCreate,
    current_user: str = Depends(verify_auth_token),
):
    """
    Create a new treatment guide.

    This endpoint creates a new treatment guide with validation,
    stores it in Supabase, and invalidates relevant caches.

    - **guide_data**: Complete guide information including steps
    - **Returns**: Created guide with assigned ID and timestamps
    - **Auth**: Requires authentication (Bearer token)
    """
    try:
        logger.info(
            f"Creating new guide for plant_id: {guide_data.plant_id} "
            f"(user: {current_user[:10]}...)"
        )

        # Create guide in database
        created_guide = await get_guide_service().create_guide(guide_data)

        # Invalidate cache for this plant_id (all related guides are now stale)
        # Pattern matches: guide:plant:{plant_id}:*
        invalidated_count = await cache_service.invalidate_pattern(
            f"guide:plant:{guide_data.plant_id}:*"
        )
        logger.info(
            f"Invalidated {invalidated_count} cache entries for plant_id: {guide_data.plant_id}"
        )

        # Return the created guide as response model
        return TreatmentGuideResponse(**created_guide.model_dump(mode="json"))

    except SupabaseError as e:
        logger.error(f"Database error creating guide: {str(e)}")
        raise HTTPException(
            status_code=503,
            detail="Database service temporarily unavailable",
        )
    except GuideServiceError as e:
        logger.error(f"Service error creating guide: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail="Internal server error while processing guide data",
        )
    except Exception as e:
        logger.error(f"Unexpected error creating guide: {type(e).__name__}: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail="Internal server error while creating guide",
        )


@router.put("/{guide_id}", response_model=TreatmentGuideResponse)
async def update_guide(
    guide_id: UUID,
    guide_update: TreatmentGuideUpdate,
    current_user: str = Depends(verify_auth_token),
):
    """
    Update an existing treatment guide.

    This endpoint updates a guide with the provided fields,
    stores changes in Supabase, and invalidates relevant caches.

    - **guide_id**: UUID of the guide to update
    - **guide_update**: Fields to update (all optional)
    - **Returns**: Updated guide information
    - **Auth**: Requires authentication (Bearer token)
    """
    try:
        # Convert UUID to string for service layer
        guide_id_str = str(guide_id)

        logger.info(f"Updating guide: {guide_id_str} (user: {current_user[:10]}...)")

        # Update guide in database
        updated_guide = await get_guide_service().update_guide(guide_id_str, guide_update)

        if not updated_guide:
            raise HTTPException(
                status_code=404,
                detail=f"Treatment guide with ID '{guide_id_str}' not found",
            )

        # Invalidate caches:
        # 1. Specific guide cache
        guide_cache_key = f"guide:id:{guide_id_str}"
        await cache_service.delete(guide_cache_key)
        logger.info(f"Invalidated guide cache: {guide_cache_key}")

        # 2. Plant-related guides cache (in case plant_id changed or for existing plant_id)
        # Get the plant_id from the updated guide to invalidate its cache
        invalidated_count = await cache_service.invalidate_pattern(
            f"guide:plant:{updated_guide.plant_id}:*"
        )
        logger.info(
            f"Invalidated {invalidated_count} cache entries for plant_id: {updated_guide.plant_id}"
        )

        # Return the updated guide
        return TreatmentGuideResponse(**updated_guide.model_dump(mode="json"))

    except HTTPException:
        raise
    except SupabaseError as e:
        logger.error(f"Database error updating guide {guide_id_str}: {str(e)}")
        raise HTTPException(
            status_code=503,
            detail="Database service temporarily unavailable",
        )
    except GuideServiceError as e:
        logger.error(f"Service error updating guide {guide_id_str}: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail="Internal server error while processing guide data",
        )
    except Exception as e:
        logger.error(
            f"Unexpected error updating guide {guide_id_str}: {type(e).__name__}: {str(e)}"
        )
        raise HTTPException(
            status_code=500,
            detail="Internal server error while updating guide",
        )


@router.delete("/{guide_id}", status_code=204)
async def delete_guide(
    guide_id: UUID,
    current_user: str = Depends(verify_auth_token),
):
    """
    Delete a treatment guide (hard delete).

    This endpoint permanently deletes a guide from Supabase
    and invalidates all relevant caches. The deleted guide object
    is returned by the service to enable atomic cache invalidation
    without race conditions.

    - **guide_id**: UUID of the guide to delete
    - **Returns**: 204 No Content on success
    - **Auth**: Requires authentication (Bearer token)
    """
    try:
        # Convert UUID to string for service layer
        guide_id_str = str(guide_id)

        logger.info(f"Deleting guide: {guide_id_str} (user: {current_user[:10]}...)")

        # Delete guide and get the deleted object (uses Prefer: return=representation)
        # This avoids race condition where guide could be modified between GET and DELETE
        deleted_guide = await get_guide_service().delete_guide(guide_id_str)

        if not deleted_guide:
            # Guide not found
            raise HTTPException(
                status_code=404,
                detail=f"Treatment guide with ID '{guide_id_str}' not found",
            )

        # Invalidate caches using plant_id from the deleted object:
        # 1. Specific guide cache
        guide_cache_key = f"guide:id:{guide_id_str}"
        await cache_service.delete(guide_cache_key)
        logger.info(f"Invalidated guide cache: {guide_cache_key}")

        # 2. Plant-related guides cache
        invalidated_count = await cache_service.invalidate_pattern(
            f"guide:plant:{deleted_guide.plant_id}:*"
        )
        logger.info(
            f"Invalidated {invalidated_count} cache entries for plant_id: {deleted_guide.plant_id}"
        )

        # Return 204 No Content (no response body)
        return None

    except HTTPException:
        raise
    except SupabaseError as e:
        logger.error(f"Database error deleting guide {guide_id_str}: {str(e)}")
        raise HTTPException(
            status_code=503,
            detail="Database service temporarily unavailable",
        )
    except GuideServiceError as e:
        logger.error(f"Service error deleting guide {guide_id_str}: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail="Internal server error while processing guide data",
        )
    except Exception as e:
        logger.error(
            f"Unexpected error deleting guide {guide_id_str}: {type(e).__name__}: {str(e)}"
        )
        raise HTTPException(
            status_code=500,
            detail="Internal server error while deleting guide",
        )



