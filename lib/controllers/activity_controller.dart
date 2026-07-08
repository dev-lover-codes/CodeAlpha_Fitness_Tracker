import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/fitness_activity.dart';
import '../services/local_storage_service.dart';

/// State class to hold activity data.
class ActivityState {
  final List<FitnessActivity> dailyActivities;
  final List<FitnessActivity> weeklyActivities;
  final bool isLoading;
  final int dailyCalorieGoal;
  final String? error;

  ActivityState({
    this.dailyActivities = const [],
    this.weeklyActivities = const [],
    this.isLoading = false,
    this.dailyCalorieGoal = 2000, // Default calorie goal
    this.error,
  });

  ActivityState copyWith({
    List<FitnessActivity>? dailyActivities,
    List<FitnessActivity>? weeklyActivities,
    bool? isLoading,
    int? dailyCalorieGoal,
    String? error,
  }) {
    return ActivityState(
      dailyActivities: dailyActivities ?? this.dailyActivities,
      weeklyActivities: weeklyActivities ?? this.weeklyActivities,
      isLoading: isLoading ?? this.isLoading,
      dailyCalorieGoal: dailyCalorieGoal ?? this.dailyCalorieGoal,
      error: error,
    );
  }
}

/// Provider for the LocalStorageService.
final localStorageServiceProvider = Provider<LocalStorageService>((ref) {
  return LocalStorageService();
});

/// Modern Riverpod Notifier to manage Fitness Activities state.
class ActivityController extends Notifier<ActivityState> {
  late final LocalStorageService _storageService;

  @override
  ActivityState build() {
    _storageService = ref.read(localStorageServiceProvider);

    // Asynchronously trigger initial load on creation
    Future.microtask(() => loadActivities());

    return ActivityState();
  }

  /// Fetch both daily and weekly activities for a given date (defaults to today).
  Future<void> loadActivities({DateTime? targetDate}) async {
    final date = targetDate ?? DateTime.now();
    state = state.copyWith(isLoading: true, error: null);

    try {
      final daily = await _storageService.fetchActivitiesForDay(date);
      final weekly = await _storageService.fetchActivitiesForPast7Days(date);

      state = state.copyWith(
        dailyActivities: daily,
        weeklyActivities: weekly,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: "Failed to load activities: ${e.toString()}",
      );
    }
  }

  /// Add a new activity. The UI is updated instantly by fetching new data.
  Future<bool> addActivity({
    required String type,
    required int durationInMinutes,
    required int caloriesBurned,
    required DateTime timestamp,
  }) async {
    final newActivity = FitnessActivity(
      id: DateTime.now().millisecondsSinceEpoch.toString(), // unique string ID
      type: type,
      durationInMinutes: durationInMinutes,
      caloriesBurned: caloriesBurned,
      timestamp: timestamp,
    );

    state = state.copyWith(isLoading: true, error: null);

    try {
      // 1. Save to Local Storage
      await _storageService.addActivity(newActivity);

      // 2. Reload data from storage to update UI state
      await loadActivities();
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: "Failed to add activity: ${e.toString()}",
      );
      return false;
    }
  }

  /// Delete an activity. Updates the UI instantly by reloading.
  Future<void> deleteActivity(String id) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _storageService.deleteActivity(id);
      await loadActivities();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: "Failed to delete activity: ${e.toString()}",
      );
    }
  }

  /// Update the daily calorie goal.
  void updateDailyCalorieGoal(int goal) {
    state = state.copyWith(dailyCalorieGoal: goal);
  }
}

/// Provider that exposes the ActivityController and its state.
final activityControllerProvider =
    NotifierProvider<ActivityController, ActivityState>(ActivityController.new);
