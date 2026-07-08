# FitTracker (CodeAlpha_Fitness_Tracker)

FitTracker is a comprehensive, production-ready, local-first Fitness Tracking application built in Flutter. The application adopts a clean modular architecture, strictly separating the UI layer, state management, and backend local data services.

---

## 🚀 Key Features

* **Interactive Energy Dashboard**:
  * **Circular Calorie Ring**: A custom-painted gradient sweep progress ring with a sweep-in animation showing today's calories burned against a customizable daily target.
  * **Weekly Active Minutes Chart**: An interactive bar chart aggregating logged workout durations over the past 7 days with tooltips, custom grids, and responsive scaling.
  * **Today's Recent Workouts**: A scrollable list of today's activities showing tailored icons and color palettes matching the workout type.
* **Manual Workout Logging**:
  * A Floating Action Button (FAB) that triggers a bottom sheet logging form.
  * Inputs for workout type (Running, Walking, Cycling, Yoga, Gym), duration (minutes), calories burned, and date/time.
  * Strict form input validation (preventing empty submissions or negative numbers) with automated confirmation snackbars.
* **Dynamic Theme Support**:
  * Seamless support for system Light and Dark themes dynamically read via `Theme.of(context)` to ensure zero text contrast issues.
  * Premium color schemes (Indigo, Emerald, Amber) and custom shadow-elevation cards.

---

## 🏗️ Architecture & Folder Structure

The project strictly decouples business logic, data persistence, and rendering layers:

```
lib/
├── models/
│   └── fitness_activity.dart         # FitnessActivity data model (JSON converters)
├── services/
│   └── local_storage_service.dart    # SharedPreferences database persistence CRUD
├── controllers/
│   ├── activity_controller.dart      # Notifiers & providers managing activities state
│   └── theme_provider.dart           # Notifiers & providers managing theme state
├── theme/
│   └── app_theme.dart                # Material 3 light/dark styles, colors & shapes
├── views/
│   └── dashboard_view.dart           # Main dashboard layout screen
├── widgets/
│   ├── activity_card.dart            # List element card showing logged workouts
│   ├── calorie_progress_indicator.dart # Custom-painted daily calorie ring indicator
│   ├── weekly_active_minutes_chart.dart # Interactive bar chart using fl_chart
│   └── add_activity_modal.dart       # Bottom sheet logging modal with form validations
└── main.dart                         # Entry point wrapping the app in ProviderScope
```

### Unidirectional Data Flow

The application implements a predictable unidirectional data flow managed by **Riverpod**:

```
[UI View Component] ──(Dispatches Action)──► [Riverpod Notifier Controller]
        ▲                                                │
        │ (Rebuilds on state update)                     │ (Invokes Save/Fetch)
        │                                                ▼
  [ActivityState] ◄──(Pushes New State)─── [Local Storage Service]
                                                   │
                                                   ▼
                                       [SharedPreferences Cache]
```

---

## 🛠️ Installation & Getting Started

### Prerequisites

* Flutter SDK (`>= 3.35.0`)
* Dart SDK (`>= 3.9.0`)

### Running Locally

1. Clone this repository to your machine.
2. Install the necessary dependencies:
   ```bash
   flutter pub get
   ```
3. Run the development server or start on a target emulator:
   ```bash
   flutter run
   ```

### Production Build

To compile a release APK for Android deployment:
```bash
flutter build apk --release
```
The resulting package will be generated at `build/app/outputs/flutter-apk/app-release.apk`.
