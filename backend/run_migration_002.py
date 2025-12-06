#!/usr/bin/env python3
"""
Run Migration 002: Create Plant Collections Tables
Execute this script to create plant_collections and care_history tables in Supabase
"""

import os
import sys
from pathlib import Path
from dotenv import load_dotenv
import httpx

# Load environment variables
load_dotenv()

SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_SERVICE_KEY = os.getenv("SUPABASE_SERVICE_KEY")

if not SUPABASE_URL or not SUPABASE_SERVICE_KEY:
    print("❌ Error: SUPABASE_URL and SUPABASE_SERVICE_KEY must be set in .env")
    print("   For service key, go to: Supabase Dashboard > Settings > API > service_role key")
    sys.exit(1)

# Read migration file
migration_file = Path(__file__).parent / "migrations" / "002_create_plant_collections.sql"
if not migration_file.exists():
    print(f"❌ Migration file not found: {migration_file}")
    sys.exit(1)

with open(migration_file, "r") as f:
    sql_content = f.read()

print("=" * 70)
print("🚀 Running Migration 002: Plant Collections Tables")
print("=" * 70)
print(f"📁 File: {migration_file.name}")
print(f"🔗 Supabase URL: {SUPABASE_URL}")
print("=" * 70)

# Execute SQL via Supabase REST API
url = f"{SUPABASE_URL}/rest/v1/rpc/exec_sql"
headers = {
    "apikey": SUPABASE_SERVICE_KEY,
    "Authorization": f"Bearer {SUPABASE_SERVICE_KEY}",
    "Content-Type": "application/json",
}

# Note: Supabase doesn't have direct SQL execution via REST API
# We need to use the SQL editor in Dashboard or use the Supabase CLI
# For now, this script will just display instructions

print("\n⚠️  Manual Execution Required")
print("=" * 70)
print("Supabase REST API doesn't support arbitrary SQL execution.")
print("Please follow these steps:")
print()
print("1. Go to: https://supabase.com/dashboard")
print("2. Select your project: PlantCare.ID")
print("3. Navigate to: SQL Editor")
print("4. Click: + New Query")
print("5. Copy the SQL below and paste it into the editor:")
print("6. Click: Run (or press Ctrl/Cmd + Enter)")
print()
print("=" * 70)
print("📋 SQL TO EXECUTE:")
print("=" * 70)
print(sql_content)
print("=" * 70)
print()
print("✅ After execution, verify with:")
print()
print("SELECT table_name, column_name, data_type")
print("FROM information_schema.columns")
print("WHERE table_name IN ('plant_collections', 'care_history')")
print("ORDER BY table_name, ordinal_position;")
print()
print("=" * 70)
