import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/fitness_activity.dart';

class ActivityCard extends StatelessWidget {
  final FitnessActivity activity;
  final VoidCallback onDelete;

  const ActivityCard({
    super.key,
    required this.activity,
    required this.onDelete,
  });

  IconData _getActivityIcon(String type) {
    switch (type.toLowerCase()) {
      case 'running':
        return Icons.directions_run_rounded;
      case 'walking':
        return Icons.directions_walk_rounded;
      case 'cycling':
        return Icons.directions_bike_rounded;
      case 'yoga':
        return Icons.self_improvement_rounded;
      case 'gym':
        return Icons.fitness_center_rounded;
      default:
        return Icons.flash_on_rounded;
    }
  }

  Color _getActivityColor(String type, BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    switch (type.toLowerCase()) {
      case 'running':
        return Colors.orange.withAlpha(isDark ? 76 : 38);
      case 'walking':
        return Colors.blue.withAlpha(isDark ? 76 : 38);
      case 'cycling':
        return Colors.teal.withAlpha(isDark ? 76 : 38);
      case 'yoga':
        return Colors.purple.withAlpha(isDark ? 76 : 38);
      case 'gym':
        return Colors.red.withAlpha(isDark ? 76 : 38);
      default:
        return Colors.indigo.withAlpha(isDark ? 76 : 38);
    }
  }

  Color _getActivityIconColor(String type) {
    switch (type.toLowerCase()) {
      case 'running':
        return Colors.orange;
      case 'walking':
        return Colors.blue;
      case 'cycling':
        return Colors.teal;
      case 'yoga':
        return Colors.purple;
      case 'gym':
        return Colors.red;
      default:
        return Colors.indigo;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final iconColor = _getActivityIconColor(activity.type);
    final bgColor = _getActivityColor(activity.type, context);
    final timeString = DateFormat('hh:mm a').format(activity.timestamp);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
      decoration: BoxDecoration(
        color: theme.cardTheme.color ?? Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: theme.brightness == Brightness.light
                ? Colors.black.withAlpha(10)
                : Colors.black.withAlpha(51),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              // Activity Icon container
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  _getActivityIcon(activity.type),
                  color: iconColor,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),

              // Activity Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      activity.type,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time_rounded,
                          size: 14,
                          color: theme.textTheme.bodyMedium?.color,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${activity.durationInMinutes} mins',
                          style: theme.textTheme.bodyMedium,
                        ),
                        const SizedBox(width: 12),
                        const Icon(
                          Icons.local_fire_department_rounded,
                          size: 14,
                          color: Colors.orange,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${activity.caloriesBurned} kcal',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Colors.orange,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Time and Delete Button
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    timeString,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  IconButton(
                    icon: Icon(
                      Icons.delete_outline_rounded,
                      color: Colors.red.withAlpha(178),
                      size: 20,
                    ),
                    onPressed: () {
                      // Confirm dialog before delete
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Delete Activity?'),
                          content: const Text(
                            'Are you sure you want to remove this activity log?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.pop(ctx);
                                onDelete();
                              },
                              child: const Text(
                                'Delete',
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
