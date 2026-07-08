import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fit_track/core/providers/settings_provider.dart';
import 'package:fit_track/core/providers/auth_provider.dart';
import 'package:fit_track/core/providers/profile_provider.dart';
import 'package:fit_track/core/providers/workouts_provider.dart';
import 'package:fit_track/core/providers/measurement_provider.dart';
import 'package:fit_track/core/providers/goals_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _changePassword(BuildContext context) async {
    final passwordController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Password'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: passwordController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'New Password',
              border: OutlineInputBorder(),
            ),
            validator: (val) => val == null || val.length < 6 ? 'Password must be at least 6 characters' : null,
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              Navigator.pop(context); // Close dialog

              // Show loading spinner
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const Center(child: CircularProgressIndicator()),
              );

              try {
                await Supabase.instance.client.auth.updateUser(
                  UserAttributes(password: passwordController.text),
                );
                if (context.mounted) {
                  Navigator.pop(context); // Close spinner
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Password updated successfully!'), backgroundColor: Colors.green),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.pop(context); // Close spinner
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to update password: ${e.toString()}'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: const Text('Update', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAccount(BuildContext context, WidgetRef ref) async {
    final currentUser = ref.read(authServiceProvider).currentUser;
    if (currentUser == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account?', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This action is permanent and cannot be undone.',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            Text('The following data will be permanently wiped:'),
            SizedBox(height: 8),
            Text('• Your user profile information'),
            Text('• All logged workouts, sets, and lift volumes'),
            Text('• Your body stats and measurements history'),
            Text('• All uploaded progress photos'),
            Text('• All active and completed fitness goals'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // Close confirm dialog

              // Show loading spinner
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const Center(child: CircularProgressIndicator()),
              );

              try {
                // Delete user profiles table (Cascades deletes to workouts, goals, measurements, etc.)
                await Supabase.instance.client
                    .from('profiles')
                    .delete()
                    .eq('id', currentUser.id);

                // Sign out
                await ref.read(authServiceProvider).signOut();

                // Clear Riverpod states
                ref.invalidate(authStateProvider);
                ref.invalidate(userProfileProvider);
                ref.invalidate(profileProvider);
                ref.invalidate(userWorkoutsProvider);
                ref.invalidate(bodyMeasurementsProvider);
                ref.invalidate(goalsProvider);

                if (context.mounted) {
                  Navigator.pop(context); // Close spinner
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Your account has been deleted.'), backgroundColor: Colors.green),
                  );
                  context.go('/login');
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.pop(context); // Close spinner
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to delete account: ${e.toString()}'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete Permanently', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showPlaceholderDialog(BuildContext context, String title, String text) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(child: Text(text)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/profile'),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // SECTION 1: UNIT SYSTEM
          _buildHeader('Unit Preferences', theme),
          Card(
            child: Column(
              children: [
                ListTile(
                  title: const Text('Weight Unit'),
                  subtitle: Text('Current: ${settings.weightUnit.toUpperCase()}'),
                  trailing: SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'kg', label: Text('kg')),
                      ButtonSegment(value: 'lb', label: Text('lb')),
                    ],
                    selected: {settings.weightUnit},
                    onSelectionChanged: (selection) => notifier.updateWeightUnit(selection.first),
                    showSelectedIcon: false,
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  title: const Text('Height Unit'),
                  subtitle: Text('Current: ${settings.heightUnit == 'cm' ? 'cm' : 'inches'}'),
                  trailing: SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'cm', label: Text('cm')),
                      ButtonSegment(value: 'in', label: Text('in')),
                    ],
                    selected: {settings.heightUnit},
                    onSelectionChanged: (selection) => notifier.updateHeightUnit(selection.first),
                    showSelectedIcon: false,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // SECTION 2: THEME SELECTION
          _buildHeader('Appearance', theme),
          Card(
            child: ListTile(
              title: const Text('Theme Mode'),
              subtitle: Text('Select your app appearance preference'),
              trailing: DropdownButton<ThemeMode>(
                value: settings.themeMode,
                underline: const SizedBox(),
                items: const [
                  DropdownMenuItem(value: ThemeMode.system, child: Text('System')),
                  DropdownMenuItem(value: ThemeMode.light, child: Text('Light')),
                  DropdownMenuItem(value: ThemeMode.dark, child: Text('Dark')),
                ],
                onChanged: (val) {
                  if (val != null) notifier.updateThemeMode(val);
                },
              ),
            ),
          ),
          const SizedBox(height: 20),

          // SECTION 3: NOTIFICATIONS
          _buildHeader('Notification Settings', theme),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Daily Workout Reminder'),
                  subtitle: const Text('Remind me to workout if I haven\'t logged yet'),
                  value: settings.dailyReminderEnabled,
                  onChanged: (val) => notifier.updateDailyReminder(val),
                ),
                if (settings.dailyReminderEnabled) ...[
                  ListTile(
                    title: const Text('Reminder Time'),
                    subtitle: Text('Scheduled for: ${settings.dailyReminderTime}'),
                    trailing: const Icon(Icons.access_time_rounded),
                    onTap: () async {
                      final parts = settings.dailyReminderTime.split(':');
                      final initialTime = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: initialTime,
                      );
                      if (picked != null) {
                        final formattedTime = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
                        notifier.updateDailyReminderTime(formattedTime);
                      }
                    },
                  ),
                ],
                const Divider(height: 1),
                SwitchListTile(
                  title: const Text('Protect My Streak'),
                  subtitle: const Text('Evening alert if active streak is at risk of reset'),
                  value: settings.streakReminderEnabled,
                  onChanged: (val) => notifier.updateStreakReminder(val),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: const Text('Goal Deadlines'),
                  subtitle: const Text('Warn me 3 days before goal deadlines if behind pace'),
                  value: settings.goalDeadlineReminderEnabled,
                  onChanged: (val) => notifier.updateGoalReminder(val),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // SECTION 4: ACCOUNT MANAGEMENT
          _buildHeader('Account Actions', theme),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.lock_outline_rounded, color: Colors.blue),
                  title: const Text('Change Password'),
                  onTap: () => _changePassword(context),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.logout_rounded, color: Colors.orange),
                  title: const Text('Sign Out'),
                  onTap: () async {
                    await ref.read(authServiceProvider).signOut();
                    ref.invalidate(authStateProvider);
                    ref.invalidate(userProfileProvider);
                    ref.invalidate(profileProvider);
                    if (context.mounted) {
                      context.go('/login');
                    }
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.delete_forever_rounded, color: Colors.red),
                  title: const Text('Delete Account'),
                  onTap: () => _deleteAccount(context, ref),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // SECTION 5: ABOUT
          _buildHeader('About FitTrack', theme),
          Card(
            child: Column(
              children: [
                const ListTile(
                  title: Text('App Version'),
                  trailing: Text('1.0.0 (build 1)', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                const Divider(height: 1),
                ListTile(
                  title: const Text('Privacy Policy'),
                  onTap: () => _showPlaceholderDialog(
                    context,
                    'Privacy Policy',
                    'FitTrack is committed to protecting your privacy. Your workout data, profile metrics, and photos are stored securely using Supabase services and are only used locally to calculate fitness statistics and trigger local device reminders. No health data is sold or shared with third parties.',
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  title: const Text('Terms of Service'),
                  onTap: () => _showPlaceholderDialog(
                    context,
                    'Terms of Service',
                    'By using FitTrack, you agree that your fitness activities are logged at your own risk. Consult a physician before beginning any training program. All uploaded media must comply with storage policies.',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildHeader(String title, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(left: 4.0, bottom: 8.0),
      child: Text(
        title,
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }
}
