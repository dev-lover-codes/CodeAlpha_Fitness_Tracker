import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:fit_track/core/providers/profile_provider.dart';
import 'package:fit_track/core/providers/repository_providers.dart';
import 'package:fit_track/core/providers/nutrition_targets_provider.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _fullNameController;
  late TextEditingController _usernameController;
  late TextEditingController _heightController;
  late TextEditingController _weightController;

  // Nutrition targets controllers
  late TextEditingController _caloriesController;
  late TextEditingController _proteinController;
  late TextEditingController _carbsController;
  late TextEditingController _fatController;

  String? _gender;
  DateTime? _dateOfBirth;
  String? _fitnessGoal;
  String? _activityLevel;

  final List<String> _genderOptions = ['Male', 'Female', 'Other', 'Prefer not to say'];
  final List<String> _goalOptions = [
    'Lose Weight',
    'Maintain Weight',
    'Build Muscle',
    'Improve Endurance'
  ];
  final List<String> _activityOptions = [
    'Sedentary',
    'Lightly Active',
    'Moderately Active',
    'Very Active'
  ];

  @override
  void initState() {
    super.initState();
    final profile = ref.read(profileProvider).value;
    final nutrition = ref.read(nutritionTargetsProvider);

    _fullNameController = TextEditingController(text: profile?.fullName ?? '');
    _usernameController = TextEditingController(text: profile?.username ?? '');
    _heightController = TextEditingController(text: profile?.heightCm?.toString() ?? '');
    _weightController = TextEditingController(text: profile?.weightKg?.toString() ?? '');

    _caloriesController = TextEditingController(text: nutrition.calories.toString());
    _proteinController = TextEditingController(text: nutrition.proteinG.toString());
    _carbsController = TextEditingController(text: nutrition.carbsG.toString());
    _fatController = TextEditingController(text: nutrition.fatG.toString());

    _gender = profile?.gender;
    _dateOfBirth = profile?.dateOfBirth;
    _fitnessGoal = profile?.fitnessGoal;
    _activityLevel = profile?.activityLevel;
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _usernameController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _caloriesController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final profile = ref.read(profileProvider).value;
    if (profile == null) return;

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // 1. Update Profile in Supabase
      final updatedProfile = profile.copyWith(
        fullName: _fullNameController.text.trim(),
        username: _usernameController.text.trim(),
        gender: _gender,
        dateOfBirth: _dateOfBirth,
        heightCm: double.tryParse(_heightController.text),
        weightKg: double.tryParse(_weightController.text),
        fitnessGoal: _fitnessGoal,
        activityLevel: _activityLevel,
        updatedAt: DateTime.now(),
      );

      await ref.read(profileRepositoryProvider).updateProfile(updatedProfile);
      ref.invalidate(profileProvider);

      // 2. Update Nutrition Targets
      await ref.read(nutritionTargetsProvider.notifier).updateTargets(
            calories: int.tryParse(_caloriesController.text),
            proteinG: int.tryParse(_proteinController.text),
            carbsG: int.tryParse(_carbsController.text),
            fatG: int.tryParse(_fatController.text),
          );

      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!'), backgroundColor: Colors.green),
        );
        context.go('/profile');
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update profile: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.check_rounded),
            onPressed: _save,
            tooltip: 'Save Changes',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // SECTION 1: Personal Info
              _buildSectionHeader('Personal Information', theme),
              const SizedBox(height: 12),
              TextFormField(
                controller: _fullNameController,
                decoration: const InputDecoration(labelText: 'Full Name', border: OutlineInputBorder()),
                validator: (val) => val == null || val.trim().isEmpty ? 'Enter your full name' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(labelText: 'Username', border: OutlineInputBorder()),
                validator: (val) => val == null || val.trim().isEmpty ? 'Enter a username' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _gender,
                decoration: const InputDecoration(labelText: 'Gender', border: OutlineInputBorder()),
                items: _genderOptions.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                onChanged: (val) => setState(() => _gender = val),
              ),
              const SizedBox(height: 16),
              ListTile(
                shape: RoundedRectangleBorder(
                  side: const BorderSide(color: Colors.grey),
                  borderRadius: BorderRadius.circular(4),
                ),
                title: const Text('Date of Birth', style: TextStyle(fontSize: 12, color: Colors.grey)),
                subtitle: Text(
                  _dateOfBirth == null ? 'Not set' : DateFormat('MMMM d, yyyy').format(_dateOfBirth!),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                trailing: const Icon(Icons.calendar_today_rounded),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _dateOfBirth ?? DateTime.now().subtract(const Duration(days: 365 * 25)),
                    firstDate: DateTime.now().subtract(const Duration(days: 365 * 120)),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) {
                    setState(() => _dateOfBirth = picked);
                  }
                },
              ),
              const SizedBox(height: 28),

              // SECTION 2: Body Stats & Goals
              _buildSectionHeader('Fitness Stats & Goals', theme),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _heightController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Height (cm)', border: OutlineInputBorder()),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _weightController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Weight (kg)', border: OutlineInputBorder()),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _fitnessGoal,
                decoration: const InputDecoration(labelText: 'Fitness Goal', border: OutlineInputBorder()),
                items: _goalOptions.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                onChanged: (val) => setState(() => _fitnessGoal = val),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _activityLevel,
                decoration: const InputDecoration(labelText: 'Activity Level', border: OutlineInputBorder()),
                items: _activityOptions.map((a) => DropdownMenuItem(value: a, child: Text(a))).toList(),
                onChanged: (val) => setState(() => _activityLevel = val),
              ),
              const SizedBox(height: 28),

              // SECTION 3: Nutrition Goals
              _buildSectionHeader('Daily Nutrition Targets', theme),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _caloriesController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Calories (kcal)', border: OutlineInputBorder()),
                      validator: (val) => val == null || int.tryParse(val) == null ? 'Enter valid number' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _proteinController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Protein (g)', border: OutlineInputBorder()),
                      validator: (val) => val == null || int.tryParse(val) == null ? 'Enter valid number' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _carbsController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Carbs (g)', border: OutlineInputBorder()),
                      validator: (val) => val == null || int.tryParse(val) == null ? 'Enter valid number' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _fatController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Fat (g)', border: OutlineInputBorder()),
                      validator: (val) => val == null || int.tryParse(val) == null ? 'Enter valid number' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),

              // Save Button
              ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.black,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
        const Divider(),
      ],
    );
  }
}
