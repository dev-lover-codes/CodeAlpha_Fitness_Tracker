// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/providers/auth_provider.dart';

class OnboardingView extends ConsumerStatefulWidget {
  const OnboardingView({super.key});

  @override
  ConsumerState<OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends ConsumerState<OnboardingView> {
  final PageController _pageController = PageController();
  final _step1FormKey = GlobalKey<FormState>();

  int _currentPage = 0;
  bool _isLoading = false;
  String? _errorMessage;

  // Step 1 values
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  DateTime? _selectedDateOfBirth;
  String _selectedGender = 'Male';

  // Step 2 values
  String _selectedGoal = 'lose_weight'; // Maps to public.fitness_goal_type

  // Step 3 values
  String _selectedActivityLevel = 'Moderately Active';

  static const Map<String, IconData> _goalIcons = {
    'lose_weight': Icons.trending_down_rounded,
    'build_muscle': Icons.fitness_center_rounded,
    'maintain': Icons.balance_rounded,
    'endurance': Icons.directions_run_rounded,
  };

  final List<Map<String, String>> _goals = [
    {
      'key': 'lose_weight',
      'title': 'Lose weight',
      'description': 'Drop some fat, feel lighter, keep the muscle',
    },
    {
      'key': 'build_muscle',
      'title': 'Build muscle',
      'description': 'Get stronger and put on size',
    },
    {
      'key': 'maintain',
      'title': 'Stay fit',
      'description': "Happy where you are. Just want to keep it that way",
    },
    {
      'key': 'endurance',
      'title': 'Build endurance',
      'description': 'Run, ride or swim further without gassing out',
    },
  ];

  final List<Map<String, String>> _activityLevels = [
    {
      'name': 'Sedentary',
      'description': 'Mostly sitting. Desk job, not much exercise',
    },
    {
      'name': 'Lightly Active',
      'description': 'Some walking or a workout 1–3 times a week',
    },
    {
      'name': 'Moderately Active',
      'description': 'Training 3–5 times a week',
    },
    {
      'name': 'Very Active',
      'description': 'Training hard most days',
    },
  ];

  @override
  void dispose() {
    _pageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _selectDateOfBirth(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 25)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedDateOfBirth = picked;
      });
    }
  }

  void _nextPage() {
    if (_currentPage == 0) {
      if (!_step1FormKey.currentState!.validate()) return;
      if (_selectedDateOfBirth == null) {
        setState(() {
          _errorMessage = "Please select your date of birth.";
        });
        return;
      }
    }

    setState(() {
      _errorMessage = null;
    });

    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _previousPage() {
    _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _submitOnboarding() async {
    final authService = ref.read(authServiceProvider);
    final user = authService.currentUser;
    if (user == null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final height = double.parse(_heightController.text);
      final weight = double.parse(_weightController.text);

      await authService.updateProfile(
        userId: user.id,
        heightCm: height,
        weightKg: weight,
        dateOfBirth: _selectedDateOfBirth!,
        gender: _selectedGender,
        fitnessGoal: _selectedGoal,
        activityLevel: _selectedActivityLevel,
      );

      // Force Riverpod to refresh the profile cache
      ref.invalidate(userProfileProvider);

      if (mounted) {
        context.go('/home');
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll("Exception: ", "");
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Step ${_currentPage + 1} of 3'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Progress Indicator Bar
            LinearProgressIndicator(
              value: (_currentPage + 1) / 3.0,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
            ),
            
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (page) {
                  setState(() {
                    _currentPage = page;
                  });
                },
                children: [
                  _buildStep1Biological(),
                  _buildStep2Goals(),
                  _buildStep3Activity(),
                ],
              ),
            ),

            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),

            // Bottom Navigation Panel
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (_currentPage > 0)
                    OutlinedButton(
                      onPressed: _isLoading ? null : _previousPage,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Back'),
                    )
                  else
                    const SizedBox.shrink(),
                  
                  ElevatedButton(
                    onPressed: _isLoading
                        ? null
                        : (_currentPage == 2 ? _submitOnboarding : _nextPage),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isLoading
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(color: theme.colorScheme.onPrimary, strokeWidth: 2),
                          )
                        : Text(_currentPage == 2 ? 'Build my plan' : 'Next'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // STEP 1 UI: Biological details
  Widget _buildStep1Biological() {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _step1FormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'First, a bit about you',
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              "We use this to set your calories and pick exercises that suit you. It stays private.",
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.textTheme.bodySmall?.color),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // Height Field
            TextFormField(
              controller: _heightController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Height (cm)',
                prefixIcon: const Icon(Icons.height),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) return 'Enter your height';
                final h = double.tryParse(value);
                if (h == null || h < 50 || h > 300) return 'Enter a valid height (50-300 cm)';
                return null;
              },
            ),
            const SizedBox(height: 20),

            // Weight Field
            TextFormField(
              controller: _weightController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Weight (kg)',
                prefixIcon: const Icon(Icons.monitor_weight),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) return 'Enter your weight';
                final w = double.tryParse(value);
                if (w == null || w < 20 || w > 500) return 'Enter a valid weight (20-500 kg)';
                return null;
              },
            ),
            const SizedBox(height: 20),

            // Date of birth
            InkWell(
              onTap: () => _selectDateOfBirth(context),
              borderRadius: BorderRadius.circular(12),
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Date of Birth',
                  prefixIcon: const Icon(Icons.calendar_today),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  _selectedDateOfBirth == null
                      ? 'Select Date'
                      : DateFormat('yyyy-MM-dd').format(_selectedDateOfBirth!),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Gender Selection
            DropdownButtonFormField<String>(
              initialValue: _selectedGender,
              decoration: InputDecoration(
                labelText: 'Gender',
                prefixIcon: const Icon(Icons.people),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              items: ['Male', 'Female', 'Other']
                  .map((gender) => DropdownMenuItem(value: gender, child: Text(gender)))
                  .toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _selectedGender = val;
                  });
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  // STEP 2 UI: Goal selector
  Widget _buildStep2Goals() {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            "What are you working towards?",
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            "Pick the one that matters most right now. You can change it later.",
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.textTheme.bodySmall?.color),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _goals.length,
            itemBuilder: (context, index) {
              final goal = _goals[index];
              final isSelected = _selectedGoal == goal['key'];

              return Card(
                elevation: isSelected ? 4 : 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: isSelected ? theme.colorScheme.primary : Colors.transparent,
                    width: 2,
                  ),
                ),
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: Icon(
                    _goalIcons[goal['key']],
                    size: 28,
                    color: isSelected ? theme.colorScheme.primary : null,
                  ),
                  title: Text(
                    goal['title']!,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  subtitle: Text(goal['description']!),
                  trailing: Radio<String>(
                    value: goal['key']!,
                    groupValue: _selectedGoal,
                    activeColor: theme.colorScheme.primary,
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _selectedGoal = val;
                        });
                      }
                    },
                  ),
                  onTap: () {
                    setState(() {
                      _selectedGoal = goal['key']!;
                    });
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // STEP 3 UI: Activity level selector
  Widget _buildStep3Activity() {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'How active are you these days?',
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            "Be honest. This decides how many days a week your plan has.",
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.textTheme.bodySmall?.color),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _activityLevels.length,
            itemBuilder: (context, index) {
              final activity = _activityLevels[index];
              final isSelected = _selectedActivityLevel == activity['name'];

              return Card(
                elevation: isSelected ? 4 : 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: isSelected ? theme.colorScheme.primary : Colors.transparent,
                    width: 2,
                  ),
                ),
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  title: Text(
                    activity['name']!,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  subtitle: Text(activity['description']!),
                  trailing: Radio<String>(
                    value: activity['name']!,
                    groupValue: _selectedActivityLevel,
                    activeColor: theme.colorScheme.primary,
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _selectedActivityLevel = val;
                        });
                      }
                    },
                  ),
                  onTap: () {
                    setState(() {
                      _selectedActivityLevel = activity['name']!;
                    });
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
