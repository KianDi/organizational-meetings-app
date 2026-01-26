-- =============================================
-- MeetingManager: Tasks Table Migration
-- =============================================
-- Creates the tasks table for storing meeting action items
-- extracted by AI or manually added
-- =============================================

-- Create tasks table
CREATE TABLE IF NOT EXISTS public.tasks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    meeting_id UUID NOT NULL REFERENCES public.meetings(id) ON DELETE CASCADE,
    organization_id UUID NOT NULL REFERENCES public.organizations(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    assignee_id UUID REFERENCES public.users(id) ON DELETE SET NULL,
    due_date TIMESTAMPTZ,
    is_completed BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    extracted_from TEXT,  -- Context snippet from document where task was mentioned
    priority TEXT,        -- 'high', 'medium', 'low'

    -- Ensure task belongs to same org as meeting
    CONSTRAINT fk_task_org_matches_meeting
        CHECK (organization_id = (SELECT organization_id FROM meetings WHERE id = meeting_id))
);

-- Create indexes for common queries
CREATE INDEX IF NOT EXISTS idx_tasks_meeting_id ON public.tasks(meeting_id);
CREATE INDEX IF NOT EXISTS idx_tasks_organization_id ON public.tasks(organization_id);
CREATE INDEX IF NOT EXISTS idx_tasks_assignee_id ON public.tasks(assignee_id);
CREATE INDEX IF NOT EXISTS idx_tasks_due_date ON public.tasks(due_date) WHERE due_date IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_tasks_is_completed ON public.tasks(is_completed);

-- Enable Row Level Security
ALTER TABLE public.tasks ENABLE ROW LEVEL SECURITY;

-- RLS Policy: Users can view tasks for their organization's meetings
CREATE POLICY "Users can view tasks for their organization"
    ON public.tasks
    FOR SELECT
    USING (
        organization_id IN (
            SELECT organization_id
            FROM public.organization_members
            WHERE user_id = auth.uid()
        )
    );

-- RLS Policy: Users can create tasks for their organization's meetings
CREATE POLICY "Users can create tasks for their organization"
    ON public.tasks
    FOR INSERT
    WITH CHECK (
        organization_id IN (
            SELECT organization_id
            FROM public.organization_members
            WHERE user_id = auth.uid()
        )
    );

-- RLS Policy: Users can update tasks in their organization
CREATE POLICY "Users can update tasks in their organization"
    ON public.tasks
    FOR UPDATE
    USING (
        organization_id IN (
            SELECT organization_id
            FROM public.organization_members
            WHERE user_id = auth.uid()
        )
    )
    WITH CHECK (
        organization_id IN (
            SELECT organization_id
            FROM public.organization_members
            WHERE user_id = auth.uid()
        )
    );

-- RLS Policy: Users can delete tasks in their organization
CREATE POLICY "Users can delete tasks in their organization"
    ON public.tasks
    FOR DELETE
    USING (
        organization_id IN (
            SELECT organization_id
            FROM public.organization_members
            WHERE user_id = auth.uid()
        )
    );

-- Grant permissions
GRANT SELECT, INSERT, UPDATE, DELETE ON public.tasks TO authenticated;
GRANT SELECT ON public.tasks TO anon;

-- Add comment for documentation
COMMENT ON TABLE public.tasks IS 'Action items and tasks extracted from meetings or manually created';
COMMENT ON COLUMN public.tasks.extracted_from IS 'Original text snippet from meeting document where task was mentioned';
COMMENT ON COLUMN public.tasks.priority IS 'Task priority: high, medium, or low';
