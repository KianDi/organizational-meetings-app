# Student Organization Meeting Manager

## What This Is

An iOS mobile app for student organizations to manage weekly meetings. Members check in via the app, organizers upload meeting documents from Google Docs, and AI generates summaries with extracted tasks and action items. The app complements existing Google Docs workflows by providing better organization, visibility, and quick-read summaries without requiring members to parse full meeting documents.

## Core Value

Keeping members informed through AI-powered meeting summaries and reliable attendance tracking, so everyone knows what's happening and what their tasks are without reading full meeting documents.

## Requirements

### Validated

(None yet — ship to validate)

### Active

- [ ] User authentication via email/password
- [ ] Organization creation and management (creator becomes admin/leader)
- [ ] Invite links or codes for members to join organizations
- [ ] Simple check-in button for meeting attendance
- [ ] Upload Google Docs meeting minutes to the app
- [ ] AI-powered summary generation from uploaded documents
- [ ] Extract positions, tasks, and decisions from meeting minutes
- [ ] Task/to-do list generated from extracted action items
- [ ] Calendar showing both meeting schedules and deadlines
- [ ] Role-based permissions (organizers vs general members)
- [ ] Organizers can set meeting times and start meetings
- [ ] Meeting agendas and summaries viewing for all members

### Out of Scope

- Complex integrations (calendar sync, email, third-party services) — v1 keeps it simple and focused
- Advanced analytics on attendance patterns or trends — basic attendance tracking only for v1
- Real-time collaborative features (live updates, chat, collaborative editing) — meetings happen in person, app is for organization and follow-up
- Location-based automatic check-in — future enhancement, v1 uses simple manual button
- Android support — iOS only for v1 to focus development
- In-app document editing — Google Docs remains the source of truth for live meeting notes

## Context

The student organization currently uses Google Docs for each weekly meeting, with attendance tracked manually within those documents. This workflow works during live meetings but creates challenges:
- Members who miss meetings struggle to catch up quickly
- Tasks and action items are buried in long documents
- No centralized view of attendance over time
- Important dates and deadlines get lost

Google Docs will continue to be used for live note-taking during meetings (the familiar collaborative editing workflow), but this app provides a companion experience for:
- Quick-read AI summaries for members who want the highlights
- Automatic extraction of tasks and responsibilities
- Reliable attendance tracking via simple check-in
- Centralized calendar of meetings and deadlines

The app supports multiple organizations (not just one), allowing different student orgs to use the same app with their own separate spaces. Each organization has its own admin (the creator) who can set meeting times, start meetings, and upload documents.

## Constraints

- **Platform**: iOS only — focusing on single platform for v1 to accelerate development
- **Integration**: Must support Google Docs upload — that's the existing source of truth and workflow
- **AI Processing**: Essential for v1 — requires budget/API access for AI service (OpenAI, Anthropic, or similar)
- **Authentication**: Standard email/password — no complex SSO or school domain verification for v1

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Google Docs upload rather than in-app editing | Preserves existing workflow where Docs are used during live meetings; app is companion, not replacement | — Pending |
| Simple button check-in for v1 | Quick to implement and validate, location-based check-in deferred to future version | — Pending |
| Multi-organization architecture | Allows app to be used by different student orgs, not just one specific group | — Pending |
| AI summary as essential v1 feature | Core value proposition is keeping members informed without reading full docs; this differentiates from simple note storage | — Pending |

---
*Last updated: 2026-01-14 after initialization*
