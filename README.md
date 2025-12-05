# Laundry Logger

**Offline-First Mobile App for Household Laundry Tracking**

Laundry Logger is a lightweight, offline-first mobile application for households to track clothing items sent to and received from ironing professionals. It replaces paper logs and memory-based tracking with a structured, mobile-first workflow.

## ✨ Key Features

- **CRUD for Laundry Items** — Add, edit, delete clothing items with customizable rates
- **Electronic Laundry Journal** — Offline SQLite persistence for reliable data storage
- **Full Hand-off Workflow** — Send → In Progress → Returned status tracking
- **Spend Analytics** — Monthly/weekly summaries and spending trends
- **Household Member Tagging** — Per-person cost tracking
- **Notes & Overrides** — Special pricing, multi-rate items support
- **Export Options** — CSV/PDF export capabilities
- **Secure Backup** — Encrypted backup & restore functionality
- **PIN Protection** — Secure storage with PIN-protected access
- **Drag-and-Drop** — Reorder items across lists
- **Quick Templates** — Favorites and personalized UI
- **Role Support** — Future-proof admin vs helper access

## 📱 Supported Platforms

- **Android** (primary release target)
- **iOS** (fully supported)

## 🏗️ Project Structure

```
/laundry-logger
├── /mobile               # Flutter app (primary)
│   ├── lib/             # Dart source code
│   ├── test/            # Unit and widget tests
│   ├── android/         # Android platform files
│   └── ios/             # iOS platform files
│
├── /docs                # Architecture, schema, UX docs
├── /agents              # Copilot agent profiles
├── /.github/workflows   # CI/CD configurations
│
├── README.md
├── TECH_STACK.md
├── TESTING.md
├── AGENTS.md
└── CHANGELOG.md
```

## 🚀 Getting Started

### Prerequisites

1. **Flutter SDK** (3.16+): https://docs.flutter.dev/get-started/install
2. **Android Studio** or **VS Code** with Flutter extension
3. **Xcode** (for iOS development on macOS)

### Installation

```bash
# Clone the repository
git clone https://github.com/your-org/laundry-logger.git
cd laundry-logger/mobile

# Install dependencies
flutter pub get

# Run the app
flutter run
```

### Development

```bash
# Run tests
flutter test

# Build Android APK
flutter build apk

# Build iOS (macOS only)
flutter build ios
```

## 📖 Documentation

- [Tech Stack](./TECH_STACK.md) — Technologies and architecture decisions
- [Testing Strategy](./TESTING.md) — Testing approach and guidelines
- [Agents](./AGENTS.md) — Multi-agent Copilot support configuration
- [Changelog](./CHANGELOG.md) — Version history and updates

## 🔒 Security

- PIN-protected app access
- Encrypted local database
- Secure backup/restore with encryption

## 📄 License

MIT License - See [LICENSE](./LICENSE) for details.
