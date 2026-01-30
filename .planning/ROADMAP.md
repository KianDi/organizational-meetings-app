# Roadmap: Student Organization Meeting Manager

## Overview

Building an iOS app that transforms how student organizations manage weekly meetings. Starting with project foundation and authentication, we'll layer on organization management, meeting check-ins, and the core AI-powered document processing. The journey culminates in task management and calendar views, with a final polish phase ensuring production readiness.

## Domain Expertise

None

## Phases

**Phase Numbering:**
- Integer phases (1, 2, 3): Planned milestone work
- Decimal phases (2.1, 2.2): Urgent insertions (marked with INSERTED)

Decimal phases appear between their surrounding integers in numeric order.

- [x] **Phase 1: Foundation & Project Setup** - iOS project initialization, dependencies, and core architecture
- [x] **Phase 2: Authentication System** - Email/password auth with user management
- [x] **Phase 3: Organization Management** - Create orgs, invite system, member roles
- [x] **Phase 4: Meeting Management** - Schedule meetings, check-in system, attendance tracking
- [x] **Phase 5: Document Upload & AI Processing** - PDF/text upload, AI summary generation, task extraction
- [x] **Phase 6: Task & Calendar Views** - Task list UI, calendar with meetings and deadlines
- [x] **Phase 7: Polish & Testing** - UI refinement, error handling, testing

## Phase Details

### Phase 1: Foundation & Project Setup
**Goal**: iOS project initialized with core architecture, data models, and dependencies configured
**Depends on**: Nothing (first phase)
**Research**: Unlikely (iOS project setup, established patterns)
**Plans**: 3 plans

Plans:
- [x] 01-01: Initialize iOS project and configure dependencies
- [x] 01-02: Create core data models (User, Organization, Meeting, Task)
- [x] 01-03: Setup navigation structure and app architecture

### Phase 2: Authentication System
**Goal**: Users can sign up, log in, and manage their accounts with email/password
**Depends on**: Phase 1
**Research**: Likely (authentication architecture and library choice)
**Research topics**: Swift authentication libraries, secure credential storage (Keychain), backend auth service selection (Firebase, Supabase, custom)
**Plans**: 4 plans

Plans:
- [x] 02-01: Implement authentication backend service integration
- [x] 02-02: Implement secure credential storage with Keychain
- [x] 02-03: Create login and signup UI screens
- [x] 02-04: Add session management and auth state handling

### Phase 3: Organization Management
**Goal**: Users can create organizations, generate invite links, and manage member roles
**Depends on**: Phase 2
**Research**: Unlikely (internal data models building on auth from Phase 2)
**Plans**: 4 plans

Plans:
- [x] 03-01: Organization creation and admin assignment
- [x] 03-02: Invite link/code generation and joining flow
- [x] 03-03: Member list and role management UI
- [x] 03-04: Organization state integration and navigation

### Phase 4: Meeting Management
**Goal**: Organizers can schedule meetings, members can check in, attendance is tracked
**Depends on**: Phase 3
**Research**: Unlikely (internal features using established patterns)
**Plans**: 4 plans

Plans:
- [x] 04-01: Meeting creation and scheduling for organizers
- [x] 04-02: Simple check-in button and attendance recording
- [x] 04-03: Meeting list view and detail screens
- [x] 04-04: Meeting state management and reactive UI integration

### Phase 5: Document Upload & AI Processing
**Goal**: Organizers upload Google Docs, AI generates summaries and extracts tasks
**Depends on**: Phase 4
**Research**: Likely (external AI API integration)
**Research topics**: AI service selection (OpenAI GPT-4, Anthropic Claude), document parsing from Google Docs, prompt engineering for task/position extraction, cost optimization strategies
**Plans**: 5 plans

Plans:
- [x] 05-01: Document upload and parsing (PDF/text)
- [x] 05-02: AI service integration with DeepSeek/OpenRouter
- [x] 05-03: Summary generation and processing
- [x] 05-04: Task extraction with assignee matching
- [x] 05-05: Display summaries and extracted content

### Phase 6: Task & Calendar Views
**Goal**: Members see their tasks and a calendar with meetings and deadlines
**Depends on**: Phase 5
**Research**: Unlikely (standard iOS UI patterns)
**Plans**: 3 plans

Plans:
- [x] 06-01: Task list UI with filtering and completion tracking
- [x] 06-02: Calendar view with meetings and task deadlines
- [x] 06-03: Polish and integration with error handling

### Phase 7: Polish & Testing
**Goal**: Production-ready app with refined UI, error handling, and comprehensive testing
**Depends on**: Phase 6
**Research**: Unlikely (refinement of existing features)
**Plans**: 3 plans

Plans:
- [x] 07-01: UI polish, loading states, and error handling
- [x] 07-02: Comprehensive testing and bug fixes
- [x] 07-03: App Store preparation and final validation

## Progress

**Execution Order:**
Phases execute in numeric order: 1 → 2 → 3 → 4 → 5 → 6 → 7

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Foundation & Project Setup | 3/3 | Complete | 2026-01-15 |
| 2. Authentication System | 4/4 | Complete | 2026-01-15 |
| 3. Organization Management | 4/4 | Complete | 2026-01-18 |
| 4. Meeting Management | 4/4 | Complete | 2026-01-18 |
| 5. Document Upload & AI Processing | 5/5 | Complete | 2026-01-23 |
| 6. Task & Calendar Views | 3/3 | Complete | 2026-01-28 |
| 7. Polish & Testing | 3/3 | Complete | 2026-01-30 |
