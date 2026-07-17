# DevGate — Design System

> **Version:** 1.1.0 · **Last Updated:** 2026-07-17

This document serves as the single source of truth for the visual design, colors, and typography used in the DevGate application. It has been updated to focus on legibility, semantic severity, and developer-friendly monospace integration.

---

## 1. Color Palette

The application uses a dark-mode-first aesthetic with Google-inspired blue accents and clean, muted dark surfaces. Semantic colors are explicitly selected for accessibility and immediate threat recognition.

### Core Colors
| Token Name | Hex Value | Usage |
|---|---|---|
| **Seed Blue** | `#4285F4` | Primary brand color, seed for Material 3 ColorScheme. |
| **Surface** | `#131314` | Main application background (near-black). |
| **Card** | `#1E1E1E` | Elevated card surfaces and panels. |
| **Border** | `#3C4043` | Subtle dividers and outlines for inputs/cards. |
| **Accent** | `#8AB4F8` | Primary interactive elements, buttons, and active states. |
| **Deep Navy** | `#0F172A` | Secondary background for headers and input fields. |
| **Divider** | `#334155` | Secondary, slightly more visible dividers. |

### Semantic Colors
| Token Name | Hex Value | Usage |
|---|---|---|
| **Success** | `#10B981` (Emerald 500) | Success states, secure findings. |
| **Danger** | `#EF4444` (Red 500) | Critical alerts, exposed secrets, errors. |
| **Warning** | `#F59E0B` (Amber 500) | Medium-severity findings, warnings. |
| **Info** | `#3B82F6` (Blue 500) | Informational messages, focused borders. |
| **Secret Mask**| `#2A1414` | Dark red-black background for masking sensitive plaintext snippets. |

### Text Colors
| Token Name | Value | Usage |
|---|---|---|
| **Primary** | `Colors.white` | Main headings and body text. |
| **Secondary** | `Colors.white70` | Subtitles, secondary descriptions. |
| **Muted** | `Colors.grey` | Disabled text, placeholders, very low-priority info. |

---

## 2. Typography & Fonts

DevGate relies on a deliberate two-family typography system utilizing the `google_fonts` package. 

| Role | Font Family | Justification |
|---|---|---|
| **UI / Body** | `Inter` | Neutral, highly legible at small sizes, provides a crisp modern aesthetic. |
| **Code / Data**| `JetBrains Mono` | Critical for snippets, commit hashes, paths, and scores. Monospace prevents ambiguity between characters (`0` vs `O`, `1` vs `l`) to aid precise security auditing. |

### Type Scale
| Style | Font / Size / Weight | Used For |
|---|---|---|
| `displaySmall` | Inter / 28 / 600 | Screen titles ("Security Scan Results") |
| `titleMedium` | Inter / 16 / 600 | Card headers, finding labels |
| `bodyMedium` | Inter / 14 / 400 | Descriptions, paragraph text |
| `labelSmall` | Inter / 12 / 500 | Status badges, section eyebrows (uppercase + tracking) |
| `codeStyle` | JetBrains Mono / 13 / 400 | Snippets, file paths, tokens, branch/commit refs |

---

## 3. UI Components

### Cards & Panels
- **Background**: `Card` (`#1E1E1E`)
- **Border Radius**: `16px`
- **Border**: `1px solid #3C4043`

### Input Fields
- **Background**: `Deep Navy` (`#0F172A`)
- **Border Radius**: `12px`
- **Idle Border**: `1px solid Colors.grey.shade800`
- **Focused Border**: `1px solid Info (#3B82F6)`
- **Padding**: Horizontal `16px`, Vertical `14px`

---

## 4. Layout Metrics
- **Window Size (Desktop)**: 1280 × 720 (Default constraints set natively).
- **Navigation**: Uses `NavigationRail` for wide screens (desktop) and `NavigationBar` for mobile form factors.

*Note: All design implementations should strictly reference `AppTheme` in `lib/core/theme/app_theme.dart` rather than hardcoding values in UI widgets.*
