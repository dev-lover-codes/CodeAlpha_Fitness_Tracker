import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:fit_track/core/models/exercise.dart';
import 'package:fit_track/core/models/workout.dart';
import 'package:fit_track/core/models/workout_exercise.dart';
import 'package:fit_track/core/models/workout_set.dart';
import 'package:fit_track/core/models/streak.dart';
import 'package:fit_track/core/providers/auth_provider.dart';
import 'package:fit_track/core/providers/repository_providers.dart';
import 'package:fit_track/core/providers/profile_provider.dart';
import 'package:fit_track/core/providers/goals_provider.dart';

class PersonalRecord {
  final String exerciseName;
  final double weightKg;
  final int reps;
  final bool isWeightPr;

  const PersonalRecord({
    required this.exerciseName,
    required this.weightKg,
    required this.reps,
    required this.isWeightPr,
  });
}

class WorkoutSummary {
  final Workout workout;
  final List<PersonalRecord> prs;
  final Streak? updatedStreak;

  const WorkoutSummary({
    required this.workout,
    required this.prs,
    this.updatedStreak,
  });
}

/// FutureProvider that fetches the list of past workouts.
/// Reloads when the user authentication state changes.
final userWorkoutsProvider = FutureProvider<List<Workout>>((ref) async {
  final repository = ref.watch(workoutRepositoryProvider);
  ref.watch(authStateProvider);

  final currentUser = ref.read(authServiceProvider).currentUser;
  if (currentUser == null) return const [];

  return await repository.getWorkouts(currentUser.id);
});

/// NotifierProvider managing the state of an active in-progress workout session.
final activeWorkoutProvider = NotifierProvider<ActiveWorkoutNotifier, Workout?>(() {
  return ActiveWorkoutNotifier();
});

class ActiveWorkoutNotifier extends Notifier<Workout?> {
  final _uuid = const Uuid();
  static const _prefsKey = 'active_workout_session';

  @override
  Workout? build() {
    _loadFromPrefs();
    return null;
  }

