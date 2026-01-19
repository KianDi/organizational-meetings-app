---
phase: 05-document-upload-ai-processing
plan: 01
subsystem: document-processing
tags: [pdf, pdfkit, document-picker, file-upload, ios]

# Dependency graph
requires:
  - phase: 04-meeting-management
    provides: Meeting model, MeetingService, MeetingDetailView UI foundation
provides:
  - Document upload capability with PDF/text parsing
  - DocumentService actor for thread-safe document operations
  - DocumentPickerView SwiftUI wrapper for native file selection
  - Database schema for document storage (documentText, documentUrl, uploadedAt)
  - Admin-only upload UI in MeetingDetailView
affects: [05-02-ai-service-integration, 05-03-summary-generation, 05-04-task-extraction, 05-05-display-summaries]

# Tech tracking
tech-stack:
  added: [PDFKit, UniformTypeIdentifiers]
  patterns: [security-scoped-resources, document-picker-coordinator]

key-files:
  created:
    - MeetingManager/Services/DocumentService.swift
    - MeetingManager/Views/Document/DocumentPickerView.swift
  modified:
    - MeetingManager/Database/schema.sql
    - MeetingManager/Models/Meeting.swift
    - MeetingManager/Services/MeetingService.swift
    - MeetingManager/Views/Meeting/MeetingDetailView.swift

key-decisions:
  - "Use PDFKit for PDF text extraction (iOS 11+ native framework, no external dependencies)"
  - "Security-scoped resource handling for file access from document picker"
  - "10MB file size limit to prevent database bloat"
  - "Store extracted text in PostgreSQL TEXT column (no external blob storage)"
  - "Admin-only upload with document re-upload capability (overwrites previous)"

patterns-established:
  - "Document picker with UIViewControllerRepresentable and Coordinator pattern"
  - "Actor-based service for document parsing operations"
  - "File size validation before processing"

issues-created: []

# Metrics
duration: 17min
completed: 2026-01-19
---

# Phase 5 Plan 1: Google Docs Upload and Document Parsing Summary

**PDF and text document upload with PDFKit extraction, security-scoped file access, and admin-controlled document management**

## Performance

- **Duration:** 17 min
- **Started:** 2026-01-19T17:17:00Z
- **Completed:** 2026-01-19T17:34:00Z
- **Tasks:** 7
- **Files modified:** 6

## Accomplishments

- Organizers can upload PDF or text documents from Files app
- Document text is extracted using PDFKit and stored in database
- Meeting detail view shows document upload status with timestamps
- Security-scoped resource handling ensures proper file access
- 10MB file size limit prevents database bloat
- Admin-only upload controls with re-upload capability

## Task Commits

Each task was committed atomically:

1. **Task 1: Extend database schema** - `c904944` (auto-commit)
2. **Task 2: Update Meeting model** - `ca6adf4` (auto-commit)
3. **Task 3: Create DocumentService actor** - `e1213ab` (auto-commit)
4. **Task 4: Create DocumentPickerView** - `04926bb` (auto-commit)
5. **Task 5: Add uploadDocument to MeetingService** - `88e833c` (auto-commit)
6. **Task 6: Add Upload button to MeetingDetailView** - `e3b10f7` (feat)
7. **Task 7: Display document status** - `08de622` (auto-commit)

**Plan metadata:** (next commit)

## Files Created/Modified

- `MeetingManager/Database/schema.sql` - Added document_text, document_url, uploaded_at columns to meetings table
- `MeetingManager/Models/Meeting.swift` - Added documentText, documentUrl, uploadedAt properties with Codable support
- `MeetingManager/Services/DocumentService.swift` - Actor for PDF/text parsing with PDFKit, security-scoped resources, file size validation
- `MeetingManager/Services/MeetingService.swift` - Added uploadDocument method, updated DTO mappings for document fields
- `MeetingManager/Views/Document/DocumentPickerView.swift` - UIViewControllerRepresentable wrapper for UIDocumentPickerViewController
- `MeetingManager/Views/Meeting/MeetingDetailView.swift` - Upload button, document picker integration, status display section

## Decisions Made

**PDFKit for text extraction:**
- Rationale: Native iOS 11+ framework, no external dependencies, handles multi-page PDFs efficiently
- Alternative: External OCR service was considered but deferred (no OCR for scanned PDFs in Phase 5)

**Security-scoped resource handling:**
- Rationale: Required for accessing files from document picker on iOS
- Implementation: startAccessingSecurityScopedResource() / defer { stopAccessingSecurityScopedResource() }

**10MB file size limit:**
- Rationale: Prevents database bloat while supporting typical meeting documents
- Validation: Check before processing, throw DocumentError.fileSizeLimitExceeded

**Store text in PostgreSQL TEXT column:**
- Rationale: Simplifies architecture, no need for external blob storage for text content
- Trade-off: Large documents consume database space, but TEXT column handles this efficiently

**Admin-only upload with re-upload capability:**
- Rationale: Prevents accidental overwrites while allowing flexibility for corrections
- UX: Upload button only appears if no document uploaded yet, or user can delete and re-upload

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## Next Phase Readiness

**Ready for Phase 5 Plan 2 (AI Service Integration):**
- Document text extraction complete and stored in database
- Meeting model has documentText field for AI processing
- Upload flow tested and working

**Blocks:**
- Plan 05-02 needs Anthropic API key configuration
- Plan 05-03 will consume documentText from Meeting model

**Notes:**
- No OCR support yet (scanned PDFs will show empty document error)
- Google Docs API direct integration deferred (currently using export/import workflow)
- Document versioning deferred (single document per meeting, re-upload overwrites)

---
*Phase: 05-document-upload-ai-processing*
*Completed: 2026-01-19*
