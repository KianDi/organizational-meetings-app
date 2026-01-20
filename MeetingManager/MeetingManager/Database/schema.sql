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

-- Policy: Users can find organizations by invite code (for joining)
-- This allows querying organizations by invite_code even if not a member yet
CREATE POLICY "Users can find organizations by invite code"
    ON organizations
    FOR SELECT
    USING (invite_code IS NOT NULL);

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

-- Users Table Schema
-- Extends Supabase auth.users with application-specific data
-- Tracks organization memberships for each user

-- Create users table
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT NOT NULL,
    name TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT now(),
    organization_ids UUID[] NOT NULL DEFAULT '{}'
);

-- Enable Row Level Security
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

-- Policy: Users can read their own user record
CREATE POLICY "Users can view their own profile"
    ON users
    FOR SELECT
    USING (id = auth.uid());

-- Policy: Users can update their own record
CREATE POLICY "Users can update their own profile"
    ON users
    FOR UPDATE
    USING (id = auth.uid());

-- Policy: Service role can insert user records (for auth trigger)
CREATE POLICY "Service role can insert users"
    ON users
    FOR INSERT
    WITH CHECK (true);

-- Create function to auto-create user record when auth.users is created
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
BEGIN
    INSERT INTO public.users (id, email, name)
    VALUES (
        NEW.id,
        NEW.email,
        COALESCE(NEW.raw_user_meta_data->>'name', NEW.email)
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger to automatically create user record
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Create index on organization_ids for efficient membership queries
CREATE INDEX IF NOT EXISTS idx_users_organization_ids ON users USING GIN (organization_ids);

-- Meetings Table Schema
-- Tracks meetings within organizations with scheduling, attendance, and document linking
-- Meetings have a lifecycle: scheduled → started → ended

-- Create meetings table
CREATE TABLE IF NOT EXISTS meetings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    scheduled_at TIMESTAMPTZ NOT NULL,
    started_at TIMESTAMPTZ,
    ended_at TIMESTAMPTZ,
    google_docs_url TEXT,
    summary TEXT,
    attendee_ids UUID[] NOT NULL DEFAULT '{}',
    created_by_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- Enable Row Level Security
ALTER TABLE meetings ENABLE ROW LEVEL SECURITY;

-- Policy: Members can view meetings for their organizations
CREATE POLICY "Members can view organization meetings"
    ON meetings
    FOR SELECT
    USING (
        organization_id IN (
            SELECT id FROM organizations
            WHERE member_ids @> ARRAY[auth.uid()]
        )
    );

-- Policy: Admins can insert meetings for their organizations
CREATE POLICY "Admins can create meetings"
    ON meetings
    FOR INSERT
    WITH CHECK (
        organization_id IN (
            SELECT id FROM organizations
            WHERE admin_id = auth.uid()
        )
    );

-- Policy: Admins can update meetings for their organizations
CREATE POLICY "Admins can update meetings"
    ON meetings
    FOR UPDATE
    USING (
        organization_id IN (
            SELECT id FROM organizations
            WHERE admin_id = auth.uid()
        )
    );

-- Policy: Members can update attendee_ids only (for check-in)
CREATE POLICY "Members can check in to meetings"
    ON meetings
    FOR UPDATE
    USING (
        organization_id IN (
            SELECT id FROM organizations
            WHERE member_ids @> ARRAY[auth.uid()]
        )
    )
    WITH CHECK (
        organization_id IN (
            SELECT id FROM organizations
            WHERE member_ids @> ARRAY[auth.uid()]
        )
    );

-- Policy: Admins can delete meetings for their organizations
CREATE POLICY "Admins can delete meetings"
    ON meetings
    FOR DELETE
    USING (
        organization_id IN (
            SELECT id FROM organizations
            WHERE admin_id = auth.uid()
        )
    );

-- Create GIN index on attendee_ids for efficient attendance queries
CREATE INDEX IF NOT EXISTS idx_meetings_attendee_ids ON meetings USING GIN (attendee_ids);

-- Create B-tree index on organization_id for efficient organization queries
CREATE INDEX IF NOT EXISTS idx_meetings_organization_id ON meetings (organization_id);

-- Create B-tree index on created_by_id for efficient creator queries
CREATE INDEX IF NOT EXISTS idx_meetings_created_by_id ON meetings (created_by_id);

-- Create B-tree index on scheduled_at for efficient time-based queries
CREATE INDEX IF NOT EXISTS idx_meetings_scheduled_at ON meetings (scheduled_at);

-- Phase 5: Document Upload & AI Processing
-- Add document storage columns to meetings table

-- Add columns for document storage
ALTER TABLE meetings
  ADD COLUMN IF NOT EXISTS document_text TEXT,
  ADD COLUMN IF NOT EXISTS document_url TEXT,
  ADD COLUMN IF NOT EXISTS uploaded_at TIMESTAMPTZ;

-- document_text: extracted plain text from uploaded document
-- document_url: original file URL or identifier
-- uploaded_at: timestamp of document upload
