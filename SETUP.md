# Meeting Manager - Setup Guide

Complete step-by-step setup instructions for running Meeting Manager locally.

## Prerequisites

Before you begin, ensure you have:

- **Xcode 15.0 or later** installed
- **iOS 17.0+** deployment target
- **Supabase account** (free tier available at [supabase.com](https://supabase.com))
- **OpenRouter account** with API credits ([openrouter.ai](https://openrouter.ai))

## 1. Clone the Repository

```bash
git clone <repository-url>
cd MeetingManager
```

## 2. Supabase Setup

### 2.1 Create Supabase Project

1. Go to [supabase.com](https://supabase.com) and sign in
2. Click "New Project"
3. Enter project details:
   - Name: "Meeting Manager" (or your preference)
   - Database Password: Choose a strong password (save it securely)
   - Region: Select closest to your location
4. Click "Create new project" and wait for initialization (1-2 minutes)

### 2.2 Get Project Credentials

1. In your Supabase project dashboard, go to **Settings** → **API**
2. Copy the following values:
   - **Project URL** (format: `https://xxxxx.supabase.co`)
   - **anon/public key** (starts with `eyJ...`)

### 2.3 Run Database Migrations

1. In Supabase dashboard, go to **SQL Editor**
2. Click "New Query"
3. Copy the entire contents of `MeetingManager/Database/schema.sql`
4. Paste into the SQL editor
5. Click "Run" to execute the migration
6. Verify success: Check **Database** → **Tables** to see:
   - `organizations`
   - `users`
   - `meetings`
   - `tasks`

### 2.4 Verify Row Level Security

The schema automatically enables RLS policies. Verify in **Authentication** → **Policies**:

- Organizations: 6 policies (view, find by invite code, admin update, user join, admin delete, create)
- Users: 3 policies (view own profile, update own profile, service insert)
- Meetings: 5 policies (view, admin create/update/delete, member check-in)
- Tasks: 4 policies (view, insert, update completion, delete)

### 2.5 Configure App Credentials

Edit `MeetingManager/MeetingManager/Auth/Secrets.swift`:

```swift
enum Secrets {
  static let supabaseURL = "https://YOUR_PROJECT_ID.supabase.co"
  static let supabaseAnonKey = "YOUR_ANON_KEY_HERE"
}
```

Replace with your actual Project URL and anon key from step 2.2.

## 3. OpenRouter Setup

### 3.1 Create OpenRouter Account

1. Go to [openrouter.ai](https://openrouter.ai)
2. Sign up with GitHub, Google, or email
3. Verify your email address

### 3.2 Add Credits

1. Go to **Settings** → **Credits**
2. Click "Add Credits"
3. Add at least **$5** (recommended for testing)
   - DeepSeek R1 costs: $0.27 input / $1.10 output per million tokens
   - Typical meeting summary: ~500 tokens = $0.0005
   - $5 = approximately 10,000 summaries

### 3.3 Generate API Key

1. Go to **Keys** in the dashboard
2. Click "Create Key"
3. Give it a name (e.g., "Meeting Manager Dev")
4. Copy the generated key (starts with `sk-or-v1-...`)

### 3.4 Configure App API Key

Edit `MeetingManager/MeetingManager/Config/OpenRouterConfig.swift`:

```swift
static let apiKey = "sk-or-v1-YOUR_API_KEY_HERE"
```

Replace with your actual API key from step 3.3.

## 4. Build and Run

### 4.1 Open Project

```bash
cd MeetingManager
open MeetingManager.xcodeproj
```

### 4.2 Select Simulator

1. In Xcode, click the device selector in the toolbar
2. Choose **iPhone 15** (or any iOS 17+ simulator)
3. If no simulators are available, go to **Xcode** → **Settings** → **Platforms** to download iOS 17+ simulators

### 4.3 Build and Run

1. Press **Cmd+R** or click the Play button
2. Wait for build to complete
3. App launches in simulator

Expected first launch:
- Sign-up screen appears
- No errors in Xcode console
- Supabase connection successful

## 5. First-Time Setup

### 5.1 Create Account

1. On signup screen, enter:
   - Email: your email
   - Name: your name
   - Password: at least 8 characters
2. Click "Sign Up"
3. Check email for verification link (from Supabase)
4. Click verification link
5. Return to app and sign in

### 5.2 Create Organization

1. After login, click "Create Organization"
2. Enter organization name (e.g., "Computer Science Club")
3. Click "Create"
4. You'll see your organization in the list

### 5.3 Invite Members (Optional)

1. Tap your organization to view details
2. Note the 6-character invite code
3. Share code with members
4. Members can join by entering code in "Join Organization"

### 5.4 Create Meeting

1. In organization view, tap "New Meeting" button
2. Enter meeting details:
   - Title: "Weekly Standup"
   - Scheduled time: select date/time
3. Click "Create"
4. Meeting appears in the meetings list

### 5.5 Test Document Upload

1. Tap the meeting you created
2. Tap "Upload Document" (admin only)
3. Select a PDF file (use the included `Business Retreat Jan 18 2026 (1).pdf` for testing)
4. Watch processing indicators:
   - "Uploading..." (~1s)
   - "Extracting text..." (~1s)
   - "Generating summary..." (~5s)
   - "Extracting tasks..." (~10s)
5. Summary appears below document section
6. Tasks appear in "Tasks from this meeting" section
7. Navigate to **Tasks** tab to see tasks grouped by due date
8. Navigate to **Calendar** tab to see meetings and tasks

## 6. Running Tests

### 6.1 Run All Tests

```bash
xcodebuild test -scheme MeetingManager -destination 'platform=iOS Simulator,name=iPhone 15'
```

Or in Xcode: **Cmd+U**

### 6.2 Expected Test Results

- 61 tests total
- All tests should pass
- Test categories:
  - NameMatcher: 26 tests (fuzzy name matching)
  - Meeting: 15 tests (state logic)
  - ProcessingState: 20 tests (enum behavior)

## 7. Configuration Files Reference

### Secrets.swift
- Location: `MeetingManager/Auth/Secrets.swift`
- Purpose: Supabase credentials
- Fields:
  - `supabaseURL`: Your Supabase project URL
  - `supabaseAnonKey`: Your Supabase anon/public key

### OpenRouterConfig.swift
- Location: `MeetingManager/Config/OpenRouterConfig.swift`
- Purpose: AI service configuration
- Fields:
  - `apiKey`: Your OpenRouter API key
  - `endpoint`: OpenRouter API endpoint (pre-configured)
  - `model`: DeepSeek R1 model (pre-configured)
  - `maxTokens`: Token limit for responses (8192)

### Database Schema
- Location: `MeetingManager/Database/schema.sql`
- Purpose: Complete database structure with RLS policies
- Tables: organizations, users, meetings, tasks
- Run once in Supabase SQL Editor during setup

## 8. Troubleshooting

### Build Errors

**Error: "Cannot find 'Secrets' in scope"**
- Solution: Ensure `Secrets.swift` exists at `MeetingManager/Auth/Secrets.swift`
- If missing, create it using the template in section 2.5

**Error: Package dependencies not resolved**
- Solution: In Xcode, go to **File** → **Packages** → **Resolve Package Versions**

### Runtime Errors

**"Supabase URL invalid"**
- Check `Secrets.swift` has correct URL format: `https://xxxxx.supabase.co`
- Verify URL copied from Supabase dashboard Settings → API

**"Authentication failed"**
- Check email verification in inbox
- Verify Supabase project is active (not paused)
- Check Auth settings in Supabase: **Authentication** → **Settings** → ensure email auth enabled

**"AI summary generation failed"**
- Check OpenRouter API key in `OpenRouterConfig.swift`
- Verify credits available in OpenRouter dashboard
- Check network connection (AI requires internet)

**"Failed to upload document"**
- Ensure meeting has started (tap "Start Meeting" first)
- Verify you're the admin (creator) of the meeting
- Check PDF file size is under 10MB

### Database Issues

**"No organizations appear after creation"**
- Check Supabase dashboard → **Database** → **Table Editor** → organizations
- Verify RLS policies are enabled (section 2.4)
- Check Xcode console for error messages

**"Can't join organization with invite code"**
- Verify invite code is exactly 6 characters
- Check organization exists in Supabase table editor
- Ensure you're authenticated (signed in)

## 9. Development Notes

### Security Considerations

- **Secrets.swift** contains real credentials and should be in `.gitignore` for production
- For this project, it's tracked in git for easy setup
- Before deploying, move credentials to environment variables or Xcode build configuration

### API Costs

DeepSeek R1 via OpenRouter:
- Input: $0.27 per million tokens
- Output: $1.10 per million tokens
- Typical meeting (5-page PDF): ~$0.001 per summary
- Very cost-effective compared to GPT-4 ($3/$15 per million tokens)

### Database Migrations

Currently using single `schema.sql` file. For production:
- Consider versioned migrations (e.g., Supabase CLI migrations)
- Track schema changes in separate migration files
- Use `IF NOT EXISTS` clauses to make migrations idempotent

## 10. Next Steps

After successful setup:

1. **Test full user flow**: Sign up → Create org → Create meeting → Upload doc → Check summary
2. **Explore features**: Calendar view, task management, multi-organization support
3. **Review code**: Check `MeetingManager/` directory structure
4. **Run tests**: Verify all 61 tests pass with `Cmd+U`
5. **Customize**: Modify UI, add features, extend functionality

## Support

If you encounter issues not covered here:

1. Check Xcode console for detailed error messages
2. Verify Supabase project status in dashboard
3. Check OpenRouter credits and API key status
4. Review database tables and RLS policies in Supabase
5. Ensure all dependencies resolved in Xcode

For questions about the codebase, see inline comments and documentation in Swift files.
