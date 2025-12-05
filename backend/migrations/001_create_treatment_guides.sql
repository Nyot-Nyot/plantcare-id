-- Sprint 3: Treatment Guides Table
-- Creates table for storing step-by-step treatment guides

CREATE TABLE IF NOT EXISTS treatment_guides (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    plant_id TEXT NOT NULL,
    disease_name TEXT,
    severity TEXT CHECK (severity IN ('low', 'medium', 'high')),
    guide_type TEXT NOT NULL CHECK (guide_type IN ('identification', 'disease_treatment')),
    steps JSONB NOT NULL,
    materials JSONB,
    estimated_duration TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_guides_plant_id ON treatment_guides(plant_id);
CREATE INDEX IF NOT EXISTS idx_guides_disease ON treatment_guides(disease_name);
CREATE INDEX IF NOT EXISTS idx_guides_type ON treatment_guides(guide_type);

-- Add comment for documentation
COMMENT ON TABLE treatment_guides IS 'Stores step-by-step treatment guides for plants and diseases';
COMMENT ON COLUMN treatment_guides.steps IS 'JSONB array of step objects with structure: {step_number, title, description, image_url, materials, is_critical, estimated_time}';
COMMENT ON COLUMN treatment_guides.materials IS 'JSONB array of required materials for the entire guide';
