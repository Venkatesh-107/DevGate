# DevGate — Agent Memory File

```
██████╗ ███████╗██╗   ██╗ ██████╗  █████╗ ████████╗███████╗
██╔══██╗██╔════╝██║   ██║██╔════╝ ██╔══██╗╚══██╔══╝██╔════╝
██║  ██║█████╗  ██║   ██║██║  ███╗███████║   ██║   █████╗
██║  ██║██╔══╝  ╚██╗ ██╔╝██║   ██║██╔══██║   ██║   ██╔══╝
██████╔╝███████╗ ╚████╔╝ ╚██████╔╝██║  ██║   ██║   ███████╗
╚═════╝ ╚══════╝  ╚═══╝   ╚═════╝ ╚═╝  ╚═╝   ╚═╝   ╚══════╝
```

> **Single source of truth for any AI agent or contributor working on DevGate.**
> Every path, pattern, and status is verified against the live codebase.
>
> **Last Verified:** `2026-07-15` · **SDK:** `^3.12.2` · **Package:** `getediv` · **Version:** `1.0.0+1`

---

## 1. Identity & Mission

**DevGate** is a **Flutter Desktop application** (Linux / macOS / Windows, mobile-responsive) that acts as a **local-first, decentralized security intelligence platform** for developers.

| Dimension | Value |
|---|---|
| Package name | `getediv` |
| Display name | `DevGate` |
| Version | `1.0.0+1` |
| Target platforms | Linux, macOS, Windows (primary); iOS, Android, Web (supported) |
| State management | Riverpod 3.x (`NotifierProvider`) |
| UI framework | Flutter + Material 3, dark theme |
| Auth strategy | GitHub Personal Access Token stored via `flutter_secure_storage` |
| External server | **None** — 100% local-first |

### Core Principles

| Principle | Implementation |
|---|---|
| **Zero Trust** | No centralized server. PAT stored on-device via `flutter_secure_storage` |
| **Pre-Push Guard** | Secret scan runs automatically before every `git push` |
| **Dual-Engine Scanning** | Shannon entropy + 22 TruffleHog-inspired regex patterns |
| **Self-Contained Git** | Git operations via `Process.run` CLI wrapper — no GUI dependencies |
| **Material 3 Dark UI** | Google Blue `#4285F4` seed, `#131314` surface, custom title bar |

---

## 2. Repository Map

```
getediv/
├── lib/
│   ├── main.dart                          # App entry point + RootScreen routing
│   ├── core/
│   │   ├── constants/
│   │   │   └── github_constants.dart      # OAuth client_id + scopes
│   │   ├── theme/
│   │   │   └── app_theme.dart             # Full design system (colors, decorations, ThemeData)
│   │   └── utils/                         # (empty — reserved for future helpers)
│   ├── data/
│   │   ├── models/
│   │   │   └── finding.dart               # Finding, FindingType, Severity enums
│   │   ├── remote/
│   │   │   └── github_client.dart         # GitHub API: device flow, create repo, push report
│   │   └── local/                         # (empty — storage handled by flutter_secure_storage)
│   ├── engines/
│   │   ├── git/
│   │   │   ├── git_engine.dart            # GitEngine: Process.run wrapper for git CLI
│   │   │   └── git_notifier.dart          # GitNotifier + GitState + gitProvider
│   │   └── scanner/
│   │       ├── scanner_engine.dart        # ScannerNotifier + ScannerState + scannerStateProvider
│   │       ├── regex_engine.dart          # RegexEngine: 22 secret-detection patterns
│   │       └── entropy_math.dart          # EntropyMath: Shannon entropy calculator
│   └── ui/
│       ├── onboarding/
│       │   └── onboarding_screen.dart     # First-run setup (name, GitHub username, PAT)
│       ├── dashboard/
│       │   ├── dashboard_screen.dart      # Main shell: NavigationRail + page switching
│       │   ├── widgets/
│       │   │   └── drop_zone.dart         # Drag-and-drop scanner UI + results dashboard
│       │   └── state/                     # (empty — scanner state lives in engines/)
│       ├── git/
│       │   └── git_panel_screen.dart      # Git operations UI (commit, push, pull, repo setup)
│       └── logs/
│           └── widgets/                   # (empty — reserved for future log viewer)
├── assets/
│   └── icon/
│       └── app_icon.png                   # App icon (all platforms)
├── pubspec.yaml                           # Dependencies + flutter_launcher_icons config
└── analysis_options.yaml                  # Lint rules
```

