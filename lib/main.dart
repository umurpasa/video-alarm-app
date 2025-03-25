import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize the alarm manager
  await AlarmManager.initialize();

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Video Alarm Clock',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        brightness: Brightness.light,
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        primarySwatch: Colors.deepPurple,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        brightness: Brightness.dark,
        useMaterial3: true,
      ),
      themeMode: ThemeMode.system,
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey, // For handling alarm notifications
      home: AlarmsListScreen(),
    );
  }
}

// List of all alarms
class AlarmsListScreen extends StatefulWidget {
  @override
  _AlarmsListScreenState createState() => _AlarmsListScreenState();
}

class _AlarmsListScreenState extends State<AlarmsListScreen> {
  List<AlarmData> _alarms = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAlarms();
  }

  Future<void> _loadAlarms() async {
    setState(() {
      _isLoading = true;
    });

    final alarms = await AlarmManager.getAllAlarms();

    setState(() {
      _alarms = alarms;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Alarms'),
        elevation: 0,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _alarms.isEmpty
              ? _buildEmptyState()
              : _buildAlarmsList(),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AlarmSetupScreen()),
          );
          // Reload alarms when coming back
          _loadAlarms();
        },
        child: Icon(Icons.add),
        tooltip: 'Add Alarm',
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.alarm_off,
            size: 80,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16),
          Text(
            'No alarms set',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Tap the + button to create an alarm',
            style: TextStyle(
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlarmsList() {
    // Sort alarms by time
    _alarms.sort((a, b) => a.time.compareTo(b.time));

    return ListView.builder(
      padding: EdgeInsets.symmetric(vertical: 8),
      itemCount: _alarms.length,
      itemBuilder: (context, index) {
        final alarm = _alarms[index];
        return _buildAlarmTile(alarm);
      },
    );
  }

  Widget _buildAlarmTile(AlarmData alarm) {
    // Format time
    final timeStr = TimeOfDay.fromDateTime(alarm.time).format(context);

    // Determine video source icon
    IconData videoIcon;
    Color videoColor;
    String videoSource;

    switch (alarm.videoType) {
      case VideoType.youtube:
        videoIcon = Icons.play_circle_fill;
        videoColor = Colors.red;
        videoSource = 'YouTube';
        break;
      case VideoType.local:
        videoIcon = Icons.video_file;
        videoColor = Colors.blue;
        videoSource = 'Local Video';
        break;
      case VideoType.external:
        videoIcon = Icons.link;
        videoColor = Colors.green;
        videoSource = 'External URL';
        break;
    }

    return Dismissible(
      key: Key('alarm-${alarm.id}'),
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: 16),
        child: Icon(
          Icons.delete,
          color: Colors.white,
        ),
      ),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) {
        // Delete the alarm
        AlarmManager.deleteAlarm(alarm.id);

        // Update UI
        setState(() {
          _alarms.remove(alarm);
        });

        // Show snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Alarm deleted'),
            action: SnackBarAction(
              label: 'UNDO',
              onPressed: () async {
                // Re-create the alarm
                await AlarmManager.scheduleAlarm(alarm);
                _loadAlarms();
              },
            ),
          ),
        );
      },
      child: Card(
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        elevation: 2,
        child: ListTile(
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: CircleAvatar(
            radius: 24,
            backgroundColor: Colors.deepPurple.withOpacity(0.2),
            child: Icon(
              Icons.alarm,
              color: Colors.deepPurple,
            ),
          ),
          title: Text(
            timeStr,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: Row(
            children: [
              Icon(
                videoIcon,
                size: 16,
                color: videoColor,
              ),
              SizedBox(width: 4),
              Text(videoSource),
              if (alarm.videoType == VideoType.youtube && alarm.isPremiumUser)
                Row(
                  children: [
                    SizedBox(width: 8),
                    Icon(
                      Icons.music_note,
                      size: 14,
                      color: Colors.deepPurple,
                    ),
                    SizedBox(width: 2),
                    Text(
                      'Premium',
                      style: TextStyle(
                        color: Colors.deepPurple,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          trailing: Switch(
            value: alarm.isEnabled,
            activeColor: Colors.deepPurple,
            onChanged: (bool value) async {
              // Toggle alarm enabled status
              final updatedAlarm = AlarmData(
                id: alarm.id,
                time: alarm.time,
                videoType: alarm.videoType,
                videoUrl: alarm.videoUrl,
                isPremiumUser: alarm.isPremiumUser,
                isEnabled: value,
              );

              if (value) {
                // Re-enable the alarm
                await AlarmManager.scheduleAlarm(updatedAlarm);
              } else {
                // Disable the alarm
                await AlarmManager.deleteAlarm(alarm.id);
                await AlarmManager.saveAlarmData(updatedAlarm);
              }

              // Refresh the list
              _loadAlarms();
            },
          ),
          onTap: () {
            // Edit the alarm
            // You would implement navigation to AlarmSetupScreen with the alarm data
          },
        ),
      ),
    );
  }
}
