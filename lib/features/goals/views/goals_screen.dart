import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:fit_track/core/models/goal.dart';
import 'package:fit_track/core/providers/goals_provider.dart';

class GoalsScreen extends ConsumerWidget {
  const GoalsScreen({super.key});

  String _getGoalTypeTitle(Goal goal) {
    switch (goal.goalType) {
      case 'weight':
        return 'Body Weight Goal';
      case 'workout_frequency':
        return 'Workout Frequency Goal';
      case 'strength_pr':
        return 'Strength PR: ${goal.unit}';
      default:
        return 'Custom Goal: ${goal.unit}';
    }
  }

  double _calculateProgress(Goal goal) {
    if (goal.targetValue == 0.0) return 0.0;
    if (goal.status == 'completed') return 1.0;

    if (goal.goalType == 'weight') {
      // If weight loss (target is less than current)
      if (goal.targetValue < goal.currentValue) {
        return (goal.targetValue / goal.currentValue).clamp(0.0, 1.0);
      } else {
        // Weight gain (target is greater than current)
        return (goal.currentValue / goal.targetValue).clamp(0.0, 1.0);
      }
    }
    return (goal.currentValue / goal.targetValue).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goalsAsync = ref.watch(goalsProvider);
    final theme = Theme.of(context);

    // Watch for goal completion triggers to show a celebration pop-up!
    ref.listen<Goal?>(justCompletedGoalProvider, (previous, next) {
      if (next != null) {
        _showCelebrationDialog(context, ref, next);
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Goals', style: TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/home'),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/goals/new'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.black,
        child: const Icon(Icons.add_rounded),
      ),
      body: goalsAsync.when(
        data: (goals) {
          if (goals.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.track_changes_outlined, size: 64, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      'No fitness goals set yet',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.grey[500],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Set target weights, weekly workouts, or lift targets to track progression.',
                      style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[500]),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => context.go('/goals/new'),
                      icon: const Icon(Icons.add_rounded, color: Colors.black),
                      label: const Text('Set Your First Goal', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(backgroundColor: theme.colorScheme.primary),
                    ),
                  ],
                ),
              ),
            );
          }

          final activeGoals = goals.where((g) => g.status == 'active').toList();
          final completedGoals = goals.where((g) => g.status == 'completed').toList();

          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              if (activeGoals.isNotEmpty) ...[
                Text(
                  'Active Goals (${activeGoals.length})',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                ...activeGoals.map((goal) => _buildGoalCard(context, ref, goal, theme)),
                const SizedBox(height: 24),
              ],
              if (completedGoals.isNotEmpty) ...[
                Text(
                  'Completed Goals 🏆 (${completedGoals.length})',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                ...completedGoals.map((goal) => _buildGoalCard(context, ref, goal, theme)),
              ],
              const SizedBox(height: 70), // FAB spacer
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildGoalCard(BuildContext context, WidgetRef ref, Goal goal, ThemeData theme) {
    final progress = _calculateProgress(goal);
    final isCompleted = goal.status == 'completed';
    final typeTitle = _getGoalTypeTitle(goal);
    
    // Formatting target values
    String targetStr = '';
    String currentStr = '';
    if (goal.goalType == 'weight' || goal.goalType == 'strength_pr') {
      targetStr = '${goal.targetValue.toStringAsFixed(goal.targetValue % 1 == 0 ? 0 : 1)} kg';
      currentStr = '${goal.currentValue.toStringAsFixed(goal.currentValue % 1 == 0 ? 0 : 1)} kg';
    } else if (goal.goalType == 'workout_frequency') {
      targetStr = '${goal.targetValue.toInt()} workouts/week';
      currentStr = '${goal.currentValue.toInt()} workouts';
    } else {
      targetStr = '${goal.targetValue.toStringAsFixed(0)} ${goal.unit}';
      currentStr = goal.currentValue.toStringAsFixed(0);
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isCompleted
            ? BorderSide(color: theme.colorScheme.primary.withValues(alpha: 0.4), width: 1.5)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title and Action Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    typeTitle,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 20),
                  onPressed: () => _confirmDeleteGoal(context, ref, goal.id),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Target Date
            if (goal.targetDate != null) ...[
              Row(
                children: [
                  Icon(Icons.calendar_today_rounded, size: 12, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Text(
                    'Target Date: ${DateFormat('MMM d, y').format(goal.targetDate!)}',
                    style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],

            // Progress Bar
            LinearProgressIndicator(
              value: progress,
              backgroundColor: theme.brightness == Brightness.dark ? Colors.grey[800] : Colors.grey[200],
              color: isCompleted ? Colors.green : theme.colorScheme.primary,
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 10),

            // Progress Label Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Current: $currentStr',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isCompleted ? Colors.green : null,
                  ),
                ),
                Text(
                  'Target: $targetStr',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteGoal(BuildContext context, WidgetRef ref, String goalId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Goal?'),
        content: const Text('Are you sure you want to remove this goal from tracking?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(goalsProvider.notifier).deleteGoal(goalId);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showCelebrationDialog(BuildContext context, WidgetRef ref, Goal goal) {
    final theme = Theme.of(context);
    final title = _getGoalTypeTitle(goal);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Column(
            children: [
              Icon(Icons.emoji_events_rounded, size: 64, color: Colors.amber),
              SizedBox(height: 12),
              Text(
                'Goal Achieved!',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Congratulations!',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'You successfully reached your target for:\n$title',
                style: const TextStyle(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            ElevatedButton(
              onPressed: () {
                // Clear trigger
                ref.read(justCompletedGoalProvider.notifier).state = null;
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: Colors.black,
                minimumSize: const Size(120, 48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Fantastic!', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }
}
