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

- [ ] **Phase 1: Foundation & Project Setup** - iOS project initialization, dependencies, and core architecture
- [ ] **Phase 2: Authentication System** - Email/password auth with user management
- [ ] **Phase 3: Organization Management** - Create orgs, invite system, member roles
- [ ] **Phase 4: Meeting Management** - Schedule meetings, check-in system, attendance tracking
- [ ] **Phase 5: Document Upload & AI Processing** - Google Docs upload, AI summary generation, task extraction
- [ ] **Phase 6: Task & Calendar Views** - Task list UI, calendar with meetings and deadlines
- [ ] **Phase 7: Polish & Testing** - UI refinement, error handling, testing

## Phase Details

### Phase 1: Foundation & Project Setup
**Goal**: iOS project initialized with core architecture, data models, and dependencies configured
**Depends on**: Nothing (first phase)
**Research**: Unlikely (iOS project setup, established patterns)
**Plans**: 3 plans

Plans:
- [ ] 01-01: Initialize iOS project and configure dependencies
- [ ] 01-02: Create core data models (User, Organization, Meeting, Task)
- [ ] 01-03: Setup navigation structure and app architecture

### Phase 2: Authentication System
**Goal**: Users can sign up, log in, and manage their accounts with email/password
**Depends on**: Phase 1
**Research**: Likely (authentication architecture and library choice)
**Research topics**: Swift authentication libraries, secure credential storage (Keychain), backend auth service selection (Firebase, Supabase, custom)
**Plans**: 4 plans

Plans:
- [ ] 02-01: Implement authentication backend service integration
- [ ] 02-02: Create login and signup UI screens
- [ ] 02-03: Implement secure credential storage with Keychain
- [ ] 02-04: Add session management and auth state handling

### Phase 3: Organization Management
**Goal**: Users can create organizations, generate invite links, and manage member roles
**Depends on**: Phase 2
**Research**: Unlikely (internal data models building on auth from Phase 2)
**Plans**: 4 plans

Plans:
- [ ] 03-01: Organization creation and admin assignment
- [ ] 03-02: Invite link/code generation and joining flow
- [ ] 03-03: Member list and role management UI
- [ ] 03-04: Organization settings and permissions logic

### Phase 4: Meeting Management
**Goal**: Organizers can schedule meetings, members can check in, attendance is tracked
**Depends on**: Phase 3
**Research**: Unlikely (internal features using established patterns)
**Plans**: 4 plans

Plans:
- [ ] 04-01: Meeting creation and scheduling for organizers
- [ ] 04-02: Simple check-in button and attendance recording
- [ ] 04-03: Meeting list view and detail screens
- [ ] 04-04: Attendance history and tracking

### Phase 5: Document Upload & AI Processing
**Goal**: Organizers upload Google Docs, AI generates summaries and extracts tasks
**Depends on**: Phase 4
**Research**: Likely (external AI API integration)
**Research topics**: AI service selection (OpenAI GPT-4, Anthropic Claude), document parsing from Google Docs, prompt engineering for task/position extraction, cost optimization strategies
**Plans**: 5 plans

Plans:
- [ ] 05-01: Google Docs file upload and parsing
- [ ] 05-02: AI service integration and API client
- [ ] 05-03: Summary generation prompt and processing
- [ ] 05-04: Task and position extraction logic
- [ ] 05-05: Display summaries and extracted content in meeting detail

### Phase 6: Task & Calendar Views
**Goal**: Members see their tasks and a calendar with meetings and deadlines
**Depends on**: Phase 5
**Research**: Unlikely (standard iOS UI patterns)
**Plans**: 3 plans

Plans:
- [ ] 06-01: Task list UI with completion tracking
- [ ] 06-02: Calendar view with meetings and deadlines
- [ ] 06-03: Task and event detail screens

### Phase 7: Polish & Testing
**Goal**: Production-ready app with refined UI, error handling, and comprehensive testing
**Depends on**: Phase 6
**Research**: Unlikely (refinement of existing features)
**Plans**: 3 plans

Plans:
- [ ] 07-01: UI polish, loading states, and error handling
- [ ] 07-02: Comprehensive testing and bug fixes
- [ ] 07-03: App Store preparation and final validation

## Progress

**Execution Order:**
Phases execute in numeric order: 1 → 2 → 3 → 4 → 5 → 6 → 7

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Foundation & Project Setup | 0/3 | Not started | - |
| 2. Authentication System | 0/4 | Not started | - |
| 3. Organization Management | 0/4 | Not started | - |
| 4. Meeting Management | 0/4 | Not started | - |
| 5. Document Upload & AI Processing | 0/5 | Not started | - |
| 6. Task & Calendar Views | 0/3 | Not started | - |
| 7. Polish & Testing | 0/3 | Not started | - |
