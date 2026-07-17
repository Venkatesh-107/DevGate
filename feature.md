# DevGate — Features Document

> **Version:** 1.0.0 · **Last Updated:** 2026-07-15

---

## Feature Overview

DevGate provides two primary capability domains accessible from the main dashboard:

| Domain | Tab | Icon |
|---|---|---|
| Security Scanner | Scanner | `Icons.security` |
| Git / GitHub Integration | Git/GitHub | `Icons.source` |

---

## Feature 1 — Onboarding & Profile Setup

**File:** `lib/ui/onboarding/onboarding_screen.dart`
**Trigger:** First launch (no stored profile in secure storage)

### What it does
- Displays a branded welcome screen with a security-first notice
- Collects three required fields: **Full Name**, **GitHub Username**, **GitHub Personal Access Token (PAT)**
- Stores all values encrypted on-device using `flutter_secure_storage`
- Provides inline PAT instructions (how to generate from GitHub Settings)
- Navigates directly to `DashboardScreen` on success

### Security notice shown to users
> "DevGate does NOT use PocketBase or any centralized servers. We do not store your keys remotely. Everything is encrypted and runs entirely on your local device for maximum security."

### Storage keys written
| Key | Value |
|---|---|
| `user_name` | Full name string |
| `github_username` | GitHub handle (used as default repo owner) |
| `github_access_token` | PAT (used for GitHub API calls and git push/pull) |

---

## Feature 2 — Secret / Credential Scanner

**Files:** `lib/engines/scanner/scanner_engine.dart`, `regex_engine.dart`, `entropy_math.dart`
**Entry point UI:** `lib/ui/dashboard/widgets/drop_zone.dart`

### What it does
Recursively scans local project directories for exposed secrets, credentials, and high-entropy strings using two independent detection engines.

### 2.1 — Drag-and-Drop Interface
- Full-screen drop target using `desktop_drop` package
- Animated border and glow effect on drag hover
- Alternative: **Browse Folders** button via native file picker (`file_selector`)
- Multiple directories can be scanned in a single session

### 2.2 — Regex-Based Detection Engine
**22 patterns** across 7 categories (TruffleHog-inspired):

| Category | Secrets Detected |
|---|---|
| **Cloud** | AWS Access Key ID, AWS Secret Access Key, Google API Key, Azure Storage Key, Firebase Config, Supabase Key |
| **Payment** | Stripe Standard API Key (`sk_live_`), Stripe Restricted API Key (`rk_live_`) |
| **AI / LLM** | OpenAI API Key (`sk-`), Anthropic API Key (`sk-ant-`) |
| **Version Control** | GitHub PAT (`ghp_`), GitHub Fine-Grained PAT (`github_pat_`), npm Token (`npm_`) |
| **Messaging** | Slack Bot Token, Discord Bot Token, Twilio API Key, SendGrid API Key, Mailgun API Key |
| **Infrastructure** | Heroku API Key (UUID format) |
| **Cryptographic** | RSA Private Key, Generic Private Key (EC/DSA), Generic JWT (`eyJ...`) |

- Regex findings are marked **severity: high**
- Each finding stores the matched line, file path, and line number

### 2.3 — Shannon Entropy Detection Engine
- Calculates `H = -Σ p(x) * log₂ p(x)` per string token
- Threshold: **> 4.8 bits** (typical API keys are 5.0–6.0 bits)
- Only tokens with `length > 16` and no `{` or `}` are evaluated
- Entropy findings are marked **severity: medium**, stored with their entropy score

### 2.4 — Architecture Recommendations
Automatically generated based on project type detection:

| Detection | Recommendation Shown |
|---|---|
| `pubspec.yaml` found | Recommends Clean Architecture / Feature-First structure for Flutter projects |
| `package.json` found | Recommends `npm audit` and avoiding `.env` files in version control |

- Recommendations are marked `FindingType.recommendation`, `severity: low`

### 2.5 — Skip Rules
The scanner automatically skips:
- Directories: `.git`, `node_modules`, `.dart_tool`, `build`, `.pub-cache`
- Files larger than 1 GB
- Non-text files (only `.dart`, `.js`, `.ts`, `.json`, `.yaml`, `.yml`, `.txt`, `.md`, `.env` are scanned)

### 2.6 — Scan Progress UI
- Shows `CircularProgressIndicator` during scan
- Displays the **current file name** being processed in real-time

### 2.7 — Results Dashboard
After scanning, a structured dashboard is shown:

**Header Stats Bar:**
- Security Risks count (red if > 0, green if 0)
- Recommendations count
- Scan Status ("Complete")

**Two-panel layout:**
- Left panel (2/3 width): **Vulnerabilities Found** — list of regex/entropy findings
  - Each card shows: label, type badge, filename, line number, code snippet (monospace)
