import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:fit_track/core/providers/auth_provider.dart';
import 'package:fit_track/core/providers/nutrition_targets_provider.dart';
import 'package:fit_track/core/providers/plan_provider.dart';
import 'package:fit_track/core/providers/profile_provider.dart';
import 'package:fit_track/core/providers/repository_providers.dart';
import 'package:fit_track/core/ui/ui.dart';
import 'package:fit_track/core/utils/units.dart';
import 'package:fit_track/features/auth/views/onboarding_view.dart' show goalOptions, activityOptions, validateHeight, validateWeight;

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _username;
  late final TextEditingController _height;
  late final TextEditingController _weight;
  late final TextEditingController _kcal;
  late final TextEditingController _protein;
  late final TextEditingController _carbs;
  late final TextEditingController _fat;

  String? _gender;
  DateTime? _birthday;
  String? _goal;
  String? _activity;
  late bool _customFood;
  bool _busy = false;

  static const _genders = ['Female', 'Male', 'Other', 'Prefer not to say'];

  @override
  void initState() {
    super.initState();
    final p = ref.read(profileProvider).value;
    final t = ref.read(nutritionTargetsProvider);
    final units = ref.read(weightUnitProvider);

    _name = TextEditingController(text: p?.fullName ?? '');
    _username = TextEditingController(text: p?.username ?? '');
    _height = TextEditingController(text: p?.heightCm == null ? '' : trimNum(p!.heightCm!));
    _weight = TextEditingController(text: p?.weightKg == null ? '' : units.number(p!.weightKg!));
    _kcal = TextEditingController(text: '${t.calories}');
    _protein = TextEditingController(text: '${t.proteinG}');
    _carbs = TextEditingController(text: '${t.carbsG}');
    _fat = TextEditingController(text: '${t.fatG}');

    _gender = _genders.contains(p?.gender) ? p?.gender : null;
    _birthday = p?.dateOfBirth;
    _goal = goalOptions.any((o) => o.value == p?.fitnessGoal) ? p?.fitnessGoal : null;
    _activity = activityOptions.any((o) => o.value == p?.activityLevel) ? p?.activityLevel : null;
    _customFood = t.custom;
  }

  @override
  void dispose() {
    for (final c in [_name, _username, _height, _weight, _kcal, _protein, _carbs, _fat]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final profile = ref.read(profileProvider).value;
    if (profile == null) return;
    final units = ref.read(weightUnitProvider);

    setState(() => _busy = true);
    try {
      await ref.read(profileRepositoryProvider).updateProfile(profile.copyWith(
            fullName: _name.text.trim(),
            username: _username.text.trim(),
            gender: _gender,
            dateOfBirth: _birthday,
            heightCm: double.tryParse(_height.text.replaceAll(',', '.')),
            weightKg: units.parse(_weight.text),
            fitnessGoal: _goal,
            activityLevel: _activity,
          ));
      ref.invalidate(profileProvider);
      ref.invalidate(userProfileProvider);

      final targets = ref.read(nutritionTargetsProvider.notifier);
      if (_customFood) {
        await targets.updateTargets(NutritionTargets(
          calories: int.tryParse(_kcal.text) ?? 2000,
          proteinG: int.tryParse(_protein.text) ?? 120,
          carbsG: int.tryParse(_carbs.text) ?? 200,
          fatG: int.tryParse(_fat.text) ?? 60,
        ));
      } else {
        await targets.useSuggested();
      }

      if (!mounted) return;
      showToast(context, 'Saved. Your plan has been updated.');
      context.canPop() ? context.pop() : context.go('/profile');
    } catch (e) {
      if (!mounted) return;
      final msg = friendlyError(e);
      showToast(context, msg.contains('already exists') ? 'That username is taken. Try another.' : msg);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final units = ref.watch(weightUnitProvider);
    final suggested = ref.watch(suggestedNutritionProvider);

    Widget label(String t) => Padding(
          padding: const EdgeInsets.only(top: 24, bottom: 10),
          child: Text(t.toUpperCase(), style: context.text.labelSmall),
        );

    return Scaffold(
      appBar: AppBar(),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
          children: [
            Text('Your details', style: context.text.headlineLarge),
            const SizedBox(height: 6),
            Text('Your plan and calorie targets update when you save.',
                style: context.text.bodyMedium!.copyWith(color: context.palette.muted)),
            label('About you'),
            TextFormField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Name'),
              validator: (v) => (v ?? '').trim().isEmpty ? 'Add your name' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _username,
              decoration: const InputDecoration(labelText: 'Username', prefixText: '@'),
              validator: (v) {
                final s = (v ?? '').trim();
                if (s.length < 3) return 'At least 3 characters';
                if (!RegExp(r'^[a-zA-Z0-9_.]+$').hasMatch(s)) return 'Letters, numbers, dots and underscores only';
                return null;
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _gender,
              decoration: const InputDecoration(labelText: 'Gender'),
              items: [for (final g in _genders) DropdownMenuItem(value: g, child: Text(g))],
              onChanged: (v) => setState(() => _gender = v),
            ),
            const SizedBox(height: 12),
            InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () async {
                final now = DateTime.now();
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _birthday ?? DateTime(now.year - 25),
                  firstDate: DateTime(1920),
                  lastDate: DateTime(now.year - 13, now.month, now.day),
                );
                if (picked != null) setState(() => _birthday = picked);
              },
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Date of birth',
                  suffixIcon: Icon(Icons.calendar_today_outlined, size: 18),
                ),
                isEmpty: _birthday == null,
                child: Text(_birthday == null ? '' : DateFormat('d MMMM yyyy').format(_birthday!)),
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
            label('Goal'),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final o in goalOptions) Pill(label: o.title, selected: _goal == o.value, onTap: () => setState(() => _goal = o.value)),
              ],
            ),
            label('How active you are'),
            DropdownButtonFormField<String>(
              initialValue: _activity,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Activity'),
              items: [
                for (final o in activityOptions) DropdownMenuItem(value: o.value, child: Text('${o.title} · ${o.detail}', overflow: TextOverflow.ellipsis)),
              ],
              onChanged: (v) => setState(() => _activity = v),
            ),
            label('Daily food targets'),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Set my own numbers'),
              subtitle: Text(
                suggested == null
                    ? 'Otherwise we work them out from your details.'
                    : 'Otherwise we use ${suggested.calories} kcal and ${suggested.proteinG} g protein from your plan.',
              ),
              value: _customFood,
              onChanged: (v) => setState(() => _customFood = v),
            ),
            if (_customFood) ...[
              const SizedBox(height: 8),
              TextFormField(
                controller: _kcal,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Calories', suffixText: 'kcal'),
                validator: (v) => (int.tryParse(v ?? '') ?? 0) < 800 ? 'At least 800' : null,
              ),
              const SizedBox(height: 12),
              Row(children: [
                for (final (c, l) in [(_protein, 'Protein'), (_carbs, 'Carbs'), (_fat, 'Fat')]) ...[
                  Expanded(
                    child: TextFormField(
                      controller: c,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(labelText: l, suffixText: 'g'),
                      validator: (v) => int.tryParse(v ?? '') == null ? 'Number' : null,
                    ),
                  ),
                  if (l != 'Fat') const SizedBox(width: 8),
                ],
              ]),
            ],
            const SizedBox(height: 32),
            PrimaryButton(label: 'Save', busy: _busy, onPressed: _save),
          ],
        ),
      ),
    );
  }
}
