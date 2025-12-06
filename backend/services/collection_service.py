"""Collection service for interacting with Supabase plant_collections table."""

import logging
import os
from datetime import datetime, timedelta
from typing import List, Optional
from uuid import UUID

import httpx
from dotenv import load_dotenv
from pydantic import ValidationError

from backend.models.plant_collection import (
    CareHistoryCreate,
    CareHistoryResponse,
    CollectionSyncItem,
    PlantCollectionCreate,
    PlantCollectionResponse,
    PlantCollectionUpdate,
)

load_dotenv()

logger = logging.getLogger(__name__)


class SupabaseError(Exception):
    """Custom exception for Supabase database errors."""

    def __init__(self, message: str, status_code: int = None, response_text: str = None):
        self.status_code = status_code
        self.response_text = response_text
        super().__init__(message)


class CollectionServiceError(Exception):
    """Custom exception for CollectionService errors."""
    pass


class CollectionService:
    """Service for managing plant collections in Supabase."""

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
                "CollectionService not properly configured. "
                "SUPABASE_URL and SUPABASE_ANON_KEY must be set."
            )

    async def create_collection(
        self, user_id: UUID, data: PlantCollectionCreate
    ) -> PlantCollectionResponse:
        """
        Create a new plant collection entry.

        Args:
            user_id: UUID of the authenticated user
            data: PlantCollectionCreate model with collection data

        Returns:
            PlantCollectionResponse model instance

        Raises:
            SupabaseError: If database error occurs
            CollectionServiceError: If data parsing fails
        """
        self._check_configured()
        try:
            # Calculate next_care_date if not provided
            next_care_date = data.next_care_date
            if not next_care_date and data.identified_at and data.care_frequency_days:
                next_care_date = data.identified_at + timedelta(
                    days=data.care_frequency_days
                )

            # Prepare payload with user_id
            payload = data.model_dump(exclude_unset=True, exclude_none=True)
            payload["user_id"] = str(user_id)
            if next_care_date:
                payload["next_care_date"] = next_care_date.isoformat()
            if payload.get("identified_at"):
                payload["identified_at"] = payload["identified_at"].isoformat()
            if payload.get("last_care_date"):
                payload["last_care_date"] = payload["last_care_date"].isoformat()

            async with httpx.AsyncClient() as client:
                response = await client.post(
                    f"{self.base_url}/plant_collections",
                    headers=self.headers,
                    json=payload,
                )

                if response.status_code == 201:
                    created_data = response.json()
                    if isinstance(created_data, list) and len(created_data) > 0:
                        created_data = created_data[0]

                    try:
                        return PlantCollectionResponse(**created_data)
                    except ValidationError as e:
                        logger.error(f"Failed to parse created collection: {e}")
                        raise CollectionServiceError(
                            f"Invalid collection data from database: {e}"
                        )
                else:
                    logger.error(
                        f"Supabase error creating collection: "
                        f"{response.status_code} - {response.text}"
                    )
                    raise SupabaseError(
                        f"Database error while creating collection",
                        status_code=response.status_code,
                        response_text=response.text,
                    )

        except (SupabaseError, CollectionServiceError):
            raise
        except Exception as e:
            logger.error(f"Unexpected error creating collection: {str(e)}")
            raise CollectionServiceError(f"Failed to create collection: {str(e)}")

    async def get_collection_by_id(
        self, collection_id: UUID
    ) -> Optional[PlantCollectionResponse]:
        """
        Get a plant collection by its UUID.

        Args:
            collection_id: UUID of the collection

        Returns:
            PlantCollectionResponse model instance or None if not found

        Raises:
            SupabaseError: If database error occurs
            CollectionServiceError: If data parsing fails
        """
        self._check_configured()
        try:
            async with httpx.AsyncClient() as client:
                response = await client.get(
                    f"{self.base_url}/plant_collections",
                    headers=self.headers,
                    params={"id": f"eq.{collection_id}", "select": "*"},
                )

                if response.status_code == 200:
                    data = response.json()
                    if data and len(data) > 0:
                        collection_data = data[0]

                        try:
                            return PlantCollectionResponse(**collection_data)
                        except ValidationError as e:
                            logger.error(
                                f"Failed to parse collection {collection_id}: {e}"
                            )
                            raise CollectionServiceError(
                                f"Invalid collection data from database: {e}"
                            )
                    return None
                elif response.status_code == 404:
                    return None
                else:
                    logger.error(
                        f"Supabase error getting collection {collection_id}: "
                        f"{response.status_code} - {response.text}"
                    )
                    raise SupabaseError(
                        f"Database error while fetching collection",
                        status_code=response.status_code,
                        response_text=response.text,
                    )

        except (SupabaseError, CollectionServiceError):
            raise
        except Exception as e:
            logger.error(
                f"Unexpected error getting collection {collection_id}: {str(e)}"
            )
            raise CollectionServiceError(f"Failed to fetch collection: {str(e)}")

    async def get_collections_by_user(
        self,
        user_id: UUID,
        health_status: Optional[str] = None,
        limit: int = 20,
        offset: int = 0,
    ) -> tuple[List[PlantCollectionResponse], int]:
        """
        Get all plant collections for a specific user with total count.

        Args:
            user_id: User identifier (UUID)
            health_status: Optional filter by health status (healthy, needs_attention, sick)
            limit: Maximum number of results (default 20, max 100)
            offset: Number of results to skip for pagination

        Returns:
            Tuple of (list of PlantCollectionResponse models, total count)

        Raises:
            SupabaseError: If database error occurs
            CollectionServiceError: If data parsing fails
        """
        self._check_configured()
        try:
            # Validate limit
            limit = min(max(1, limit), 100)

            params = {
                "user_id": f"eq.{user_id}",
                "select": "*",
                "limit": str(limit),
                "offset": str(offset),
                "order": "next_care_date.asc.nullslast,created_at.desc",
            }

            if health_status:
                params["health_status"] = f"eq.{health_status}"

            # Add Prefer header to get total count
            headers_with_count = {**self.headers, "Prefer": "count=exact"}

            async with httpx.AsyncClient() as client:
                response = await client.get(
                    f"{self.base_url}/plant_collections",
                    headers=headers_with_count,
                    params=params,
                )

                # Supabase returns 206 Partial Content when using Prefer: count=exact
                # with pagination, or 200 OK otherwise
                if response.status_code in (200, 206):
                    collections_data = response.json()

                    # Extract total count from Content-Range header
                    # Format: "0-19/42" means items 0-19 out of total 42
                    total_count = 0
                    content_range = response.headers.get("Content-Range")
                    if content_range:
                        try:
                            total_str = content_range.split("/")[-1]
                            total_count = int(total_str) if total_str != "*" else len(
                                collections_data
                            )
                        except (IndexError, ValueError):
                            total_count = len(collections_data)
                    else:
                        total_count = len(collections_data)

                    # Parse each collection
                    collections = []
                    for collection_data in collections_data:
                        try:
                            collections.append(
                                PlantCollectionResponse(**collection_data)
                            )
                        except ValidationError as e:
                            logger.warning(
                                f"Skipping invalid collection data: {e}"
                            )
                            continue

                    return collections, total_count
                else:
                    logger.error(
                        f"Supabase error getting collections for user {user_id}: "
                        f"{response.status_code} - {response.text}"
                    )
                    raise SupabaseError(
                        f"Database error while fetching collections",
                        status_code=response.status_code,
                        response_text=response.text,
                    )

        except (SupabaseError, CollectionServiceError):
            raise
        except Exception as e:
            logger.error(
                f"Unexpected error getting collections for user {user_id}: {str(e)}"
            )
            raise CollectionServiceError(f"Failed to fetch collections: {str(e)}")

    async def update_collection(
        self, collection_id: UUID, data: PlantCollectionUpdate
    ) -> Optional[PlantCollectionResponse]:
        """
        Update a plant collection.

        Args:
            collection_id: UUID of the collection to update
            data: PlantCollectionUpdate model with fields to update

        Returns:
            Updated PlantCollectionResponse or None if not found

        Raises:
            SupabaseError: If database error occurs
            CollectionServiceError: If data parsing fails
        """
        self._check_configured()
        try:
            # Only include fields that were explicitly set
            payload = data.model_dump(exclude_unset=True, exclude_none=True)

            # Convert datetime objects to ISO format strings
            if "last_care_date" in payload and payload["last_care_date"]:
                payload["last_care_date"] = payload["last_care_date"].isoformat()
            if "next_care_date" in payload and payload["next_care_date"]:
                payload["next_care_date"] = payload["next_care_date"].isoformat()

            # If no fields to update, return None
            if not payload:
                logger.warning(
                    f"No fields to update for collection {collection_id}"
                )
                return await self.get_collection_by_id(collection_id)

            async with httpx.AsyncClient() as client:
                response = await client.patch(
                    f"{self.base_url}/plant_collections",
                    headers=self.headers,
                    params={"id": f"eq.{collection_id}"},
                    json=payload,
                )

                if response.status_code == 200:
                    updated_data = response.json()
                    if updated_data and len(updated_data) > 0:
                        collection_data = updated_data[0]

                        try:
                            return PlantCollectionResponse(**collection_data)
                        except ValidationError as e:
                            logger.error(
                                f"Failed to parse updated collection {collection_id}: {e}"
                            )
                            raise CollectionServiceError(
                                f"Invalid collection data from database: {e}"
                            )
                    return None
                elif response.status_code == 404:
                    return None
                else:
                    logger.error(
                        f"Supabase error updating collection {collection_id}: "
                        f"{response.status_code} - {response.text}"
                    )
                    raise SupabaseError(
                        f"Database error while updating collection",
                        status_code=response.status_code,
                        response_text=response.text,
                    )

        except (SupabaseError, CollectionServiceError):
            raise
        except Exception as e:
            logger.error(
                f"Unexpected error updating collection {collection_id}: {str(e)}"
            )
            raise CollectionServiceError(f"Failed to update collection: {str(e)}")

    async def delete_collection(self, collection_id: UUID) -> bool:
        """
        Delete a plant collection (hard delete).

        Args:
            collection_id: UUID of the collection to delete

        Returns:
            True if deletion successful, False if not found

        Raises:
            SupabaseError: If database error occurs
        """
        self._check_configured()
        try:
            # Use Prefer: return=minimal to avoid returning deleted rows
            headers_no_return = {**self.headers}
            headers_no_return["Prefer"] = "return=minimal"

            async with httpx.AsyncClient() as client:
                response = await client.delete(
                    f"{self.base_url}/plant_collections",
                    headers=headers_no_return,
                    params={"id": f"eq.{collection_id}"},
                )

                if response.status_code == 204:
                    # 204 No Content means successful deletion
                    return True
                elif response.status_code == 404:
                    # Not found
                    return False
                else:
                    logger.error(
                        f"Supabase error deleting collection {collection_id}: "
                        f"{response.status_code} - {response.text}"
                    )
                    raise SupabaseError(
                        f"Database error while deleting collection",
                        status_code=response.status_code,
                        response_text=response.text,
                    )

        except SupabaseError:
            raise
        except Exception as e:
            logger.error(
                f"Unexpected error deleting collection {collection_id}: {str(e)}"
            )
            raise CollectionServiceError(f"Failed to delete collection: {str(e)}")

    async def sync_collections(
        self, user_id: UUID, collections: List[CollectionSyncItem]
    ) -> tuple[List[PlantCollectionResponse], int]:
        """
        Bulk upsert collections from client for sync.

        Server-wins conflict resolution:
        - If collection with same id exists on server, keep server version
        - New collections from client are inserted
        - All synced collections marked as is_synced=True

        Args:
            user_id: UUID of the authenticated user
            collections: List of CollectionSyncItem from client

        Returns:
            Tuple of (synced_collections_list, failed_count)

        Raises:
            SupabaseError: If database error occurs
            CollectionServiceError: If data parsing fails
        """
        self._check_configured()
        synced_collections: List[PlantCollectionResponse] = []
        failed_count = 0

        for item in collections:
            try:
                # Check if collection already exists on server
                if item.id:
                    existing = await self.get_collection_by_id(item.id)
                    if existing:
                        # Server wins - use existing server version
                        synced_collections.append(existing)
                        continue

                # Create new collection (upsert)
                create_data = PlantCollectionCreate(
                    plant_id=item.plant_id,
                    common_name=item.common_name,
                    scientific_name=item.scientific_name,
                    image_url=item.image_url,
                    identified_at=item.identified_at,
                    last_care_date=item.last_care_date,
                    next_care_date=item.next_care_date,
                    care_frequency_days=item.care_frequency_days,
                    health_status=item.health_status,
                    notes=item.notes,
                )

                created = await self.create_collection(user_id, create_data)
                synced_collections.append(created)

            except Exception as e:
                logger.error(f"Failed to sync collection item: {str(e)}")
                failed_count += 1
                continue

        return synced_collections, failed_count

    async def get_collections_by_timestamp(
        self, user_id: UUID, since_timestamp: datetime
    ) -> List[PlantCollectionResponse]:
        """
        Get collections that have been updated since a specific timestamp.

        Used for incremental sync to reduce bandwidth usage.

        Args:
            user_id: UUID of the authenticated user
            since_timestamp: Only return collections with updated_at > this timestamp

        Returns:
            List of PlantCollectionResponse objects

        Raises:
            SupabaseError: If database error occurs
            CollectionServiceError: If data parsing fails
        """
        self._check_configured()
        try:
            # Query collections with updated_at > since_timestamp
            params = {
                "user_id": f"eq.{user_id}",
                "updated_at": f"gt.{since_timestamp.isoformat()}",
                "order": "updated_at.asc",
            }

            async with httpx.AsyncClient() as client:
                response = await client.get(
                    f"{self.base_url}/plant_collections",
                    headers=self.headers,
                    params=params,
                )

                if response.status_code == 200:
                    data = response.json()
                    try:
                        return [PlantCollectionResponse(**item) for item in data]
                    except ValidationError as e:
                        logger.error(f"Failed to parse collections: {e}")
                        raise CollectionServiceError(
                            f"Invalid collection data from database: {e}"
                        )
                else:
                    logger.error(
                        f"Supabase error fetching collections by timestamp: "
                        f"{response.status_code} - {response.text}"
                    )
                    raise SupabaseError(
                        f"Database error while fetching collections",
                        status_code=response.status_code,
                        response_text=response.text,
                    )

        except (SupabaseError, CollectionServiceError):
            raise
        except Exception as e:
            logger.error(
                f"Unexpected error fetching collections by timestamp: {str(e)}"
            )
            raise CollectionServiceError(
                f"Failed to fetch collections by timestamp: {str(e)}"
            )

    async def record_care_action(
        self, collection_id: UUID, user_id: UUID, care_data: CareHistoryCreate
    ) -> tuple[CareHistoryResponse, PlantCollectionResponse]:
        """
        Record a care action for a collection using an atomic PostgreSQL function.

        This method calls a PostgreSQL function that atomically:
        1. Verifies collection exists and user owns it
        2. Creates a new care_history record
        3. Updates the collection's last_care_date to current time
        4. Recalculates next_care_date based on care_frequency_days

        All operations are performed within a single database transaction,
        ensuring data consistency even if errors occur.

        Args:
            collection_id: UUID of the collection
            user_id: UUID of the authenticated user (for ownership check)
            care_data: CareHistoryCreate model with care action details

        Returns:
            Tuple of (CareHistoryResponse, updated PlantCollectionResponse)

        Raises:
            SupabaseError: If database error occurs
            CollectionServiceError: If collection not found or ownership mismatch
        """
        self._check_configured()

        try:
            # Prepare RPC payload
            rpc_payload = {
                "p_collection_id": str(collection_id),
                "p_user_id": str(user_id),
                "p_care_type": care_data.care_type,
                "p_notes": care_data.notes,
            }

            # Add care_date if provided, otherwise PostgreSQL function uses NOW()
            if care_data.care_date:
                rpc_payload["p_care_date"] = care_data.care_date.isoformat()

            async with httpx.AsyncClient() as client:
                # Call PostgreSQL function via Supabase RPC
                response = await client.post(
                    f"{self.base_url}/rpc/record_care_action",
                    headers=self.headers,
                    json=rpc_payload,
                )

                if response.status_code != 200:
                    error_text = response.text
                    logger.error(
                        f"Supabase RPC error recording care action: "
                        f"{response.status_code} - {error_text}"
                    )

                    # Check for specific error messages
                    if "not found or access denied" in error_text.lower():
                        raise CollectionServiceError(
                            f"Collection {collection_id} not found or access denied"
                        )

                    raise SupabaseError(
                        "Database error while recording care action",
                        status_code=response.status_code,
                        response_text=error_text,
                    )

                result = response.json()

                # Parse the result from the PostgreSQL function
                try:
                    care_history = CareHistoryResponse(**result["care_history"])
                    updated_collection = PlantCollectionResponse(**result["collection"])
                    return care_history, updated_collection
                except (KeyError, ValidationError) as e:
                    logger.error(f"Failed to parse RPC response: {e}")
                    raise CollectionServiceError(
                        f"Invalid data from database: {e}"
                    )

        except (SupabaseError, CollectionServiceError):
            raise
        except Exception as e:
            logger.error(f"Unexpected error recording care action: {str(e)}")
            raise CollectionServiceError(f"Failed to record care action: {str(e)}")
