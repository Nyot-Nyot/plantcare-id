"""Treatment Guide models for PlantCare.ID."""

from datetime import datetime
from typing import List, Literal, Optional
from uuid import UUID

from pydantic import BaseModel, Field, field_validator


class GuideStep(BaseModel):
    """Individual step in a treatment guide."""

    step_number: int = Field(..., ge=1, description="Step order number (1-based)")
    title: str = Field(..., min_length=1, max_length=200, description="Step title")
    description: str = Field(
        ..., min_length=1, max_length=2000, description="Detailed step description"
    )
    image_url: Optional[str] = Field(None, description="URL to step illustration image")
    materials: List[str] = Field(
        default_factory=list, description="Materials needed for this step"
    )
    is_critical: bool = Field(
        default=False, description="Whether this step is critical for success"
    )
    estimated_time: str = Field(
        ..., description="Estimated time for this step (e.g., '5 menit', '1 jam')"
    )

    class Config:
        json_schema_extra = {
            "example": {
                "step_number": 1,
                "title": "Isolasi Tanaman",
                "description": "Pisahkan tanaman yang sakit dari tanaman lain untuk mencegah penyebaran penyakit.",
                "image_url": "https://placehold.co/600x400/27AE60/white?text=Isolasi",
                "materials": ["sarung tangan", "pot terpisah"],
                "is_critical": True,
                "estimated_time": "5 menit",
            }
        }


class TreatmentGuideBase(BaseModel):
    """Base model for treatment guide."""

    plant_id: str = Field(
        ...,
        min_length=1,
        max_length=100,
        description="Plant identifier (e.g., 'general', 'monstera_deliciosa')",
    )
    disease_name: Optional[str] = Field(
        None,
        max_length=200,
        description="Disease name if guide is for disease treatment",
    )
    severity: Literal["low", "medium", "high"] = Field(
        ..., description="Severity level of the issue"
    )
    guide_type: Literal["identification", "disease_treatment"] = Field(
        ..., description="Type of guide"
    )
    steps: List[GuideStep] = Field(
        ..., min_length=1, max_length=10, description="List of treatment steps"
    )
    materials: List[str] = Field(
        default_factory=list, description="All materials needed for the guide"
    )
    estimated_duration_minutes: Optional[int] = Field(
        None,
        ge=0,
        description="Estimated total duration in minutes for calculations",
    )
    estimated_duration_text: Optional[str] = Field(
        None,
        max_length=100,
        description="Human-readable duration (e.g., '2-3 minggu', '1 bulan')",
    )

    @field_validator("steps")
    @classmethod
    def validate_step_numbers(cls, steps: List[GuideStep]) -> List[GuideStep]:
        """Ensure step numbers are sequential starting from 1."""
        if not steps:
            raise ValueError("At least one step is required")

        expected_numbers = list(range(1, len(steps) + 1))
        actual_numbers = sorted([step.step_number for step in steps])

        if actual_numbers != expected_numbers:
            raise ValueError(
                f"Step numbers must be sequential from 1 to {len(steps)}. "
                f"Got: {actual_numbers}"
            )

        return steps


class TreatmentGuide(TreatmentGuideBase):
    """Treatment guide model (from database)."""

    id: UUID = Field(..., description="Unique guide identifier")
    created_at: datetime = Field(..., description="Creation timestamp")
    updated_at: datetime = Field(..., description="Last update timestamp")

    class Config:
        from_attributes = True
        json_schema_extra = {
            "example": {
                "id": "550e8400-e29b-41d4-a716-446655440000",
                "plant_id": "general",
                "disease_name": "Leaf Spot",
                "severity": "medium",
                "guide_type": "disease_treatment",
                "steps": [
                    {
                        "step_number": 1,
                        "title": "Isolasi Tanaman",
                        "description": "Pisahkan tanaman yang sakit dari tanaman lain.",
                        "image_url": "https://placehold.co/600x400",
                        "materials": ["sarung tangan"],
                        "is_critical": True,
                        "estimated_time": "5 menit",
                    }
                ],
                "materials": ["sarung tangan", "fungisida"],
                "estimated_duration_minutes": 20160,
                "estimated_duration_text": "2-3 minggu",
                "created_at": "2025-12-05T10:00:00Z",
                "updated_at": "2025-12-05T10:00:00Z",
            }
        }


