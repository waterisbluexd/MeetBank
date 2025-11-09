import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:meetbank/models/Meeting.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:uuid/uuid.dart';

class MeetingScreen extends StatefulWidget {
  final String meetingLink;

  const MeetingScreen({super.key, required this.meetingLink});

  @override
  State<MeetingScreen> createState() => _MeetingScreenState();
}

class _MeetingScreenState extends State<MeetingScreen> {
  final _localRenderer = RTCVideoRenderer();
  MediaStream? _localStream;
  String? _meetingId;
  String? _userId;

  final _remoteRenderers = <String, RTCVideoRenderer>{};
  final _peerConnections = <String, RTCPeerConnection>{};

  StreamSubscription? _participantsSubscription;
  StreamSubscription? _signalingSubscription;

  bool _isMuted = false;
  bool _isCameraOff = false;
  int _participantCount = 0;
  bool _isLeaving = false;

  double? _localViewTop;
  double? _localViewLeft;

  final SpeechToText _speechToText = SpeechToText();
  bool _isListening = false;
  String _lastWords = "";
  final StringBuffer _transcript = StringBuffer();

  @override
  void initState() {
    super.initState();
    _meetingId = widget.meetingLink.split('/').last;
    _userId = const Uuid().v4();
    if (kDebugMode) print("My userId: $_userId");
    initRenderers();
    Helper.setSpeakerphoneOn(true);
    _setupWebRTC();
    _initSpeech();
  }

  void _initSpeech() async {
    await _speechToText.initialize();
    if (mounted) setState(() {});
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final size = MediaQuery.of(context).size;
    _localViewTop = 20.0;
    _localViewLeft = size.width - 140.0;
  }

  @override
  void dispose() {
    if (kDebugMode) print("Dispose called");
    if (!_isLeaving) {
      _cleanUp();
    }
    super.dispose();
  }

  void _cleanUp() {
    if (kDebugMode) print("Cleanup called");
    try {
      _signalingSubscription?.cancel();
      _participantsSubscription?.cancel();

      _peerConnections.forEach((key, pc) {
        pc.close();
      });
      _peerConnections.clear();

      _remoteRenderers.forEach((key, renderer) {
        renderer.dispose();
      });
      _remoteRenderers.clear();

      _localStream?.getTracks().forEach((track) {
        track.stop();
      });
      _localStream?.dispose();
      _localRenderer.dispose();

      Helper.setSpeakerphoneOn(false);
    } catch (e) {
      if (kDebugMode) print("Error during cleanup: $e");
    }
  }

  Future<void> initRenderers() async {
    await _localRenderer.initialize();
  }

  Future<void> _setupWebRTC() async {
    final meetingRef = FirebaseFirestore.instance.collection('meetings').doc(_meetingId);

    // Check if meeting exists
    final meetingDoc = await meetingRef.get();
    if (!meetingDoc.exists) {
      final now = DateTime.now();
      final newMeeting = Meeting(
        id: _meetingId!,
        title: "Instant Meeting",
        description: "Meeting started on ${now.toLocal()}",
        startTime: now,
        endTime: now.add(const Duration(hours: 1)),
        status: "Ongoing",
        summary: "",
        summaryKeywords: [],
        meetingLink: widget.meetingLink,
        linkType: 'google_meet',
        createdBy: FirebaseAuth.instance.currentUser!.uid,
        createdAt: now,
      );
      await meetingRef.set(newMeeting.toMap());
    }

    // Get media first
    await _getUserMedia();
    if (_localStream == null) {
      if (kDebugMode) print("Failed to get local stream");
      return;
    }

    // Add self to participants
    await meetingRef.collection('participants').doc(_userId).set({
      'id': _userId,
      'joinedAt': FieldValue.serverTimestamp(),
    });

    // Start listening for signaling BEFORE checking existing participants
    _listenForSignaling(meetingRef);

    // Small delay to ensure listener is active
    await Future.delayed(const Duration(milliseconds: 300));

    // Get existing participants and create connections
    final participantsSnapshot = await meetingRef.collection('participants').get();
    if (kDebugMode) print("Found ${participantsSnapshot.docs.length} participants");

    for (var participantDoc in participantsSnapshot.docs) {
      final otherUserId = participantDoc.id;
      if (otherUserId != _userId) {
        if (kDebugMode) print("Creating offer for existing participant: $otherUserId");
        await _createPeerConnectionAndOffer(otherUserId, meetingRef);
      }
    }

    // Listen for new participants
    _participantsSubscription = meetingRef.collection('participants').snapshots().listen((snapshot) {
      if (!mounted) return;

      setState(() {
        _participantCount = snapshot.docs.length;
      });

      if (kDebugMode) print("Participant count: $_participantCount");

      for (var change in snapshot.docChanges) {
        final docId = change.doc.id;

        if (change.type == DocumentChangeType.added && docId != _userId) {
          if (!_peerConnections.containsKey(docId)) {
            if (kDebugMode) print("New participant joined: $docId");
            // Don't create offer here - let the new joiner create it
          }
        } else if (change.type == DocumentChangeType.removed) {
          if (kDebugMode) print("Participant left: $docId");
          _removePeer(docId);
        }
      }
    });
  }

