-- Migration: Create transactional function for recording care actions
-- Purpose: Ensure atomicity when creating care_history and updating plant_collections
-- Date: 2025-12-06

-- Drop function if exists (for re-running migration)
DROP FUNCTION IF EXISTS record_care_action(UUID, UUID, TEXT, TEXT, TIMESTAMPTZ);

-- Create function to atomically record care action
CREATE OR REPLACE FUNCTION record_care_action(
    p_collection_id UUID,
    p_user_id UUID,
    p_care_type TEXT,
    p_notes TEXT DEFAULT NULL,
    p_care_date TIMESTAMPTZ DEFAULT NOW()
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_collection RECORD;
    v_care_history RECORD;
    v_next_care_date TIMESTAMPTZ;
    v_result JSON;
BEGIN
    -- Step 1: Verify collection exists and user owns it
    SELECT * INTO v_collection
    FROM plant_collections
    WHERE id = p_collection_id
    AND user_id = p_user_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Collection not found or access denied'
            USING ERRCODE = 'P0001';
    END IF;

    -- Step 2: Insert care history record
    INSERT INTO care_history (
        collection_id,
        care_type,
        notes,
        care_date
    ) VALUES (
        p_collection_id,
        p_care_type,
        p_notes,
        p_care_date
    )
    RETURNING * INTO v_care_history;

    -- Step 3: Calculate next care date
    IF v_collection.care_frequency_days IS NOT NULL THEN
        v_next_care_date := NOW() + (v_collection.care_frequency_days || ' days')::INTERVAL;
    ELSE
        v_next_care_date := NULL;
    END IF;

    -- Step 4: Update collection with new care dates
    UPDATE plant_collections
    SET 
        last_care_date = NOW(),
        next_care_date = v_next_care_date,
        updated_at = NOW()
    WHERE id = p_collection_id
    RETURNING * INTO v_collection;

    -- Step 5: Build JSON response with both care_history and updated collection
    v_result := json_build_object(
        'care_history', row_to_json(v_care_history),
        'collection', row_to_json(v_collection)
    );

    RETURN v_result;
EXCEPTION
    WHEN OTHERS THEN
        -- Log error details and re-raise
        RAISE EXCEPTION 'Error recording care action: %', SQLERRM
            USING ERRCODE = SQLSTATE;
END;
$$;

-- Add comment explaining the function
COMMENT ON FUNCTION record_care_action IS 
'Atomically records a care action by creating a care_history entry and updating the plant_collections table. 
All operations are performed within a single transaction to ensure data consistency.';

-- Grant execute permission to authenticated users
-- Note: Adjust role name based on your Supabase setup (typically "authenticated" or "anon")
GRANT EXECUTE ON FUNCTION record_care_action TO authenticated;
