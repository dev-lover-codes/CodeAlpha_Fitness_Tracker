import 'package:fit_track/core/models/exercise.dart';
import 'package:fit_track/core/models/profile.dart';

/// Builds a training + nutrition plan from the user's profile.
///
/// Everything here is plain rule-based logic (no network calls), so the plan
/// updates instantly whenever the profile changes.

enum FitnessGoal { loseWeight, buildMuscle, maintain, endurance }

enum Experience { beginner, intermediate, advanced }

FitnessGoal parseGoal(String? raw) {
  final v = (raw ?? '').toLowerCase().replaceAll(' ', '_');
  if (v.contains('lose')) return FitnessGoal.loseWeight;
  if (v.contains('muscle')) return FitnessGoal.buildMuscle;
  if (v.contains('endurance')) return FitnessGoal.endurance;
  return FitnessGoal.maintain;
}

String goalLabel(FitnessGoal g) => switch (g) {
      FitnessGoal.loseWeight => 'Lose weight',
      FitnessGoal.buildMuscle => 'Build muscle',
      FitnessGoal.maintain => 'Stay fit',
      FitnessGoal.endurance => 'Build endurance',
    };

String experienceLabel(Experience e) => switch (e) {
      Experience.beginner => 'Beginner',
      Experience.intermediate => 'Intermediate',
      Experience.advanced => 'Advanced',
    };

class Prescription {
  final int sets;
  final String reps; // e.g. "8–12" or "25 min"
  final int restSeconds;

  const Prescription({required this.sets, required this.reps, required this.restSeconds});

  /// The first number of the rep range, used to prefill sets.
  int get startingReps => int.tryParse(reps.split(RegExp(r'[^0-9]')).first) ?? 10;

  String get label => sets <= 1 ? reps : '$sets × $reps';

  /// For timed work ("25 min", "45 sec") the duration in seconds, else null.
  int? get seconds {
    final n = startingReps;
    if (reps.endsWith('min')) return n * 60;
    if (reps.endsWith('sec')) return n;
    return null;
  }
}

class PlannedExercise {
  final Exercise exercise;
  final Prescription prescription;
  final String reason;

  const PlannedExercise({
    required this.exercise,
    required this.prescription,
    required this.reason,
  });
}

class PlannedSession {
  final String name;
  final String focus;
  final List<PlannedExercise> exercises;

  const PlannedSession({required this.name, required this.focus, required this.exercises});

  int get estimatedMinutes {
    var total = 8; // warm-up
    for (final p in exercises) {
      if (p.exercise.category == 'cardio' || p.exercise.category == 'flexibility') {
        total += p.prescription.startingReps;
      } else {
        total += (p.prescription.sets * (0.75 + p.prescription.restSeconds / 60)).round();
      }
    }
    return total;
  }
}

class NutritionSuggestion {
  final int calories;
  final int proteinG;
  final int carbsG;
  final int fatG;
  final double waterLitres;
  final int maintenanceCalories;

  const NutritionSuggestion({
    required this.calories,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    required this.waterLitres,
    required this.maintenanceCalories,
  });
}

class FitnessPlan {
  final FitnessGoal goal;
  final Experience experience;
  final int daysPerWeek;
  final List<PlannedSession> week;
  final List<ScoredExercise> recommended;
  final NutritionSuggestion? nutrition;
  final List<String> notes;
  final double? bmi;

  const FitnessPlan({
    required this.goal,
    required this.experience,
    required this.daysPerWeek,
    required this.week,
    required this.recommended,
    required this.nutrition,
    required this.notes,
    required this.bmi,
  });

  /// Next session to do, based on how many workouts are already logged this week.
  PlannedSession? nextSession(int workoutsThisWeek) {
    if (week.isEmpty) return null;
    return week[workoutsThisWeek % week.length];
  }
}

class ScoredExercise {
  final Exercise exercise;
  final double score;
  final String reason;

