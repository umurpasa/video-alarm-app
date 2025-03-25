import 'package:flutter/material.dart';
import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:video_alarm_app/models/alarm_data.dart';
import 'package:video_alarm_app/services/media_handler.dart';
// Import your alarm manager service
import 'package:video_alarm_app/services/alarm_manager.dart'; // Add this import

class AlarmRingingScreen extends StatefulWidget {
  final AlarmData alarm;

  const AlarmRingingScreen({Key? key, required this.alarm}) : super(key: key);

  @override
  _AlarmRingingScreenState createState() => _AlarmRingingScreenState();
}

class _AlarmRingingScreenState extends State<AlarmRingingScreen> {
  late AudioHandler _audioHandler;

  @override
  void initState() {
    super.initState();
    // Initialize the audio handler
    _initAudioHandler();
    // Start playing the appropriate audio
    MediaHandler.playAlarmAudio(widget.alarm);
  }

  Future<void> _initAudioHandler() async {
    _audioHandler = await AudioService.init(
      builder: () => AudioPlayerHandler(),
      config: AudioServiceConfig(
        androidNotificationChannelId:
            'com.yourdomain.videoalarmapp.channel.audio',
        androidNotificationChannelName: 'Video Alarm App',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Time display
            Text(
              TimeOfDay.fromDateTime(DateTime.now()).format(context),
              style: TextStyle(
                fontSize: 60,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),

            SizedBox(height: 40),

            // Alarm title
            Text(
              'WAKE UP!',
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
                letterSpacing: 2.0,
              ),
            ),

            SizedBox(height: 60),

            // Video preview thumbnail (could be implemented)
            Container(
              width: 200,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.videocam,
                size: 50,
                color: Colors.white,
              ),
            ),

            SizedBox(height: 60),

            // Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Snooze button
                ElevatedButton(
                  onPressed: () {
                    // Implementation for snooze functionality
                    // Stop current alarm
                    _audioHandler
                        .stop(); // Using the audio handler instead of deprecated method

                    // Schedule a new alarm 5 minutes from now
                    final snoozeTime = DateTime.now().add(Duration(minutes: 5));
                    final snoozeAlarm = AlarmData(
                      id: widget.alarm.id + 1,
                      time: snoozeTime,
                      videoType: widget.alarm.videoType,
                      videoUrl: widget.alarm.videoUrl,
                      isPremiumUser: widget.alarm.isPremiumUser,
                    );

                    // Use AlarmManager from the imported service
                    AlarmManager.scheduleAlarm(snoozeAlarm);

                    // Close the alarm screen
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[700],
                    padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: Text(
                    'SNOOZE',
                    style: TextStyle(fontSize: 16),
                  ),
                ),

                // Play video button
                ElevatedButton(
                  onPressed: () {
                    // Stop alarm sound
                    _audioHandler
                        .stop(); // Using the audio handler instead of deprecated method

                    // Launch video player
                    MediaHandler.launchVideo(context, widget.alarm);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: Text(
                    'PLAY VIDEO',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),

            SizedBox(height: 20),

            // Dismiss button
            TextButton(
              onPressed: () {
                // Stop alarm sound
                _audioHandler
                    .stop(); // Using the audio handler instead of deprecated method

                // Close the alarm screen
                Navigator.pop(context);
              },
              child: Text(
                'Dismiss',
                style: TextStyle(
                  color: Colors.white60,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    // Make sure to stop any playing audio when screen is dismissed
    _audioHandler
        .stop(); // Using the audio handler instead of deprecated method
    super.dispose();
  }
}

// Simple implementation of AudioHandler - you might want to move this to a separate file
class AudioPlayerHandler extends BaseAudioHandler {
  final _player = AudioPlayer();

  AudioPlayerHandler() {
    _player.playbackEventStream.map(_transformEvent).pipe(playbackState);
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
