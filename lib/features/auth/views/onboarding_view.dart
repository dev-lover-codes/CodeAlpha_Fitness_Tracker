import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:fit_track/core/providers/auth_provider.dart';
import 'package:fit_track/core/providers/profile_provider.dart';
import 'package:fit_track/core/providers/settings_provider.dart';
import 'package:fit_track/core/ui/ui.dart';
import 'package:fit_track/core/utils/units.dart';
import 'package:fit_track/features/auth/widgets/option_list.dart';

const goalOptions = [
  Option('lose_weight', 'Lose weight', 'Drop some fat and keep the muscle'),
  Option('build_muscle', 'Build muscle', 'Get stronger and put on size'),
  Option('maintain', 'Stay fit', "Happy where you are, just want to keep it"),
  Option('endurance', 'Build endurance', 'Run, ride or swim further without gassing out'),
];

const activityOptions = [
  Option('Sedentary', 'Mostly sitting', 'Desk job, not much exercise right now'),
  Option('Lightly Active', 'A little active', 'Walks, or a workout 1–3 times a week'),
  Option('Moderately Active', 'Fairly active', 'Training 3–5 times a week'),
  Option('Very Active', 'Very active', 'Training hard most days'),
];

class OnboardingView extends ConsumerStatefulWidget {
  const OnboardingView({super.key});

  @override
  ConsumerState<OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends ConsumerState<OnboardingView> {
  final _formKey = GlobalKey<FormState>();
  final _height = TextEditingController();
  final _weight = TextEditingController();

  int _step = 0;
  bool _busy = false;
  DateTime? _birthday;
  String _gender = 'Female';
  String _goal = 'build_muscle';
  String _activityLevel = 'Lightly Active';
  String? _birthdayError;

  @override
  void dispose() {
    _height.dispose();
    _weight.dispose();
    super.dispose();
  }

  Future<void> _pickBirthday() async {
    final now = DateTime.now();
    final latest = DateTime(now.year - 13, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthday ?? DateTime(now.year - 25, now.month, now.day),
      firstDate: DateTime(1920),
      lastDate: latest,
      helpText: 'Your date of birth',
    );
    if (picked != null) {
      setState(() {
        _birthday = picked;
        _birthdayError = null;
      });
    }
  }

  void _next() {
    if (_step == 0) {
      final valid = _formKey.currentState!.validate();
      if (_birthday == null) setState(() => _birthdayError = 'We need this to work out your age');
      if (!valid || _birthday == null) return;
    }
    if (_step < 2) {
      setState(() => _step++);
    } else {
      _finish();
    }
  }

  Future<void> _finish() async {
    final user = ref.read(authServiceProvider).currentUser;
    if (user == null) return;
    final units = ref.read(weightUnitProvider);
    setState(() => _busy = true);
    try {
      await ref.read(authServiceProvider).updateProfile(
            userId: user.id,
            heightCm: double.parse(_height.text.trim().replaceAll(',', '.')),
            weightKg: units.parse(_weight.text)!,
            dateOfBirth: _birthday!,
            gender: _gender,
            fitnessGoal: _goal,
            activityLevel: _activityLevel,
          );
      ref.invalidate(profileProvider);
      ref.invalidate(userProfileProvider); // the router moves on once this reloads
    } catch (e) {
      if (mounted) showErrorToast(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const titles = ['A bit about you', 'What are you working towards?', 'How active are you these days?'];
    const subtitles = [
      'Used to set your calories and pick exercises that suit you. It stays private.',
      'Pick the one that matters most right now. You can change it later.',
      'Be honest. This decides how many days a week your plan has.',
    ];

    return PopScope(
      canPop: _step == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _step > 0) setState(() => _step--);
      },
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          leading: _step > 0
              ? IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => setState(() => _step--))
              : null,
          title: Text('Step ${_step + 1} of 3', style: context.text.bodySmall),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(4),
            child: Padding(padding: kPage, child: Meter(value: (_step + 1) / 3, height: 3)),
          ),
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                  children: [
                    Text(titles[_step], style: context.text.headlineLarge),
                    const SizedBox(height: 8),
                    Text(subtitles[_step], style: context.text.bodyLarge!.copyWith(color: context.palette.muted)),
                    const SizedBox(height: 28),
                    if (_step == 0) _aboutYou(),
                    if (_step == 1)
                      OptionList(options: goalOptions, selected: _goal, onSelect: (v) => setState(() => _goal = v)),
                    if (_step == 2)
                      OptionList(
                        options: activityOptions,
                        selected: _activityLevel,
                        onSelect: (v) => setState(() => _activityLevel = v),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: PrimaryButton(label: _step == 2 ? 'Build my plan' : 'Continue', busy: _busy, onPressed: _next),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _aboutYou() {
    final units = ref.watch(weightUnitProvider);
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('I am', style: context.text.labelMedium),
          const SizedBox(height: 8),
          SegmentedButton<String>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(value: 'Female', label: Text('A woman')),
              ButtonSegment(value: 'Male', label: Text('A man')),
              ButtonSegment(value: 'Other', label: Text('Other')),
            ],
            selected: {_gender},
            onSelectionChanged: (s) => setState(() => _gender = s.first),
          ),
          const SizedBox(height: 20),
          InkWell(
            onTap: _pickBirthday,
            borderRadius: BorderRadius.circular(12),
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: 'Date of birth',
                errorText: _birthdayError,
                suffixIcon: const Icon(Icons.calendar_today_outlined, size: 18),
              ),
              isEmpty: _birthday == null,
              child: Text(
                _birthday == null ? '' : DateFormat('d MMMM yyyy').format(_birthday!),
                style: context.text.bodyLarge,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextFormField(
                  controller: _height,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Height (cm)'),
                  validator: validateHeight,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _weight,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(labelText: 'Weight (${units.label})'),
                  validator: (v) => validateWeight(units, v),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {
                final kg = units.parse(_weight.text);
                final toPounds = !units.pounds;
                ref.read(settingsProvider.notifier).updateWeightUnit(toPounds ? 'lb' : 'kg');
                if (kg != null) _weight.text = WeightUnit(toPounds).number(kg);
              },
              child: Text(
                units.pounds ? 'Use kilograms instead' : 'Use pounds instead',
                style: context.text.labelMedium!.copyWith(color: context.palette.muted),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String? validateHeight(String? v) {
  final h = double.tryParse((v ?? '').trim().replaceAll(',', '.'));
  if (h == null) return 'Enter your height';
  if (h < 100 || h > 250) return 'Between 100 and 250 cm';
  return null;
}

String? validateWeight(WeightUnit units, String? v) {
  final kg = units.parse(v ?? '');
  if (kg == null) return 'Enter your weight';
  if (kg < 30 || kg > 300) return 'That looks off';
  return null;
}
