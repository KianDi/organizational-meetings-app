-- Organizations Table Schema for Supabase
-- This file should be executed in the Supabase SQL Editor
-- to create the organizations table with proper RLS policies

-- Create organizations table
CREATE TABLE IF NOT EXISTS organizations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    admin_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT now(),
    invite_code TEXT UNIQUE,
    member_ids UUID[] NOT NULL DEFAULT '{}'
);

-- Enable Row Level Security
ALTER TABLE organizations ENABLE ROW LEVEL SECURITY;

-- Policy: Users can read organizations they're a member of
CREATE POLICY "Users can view their organizations"
    ON organizations
    FOR SELECT
    USING (member_ids @> ARRAY[auth.uid()]);

-- Policy: Admins can update their own organizations
CREATE POLICY "Admins can update their organizations"
    ON organizations
    FOR UPDATE
    USING (admin_id = auth.uid());

-- Policy: Admins can delete their own organizations
CREATE POLICY "Admins can delete their organizations"
    ON organizations
    FOR DELETE
    USING (admin_id = auth.uid());

-- Policy: Any authenticated user can create organizations
CREATE POLICY "Authenticated users can create organizations"
    ON organizations
    FOR INSERT
    WITH CHECK (auth.uid() IS NOT NULL);

-- Create index on member_ids for efficient membership queries
CREATE INDEX IF NOT EXISTS idx_organizations_member_ids ON organizations USING GIN (member_ids);

-- Create index on admin_id for efficient admin queries
CREATE INDEX IF NOT EXISTS idx_organizations_admin_id ON organizations (admin_id);

-- Create index on invite_code for efficient join queries
CREATE INDEX IF NOT EXISTS idx_organizations_invite_code ON organizations (invite_code);
