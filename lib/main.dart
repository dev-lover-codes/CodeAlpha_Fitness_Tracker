import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MyApp());
}

/// The root application widget.
/// Manages the global theme state (Light/Dark mode) in a single-file setup.
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // Holds current ThemeMode (System default on start)
  ThemeMode _themeMode = ThemeMode.system;

  void _toggleTheme() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.dark
          ? ThemeMode.light
          : ThemeMode.dark;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FitTracker',
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,

      // Dynamic Light Theme
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6366F1), // Indigo
          brightness: Brightness.light,
          primary: const Color(0xFF6366F1),
          secondary: const Color(0xFF10B981), // Emerald
          tertiary: const Color(0xFFF59E0B), // Amber
          surface: const Color(0xFFF8FAFC),
        ),
        cardTheme: CardThemeData(
          elevation: 4,
          shadowColor: Colors.black.withOpacity(0.04),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme),
      ),

      // Dynamic Dark Theme
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6366F1), // Indigo
          brightness: Brightness.dark,
          primary: const Color(0xFF6366F1),
          secondary: const Color(0xFF10B981), // Emerald
          tertiary: const Color(0xFFF59E0B), // Amber
          surface: const Color(0xFF0F172A), // Slate-900
        ),
        cardTheme: CardThemeData(
          elevation: 6,
          shadowColor: Colors.black.withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
      ),

      home: FitnessTrackerHome(
        currentThemeMode: _themeMode,
        onThemeToggle: _toggleTheme,
      ),
    );
  }
}

/// FitnessActivity data model class.
class FitnessActivity {
  final String id;
  final String type; // e.g., Running, Walking, Gym, Yoga
  final int durationInMinutes;
  final int caloriesBurned;
  final DateTime timestamp;

  FitnessActivity({
    required this.id,
    required this.type,
    required this.durationInMinutes,
    required this.caloriesBurned,
    required this.timestamp,
  });

  /// Convert activity to JSON map for local storage.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'durationInMinutes': durationInMinutes,
      'caloriesBurned': caloriesBurned,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  /// Create activity from JSON map.
  factory FitnessActivity.fromMap(Map<String, dynamic> map) {
    return FitnessActivity(
      id: map['id'] as String,
      type: map['type'] as String,
      durationInMinutes: map['durationInMinutes'] as int,
      caloriesBurned: map['caloriesBurned'] as int,
      timestamp: DateTime.parse(map['timestamp'] as String),
    );
  }
}

/// The Dashboard and list screen.
class FitnessTrackerHome extends StatefulWidget {
  final ThemeMode currentThemeMode;
  final VoidCallback onThemeToggle;

  const FitnessTrackerHome({
    super.key,
    required this.currentThemeMode,
    required this.onThemeToggle,
  });

  @override
  State<FitnessTrackerHome> createState() => _FitnessTrackerHomeState();
}

class _FitnessTrackerHomeState extends State<FitnessTrackerHome> {
  static const String _storageKey = 'fit_tracker_activities_key';
  final int _dailyCalorieGoal = 2000;

