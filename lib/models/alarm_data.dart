import 'package:flutter/foundation.dart';

/// Enum to define different types of videos that can be used for alarms
enum VideoType {
  /// YouTube videos
  youtube,

  /// Local videos stored on the device
  local,

  /// External videos from a URL
  external
}

/// Class to hold all data related to an alarm
class AlarmData {
  /// Unique identifier for the alarm
  final int id;

  /// Time when the alarm should trigger
  final DateTime time;

  /// Type of video (YouTube, local, or external)
  final VideoType videoType;

  /// URL or path to the video
  final String videoUrl;

  /// Whether the user has premium features
  final bool isPremiumUser;

  /// Optional title for the alarm
  final String? title;

  /// Optional days of the week for repeating alarms (0 = Sunday, 6 = Saturday)
  final List<int>? repeatDays;

  /// Whether the alarm is active
  final bool isEnabled;

  /// Constructor for AlarmData
  AlarmData({
    required this.id,
    required this.time,
    required this.videoType,
    required this.videoUrl,
    this.isPremiumUser = false,
    this.title,
    this.repeatDays,
    this.isEnabled = true,
  });

  /// Create a copy of this AlarmData with some fields replaced
  AlarmData copyWith({
    int? id,
    DateTime? time,
    VideoType? videoType,
    String? videoUrl,
    bool? isPremiumUser,
    String? title,
    List<int>? repeatDays,
    bool? isEnabled,
  }) {
    return AlarmData(
      id: id ?? this.id,
      time: time ?? this.time,
      videoType: videoType ?? this.videoType,
      videoUrl: videoUrl ?? this.videoUrl,
      isPremiumUser: isPremiumUser ?? this.isPremiumUser,
      title: title ?? this.title,
      repeatDays: repeatDays ?? this.repeatDays,
      isEnabled: isEnabled ?? this.isEnabled,
    );
  }

  /// Convert AlarmData to a Map for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'time': time.toIso8601String(),
      'videoType': videoType.index,
      'videoUrl': videoUrl,
      'isPremiumUser': isPremiumUser,
      'title': title,
      'repeatDays': repeatDays,
      'isEnabled': isEnabled,
    };
  }

  /// Create AlarmData from a stored Map
  factory AlarmData.fromJson(Map<String, dynamic> json) {
    return AlarmData(
      id: json['id'] as int,
      time: DateTime.parse(json['time'] as String),
      videoType: VideoType.values[json['videoType'] as int],
      videoUrl: json['videoUrl'] as String,
      isPremiumUser: json['isPremiumUser'] as bool,
      title: json['title'] as String?,
      repeatDays: json['repeatDays'] != null
          ? List<int>.from(json['repeatDays'] as List)
          : null,
      isEnabled: json['isEnabled'] as bool? ?? true,
    );
  }

  @override
  String toString() {
    return 'AlarmData{id: $id, time: $time, videoType: $videoType, title: $title}';
  }
}
