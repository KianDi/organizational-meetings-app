# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-01-14)

**Core value:** Keeping members informed through AI-powered meeting summaries and reliable attendance tracking, so everyone knows what's happening and what their tasks are without reading full meeting documents.
**Current focus:** Phase 5 — Document Upload & AI Processing

## Current Position

Phase: 5 of 7 (Document Upload & AI Processing)
Plan: 4 of 5 in current phase
Status: In progress
Last activity: 2026-01-22 — Completed 05-04-PLAN.md

Progress: ████████████ 64%

## Performance Metrics

**Velocity:**
- Total plans completed: 19
- Average duration: ~10 min
- Total execution time: 3.83 hours

**By Phase:**

| Phase | Plans | Total | Avg/Plan |
|-------|-------|-------|----------|
| 1 | 3 | 28 min | 9 min |
| 2 | 4 | 27 min | 7 min |
| 3 | 4 | 42 min | 11 min |
| 4 | 4 | 39 min | 10 min |
| 5 | 4 | 98 min | 25 min |

**Recent Trend:**
- Last 5 plans: 05-01 (17 min), 05-02 (23 min), 05-03 (35 min)
- Trend: Phase 5 plans taking longer due to AI integration complexity and multi-step workflows

## Accumulated Context

### Decisions

Decisions are logged in PROJECT.md Key Decisions table.
Recent decisions affecting current work:

