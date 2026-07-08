import 'package:fit_track/core/models/workout.dart';
import 'package:fit_track/core/models/goal.dart';
import 'package:fit_track/core/models/profile.dart';
import 'package:fit_track/core/models/streak.dart';
import 'package:fit_track/core/services/supabase/workout_repository.dart';
import 'package:fit_track/core/services/supabase/goal_repository.dart';
import 'package:fit_track/core/services/supabase/profile_repository.dart';

class FakeWorkoutRepository implements WorkoutRepository {
  List<Workout> workouts = [];

  @override
  Future<List<Workout>> getWorkouts(String userId, {int? limit, int? offset}) async {
    return workouts.where((w) => w.userId == userId).toList();
  }

  @override
  Future<Workout> saveWorkout(Workout workout) async {
    workouts.add(workout);
    return workout;
  }

  @override
  Future<void> createWorkout(Workout workout) async {
    workouts.add(workout);
  }

  @override
  Future<void> deleteWorkout(String workoutId) async {
    workouts.removeWhere((w) => w.id == workoutId);
  }
}

class FakeGoalRepository implements GoalRepository {
  List<Goal> goals = [];

  @override
  Future<List<Goal>> getGoals(String userId) async {
    return goals.where((g) => g.userId == userId).toList();
  }

  @override
  Future<Goal> saveGoal(Goal goal) async {
    final index = goals.indexWhere((g) => g.id == goal.id);
    if (index >= 0) {
      goals[index] = goal;
    } else {
      goals.add(goal);
    }
    return goal;
  }

  @override
  Future<void> createGoal(Goal goal) async {
    goals.add(goal);
  }

  @override
  Future<void> updateGoal(Goal goal) async {
    final index = goals.indexWhere((g) => g.id == goal.id);
    if (index >= 0) {
      goals[index] = goal;
    }
  }

  @override
  Future<void> updateGoalProgress(String goalId, double currentProgress) async {
    final index = goals.indexWhere((g) => g.id == goalId);
    if (index >= 0) {
      goals[index] = goals[index].copyWith(currentValue: currentProgress);
    }
  }

  @override
  Future<void> deleteGoal(String goalId) async {
    goals.removeWhere((g) => g.id == goalId);
  }
}

class FakeProfileRepository implements ProfileRepository {
  Profile? currentProfile;
  Streak? currentStreak;

  @override
  Future<Profile?> getProfile(String userId) async {
    return currentProfile;
  }

  @override
  Future<Profile> updateProfile(Profile profile) async {
    currentProfile = profile;
    return profile;
  }

  @override
  Future<Streak?> getStreak(String userId) async {
    return currentStreak;
  }

  @override
  Future<Streak> updateStreak(String userId) async {
    currentStreak = Streak(
      id: '1',
      userId: userId,
      currentStreak: 2,
      longestStreak: 2,
      lastWorkoutDate: DateTime.now(),
    );
    return currentStreak!;
  }
}
