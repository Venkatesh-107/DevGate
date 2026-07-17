# DevGate — Architecture Document

> **Version:** 1.0.0 · **Last Updated:** 2026-07-15 · **Stack:** Flutter + Dart + Riverpod 3.x

---

## 1. High-Level Overview

DevGate is structured as a **layered desktop application** that blends Feature-First organization with Clean Architecture concepts. There is no backend server — all data flows stay on-device, and GitHub serves as the only optional external endpoint.

```
┌─────────────────────────────────────────────────────────────┐
│                        UI LAYER                             │
│  OnboardingScreen  │  DashboardScreen  │  GitPanelScreen    │
│                    │  └─ DropZoneWidget│                    │
└────────────────────┬──────────────────┬────────────────────┘
                     │  ref.watch/read  │
                     ▼                  ▼
┌─────────────────────────────────────────────────────────────┐
│                    STATE LAYER (Riverpod)                   │
│   scannerStateProvider ← ScannerNotifier ← ScannerState    │
│   gitProvider          ← GitNotifier     ← GitState        │
└────────────┬────────────────────────────┬───────────────────┘
             │                            │
             ▼                            ▼
┌────────────────────┐      ┌─────────────────────────────────┐
│   SCANNER ENGINE   │      │           GIT ENGINE            │
│  ├─ RegexEngine    │      │  ├─ GitEngine (Process.run CLI) │
│  ├─ EntropyMath    │      │  └─ GitResult / GitFile         │
│  └─ ScannerNotifier│      │                                 │
└────────────────────┘      └────────────────┬────────────────┘
                                             │
┌────────────────────┐      ┌────────────────▼────────────────┐
│    DATA / MODELS   │      │         GITHUB CLIENT           │
│  └─ Finding model  │      │  ├─ Device Flow OAuth           │
│     (type,severity,│      │  ├─ Create Repo (REST API)      │
│      snippet, line)│      │  └─ Push Report (REST API)      │
└────────────────────┘      └─────────────────────────────────┘
```

---

## 2. Layer Responsibilities

### 2.1 UI Layer (`lib/ui/`)

Responsible for rendering widgets and user interaction only. UI widgets **never** call git or scanner logic directly — they always go through Riverpod providers.

| Screen / Widget | Responsibility |
|---|---|
| `OnboardingScreen` | Collects name, GitHub username, PAT on first launch. Writes to `flutter_secure_storage`. |
| `DashboardScreen` | Shell with `NavigationRail` (desktop) / `NavigationBar` (mobile). Switches between Scanner and Git tabs. Also manages custom window title bar via `window_manager`. |
| `DropZoneWidget` | Accepts drag-and-drop folders via `desktop_drop`. Initiates scans via `ScannerNotifier`. Renders the results dashboard (security risks + architecture advice). |
| `GitPanelScreen` | Full Git workflow UI: pick project, init repo, link/create GitHub repo, stage files, commit, push (safe), pull. |

### 2.2 State Layer (`lib/engines/` — Notifiers)

Riverpod Notifiers act as the **ViewModel** layer. They hold application state and orchestrate calls to the lower engines.

| Notifier | State | Provider |
|---|---|---|
| `ScannerNotifier` | `ScannerState` (isScanning, currentFile, findings) | `scannerStateProvider` |
| `GitNotifier` | `GitState` (branch, remote, changedFiles, operation, output) | `gitProvider` |

**State is immutable** — all mutations go through `copyWith()` patterns.

### 2.3 Engine Layer (`lib/engines/`)

Pure Dart business logic with no Flutter dependencies.

**Scanner Engine:**
- `RegexEngine` — stateless, scans a line of text against 22 pre-compiled `RegExp` patterns
- `EntropyMath` — stateless, computes Shannon entropy of a string token
- `ScannerNotifier.scanDirectories()` — orchestrates file iteration, skips binary files and noisy directories, calls both engines per line

**Git Engine:**
- `GitEngine` — a thin wrapper around `Process.run('git', args, workingDirectory: ...)`. Every git command returns a `GitResult(success, output, error)`.
- `GIT_TERMINAL_PROMPT=0` is injected into the process environment to prevent interactive prompts from hanging the app.

### 2.4 Data Layer (`lib/data/`)

- **Models:** `Finding` — the single data model for all scanner output. Uses `FindingType` (regex/entropy/recommendation) and `Severity` (critical/high/medium/low) enums.
- **Remote:** `GitHubClient` — wraps the GitHub REST API using `Dio`. Manages token injection from `flutter_secure_storage`.
- **Local:** Currently handled entirely by `flutter_secure_storage` (no local database). The `lib/data/local/` directory is a reserved stub.

### 2.5 Core Layer (`lib/core/`)

| File | Contents |
|---|---|
| `app_theme.dart` | All visual design tokens, `ThemeData`, reusable `InputDecoration` and `BoxDecoration` helpers |
| `github_constants.dart` | OAuth `clientId` and `scopes` — the only configuration constant in the app |

---

## 3. State Flow Diagrams

### 3.1 Scan Flow

```
User drops folder / clicks Browse
         │
         ▼
DropZoneWidget.onDragDone()
         │
         ▼
ScannerNotifier.scanDirectories([paths])
         │
         ├─ setState(isScanning: true)
         │
         ├─ For each directory:
         │   ├─ Check pubspec.yaml → add recommendation Finding
         │   ├─ Check package.json → add recommendation Finding
         │   └─ For each text file:
         │       ├─ Skip if in .git / node_modules / build / .dart_tool / .pub-cache
         │       ├─ Read file content
         │       └─ For each line:
         │           ├─ RegexEngine.scanText(line) → 0..N regex Findings (severity: high)
         │           └─ EntropyMath.calculateEntropy(token) > 4.8 → entropy Finding (severity: medium)
         │
         └─ setState(isScanning: false, findings: allFindings)
                  │
                  ▼
         DropZoneWidget rebuilds → shows report dashboard
```

