import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fit_track/core/models/body_measurement.dart';
import 'package:fit_track/core/models/progress_photo.dart';
import 'package:fit_track/core/providers/repository_providers.dart';
import 'package:fit_track/core/providers/auth_provider.dart';
import 'package:fit_track/core/providers/goals_provider.dart';

/// Provider for body measurements list.
final bodyMeasurementsProvider = AsyncNotifierProvider<BodyMeasurementsNotifier, List<BodyMeasurement>>(() {
  return BodyMeasurementsNotifier();
});

class BodyMeasurementsNotifier extends AsyncNotifier<List<BodyMeasurement>> {
  @override
  Future<List<BodyMeasurement>> build() async {
    ref.watch(authStateProvider);
    final currentUser = ref.read(authServiceProvider).currentUser;
    if (currentUser == null) return const [];
    final repo = ref.read(measurementRepositoryProvider);
    return await repo.getBodyMeasurements(currentUser.id);
  }

  Future<void> addMeasurement(BodyMeasurement measurement) async {
    final repo = ref.read(measurementRepositoryProvider);
    await repo.createBodyMeasurement(measurement);
    ref.invalidateSelf();

    // Auto-update weight goals
    if (measurement.weightKg != null) {
      await ref.read(goalsProvider.notifier).autoUpdateWeightGoals(measurement.weightKg!);
    }
  }

  Future<void> deleteMeasurement(String id) async {
    final repo = ref.read(measurementRepositoryProvider);
    await repo.deleteBodyMeasurement(id);
    ref.invalidateSelf();
  }
}

/// Provider for progress photos list.
final progressPhotosProvider = AsyncNotifierProvider<ProgressPhotosNotifier, List<ProgressPhoto>>(() {
  return ProgressPhotosNotifier();
});

class ProgressPhotosNotifier extends AsyncNotifier<List<ProgressPhoto>> {
  final SupabaseClient _supabase = Supabase.instance.client;

  @override
  Future<List<ProgressPhoto>> build() async {
    ref.watch(authStateProvider);
    final currentUser = ref.read(authServiceProvider).currentUser;
    if (currentUser == null) return const [];
    final repo = ref.read(measurementRepositoryProvider);
    return await repo.getProgressPhotos(currentUser.id);
  }

  Future<void> uploadPhoto(File file, String? notes) async {
    final currentUser = ref.read(authServiceProvider).currentUser;
    if (currentUser == null) return;
    
    final repo = ref.read(measurementRepositoryProvider);
    
    // Generate unique name matching RLS: userId/uuid.jpg
    final String extension = file.path.split('.').last.toLowerCase();
    final String fileName = '${DateTime.now().millisecondsSinceEpoch}_${DateTime.now().microsecondsSinceEpoch}.$extension';
    final String storagePath = '${currentUser.id}/$fileName';

    // 1. Upload to Supabase Storage
    await _supabase.storage.from('progress-photos').upload(
      storagePath,
      file,
      fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
    );

    // 2. Insert record in progress_photos table
    final progressPhoto = ProgressPhoto(
      id: '',
      userId: currentUser.id,
      photoUrl: storagePath, // Save storage path as URL
      loggedAt: DateTime.now(),
      notes: notes,
    );

    await repo.createProgressPhoto(progressPhoto);
    ref.invalidateSelf();
  }

  Future<void> deletePhoto(ProgressPhoto photo) async {
    final repo = ref.read(measurementRepositoryProvider);
    
    // 1. Delete from database
    await repo.deleteProgressPhoto(photo.id);

    // 2. Delete from storage
    try {
      await _supabase.storage.from('progress-photos').remove([photo.photoUrl]);
    } catch (_) {
      // Ignore storage deletion errors to avoid breaking DB sync
    }

    ref.invalidateSelf();
  }
}