class TreatmentGuideCreate(TreatmentGuideBase):
    """Model for creating a new treatment guide."""

    pass


class TreatmentGuideUpdate(BaseModel):
    """Model for updating an existing treatment guide (all fields optional)."""

    plant_id: Optional[str] = Field(None, min_length=1, max_length=100)
    disease_name: Optional[str] = Field(None, max_length=200)
    severity: Optional[Literal["low", "medium", "high"]] = None
    guide_type: Optional[Literal["identification", "disease_treatment"]] = None
    steps: Optional[List[GuideStep]] = Field(None, min_length=1, max_length=10)
    materials: Optional[List[str]] = None
    estimated_duration_minutes: Optional[int] = Field(None, ge=0)
    estimated_duration_text: Optional[str] = Field(None, max_length=100)

    @field_validator("steps")
    @classmethod
    def validate_step_numbers(cls, steps: Optional[List[GuideStep]]) -> Optional[List[GuideStep]]:
        """Ensure step numbers are sequential starting from 1 if provided."""
        if steps is None:
            return None

        if not steps:
            raise ValueError("If providing steps, at least one step is required")

        expected_numbers = list(range(1, len(steps) + 1))
        actual_numbers = sorted([step.step_number for step in steps])

        if actual_numbers != expected_numbers:
            raise ValueError(
                f"Step numbers must be sequential from 1 to {len(steps)}. "
                f"Got: {actual_numbers}"
            )

        return steps


class TreatmentGuideResponse(BaseModel):
    """API response model for treatment guide."""

    id: str = Field(..., description="Guide UUID as string")
    plant_id: str
    disease_name: Optional[str]
    severity: str
    guide_type: str
    steps: List[GuideStep]
    materials: List[str]
    estimated_duration_minutes: Optional[int]
    estimated_duration_text: Optional[str]
    created_at: str = Field(..., description="ISO format timestamp")
    updated_at: str = Field(..., description="ISO format timestamp")

    class Config:
        json_schema_extra = {
            "example": {
                "id": "550e8400-e29b-41d4-a716-446655440000",
                "plant_id": "general",
                "disease_name": "Leaf Spot",
                "severity": "medium",
                "guide_type": "disease_treatment",
                "steps": [
                    {
                        "step_number": 1,
                        "title": "Isolasi Tanaman",
                        "description": "Pisahkan tanaman yang sakit.",
                        "image_url": "https://placehold.co/600x400",
                        "materials": ["sarung tangan"],
                        "is_critical": True,
                        "estimated_time": "5 menit",
                    }
                ],
                "materials": ["sarung tangan", "fungisida"],
                "estimated_duration_minutes": 20160,
                "estimated_duration_text": "2-3 minggu",
                "created_at": "2025-12-05T10:00:00Z",
                "updated_at": "2025-12-05T10:00:00Z",
            }
        }


class TreatmentGuideListResponse(BaseModel):
    """API response model for paginated list of treatment guides."""

    plant_id: str = Field(..., description="Plant identifier")
    disease_filter: Optional[str] = Field(None, description="Disease name filter applied")
    total_results: int = Field(..., ge=0, description="Total number of guides matching the query")
    limit: int = Field(..., ge=1, le=100, description="Maximum results per page")
    offset: int = Field(..., ge=0, description="Number of results skipped")
    guides: List[TreatmentGuideResponse] = Field(..., description="List of treatment guides")

    class Config:
        json_schema_extra = {
            "example": {
                "plant_id": "general",
                "disease_filter": None,
                "total_results": 4,
                "limit": 10,
                "offset": 0,
                "guides": [
                    {
                        "id": "550e8400-e29b-41d4-a716-446655440000",
                        "plant_id": "general",
                        "disease_name": "Leaf Spot",
                        "severity": "medium",
                        "guide_type": "disease_treatment",
                        "steps": [],
                        "materials": ["fungisida"],
                        "estimated_duration_minutes": 20160,
                        "estimated_duration_text": "2-3 minggu",
                        "created_at": "2025-12-05T10:00:00Z",
                        "updated_at": "2025-12-05T10:00:00Z",
                    }
                ],
            }
        }