---

## 3. Key Providers

| Provider | Type | Location | Purpose |
|---|---|---|---|
| `scannerStateProvider` | `NotifierProvider<ScannerNotifier, ScannerState>` | `engines/scanner/scanner_engine.dart` | Drives all scanning (regex + entropy) |
| `gitProvider` | `NotifierProvider<GitNotifier, GitState>` | `engines/git/git_notifier.dart` | Drives all git operations |

---

## 4. Data Models

### `Finding` (`data/models/finding.dart`)
```dart
class Finding {
  final FindingType type;        // regex | entropy | recommendation
  final String label;            // Human-readable name (e.g. "AWS Access Key ID")
  final String filePath;
  final int lineNumber;
  final String snippet;          // The matching line or token
  final double? entropyScore;    // Set for entropy findings
  final Severity severity;       // critical | high | medium | low
  final DateTime detectedAt;
}
```

### `GitFile` (`engines/git/git_engine.dart`)
```dart
class GitFile {
  final String status;           // 'M', 'A', 'D', '?', 'R'
  final String path;
  String get statusLabel;        // 'Modified', 'Added', 'Deleted', 'Untracked', 'Renamed'
}
```

### `GitState` (`engines/git/git_notifier.dart`)
```dart
class GitState {
  final bool isGitRepo;
  final String currentBranch;
  final String remoteUrl;
  final String recentLog;
  final List<GitFile> changedFiles;
  final GitOperation operation;  // idle | staging | committing | pushing | pulling | cloning
  final String operationOutput;
  final bool hasError;
}
```

---

## 5. Scanner Engine Details

### RegexEngine — 22 Patterns (`engines/scanner/regex_engine.dart`)

| Category | Patterns Covered |
|---|---|
| Cloud Providers | AWS Access Key ID, AWS Secret Key, Google API Key, Azure Storage Key, Firebase Config, Supabase Key |
| Payment | Stripe Standard Key, Stripe Restricted Key |
| AI / LLM | OpenAI API Key, Anthropic API Key |
| Version Control | GitHub PAT, GitHub Fine-Grained PAT, npm Token |
| Messaging | Slack Bot Token, Discord Bot Token, Twilio API Key, SendGrid API Key, Mailgun API Key |
| Infrastructure | Heroku API Key |
| Cryptographic | RSA Private Key, Generic Private Key, Generic JWT |

### EntropyMath (`engines/scanner/entropy_math.dart`)
- Implements **Shannon entropy**: `H = -Σ p(x) log₂ p(x)`
- Default threshold: **4.8 bits** (configurable in `scanDirectories()`)
- Only tokens with `length > 16` and no `{` or `}` are evaluated (reduces false positives)

### Scanner Skip List
Directories automatically excluded from scans: `.git`, `node_modules`, `.dart_tool`, `build`, `.pub-cache`

### Supported File Types
`.dart`, `.js`, `.ts`, `.json`, `.yaml`, `.yml`, `.txt`, `.md`, `.env`

---

## 6. Git Engine Operations (`engines/git/git_engine.dart`)

| Method | Git Command |
|---|---|
| `isGitRepo()` | `git rev-parse --is-inside-work-tree` |
| `getRepoRoot()` | `git rev-parse --show-toplevel` |
| `status()` | `git status --porcelain -uall` |
| `currentBranch()` | `git rev-parse --abbrev-ref HEAD` |
| `remoteUrl()` | `git remote get-url origin` |
| `log(count)` | `git log --oneline -N` |
| `addAll()` | `git add .` |
| `addFile(path)` | `git add <path>` |
| `addFiles(paths)` | `git add <path1> <path2> ...` |
| `resetFile(path)` | `git restore --staged <path>` |
| `commit(msg)` | `git commit -m <message>` |
| `push()` | `git push origin <branch>` |
| `pull()` | `git pull origin <branch>` |
| `init()` | `git init --initial-branch=main` |
| `addRemote(url)` | `git remote add origin <url>` |
| `setRemoteUrl(url)` | `git remote set-url origin <url>` |
| `clone(url, dest)` | `git clone <url> <dest>` (static) |
| `configUser(name, email)` | `git config user.name / user.email` |
| `setRemoteWithToken(...)` | Injects token into HTTPS remote URL |

