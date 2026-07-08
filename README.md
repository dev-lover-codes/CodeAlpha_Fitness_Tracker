<div align="center">

# 🏋️ FitTrack

**A comprehensive, open-source fitness tracking app built with Flutter and Supabase.**

[![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=for-the-badge&logo=Flutter&logoColor=white)](https://flutter.dev/)
[![Supabase](https://img.shields.io/badge/Supabase-3ECF8E?style=for-the-badge&logo=supabase&logoColor=white)](https://supabase.com/)
[![Dart](https://img.shields.io/badge/dart-%230175C2.svg?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev/)

</div>

---

## 🌟 Overview

FitTrack is a modern, cross-platform mobile application designed to help users track their fitness journey comprehensively. Whether you're lifting weights, monitoring your macros, or tracking your physical transformation, FitTrack brings all your data into one seamless, beautifully designed interface.

## ✨ Features

### 🏋️ Workout Logging
* **Exercise Library**: Search and add exercises to your routines.
* **Real-time Tracking**: Log sets, reps, and weights during your workout.
* **Workout History**: View past workouts and track volume over time.

### 🥗 Nutrition & Macro Tracking
* **Daily Goals**: Set custom targets for calories, protein, carbohydrates, and fats.
* **Meal Logging**: Easily log Breakfast, Lunch, Dinner, and Snacks.
* **Visual Progress**: Daily macro rings and weekly trend charts to keep you accountable.

### 📈 Progress & Measurements
* **Body Stats**: Track weight, body fat %, and precise muscle measurements (chest, waist, arms, etc.).
* **Progress Photos**: Upload and visually compare before/after transformation photos.
* **Strength Charts**: Visualize your 1RM (One Rep Max) progression on your top exercises.

### 🔔 Smart Notifications
* **Streak Protection**: Receive reminders to log a workout before your streak expires.
* **Goal Deadlines**: Gentle nudges when a fitness goal deadline is approaching.

### ⚙️ Customization
* **Unit System**: Seamlessly toggle between Metric (kg/cm) and Imperial (lbs/in).
* **Themes**: Beautiful Dark, Light, and System themes built with Material 3.

## 🚀 Tech Stack

* **Frontend**: Flutter (Dart)
* **State Management**: Riverpod 3.0 (`AsyncNotifier` & `Notifier`)
* **Backend**: Supabase (PostgreSQL, Authentication, Storage)
* **Local Storage**: SharedPreferences
* **Charts**: fl_chart
* **Notifications**: flutter_local_notifications (with Java 8 core library desugaring support)

## 🛠️ Getting Started

### Prerequisites
* [Flutter SDK](https://flutter.dev/docs/get-started/install) (latest stable)
* A [Supabase](https://supabase.com/) project
* Android Studio / Xcode

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/dev-lover-codes/CodeAlpha_Fitness_Tracker.git
   cd CodeAlpha_Fitness_Tracker
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure Environment Variables**
   Create an `.env` file at the root of the project with your Supabase credentials:
   ```env
   SUPABASE_URL=your_project_url
   SUPABASE_ANON_KEY=your_anon_key
   ```

4. **Run the App**
   ```bash
   flutter run
   ```

## 📦 Releases

Compiled Android APKs are available in the [Releases](../../releases) section. 

* Download the latest `app-release.apk`.
* Install it directly onto your Android device.

## 🤝 Contributing

Contributions, issues, and feature requests are welcome! Feel free to check the [issues page](../../issues).

## 📝 License

This project is licensed under the MIT License.
