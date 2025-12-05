"""Cache service using Redis with in-memory fallback."""

import json
import logging
import os
from typing import Any, Optional

from dotenv import load_dotenv

try:
    import redis.asyncio as aioredis  # type: ignore
except ImportError:
    aioredis = None

load_dotenv()

logger = logging.getLogger(__name__)


class CacheService:
    """
    Cache service with Redis backend and in-memory fallback.

    Uses Redis when available, falls back to in-memory dict when not configured.
    """

    def __init__(self):
        """Initialize cache service (Redis or in-memory fallback)."""
        self.redis_url = os.getenv("REDIS_URL")
        self.redis_client: Optional[Any] = None
        self.memory_cache: dict[str, tuple[float, Any]] = {}

        if self.redis_url and aioredis:
            try:
                self.redis_client = aioredis.from_url(
                    self.redis_url,
                    encoding="utf-8",
                    decode_responses=True,
                )
                logger.info("Redis cache initialized successfully")
            except Exception as e:
                logger.warning(
                    f"Failed to initialize Redis, using in-memory cache: {e}"
                )
                self.redis_client = None
        else:
            logger.warning(
                "REDIS_URL not set or redis not installed, using in-memory cache"
            )

    async def get(self, key: str) -> Optional[Any]:
        """
        Get a value from cache.

        Args:
            key: Cache key

        Returns:
            Cached value or None if not found/expired
        """
        try:
            if self.redis_client:
                # Use Redis
                value = await self.redis_client.get(key)
                if value:
                    logger.debug(f"Cache HIT (Redis): {key}")
                    return json.loads(value)
                logger.debug(f"Cache MISS (Redis): {key}")
                return None
            else:
                # Use in-memory cache
                import time

                if key in self.memory_cache:
                    expiry, value = self.memory_cache[key]
                    if time.time() < expiry:
                        logger.debug(f"Cache HIT (memory): {key}")
                        return value
                    else:
                        # Expired, remove it
                        del self.memory_cache[key]

                logger.debug(f"Cache MISS (memory): {key}")
                return None

        except Exception as e:
            logger.error(f"Error getting from cache ({key}): {e}")
            return None

    async def set(
        self, key: str, value: Any, ttl_seconds: int = 86400
    ) -> bool:
        """
        Set a value in cache with TTL.

        Args:
            key: Cache key
            value: Value to cache (will be JSON serialized)
            ttl_seconds: Time to live in seconds (default 24 hours)

        Returns:
            True if successful, False otherwise
        """
        try:
            if self.redis_client:
                # Use Redis
                json_value = json.dumps(value)
                await self.redis_client.set(key, json_value, ex=ttl_seconds)
                logger.debug(
                    f"Cache SET (Redis): {key} (TTL: {ttl_seconds}s)"
                )
                return True
            else:
                # Use in-memory cache
                import time

                expiry = time.time() + ttl_seconds
                self.memory_cache[key] = (expiry, value)
                logger.debug(
                    f"Cache SET (memory): {key} (TTL: {ttl_seconds}s)"
                )
                return True

        except Exception as e:
            logger.error(f"Error setting cache ({key}): {e}")
            return False

    async def delete(self, key: str) -> bool:
        """
        Delete a key from cache.

        Args:
            key: Cache key to delete

        Returns:
            True if successful, False otherwise
        """
        try:
            if self.redis_client:
                # Use Redis
                await self.redis_client.delete(key)
                logger.debug(f"Cache DELETE (Redis): {key}")
                return True
            else:
                # Use in-memory cache
                if key in self.memory_cache:
                    del self.memory_cache[key]
                    logger.debug(f"Cache DELETE (memory): {key}")
                return True

        except Exception as e:
            logger.error(f"Error deleting from cache ({key}): {e}")
            return False

    async def invalidate_pattern(self, pattern: str) -> int:
        """
        Invalidate all keys matching a pattern.

        Args:
            pattern: Pattern to match (e.g., "guide:plant:*")

        Returns:
            Number of keys deleted
        """
        try:
            if self.redis_client:
                # Use Redis SCAN for pattern matching
                keys_deleted = 0
                async for key in self.redis_client.scan_iter(match=pattern):
                    await self.redis_client.delete(key)
                    keys_deleted += 1
                logger.info(
                    f"Cache INVALIDATE (Redis): {pattern} ({keys_deleted} keys)"
                )
                return keys_deleted
            else:
                # Use in-memory cache
                keys_to_delete = [
                    key
                    for key in self.memory_cache.keys()
                    if self._match_pattern(key, pattern)
                ]
                for key in keys_to_delete:
                    del self.memory_cache[key]
                logger.info(
                    f"Cache INVALIDATE (memory): {pattern} ({len(keys_to_delete)} keys)"
                )
                return len(keys_to_delete)

        except Exception as e:
            logger.error(f"Error invalidating pattern ({pattern}): {e}")
            return 0

    def _match_pattern(self, key: str, pattern: str) -> bool:
        """Simple pattern matching for in-memory cache (supports * wildcard)."""
        import re

        regex_pattern = pattern.replace("*", ".*")
        return bool(re.match(f"^{regex_pattern}$", key))

    async def close(self):
        """Close Redis connection if active."""
        if self.redis_client:
            try:
                await self.redis_client.close()
                logger.info("Redis connection closed")
            except Exception as e:
                logger.error(f"Error closing Redis connection: {e}")


# Global cache instance
cache_service = CacheService()
