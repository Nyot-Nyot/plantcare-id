"""Plant collection API routes."""

import logging
from datetime import datetime
from typing import List, Optional
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, Query, status

from backend.auth import verify_auth_token
from backend.models.plant_collection import (
    CareActionRequest,
    CareActionResponse,
    CareHistoryCreate,
    CollectionSyncRequest,
    CollectionSyncResponse,
    HealthStatus,
    PlantCollectionCreate,
    PlantCollectionResponse,
    PlantCollectionUpdate,
)
from backend.services.collection_service import (
    CollectionAccessDeniedError,
    CollectionNotFoundError,
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


async def verify_collection_ownership(
    collection_id: UUID,
    user_id: str = Depends(verify_auth_token),
) -> PlantCollectionResponse:
    """
    Dependency to verify collection exists and user owns it.

    This dependency handles:
    - UUID conversion and validation
    - Collection existence check (404 if not found)
    - Ownership verification (403 if not owner)
    - Error handling for database issues

    Args:
        collection_id: UUID of the collection to verify
        user_id: Authenticated user ID from JWT token

    Returns:
        PlantCollectionResponse if collection exists and user owns it

    Raises:
        HTTPException: 400 (invalid UUID), 404 (not found), 403 (forbidden), 503 (db error)
    """
    try:
        # Convert user_id string to UUID
        user_uuid = UUID(user_id)

        # Fetch collection from service
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
    collection: PlantCollectionResponse = Depends(verify_collection_ownership),
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
    return collection


@router.put("/{collection_id}", response_model=PlantCollectionResponse)
async def update_collection(
    update_data: PlantCollectionUpdate,
    collection: PlantCollectionResponse = Depends(verify_collection_ownership),
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
        # Update collection via service
        logger.info(f"Updating collection {collection.id}")
        updated_collection = await get_collection_service().update_collection(
            collection_id=collection.id, data=update_data
        )

        if not updated_collection:
            # This shouldn't happen since we verified existence in dependency
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Collection with ID '{collection.id}' not found",
            )

        return updated_collection

    except HTTPException:
        raise
    except SupabaseError as e:
        logger.error(f"Database error updating collection {collection.id}: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Database service temporarily unavailable",
        )
    except CollectionServiceError as e:
        logger.error(f"Service error updating collection {collection.id}: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Internal server error while updating collection",
        )
    except Exception as e:
        logger.error(f"Unexpected error updating collection {collection.id}: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Internal server error",
        )


@router.delete("/{collection_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_collection(
    collection: PlantCollectionResponse = Depends(verify_collection_ownership),
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
        # Delete collection via service
        logger.info(f"Deleting collection {collection.id}")
        deleted = await get_collection_service().delete_collection(collection.id)

        if not deleted:
            # This shouldn't happen since we verified existence in dependency
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Collection with ID '{collection.id}' not found",
            )

        # Return 204 No Content (FastAPI handles this with status_code)
        return None

    except HTTPException:
        raise
    except SupabaseError as e:
        logger.error(f"Database error deleting collection {collection.id}: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Database service temporarily unavailable",
        )
    except CollectionServiceError as e:
        logger.error(f"Service error deleting collection {collection.id}: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Internal server error while deleting collection",
        )
    except Exception as e:
        logger.error(f"Unexpected error deleting collection {collection.id}: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Internal server error",
        )


@router.post(
    "/sync",
    response_model=CollectionSyncResponse,
    status_code=status.HTTP_200_OK,
    summary="Sync collections from client",
    description="""
    Bulk upsert collections from client for synchronization.

    **Conflict Resolution (Server Wins):**
    - If a collection with the same ID already exists on server, the server version is kept
    - New collections from client are inserted
    - All synced collections are marked as is_synced=True

    **Request Body:**
    - collections: Array of collection items from client (with optional IDs)

    **Response:**
    - synced_count: Number of collections successfully synced
    - failed_count: Number of collections that failed to sync
    - collections: Server versions of all synced collections

    **Authentication:**
    - Requires valid Bearer token
    - Only syncs collections for the authenticated user
    """,
)
async def sync_collections(
    request: CollectionSyncRequest,
    user_id: str = Depends(verify_auth_token),
    service: CollectionService = Depends(get_collection_service),
) -> CollectionSyncResponse:
    """Sync collections from client to server with conflict resolution."""
    try:
        synced_collections, failed_count = await service.sync_collections(
            user_id=UUID(user_id),
            collections=request.collections,
        )

        return CollectionSyncResponse(
            synced_count=len(synced_collections),
            failed_count=failed_count,
            collections=synced_collections,
        )

    except SupabaseError as e:
        logger.error(f"Database error syncing collections: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Database service temporarily unavailable",
        )
    except CollectionServiceError as e:
        logger.error(f"Service error syncing collections: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Internal server error while syncing collections",
        )
    except Exception as e:
        logger.error(f"Unexpected error syncing collections: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Internal server error",
        )


@router.get(
    "/changes",
    response_model=List[PlantCollectionResponse],
    status_code=status.HTTP_200_OK,
    summary="Get collections changed since timestamp",
    description="""
    Get collections that have been updated since a specific timestamp.

    **Use Case:**
    - Incremental sync to reduce bandwidth usage
    - Only fetch collections that changed since last sync

    **Query Parameters:**
    - since: ISO 8601 timestamp (e.g., "2024-01-01T00:00:00Z")
    - Returns collections with updated_at > since timestamp

    **Response:**
    - Array of collections sorted by updated_at (ascending)
    - Empty array if no changes since timestamp

    **Authentication:**
    - Requires valid Bearer token
    - Only returns collections for the authenticated user
    """,
)
async def get_collections_changes(
    since: datetime = Query(
        ...,
        description="ISO 8601 timestamp - only return collections updated after this time",
        example="2024-01-01T00:00:00Z",
    ),
    user_id: str = Depends(verify_auth_token),
    service: CollectionService = Depends(get_collection_service),
) -> List[PlantCollectionResponse]:
    """Get collections that have been updated since a specific timestamp."""
    try:
        collections = await service.get_collections_by_timestamp(
            user_id=UUID(user_id),
            since_timestamp=since,
        )

        return collections

    except SupabaseError as e:
        logger.error(f"Database error fetching collection changes: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Database service temporarily unavailable",
        )
    except CollectionServiceError as e:
        logger.error(f"Service error fetching collection changes: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Internal server error while fetching collection changes",
        )
    except Exception as e:
        logger.error(f"Unexpected error fetching collection changes: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Internal server error",
        )


@router.post(
    "/{collection_id}/care",
    response_model=CareActionResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Record care action for a collection",
    description="""
    Record a care action (watering, fertilizing, etc.) for a plant collection.

    **What happens:**
    1. Creates a new care_history record
    2. Updates collection's last_care_date to current time (or provided care_date)
    3. Recalculates next_care_date based on care_frequency_days

    **Request Body:**
    - care_type: Type of care (watering, fertilizing, pruning, repotting, pest_control, other)
    - notes: Optional notes about the care action
    - care_date: Optional timestamp (defaults to now if not provided)

    **Response:**
    - care_history: The created care history record
    - collection: The updated collection with new dates

    **Authentication:**
    - Requires valid Bearer token
    - Only collection owner can record care actions
    """,
)
async def record_care_action(
    collection_id: UUID,
    care_request: CareActionRequest,
    user_id: str = Depends(verify_auth_token),
    service: CollectionService = Depends(get_collection_service),
) -> CareActionResponse:
    """Record a care action for a plant collection."""
    try:
        # Default care_date to now if not provided
        care_date = care_request.care_date or datetime.utcnow()

        # Create CareHistoryCreate object
        care_data = CareHistoryCreate(
            collection_id=collection_id,
            care_type=care_request.care_type,
            care_date=care_date,
            notes=care_request.notes,
        )

        # Record care action
        care_history, updated_collection = await service.record_care_action(
            collection_id=collection_id,
            user_id=UUID(user_id),
            care_data=care_data,
        )

        return CareActionResponse(
            care_history=care_history,
            collection=updated_collection,
        )

    except CollectionNotFoundError as e:
        # Collection does not exist
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=str(e),
        )
    except CollectionAccessDeniedError as e:
        # User does not own the collection
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail=str(e),
        )
    except CollectionServiceError as e:
        # Other service errors (validation, parsing, etc.)
        logger.error(f"Service error recording care action: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Internal server error while recording care action",
        )
    except SupabaseError as e:
        logger.error(f"Database error recording care action: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Database service temporarily unavailable",
        )
    except Exception as e:
        logger.error(f"Unexpected error recording care action: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Internal server error",
        )
