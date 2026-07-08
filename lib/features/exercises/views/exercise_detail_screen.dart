import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:fit_track/core/models/exercise.dart';
import 'package:fit_track/core/models/workout.dart';
import 'package:fit_track/core/providers/exercises_provider.dart';
import 'package:fit_track/core/providers/workouts_provider.dart';
import 'package:fit_track/core/utils/formatters.dart';

class ExerciseDetailScreen extends ConsumerWidget {
  final String exerciseId;

  const ExerciseDetailScreen({
    super.key,
    required this.exerciseId,
  });

  Color _getMuscleColor(String muscle) {
    switch (muscle.toLowerCase()) {
      case 'chest':
        return Colors.blue;
      case 'back':
        return Colors.orange;
      case 'legs':
        return Colors.purple;
      case 'shoulders':
        return Colors.teal;
      case 'arms':
        return Colors.amber;
      case 'core':
        return Colors.pink;
      case 'full_body':
        return Colors.indigo;
      case 'cardio':
        return Colors.deepOrange;
      default:
        return Colors.grey;
    }
  }

  Color _getDifficultyColor(String diff) {
    switch (diff.toLowerCase()) {
      case 'beginner':
        return Colors.green;
      case 'intermediate':
        return Colors.orange;
      case 'advanced':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text.replaceAll('_', ' ').split(' ').map((word) {
      if (word.isEmpty) return '';
      return word[0].toUpperCase() + word.substring(1);
    }).join(' ');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    
    // Watch raw exercise list
    final allAsync = ref.watch(allExercisesProvider);
    final favoritesAsync = ref.watch(favoriteExerciseIdsProvider);
    final workoutsAsync = ref.watch(userWorkoutsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Exercise Details', style: TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // Check if we can pop, otherwise navigate to /exercises
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/exercises');
            }
          },
        ),
      ),
      body: allAsync.when(
        data: (exercises) {
          final exercise = exercises.firstWhere(
            (e) => e.id == exerciseId,
            orElse: () => Exercise(
              id: '',
              name: 'Unknown Exercise',
              category: 'strength',
              muscleGroup: 'full_body',
              difficulty: 'beginner',
              isCustom: false,
              createdAt: DateTime(1970),
              updatedAt: DateTime(1970),
            ),
          );

          if (exercise.id.isEmpty) {
            return const Center(child: Text('Exercise not found.'));
          }

          final favorites = favoritesAsync.value ?? [];
          final isFav = favorites.contains(exercise.id);
          final workouts = workoutsAsync.value ?? [];

          // Compute exercise history
          final historyPoints = _computeHistory(exercise.id, workouts);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Details card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                exercise.name,
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                isFav ? Icons.star_rounded : Icons.star_border_rounded,
                                color: isFav ? Colors.amber : Colors.grey,
                                size: 28,
                              ),
                              onPressed: () {
                                ref.read(favoriteExerciseIdsProvider.notifier).toggleFavorite(exercise.id);
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        // Metadata Chips row
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _buildInfoChip(
                              theme,
                              label: _capitalize(exercise.category),
                              color: theme.colorScheme.primary,
                              textColor: Colors.black,
                            ),
                            _buildInfoChip(
                              theme,
                              label: _capitalize(exercise.muscleGroup),
                              color: _getMuscleColor(exercise.muscleGroup),
                              textColor: Colors.white,
                            ),
                            _buildInfoChip(
                              theme,
                              label: _capitalize(exercise.difficulty),
                              color: _getDifficultyColor(exercise.difficulty),
                              textColor: Colors.white,
                            ),
                            if (exercise.equipment != null)
                              _buildInfoChip(
                                theme,
                                label: exercise.equipment!,
                                color: Colors.grey[700]!,
                                textColor: Colors.white,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Instructions Card
                Text(
                  'Instructions',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      exercise.instructions ?? 'No instructions provided.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        height: 1.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                // History Section
                if (historyPoints.isEmpty) ...[
                  Card(
                    color: theme.brightness == Brightness.dark
                        ? Colors.grey[900]?.withValues(alpha: 0.5)
                        : Colors.grey[100],
                    elevation: 0,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32.0, horizontal: 16.0),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(Icons.history_rounded, size: 36, color: Colors.grey[500]),
                            const SizedBox(height: 12),
                            Text(
                              'No progression history yet',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: Colors.grey[500],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Once you perform this exercise in a workout, your progression chart and personal bests will appear here!',
                              style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[500]),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ] else ...[
                  // Progression Chart
                  Text(
                    'Progression Chart (Max Weight)',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 200,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 16, top: 12, bottom: 8),
                      child: LineChart(
                        _buildLineChartData(historyPoints, theme),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Personal Bests Table
                  Text(
                    '🏆 Personal Bests',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _buildPersonalBestsTable(historyPoints, theme),
                ],
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: ${err.toString()}')),
      ),
    );
  }

  Widget _buildInfoChip(
    ThemeData theme, {
    required String label,
    required Color color,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        border: Border.all(color: color.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: theme.brightness == Brightness.dark ? Colors.white : color,
        ),
      ),
    );
  }

  List<_ExerciseHistoryPoint> _computeHistory(String exerciseId, List<Workout> workouts) {
    final List<_ExerciseHistoryPoint> points = [];

    // Sort workouts oldest to newest
    final sorted = List<Workout>.from(workouts);
    sorted.sort((a, b) => a.startedAt.compareTo(b.startedAt));

    for (var w in sorted) {
      final matchingExs = w.exercises.where((we) => we.exerciseId == exerciseId).toList();
      if (matchingExs.isEmpty) continue;

      for (var we in matchingExs) {
        final completedSets = we.sets.where((s) => s.completed).toList();
        if (completedSets.isEmpty) continue;

        double maxWeight = 0.0;
        int maxReps = 0;
        double volume = 0.0;

        for (var s in completedSets) {
          final weight = s.weightKg ?? 0.0;
          final reps = s.reps ?? 0;
          if (weight > maxWeight) maxWeight = weight;
          if (reps > maxReps) maxReps = reps;
          volume += weight * reps;
        }

        points.add(_ExerciseHistoryPoint(
          date: w.startedAt,
          maxWeight: maxWeight,
          maxReps: maxReps,
          volume: volume,
        ));
      }
    }

    return points;
  }

  LineChartData _buildLineChartData(List<_ExerciseHistoryPoint> points, ThemeData theme) {
    final spots = <FlSpot>[];
    for (int i = 0; i < points.length; i++) {
      spots.add(FlSpot(i.toDouble(), points[i].maxWeight));
    }

    final double minY = spots.map((s) => s.y).reduce((a, b) => a < b ? a : b) - 5;
    final double maxY = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b) + 5;

    return LineChartData(
      gridData: const FlGridData(show: false),
      titlesData: FlTitlesData(
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, meta) {
              final idx = value.toInt();
              if (idx < 0 || idx >= points.length) return const SizedBox.shrink();
              
              // Only show first, middle, last labels if there are many points to prevent overlap
              if (points.length > 3) {
                if (idx != 0 && idx != points.length - 1 && idx != points.length ~/ 2) {
                  return const SizedBox.shrink();
                }
              }
              
              final dateStr = DateFormat('MMM d').format(points[idx].date);
              return Padding(
                padding: const EdgeInsets.only(top: 6.0),
                child: Text(
                  dateStr,
                  style: TextStyle(fontSize: 10, color: Colors.grey[500], fontWeight: FontWeight.bold),
                ),
              );
            },
            reservedSize: 22,
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, meta) {
              return Text(
                '${value.toStringAsFixed(0)}kg',
                style: TextStyle(fontSize: 9, color: Colors.grey[500], fontWeight: FontWeight.bold),
              );
            },
            reservedSize: 36,
          ),
        ),
      ),
      borderData: FlBorderData(show: false),
      minX: 0,
      maxX: (points.length - 1).toDouble(),
      minY: minY < 0 ? 0 : minY,
      maxY: maxY,
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          color: theme.colorScheme.primary,
          barWidth: 4,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
              radius: 4,
              color: theme.colorScheme.primary,
              strokeWidth: 2,
              strokeColor: Colors.black,
            ),
          ),
          belowBarData: BarAreaData(
            show: true,
            color: theme.colorScheme.primary.withValues(alpha: 0.12),
          ),
        ),
      ],
    );
  }

  Widget _buildPersonalBestsTable(List<_ExerciseHistoryPoint> points, ThemeData theme) {
    double maxWeight = 0.0;
    int maxReps = 0;
    double maxVolume = 0.0;

    for (var p in points) {
      if (p.maxWeight > maxWeight) maxWeight = p.maxWeight;
      if (p.maxReps > maxReps) maxReps = p.maxReps;
      if (p.volume > maxVolume) maxVolume = p.volume;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildPbRow('Max Weight Lifted', '${maxWeight.toStringAsFixed(maxWeight % 1 == 0 ? 0 : 1)} kg', theme),
            const Divider(height: 20),
            _buildPbRow('Max Repetitions in a Set', '$maxReps reps', theme),
            const Divider(height: 20),
            _buildPbRow('Max Session Volume', Formatters.formatVolume(maxVolume), theme),
          ],
        ),
      ),
    );
  }

  Widget _buildPbRow(String label, String value, ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
            fontSize: 16,
          ),
        ),
      ],
    );
  }
}

class _ExerciseHistoryPoint {
  final DateTime date;
  final double maxWeight;
  final int maxReps;
  final double volume;

  _ExerciseHistoryPoint({
    required this.date,
    required this.maxWeight,
    required this.maxReps,
    required this.volume,
  });
}
