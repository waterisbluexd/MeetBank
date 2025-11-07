import 'package:flutter/material.dart';
import 'package:jitsi_meet_flutter_sdk/jitsi_meet_flutter_sdk.dart';
import 'package:uuid/uuid.dart';

class VideoConferencePage extends StatefulWidget {
  final String? room;
  const VideoConferencePage({Key? key, this.room}) : super(key: key);

  @override
  State<VideoConferencePage> createState() => _VideoConferencePageState();
}

class _VideoConferencePageState extends State<VideoConferencePage> {
  final TextEditingController _roomController = TextEditingController();
  final Uuid _uuid = const Uuid();
  final _jitsiMeetPlugin = JitsiMeet();
  bool _isJoining = false;

  @override
  void initState() {
    super.initState();
    if (widget.room != null) {
      _roomController.text = widget.room!;
    } else {
      _roomController.text = _uuid.v4().substring(0, 8);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Join a Meeting'),
        actions: [
          if (_isJoining)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(color: Colors.white),
            )
          else
            TextButton(
              onPressed: _joinMeeting,
              child: const Text('Join', style: TextStyle(color: Colors.white, fontSize: 16)),
            )
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Enter a room name to join or create a meeting",
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _roomController,
                decoration: const InputDecoration(
                  labelText: 'Room Name',
                  hintText: 'e.g. my-awesome-meeting',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.group),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _joinMeeting() async {
    if (_roomController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a room name.')),
      );
      return;
    }
    
    setState(() {
      _isJoining = true;
    });

    var options = JitsiMeetConferenceOptions(
      room: _roomController.text,
      configOverrides: {
        "startWithAudioMuted": true,
        "startWithVideoMuted": true,
      },
      featureFlags: {
        FeatureFlags.addPeopleEnabled: true,
        FeatureFlags.welcomePageEnabled: false,
        FeatureFlags.preJoinPageEnabled: true,
        FeatureFlags.unsafeRoomWarningEnabled: false,
      },
       userInfo: JitsiMeetUserInfo(
          displayName: "MeetBank User",
       ),
    );
    
    var listener = JitsiMeetEventListener(
      conferenceTerminated: (url, error) {
        setState(() {
          _isJoining = false;
        });
      },
    );

    await _jitsiMeetPlugin.join(options, listener);
  }
  
  @override
  void dispose() {
    _roomController.dispose();
    super.dispose();
  }
}
