import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fit_track/core/models/goal.dart';
import 'package:fit_track/core/models/workout.dart';
import 'package:fit_track/core/providers/repository_providers.dart';
import 'package:fit_track/core/providers/auth_provider.dart';
import 'package:fit_track/core/providers/workouts_provider.dart';

/// Provider exposing the list of active goals for the user.
final goalsProvider = AsyncNotifierProvider<GoalsNotifier, List<Goal>>(() {
  return GoalsNotifier();
});

class GoalsNotifier extends AsyncNotifier<List<Goal>> {
  @override
  Future<List<Goal>> build() async {
    ref.watch(authStateProvider);
    final currentUser = ref.read(authServiceProvider).currentUser;
    if (currentUser == null) return const [];
    final repo = ref.read(goalRepositoryProvider);
    return await repo.getGoals(currentUser.id);
  }

  Future<Goal> addGoal(Goal goal) async {
    final repo = ref.read(goalRepositoryProvider);
    final created = await repo.createGoal(goal);
    ref.invalidateSelf();
    return created;
  }

  Future<void> deleteGoal(String goalId) async {
    final repo = ref.read(goalRepositoryProvider);
    await repo.deleteGoal(goalId);
    ref.invalidateSelf();
  }

  Future<void> updateGoalProgress(Goal goal, double newValue) async {
    final repo = ref.read(goalRepositoryProvider);

    // Determine completion based on goal type & direction
    String newStatus = goal.status;
    bool isCompleted = false;

    if (goal.goalType == 'weight') {
      // Weight loss vs weight gain direction check:
      // If we don't have initial, we check if target is reached
      // Let's assume weight loss if target < current at creation, or if target value is crossed.
      // If targetValue was smaller than currentValue, we complete when newValue <= targetValue.
      // If targetValue was larger, we complete when newValue >= targetValue.
      // E.g. target 75kg, current 80kg -> complete when weight <= 75.
      // To be safe, we can inspect both directions:
      final isLoss = goal.targetValue < goal.currentValue;
      if (isLoss && newValue <= goal.targetValue) {
        isCompleted = true;
      } else if (!isLoss && newValue >= goal.targetValue) {
        isCompleted = true;
      }
    } else {
      // For strength_pr, workout_frequency, custom: complete when newValue >= targetValue
      if (newValue >= goal.targetValue) {
        isCompleted = true;
      }
    }

    if (isCompleted) {
      newStatus = 'completed';
    }

    final updatedGoal = goal.copyWith(
      currentValue: newValue,
      status: newStatus,
    );

    await repo.updateGoal(updatedGoal);

    if (isCompleted) {
      ref.read(justCompletedGoalProvider.notifier).state = updatedGoal;
    }

    ref.invalidateSelf();
  }

  /// Automatically updates matching weight goals.
  Future<void> autoUpdateWeightGoals(double weight) async {
    final activeGoals = state.value ?? [];
    for (final goal in activeGoals) {
      if (goal.goalType == 'weight' && goal.status == 'active') {
        await updateGoalProgress(goal, weight);
      }
    }
  }

  /// Automatically updates matching strength goals.
  Future<void> autoUpdateStrengthGoals(String exerciseName, double maxWeight) async {
    final activeGoals = state.value ?? [];
    for (final goal in activeGoals) {
      if (goal.goalType == 'strength_pr' &&
          goal.status == 'active' &&
          goal.unit.toLowerCase() == exerciseName.toLowerCase()) {
        if (maxWeight > goal.currentValue) {
          await updateGoalProgress(goal, maxWeight);
        }
      }
    }
  }

  /// Automatically updates workout frequency goals.
  Future<void> autoUpdateWorkoutFrequencyGoals([List<Workout>? customWorkoutsList]) async {
    final activeGoals = state.value ?? [];
    
    final List<Workout> workouts;
    if (customWorkoutsList != null) {
      workouts = customWorkoutsList;
    } else {
      final workoutsAsync = ref.read(userWorkoutsProvider);
      workouts = workoutsAsync.value ?? [];
    }

    // Calculate workouts this week (Monday to Sunday)
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final startOfWeekDay = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
    final thisWeeksWorkouts = workouts.where((w) => w.startedAt.isAfter(startOfWeekDay)).toList();
    final workoutCount = thisWeeksWorkouts.length.toDouble();

    for (final goal in activeGoals) {
      if (goal.goalType == 'workout_frequency' && goal.status == 'active') {
        await updateGoalProgress(goal, workoutCount);
      }
    }
  }
}

/// Helper state provider to hold the newly completed goal for confetti animations
final justCompletedGoalProvider = NotifierProvider<JustCompletedGoalNotifier, Goal?>(() {
  return JustCompletedGoalNotifier();
});

class JustCompletedGoalNotifier extends Notifier<Goal?> {
  @override
  Goal? build() => null;

  @override
  set state(Goal? value) => super.state = value;
}