  List<FitnessActivity> _activities = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadActivities();
  }

  /// Loads fitness activities from SharedPreferences.
  /// Seeds initial mockup values if storage is empty.
  Future<void> _loadActivities() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? jsonString = prefs.getString(_storageKey);

      if (jsonString == null || jsonString.isEmpty) {
        // Seed initial data for a beautiful visual start
        _activities = _getSeedActivities();
        await _saveActivities();
      } else {
        final List<dynamic> decoded = json.decode(jsonString);
        setState(() {
          _activities = decoded
              .map(
                (item) =>
                    FitnessActivity.fromMap(Map<String, dynamic>.from(item)),
              )
              .toList();
        });
      }
    } catch (e) {
      debugPrint("FitTracker: Error loading activities: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Saves the list of activities locally as JSON.
  Future<void> _saveActivities() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<Map<String, dynamic>> mappedList = _activities
          .map((item) => item.toMap())
          .toList();
      await prefs.setString(_storageKey, json.encode(mappedList));
    } catch (e) {
      debugPrint("FitTracker: Error saving activities: $e");
    }
  }

  /// Adds a new activity to the memory and persists it.
  void _addActivity(String type, int duration, int calories) {
    final newActivity = FitnessActivity(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: type,
      durationInMinutes: duration,
      caloriesBurned: calories,
      timestamp: DateTime.now(),
    );

    setState(() {
      _activities.insert(0, newActivity);
    });
    _saveActivities();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Logged "$type" successfully!'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  /// Removes an activity and persists the change.
  /// Supports Undo capability.
  void _deleteActivity(int index, FitnessActivity activity) {
    setState(() {
      _activities.removeAt(index);
    });
    _saveActivities();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Removed ${activity.type} workout'),
        action: SnackBarAction(
          label: 'UNDO',
          textColor: Colors.amber,
          onPressed: () {
            setState(() {
              _activities.insert(index, activity);
            });
            _saveActivities();
          },
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  /// Sum of calories burned in workouts completed today
  int get _caloriesBurnedToday {
    final now = DateTime.now();
    return _activities
        .where(
          (act) =>
              act.timestamp.year == now.year &&
              act.timestamp.month == now.month &&
              act.timestamp.day == now.day,
        )
        .fold<int>(0, (sum, act) => sum + act.caloriesBurned);
  }

  /// Sum of active workout minutes today
  int get _activeMinutesToday {
    final now = DateTime.now();
    return _activities
        .where(
          (act) =>
              act.timestamp.year == now.year &&
              act.timestamp.month == now.month &&
              act.timestamp.day == now.day,
        )
        .fold<int>(0, (sum, act) => sum + act.durationInMinutes);
  }

  /// Open Bottom Sheet modal dialog for workout entry
  void _showAddActivityBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext ctx) {
        return _AddActivityModal(onSave: _addActivity);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final progressValue = (_caloriesBurnedToday / _dailyCalorieGoal).clamp(
      0.0,
      1.0,
    );
    final progressPercentage = (_caloriesBurnedToday / _dailyCalorieGoal * 100)
        .toInt();

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.flash_on_rounded,
              color: theme.colorScheme.primary,
              size: 28,
            ),
            const SizedBox(width: 8),
            Text(
              'FitTracker',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        centerTitle: true,
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        actions: [
          // Theme toggler button
          IconButton(
            icon: Icon(
              widget.currentThemeMode == ThemeMode.dark
                  ? Icons.light_mode_rounded
                  : Icons.dark_mode_rounded,
            ),
            tooltip: 'Toggle Theme',
            onPressed: widget.onThemeToggle,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 12),
                  // TOP HALF: Summary Card & Progress Indicators
                  Card(
                    color: isDark ? theme.colorScheme.surface : Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Today's Energy",
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Goal: $_dailyCalorieGoal kcal',
                                    style: theme.textTheme.bodyMedium,
                                  ),
                                ],
                              ),
                              // Active Minutes Badge
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary.withOpacity(
                                    0.1,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.timer_outlined,
                                      size: 16,
                                      color: theme.colorScheme.primary,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '$_activeMinutesToday min',
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                            color: theme.colorScheme.primary,
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          // Linear Progress bar and stats
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '$_caloriesBurnedToday kcal burned',
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                '$progressPercentage%',
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  color: theme.colorScheme.secondary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: progressValue,
                              minHeight: 12,
                              backgroundColor: isDark
                                  ? Colors.white.withOpacity(0.06)
                                  : Colors.grey.withOpacity(0.15),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                progressValue >= 1.0
                                    ? theme.colorScheme.secondary
                                    : theme.colorScheme.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // BOTTOM HALF: Workouts History Title
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Workouts History',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Swipe card to delete',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Workout List
                  Expanded(
                    child: _activities.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.history_rounded,
                                  size: 48,
                                  color: theme.textTheme.bodyMedium?.color
                                      ?.withOpacity(0.3),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'No workouts logged yet',
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: _activities.length,
                            itemBuilder: (context, index) {
                              final activity = _activities[index];
                              return Dismissible(
                                key: Key(activity.id),
                                background: Container(
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.only(right: 20.0),
                                  margin: const EdgeInsets.symmetric(
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.redAccent,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Icon(
                                    Icons.delete_rounded,
                                    color: Colors.white,
                                  ),
                                ),
                                direction: DismissDirection.endToStart,
                                onDismissed: (direction) {
                                  _deleteActivity(index, activity);
                                },
                                child: _ActivityItem(activity: activity),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddActivityBottomSheet,
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text(
          'Log Workout',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  /// Initial Seed list
  List<FitnessActivity> _getSeedActivities() {
    final now = DateTime.now();
    return [
      FitnessActivity(
        id: 'seed_1',
        type: 'Running',
        durationInMinutes: 30,
        caloriesBurned: 320,
        timestamp: now.subtract(const Duration(hours: 1)),
      ),
      FitnessActivity(
        id: 'seed_2',
        type: 'Yoga',
        durationInMinutes: 40,
        caloriesBurned: 160,
        timestamp: now.subtract(const Duration(hours: 4)),
      ),
      FitnessActivity(
        id: 'seed_3',
        type: 'Gym',
        durationInMinutes: 60,
        caloriesBurned: 480,
        timestamp: now.subtract(const Duration(days: 1)),
      ),
    ];
  }
}

/// Custom ListTile Card representing individual workouts.
class _ActivityItem extends StatelessWidget {
  final FitnessActivity activity;

  const _ActivityItem({required this.activity});

  IconData _getActivityIcon(String type) {
    switch (type.toLowerCase()) {
      case 'running':
        return Icons.directions_run_rounded;
      case 'walking':
        return Icons.directions_walk_rounded;
      case 'gym':
        return Icons.fitness_center_rounded;
      case 'yoga':
        return Icons.self_improvement_rounded;
      default:
        return Icons.flash_on_rounded;
    }
  }

  Color _getActivityColor(String type) {
    switch (type.toLowerCase()) {
      case 'running':
        return Colors.orange;
      case 'walking':
        return Colors.blue;
      case 'gym':
        return Colors.red;
      case 'yoga':
        return Colors.purple;
      default:
        return Colors.indigo;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _getActivityColor(activity.type);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                _getActivityIcon(activity.type),
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            // Info
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
                        Icons.timer_outlined,
                        size: 14,
                        color: theme.textTheme.bodyMedium?.color,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${activity.durationInMinutes} mins',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Calories
            Text(
              '${activity.caloriesBurned} kcal',
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: theme.colorScheme.tertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The Modal Sheet form layout to enter a new workout.
class _AddActivityModal extends StatefulWidget {
  final Function(String, int, int) onSave;

  const _AddActivityModal({required this.onSave});

  @override
  State<_AddActivityModal> createState() => _AddActivityModalState();
}

class _AddActivityModalState extends State<_AddActivityModal> {
  final _formKey = GlobalKey<FormState>();

  String _selectedType = 'Running';
  final _durationController = TextEditingController();
  final _caloriesController = TextEditingController();

  @override
  void dispose() {
    _durationController.dispose();
    _caloriesController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final duration = int.parse(_durationController.text);
      final calories = int.parse(_caloriesController.text);

      widget.onSave(_selectedType, duration, calories);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final keyboardPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: 24 + keyboardPadding,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.dividerColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Log Workout',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 22,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              // Dropdown Selection
              DropdownButtonFormField<String>(
                initialValue: _selectedType,
                decoration: const InputDecoration(
                  labelText: 'Activity Type',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(16)),
                  ),
                ),
                items: ['Running', 'Walking', 'Gym', 'Yoga']
                    .map(
                      (type) =>
                          DropdownMenuItem(value: type, child: Text(type)),
                    )
                    .toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _selectedType = val;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              // Duration Input
              TextFormField(
                controller: _durationController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Duration (minutes)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(16)),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a duration';
                  }
                  final num = int.tryParse(value);
                  if (num == null || num <= 0) {
                    return 'Enter a valid positive number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Calories Input
              TextFormField(
                controller: _caloriesController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Calories Burned (kcal)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(16)),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter calories burned';
                  }
                  final num = int.tryParse(value);
                  if (num == null || num < 0) {
                    return 'Enter a valid non-negative number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              // Submit button
              ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Save Workout',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
