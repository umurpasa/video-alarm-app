import 'dart:io';
import 'package:flutter/material.dart';
import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:video_alarm_app/models/alarm_data.dart'; // Import the AlarmData model

// YouTubePlayerScreen component is now imported from video_player_screen.dart
// VideoPlayerScreen component is now imported from video_player_screen.dart
// Import these screens from their respective files

class MediaHandler {
  static Future<void> playAlarmAudio(AlarmData alarmData) async {
    try {
      if (alarmData.videoType == VideoType.youtube) {
        if (alarmData.isPremiumUser) {
          // For YouTube Premium users, try to play audio in background
          // Note: This can only work if user has YouTube Premium
          await AudioService.init(
            builder: () => AudioPlayerTask(),
            config: AudioServiceConfig(
              androidNotificationChannelName: 'Alarm Service',
              androidNotificationIcon: 'mipmap/ic_launcher',
            ),
          );

          final audioHandler = await AudioService.init(
            builder: () => AudioPlayerTask(),
            config: AudioServiceConfig(
              androidNotificationChannelName: 'Alarm Service',
              androidNotificationIcon: 'mipmap/ic_launcher',
            ),
          );

          await audioHandler.customAction('play', {
            'url': _extractYouTubeAudioUrl(alarmData.videoUrl),
            'isYouTube': true
          });
        } else {
          // For non-premium users, play default alarm sound
          await _playDefaultAlarm();
        }
      } else {
        // For local/external videos, always play default alarm when locked
        await _playDefaultAlarm();
      }
    } catch (e) {
      // Fallback to default alarm on any error
      await _playDefaultAlarm();
    }
  }

  static Future<void> _playDefaultAlarm() async {
    final player = AudioPlayer();
    await player.setAsset('assets/audio/default_alarm.mp3');
    await player.play();
  }

  static String _extractYouTubeAudioUrl(String youtubeUrl) {
    // In a real app, you would use a more sophisticated method
    // This is simplified for demonstration
    final videoId = YoutubePlayer.convertUrlToId(youtubeUrl);
    return 'https://youtubeaudio.example.com/$videoId'; // Placeholder
  }

  // Launch video player when phone is unlocked
  static Future<void> launchVideo(
      BuildContext context, AlarmData alarmData) async {
    // Stop background audio first
    final audioHandler = await AudioService.init(
      builder: () => AudioPlayerTask(),
      config: AudioServiceConfig(
        androidNotificationChannelName: 'Alarm Service',
        androidNotificationIcon: 'mipmap/ic_launcher',
      ),
    );

    await audioHandler.stop();

    if (alarmData.videoType == VideoType.youtube) {
      final videoId = YoutubePlayer.convertUrlToId(alarmData.videoUrl) ?? '';
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => YouTubePlayerScreen(videoId: videoId),
        ),
      );
    } else {
      // Handle local or external video
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => VideoPlayerScreen(
            videoPath: alarmData.videoUrl,
            isLocal: alarmData.videoType == VideoType.local,
          ),
        ),
      );
    }
  }
}

// Audio handler to replace the deprecated BackgroundAudioTask
class AudioPlayerTask extends BaseAudioHandler {
  final _player = AudioPlayer();

  AudioPlayerTask() {
    _player.playbackEventStream.map(_transformEvent).pipe(playbackState);
  }

  @override
  Future<dynamic> customAction(String name,
      [Map<String, dynamic>? extras]) async {
    if (name == 'play' && extras != null) {
      final url = extras['url'] as String;
      final isYouTube = extras['isYouTube'] as bool;

      try {
        if (isYouTube) {
          // Attempt to play YouTube audio (requires Premium)
          await _player.setUrl(url);
        } else {
          await _player.setUrl(url);
        }
        await _player.play();
      } catch (e) {
        // Fallback to default alarm
        await _player.setAsset('assets/audio/default_alarm.mp3');
        await _player.play();
      }
    }
    return super.customAction(name, extras);
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> stop() => _player.stop();

  PlaybackState _transformEvent(PlaybackEvent event) {
    return PlaybackState(
      controls: [
        MediaControl.stop,
      ],
      androidCompactActionIndices: const [0],
      processingState: const {
        ProcessingState.idle: AudioProcessingState.idle,
        ProcessingState.loading: AudioProcessingState.loading,
        ProcessingState.buffering: AudioProcessingState.buffering,
        ProcessingState.ready: AudioProcessingState.ready,
        ProcessingState.completed: AudioProcessingState.completed,
      }[_player.processingState]!,
      playing: _player.playing,
      updatePosition: _player.position,
      bufferedPosition: _player.bufferedPosition,
      speed: _player.speed,
      queueIndex: event.currentIndex,
    );
  }
}
