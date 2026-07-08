import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/fitness_activity.dart';

/// Local Storage Service to handle saving and loading fitness activities using SharedPreferences.
class LocalStorageService {
  static const String _prefsKey = 'fitness_activities_local_store';

  /// Save a fitness activity locally.
  Future<void> addActivity(FitnessActivity activity) async {
    final prefs = await SharedPreferences.getInstance();
    final list = await loadAllActivities();

    final index = list.indexWhere((item) => item.id == activity.id);
    if (index >= 0) {
      list[index] = activity;
    } else {
      list.add(activity);
    }

    await _persistList(prefs, list);
  }

  /// Fetch activities logged on a specific day.
  Future<List<FitnessActivity>> fetchActivitiesForDay(DateTime date) async {
    final start = DateTime(date.year, date.month, date.day);
    final end = DateTime(date.year, date.month, date.day, 23, 59, 59, 999);

    final all = await loadAllActivities();
    final filtered = all.where((activity) {
      return activity.timestamp.isAfter(
            start.subtract(const Duration(milliseconds: 1)),
          ) &&
          activity.timestamp.isBefore(end.add(const Duration(milliseconds: 1)));
    }).toList();

    filtered.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return filtered;
  }

  /// Fetch activities logged in the past 7 days (weekly progress).
  Future<List<FitnessActivity>> fetchActivitiesForPast7Days(
    DateTime date,
  ) async {
    final sevenDaysAgo = date.subtract(const Duration(days: 6));
    final start = DateTime(
      sevenDaysAgo.year,
      sevenDaysAgo.month,
      sevenDaysAgo.day,
    );
    final end = DateTime(date.year, date.month, date.day, 23, 59, 59, 999);

    final all = await loadAllActivities();
    final filtered = all.where((activity) {
      return activity.timestamp.isAfter(
            start.subtract(const Duration(milliseconds: 1)),
          ) &&
          activity.timestamp.isBefore(end.add(const Duration(milliseconds: 1)));
    }).toList();

    filtered.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return filtered;
  }

  /// Delete an activity.
  Future<void> deleteActivity(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final list = await loadAllActivities();
    list.removeWhere((item) => item.id == id);
    await _persistList(prefs, list);
  }

  /// Load all activities from SharedPreferences. Seeding dummy data if empty.
  Future<List<FitnessActivity>> loadAllActivities() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? jsonString = prefs.getString(_prefsKey);

      if (jsonString == null || jsonString.isEmpty) {
        final dummyData = _getDummyActivities();
        await _persistList(prefs, dummyData);
        return dummyData;
      }

      final List<dynamic> decoded = json.decode(jsonString);
      return decoded.map((item) {
        final Map<String, dynamic> map = Map<String, dynamic>.from(item);
        return FitnessActivity.fromMap(map, map['id']);
      }).toList();
    } catch (e) {
      debugPrint("LocalStorageService: Error loading activities: $e");
      return [];
    }
  }

  /// Persist the list to SharedPreferences.
  Future<void> _persistList(
    SharedPreferences prefs,
    List<FitnessActivity> list,
  ) async {
    final List<Map<String, dynamic>> mappedList = list
        .map((item) => item.toMap())
        .toList();
    await prefs.setString(_prefsKey, json.encode(mappedList));
  }

  /// Seeding initial mock data on first launch.
  List<FitnessActivity> _getDummyActivities() {
    final now = DateTime.now();
    return [
      FitnessActivity(
        id: 'dummy_1',
        type: 'Running',
        durationInMinutes: 30,
        caloriesBurned: 350,
        timestamp: now.subtract(const Duration(hours: 2)),
      ),
      FitnessActivity(
        id: 'dummy_2',
        type: 'Yoga',
        durationInMinutes: 45,
        caloriesBurned: 180,
        timestamp: now.subtract(const Duration(hours: 5)),
      ),
      FitnessActivity(
        id: 'dummy_3',
        type: 'Cycling',
        durationInMinutes: 50,
        caloriesBurned: 450,
        timestamp: now.subtract(const Duration(days: 1, hours: 3)),
      ),
      FitnessActivity(
        id: 'dummy_4',
        type: 'Gym',
        durationInMinutes: 60,
        caloriesBurned: 520,
        timestamp: now.subtract(const Duration(days: 2, hours: 1)),
      ),
      FitnessActivity(
        id: 'dummy_5',
        type: 'Walking',
        durationInMinutes: 20,
        caloriesBurned: 100,
        timestamp: now.subtract(const Duration(days: 3, hours: 4)),
      ),
      FitnessActivity(
        id: 'dummy_6',
        type: 'Running',
        durationInMinutes: 40,
        caloriesBurned: 420,
        timestamp: now.subtract(const Duration(days: 4, hours: 2)),
      ),
      FitnessActivity(
        id: 'dummy_7',
        type: 'Gym',
        durationInMinutes: 75,
        caloriesBurned: 600,
        timestamp: now.subtract(const Duration(days: 5, hours: 6)),
      ),
      FitnessActivity(
        id: 'dummy_8',
        type: 'Cycling',
        durationInMinutes: 35,
        caloriesBurned: 320,
        timestamp: now.subtract(const Duration(days: 6, hours: 1)),
      ),
    ];
  }
}
