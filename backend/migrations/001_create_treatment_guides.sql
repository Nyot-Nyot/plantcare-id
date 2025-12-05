-- Sprint 3: Treatment Guides Table
-- Creates table for storing step-by-step treatment guides

-- Enable UUID extension (required for uuid_generate_v4())
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

CREATE TABLE IF NOT EXISTS treatment_guides (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    plant_id TEXT NOT NULL,
    disease_name TEXT,
    severity TEXT CHECK (severity IN ('low', 'medium', 'high')),
    guide_type TEXT NOT NULL CHECK (guide_type IN ('identification', 'disease_treatment')),
    steps JSONB NOT NULL,
    materials JSONB,
    estimated_duration_minutes INTEGER,
    estimated_duration_text TEXT,
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
COMMENT ON COLUMN treatment_guides.estimated_duration_minutes IS 'Estimated duration in minutes for structured calculations (e.g., 1440 for 1 day, 10080 for 1 week)';
COMMENT ON COLUMN treatment_guides.estimated_duration_text IS 'Human-readable duration text for display (e.g., "2-3 minggu", "1-2 bulan")';

-- Create function to automatically update updated_at timestamp
-- This function can be reused for other tables (e.g., plant_collections)
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to call the function on UPDATE
CREATE TRIGGER update_treatment_guides_updated_at
    BEFORE UPDATE ON treatment_guides
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();