---

## 7. GitHub Client (`data/remote/github_client.dart`)

| Method | Endpoint | Description |
|---|---|---|
| `requestDeviceCode()` | `POST /login/device/code` | Starts Device Flow OAuth |
| `pollForToken(code, interval)` | `POST /login/oauth/access_token` | Polls until user authorizes |
| `createRepository(name)` | `POST /user/repos` | Creates GitHub repo (private by default) |
| `pushReport(owner, repo, data)` | `PUT /repos/:owner/:repo/contents/.devgate/scan-reports/:file` | Commits JSON report to repo |

**Token storage key:** `github_access_token` (via `flutter_secure_storage`)
**OAuth client ID location:** `core/constants/github_constants.dart` → `GitHubConstants.clientId`

> ⚠️ `clientId` is currently a placeholder `'YOUR_OAUTH_APP_CLIENT_ID'` — must be set before Device Flow auth works.

---

## 8. Screen Routing

```
App Start
  └─ main() → ProviderScope → DevGateApp → RootScreen
       ├─ checks flutter_secure_storage for 'user_name' + 'github_access_token'
       ├─ if missing → OnboardingScreen (first-run setup)
       └─ if present → DashboardScreen
            ├─ [0] Scanner tab → DropZoneWidget (scan + report dashboard)
            └─ [1] Git/GitHub tab → GitPanelScreen (git operations + repo management)
```

---

## 9. Theme Design Tokens (`core/theme/app_theme.dart`)

| Token | Value | Usage |
|---|---|---|
| `surface` | `#131314` | Main scaffold background |
| `card` | `#1E1E1E` | Elevated card surfaces |
| `border` | `#3C4043` | Subtle dividers |
| `accent` | `#8AB4F8` | Primary action color (light blue) |
| `seedBlue` | `#4285F4` | Google Blue — navigation indicator |
| `deepNavy` | `#0F172A` | Headers, stat bar background |
| `divider` | `#334155` | Secondary dividers |
| `success` | `Colors.green` | Positive states |
| `danger` | `Colors.redAccent` | Risks, errors |
| `warning` | `Colors.orangeAccent` | Warnings |
| `info` | `Colors.blueAccent` | Informational |

---

## 10. Dependency Reference

| Package | Version | Purpose |
|---|---|---|
| `flutter_riverpod` | `^3.3.2` | State management |
| `window_manager` | `^0.5.1` | Desktop window control (custom title bar, drag) |
| `desktop_drop` | `^0.7.1` | Drag-and-drop folder support |
| `cross_file` | `^0.3.5+2` | Cross-platform file abstraction |
| `dio` | `^5.10.0` | HTTP client for GitHub API calls |
| `flutter_secure_storage` | `^10.3.1` | Encrypted on-device token storage |
| `url_launcher` | `^6.3.2` | Open URLs (GitHub OAuth pages) |
| `file_selector` | `^1.1.0` | Native folder/file picker dialogs |
| `cupertino_icons` | `^1.0.8` | iOS-style icons |

---

## 11. Known Gaps & Future Work

| Area | Status | Notes |
|---|---|---|
| `lib/core/utils/` | Empty | Intended for shared helper utilities |
| `lib/data/local/` | Empty | Local persistence beyond secure storage |
| `lib/ui/logs/widgets/` | Empty | Log viewer UI not yet implemented |
| `lib/ui/dashboard/state/` | Empty | Scanner state lives in `engines/` — may be reorganized |
| `GitHubConstants.clientId` | Placeholder | Must be replaced with a real GitHub OAuth App Client ID |
| Device Flow OAuth | Built, not wired to UI | `GitHubClient.requestDeviceCode()` exists but the UI trigger is not implemented |
| Error handling | Minimal | `print()` calls throughout — needs structured logging |
| Tests | Minimal | `test/` directory exists but is essentially empty |
| Entropy threshold | Hardcoded `4.8` | Should be user-configurable |
| File size limit bug | `> 1000 * 1024 * 1024` = 1 GB | Likely meant `> 1 * 1024 * 1024` (1 MB) |
