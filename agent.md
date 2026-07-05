<![CDATA[<div align="center">

```
██████╗ ███████╗██╗   ██╗ ██████╗  █████╗ ████████╗███████╗
██╔══██╗██╔════╝██║   ██║██╔════╝ ██╔══██╗╚══██╔══╝██╔════╝
██║  ██║█████╗  ██║   ██║██║  ███╗███████║   ██║   █████╗  
██║  ██║██╔══╝  ╚██╗ ██╔╝██║   ██║██╔══██║   ██║   ██╔══╝  
██████╔╝███████╗ ╚████╔╝ ╚██████╔╝██║  ██║   ██║   ███████╗
╚═════╝ ╚══════╝  ╚═══╝   ╚═════╝ ╚═╝  ╚═╝   ╚═╝   ╚══════╝
```

### ⚡ Desktop Security Intelligence Platform

**`v1.0.0`** · Flutter Desktop · Riverpod 3.x · Pure Dart Engines

*"Scan. Protect. Ship."*

</div>

---

> **📋 Agent Memory File** — This document is the single source of truth for any AI agent working on DevGate.
> Every file path, pattern, and status has been verified against the live codebase.
>
> **Last Verified:** `2026-07-05` · **SDK:** `^3.12.2` · **Path:** `/home/nikesh/Documents/flutter - ADBT/flutter-dev/devgate`

---

## 🧬 Identity & Vision

DevGate is a **Flutter Desktop application** (Linux/macOS/Windows) that serves as a **local-first, decentralized security tool** for developers. It scans codebases for leaked secrets, provides architecture recommendations, and integrates directly with GitHub for secure code management — all without any centralized server or cloud dependency.

### Core Principles

| Principle | Implementation |
|-----------|---------------|
| 🔒 **Zero Trust** | No PocketBase, no remote servers. Token stored via `flutter_secure_storage` on-device only |
| 🧠 **Intelligence** | Shannon entropy analysis + 11 regex patterns (TruffleHog-inspired) |
| 🛡️ **Pre-Push Guard** | Automatic secret scan before every `git push` — blocks if secrets detected |
| 📦 **Self-Contained** | Git operations via local CLI wrapper, no external git GUI dependency |
| 🎨 **Material 3** | Dark theme, Google Blue (`#4285F4`) seed, `#131314` surface |

---

## 🏛️ Architecture Blueprint

```
╔══════════════════════════════════════════════════════════════════╗
║                         UI LAYER                                ║
║  ┌──────────────┐  ┌──────────────┐  ┌─────────────────────┐   ║
║  │ Onboarding   │  │  Dashboard   │  │   Git Panel          │   ║
║  │ Screen       │  │  Screen      │  │   Screen             │   ║
║  │ (first-run)  │  │  + DropZone  │  │   + Setup Wizard     │   ║
║  │              │  │  + Report    │  │   + Commit Flow      │   ║
║  └──────┬───────┘  └──────┬───────┘  └──────────┬──────────┘   ║
║         │    ref.watch / ref.read                │              ║
║         ▼                  ▼                     ▼              ║
║  ┌─────────────────────────────────────────────────────────┐   ║
║  │              RIVERPOD STATE LAYER                       │   ║
║  │  scannerStateProvider ←── ScannerNotifier               │   ║
║  │  gitProvider          ←── GitNotifier                   │   ║
║  └────────────┬────────────────────────┬───────────────────┘   ║
╠═══════════════╪════════════════════════╪═══════════════════════╣
║               ▼                        ▼                       ║
║  ┌──────────────────────┐  ┌───────────────────────────┐      ║
║  │   SCANNER ENGINE     │  │      GIT ENGINE            │      ║
║  │   ├─ RegexEngine     │  │      ├─ GitEngine          │      ║
║  │   ├─ EntropyMath     │  │      │  (Process.run CLI)  │      ║
║  │   └─ Finding model   │  │      └─ GitResult/GitFile  │      ║
║  └──────────────────────┘  └───────────────────────────┐│      ║
║                                                        ││      ║
║  ┌──────────────────────┐  ┌───────────────────────────┘│      ║
║  │   DATA LAYER         │  │      GITHUB CLIENT          │      ║
║  │   └─ Finding (model) │  │      ├─ Device Flow auth    │      ║
║  │                      │  │      ├─ Create repo (API)   │      ║
║  │                      │  │      └─ Push report (API)   │      ║
║  └──────────────────────┘  └─────────────────────────────┘      ║
╚══════════════════════════════════════════════════════════════════╝
```

---

## 📁 File Map — Verified Source of Truth

> ✅ = Implemented & Working · 🔲 = Planned/Not Yet Created

```
devgate/
├── agent.md                                    ← THIS FILE (agent memory)
├── pubspec.yaml                                ✅ All deps installed
│
└── lib/
    ├── main.dart                               ✅ WindowManager + ProviderScope
    │                                              RootScreen → checks secure storage
    │                                              → OnboardingScreen (no profile)
    │                                              → DashboardScreen (has profile)
    │
    ├── core/
    │   └── constants/
    │       └── github_constants.dart           ✅ clientId + scopes (placeholder)
    │
    ├── data/
    │   ├── models/
    │   │   └── finding.dart                    ✅ Finding class + FindingType + Severity enums
    │   └── remote/
    │       └── github_client.dart              ✅ Device Flow + pollForToken + pushReport + createRepository
    │
    ├── engines/
    │   ├── git/
    │   │   ├── git_engine.dart                 ✅ Full git CLI wrapper (init/add/commit/push/pull/clone/remote)
    │   │   └── git_notifier.dart               ✅ GitNotifier + GitState + gitProvider
    │   │
    │   └── scanner/
    │       ├── scanner_engine.dart              ✅ ScannerNotifier + line-by-line scan + skip noisy dirs
    │       ├── regex_engine.dart                ✅ 11 patterns (AWS, Stripe, GH, Google, JWT, OpenAI, Slack, RSA, Twilio, SendGrid)
    │       └── entropy_math.dart               ✅ Shannon entropy (threshold: 4.8)
    │
    └── ui/
        ├── onboarding/
        │   └── onboarding_screen.dart          ✅ Name + GitHub username + PAT → secure storage
        │
        ├── dashboard/
        │   ├── dashboard_screen.dart           ✅ NavigationRail (Scanner | Git/GitHub) + draggable title bar
        │   └── widgets/
        │       └── drop_zone.dart              ✅ DropTarget + folder browse + scan trigger + report dashboard + JSON export
        │
        └── git/
            └── git_panel_screen.dart           ✅ Project picker + setup wizard + commit flow + pre-push scanner
```

---

## ⚙️ Feature Matrix

### Phase 1 — Desktop Shell `✅ COMPLETE`

| Feature | File | Details |
|---------|------|---------|
| Flutter Desktop window | `main.dart` | `window_manager` · 400×800 · hidden title bar |
| Custom draggable title bar | `dashboard_screen.dart` | `GestureDetector` → `windowManager.startDragging()` |
| Material 3 dark theme | `main.dart` | Seed: `#4285F4` · Surface: `#131314` · Rail: `#1E1E1E` |
| Navigation Rail | `dashboard_screen.dart` | Scanner + Git/GitHub tabs · mobile bottom nav fallback |

### Phase 2 — Scanner Engine `✅ COMPLETE`

| Feature | File | Details |
|---------|------|---------|
| Regex secret scanner | `regex_engine.dart` | 11 patterns · returns `List<String>` of matched labels |
| Shannon entropy calc | `entropy_math.dart` | `H = -Σ p·log₂(p)` · flags tokens with entropy > 4.8 |
| Structured Finding model | `finding.dart` | `FindingType` {regex, entropy, recommendation} + `Severity` |
| Line-by-line scanner | `scanner_engine.dart` | Splits by `\n`, scans each line, reports exact line numbers |
| Multi-directory scan | `scanner_engine.dart` | `scanDirectories(List<String>)` — iterates all paths |
| Noisy dir skip | `scanner_engine.dart` | Skips `.git`, `node_modules`, `.dart_tool`, `build`, `.pub-cache` |
| File size guard | `scanner_engine.dart` | Skips files > 1GB |
| Architecture recommendations | `scanner_engine.dart` | Detects `pubspec.yaml` / `package.json` → advice findings |
| Drag-and-drop scan | `drop_zone.dart` | `desktop_drop` + `DropTarget` widget |
| Browse folders | `drop_zone.dart` | `file_selector` → `getDirectoryPath()` |
| Report dashboard | `drop_zone.dart` | Split view: vulnerabilities (left) + recommendations (right) |
| JSON export | `drop_zone.dart` | `getSaveLocation()` → writes formatted JSON report |

### Phase 3 — Onboarding & Auth `✅ COMPLETE`

| Feature | File | Details |
|---------|------|---------|
| First-run onboarding | `onboarding_screen.dart` | Name + GitHub username + PAT input |
| Secure storage | `main.dart` + onboarding | `flutter_secure_storage` · keys: `user_name`, `github_username`, `github_access_token` |
| Profile gate | `main.dart` → `RootScreen` | Checks storage on init → routes to Onboarding or Dashboard |
| Decentralized security notice | `onboarding_screen.dart` | Green banner explaining zero-server architecture |

### Phase 4 — Git & GitHub Integration `✅ COMPLETE`

| Feature | File | Details |
|---------|------|---------|
| Git CLI wrapper | `git_engine.dart` | `Process.run('git', ...)` · init/add/commit/push/pull/clone/remote |
| Token-injected HTTPS remote | `git_engine.dart` | `https://$token@github.com/owner/repo.git` |
| Git config (user.name/email) | `git_engine.dart` | `configUser()` method |
| Git state management | `git_notifier.dart` | `GitState` + `GitNotifier` + `gitProvider` |
| Project folder picker | `git_panel_screen.dart` | `file_selector` → loads project into `gitProvider` |
| Auto `.gitignore` creation | `git_panel_screen.dart` | Creates standard `.gitignore` if missing on project load |
| Link existing repo wizard | `git_panel_screen.dart` | Owner + Repo name → `setRemoteWithToken()` |
| Create new repo wizard | `git_panel_screen.dart` | GitHub API `POST /user/repos` → auto-link |
| Stage + Commit + Push flow | `git_panel_screen.dart` | Full commit pipeline with message input |
| **Pre-push security scan** | `git_panel_screen.dart` | `_safePush()` — runs scanner → blocks if secrets found → shows dialog |
| Token update dialog | `git_panel_screen.dart` | Settings icon → update PAT securely |
| Profile badge sidebar | `git_panel_screen.dart` | Shows `@username` + recommendation cards + terminal output |
| GitHub Device Flow auth | `github_client.dart` | `requestDeviceCode()` + `pollForToken()` |
| Create repository API | `github_client.dart` | `POST /user/repos` with Bearer token |
| Push scan report API | `github_client.dart` | `PUT /repos/.../contents/.devgate/scan-reports/` |

---

## 🔬 Scanner Engine — Technical Deep Dive

### Scan Pipeline

```
User Action (Drop folder / Browse / Pre-push)
     │
     ▼
ScannerNotifier.scanDirectories(List<String> paths)
     │
     ├─── For each directory path:
     │      ├── Check pubspec.yaml → Flutter recommendation Finding
     │      ├── Check package.json → Node.js recommendation Finding
     │      │
     │      └── dir.list(recursive: true)
     │            │
     │            ├── _isProbablyTextFile(path)
     │            │     Scans: .dart .js .ts .json .yaml .yml .env
     │            │
     │            ├── Skip check: file > 1GB → skip
     │            ├── Skip check: path contains skipDirs → skip
     │            │     {.git, node_modules, .dart_tool, build, .pub-cache}
     │            │
     │            └── Read file → split('\n') → for each line:
     │                  │
     │                  ├── RegexEngine.scanText(line)
     │                  │     11 patterns → Finding(type: regex)
     │                  │
     │                  └── Entropy scan per token
     │                        token.length > 16 && no { } chars
     │                        EntropyMath.calculateEntropy(token)
     │                        threshold > 4.8 → Finding(type: entropy)
     │
     └─── State update: ScannerState(findings: allFindings)
```

### Regex Patterns (11 total)

| # | Pattern Name | Regex Signature | Case Sensitive |
|---|-------------|-----------------|----------------|
| 1 | AWS Access Key ID | `AKIA[A-Z0-9]{16}` | Yes |
| 2 | AWS Secret Access Key | `aws_secret_access_key\s*=...` | **No** |
| 3 | Stripe Standard API Key | `sk_live_[0-9a-zA-Z]{24}` | Yes |
| 4 | Stripe Restricted API Key | `rk_live_[0-9a-zA-Z]{24}` | Yes |
| 5 | GitHub PAT | `ghp_[0-9a-zA-Z]{36}` | Yes |
| 6 | Google API Key | `AIza[0-9A-Za-z_-]{35}` | Yes |
| 7 | Generic JWT | `eyJ[...]{10,}.[...]{10,}.[...]{10,}` | Yes |
| 8 | OpenAI API Key | `sk-[A-Za-z0-9]{48}` | Yes |
| 9 | Slack Bot Token | `xoxb-[0-9]{11}-[0-9]{11}-...` | Yes |
| 10 | RSA Private Key | `-----BEGIN RSA PRIVATE KEY-----` | Yes |
| 11 | Twilio API Key | `SK[0-9a-fA-F]{32}` | Yes |
| 12 | SendGrid API Key | `SG\.[...]{22}\.[...]{43}` | Yes |

---

## 🐙 Git Integration — How It Works

### Authentication Model

```
┌─────────────────────────────────────────────────────────────┐
│                    ONBOARDING (First Run)                    │
│                                                             │
│    User enters:  Full Name                                  │
│                  GitHub Username                            │
│                  GitHub PAT (Personal Access Token)          │
│                        │                                    │
│                        ▼                                    │
│              flutter_secure_storage                         │
│              ┌─────────────────────────┐                   │
│              │ user_name        → name │                   │
│              │ github_username  → user │                   │
│              │ github_access_token → ** │                   │
│              └─────────────────────────┘                   │
│                        │                                    │
│                        ▼                                    │
│              Token injected into HTTPS remote URL            │
│              https://{token}@github.com/owner/repo.git      │
└─────────────────────────────────────────────────────────────┘
```

### Pre-Push Security Flow

```
User clicks "Push to Remote"
     │
     ├── 1. Run full scanner on project directory
     │
     ├── 2. Filter findings: exclude FindingType.recommendation
     │
     ├── 3. If secrets found:
     │       → Show AlertDialog with red warning
     │       → "Found N potential secrets"
     │       → Block push entirely
     │       → User must clean secrets first
     │
     └── 4. If clean:
             → Execute git push via GitEngine
             → Show success in terminal output
```

---

## 📦 Dependencies — Verified from `pubspec.yaml`

| Package | Version | Purpose | Status |
|---------|---------|---------|--------|
| `flutter_riverpod` | `^3.3.2` | State management (Notifier pattern) | ✅ Installed |
| `window_manager` | `^0.5.1` | Custom title bar + window drag | ✅ Installed |
| `desktop_drop` | `^0.7.1` | Drag-and-drop folder input | ✅ Installed |
| `cross_file` | `^0.3.5+2` | File abstraction | ✅ Installed |
| `dio` | `^5.10.0` | GitHub API HTTP client | ✅ Installed |
| `flutter_secure_storage` | `^10.3.1` | Encrypted local token storage | ✅ Installed |
| `url_launcher` | `^6.3.2` | Open URLs in browser | ✅ Installed |
| `file_selector` | `^1.1.0` | Native folder/file picker dialogs | ✅ Installed |

---

## 🎨 Design System

```
Theme: Material 3 Dark
├── Seed Color:      #4285F4  (Google Blue)
├── Surface:         #131314  (near-black)
├── Card/Panel:      #1E1E1E  (elevated surface)
├── Border:          #3C4043  (subtle dividers)
├── Accent:          #8AB4F8  (light blue — buttons, highlights)
├── Loading BG:      #0F172A  (deep navy — splash/headers)
├── Success:         Colors.green / Colors.greenAccent
├── Danger:          Colors.redAccent
├── Warning:         Colors.orangeAccent
└── Text:
    ├── Primary:     Colors.white
    ├── Secondary:   Colors.white70
    └── Muted:       Colors.grey / Colors.grey.shade400
```

---

## 🚀 Roadmap — What's Next

### Phase 5 — Polish & Power Features

- [x] **[Theme]** Extract all colors into `lib/core/theme/app_theme.dart` — eliminate hardcoded hex values
- [x] **[Scanner]** Add `.txt` and `.md` file scanning (currently excluded to reduce noise)
- [x] **[Scanner]** Configurable entropy threshold (currently hardcoded at 4.8)
- [x] **[Scanner]** Add patterns: Anthropic keys, Azure keys, Firebase tokens, Supabase keys
- [ ] **[Git]** Pull request support — show remote/local diff before push
- [ ] **[Git]** Branch management — create/switch/delete branches from UI
- [ ] **[UI]** Settings screen — manage token, scan preferences, theme toggle
- [ ] **[UI]** Animated scan progress bar (replace simple `CircularProgressIndicator`)

### Phase 6 — Persistence & Analytics

- [ ] **[Data]** Add Isar/Hive DB for persistent scan history
- [ ] **[Data]** SecurityLog schema — track all scans with timestamps
- [ ] **[Analytics]** Scan trends dashboard — findings over time chart
- [ ] **[Export]** CSV/PDF export options alongside JSON

### Phase 7 — Advanced Intelligence

- [ ] **[Proxy]** Revive HTTP proxy engine (`shelf` + `shelf_proxy` — deps exist, UI not wired)
- [ ] **[Proxy]** Real-time header/payload inspection
- [ ] **[AI]** Local LLM integration for code review suggestions
- [ ] **[Watch]** Background `FileSystemEntity.watch()` for real-time monitoring

---

## ⚠️ Known Issues & Gotchas

| # | Issue | Location | Severity |
|---|-------|----------|----------|
| 1 | `github_constants.dart` has placeholder `clientId` | `core/constants/` | 🔴 Must replace before Device Flow works |
| 2 | `git_panel_screen.dart` has invalid relative import | Line 9: `../../../engines/` should be `../../engines/` | 🟡 May cause compile error |
| 3 | Proxy server code removed from file tree | Was `shelf`+`shelf_proxy` — deps still in pubspec | 🟢 Low — can rebuild |
| 4 | No error boundary on `_exportJson` map syntax | `drop_zone.dart` L378: `map` closure uses `{ }` not `=> { }` — may silently produce null entries | 🟡 Medium |
| 5 | `withOpacity()` deprecation warnings | Multiple files | 🟢 Low — cosmetic |

---

## 🧭 Agent Instructions

When working on this codebase, follow these rules:

1. **State Management** — Always use Riverpod `Notifier` pattern. No `StateProvider`, no `ChangeNotifier`.
2. **File Naming** — `snake_case.dart` for everything. Features go in `lib/ui/{feature}/`.
3. **No Server Calls** — DevGate is 100% local. Never add PocketBase, Supabase, or any centralized backend.
4. **Secure Storage** — All sensitive data (tokens, PATs) goes through `FlutterSecureStorage`. Never write tokens to plaintext files.
5. **Git Operations** — Always use `GitEngine` wrapper (which uses `Process.run`). Never shell out directly from UI code.
6. **Theme Colors** — Use the design system palette above. Primary accent is `#8AB4F8`, surface is `#131314`.
7. **Imports** — Use relative imports within the project. No `package:devgate/` self-imports.

---

<div align="center">

```
┌─────────────────────────────────────────────┐
│                                             │
│   Built with 🛡️ by the DevGate team         │
│   Security-first. Local-first. Always.      │
│                                             │
└─────────────────────────────────────────────┘
```

</div>
]]>