  const ScoredExercise(this.exercise, this.score, this.reason);
}

class _Slot {
  final String muscleGroup; // or 'cardio' / 'flexibility'
  final int count;
  const _Slot(this.muscleGroup, [this.count = 1]);
}

class _SessionTemplate {
  final String name;
  final String focus;
  final List<_Slot> slots;
  const _SessionTemplate(this.name, this.focus, this.slots);
}

class PlanEngine {
  static const _compoundWords = [
    'squat', 'deadlift', 'bench press', 'overhead press', 'row', 'pull-up', 'lunge', 'leg press', 'push-up',
  ];
  static const _highImpactWords = ['running', 'treadmill', 'jump rope'];
  static const _lowImpactWords = ['cycling', 'bike', 'swimming', 'elliptical', 'rowing'];

  static FitnessPlan build({required Profile profile, required List<Exercise> exercises}) {
    final goal = parseGoal(profile.fitnessGoal);
    final experience = _experienceFor(profile.activityLevel);
    final age = _ageOf(profile.dateOfBirth);
    final bmi = (profile.heightCm != null && profile.weightKg != null && profile.heightCm! > 0)
        ? profile.weightKg! / ((profile.heightCm! / 100) * (profile.heightCm! / 100))
        : null;
    final preferLowImpact = (bmi != null && bmi >= 30) || (age != null && age >= 55);
    final days = _daysFor(profile.activityLevel);

    // Score every exercise once, then pick from the ranked list per slot.
    final scored = <ScoredExercise>[];
    for (final e in exercises) {
      final s = _score(e, goal, experience, preferLowImpact, age);
      if (s != null) scored.add(s);
    }
    scored.sort((a, b) {
      final c = b.score.compareTo(a.score);
      return c != 0 ? c : a.exercise.name.compareTo(b.exercise.name);
    });

    final templates = _templatesFor(goal, days);
    final week = <PlannedSession>[];
    for (var i = 0; i < templates.length; i++) {
      week.add(_fill(templates[i], scored, goal, experience, rotation: i));
    }

    return FitnessPlan(
      goal: goal,
      experience: experience,
      daysPerWeek: days,
      week: week,
      recommended: scored.take(12).toList(),
      nutrition: _nutrition(profile, goal, age),
      notes: _notes(goal, experience, preferLowImpact, bmi, age),
      bmi: bmi,
    );
  }

  // ---------------------------------------------------------------------------

  static Experience _experienceFor(String? activity) {
    final a = (activity ?? '').toLowerCase();
    if (a.startsWith('very')) return Experience.advanced;
    if (a.startsWith('moderate')) return Experience.intermediate;
    return Experience.beginner;
  }

  static int _daysFor(String? activity) {
    final a = (activity ?? '').toLowerCase();
    if (a.startsWith('very')) return 5;
    if (a.startsWith('moderate')) return 4;
    return 3;
  }

  static int? _ageOf(DateTime? dob) {
    if (dob == null) return null;
    final now = DateTime.now();
    var age = now.year - dob.year;
    if (now.month < dob.month || (now.month == dob.month && now.day < dob.day)) age--;
    return age;
  }

  static int _levelIndex(String difficulty) => switch (difficulty) {
        'advanced' => 2,
        'intermediate' => 1,
        _ => 0,
      };

