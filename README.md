# FitTrack (Fitness Tracker App)

FitTrack is a modern Fitness Tracker application built in Flutter with a Supabase backend, Riverpod state management, and declarative routing via GoRouter.

---

## 🏗️ Architecture & Folder Structure

The project adopts a clean, feature-first structure to ensure modularity and scalability:

```
lib/
├── core/
│   ├── constants/             # App-wide constant definitions (constants.dart)
│   ├── theme/                 # Light & Dark themes with an electric green fitness palette
│   ├── utils/                 # Utility files and helper formatters
│   ├── widgets/               # Reusable UI widgets shared across multiple features
│   ├── router/                # Declarative navigation setup (go_router)
│   ├── models/                # App-wide data models
│   ├── services/
│   │   └── supabase/          # API & database services for Supabase
│   └── providers/             # Global Riverpod state providers
│
└── features/                  # Feature-specific modules
    ├── auth/                  # Authentication screens (Splash, Login, Signup)
    ├── dashboard/             # App summary dashboard and stats home
    ├── workouts/              # Workout logging and session planners
    ├── exercises/             # Exercise library and details
    ├── progress/              # Visual progress charts and weight tracking
    ├── nutrition/             # Diet tracking and water logging
    ├── goals/                 # Personal fitness and nutrition goals
    ├── profile/               # User profile info and statistics
    └── settings/              # App configurations and preferences
```

---

## 🛠️ Installation & Getting Started

### Prerequisites

* Flutter SDK (`>= 3.35.0`)
* Dart SDK (`>= 3.9.0`)

### Setup

1. **Install dependencies**:
   ```bash
   flutter pub get
   ```

2. **Configure Environment variables**:
   Modify the `.env` file at the root of the project (which is added to `.gitignore` to protect keys) with your Supabase credentials:
   ```env
   SUPABASE_URL=https://your-supabase-url.supabase.co
   SUPABASE_ANON_KEY=your-supabase-anon-key
   ```
   *Note: If the `.env` file has default placeholder keys, the app will run successfully and bypass Supabase initialization logs.*

3. **Run Locally**:
   To start the development server:
   ```bash
   flutter run
   ```
