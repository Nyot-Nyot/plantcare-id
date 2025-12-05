-- Sprint 3: Plant Collections Tables
-- Creates tables for user's plant collection and care history

-- Plant Collections Table
CREATE TABLE IF NOT EXISTS plant_collections (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    plant_id TEXT NOT NULL,
    common_name TEXT NOT NULL,
    scientific_name TEXT,
    image_url TEXT,
    identified_at TIMESTAMPTZ NOT NULL,
    last_care_date TIMESTAMPTZ,
    next_care_date TIMESTAMPTZ,
    care_frequency_days INT DEFAULT 7 CHECK (care_frequency_days > 0),
    health_status TEXT CHECK (health_status IN ('healthy', 'needs_attention', 'sick')),
    notes TEXT,
    is_synced BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create indexes for plant_collections
CREATE INDEX IF NOT EXISTS idx_collections_user ON plant_collections(user_id);
CREATE INDEX IF NOT EXISTS idx_collections_next_care ON plant_collections(next_care_date);
CREATE INDEX IF NOT EXISTS idx_collections_synced ON plant_collections(is_synced);
CREATE INDEX IF NOT EXISTS idx_collections_health ON plant_collections(health_status);

-- Care History Table
CREATE TABLE IF NOT EXISTS care_history (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    collection_id UUID NOT NULL REFERENCES plant_collections(id) ON DELETE CASCADE,
    care_date TIMESTAMPTZ NOT NULL,
    care_type TEXT NOT NULL CHECK (care_type IN ('watering', 'fertilizing', 'pruning', 'repotting', 'pest_control', 'other')),
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create index for care_history
CREATE INDEX IF NOT EXISTS idx_care_history_collection ON care_history(collection_id);
CREATE INDEX IF NOT EXISTS idx_care_history_date ON care_history(care_date DESC);

-- Add comments for documentation
COMMENT ON TABLE plant_collections IS 'Stores user plant collections with care tracking information';
COMMENT ON COLUMN plant_collections.care_frequency_days IS 'Number of days between care reminders';
COMMENT ON COLUMN plant_collections.is_synced IS 'Flag to track if local changes have been synced to server';

COMMENT ON TABLE care_history IS 'Tracks history of care actions performed on plants';
COMMENT ON COLUMN care_history.care_type IS 'Type of care action: watering, fertilizing, pruning, repotting, pest_control, or other';
