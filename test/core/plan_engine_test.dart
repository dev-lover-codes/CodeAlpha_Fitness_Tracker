import 'package:flutter_test/flutter_test.dart';
import 'package:fit_track/core/models/exercise.dart';
import 'package:fit_track/core/models/profile.dart';
import 'package:fit_track/core/services/plan_engine.dart';

Exercise ex(String name, String cat, String muscle, String diff, {String equip = 'Dumbbells'}) => Exercise(
      id: name,
      name: name,
      category: cat,
      muscleGroup: muscle,
      equipment: equip,
      difficulty: diff,
      isCustom: false,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );

final library = [
  ex('Bench Press (Barbell)', 'strength', 'chest', 'intermediate'),
  ex('Push-up', 'strength', 'chest', 'beginner', equip: 'Bodyweight'),
  ex('Chest Fly (Dumbbell)', 'strength', 'chest', 'beginner'),
  ex('Deadlift (Barbell)', 'strength', 'back', 'advanced'),
  ex('Pull-up', 'strength', 'back', 'intermediate'),
  ex('Lat Pulldown (Cable)', 'strength', 'back', 'beginner'),
  ex('Single Arm Row (Dumbbell)', 'strength', 'back', 'beginner'),
  ex('Back Squat (Barbell)', 'strength', 'legs', 'intermediate'),
  ex('Leg Press', 'strength', 'legs', 'beginner'),
  ex('Lunge (Dumbbell)', 'strength', 'legs', 'beginner'),
  ex('Lateral Raise (Dumbbell)', 'strength', 'shoulders', 'beginner'),
  ex('Bicep Curl (Dumbbell)', 'strength', 'arms', 'beginner'),
  ex('Plank', 'strength', 'core', 'beginner', equip: 'Bodyweight'),
  ex('Ab Wheel Rollout', 'strength', 'core', 'advanced'),
  ex('Running (Outdoor)', 'cardio', 'cardio', 'beginner'),
  ex('Stationary Bike', 'cardio', 'cardio', 'beginner'),
  ex('Swimming', 'cardio', 'cardio', 'beginner'),
  ex('Hamstring Stretch', 'flexibility', 'legs', 'beginner'),
];

Profile profile({String goal = 'build_muscle', String activity = 'Moderately Active', double weight = 75, int age = 28}) =>
    Profile(
      id: 'u',
      fullName: 'Test User',
      heightCm: 178,
      weightKg: weight,
      dateOfBirth: DateTime(DateTime.now().year - age, 1, 1),
      gender: 'Male',
      fitnessGoal: goal,
      activityLevel: activity,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );

void main() {
  test('muscle goal, moderately active → 4-day upper/lower with lifting first', () {
    final plan = PlanEngine.build(profile: profile(), exercises: library);
    expect(plan.daysPerWeek, 4);
    expect(plan.week.map((s) => s.name), ['Upper body', 'Lower body', 'Upper body', 'Lower body']);
    expect(plan.recommended.first.exercise.category, 'strength');
    expect(plan.nutrition!.calories, greaterThan(plan.nutrition!.maintenanceCalories));
  });

  test('beginners never get advanced exercises', () {
    final plan = PlanEngine.build(profile: profile(activity: 'Sedentary'), exercises: library);
    final all = plan.week.expand((s) => s.exercises).map((p) => p.exercise.difficulty);
    expect(all, isNot(contains('advanced')));
    expect(plan.daysPerWeek, 3);
  });

  test('weight loss puts calories below maintenance and includes cardio', () {
    final plan = PlanEngine.build(profile: profile(goal: 'lose_weight'), exercises: library);
    expect(plan.nutrition!.calories, lessThan(plan.nutrition!.maintenanceCalories));
    expect(plan.week.expand((s) => s.exercises).any((p) => p.exercise.category == 'cardio'), isTrue);
  });

  test('high BMI prefers low-impact cardio over running', () {
    final plan = PlanEngine.build(profile: profile(goal: 'lose_weight', weight: 120), exercises: library);
    final cardio = plan.recommended.where((s) => s.exercise.category == 'cardio').toList();
    expect(cardio.first.exercise.name, isNot('Running (Outdoor)'));
  });

  test('accepts display-style goal labels from older profiles', () {
    expect(parseGoal('Build Muscle'), FitnessGoal.buildMuscle);
    expect(parseGoal('Improve Endurance'), FitnessGoal.endurance);
    expect(parseGoal(null), FitnessGoal.maintain);
  });

  test('no exercise appears twice in one session', () {
    final plan = PlanEngine.build(profile: profile(activity: 'Very Active'), exercises: library);
    for (final s in plan.week) {
      final ids = s.exercises.map((p) => p.exercise.id).toList();
      expect(ids.toSet().length, ids.length, reason: s.name);
    }
  });
}
