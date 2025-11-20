# QuickNotes

A modern, cross-platform note-taking application built with Flutter and Firebase.

## Features

- 📝 Create and manage notes (text and checklist)
- 🏷️ Organize notes with color tags
- 📦 Archive and restore notes
- ⭐ Favorite important notes
- 🌓 Light and dark theme support
- 🔄 Real-time synchronization across devices
- 📴 **Offline mode** - Create and edit notes without internet
- 🔐 Secure authentication with Firebase
- 📱 Cross-platform (Android, iOS, Web, Desktop)
- ⚡ Optimized performance with instant UI updates
- 🎯 Smart caching and memoization
- 🚀 Optimistic UI updates for faster user experience
- 🧹 Clean, maintainable codebase with zero duplicate code

## Tech Stack

- **Frontend**: Flutter (Dart)
- **Backend**: Firebase (Authentication + Firestore)
- **State Management**: Provider (with Consumer/Selector for optimized rebuilds)
- **Real-time Database**: Cloud Firestore
- **Environment Variables**: flutter_dotenv for secure configuration

## Getting Started

### Prerequisites

- Flutter SDK (latest stable version)
- Firebase project with Firestore and Authentication enabled
- `.env` file with Firebase configuration (see `ENV_TEMPLATE.txt`)

### Installation

1. Clone the repository:
   ```bash
   git clone <repository-url>
   cd quicknotes
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Set up Firebase:
   - Create a Firebase project at [Firebase Console](https://console.firebase.google.com)
   - Enable Authentication (Email/Password)
   - Create a Firestore database
   - Copy your Firebase configuration to `.env` file (see `ENV_TEMPLATE.txt`)

4. Deploy Firestore security rules:
   - Copy rules from `FIRESTORE_RULES.txt`
   - Deploy to Firebase Console > Firestore Database > Rules

5. Run the app:
   ```bash
   flutter run
   ```

## Project Structure

See [SYSTEM_OVERVIEW.md](SYSTEM_OVERVIEW.md) for detailed architecture and system documentation.

## Security

- All API keys are stored in `.env` file (not committed to Git)
- Firestore security rules ensure user data isolation
- Secure authentication with Firebase Auth
- No sensitive data in source code
- Comprehensive error handling with user-friendly messages
- Web platform type error suppression (LegacyJavaScriptObject)

## Performance Features

- **Optimistic UI Updates**: Notes appear instantly when added/updated/deleted
- **Smart Rebuilds**: Only affected widgets rebuild using Selector/Consumer
- **Memoized Computations**: Cached filtering and date formatting
- **Immediate Navigation**: Fast navigation with background operations
- **Efficient List Rendering**: ListView with keys for optimal scrolling
- **Stream Optimization**: Only updates UI when data actually changes
- **Offline Persistence**: Firestore caches data locally for offline access
- **Auto-sync**: Changes sync automatically when connection restored

## Code Quality

- **Zero Duplicate Code**: Centralized helper utilities for common operations
- **Type Safety**: Comprehensive Dart type checking
- **Error Handling**: Graceful degradation with user-friendly messages
- **Clean Architecture**: Organized project structure with clear separation of concerns
- **Performance Optimized**: Memoization and smart caching throughout

## Building for Production

```bash
# Android
flutter build apk --release
flutter build appbundle --release

# iOS
flutter build ios --release

# Web
flutter build web --release
```

## Documentation

- [System Overview](SYSTEM_OVERVIEW.md) - Complete system architecture and documentation
- [Firestore Rules](FIRESTORE_RULES.txt) - Security rules for Firestore
- [Environment Template](ENV_TEMPLATE.txt) - Template for `.env` file

## License

[Add your license information here]