  /// Asynchronously loads any active workout session stored in local preferences.
  Future<void> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_prefsKey);
      if (jsonStr != null) {
        final map = json.decode(jsonStr) as Map<String, dynamic>;
        state = _workoutFromFullJson(map);
      }
    } catch (e) {
      debugPrint("FitTrack: Failed to load active workout from local preferences: $e");
    }
  }

  /// Persists the current active workout session locally.
  Future<void> _saveToPrefs() async {
    if (state == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = json.encode(_workoutToFullJson(state!));
      await prefs.setString(_prefsKey, jsonStr);
    } catch (e) {
      debugPrint("FitTrack: Failed to save active workout to local preferences: $e");
    }
  }

  /// Clears any persisted active workout session.
  Future<void> _clearPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_prefsKey);
    } catch (e) {
      debugPrint("FitTrack: Failed to clear active workout from local preferences: $e");
    }
  }

  /// Starts a new active workout session.
  void startWorkout(String name, String userId) {
    state = Workout(
      id: 'temp_workout_${_uuid.v4()}',
      userId: userId,
      name: name,
      startedAt: DateTime.now(),
      createdAt: DateTime.now(),
      exercises: const [],
    );
    _saveToPrefs();
  }

  /// Discards the current workout session.
  void discardWorkout() {
    state = null;
    _clearPrefs();
  }

  /// Adds an exercise to the active workout session.
  void addExercise(Exercise exercise) {
    if (state == null) return;

    final exerciseId = 'temp_exercise_${_uuid.v4()}';
    final newWorkoutExercise = WorkoutExercise(
      id: exerciseId,
      workoutId: state!.id,
      exerciseId: exercise.id,
      orderIndex: state!.exercises.length,
      exercise: exercise,
      sets: [
        WorkoutSet(
          id: 'temp_set_${_uuid.v4()}',
          workoutExerciseId: exerciseId,
          setNumber: 1,
          reps: 10,
          weightKg: 0.0,
          completed: false,
        )
      ],
    );

    state = state!.copyWith(
      exercises: [...state!.exercises, newWorkoutExercise],
    );
    _saveToPrefs();
  }

  /// Removes an exercise from the active workout session.
  void removeExercise(String exerciseId) {
    if (state == null) return;

    final updatedList = state!.exercises
        .where((e) => e.id != exerciseId)
        .toList();

    // Re-adjust order indices
    for (int i = 0; i < updatedList.length; i++) {
      updatedList[i] = updatedList[i].copyWith(orderIndex: i);
    }

    state = state!.copyWith(exercises: updatedList);
    _saveToPrefs();
  }

  /// Adds a new set to a specific exercise.
  void addSet(String workoutExerciseId) {
    if (state == null) return;

    final updatedExercises = state!.exercises.map((exercise) {
      if (exercise.id != workoutExerciseId) return exercise;

      final lastSet = exercise.sets.isNotEmpty ? exercise.sets.last : null;
      final newSetNumber = exercise.sets.length + 1;
      
      final newSet = WorkoutSet(
        id: 'temp_set_${_uuid.v4()}',
        workoutExerciseId: workoutExerciseId,
        setNumber: newSetNumber,
        reps: lastSet?.reps ?? 10,
        weightKg: lastSet?.weightKg ?? 0.0,
        rpe: lastSet?.rpe,
        isWarmup: false,
        completed: false,
      );

      return exercise.copyWith(
        sets: [...exercise.sets, newSet],
      );
    }).toList();

    state = state!.copyWith(exercises: updatedExercises);
    _saveToPrefs();
  }

  /// Updates properties of a specific set.
  void updateSet(String workoutExerciseId, String setId, WorkoutSet updatedSet) {
    if (state == null) return;

    final updatedExercises = state!.exercises.map((exercise) {
      if (exercise.id != workoutExerciseId) return exercise;

      final updatedSets = exercise.sets.map((set) {
        return set.id == setId ? updatedSet : set;
      }).toList();

      return exercise.copyWith(sets: updatedSets);
    }).toList();

    state = state!.copyWith(exercises: updatedExercises);
    _saveToPrefs();
  }

  /// Removes a set from an exercise.
  void removeSet(String workoutExerciseId, String setId) {
    if (state == null) return;

    final updatedExercises = state!.exercises.map((exercise) {
      if (exercise.id != workoutExerciseId) return exercise;

      final filteredSets = exercise.sets.where((s) => s.id != setId).toList();

      // Recalculate set number ordering
      for (int i = 0; i < filteredSets.length; i++) {
        filteredSets[i] = filteredSets[i].copyWith(setNumber: i + 1);
      }

      return exercise.copyWith(sets: filteredSets);
    }).toList();

    state = state!.copyWith(exercises: updatedExercises);
    _saveToPrefs();
  }

  /// Computes final workout volume, saves to Supabase, updates streaks, calculates PRs, and returns WorkoutSummary.
  Future<WorkoutSummary> saveWorkout() async {
    if (state == null) {
      throw Exception("No active workout session found to save.");
    }

    final activeWorkout = state!;
    final completedAt = DateTime.now();
    final durationSeconds = completedAt.difference(activeWorkout.startedAt).inSeconds;
    final totalVolumeKg = _calculateTotalVolume(activeWorkout.exercises);

    final completedWorkout = activeWorkout.copyWith(
      completedAt: completedAt,
      durationSeconds: durationSeconds,
      totalVolumeKg: totalVolumeKg,
    );

    // 1. Fetch past workouts to compute PRs BEFORE saving this workout
    final pastWorkouts = ref.read(userWorkoutsProvider).value ?? [];

    // 2. Detect PRs
    final prs = _detectPRs(completedWorkout, pastWorkouts);

    // 3. Save to Supabase (creates workout, workout_exercises, sets)
    final workoutRepo = ref.read(workoutRepositoryProvider);
    final savedWorkout = await workoutRepo.createWorkout(completedWorkout);

    // 4. Update streaks
    final profileRepo = ref.read(profileRepositoryProvider);
    Streak? updatedStreak;
    try {
      updatedStreak = await profileRepo.updateStreak(completedWorkout.userId);
    } catch (e) {
      debugPrint("FitTrack: Failed to update streak on workout completion: $e");
    }

    // 5. Invalidate relevant providers to reload list and profiles
    ref.invalidate(userWorkoutsProvider);
    ref.invalidate(streakProvider);
    ref.invalidate(userProfileProvider);

    // 6. Auto-update strength PR and frequency goals
    final goalsNotifier = ref.read(goalsProvider.notifier);
    for (var pr in prs) {
      try {
        await goalsNotifier.autoUpdateStrengthGoals(pr.exerciseName, pr.weightKg);
      } catch (e) {
        debugPrint("FitTrack: Failed to auto-update strength goal: $e");
      }
    }
    try {
      await goalsNotifier.autoUpdateWorkoutFrequencyGoals([savedWorkout, ...pastWorkouts]);
    } catch (e) {
      debugPrint("FitTrack: Failed to auto-update frequency goal: $e");
    }

    // 7. Clear state and prefs
    state = null;
    await _clearPrefs();

    return WorkoutSummary(
      workout: savedWorkout,
      prs: prs,
      updatedStreak: updatedStreak,
    );
  }

  /// Helper to calculate the accumulated lift volume.
  double _calculateTotalVolume(List<WorkoutExercise> exercises) {
    double sum = 0.0;
    for (var exercise in exercises) {
      for (var set in exercise.sets) {
        if (set.completed && set.weightKg != null && set.reps != null) {
          sum += set.weightKg! * set.reps!;
        }
      }
    }
    return sum;
  }

  /// Detects personal records hit in the completed workout compared to past history.
  List<PersonalRecord> _detectPRs(Workout activeWorkout, List<Workout> pastWorkouts) {
    final List<PersonalRecord> prs = [];

    // Group past completed sets by exercise ID
    final Map<String, List<WorkoutSet>> pastSetsByExercise = {};
    for (var w in pastWorkouts) {
      for (var we in w.exercises) {
        pastSetsByExercise.putIfAbsent(we.exerciseId, () => []);
        for (var s in we.sets) {
          if (s.completed) {
            pastSetsByExercise[we.exerciseId]!.add(s);
          }
        }
      }
    }

    for (var we in activeWorkout.exercises) {
      final activeSets = we.sets.where((s) => s.completed).toList();
      if (activeSets.isEmpty) continue;

      // Find the best completed set in the active workout for this exercise
      WorkoutSet? bestActiveSet;
      for (var s in activeSets) {
        if (s.weightKg == null || s.reps == null) continue;
        if (bestActiveSet == null) {
          bestActiveSet = s;
        } else {
          if (s.weightKg! > bestActiveSet.weightKg!) {
            bestActiveSet = s;
          } else if (s.weightKg! == bestActiveSet.weightKg! && s.reps! > bestActiveSet.reps!) {
            bestActiveSet = s;
          }
        }
      }

      if (bestActiveSet == null) continue;

      final exerciseId = we.exerciseId;
      final exerciseName = we.exercise?.name ?? 'Exercise';
      final pastSets = pastSetsByExercise[exerciseId] ?? [];

      if (pastSets.isEmpty) {
        // First time doing this exercise - automatically a PR!
        prs.add(PersonalRecord(
          exerciseName: exerciseName,
          weightKg: bestActiveSet.weightKg!,
          reps: bestActiveSet.reps!,
          isWeightPr: true,
        ));
        continue;
      }

      // Find max weight in past sets
      double maxPastWeight = 0.0;
      for (var s in pastSets) {
        if (s.weightKg != null && s.weightKg! > maxPastWeight) {
          maxPastWeight = s.weightKg!;
        }
      }

      // Find max reps at that max weight in past sets
      int maxPastRepsAtMaxWeight = 0;
      for (var s in pastSets) {
        if (s.weightKg == maxPastWeight && s.reps != null && s.reps! > maxPastRepsAtMaxWeight) {
          maxPastRepsAtMaxWeight = s.reps!;
        }
      }

      if (bestActiveSet.weightKg! > maxPastWeight) {
        prs.add(PersonalRecord(
          exerciseName: exerciseName,
          weightKg: bestActiveSet.weightKg!,
          reps: bestActiveSet.reps!,
          isWeightPr: true,
        ));
      } else if (bestActiveSet.weightKg! == maxPastWeight && bestActiveSet.reps! > maxPastRepsAtMaxWeight) {
        prs.add(PersonalRecord(
          exerciseName: exerciseName,
          weightKg: bestActiveSet.weightKg!,
          reps: bestActiveSet.reps!,
          isWeightPr: false,
        ));
      }
    }

    return prs;
  }

  // --- CUSTOM FULL SERIALIZATION HELPERS FOR LOCAL PERSISTENCE ---

  Map<String, dynamic> _workoutToFullJson(Workout workout) {
    return {
      'id': workout.id,
      'user_id': workout.userId,
      'name': workout.name,
      'notes': workout.notes,
      'started_at': workout.startedAt.toIso8601String(),
      'completed_at': workout.completedAt?.toIso8601String(),
      'duration_seconds': workout.durationSeconds,
      'total_volume_kg': workout.totalVolumeKg,
      'created_at': workout.createdAt.toIso8601String(),
      'exercises': workout.exercises.map((e) => {
        'id': e.id,
        'workout_id': e.workoutId,
        'exercise_id': e.exerciseId,
        'order_index': e.orderIndex,
        'notes': e.notes,
        'exercise': e.exercise?.toJson(),
        'sets': e.sets.map((s) => s.toJson()).toList(),
      }).toList(),
    };
  }

  Workout _workoutFromFullJson(Map<String, dynamic> json) {
    final rawExercises = json['exercises'] as List? ?? [];
    final parsedExercises = rawExercises.map((eMap) {
      final e = eMap as Map<String, dynamic>;
      final rawSets = e['sets'] as List? ?? [];
      final parsedSets = rawSets.map((s) => WorkoutSet.fromJson(s as Map<String, dynamic>)).toList();
      final rawExercise = e['exercise'] as Map<String, dynamic>?;
      final parsedExercise = rawExercise != null ? Exercise.fromJson(rawExercise) : null;
      return WorkoutExercise(
        id: e['id'] as String,
        workoutId: e['workout_id'] as String,
        exerciseId: e['exercise_id'] as String,
        orderIndex: e['order_index'] as int,
        notes: e['notes'] as String?,
        sets: parsedSets,
        exercise: parsedExercise,
      );
    }).toList();

    return Workout(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      name: json['name'] as String,
      notes: json['notes'] as String?,
      startedAt: DateTime.parse(json['started_at'] as String),
      completedAt: json['completed_at'] != null ? DateTime.parse(json['completed_at'] as String) : null,
      durationSeconds: json['duration_seconds'] as int?,
      totalVolumeKg: (json['total_volume_kg'] as num? ?? 0.0).toDouble(),
      createdAt: DateTime.parse(json['created_at'] as String),
      exercises: parsedExercises,
    );
  }
}