- Right panel (1/3 width): **Architecture Advice** — recommendation cards with lightbulb icon

**Footer Actions:**
- **New Scan** — clears all results and resets state
- **Export JSON** — saves a structured JSON report via native save dialog

### 2.8 — JSON Report Export
Exported report format:
```json
{
  "generated_by": "DevGate v1.0.0",
  "scanned_at": "<ISO 8601 timestamp>",
  "summary": { "total_findings": 3 },
  "findings": [
    {
      "type": "regex",
      "label": "AWS Access Key ID",
      "file": "/path/to/file.dart",
      "line": 42,
      "snippet": "AKIA...",
      "severity": "high"
    }
  ]
}
```

---

## Feature 3 — Git Operations Panel

**Files:** `lib/engines/git/git_engine.dart`, `git_notifier.dart`
**UI:** `lib/ui/git/git_panel_screen.dart`

### 3.1 — Project Loading
- Native folder picker to select any local directory
- Automatically detects if folder is a git repository (`git rev-parse --is-inside-work-tree`)
- Loads: current branch, remote URL, changed files list, recent commit log
- Auto-creates a `.gitignore` file if none exists (with standard Flutter/Node entries)

### 3.2 — Repository Setup
Two modes available via tabs:

**Link Existing Repository:**
- Enter GitHub Owner (pre-filled from profile) and Repository name
- Injects PAT into remote URL: `https://<token>@github.com/<owner>/<repo>.git`
- Initializes git repo if not already initialized

**Create New Repository:**
- Enter new repository name
- Choose private (default) or public visibility
- Calls `POST /user/repos` GitHub API to create the repo
- Automatically links local project to new remote

### 3.3 — File Staging
- Displays all changed files with status badges:
  - `M` → Modified (orange)
  - `A` → Added (green)
  - `D` → Deleted (red)
  - `?` → Untracked (grey)
  - `R` → Renamed (blue)
- **Stage All** — runs `git add .`
- **Selective staging** — checkboxes per file, stages selected files only
- **Unstage** — runs `git restore --staged <file>`

### 3.4 — Commit
- Text input for commit message
- Commits staged changes via `git commit -m "<message>"`
- Shows operation output (success or git error) inline

### 3.5 — Safe Push (Pre-Push Security Gate)
This is the core safety feature of DevGate:

