# Meeting Manager

A comprehensive meeting management app for student organizations, featuring attendance tracking, AI-powered meeting summaries, automatic task extraction, and integrated calendar views. Made this for my own org, Surge Interest Group but feel free to use at your own discretion.

## Features

- **Organization Management**: Create organizations, invite members via shareable codes
- **Meeting Scheduling**: Schedule meetings, track attendance with check-in/check-out
- **Document Processing**: Upload meeting documents (PDF) with automatic text extraction
- **AI Summaries**: Automatically generate meeting summaries using DeepSeek AI via OpenRouter
- **Task Extraction**: AI-powered extraction of action items with assignees and due dates
- **Calendar View**: Visual calendar showing meetings and tasks across all organizations
- **Task Management**: Organized task list with sections (Overdue, Today, This Week, Later, Completed)
- **Multi-Organization**: Manage memberships across multiple organizations simultaneously

## Tech Stack

- **Frontend**: SwiftUI (iOS 17+)
- **Backend**: Supabase (PostgreSQL + Auth + Real-time)
- **AI Processing**: OpenRouter API with DeepSeek R1 (cost-effective at $0.27/$1.10 per million tokens)
- **Document Processing**: PDFKit for native PDF text extraction
- **Architecture**: @Observable state management, Actor-based concurrency, Coordinator navigation pattern

## Requirements

- Xcode 15.0 or later
- iOS 17.0+ deployment target
- Supabase account (free tier works)
- OpenRouter account with API credits ($5 minimum recommended)

## Quick Start

For detailed setup instructions, see [SETUP.md](SETUP.md).

**Quick overview:**
1. Clone the repository
2. Set up Supabase project and run database migrations
3. Copy config templates and add your credentials:
   - `cp MeetingManager/Auth/SupabaseConfig.swift.template MeetingManager/Auth/SupabaseConfig.swift`
   - `cp MeetingManager/Config/OpenRouterConfig.swift.template MeetingManager/Config/OpenRouterConfig.swift`
   - Create `MeetingManager/Auth/Secrets.swift` with Supabase credentials
   - Edit `OpenRouterConfig.swift` to add your API key
4. Open `MeetingManager.xcodeproj` in Xcode
5. Build and run on iOS Simulator (Cmd+R)

## Project Structure

```
MeetingManager/
├── Auth/               # Authentication and Supabase configuration
├── Config/             # OpenRouter API configuration
├── Database/           # SQL schema for Supabase
├── Models/             # Data models (Organization, Meeting, MeetingTask)
├── Navigation/         # Coordinator pattern for type-safe routing
├── Services/           # Business logic (Auth, Organization, Meeting, AI)
├── State/              # Centralized state management (@Observable classes)
├── Utilities/          # Helper functions (NameMatcher for fuzzy matching)
└── Views/              # SwiftUI views organized by feature
```

## Key Architecture Decisions

- **MeetingTask instead of Task**: Avoids naming conflict with Swift Concurrency.Task
- **Actor pattern for services**: Thread-safe operations (AuthService, KeychainManager)
- **@Observable state management**: Modern iOS 17+ approach with automatic view updates
- **Coordinator navigation**: Centralized routing with type-safe Route enum
- **Supabase Row Level Security**: Database-level security for organizations, meetings, tasks
- **Idempotent operations**: Safe check-ins, organization joins, task updates

## License

See [LICENSE](LICENSE) for details.

## Support

For setup issues or questions, see the detailed instructions in [SETUP.md](SETUP.md).