### 3.2 Safe Push Flow

```
User clicks "Safe Push" in GitPanelScreen
         │
         ▼
ScannerNotifier.scanDirectories([projectPath])
         │
         ▼
Read scannerStateProvider.findings
         │
         ├─ secrets.isEmpty → GitNotifier.push()
         │       │
         │       └─ GitEngine._run(['push', 'origin', branch])
         │
         └─ secrets.isNotEmpty → Show AlertDialog (block push)
                  │
                  └─ User can "Push Anyway" (override) or "Cancel Push"
```

### 3.3 Git Operations Flow

```
User picks project folder (getDirectoryPath)
         │
         ▼
GitNotifier.loadProject(dir)
         │
         ├─ GitEngine.isGitRepo() → false → state(isGitRepo: false)
         │
         └─ true → _refresh()
                  ├─ currentBranch()
                  ├─ remoteUrl()
                  ├─ status() → List<GitFile>
                  └─ log() → recent commits string
                  └─ state updated → GitPanelScreen rebuilds
```

---

## 4. Authentication Architecture

```
flutter_secure_storage (on-device encrypted keychain)
       │
       ├─ key: 'user_name'              → display name
       ├─ key: 'github_username'        → used as default repo owner
       └─ key: 'github_access_token'   → GitHub PAT
                    │
                    ├─ GitHubClient (Dio HTTP)
                    │       → injected as Bearer token in Authorization header
                    │
                    └─ GitEngine.setRemoteWithToken()
                            → embedded directly in HTTPS remote URL:
                              https://<token>@github.com/<owner>/<repo>.git
```

No token is ever sent to any server other than `api.github.com` and `github.com`.

---

## 5. Window Management (Desktop)

`window_manager` is initialized before `runApp()` for Linux / macOS / Windows:

- Window size: **1200 × 800** px, centered
- Title bar: **hidden** (`TitleBarStyle.hidden`) — custom AppBar is used instead
- Drag-to-move: `GestureDetector.onPanStart → windowManager.startDragging()`
- Close button: `windowManager.close()` rendered as an `IconButton`

Mobile/web fallback: standard `AppBar` with no window management.

---

## 6. Directory Structure Conventions

```
lib/
├── core/           # App-wide: theme, constants, utilities (no Flutter widget imports in constants)
├── data/
│   ├── models/     # Pure Dart data classes (no Flutter, no Riverpod)
│   ├── remote/     # API clients (Dio-based)
│   └── local/      # On-device persistence (currently: flutter_secure_storage directly in UI/notifiers)
├── engines/        # Business logic engines (pure Dart, may use Riverpod for state)
│   ├── git/        # Git CLI wrapper + Riverpod notifier
│   └── scanner/    # Secret scanner + Riverpod notifier
└── ui/             # Flutter widgets only; no business logic
    ├── onboarding/
    ├── dashboard/
    │   └── widgets/
    ├── git/
    └── logs/       # Reserved — not yet implemented
```

**Rule:** UI widgets → read/watch providers only. Engines → call models and other engines only. No circular dependencies.

---

## 7. Riverpod Pattern Used

All providers use the `NotifierProvider` pattern (Riverpod 3.x / code-gen-free):

```dart
// Definition
class MyNotifier extends Notifier<MyState> {
  @override
  MyState build() => const MyState();
  // ...methods
}

final myProvider = NotifierProvider<MyNotifier, MyState>(() => MyNotifier());

// Consumption
ref.watch(myProvider)           // reactive rebuild
ref.read(myProvider.notifier)   // call methods imperatively
```

State is always updated via `copyWith()` — no direct mutation of state fields.

---

## 8. Cross-Platform Compatibility

| Platform | Window Manager | Drop Zone | File Selector | Secure Storage |
|---|---|---|---|---|
| Linux | ✅ | ✅ | ✅ | ✅ (libsecret) |
| macOS | ✅ | ✅ | ✅ | ✅ (Keychain) |
| Windows | ✅ | ✅ | ✅ | ✅ (DPAPI) |
| Android | ❌ (skipped) | ❌ | ✅ | ✅ |
| iOS | ❌ (skipped) | ❌ | ✅ | ✅ (Keychain) |
| Web | ❌ (skipped) | ❌ | ✅ | ✅ (AES) |

Responsive layout: `MediaQuery.of(context).size.width < 600` switches between `NavigationBar` (mobile) and `NavigationRail` (desktop).

---

## 9. Identified Architectural Issues

| Issue | Location | Severity | Recommendation |
|---|---|---|---|
| `print()` used for error logging | `github_client.dart`, `scanner_engine.dart` | Medium | Replace with structured logger |
| Token embedded in git remote URL | `git_engine.dart:setRemoteWithToken` | Medium | Prefer git credential helper instead |
| `data/local/` directory unused | `lib/data/local/` | Low | Move `flutter_secure_storage` access here from UI/notifier layers |
| `GitHubConstants.clientId` is a placeholder | `core/constants/github_constants.dart` | High | Must be replaced with real OAuth App client ID before Device Flow works |
| No error boundary / global error handling | App-wide | Medium | Add `FlutterError.onError` and `PlatformDispatcher.instance.onError` |
| Scanner result not persisted | `ScannerNotifier` | Low | Results are in-memory only — lost on app restart |