  static ScoredExercise? _score(
    Exercise e,
    FitnessGoal goal,
    Experience exp,
    bool preferLowImpact,
    int? age,
  ) {
    final name = e.name.toLowerCase();
    final level = _levelIndex(e.difficulty);
    final userLevel = exp.index;

    // Never suggest something more than one step above the user's level,
    // and skip advanced moves for complete beginners and older lifters.
    if (level > userLevel + 1) return null;
    if (level == 2 && (userLevel == 0 || (age != null && age >= 60))) return null;

    double score = 0;
    String reason = '';

    // How well the type of exercise fits the goal.
    final goalFit = switch (goal) {
      FitnessGoal.buildMuscle => {'strength': 5.0, 'cardio': 0.5, 'flexibility': 1.0},
      FitnessGoal.loseWeight => {'strength': 3.5, 'cardio': 4.5, 'flexibility': 1.0},
      FitnessGoal.endurance => {'strength': 2.0, 'cardio': 5.0, 'flexibility': 1.5},
      FitnessGoal.maintain => {'strength': 3.5, 'cardio': 3.0, 'flexibility': 2.5},
    };
    score += goalFit[e.category] ?? 1.0;

    // Difficulty: right at your level is best, one below is fine, one above is a stretch.
    if (level == userLevel) {
      score += 2;
    } else if (level < userLevel) {
      score += 1;
    } else {
      score -= 1.5;
    }

    final isCompound = _compoundWords.any(name.contains);
    if (isCompound && e.category == 'strength') {
      score += goal == FitnessGoal.buildMuscle ? 2.5 : 1.5;
      reason = 'Big compound lift';
    }

    final isBodyweight = (e.equipment ?? '').toLowerCase().contains('bodyweight');
    if (isBodyweight && exp == Experience.beginner) {
      score += 1.5;
      if (reason.isEmpty) reason = 'No equipment needed';
    }

    if (e.category == 'cardio') {
      final highImpact = _highImpactWords.any(name.contains);
      final lowImpact = _lowImpactWords.any(name.contains);
      if (preferLowImpact && highImpact) score -= 3;
      if (preferLowImpact && lowImpact) {
        score += 2;
        reason = 'Easy on joints';
      }
      if (reason.isEmpty) {
        reason = goal == FitnessGoal.loseWeight ? 'Good calorie burn' : 'Builds your engine';
      }
    }

    if (e.category == 'flexibility' && reason.isEmpty) reason = 'Helps you recover';
    if (e.muscleGroup == 'core' && reason.isEmpty) reason = 'Stronger core, better lifts';
    if (reason.isEmpty) reason = 'Fits your ${experienceLabel(exp).toLowerCase()} level';

    return ScoredExercise(e, score, reason);
  }

  static List<_SessionTemplate> _templatesFor(FitnessGoal goal, int days) {
    const fullA = _SessionTemplate('Full body A', 'Legs, chest, back', [
      _Slot('legs'), _Slot('chest'), _Slot('back'), _Slot('shoulders'), _Slot('core'),
    ]);
    const fullB = _SessionTemplate('Full body B', 'Back, legs, arms', [
      _Slot('back'), _Slot('legs'), _Slot('chest'), _Slot('arms'), _Slot('core'),
    ]);
    const fullC = _SessionTemplate('Full body C', 'Legs, shoulders, core', [
      _Slot('legs'), _Slot('shoulders'), _Slot('back'), _Slot('chest'), _Slot('core'),
    ]);
    const upper = _SessionTemplate('Upper body', 'Chest, back, shoulders, arms', [
      _Slot('chest'), _Slot('back'), _Slot('shoulders'), _Slot('chest'), _Slot('back'), _Slot('arms'),
    ]);
    const lower = _SessionTemplate('Lower body', 'Legs and core', [
      _Slot('legs', 4), _Slot('core', 2),
    ]);
    const push = _SessionTemplate('Push', 'Chest, shoulders, triceps', [
      _Slot('chest', 3), _Slot('shoulders', 2), _Slot('arms'),
    ]);
    const pull = _SessionTemplate('Pull', 'Back and biceps', [
      _Slot('back', 4), _Slot('arms', 2),
    ]);
    const legs = _SessionTemplate('Legs', 'Quads, hamstrings, calves', [
      _Slot('legs', 5), _Slot('core'),
    ]);
    const cardio = _SessionTemplate('Cardio', 'Steady effort + core', [
      _Slot('cardio'), _Slot('core', 2), _Slot('flexibility'),
    ]);
    const longCardio = _SessionTemplate('Long cardio', 'Go easy, go longer', [
      _Slot('cardio'), _Slot('flexibility'),
    ]);
    const intervals = _SessionTemplate('Cardio mix', 'Two machines, moderate pace', [
      _Slot('cardio', 2), _Slot('core'),
    ]);
    const circuit = _SessionTemplate('Strength circuit', 'Whole body, short rests', [
      _Slot('legs'), _Slot('chest'), _Slot('back'), _Slot('shoulders'), _Slot('core'), _Slot('cardio'),
    ]);
    const mobility = _SessionTemplate('Mobility + core', 'Recover and loosen up', [
      _Slot('flexibility', 2), _Slot('core', 2),
    ]);

    switch (goal) {
      case FitnessGoal.buildMuscle:
        if (days >= 5) return [push, pull, legs, upper, lower];
        if (days == 4) return [upper, lower, upper, lower];
        return [fullA, fullB, fullC];
      case FitnessGoal.loseWeight:
        if (days >= 5) return [circuit, cardio, upper, lower, intervals];
        if (days == 4) return [circuit, cardio, fullB, intervals];
        return [circuit, cardio, fullB];
      case FitnessGoal.endurance:
        if (days >= 5) return [intervals, fullA, longCardio, cardio, mobility];
        if (days == 4) return [intervals, fullA, longCardio, mobility];
        return [intervals, fullA, longCardio];
      case FitnessGoal.maintain:
        if (days >= 5) return [fullA, cardio, fullB, mobility, intervals];
        if (days == 4) return [fullA, cardio, fullB, mobility];
        return [fullA, cardio, fullB];
    }
  }

