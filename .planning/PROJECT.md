# Student Organization Meeting Manager

## What This Is

An iOS mobile app for student organizations to manage weekly meetings. Members check in via the app, organizers upload meeting documents from Google Docs, and AI generates summaries with extracted tasks and action items. The app complements existing Google Docs workflows by providing better organization, visibility, and quick-read summaries without requiring members to parse full meeting documents.

## Current State

**Status:** v1.0 MVP shipped (2026-01-30)

Production-ready iOS app with complete authentication, organization management, meeting check-in, AI-powered document processing, task management, and calendar views. Built with iOS 17+, Swift 6.0, SwiftUI, Supabase (PostgreSQL + Auth), and DeepSeek AI via OpenRouter. 81 unit tests, comprehensive error handling, and full setup documentation included.

**What works:** All core features shipped and validated. Users can authenticate, create/join organizations via 6-character invite codes, check into meetings, upload PDF/text documents for AI processing, view generated summaries and extracted tasks, manage task completion, and view calendars with meetings and deadlines.

**What's next:** v1.1 planned features include Google Docs direct integration, push notifications for meetings, and member analytics.

## Core Value

Keeping members informed through AI-powered meeting summaries and reliable attendance tracking, so everyone knows what's happening and what their tasks are without reading full meeting documents.

## Requirements

### Validated

- [x] User authentication via email/password — v1.0
- [x] Organization creation and management (creator becomes admin/leader) — v1.0
- [x] Invite links or codes for members to join organizations — v1.0
- [x] Simple check-in button for meeting attendance — v1.0
- [x] Upload meeting documents (PDF/text, Google Docs indirect) — v1.0
- [x] AI-powered summary generation from uploaded documents — v1.0
- [x] Extract positions, tasks, and decisions from meeting minutes — v1.0
- [x] Task/to-do list generated from extracted action items — v1.0
- [x] Calendar showing both meeting schedules and deadlines — v1.0
- [x] Role-based permissions (organizers vs general members) — v1.0
- [x] Organizers can set meeting times and start meetings — v1.0
- [x] Meeting agendas and summaries viewing for all members — v1.0

### Active

(None — v1.0 shipped all planned features)

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
| PDF/text upload for v1 (not direct Google Docs) | Simpler implementation path, validates core AI processing workflow; direct integration deferred to v1.1 | ✓ Good — Users can export Docs as PDF, AI processing works well |
| Simple button check-in for v1 | Quick to implement and validate, location-based check-in deferred to future version | ✓ Good — Haptic feedback, idempotent check-in, clean UX |
| Multi-organization architecture | Allows app to be used by different student orgs, not just one specific group | ✓ Good — Bidirectional tracking, RLS policies, seamless switching |
| AI summary as essential v1 feature | Core value proposition is keeping members informed without reading full docs; this differentiates from simple note storage | ✓ Good — DeepSeek via OpenRouter provides 10x cost savings |
| Supabase over Firebase | Open-source flexibility, PostgreSQL RLS, simpler auth integration | ✓ Good — Actor-based services, clean async/await patterns |
| 6-character invite codes | Balance between typing convenience and collision avoidance | ✓ Good — UUID prefix approach, ShareSheet integration |
| @Observable over ObservableObject | Modern iOS 17+ pattern with better performance | ✓ Good — Cleaner state management, automatic UI updates |

---
*Last updated: 2026-01-30 after v1.0 milestone*
