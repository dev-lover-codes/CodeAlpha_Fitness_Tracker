import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fit_track/core/models/profile.dart';
import 'package:fit_track/core/providers/auth_provider.dart';
import 'package:fit_track/core/providers/plan_provider.dart';
import 'package:fit_track/core/providers/profile_provider.dart';
import 'package:fit_track/core/providers/repository_providers.dart';
import 'package:fit_track/core/providers/workouts_provider.dart';
import 'package:fit_track/core/services/plan_engine.dart';
import 'package:fit_track/core/ui/ui.dart';

final avatarBytesProvider = FutureProvider.family<Uint8List, String>((ref, path) async {
  return Supabase.instance.client.storage.from('avatars').download(path);
});

class ProfileView extends ConsumerWidget {
  const ProfileView({super.key});

  Future<void> _changePhoto(BuildContext context, WidgetRef ref, Profile profile) async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 75, maxWidth: 800);
    if (picked == null || !context.mounted) return;
    final storage = Supabase.instance.client.storage.from('avatars');
    final path = '${profile.id}/avatar_${DateTime.now().millisecondsSinceEpoch}.jpg';

    await runWithSpinner(context, () async {
      await storage.upload(path, File(picked.path), fileOptions: const FileOptions(upsert: true));
      await ref.read(profileRepositoryProvider).updateProfile(profile.copyWith(avatarUrl: path));
      // Clean up the old picture so storage doesn't fill up.
      final old = profile.avatarUrl;
      if (old != null && old.isNotEmpty && !old.startsWith('http') && old != path) {
        try {
          await storage.remove([old]);
        } catch (_) {}
      }
      ref.invalidate(profileProvider);
    });
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(profileProvider);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: async.when(
          loading: () => const Loading(),
          error: (e, _) => ErrorNote(error: e, onRetry: () => ref.invalidate(profileProvider)),
          data: (profile) {
            if (profile == null) return const EmptyNote(title: "We couldn't find your profile");
            final plan = ref.watch(fitnessPlanProvider).value;
            return ListView(
              padding: const EdgeInsets.only(bottom: 40),
              children: [
                const PageTitle('You'),
                const SizedBox(height: 8),
                Padding(
                  padding: kPage,
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => _changePhoto(context, ref, profile),
                        child: _Avatar(profile: profile),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              (profile.fullName ?? '').isEmpty ? 'Add your name' : profile.fullName!,
                              style: context.text.titleLarge,
                            ),
                            if ((profile.username ?? '').isNotEmpty) Text('@${profile.username}', style: context.text.bodySmall),
                            Text('Since ${DateFormat('MMMM yyyy').format(profile.createdAt)}', style: context.text.bodySmall),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const _Numbers(),
                const _Milestones(),
                const SectionLabel('Your setup'),
                PanelList(children: [
                  ListRow(
                    leading: const Icon(Icons.person_outline),
                    title: 'Your details',
                    subtitle: _detailLine(profile, plan),
                    chevron: true,
                    onTap: () => context.push('/profile/edit'),
                  ),
                  ListRow(
                    leading: const Icon(Icons.calendar_view_week_outlined),
                    title: 'Your plan',
                    subtitle: plan == null ? null : '${plan.daysPerWeek} days a week · ${experienceLabel(plan.experience).toLowerCase()}',
                    chevron: true,
                    onTap: () => context.push('/plan'),
                  ),
                  ListRow(
                    leading: const Icon(Icons.flag_outlined),
                    title: 'Goals',
                    chevron: true,
                    onTap: () => context.push('/goals'),
                  ),
                  ListRow(
                    leading: const Icon(Icons.menu_book_outlined),
                    title: 'Exercises',
                    chevron: true,
                    onTap: () => context.push('/exercises'),
                  ),
                  ListRow(
                    leading: const Icon(Icons.settings_outlined),
                    title: 'Settings',
                    chevron: true,
                    onTap: () => context.push('/settings'),
                  ),
                ]),
                const SizedBox(height: 20),
                Center(
                  child: TextButton(
                    onPressed: () async {
                      final ok = await confirmAction(context, title: 'Sign out?', confirmLabel: 'Sign out');
                      if (ok) await ref.read(authServiceProvider).signOut();
                    },
                    child: const Text('Sign out'),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  static String? _detailLine(Profile p, FitnessPlan? plan) {
    final parts = [
      if (plan != null) goalLabel(plan.goal),
      if (p.heightCm != null) '${trimNum(p.heightCm!)} cm',
    ];
    return parts.isEmpty ? null : parts.join(' · ');
  }
}

class _Avatar extends ConsumerWidget {
  final Profile profile;
  const _Avatar({required this.profile});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final path = profile.avatarUrl ?? '';
    final initials = (profile.fullName ?? '?')
        .trim()
        .split(RegExp(r'\s+'))
        .where((s) => s.isNotEmpty)
        .take(2)
        .map((s) => s[0].toUpperCase())
        .join();

    Widget fallback() => Center(child: Text(initials.isEmpty ? '?' : initials, style: context.text.headlineSmall));

    Widget image;
    if (path.isEmpty) {
      image = fallback();
    } else if (path.startsWith('http')) {
      image = Image.network(path, fit: BoxFit.cover, errorBuilder: (_, _, _) => fallback());
    } else {
      image = ref.watch(avatarBytesProvider(path)).when(
            data: (bytes) => Image.memory(bytes, fit: BoxFit.cover),
            loading: () => fallback(),
            error: (_, _) => fallback(),
          );
    }

    return Stack(
      children: [
        Container(
          width: 72,
          height: 72,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(shape: BoxShape.circle, color: p.surfaceAlt),
          child: image,
        ),
        Positioned(
          right: 0,
          bottom: 0,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(color: p.ink, shape: BoxShape.circle, border: Border.all(color: p.background, width: 2)),
            child: Icon(Icons.edit, size: 12, color: p.inkInverse),
          ),
        ),
      ],
    );
  }
}

class _Numbers extends ConsumerWidget {
  const _Numbers();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final total = ref.watch(workoutCountProvider).value ?? 0;
    final streak = ref.watch(streakProvider).value;
    final workouts = ref.watch(userWorkoutsProvider).value ?? const [];
    final now = DateTime.now();
    final thisMonth = workouts.where((w) => w.startedAt.year == now.year && w.startedAt.month == now.month).length;

    return Panel(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Expanded(child: Padding(padding: const EdgeInsets.only(left: 16), child: Stat(value: '$total', label: 'Workouts'))),
            VerticalDivider(width: 1, color: p.line),
            Expanded(child: Padding(padding: const EdgeInsets.only(left: 16), child: Stat(value: '$thisMonth', label: 'This month'))),
            VerticalDivider(width: 1, color: p.line),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 16),
                child: Stat(value: '${streak?.longestStreak ?? 0}', unit: 'd', label: 'Best streak'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Milestones extends ConsumerWidget {
  const _Milestones();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final total = ref.watch(workoutCountProvider).value ?? 0;
    final longest = ref.watch(streakProvider).value?.longestStreak ?? 0;

    final items = <(String, bool)>[
      ('First workout', total >= 1),
      ('10 workouts', total >= 10),
      ('50 workouts', total >= 50),
      ('100 workouts', total >= 100),
      ('A full week streak', longest >= 7),
      ('A month-long streak', longest >= 30),
    ];
    final next = items.where((i) => !i.$2).firstOrNull;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionLabel('Milestones · ${items.where((i) => i.$2).length} of ${items.length}'),
        Padding(
          padding: kPage,
          child: Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final (title, got) in items)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: got ? p.accentSoft : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: got ? Colors.transparent : p.line),
                  ),
                  child: Text(
                    title,
                    style: context.text.labelMedium!.copyWith(color: got ? p.accent : p.faint),
                  ),
                ),
            ],
          ),
        ),
        if (next != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
            child: Text('Next up: ${next.$1.toLowerCase()}.', style: context.text.bodySmall),
          ),
      ],
    );
  }
}
