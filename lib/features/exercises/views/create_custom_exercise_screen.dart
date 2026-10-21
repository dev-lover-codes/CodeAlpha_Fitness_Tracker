import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fit_track/core/models/exercise.dart';
import 'package:fit_track/core/providers/auth_provider.dart';
import 'package:fit_track/core/providers/exercises_provider.dart';
import 'package:fit_track/core/providers/repository_providers.dart';
import 'package:fit_track/core/ui/ui.dart';

class CreateCustomExerciseScreen extends ConsumerStatefulWidget {
  const CreateCustomExerciseScreen({super.key});

  @override
  ConsumerState<CreateCustomExerciseScreen> createState() => _CreateCustomExerciseScreenState();
}

class _CreateCustomExerciseScreenState extends ConsumerState<CreateCustomExerciseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _equipment = TextEditingController();
  final _instructions = TextEditingController();

  String _type = 'strength';
  String _muscle = 'chest';
  String _difficulty = 'beginner';
  bool _busy = false;

  static const _muscles = ['chest', 'back', 'legs', 'shoulders', 'arms', 'core', 'full_body'];

  @override
  void dispose() {
    _name.dispose();
    _equipment.dispose();
    _instructions.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final user = ref.read(authServiceProvider).currentUser;
    if (user == null) return;

    final name = _name.text.trim();
    final existing = ref.read(allExercisesProvider).value ?? const <Exercise>[];
    if (existing.any((e) => e.name.toLowerCase() == name.toLowerCase())) {
      showToast(context, 'You already have an exercise called "$name".');
      return;
    }

    setState(() => _busy = true);
    try {
      final created = await ref.read(exerciseRepositoryProvider).createExercise(Exercise(
            id: '',
            name: name,
            category: _type,
            muscleGroup: _type == 'cardio' ? 'cardio' : (_type == 'flexibility' ? 'full_body' : _muscle),
            equipment: _equipment.text.trim().isEmpty ? null : _equipment.text.trim(),
            difficulty: _difficulty,
            instructions: _instructions.text.trim().isEmpty ? null : _instructions.text.trim(),
            isCustom: true,
            createdBy: user.id,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ));
      ref.invalidate(allExercisesProvider);
      if (!mounted) return;
      showToast(context, '$name added.');
      context.pushReplacement('/exercises/detail/${created.id}');
    } catch (e) {
      if (mounted) showErrorToast(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
          children: [
            Text('New exercise', style: context.text.headlineLarge),
            const SizedBox(height: 6),
            Text("For anything that isn't in the list. Only you can see it.",
                style: context.text.bodyMedium!.copyWith(color: context.palette.muted)),
            const SizedBox(height: 24),
            TextFormField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Name', hintText: 'e.g. Landmine press'),
              validator: (v) => (v ?? '').trim().length < 2 ? 'Give it a name' : null,
            ),
            const SizedBox(height: 20),
            Text('Type', style: context.text.labelMedium),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(value: 'strength', label: Text('Strength')),
                ButtonSegment(value: 'cardio', label: Text('Cardio')),
                ButtonSegment(value: 'flexibility', label: Text('Stretch')),
              ],
              selected: {_type},
              onSelectionChanged: (s) => setState(() => _type = s.first),
            ),
            if (_type == 'strength') ...[
              const SizedBox(height: 20),
              Text('Main muscle', style: context.text.labelMedium),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final m in _muscles)
                    Pill(label: capitalize(m), selected: _muscle == m, onTap: () => setState(() => _muscle = m)),
                ],
              ),
            ],
            const SizedBox(height: 20),
            Text('Difficulty', style: context.text.labelMedium),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(value: 'beginner', label: Text('Easy')),
                ButtonSegment(value: 'intermediate', label: Text('Medium')),
                ButtonSegment(value: 'advanced', label: Text('Hard')),
              ],
              selected: {_difficulty},
              onSelectionChanged: (s) => setState(() => _difficulty = s.first),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _equipment,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: 'Equipment (optional)', hintText: 'e.g. Barbell'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _instructions,
              minLines: 3,
              maxLines: 6,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'How to do it (optional)',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 28),
            PrimaryButton(label: 'Save exercise', busy: _busy, onPressed: _save),
          ],
        ),
      ),
    );
  }
}
