import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fit_track/core/constants/app_constants.dart';
import 'package:fit_track/core/providers/auth_provider.dart';
import 'package:fit_track/core/providers/notification_provider.dart';
import 'package:fit_track/core/providers/settings_provider.dart';
import 'package:fit_track/core/ui/ui.dart';
import 'package:fit_track/features/auth/widgets/auth_layout.dart' show validateNewPassword;

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _changePassword(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final password = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New password'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            obscureText: true,
            autofocus: true,
            decoration: const InputDecoration(helperText: 'At least 8 characters'),
            validator: validateNewPassword,
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              if (formKey.currentState!.validate()) Navigator.pop(ctx, controller.text);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (password == null || !context.mounted) return;
    final ok = await runWithSpinner(context, () async {
      await ref.read(authServiceProvider).updatePassword(password);
      return true;
    });
    if (ok == true && context.mounted) showToast(context, 'Password changed.');
  }

  Future<void> _deleteAccount(BuildContext context, WidgetRef ref) async {
    final confirmed = await confirmAction(
      context,
      title: 'Delete your account?',
      message:
          'This permanently removes your profile, every workout, measurement, photo, meal and goal. It can\'t be undone.',
      confirmLabel: 'Delete everything',
      destructive: true,
    );
    if (!confirmed || !context.mounted) return;
    await runWithSpinner(context, () => ref.read(authServiceProvider).deleteAccount());
    // Signing out sends the router back to the login screen.
  }

  Future<void> _toggleReminder(WidgetRef ref, bool on, Future<void> Function(bool) update) async {
    if (on) await ref.read(notificationServiceProvider).requestPermissions();
    await update(on);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(settingsProvider);
    final n = ref.read(settingsProvider.notifier);
    final p = context.palette;

    return Scaffold(
      appBar: AppBar(),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 40),
        children: [
          Padding(padding: kPage, child: Text('Settings', style: context.text.headlineLarge)),
          const SectionLabel('Units'),
          PanelList(children: [
            ListRow(
              title: 'Weight',
              trailing: SegmentedButton<String>(
                showSelectedIcon: false,
                segments: const [ButtonSegment(value: 'kg', label: Text('kg')), ButtonSegment(value: 'lb', label: Text('lb'))],
                selected: {s.weightUnit},
                onSelectionChanged: (v) => n.updateWeightUnit(v.first),
              ),
            ),
          ]),
          const SectionLabel('Appearance'),
          Padding(
            padding: kPage,
            child: SegmentedButton<ThemeMode>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(value: ThemeMode.system, label: Text('Automatic')),
                ButtonSegment(value: ThemeMode.light, label: Text('Light')),
                ButtonSegment(value: ThemeMode.dark, label: Text('Dark')),
              ],
              selected: {s.themeMode},
              onSelectionChanged: (v) => n.updateThemeMode(v.first),
            ),
          ),
          const SectionLabel('Reminders'),
          PanelList(children: [
            SwitchListTile(
              title: const Text('Daily nudge'),
              subtitle: const Text("Only if you haven't trained yet that day"),
              value: s.dailyReminderEnabled,
              onChanged: (v) => _toggleReminder(ref, v, n.updateDailyReminder),
            ),
            if (s.dailyReminderEnabled)
              ListRow(
                title: 'Time',
                trailing: Text(s.dailyReminderTime, style: context.text.labelLarge),
                onTap: () async {
                  final parts = s.dailyReminderTime.split(':');
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay(hour: int.tryParse(parts[0]) ?? 8, minute: int.tryParse(parts.last) ?? 0),
                  );
                  if (picked != null) {
                    n.updateDailyReminderTime(
                        '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}');
                  }
                },
              ),
            SwitchListTile(
              title: const Text('Streak warning'),
              subtitle: const Text('At 8pm if your streak is about to end'),
              value: s.streakReminderEnabled,
              onChanged: (v) => _toggleReminder(ref, v, n.updateStreakReminder),
            ),
            SwitchListTile(
              title: const Text('Goal deadlines'),
              subtitle: const Text('Three days before a goal is due'),
              value: s.goalDeadlineReminderEnabled,
              onChanged: (v) => _toggleReminder(ref, v, n.updateGoalReminder),
            ),
          ]),
          const SectionLabel('Account'),
          PanelList(children: [
            ListRow(title: 'Change password', chevron: true, onTap: () => _changePassword(context, ref)),
            ListRow(
              title: 'Sign out',
              onTap: () async {
                final ok = await confirmAction(context, title: 'Sign out?', confirmLabel: 'Sign out');
                if (ok) await ref.read(authServiceProvider).signOut();
              },
            ),
            ListRow(title: 'Delete account', titleColor: p.danger, onTap: () => _deleteAccount(context, ref)),
          ]),
          const SectionLabel('About'),
          Padding(
            padding: kPage,
            child: Text(
              'FitTrack ${AppConstants.version}\n\n'
              'Your workouts, measurements and photos are stored in your own account and only used to run the app. '
              'Nothing is sold or shared. Photos are private to you.\n\n'
              'The plan and calorie numbers are general guidance, not medical advice. Check with a doctor before starting '
              'something new if you have an injury or health condition.',
              style: context.text.bodySmall!.copyWith(height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}