  static Prescription _prescriptionFor(Exercise e, FitnessGoal goal, Experience exp) {
    final beginner = exp == Experience.beginner;
    if (e.category == 'cardio') {
      final minutes = switch (goal) {
        FitnessGoal.endurance => beginner ? 25 : 40,
        FitnessGoal.loseWeight => beginner ? 20 : 30,
        _ => 20,
      };
      return Prescription(sets: 1, reps: '$minutes min', restSeconds: 0);
    }
    if (e.category == 'flexibility') {
      return const Prescription(sets: 1, reps: '10 min', restSeconds: 0);
    }
    if (e.name.toLowerCase().contains('plank')) {
      return Prescription(sets: beginner ? 2 : 3, reps: beginner ? '30 sec' : '45 sec', restSeconds: 45);
    }
    final base = switch (goal) {
      FitnessGoal.buildMuscle => const Prescription(sets: 4, reps: '8–12', restSeconds: 90),
      FitnessGoal.loseWeight => const Prescription(sets: 3, reps: '12–15', restSeconds: 45),
      FitnessGoal.endurance => const Prescription(sets: 3, reps: '15–20', restSeconds: 30),
      FitnessGoal.maintain => const Prescription(sets: 3, reps: '10–12', restSeconds: 60),
    };
    return beginner
        ? Prescription(sets: base.sets - 1, reps: base.reps, restSeconds: base.restSeconds)
        : base;
  }

  static PlannedSession _fill(
    _SessionTemplate t,
    List<ScoredExercise> ranked,
    FitnessGoal goal,
    Experience exp, {
    required int rotation,
  }) {
    final used = <String>{};
    final picked = <PlannedExercise>[];

    for (final slot in t.slots) {
      final candidates = ranked.where((s) {
        final e = s.exercise;
        if (used.contains(e.id)) return false;
        if (slot.muscleGroup == 'cardio') return e.category == 'cardio';
        if (slot.muscleGroup == 'flexibility') return e.category == 'flexibility';
        return e.category == 'strength' && e.muscleGroup == slot.muscleGroup;
      }).toList();
      if (candidates.isEmpty) continue;

      // Rotate through the top few so repeated sessions in a week aren't identical.
      final spare = candidates.length - slot.count;
      final offset = spare > 0 ? rotation % (spare.clamp(0, 2) + 1) : 0;
      for (var i = 0; i < slot.count; i++) {
        final idx = offset + i;
        if (idx >= candidates.length) break;
        final pick = candidates[idx];
        used.add(pick.exercise.id);
        picked.add(PlannedExercise(
          exercise: pick.exercise,
          prescription: _prescriptionFor(pick.exercise, goal, exp),
          reason: pick.reason,
        ));
      }
    }

    return PlannedSession(name: t.name, focus: t.focus, exercises: picked);
  }