  void _listenForSignaling(DocumentReference meetingRef) {
    if (kDebugMode) print("Starting to listen for signaling messages");

    _signalingSubscription = meetingRef
        .collection('signaling')
        .where('to', isEqualTo: _userId)
        .snapshots()
        .listen((snapshot) async {
      if (!mounted) return;

      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final data = change.doc.data() as Map<String, dynamic>;
          final fromUserId = data['from'] as String;
          final type = data['type'] as String;

          if (kDebugMode) print("Received $type from $fromUserId");

          // Delete the signaling document
          change.doc.reference.delete().catchError((e) {
            if (kDebugMode) print("Error deleting signaling doc: $e");
          });

          if (type == 'hangup') {
            _removePeer(fromUserId);
            continue;
          }

          try {
            final pc = await _getOrCreatePeerConnection(fromUserId, meetingRef);

            switch (type) {
              case 'offer':
                final offerData = data['data'] as Map<String, dynamic>;
                final offer = RTCSessionDescription(offerData['sdp'], offerData['type']);

                if (kDebugMode) print("Setting remote description (offer) from $fromUserId");
                await pc.setRemoteDescription(offer);

                if (kDebugMode) print("Creating answer for $fromUserId");
                final answer = await pc.createAnswer();
                await pc.setLocalDescription(answer);

                if (kDebugMode) print("Sending answer to $fromUserId");
                await meetingRef.collection('signaling').add({
                  'to': fromUserId,
                  'from': _userId,
                  'type': 'answer',
                  'data': answer.toMap(),
                  'timestamp': FieldValue.serverTimestamp(),
                });
                break;

              case 'answer':
                final answerData = data['data'] as Map<String, dynamic>;
                final answer = RTCSessionDescription(answerData['sdp'], answerData['type']);

                if (kDebugMode) print("Setting remote description (answer) from $fromUserId");
                if (pc.signalingState != RTCSignalingState.RTCSignalingStateStable) {
                  await pc.setRemoteDescription(answer);
                }
                break;

              case 'candidate':
                final candidateData = data['data'] as Map<String, dynamic>;
                if (candidateData['candidate'] != null) {
                  final candidate = RTCIceCandidate(
                    candidateData['candidate'],
                    candidateData['sdpMid'],
                    candidateData['sdpMLineIndex'],
                  );

                  if (kDebugMode) print("Adding ICE candidate from $fromUserId");
                  await pc.addCandidate(candidate);
                }
                break;
            }
          } catch (e) {
            if (kDebugMode) print("Error processing signaling: $e");
          }
        }
      }
    });
  }

  Future<void> _createPeerConnectionAndOffer(String otherUserId, DocumentReference meetingRef) async {
    if (kDebugMode) print("Creating peer connection and offer for $otherUserId");

    final pc = await _getOrCreatePeerConnection(otherUserId, meetingRef);

    final offer = await pc.createOffer();
    await pc.setLocalDescription(offer);

    if (kDebugMode) print("Sending offer to $otherUserId");
    await meetingRef.collection('signaling').add({
      'to': otherUserId,
      'from': _userId,
      'type': 'offer',
      'data': offer.toMap(),
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Future<RTCPeerConnection> _getOrCreatePeerConnection(String otherUserId, DocumentReference meetingRef) async {
    if (_peerConnections.containsKey(otherUserId)) {
      return _peerConnections[otherUserId]!;
    }

    if (kDebugMode) print("Creating new peer connection for $otherUserId");

    // Create and initialize remote renderer
    final renderer = RTCVideoRenderer();
    await renderer.initialize();

    if (mounted) {
      setState(() {
        _remoteRenderers[otherUserId] = renderer;
      });
    }

    // ICE configuration
    final configuration = <String, dynamic>{
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'},
        {'urls': 'stun:stun1.l.google.com:19302'},
      ],
    };

    final pc = await createPeerConnection(configuration);
    _peerConnections[otherUserId] = pc;

    // Add local tracks
    if (_localStream != null) {
      _localStream!.getTracks().forEach((track) {
        if (kDebugMode) print("Adding local track to peer connection: ${track.kind}");
        pc.addTrack(track, _localStream!);
      });
    }

    // Handle incoming tracks
    pc.onTrack = (event) {
      if (kDebugMode) print("Received track from $otherUserId: ${event.track.kind}");

      if (event.streams.isNotEmpty) {
        final stream = event.streams[0];
        final renderer = _remoteRenderers[otherUserId];

        if (renderer != null) {
          if (kDebugMode) print("Setting stream for $otherUserId");
          renderer.srcObject = stream;
          if (mounted) setState(() {});
        }
      }
    };

    // Handle ICE candidates
    pc.onIceCandidate = (candidate) {
      if (candidate.candidate != null) {
        if (kDebugMode) print("Sending ICE candidate to $otherUserId");
        meetingRef.collection('signaling').add({
          'to': otherUserId,
          'from': _userId,
          'type': 'candidate',
          'data': candidate.toMap(),
          'timestamp': FieldValue.serverTimestamp(),
        });
      }
    };

    // Handle connection state changes
    pc.onConnectionState = (state) {
      if (kDebugMode) print("Connection state with $otherUserId: $state");

      if (state == RTCPeerConnectionState.RTCPeerConnectionStateFailed ||
          state == RTCPeerConnectionState.RTCPeerConnectionStateDisconnected) {
        if (kDebugMode) print("Connection failed/disconnected with $otherUserId");
      }
    };

    pc.onIceConnectionState = (state) {
      if (kDebugMode) print("ICE connection state with $otherUserId: $state");
    };

    return pc;
  }

  Future<void> _getUserMedia() async {
    final Map<String, dynamic> mediaConstraints = {
      'audio': true,
      'video': {
        'facingMode': 'user',
        'width': {'ideal': 640},
        'height': {'ideal': 480},
      },
    };

    try {
      final stream = await navigator.mediaDevices.getUserMedia(mediaConstraints);
      _localStream = stream;
      _localRenderer.srcObject = _localStream;

      if (kDebugMode) {
        print("Local stream obtained");
        print("Audio tracks: ${stream.getAudioTracks().length}");
        print("Video tracks: ${stream.getVideoTracks().length}");
      }

      if (mounted) setState(() {});
    } catch (e) {
      if (kDebugMode) print("getUserMedia error: $e");
    }
  }

  Future<void> _leaveMeeting() async {
    if (_isLeaving) return;
    _isLeaving = true;

    if (kDebugMode) print("Leaving meeting...");

    try {
      final meetingRef = FirebaseFirestore.instance.collection('meetings').doc(_meetingId);

      // Save transcript
      if (_transcript.isNotEmpty) {
        await meetingRef.update({'summary': _transcript.toString()}).catchError((e) {
          if (kDebugMode) print("Error saving transcript: $e");
        });
      }

      // Send hangup signals
      final peerIds = _peerConnections.keys.toList();
      for (var otherUserId in peerIds) {
        await meetingRef.collection('signaling').add({
          'to': otherUserId,
          'from': _userId,
          'type': 'hangup',
          'timestamp': FieldValue.serverTimestamp(),
        }).catchError((e) {
          if (kDebugMode) print("Error sending hangup: $e");
        });
      }

      // Remove from participants
      if (_userId != null) {
        await meetingRef.collection('participants').doc(_userId!).delete().catchError((e) {
          if (kDebugMode) print("Error removing participant: $e");
        });
      }

      // Clean up signaling messages from this user
      final signalingQuery = await meetingRef
          .collection('signaling')
          .where('from', isEqualTo: _userId)
          .get()
          .catchError((e) {
        if (kDebugMode) print("Error querying signaling: $e");
        return null;
      });

      if (signalingQuery != null) {
        for (var doc in signalingQuery.docs) {
          await doc.reference.delete().catchError((e) {
            if (kDebugMode) print("Error deleting signaling doc: $e");
          });
        }
      }
    } catch (e) {
      if (kDebugMode) print('Error in _leaveMeeting: $e');
    }

    // Clean up local resources
    _cleanUp();

    // Pop the screen
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  void _removePeer(String userId) {
    if (kDebugMode) print("Removing peer: $userId");

    _peerConnections[userId]?.close();
    _peerConnections.remove(userId);
    _remoteRenderers[userId]?.dispose();
    _remoteRenderers.remove(userId);

    if (mounted) setState(() {});
  }

  void _toggleMute() {
    if (_localStream?.getAudioTracks().isNotEmpty == true) {
      final newMutedState = !_isMuted;
      _localStream!.getAudioTracks()[0].enabled = !newMutedState;
      setState(() {
        _isMuted = newMutedState;
      });
    }
  }

  void _toggleCamera() {
    if (_localStream?.getVideoTracks().isNotEmpty == true) {
      final newCameraOffState = !_isCameraOff;
      _localStream!.getVideoTracks()[0].enabled = !newCameraOffState;
      setState(() {
        _isCameraOff = newCameraOffState;
      });
    }
  }

  void _startListening() {
    _speechToText.listen(
      onResult: (result) {
        if (mounted) {
          setState(() {
            _lastWords = result.recognizedWords;
            if (result.finalResult) {
              _transcript.writeln(_lastWords);
              _lastWords = "";
            }
          });
        }
      },
    );
    setState(() {
      _isListening = true;
    });
  }

  void _stopListening() {
    _speechToText.stop();
    setState(() {
      _isListening = false;
    });
  }

  void _toggleListening() {
    if (_isListening) {
      _stopListening();
    } else {
      _startListening();
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (!_isLeaving) {
          await _leaveMeeting();
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: <Widget>[
            // Remote video grid
            Positioned.fill(
              child: _remoteRenderers.isEmpty
                  ? Center(
                child: Text(
                  'Waiting for participants...',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
              )
                  : GridView.builder(
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 400,
                  childAspectRatio: 3 / 4,
                ),
                itemCount: _remoteRenderers.length,
                itemBuilder: (context, index) {
                  final userId = _remoteRenderers.keys.elementAt(index);
                  final renderer = _remoteRenderers[userId]!;
                  return Container(
                    margin: EdgeInsets.all(2),
                    child: RTCVideoView(
                      renderer,
                      objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                    ),
                  );
                },
              ),
            ),

            // Local video (draggable)
            if (_localRenderer.srcObject != null && _localViewTop != null && _localViewLeft != null)
              Positioned(
                left: _localViewLeft,
                top: _localViewTop,
                width: 120.0,
                height: 160.0,
                child: GestureDetector(
                  onPanUpdate: (details) {
                    setState(() {
                      _localViewLeft = (_localViewLeft! + details.delta.dx)
                          .clamp(0.0, MediaQuery.of(context).size.width - 120.0);
                      _localViewTop = (_localViewTop! + details.delta.dy)
                          .clamp(0.0, MediaQuery.of(context).size.height - 160.0);
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white, width: 2.0),
                      borderRadius: BorderRadius.circular(8.0),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 10.0,
                          offset: Offset(0, 4),
                        )
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8.0),
                      child: RTCVideoView(
                        _localRenderer,
                        mirror: true,
                        objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                      ),
                    ),
                  ),
                ),
              ),

            // Participant count
            Positioned(
              top: 40.0,
              left: 20.0,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(20.0),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.people, color: Colors.white, size: 18),
                    const SizedBox(width: 8.0),
                    Text(
                      '$_participantCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Transcript display
            if (_lastWords.isNotEmpty)
              Positioned(
                bottom: 100.0,
                left: 20,
                right: 20,
                child: Container(
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: Text(
                    _lastWords,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16.0,
                    ),
                  ),
                ),
              ),

            // Control buttons
            Positioned(
              bottom: 20.0,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  FloatingActionButton(
                    heroTag: 'transcript',
                    backgroundColor: _isListening ? Colors.blue : Colors.white,
                    onPressed: _toggleListening,
                    child: Icon(
                      _isListening ? Icons.mic : Icons.mic_none,
                      color: _isListening ? Colors.white : Colors.black,
                    ),
                  ),
                  FloatingActionButton(
                    heroTag: 'mute',
                    backgroundColor: _isMuted ? Colors.red : Colors.white,
                    onPressed: _toggleMute,
                    child: Icon(
                      _isMuted ? Icons.mic_off : Icons.mic,
                      color: _isMuted ? Colors.white : Colors.black,
                    ),
                  ),
                  FloatingActionButton(
                    heroTag: 'camera',
                    backgroundColor: _isCameraOff ? Colors.red : Colors.white,
                    onPressed: _toggleCamera,
                    child: Icon(
                      _isCameraOff ? Icons.videocam_off : Icons.videocam,
                      color: _isCameraOff ? Colors.white : Colors.black,
                    ),
                  ),
                  FloatingActionButton(
                    heroTag: 'hangup',
                    backgroundColor: Colors.red,
                    onPressed: _leaveMeeting,
                    child: const Icon(Icons.call_end, color: Colors.white),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

extension on RTCSessionDescription {
  Map<String, dynamic> toMap() => {'sdp': sdp, 'type': type};
}

extension on RTCIceCandidate {
  Map<String, dynamic> toMap() => {
    'candidate': candidate,
    'sdpMid': sdpMid,
    'sdpMLineIndex': sdpMLineIndex,
  };
}