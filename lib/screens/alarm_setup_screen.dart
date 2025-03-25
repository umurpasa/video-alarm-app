import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:video_alarm_app/models/alarm_data.dart';
import 'package:video_alarm_app/services/alarm_manager.dart';
import 'package:video_alarm_app/screens/video_player_screen.dart';

class AlarmSetupScreen extends StatefulWidget {
  @override
  _AlarmSetupScreenState createState() => _AlarmSetupScreenState();
}

class _AlarmSetupScreenState extends State<AlarmSetupScreen> {
  TimeOfDay _selectedTime = TimeOfDay.now();
  VideoType _selectedVideoType = VideoType.youtube;
  String _videoUrl = '';
  bool _isPremiumUser = false;
  bool _isPreviewAvailable = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Set Video Alarm'),
        backgroundColor: Colors.deepPurple,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Time picker card
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Alarm Time',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 16),
                    InkWell(
                      onTap: _selectTime,
                      child: Container(
                        padding:
                            EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                        decoration: BoxDecoration(
                          color: Colors.deepPurple.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _selectedTime.format(context),
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Icon(Icons.access_time, size: 32),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 20),

            // Video source selection
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Video Source',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),

                    // YouTube option
                    _buildVideoTypeOption(
                      type: VideoType.youtube,
                      title: 'YouTube Video',
                      icon: Icons.play_circle_fill,
                      color: Colors.red,
                    ),

                    // Local video option
                    _buildVideoTypeOption(
                      type: VideoType.local,
                      title: 'Local Video',
                      icon: Icons.video_file,
                      color: Colors.blue,
                    ),

                    // External URL option
                    _buildVideoTypeOption(
                      type: VideoType.external,
                      title: 'External Video URL',
                      icon: Icons.link,
                      color: Colors.green,
                    ),

                    // YouTube Premium checkbox (only for YouTube)
                    if (_selectedVideoType == VideoType.youtube)
                      Padding(
                        padding: const EdgeInsets.only(top: 16.0),
                        child: CheckboxListTile(
                          title: Text('I have YouTube Premium'),
                          subtitle: Text(
                            'Required for background audio playback from YouTube',
                            style: TextStyle(fontSize: 12),
                          ),
                          value: _isPremiumUser,
                          activeColor: Colors.deepPurple,
                          onChanged: (bool? value) {
                            setState(() {
                              _isPremiumUser = value ?? false;
                            });
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 20),

            // Video selection input
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Select Video',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 16),

                    // Different input based on video type
                    if (_selectedVideoType == VideoType.youtube)
                      TextField(
                        decoration: InputDecoration(
                          labelText: 'YouTube URL',
                          hintText: 'https://www.youtube.com/watch?v=...',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.link),
                        ),
                        onChanged: (value) {
                          setState(() {
                            _videoUrl = value;
                            _isPreviewAvailable =
                                YoutubePlayer.convertUrlToId(value) != null;
                          });
                        },
                      )
                    else if (_selectedVideoType == VideoType.local)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ElevatedButton.icon(
                            icon: Icon(Icons.folder_open),
                            label: Text('Choose Video from Device'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              padding: EdgeInsets.symmetric(vertical: 12),
                            ),
                            onPressed: _pickLocalVideo,
                          ),
                          if (_videoUrl.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                'Selected: ${_videoUrl.split('/').last}',
                                style: TextStyle(fontStyle: FontStyle.italic),
                              ),
                            ),
                        ],
                      )
                    else if (_selectedVideoType == VideoType.external)
                      TextField(
                        decoration: InputDecoration(
                          labelText: 'Video URL',
                          hintText: 'https://example.com/video.mp4',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.link),
                        ),
                        onChanged: (value) {
                          setState(() {
                            _videoUrl = value;
                            _isPreviewAvailable = value.isNotEmpty &&
                                (value.endsWith('.mp4') ||
                                    value.endsWith('.mov') ||
                                    value.endsWith('.webm'));
                          });
                        },
                      ),

                    SizedBox(height: 16),

                    // Preview button
                    if (_isPreviewAvailable)
                      ElevatedButton.icon(
                        icon: Icon(Icons.preview),
                        label: Text('Preview Video'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber,
                          padding: EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: _previewVideo,
                      ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 30),

            // Save button
            ElevatedButton(
              onPressed: _videoUrl.isNotEmpty ? _saveAlarm : null,
              child: Text(
                'Save Alarm',
                style: TextStyle(fontSize: 16),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoTypeOption({
    required VideoType type,
    required String title,
    required IconData icon,
    required Color color,
  }) {
    return RadioListTile<VideoType>(
      title: Text(title),
      value: type,
      groupValue: _selectedVideoType,
      activeColor: color,
      secondary: Icon(icon, color: color),
      onChanged: (VideoType? value) {
        setState(() {
          _selectedVideoType = value!;
          _videoUrl = '';
          _isPreviewAvailable = false;
        });
      },
    );
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );

    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Future<void> _pickLocalVideo() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.video,
    );

    if (result != null) {
      setState(() {
        _videoUrl = result.files.single.path!;
        _isPreviewAvailable = true;
      });
    }
  }

  void _previewVideo() {
    if (_selectedVideoType == VideoType.youtube) {
      final videoId = YoutubePlayer.convertUrlToId(_videoUrl) ?? '';
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => YouTubePlayerScreen(videoId: videoId),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => VideoPlayerScreen(
            videoPath: _videoUrl,
            isLocal: _selectedVideoType == VideoType.local,
          ),
        ),
      );
    }
  }

  Future<void> _saveAlarm() async {
    // Get current date for the alarm
    final now = DateTime.now();
    final alarmTime = DateTime(
      now.year,
      now.month,
      now.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    // If time is in the past, set for tomorrow
    final finalAlarmTime =
        alarmTime.isBefore(now) ? alarmTime.add(Duration(days: 1)) : alarmTime;

    // Create alarm data
    final alarm = AlarmData(
      id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
      time: finalAlarmTime,
      videoType: _selectedVideoType,
      videoUrl: _videoUrl,
      isPremiumUser: _isPremiumUser,
    );

    // Schedule the alarm
    await AlarmManager.scheduleAlarm(alarm);

    // Show confirmation
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Alarm set for ${_selectedTime.format(context)}')),
    );

    // Go back to the alarms list
    Navigator.pop(context);
  }
}
