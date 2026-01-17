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
