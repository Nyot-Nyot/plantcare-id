"""Plant Collection models for PlantCare.ID."""

from datetime import datetime
from typing import Literal, Optional
from uuid import UUID

from pydantic import BaseModel, Field, field_validator


# Type aliases for health status
HealthStatus = Literal["healthy", "needs_attention", "sick"]


class PlantCollectionBase(BaseModel):
    """Base model for plant collection with common fields."""

    plant_id: str = Field(
        ...,
        min_length=1,
        max_length=255,
        description="Identifier for the plant species/type",
    )
    common_name: str = Field(
        ...,
        min_length=1,
        max_length=255,
        description="Common name of the plant (e.g., 'Snake Plant')",
    )
    scientific_name: Optional[str] = Field(
        None,
        max_length=255,
        description="Scientific name of the plant (e.g., 'Sansevieria trifasciata')",
    )
    image_url: Optional[str] = Field(
        None,
        max_length=2048,
        description="URL to the plant image",
    )
    identified_at: datetime = Field(
        ...,
        description="Timestamp when the plant was identified/added",
    )
    last_care_date: Optional[datetime] = Field(
        None,
        description="Last time the plant was cared for",
    )
    next_care_date: Optional[datetime] = Field(
        None,
        description="Next scheduled care date",
    )
    care_frequency_days: int = Field(
        default=7,
        ge=1,
        le=365,
        description="Number of days between care reminders (1-365)",
    )
    health_status: Optional[HealthStatus] = Field(
        default="healthy",
        description="Current health status of the plant",
    )
    notes: Optional[str] = Field(
        None,
        max_length=2000,
        description="User notes about the plant",
    )


class PlantCollectionCreate(PlantCollectionBase):
    """Model for creating a new plant collection entry."""

    @field_validator("common_name", "plant_id")
    @classmethod
    def validate_not_empty(cls, v: str) -> str:
        """Ensure required string fields are not just whitespace."""
        if not v or not v.strip():
            raise ValueError("Field cannot be empty or whitespace")
        return v.strip()

    @field_validator("scientific_name", "image_url", "notes")
    @classmethod
    def validate_not_empty_if_provided(cls, v: Optional[str]) -> Optional[str]:
        """Ensure optional string fields are not just whitespace if provided."""
        if v is not None and (not v or not v.strip()):
            raise ValueError("Field cannot be empty or whitespace")
        return v.strip() if v else None


class PlantCollectionUpdate(BaseModel):
    """Model for updating an existing plant collection entry (partial updates)."""

    common_name: Optional[str] = Field(
        None,
        min_length=1,
        max_length=255,
    )
    scientific_name: Optional[str] = Field(
        None,
        max_length=255,
    )
    image_url: Optional[str] = Field(
        None,
        max_length=2048,
    )
    last_care_date: Optional[datetime] = None
    next_care_date: Optional[datetime] = None
    care_frequency_days: Optional[int] = Field(
        None,
        ge=1,
        le=365,
    )
    health_status: Optional[HealthStatus] = None
    notes: Optional[str] = Field(
        None,
        max_length=2000,
    )

    @field_validator("common_name", "scientific_name", "image_url", "notes")
    @classmethod
    def validate_not_empty_if_provided(cls, v: Optional[str]) -> Optional[str]:
        """Ensure string fields are not just whitespace if provided."""
        if v is not None and (not v or not v.strip()):
            raise ValueError("Field cannot be empty or whitespace")
        return v.strip() if v else None


class PlantCollectionResponse(PlantCollectionBase):
    """Model for plant collection responses (includes DB fields)."""

    id: UUID = Field(..., description="Unique identifier for this collection entry")
    user_id: UUID = Field(..., description="ID of the user who owns this collection")
    is_synced: bool = Field(
        default=False,
        description="Whether this entry has been synced with the server",
    )
    created_at: datetime = Field(..., description="Timestamp when entry was created")
    updated_at: datetime = Field(..., description="Timestamp when entry was last updated")

    class Config:
        """Pydantic configuration."""

        from_attributes = True  # Enable ORM mode for SQLAlchemy compatibility


class CareHistoryBase(BaseModel):
    """Base model for care history records."""

    care_date: datetime = Field(
        ...,
        description="Date and time when care was performed",
    )
    care_type: Literal[
        "watering",
        "fertilizing",
        "pruning",
        "repotting",
        "pest_control",
        "other",
    ] = Field(
        ...,
        description="Type of care action performed",
    )
    notes: Optional[str] = Field(
        None,
        max_length=1000,
        description="Additional notes about the care action",
    )


class CareHistoryCreate(CareHistoryBase):
    """Model for creating a new care history record."""

    collection_id: UUID = Field(
        ...,
        description="ID of the plant collection this care action belongs to",
    )


class CareHistoryResponse(CareHistoryBase):
    """Model for care history responses."""

    id: UUID = Field(..., description="Unique identifier for this care history record")
    collection_id: UUID = Field(..., description="ID of the related plant collection")
    created_at: datetime = Field(..., description="Timestamp when record was created")

    class Config:
        """Pydantic configuration."""

        from_attributes = True
