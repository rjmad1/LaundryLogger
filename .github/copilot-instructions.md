# LaundryLogger Project Instructions

## Project Overview
LaundryLogger is an offline-first Flutter mobile application for households to track clothing items sent to and received from ironing professionals.

## Tech Stack
- **Framework:** Flutter 3.16+ / Dart 3.2+
- **State Management:** flutter_bloc
- **Database:** sqflite (SQLite)
- **DI:** get_it + injectable
- **Navigation:** go_router
- **Security:** flutter_secure_storage, local_auth

## Project Structure
```
/laundry-logger
├── /mobile          # Flutter app
│   ├── lib/
│   │   ├── core/    # Theme, DI, Router
│   │   └── features/# Feature modules
│   └── test/
├── /docs            # Documentation
├── /agents          # Copilot agent profiles
└── /.github         # CI/CD workflows
```

## Coding Standards
- Use `const` constructors where possible
- Follow BLoC pattern for state management
- Use clean architecture (presentation/domain/data layers)
- Write tests for all business logic
- Document public APIs with dartdoc comments

## Development Checklist

- [x] Create copilot-instructions.md file
- [x] Clarify Project Requirements
- [x] Scaffold the Project
- [x] Install Required Extensions (Flutter)
- [ ] Install Flutter SDK (manual step)
- [ ] Run `flutter pub get` in /mobile
- [ ] Launch the Project

## Getting Started
1. Install Flutter SDK: https://docs.flutter.dev/get-started/install
2. Run `flutter pub get` in the mobile directory
3. Run `flutter run` to launch the app
