import 'dart:io';

void main() {
  final file = File('lib/core/services/notification_service.dart');
  var content = file.readAsStringSync();
  
  // Fix _plugin.initialize
  content = content.replaceAll(
    'await _plugin.initialize(initSettings);',
    'await _plugin.initialize(initializationSettings: initSettings);'
  );
  
  // Fix _plugin.cancel
  content = content.replaceAll(
    'await _plugin.cancel(id);',
    'await _plugin.cancel(id: id);'
  );
  
  // Fix _plugin.zonedSchedule
  content = content.replaceAll(
    "await _plugin.zonedSchedule(\n        notificationId,\n        'Time to Workout! 🏋️',\n        'Keep up the consistency and log your workout session today.',\n        tzScheduled,\n        details,\n        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,\n        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,\n        matchDateTimeComponents: DateTimeComponents.time,\n      );",
    """await _plugin.zonedSchedule(
        id: notificationId,
        title: 'Time to Workout! 🏋️',
        body: 'Keep up the consistency and log your workout session today.',
        scheduledDate: tzScheduled,
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );"""
  );
  
  content = content.replaceAll(
    "await _plugin.zonedSchedule(\n        notificationId,\n        'Streak at Risk! 🔥',\n        'You have an active streak of \$streak! Log a workout to keep it alive.',\n        tzScheduled,\n        details,\n        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,\n        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,\n      );",
    """await _plugin.zonedSchedule(
        id: notificationId,
        title: 'Streak at Risk! 🔥',
        body: 'You have an active streak of \$streak! Log a workout to keep it alive.',
        scheduledDate: tzScheduled,
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );"""
  );
  
  content = content.replaceAll(
    "await _plugin.zonedSchedule(\n          notificationId,\n          'Goal Deadline Approaching!',\n          'Your goal \"\${goal.goalType}\" is due in 3 days. Let\\'s make a final push!',\n          tzScheduled,\n          details,\n          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,\n          uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,\n        );",
    """await _plugin.zonedSchedule(
          id: notificationId,
          title: 'Goal Deadline Approaching!',
          body: 'Your goal "\${goal.goalType}" is due in 3 days. Let\\'s make a final push!',
          scheduledDate: tzScheduled,
          notificationDetails: details,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        );"""
  );
  
  file.writeAsStringSync(content);
}