| Phase | Decision | Rationale |
|-------|----------|-----------|
| 01-02 | Used MeetingTask instead of Task | Avoids naming conflict with Swift Concurrency.Task |
| 01-02 | UUID-based relationships | Clean Codable serialization with backend |
| 01-02 | Admin auto-included in memberIds | Ensures consistency in Organization model |
| 01-03 | Coordinator pattern for navigation | Centralizes navigation logic for testability and maintainability |
| 01-03 | NavigationStack over NavigationView | Modern iOS 17+ approach with type-safe path binding |
| 01-03 | Route enum with associated values | Type-safe routing with compile-time parameter checking |
| 02-01 | Supabase Auth over Firebase | Open-source flexibility and PostgreSQL RLS integration |
| 02-01 | Actor pattern for AuthService | Prevents race conditions in concurrent auth operations |
| 02-01 | Placeholder Supabase credentials | User configures actual project credentials when ready |
| 02-02 | kSecAttrAccessibleWhenUnlockedThisDeviceOnly | Maximum security: tokens only accessible when unlocked, not backed up |
| 02-02 | Actor-based KeychainManager | Thread-safe credential access without manual locking |
| 02-03 | LoginView requires 6 chars, SignupView requires 8 chars | Stronger security for new accounts while allowing existing users to login |
| 02-03 | Form validation disables submit button | Prevents invalid API calls and provides immediate user feedback |
| 02-03 | Callback-based navigation (onAuthSuccess) | Decouples views from routing logic for coordinator integration |
| 02-02 | Async/await for Keychain operations | Prevents UI blocking during Security framework calls |
| 02-04 | @Observable over ObservableObject | Modern iOS 17+ pattern with cleaner syntax and better performance |
| 02-04 | @MainActor on state-changing methods | Ensures UI updates happen on main thread for auth state changes |
| 02-04 | Environment injection for AuthState | Cleaner dependency injection than passing parameters through view hierarchy |
| 02-04 | Session restoration in .task modifier | Automatic restoration from Keychain on app launch without manual trigger |
| 03-01 | Codable DTO for database mapping | Type-safe snake_case to camelCase mapping, cleaner than dictionaries |
| 03-01 | 6-character invite code from UUID prefix | Short enough to type, unique enough to avoid collisions |
| 03-01 | RLS policies for organizations table | Member-based read access, admin-only write access for security |
| 03-02 | Early return for existing members | Prevents duplicate entries in memberIds, improves idempotency |
| 03-02 | TextField onChange for input formatting | Automatic uppercase and 6-char limit for invite codes |
| 03-02 | Users table with auto-creation trigger | PostgreSQL trigger syncs users table with auth.users automatically |
| 03-02 | Bidirectional organization tracking | organizations.member_ids AND users.organization_ids for efficient queries both ways |
| 03-03 | .in() Postgrest filter for member queries | Efficient batch query for multiple user IDs, avoids N+1 queries |
| 03-03 | Admin-first sorting in member list | Highlights organization leader, provides consistent UX |
| 03-03 | ShareSheet UIKit wrapper | Native iOS sharing experience for invite codes |
| 03-03 | LabeledContent for detail rows | Consistent iOS design language for organization details |
| 03-04 | OrganizationState follows AuthState pattern | Consistent with Phase 2, ensures thread-safe UI updates with @MainActor |
| 03-04 | OrganizationListView as authenticated home screen | Provides immediate value on login, central hub for organization access |
| 03-04 | Wrapper views for create/join integration | Maintains backwards compatibility while integrating with app-wide state |
| 03-04 | Organization Hashable conformance | Required for modern SwiftUI NavigationLink value-based navigation |
| 04-01 | RLS policies for member SELECT, admin INSERT/UPDATE/DELETE | Separates read access (all members) from write access (admins only) for security |
| 04-01 | Separate member UPDATE policy for attendee_ids | Enables members to check in without granting full update permissions |
| 04-01 | MeetingUpdateDTO with optional fields | Type-safe partial updates using Encodable instead of [String: Any] dictionaries |
| 04-01 | Default scheduled time 1 hour from now | Better UX than current time, provides reasonable starting point organizers can adjust |
| 04-02 | Idempotent check-in with early return | Prevents duplicate entries in attendeeIds, safe to retry operations |
| 04-02 | State-conditional button rendering in SwiftUI | Separate if/else branches avoid ternary ButtonStyle type mismatch |
| 04-02 | MeetingError enum with LocalizedError | User-friendly validation messages for meeting state and membership checks |
| 04-02 | Three-stage validation order | Check started → not ended → membership for most relevant error messages |
| 04-02 | Atomic attendee_ids updates | Only update attendee_ids column to prevent race conditions with other meeting fields |
| 04-02 | Haptic feedback on successful check-in | UINotificationFeedbackGenerator provides tactile confirmation for better UX |
| 04-03 | Three-tier meeting categorization | Active/Upcoming/Past sections improve meeting discovery and status visibility |
| 04-03 | Relative date formatting in meeting list | "Today 3pm" more user-friendly than absolute timestamps for scheduled times |
| 04-03 | Green indicator dot for active meetings | Visual prominence helps users quickly identify ongoing meetings in list |
| 04-03 | Direct Supabase query for attendees | Follows OrganizationService.fetchMembers pattern with .in() filter for efficiency |
| 04-03 | Creator-based admin check in detail view | Simplified admin logic - meeting creator can start/end meetings |
| 04-03 | ContentUnavailableView for empty meetings | iOS 17+ standard component for consistent empty state UX |
| 04-04 | MeetingState follows OrganizationState pattern | Consistent centralized state management across the app |
| 04-04 | Environment injection for MeetingState | Makes state available throughout view hierarchy without prop drilling |
| 04-04 | Local array updates after service calls | Instant UI feedback by updating meetings array immediately after backend operations |
| 04-04 | Computed currentMeeting property | Reactive state derivation in MeetingDetailView instead of separate @State |
| 05-01 | PDFKit for PDF text extraction | Native iOS 11+ framework, no external dependencies, handles multi-page PDFs efficiently |
| 05-01 | Security-scoped resource handling | Required for accessing files from document picker, proper startAccessingSecurityScopedResource pattern |
| 05-01 | 10MB file size limit | Prevents database bloat while supporting typical meeting documents |
| 05-01 | Store text in PostgreSQL TEXT column | Simplifies architecture, no external blob storage needed for text content |
| 05-01 | Admin-only upload with re-upload capability | Prevents accidental overwrites while allowing flexibility for corrections |
| 05-02 | DeepSeek via OpenRouter instead of Claude | 10x cost savings ($0.27/$1.10 vs $3/$15 per million tokens) while maintaining quality |
| 05-02 | Native URLSession over external SDK | OpenRouter uses OpenAI-compatible API, no package dependencies needed |
| 05-02 | JSON mode for structured outputs | Enables reliable task extraction with predictable data format |
| 05-02 | Exponential backoff with jitter | 3 retries (1s, 2s, 4s) for network errors only, no retry for API errors |
| 05-02 | Placeholder API key in config | Tracked in git for easy setup, users replace with actual key |
| 05-03 | Auto-generate summary on document upload | No manual trigger needed, summary generation automatic after successful parse |
| 05-03 | Summary regeneration with confirmation dialog | Re-upload shows confirmation: "Re-uploading will regenerate the AI summary. Continue?" |
| 05-03 | Auto-dismissing status messages | Completed state clears after 2s, error state after 5s to keep UI clean |
| 05-03 | Inline retry button for failed processing | Retry button appears for 5s after failure, reuses lastFailedDocumentUrl |
| 05-03 | ProcessingState enum for workflow tracking | 7 states (idle/uploading/parsing/generating/extracting/completed/failed) with UI helpers |

### Deferred Issues

None yet.

### Pending Todos

None yet.

### Blockers/Concerns

None yet.

## Session Continuity

Last session: 2026-01-22T20:23:00Z
Stopped at: Completed 05-03-PLAN.md
Resume file: None

**Phase 5 Progress:**
- ✓ 05-01: Document upload and document parsing (Wave 1) - COMPLETE
- ✓ 05-02: AI service integration with DeepSeek/OpenRouter (Wave 1) - COMPLETE
- ✓ 05-03: Summary generation and processing (Wave 2) - COMPLETE
- 05-04: Task and position extraction logic (Wave 3) - NEXT
- 05-05: Display summaries and extracted content (Wave 4)

**05-03 Accomplishments:**
- Complete AI processing pipeline: upload → parse → summarize → save → update UI
- ProcessingState enum tracking 7 workflow states with UI helpers (displayText, isProcessing)
- MeetingState.processDocument orchestrating multi-step async workflow with conditional regeneration
- Real-time processing status UI with spinner, checkmark, error icons, and retry button
- Re-upload confirmation dialog preventing accidental summary overwrites
- Auto-dismissing status messages (2s completed, 5s errors)
- Summary display integrated into meeting detail view
- Error recovery with retry button using lastFailedDocumentUrl
