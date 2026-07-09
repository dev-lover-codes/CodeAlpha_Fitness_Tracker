import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fit_track/core/providers/auth_provider.dart';
import 'package:fit_track/core/providers/profile_provider.dart';
import 'package:fit_track/core/providers/workouts_provider.dart';
import 'package:fit_track/core/providers/repository_providers.dart';

final avatarBytesProvider = FutureProvider.family<Uint8List, String>((ref, path) async {
  final supabase = Supabase.instance.client;
  return await supabase.storage.from('avatars').download(path);
});

class ProfileView extends ConsumerWidget {
  const ProfileView({super.key});

  Future<void> _uploadAvatar(BuildContext context, WidgetRef ref) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (picked == null) return;

    final currentUser = ref.read(authServiceProvider).currentUser;
    if (currentUser == null) return;

    final file = File(picked.path);
    final supabase = Supabase.instance.client;
    final userId = currentUser.id;
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final storagePath = '$userId/avatar_$timestamp.jpg';

    if (!context.mounted) return;

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // Ensure avatars bucket exists
      try {
        await supabase.storage.createBucket('avatars');
      } catch (_) {}

      // Upload file
      await supabase.storage.from('avatars').upload(
        storagePath,
        file,
        fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
      );

      // Update user profile record
      final profile = ref.read(profileProvider).value;
      if (profile != null) {
        final updated = profile.copyWith(
          avatarUrl: storagePath,
          updatedAt: DateTime.now(),
        );
        await ref.read(profileRepositoryProvider).updateProfile(updated);
        ref.invalidate(profileProvider);

        if (context.mounted) {
          Navigator.pop(context); // Close loading dialog
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Avatar updated successfully!'), backgroundColor: Colors.green),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload avatar: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);
    final streakAsync = ref.watch(streakProvider);
    final workoutsAsync = ref.watch(userWorkoutsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_rounded),
            tooltip: 'App Settings',
            onPressed: () => context.go('/settings'),
          ),
        ],
      ),
      body: profileAsync.when(
        data: (profile) {
          if (profile == null) {
            return const Center(child: Text('No profile data found.'));
          }

          final workouts = workoutsAsync.value ?? [];
          final streak = streakAsync.value;
          final streakCount = streak?.currentStreak ?? 0;
          final memberSince = DateFormat('MMMM yyyy').format(profile.createdAt);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Profile Avatar & Identity Card
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
                    child: Column(
                      children: [
                        // Tap-to-change avatar container
                        GestureDetector(
                          onTap: () => _uploadAvatar(context, ref),
                          child: Stack(
                            alignment: Alignment.bottomRight,
                            children: [
                              CircleAvatar(
                                radius: 54,
                                backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                                child: ClipOval(
                                  child: profile.avatarUrl != null && profile.avatarUrl!.isNotEmpty
                                      ? _AvatarImage(storagePath: profile.avatarUrl!)
                                      : Center(
                                          child: Text(
                                            (profile.fullName ?? profile.username ?? 'U').substring(0, 1).toUpperCase(),
                                            style: TextStyle(
                                              fontSize: 40,
                                              fontWeight: FontWeight.bold,
                                              color: theme.colorScheme.primary,
                                            ),
                                          ),
                                        ),
                                ),
                              ),
                              CircleAvatar(
                                radius: 18,
                                backgroundColor: theme.colorScheme.primary,
                                child: const Icon(Icons.camera_alt_rounded, size: 18, color: Colors.black),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          profile.fullName ?? 'Set Full Name',
                          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                        Text(
                          '@${profile.username ?? 'user'}',
                          style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[500]),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Stats Dashboard Section
                Text(
                  'Key Statistics',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildStatCard(
                      label: 'Total Workouts',
                      value: '${workouts.length}',
                      icon: Icons.fitness_center_rounded,
                      color: theme.colorScheme.primary,
                      theme: theme,
                    ),
                    const SizedBox(width: 12),
                    _buildStatCard(
                      label: 'Active Streak',
                      value: '$streakCount Days',
                      icon: Icons.local_fire_department_rounded,
                      color: Colors.orange,
                      theme: theme,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today_rounded, color: theme.colorScheme.secondary, size: 24),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Member Since',
                              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                            ),
                            Text(
                              memberSince,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Actions Section
                ElevatedButton.icon(
                  onPressed: () => context.go('/profile/edit'),
                  icon: const Icon(Icons.edit_rounded, color: Colors.black),
                  label: const Text('Edit Profile & Goals', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    minimumSize: const Size(double.infinity, 54),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error loading profile: $e')),
      ),
    );
  }

  Widget _buildStatCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    required ThemeData theme,
  }) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 12),
              Text(
                value,
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20),
              ),
              Text(
                label,
                style: TextStyle(fontSize: 11, color: Colors.grey[500]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AvatarImage extends ConsumerWidget {
  final String storagePath;

  const _AvatarImage({required this.storagePath});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bytesAsync = ref.watch(avatarBytesProvider(storagePath));

    return bytesAsync.when(
      data: (bytes) => Image.memory(
        bytes,
        width: 108,
        height: 108,
        fit: BoxFit.cover,
      ),
      loading: () => const Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))),
      error: (_, __) => const Icon(Icons.broken_image_rounded, size: 36, color: Colors.grey),
    );
  }
}
