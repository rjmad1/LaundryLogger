# Tech Stack

## Overview

Laundry Logger is built as a Flutter monorepo with offline-first architecture, prioritizing reliability and user experience.

## Core Technologies

### Frontend Framework
- **Flutter 3.16+** — Cross-platform UI framework
- **Dart 3.2+** — Programming language

### State Management
- **flutter_bloc / Bloc** — Predictable state management
- **Equatable** — Value equality for state comparison

### Local Database
- **sqflite** — SQLite plugin for Flutter (offline-first persistence)
- **drift** (optional) — Type-safe database queries

### Dependency Injection
- **get_it** — Service locator for DI
- **injectable** — Code generation for DI

### Navigation
- **go_router** — Declarative routing

### Security
- **flutter_secure_storage** — Encrypted key-value storage
- **local_auth** — Biometric/PIN authentication

### Export & Reporting
- **pdf** — PDF generation
- **csv** — CSV file generation
- **share_plus** — Share files across apps

### UI Components
- **Material 3** — Modern Material Design
- **flutter_slidable** — Swipe actions
- **reorderable_grid** — Drag-and-drop reordering

### Testing
- **flutter_test** — Unit and widget testing
- **integration_test** — Integration testing
- **mocktail** — Mocking library

### Code Quality
- **flutter_lints** — Recommended lint rules
- **very_good_analysis** — Strict analysis options

## Architecture

```
┌─────────────────────────────────────────────┐
│                  UI Layer                    │
│         (Widgets, Pages, Components)         │
├─────────────────────────────────────────────┤
│              Presentation Layer              │
│            (BLoC, State, Events)             │
├─────────────────────────────────────────────┤
│               Domain Layer                   │
│       (Entities, Use Cases, Repositories)    │
├─────────────────────────────────────────────┤
│                Data Layer                    │
│    (Data Sources, Models, Local Storage)     │
└─────────────────────────────────────────────┘
```

### Layer Responsibilities

1. **UI Layer** — Flutter widgets, screens, and UI components
2. **Presentation Layer** — BLoC/Cubit for state management
3. **Domain Layer** — Business logic, entities, and repository interfaces
4. **Data Layer** — SQLite database, data models, and implementations

## Database Schema

### Core Tables

- `items` — Laundry item definitions (name, default rate, category)
- `transactions` — Journal entries (item, quantity, status, date)
- `household_members` — Family members for tagging
- `rates` — Custom pricing overrides
- `settings` — App configuration

## Offline-First Strategy

1. **SQLite as source of truth** — All data persisted locally
2. **No network dependency** — App works completely offline
3. **Export for sharing** — CSV/PDF for external use
4. **Encrypted backups** — Secure data portability

## Future Considerations

- Cloud sync (optional, user-controlled)
- Multi-device support
- Family sharing with role-based access
