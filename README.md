# Vocaboo

A Cebuano Mother Tongue-First vocabulary acquisition app for Filipino children (ages 9-12) that uses first-language anchoring and spaced repetition principles to improve English vocabulary learning.

## 🛠️ Tech Stack

**Frontend (Mobile)**
- Flutter 3.41.8
- Dart
- Android (API 34+), iOS, Web, Linux, macOS, Windows
- SharedPreferences (local storage)
- HTTP package (API communication)

**Backend (API Server)**
- Java 17+
- Spring Boot 3.x
- Spring Data JPA
- Maven build tool

**Database**
- PostgreSQL (production via Supabase)
- H2 (development)

**Admin Panel**
- React JS
- HTTPS communication with backend

**External Services**
- Text-to-Speech (TTS) - pronunciation playback
- Automatic Speech Recognition (ASR) - pronunciation evaluation
- AI Language Model API - sandbox vocabulary generation
- Supabase - cloud database & authentication

## 📱 Flutter Setup Guide

### Prerequisites
Before setting up, make sure you have:
- **Flutter SDK** (3.41.8+) - [Install Flutter](https://flutter.dev/docs/get-started/install)
- **Dart SDK** (comes with Flutter)
- **Android Studio** or **Xcode** (for emulator/device)
- **Git** (for cloning repo)

### Step 1: Clone the Repository
```bash
git clone <your-repo-url>
cd Vocaboo
```

### Step 2: Navigate to Mobile Directory
```bash
cd mobile
```

### Step 3: Get Flutter Dependencies
```bash
flutter pub get
```

### Step 4: Verify Flutter Setup
```bash
flutter doctor
```
Make sure all items show a checkmark ✓

### Step 5: Run the App

**On Android Emulator:**
```bash
flutter run
```

**On Physical Device (Android):**
1. Connect via USB with USB debugging enabled
2. Run: `flutter run`

**Select Target Device:**
```bash
flutter devices  # List available devices
flutter run -d <device-id>  # Run on specific device
```

### Step 6: Backend Connection (Optional)
For API integration, the backend must be running:
```bash
# In a separate terminal from the mobile directory
cd backend
./mvnw spring-boot:run
```

The app will connect to `http://10.0.2.2:8080` (Android emulator localhost)

## 🔄 Development Workflow

**Hot Reload** (Quick Updates)
- Press `r` in terminal to reload code changes
- Press `R` for full app restart

**Troubleshooting:**
```bash
# Clear build cache
flutter clean

# Get dependencies again
flutter pub get

# Rebuild from scratch
flutter run --no-fast-start
```

## 📂 Project Structure

```
mobile/
├── lib/
│   ├── main.dart                 # App entry point
│   ├── models/
│   │   └── learner_model.dart
│   ├── screens/
│   │   └── onboarding/          # Onboarding UI screens
│   ├── services/
│   │   └── learner_service.dart  # API communication
│   └── utils/
│       └── local_storage.dart    # SharedPreferences wrapper
├── pubspec.yaml                  # Dependencies
└── test/
    └── widget_test.dart
```