1. Runs a full secret scan on the project directory using `ScannerNotifier`
2. If **secrets are found**: shows a blocking `AlertDialog` warning with secret count
   - **Cancel Push** — aborts the operation
   - **Push Anyway** — allows override (user's choice)
3. If **no secrets found**: proceeds with `git push origin <branch>`
4. Push result displayed as SnackBar notification

### 3.6 — Pull
- Pulls latest changes from `origin/<current-branch>`
- Shows output ("Already up to date." or merge summary)

### 3.7 — Clone Repository
- Input field for any git repository URL
- Native folder picker for destination directory
- Runs `git clone <url> <dest>` via `Process.run`

---

## Feature 4 — GitHub Integration

**File:** `lib/data/remote/github_client.dart`

### 4.1 — Personal Access Token Authentication
- PAT is stored encrypted via `flutter_secure_storage`
- Injected as `Bearer` token in all GitHub API requests
- Also embedded in git remote URLs for push/pull via HTTPS

### 4.2 — Device Flow OAuth (Built, UI not yet wired)
The infrastructure for GitHub's Device Flow is implemented:
- `requestDeviceCode()` — gets a user code and verification URL
- `pollForToken(deviceCode, interval)` — polls until authorized or expired
- Handles `authorization_pending`, `slow_down`, and error states

> Note: The Device Flow UI trigger is not yet connected to the onboarding or settings screen.

### 4.3 — Repository Creation
- Creates a new GitHub repository under the authenticated user
- Supports `private: true/false`
- Automatically links via `git remote set-url`

### 4.4 — Security Report Push to GitHub
- Pushes the JSON scan report as a committed file to a GitHub repository
- File path in repo: `.devgate/scan-reports/<date>_scan-report.json`
- Commit message: `"DevGate: security scan <filename>"`
- Content is base64-encoded per GitHub Contents API requirements

---

## Feature 5 — Desktop Window Management

**Package:** `window_manager`

| Feature | Detail |
|---|---|
| Custom title bar | `TitleBarStyle.hidden` — AppBar rendered by Flutter |
| Window drag | `GestureDetector.onPanStart → windowManager.startDragging()` |
| Window close | Custom `IconButton` → `windowManager.close()` |
| Initial size | 1200 × 800 px, centered |
| Background | Transparent (`Colors.transparent`) |
| Taskbar | Shown (`skipTaskbar: false`) |

Only active on Linux / macOS / Windows; mobile/web use standard AppBar.

---

## Feature 6 — Responsive Layout

The dashboard automatically adapts to screen width:

| Width | Layout | Navigation |
|---|---|---|
| `< 600 px` (mobile) | Single-panel, full-width pages | `NavigationBar` (bottom) |
| `>= 600 px` (desktop) | Side `NavigationRail` + `Expanded` content area | `NavigationRail` (left) |

---

## Feature Summary Table

| # | Feature | Status | Key Files |
|---|---|---|---|
| 1 | First-run onboarding + PAT setup | ✅ Complete | `onboarding_screen.dart` |
| 2 | Drag-and-drop folder scanning | ✅ Complete | `drop_zone.dart` |
| 3 | Regex secret detection (22 patterns) | ✅ Complete | `regex_engine.dart` |
| 4 | Shannon entropy detection | ✅ Complete | `entropy_math.dart`, `scanner_engine.dart` |
| 5 | Architecture recommendations | ✅ Complete | `scanner_engine.dart` |
| 6 | JSON report export | ✅ Complete | `drop_zone.dart` |
| 7 | Git status, branch, log display | ✅ Complete | `git_engine.dart`, `git_notifier.dart` |
| 8 | File staging (all + selective) | ✅ Complete | `git_panel_screen.dart` |
| 9 | Git commit | ✅ Complete | `git_engine.dart` |
| 10 | Safe push (pre-push secret scan) | ✅ Complete | `git_panel_screen.dart` |
| 11 | Git pull | ✅ Complete | `git_engine.dart` |
| 12 | Git clone | ✅ Complete | `git_engine.dart` |
| 13 | Link existing GitHub repo | ✅ Complete | `git_panel_screen.dart` |
| 14 | Create new GitHub repo via API | ✅ Complete | `github_client.dart` |
| 15 | Push scan report to GitHub repo | ✅ Complete | `github_client.dart` |
| 16 | Custom desktop window (drag, close) | ✅ Complete | `dashboard_screen.dart` |
| 17 | Responsive desktop/mobile layout | ✅ Complete | `dashboard_screen.dart` |
| 18 | Auto `.gitignore` generation | ✅ Complete | `git_panel_screen.dart` |
| 19 | Device Flow OAuth (GitHub) | ⚠️ Built, no UI trigger | `github_client.dart` |
| 20 | Structured log viewer | ❌ Not implemented | `ui/logs/widgets/` (empty) |
| 21 | User settings / profile editor | ❌ Not implemented | — |
| 22 | Configurable entropy threshold | ❌ Not implemented | Hardcoded `4.8` in `scanner_engine.dart` |

---

## Future Opportunities & UX Improvements

### 1. UI Flow Enhancements
- **Onboarding:**
  - Add a "Test Token" step that pings `GET /user` with the PAT before saving.
  - Offer a "Skip GitHub, scan only" path for frictionless local scanning.
- **Scanner / Drop Zone:**
  - Mask sensitive snippets by default (`secretMask` styling) with a reveal-on-click toggle.
  - Display a live running counter during scans (e.g., "Scanning… 142/380 files") for better progress feedback on large repos.
  - Add inline triage actions to finding cards: "Add file to .gitignore", "Mark as false positive" (persisted per-repo), "Copy redacted snippet".
- **Git Panel / Safe Push:**
  - Add a persistent "safety badge" (green/red dot with finding count) in the Git panel that updates live as files are staged.
  - Implement a stronger confirmation (e.g., type "push" or hold-to-confirm) for overriding the Safe Push block on critical findings.
- **Global:**
  - Expand `NavigationRail` with icons/labels for Settings and Logs.
  - Add collapsed/expanded rail state toggle for the desktop window.

### 2. Feature Backlog

**Quick Wins (High Value, Small Scope):**
- Wire up the existing Device Flow OAuth logic to the UI.
- Expose the configurable entropy threshold via a slider in Settings.

**Medium Effort:**
- **Settings/Profile Screen:** Rotate PAT, adjust entropy threshold, toggle light/dark mode, configure default branch.
- **Scan History:** Persist past scans locally using the `data/local/` storage, providing a trend view of findings over time.
- **False-Positive Allowlist:** Implement per-repo `.devgateignore` or persistent allowlist to prevent re-flagging accepted findings.
- **Structured Log Viewer:** Fill out `ui/logs/` to display git operation output and scan history rather than just using `print()`.

**Ambitious / Roadmap:**
- **Custom Regex Editor:** Allow teams to define org-specific secret formats beyond the 22 built-in patterns.
- **Per-file Diff Viewer:** Show line-by-line diffs in the Git panel instead of just status badges.
- **Rich Export Options:** Export scan reports as HTML or PDF in addition to JSON for non-technical stakeholders.
- **CI/CD Integration:** Generate a GitHub Actions workflow file that runs the same local-first scan logic in CI pipelines.
