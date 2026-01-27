-- Fix tasks table RLS policy to allow updates
-- Drop the old restrictive policy
DROP POLICY IF EXISTS "tasks_update_policy" ON tasks;

-- Create new policy that allows:
-- 1. Task assignees to update their own tasks
-- 2. Meeting creators to update tasks from their meetings
-- 3. Organization members to update tasks in their organization
CREATE POLICY "tasks_update_policy" ON tasks
    FOR UPDATE
    USING (
        -- Task assignee can update
        assignee_id = auth.uid()
        OR
        -- Meeting creator can update
        meeting_id IN (
            SELECT id FROM meetings
            WHERE created_by_id = auth.uid()
        )
        OR
        -- Organization members can update
        organization_id IN (
            SELECT id FROM organizations
            WHERE auth.uid() = ANY(member_ids)
        )
    )
    WITH CHECK (
        -- Same conditions for the new values
        assignee_id = auth.uid()
        OR
        meeting_id IN (
            SELECT id FROM meetings
            WHERE created_by_id = auth.uid()
        )
        OR
        organization_id IN (
            SELECT id FROM organizations
            WHERE auth.uid() = ANY(member_ids)
        )
    );
