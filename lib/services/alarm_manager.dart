import 'package:flutter/material.dart';
import 'package:video_alarm_app/models/alarm_data.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'dart:isolate';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// A service to manage scheduling and triggering alarms
class AlarmManager {
  // Name for the isolate port
  static const String _isolatePortName = 'alarm_isolate';

  /// Initialize the alarm manager service
  static Future<void> initialize() async {
    await AndroidAlarmManager.initialize();
  }

  /// Schedule an alarm to trigger at the specified time
  static Future<bool> scheduleAlarm(AlarmData alarm) async {
    // First save the alarm data to shared preferences so we can access it when the alarm triggers
    await _saveAlarmData(alarm);
    await saveAlarmData(alarm);

    // Schedule the alarm to trigger at the specified time
    return await AndroidAlarmManager.oneShotAt(
      alarm.time,
      alarm.id,
      _alarmCallback,
      exact: true,
      wakeup: true,
      rescheduleOnReboot: true,
    );
  }

  /// Cancel a scheduled alarm
  static Future<bool> cancelAlarm(int alarmId) async {
    return await AndroidAlarmManager.cancel(alarmId);
  }

  /// Save alarm data to shared preferences
  static Future<void> _saveAlarmData(AlarmData alarm) async {
    final prefs = await SharedPreferences.getInstance();
    final alarmJson = jsonEncode(alarm.toJson());
    await prefs.setString('alarm_${alarm.id}', alarmJson);
  }

  /// Get alarm data from shared preferences
  static Future<AlarmData?> getAlarmData(int alarmId) async {
    final prefs = await SharedPreferences.getInstance();
    final alarmJson = prefs.getString('alarm_${alarmId}');

    if (alarmJson != null) {
      final Map<String, dynamic> alarmMap = jsonDecode(alarmJson);
      return AlarmData.fromJson(alarmMap);
    }

    return null;
  }

  /// Callback function triggered when an alarm goes off
  @pragma(
      'vm:entry-point') // Needed for Flutter 3.0+ to ensure this method isn't tree-shaken
  static Future<void> _alarmCallback(int alarmId) async {
    // This runs in a separate isolate
    final SendPort? sendPort = ReceivePort().sendPort;

    try {
      // Use the services binding to interact with platform channels
      WidgetsFlutterBinding.ensureInitialized();

      // Look up the send port
      final SendPort? isolateSendPort =
          IsolateNameServer.lookupPortByName(_isolatePortName);

      if (isolateSendPort != null) {
        // Send the alarm ID to the main isolate
        isolateSendPort.send(alarmId);
      }
    } catch (e) {
      print('Error in alarm callback: $e');
    }
  }

  /// Register the alarm callback port to communicate between isolates
  static void registerAlarmCallbackPort(Function(int) callback) {
    // Create a receive port for handling messages from the alarm isolate
    final receivePort = ReceivePort();

    // Unregister any existing port with this name first
    IsolateNameServer.removePortNameMapping(_isolatePortName);

    // Register the port
    IsolateNameServer.registerPortWithName(
      receivePort.sendPort,
      _isolatePortName,
    );

    // Listen for alarm triggers
    receivePort.listen((message) {
      if (message is int) {
        callback(message);
      }
    });
  }

  static Future<List<AlarmData>> getAllAlarms() async {
    final prefs = await SharedPreferences.getInstance();
    final alarmStrings = prefs.getStringList('alarms') ?? [];

    return alarmStrings
        .map((string) => AlarmData.fromJson(jsonDecode(string)))
        .toList();
  }

  static Future<void> deleteAlarm(int id) async {
    final prefs = await SharedPreferences.getInstance();
    final alarms = await getAllAlarms();

    alarms.removeWhere((alarm) => alarm.id == id);
    await prefs.setStringList(
      'alarms',
      alarms.map((a) => jsonEncode(a.toJson())).toList(),
    );
  }

  static Future<void> saveAlarmData(AlarmData alarm) async {
    final prefs = await SharedPreferences.getInstance();
    final alarms = await getAllAlarms();

    final index = alarms.indexWhere((a) => a.id == alarm.id);
    if (index >= 0) {
      alarms[index] = alarm;
    } else {
      alarms.add(alarm);
    }

    await prefs.setStringList(
      'alarms',
      alarms.map((a) => jsonEncode(a.toJson())).toList(),
    );
  }
}
