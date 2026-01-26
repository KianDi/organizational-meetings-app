-- =============================================
-- MeetingManager: Tasks Table Migration
-- =============================================
-- Creates the tasks table for storing meeting action items
-- extracted by AI or manually added
-- =============================================

-- Create tasks table
CREATE TABLE IF NOT EXISTS tasks (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    meeting_id UUID NOT NULL REFERENCES meetings(id) ON DELETE CASCADE,
    organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    assignee_id UUID REFERENCES auth.users(id),
    due_date TIMESTAMPTZ,
    is_completed BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    extracted_from TEXT,  -- Source text where task was mentioned
    priority TEXT,        -- 'high', 'medium', 'low'
    CONSTRAINT valid_priority CHECK (priority IS NULL OR priority IN ('high', 'medium', 'low'))
);

-- Create index for common queries
CREATE INDEX IF NOT EXISTS idx_tasks_organization ON tasks(organization_id);
CREATE INDEX IF NOT EXISTS idx_tasks_assignee ON tasks(assignee_id);
CREATE INDEX IF NOT EXISTS idx_tasks_meeting ON tasks(meeting_id);
CREATE INDEX IF NOT EXISTS idx_tasks_due_date ON tasks(due_date) WHERE due_date IS NOT NULL;

-- Enable Row Level Security
ALTER TABLE tasks ENABLE ROW LEVEL SECURITY;

-- Members can view all tasks in their organization
CREATE POLICY "tasks_select_policy" ON tasks
    FOR SELECT
    USING (
        organization_id IN (
            SELECT id FROM organizations
            WHERE auth.uid() = ANY(member_ids)
        )
    );

-- Organizers (meeting creators) can insert tasks
CREATE POLICY "tasks_insert_policy" ON tasks
    FOR INSERT
    WITH CHECK (
        meeting_id IN (
            SELECT id FROM meetings
            WHERE created_by_id = auth.uid()
        )
    );

-- Task assignees can update their own task completion status
CREATE POLICY "tasks_update_policy" ON tasks
    FOR UPDATE
    USING (assignee_id = auth.uid())
    WITH CHECK (assignee_id = auth.uid());

-- Meeting creators can delete tasks from their meetings
CREATE POLICY "tasks_delete_policy" ON tasks
    FOR DELETE
    USING (
        meeting_id IN (
            SELECT id FROM meetings
            WHERE created_by_id = auth.uid()
        )
    );