  static NutritionSuggestion? _nutrition(Profile p, FitnessGoal goal, int? age) {
    final w = p.weightKg;
    final h = p.heightCm;
    if (w == null || h == null) return null;
    final a = age ?? 30;
    final g = (p.gender ?? '').toLowerCase();
    final genderAdj = g == 'male' ? 5 : (g == 'female' ? -161 : -78);
    final bmr = 10 * w + 6.25 * h - 5 * a + genderAdj;

    final act = (p.activityLevel ?? '').toLowerCase();
    final factor = act.startsWith('very')
        ? 1.725
        : act.startsWith('moderate')
            ? 1.55
            : act.startsWith('light')
                ? 1.375
                : 1.2;
    final maintenance = bmr * factor;

    final floor = g == 'male' ? 1500.0 : 1200.0;
    final target = switch (goal) {
      FitnessGoal.loseWeight => (maintenance - 450).clamp(floor, double.infinity),
      FitnessGoal.buildMuscle => maintenance + 300,
      FitnessGoal.endurance => maintenance + 150,
      FitnessGoal.maintain => maintenance,
    };

    final proteinPerKg = switch (goal) {
      FitnessGoal.buildMuscle || FitnessGoal.loseWeight => 2.0,
      _ => 1.6,
    };
    final protein = (w * proteinPerKg).round();
    final fat = (target * 0.25 / 9).round();
    final carbs = ((target - protein * 4 - fat * 9) / 4).round().clamp(50, 1000);

    return NutritionSuggestion(
      calories: _roundTo(target, 10),
      proteinG: protein,
      carbsG: carbs,
      fatG: fat,
      waterLitres: double.parse((w * 0.035).toStringAsFixed(1)),
      maintenanceCalories: _roundTo(maintenance, 10),
    );
  }

  static int _roundTo(double v, int step) => (v / step).round() * step;

  static List<String> _notes(
    FitnessGoal goal,
    Experience exp,
    bool lowImpact,
    double? bmi,
    int? age,
  ) {
    final notes = <String>[];
    switch (goal) {
      case FitnessGoal.loseWeight:
        notes.add('Most fat loss happens in the kitchen. Training keeps the muscle while the scale moves.');
        notes.add('Aim for 7–10k steps on days you don\'t train. It adds up quietly.');
      case FitnessGoal.buildMuscle:
        notes.add('Add a little weight or one rep each week. Small jumps, every week, is the whole trick.');
        notes.add('Get your protein in and sleep 7+ hours. Muscle is built on rest days.');
      case FitnessGoal.endurance:
        notes.add('Keep most cardio at a pace where you could still hold a conversation.');
        notes.add('Increase total weekly time by about 10% at most so your joints keep up.');
      case FitnessGoal.maintain:
        notes.add('Consistency beats intensity. Showing up three times a week is plenty.');
        notes.add('Mix it up every month or so to keep it fun.');
    }
    if (exp == Experience.beginner) {
      notes.add('Start lighter than you think. Learn the movement first, then add weight.');
    }
    if (lowImpact) {
      notes.add('We\'ve leaned toward low-impact cardio like cycling and swimming to protect your knees.');
    }
    if (age != null && age >= 50) {
      notes.add('Take an extra few minutes to warm up. It makes a real difference.');
    }
    return notes;
  }
}
