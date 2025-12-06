"""Plant collection API routes."""

import logging
from typing import Optional
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, Query, status

from backend.auth import verify_auth_token
from backend.models.plant_collection import (
    HealthStatus,
    PlantCollectionCreate,
    PlantCollectionResponse,
    PlantCollectionUpdate,
)
from backend.services.collection_service import (
    CollectionService,
    CollectionServiceError,
    SupabaseError,
)

logger = logging.getLogger(__name__)

router = APIRouter()

# Lazy initialization of collection service
_collection_service = None


def get_collection_service() -> CollectionService:
    """Get or create collection service instance (lazy loading)."""
    global _collection_service
    if _collection_service is None:
        _collection_service = CollectionService()
    return _collection_service


@router.post(
    "",
    response_model=PlantCollectionResponse,
    status_code=status.HTTP_201_CREATED,
)
async def create_collection(
    collection_data: PlantCollectionCreate,
    user_id: str = Depends(verify_auth_token),
):
    """
    Create a new plant collection entry.

    This endpoint allows authenticated users to add a plant to their collection
    after identifying it. The next_care_date is automatically calculated if not provided.

    - **Authentication**: Required (Bearer token)
    - **plant_id**: Plant identifier from identification service
    - **common_name**: Plant's common name
    - **scientific_name**: Plant's scientific name (optional)
    - **image_url**: URL to plant photo
    - **identified_at**: When the plant was identified
    - **care_frequency_days**: Days between care actions
    - **health_status**: Current health status (healthy, needs_attention, sick)
    - **Returns**: Created collection with auto-generated ID and calculated fields
    """
    try:
        # Convert user_id string to UUID
        user_uuid = UUID(user_id)

        # Create collection via service
        logger.info(f"Creating collection for user {user_id}, plant {collection_data.plant_id}")
        collection = await get_collection_service().create_collection(
            user_id=user_uuid, data=collection_data
        )

        return collection

    except ValueError as e:
        logger.error(f"Invalid UUID format: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid user ID format",
        )
    except SupabaseError as e:
        logger.error(f"Database error creating collection: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Database service temporarily unavailable",
        )
    except CollectionServiceError as e:
        logger.error(f"Service error creating collection: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Internal server error while creating collection",
        )
    except Exception as e:
        logger.error(f"Unexpected error creating collection: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Internal server error",
        )


@router.get("", response_model=dict)
async def get_user_collections(
    health_status: Optional[HealthStatus] = Query(
        None,
        description="Filter by health status (healthy, needs_attention, sick)",
    ),
    limit: int = Query(20, ge=1, le=100, description="Number of results to return"),
    offset: int = Query(0, ge=0, description="Number of results to skip"),
    user_id: str = Depends(verify_auth_token),
):
    """
    Get all plant collections for the authenticated user.

    This endpoint returns a paginated list of plants in the user's collection,
    sorted by next care date (soonest first), then by creation date.

    - **Authentication**: Required (Bearer token)
    - **health_status**: Optional filter (healthy, needs_attention, sick)
    - **limit**: Maximum results (1-100, default 20)
    - **offset**: Results to skip for pagination (default 0)
    - **Returns**: List of collections with total count and pagination info
    """
    try:
        # Convert user_id string to UUID
        user_uuid = UUID(user_id)

        # Fetch collections from service
        # FastAPI automatically validates health_status against HealthStatus type
        logger.info(
            f"Fetching collections for user {user_id} "
            f"(health_status: {health_status}, limit: {limit}, offset: {offset})"
        )
        collections, total_count = await get_collection_service().get_collections_by_user(
            user_id=user_uuid,
            health_status=health_status,
            limit=limit,
            offset=offset,
        )

        # Return paginated response
        return {
            "data": [c.model_dump(mode="json") for c in collections],
            "total": total_count,
            "limit": limit,
            "offset": offset,
            "has_more": (offset + limit) < total_count,
        }

    except ValueError as e:
        logger.error(f"Invalid UUID format: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid user ID format",
        )
    except HTTPException:
        raise
    except SupabaseError as e:
        logger.error(f"Database error fetching collections: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Database service temporarily unavailable",
        )
    except CollectionServiceError as e:
        logger.error(f"Service error fetching collections: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Internal server error while fetching collections",
        )
    except Exception as e:
        logger.error(f"Unexpected error fetching collections: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Internal server error",
        )


