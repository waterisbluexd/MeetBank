import 'package:flutter/material.dart';
import 'package:jitsi_meet_flutter_sdk/jitsi_meet_flutter_sdk.dart';
import 'package:uuid/uuid.dart';

class VideoConferencePage extends StatefulWidget {
  const VideoConferencePage({Key? key}) : super(key: key);

  @override
  State<VideoConferencePage> createState() => _VideoConferencePageState();
}

class _VideoConferencePageState extends State<VideoConferencePage> {
  final TextEditingController _roomController = TextEditingController();
  final Uuid _uuid = const Uuid();
  final _jitsiMeetPlugin = JitsiMeet();

  @override
  void initState() {
    super.initState();
    _roomController.text = _uuid.v4().substring(0, 8);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Video Conference'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _roomController,
                decoration: const InputDecoration(
                  labelText: 'Room ID',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _joinMeeting,
              child: const Text('Join Meeting'),
            ),
          ],
        ),
      ),
    );
  }

  void _joinMeeting() {
    if (_roomController.text.isNotEmpty) {
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
        },
      );
      _jitsiMeetPlugin.join(options);
    }
  }
}
