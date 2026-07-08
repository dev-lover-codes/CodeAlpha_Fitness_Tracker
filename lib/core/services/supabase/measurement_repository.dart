import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/body_measurement.dart';
import '../../models/progress_photo.dart';
import '../../utils/app_exception.dart';

class MeasurementRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Fetches all body measurements for a user, sorted by date.
  Future<List<BodyMeasurement>> getBodyMeasurements(String userId) async {
    try {
      final List<dynamic> data = await _supabase
          .from('body_measurements')
          .select()
          .eq('user_id', userId)
          .order('logged_at', ascending: false);
      return data.map((json) => BodyMeasurement.fromJson(json as Map<String, dynamic>)).toList();
    } catch (e) {
      throw AppException("Failed to load body measurements: ${e.toString()}", e);
    }
  }

  /// Logs a new body measurement.
  Future<BodyMeasurement> createBodyMeasurement(BodyMeasurement measurement) async {
    try {
      final jsonMap = measurement.toJson();
      if (measurement.id.isEmpty || measurement.id.startsWith('temp_') || measurement.id.length < 36) {
        jsonMap.remove('id');
      }

      final data = await _supabase
          .from('body_measurements')
          .insert(jsonMap)
          .select()
          .single();
      return BodyMeasurement.fromJson(data);
    } catch (e) {
      throw AppException("Failed to log body measurement: ${e.toString()}", e);
    }
  }

  /// Deletes a body measurement.
  Future<void> deleteBodyMeasurement(String id) async {
    try {
      await _supabase.from('body_measurements').delete().eq('id', id);
    } catch (e) {
      throw AppException("Failed to delete body measurement: ${e.toString()}", e);
    }
  }

  /// Fetches a user's progress photo uploads.
  Future<List<ProgressPhoto>> getProgressPhotos(String userId) async {
    try {
      final List<dynamic> data = await _supabase
          .from('progress_photos')
          .select()
          .eq('user_id', userId)
          .order('logged_at', ascending: false);
      return data.map((json) => ProgressPhoto.fromJson(json as Map<String, dynamic>)).toList();
    } catch (e) {
      throw AppException("Failed to load progress photos list: ${e.toString()}", e);
    }
  }

  /// Logs a new progress photo.
  Future<ProgressPhoto> createProgressPhoto(ProgressPhoto photo) async {
    try {
      final jsonMap = photo.toJson();
      if (photo.id.isEmpty || photo.id.startsWith('temp_') || photo.id.length < 36) {
        jsonMap.remove('id');
      }

      final data = await _supabase
          .from('progress_photos')
          .insert(jsonMap)
          .select()
          .single();
      return ProgressPhoto.fromJson(data);
    } catch (e) {
      throw AppException("Failed to save progress photo: ${e.toString()}", e);
    }
  }

  /// Deletes a progress photo.
  Future<void> deleteProgressPhoto(String id) async {
    try {
      await _supabase.from('progress_photos').delete().eq('id', id);
    } catch (e) {
      throw AppException("Failed to delete progress photo: ${e.toString()}", e);
    }
  }
}