@router.get("/{collection_id}", response_model=PlantCollectionResponse)
async def get_collection_by_id(
    collection_id: UUID,
    user_id: str = Depends(verify_auth_token),
):
    """
    Get a specific plant collection by ID.

    This endpoint returns detailed information about a single collection entry.
    Users can only access their own collections.

    - **Authentication**: Required (Bearer token)
    - **collection_id**: UUID of the collection entry
    - **Returns**: Complete collection information
    - **Authorization**: Users can only access their own collections
    """
    try:
        # Convert user_id string to UUID
        user_uuid = UUID(user_id)

        # Fetch collection from service
        logger.info(f"Fetching collection {collection_id} for user {user_id}")
        collection = await get_collection_service().get_collection_by_id(collection_id)

        if not collection:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Collection with ID '{collection_id}' not found",
            )

        # Check ownership
        if collection.user_id != user_uuid:
            logger.warning(
                f"User {user_id} attempted to access collection {collection_id} "
                f"owned by {collection.user_id}"
            )
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="You don't have permission to access this collection",
            )

        return collection

    except ValueError as e:
        logger.error(f"Invalid UUID format: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid ID format",
        )
    except HTTPException:
        raise
    except SupabaseError as e:
        logger.error(f"Database error fetching collection {collection_id}: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Database service temporarily unavailable",
        )
    except CollectionServiceError as e:
        logger.error(f"Service error fetching collection {collection_id}: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Internal server error while fetching collection",
        )
    except Exception as e:
        logger.error(f"Unexpected error fetching collection {collection_id}: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Internal server error",
        )


@router.put("/{collection_id}", response_model=PlantCollectionResponse)
async def update_collection(
    collection_id: UUID,
    update_data: PlantCollectionUpdate,
    user_id: str = Depends(verify_auth_token),
):
    """
    Update a plant collection entry.

    This endpoint allows authenticated users to update their plant collection entries.
    Partial updates are supported - only provided fields will be updated.
    The updated_at timestamp is automatically updated.

    - **Authentication**: Required (Bearer token)
    - **collection_id**: UUID of the collection to update
    - **Authorization**: Users can only update their own collections
    - **Returns**: Updated collection information
    """
    try:
        # Convert user_id string to UUID
        user_uuid = UUID(user_id)

        # First, check if collection exists and verify ownership
        existing_collection = await get_collection_service().get_collection_by_id(
            collection_id
        )

        if not existing_collection:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Collection with ID '{collection_id}' not found",
            )

        # Check ownership
        if existing_collection.user_id != user_uuid:
            logger.warning(
                f"User {user_id} attempted to update collection {collection_id} "
                f"owned by {existing_collection.user_id}"
            )
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="You don't have permission to update this collection",
            )

        # Update collection via service
        logger.info(f"Updating collection {collection_id} for user {user_id}")
        updated_collection = await get_collection_service().update_collection(
            collection_id=collection_id, data=update_data
        )

        if not updated_collection:
            # This shouldn't happen since we checked existence above
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Collection with ID '{collection_id}' not found",
            )

        return updated_collection

    except ValueError as e:
        logger.error(f"Invalid UUID format: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid ID format",
        )
    except HTTPException:
        raise
    except SupabaseError as e:
        logger.error(f"Database error updating collection {collection_id}: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Database service temporarily unavailable",
        )
    except CollectionServiceError as e:
        logger.error(f"Service error updating collection {collection_id}: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Internal server error while updating collection",
        )
    except Exception as e:
        logger.error(f"Unexpected error updating collection {collection_id}: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Internal server error",
        )


@router.delete("/{collection_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_collection(
    collection_id: UUID,
    user_id: str = Depends(verify_auth_token),
):
    """
    Delete a plant collection entry.

    This endpoint performs a hard delete of the collection entry.
    Related care_history entries are automatically deleted via CASCADE constraint.

    - **Authentication**: Required (Bearer token)
    - **collection_id**: UUID of the collection to delete
    - **Authorization**: Users can only delete their own collections
    - **Returns**: 204 No Content on success
    """
    try:
        # Convert user_id string to UUID
        user_uuid = UUID(user_id)

        # First, check if collection exists and verify ownership
        existing_collection = await get_collection_service().get_collection_by_id(
            collection_id
        )

        if not existing_collection:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Collection with ID '{collection_id}' not found",
            )

        # Check ownership
        if existing_collection.user_id != user_uuid:
            logger.warning(
                f"User {user_id} attempted to delete collection {collection_id} "
                f"owned by {existing_collection.user_id}"
            )
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="You don't have permission to delete this collection",
            )

        # Delete collection via service
        logger.info(f"Deleting collection {collection_id} for user {user_id}")
        deleted = await get_collection_service().delete_collection(collection_id)

        if not deleted:
            # This shouldn't happen since we checked existence above
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Collection with ID '{collection_id}' not found",
            )

        # Return 204 No Content (FastAPI handles this with status_code)
        return None

    except ValueError as e:
        logger.error(f"Invalid UUID format: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid ID format",
        )
    except HTTPException:
        raise
    except SupabaseError as e:
        logger.error(f"Database error deleting collection {collection_id}: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Database service temporarily unavailable",
        )
    except CollectionServiceError as e:
        logger.error(f"Service error deleting collection {collection_id}: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Internal server error while deleting collection",
        )
    except Exception as e:
        logger.error(f"Unexpected error deleting collection {collection_id}: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Internal server error",
        )
