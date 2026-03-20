# Vibe Demo

A Flutter web boilerplate optimized for rapid prototyping and vibe coding.

## Quick Start

```bash
# Install dependencies
flutter pub get

# Run on web (Chrome) — debug mode
flutter run -d chrome

# Run on web (Chrome) — release mode
flutter run -d chrome --release
```

## Pre-installed Packages

- `firebase_core` - Firebase initialization
- `firebase_auth` - Authentication (email/password, Google, etc.)
- `cloud_firestore` - Cloud Firestore database
- `http` - HTTP requests
- `provider` - Simple state management
- `google_fonts` - Custom fonts

## Firebase Setup (Full Walkthrough)

### 1. Create a Firebase project

1. Go to [console.firebase.google.com](https://console.firebase.google.com)
2. Click **Add project**, give it a name, and follow the wizard
3. Once created, you'll land on the project dashboard

### 2. Enable Authentication

1. In the Firebase Console, go to **Security > Authentication**
2. Click **Get started**
3. Under **Sign-in method**, enable the providers you need (e.g. **Email/Password**)

### 3. Enable Cloud Firestore (database)

1. In the Firebase Console, go to **Build > Firestore Database**
2. Click **Create database**
3. Choose **Start in test mode** for prototyping (allows all reads/writes — tighten rules before going to production)
4. Select a Cloud Firestore location and click **Enable**

### 4. Install tools & configure the Flutter app

```bash
# Install the Firebase CLI (one-time, requires Node.js / npm)
npm install -g firebase-tools

# Log in to Firebase
firebase login

# Install the FlutterFire CLI (one-time)
dart pub global activate flutterfire_cli

# Configure Firebase for this Flutter project (generates lib/firebase_options.dart)
flutterfire configure
```

Select your project when prompted. This generates `lib/firebase_options.dart` with
all the keys and IDs the app needs — no manual copy-pasting required.

### 5. Set up Firebase Hosting (static web)

```bash
# Initialise hosting in the project root
firebase init hosting

# When prompted:
#   - Select your Firebase project
#   - Set public directory to: build/web
#   - Configure as single-page app: Yes
#   - Do NOT overwrite index.html if asked

# Build the Flutter web app
flutter build web

# Deploy to Firebase Hosting
firebase deploy --only hosting
```

Your app will be live at `https://<your-project>.web.app`.

### Quick usage example

```dart
import 'firebase_config.dart';

// Fetch data from Firestore
final snapshot = await db.collection('todos').get();
final todos = snapshot.docs.map((d) => d.data()).toList();

// Insert data
await db.collection('todos').add({'title': 'New todo'});

// Auth - sign in
await auth.signInWithEmailAndPassword(email: email, password: password);

// Auth - current user
final user = auth.currentUser;
```

## Tips for Vibe Coding

1. **Start simple** - Build the UI first, add logic later
2. **Iterate fast** - Hot reload is your friend
3. **Don't over-engineer** - Working code beats perfect code
4. **Use AI** - Let Cursor help you build features quickly

## VS Code / Cursor Launch

Two launch configurations are provided in `.vscode/launch.json`:

- **Flutter Web (Debug)** — Chrome, debug mode (hot reload, DevTools)
- **Flutter Web (Release)** — Chrome, release mode (production-like performance)

Press F5 and select the configuration you need.
