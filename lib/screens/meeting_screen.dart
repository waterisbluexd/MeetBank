import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
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
  int _participantCount = 0; // To show user count

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
    initRenderers();
    // Enable speakerphone
    Helper.setSpeakerphoneOn(true);
    _setupWebRTC();
    _initSpeech();
  }

  void _initSpeech() async {
    await _speechToText.initialize();
    setState(() {});
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
    _localRenderer.dispose();
    _localStream?.getTracks().forEach((track) => track.stop());
    _localStream?.dispose();
    _participantsSubscription?.cancel();
    _signalingSubscription?.cancel();
    _peerConnections.forEach((key, pc) => pc.close());
    _remoteRenderers.forEach((key, renderer) => renderer.dispose());
    // Also turn off speaker phone
    Helper.setSpeakerphoneOn(false);
    super.dispose();
  }

  Future<void> initRenderers() async {
    await _localRenderer.initialize();
  }

  Future<void> _setupWebRTC() async {
    final meetingRef =
        FirebaseFirestore.instance.collection('meetings').doc(_meetingId);

    await _getUserMedia();
    _listenForSignaling(meetingRef);

    // Join the meeting by creating offers for existing participants
    final participantsSnapshot =
        await meetingRef.collection('participants').get();
    for (var participantDoc in participantsSnapshot.docs) {
      final otherUserId = participantDoc.id;
      if (otherUserId != _userId) {
        _createPeerConnectionAndOffer(otherUserId, meetingRef);
      }
    }

    // Add self to participants list
    await meetingRef
        .collection('participants')
        .doc(_userId)
        .set({'id': _userId, 'joinedAt': FieldValue.serverTimestamp()});

    // Listen for new and leaving participants
    _participantsSubscription =
        meetingRef.collection('participants').snapshots().listen((snapshot) {
      if (mounted) {
        setState(() {
          _participantCount = snapshot.docs.length;
        });
      }
      for (var change in snapshot.docChanges) {
        final docId = change.doc.id;
        if (change.type == DocumentChangeType.added &&
            docId != _userId &&
            !_peerConnections.containsKey(docId)) {
          _createPeerConnectionAndOffer(docId, meetingRef);
        } else if (change.type == DocumentChangeType.removed &&
            docId != _userId) {
          _removePeer(docId);
        }
      }
    });
  }

  void _listenForSignaling(DocumentReference meetingRef) {
    _signalingSubscription = meetingRef
        .collection('signaling')
        .where('to', isEqualTo: _userId)
        .snapshots()
        .listen((snapshot) async {
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final data = change.doc.data() as Map<String, dynamic>;
          final fromUserId = data['from'] as String;
          final type = data['type'] as String;

          final pc = await _createPeerConnection(fromUserId, meetingRef);

          switch (type) {
            case 'offer':
              final offerData = data['data'] as Map<String, dynamic>;
              final offer =
                  RTCSessionDescription(offerData['sdp'], offerData['type']);
              await pc.setRemoteDescription(offer);
              final answer = await pc.createAnswer();
              await pc.setLocalDescription(answer);
              await meetingRef.collection('signaling').add({
                'to': fromUserId,
                'from': _userId,
                'type': 'answer',
                'data': answer.toMap(),
              });
              break;
            case 'answer':
              final answerData = data['data'] as Map<String, dynamic>;
              final answer =
                  RTCSessionDescription(answerData['sdp'], answerData['type']);
              if (pc.signalingState !=
                  RTCSignalingState.RTCSignalingStateStable) {
                await pc.setRemoteDescription(answer);
              }
              break;
            case 'candidate':
              final candidateData = data['data'] as Map<String, dynamic>;
              final candidate = RTCIceCandidate(candidateData['candidate'],
                  candidateData['sdpMid'], candidateData['sdpMLineIndex']);
              await pc.addCandidate(candidate);
              break;
          }
          await change.doc.reference.delete();
        }
      }
    });
  }

  Future<void> _createPeerConnectionAndOffer(
      String otherUserId, DocumentReference meetingRef) async {
    final pc = await _createPeerConnection(otherUserId, meetingRef);
    final offer = await pc.createOffer();
    await pc.setLocalDescription(offer);
    await meetingRef.collection('signaling').add({
      'to': otherUserId,
      'from': _userId,
      'type': 'offer',
      'data': offer.toMap(),
    });
  }

  Future<RTCPeerConnection> _createPeerConnection(
      String otherUserId, DocumentReference meetingRef) async {
    if (_peerConnections.containsKey(otherUserId)) {
      return _peerConnections[otherUserId]!;
    }

    final renderer = RTCVideoRenderer();
    await renderer.initialize();
    _remoteRenderers[otherUserId] = renderer;
    if (mounted) setState(() {});

    final configuration = <String, dynamic>{
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'}
      ]
    };
    final pc = await createPeerConnection(configuration);
    _peerConnections[otherUserId] = pc;

    _localStream?.getTracks().forEach((track) {
      pc.addTrack(track, _localStream!);
    });

    pc.onTrack = (event) {
      if (event.streams.isNotEmpty) {
        _remoteRenderers[otherUserId]?.srcObject = event.streams[0];
        if (mounted) setState(() {});
      }
    };

    pc.onIceCandidate = (candidate) {
      meetingRef.collection('signaling').add({
        'to': otherUserId,
        'from': _userId,
        'type': 'candidate',
        'data': candidate.toMap(),
      });
    };

    return pc;
  }

  Future<void> _getUserMedia() async {
    final Map<String, dynamic> mediaConstraints = {
      'audio': true,
      'video': {'facingMode': 'user'},
    };

    try {
      final stream = await navigator.mediaDevices.getUserMedia(mediaConstraints);
      _localStream = stream;
      _localRenderer.srcObject = _localStream;
    } catch (e) {
      if (kDebugMode) {
        print(e.toString());
      }
    }
  }

  void _leaveMeeting() async {
    final meetingRef =
        FirebaseFirestore.instance.collection('meetings').doc(_meetingId);

    // Save the transcript to the summary field
    await meetingRef.update({'summary': _transcript.toString()});

    await meetingRef.collection('participants').doc(_userId).delete();
    final signalingQuery = await meetingRef
        .collection('signaling')
        .where('from', isEqualTo: _userId)
        .get();
    for (var doc in signalingQuery.docs) {
      await doc.reference.delete();
    }

    _hangUp();
    if (mounted) Navigator.pop(context);
  }

  void _hangUp() {
    _localStream?.getTracks().forEach((track) => track.stop());
    _peerConnections.forEach((key, pc) => pc.close());
    _remoteRenderers.forEach((key, renderer) => renderer.dispose());
    _peerConnections.clear();
    _remoteRenderers.clear();
  }

  void _removePeer(String userId) {
    _peerConnections[userId]?.close();
    _peerConnections.remove(userId);
    _remoteRenderers[userId]?.dispose();
    _remoteRenderers.remove(userId);
    if (mounted) setState(() {});
  }

  void _toggleMute() {
    if (_localStream != null) {
      final enabled = !_isMuted;
      setState(() {
        _isMuted = !enabled;
      });
      _localStream!.getAudioTracks()[0].enabled = enabled;
    }
  }

  void _toggleCamera() {
    if (_localStream != null) {
      final enabled = _isCameraOff;
      setState(() {
        _isCameraOff = !enabled;
      });
      _localStream!.getVideoTracks()[0].enabled = enabled;
    }
  }

  void _startListening() {
    _speechToText.listen(
      onResult: (result) {
        setState(() {
          _lastWords = result.recognizedWords;
          if (result.finalResult) {
            _transcript.writeln(_lastWords);
            _lastWords = "";
          }
        });
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
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: <Widget>[
          Positioned.fill(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 400,
                childAspectRatio: 3 / 4,
              ),
              itemCount: _remoteRenderers.length,
              itemBuilder: (context, index) {
                final userId = _remoteRenderers.keys.elementAt(index);
                final renderer = _remoteRenderers[userId]!;
                return RTCVideoView(renderer,
                    objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover);
              },
            ),
          ),
          if (_localRenderer.srcObject != null &&
              _localViewTop != null &&
              _localViewLeft != null)
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
                          offset: Offset(0, 4))
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8.0),
                    child: RTCVideoView(_localRenderer,
                        mirror: true,
                        objectFit:
                            RTCVideoViewObjectFit.RTCVideoViewObjectFitCover),
                  ),
                ),
              ),
            ),
          Positioned(
            top: 40.0,
            left: 20.0,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
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
                        fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
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
                  child: Icon(_isListening ? Icons.mic : Icons.mic_none,
                      color: _isListening ? Colors.white : Colors.black),
                ),
                FloatingActionButton(
                  heroTag: 'mute',
                  backgroundColor: _isMuted ? Colors.red : Colors.white,
                  onPressed: _toggleMute,
                  child: Icon(_isMuted ? Icons.mic_off : Icons.mic,
                      color: _isMuted ? Colors.white : Colors.black),
                ),
                FloatingActionButton(
                  heroTag: 'camera',
                  backgroundColor: _isCameraOff ? Colors.red : Colors.white,
                  onPressed: _toggleCamera,
                  child: Icon(
                      _isCameraOff ? Icons.videocam_off : Icons.videocam,
                      color: _isCameraOff ? Colors.white : Colors.black),
                ),
                FloatingActionButton(
                  heroTag: 'hangup',
                  backgroundColor: Colors.red,
                  onPressed: _leaveMeeting,
                  child: const Icon(Icons.call_end, color: Colors.white),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}

extension on RTCSessionDescription {
  Map<String, dynamic> toMap() => {'sdp': sdp, 'type': type};
}

extension on RTCIceCandidate {
  Map<String, dynamic> toMap() =>
      {'candidate': candidate, 'sdpMid': sdpMid, 'sdpMLineIndex': sdpMLineIndex};
}
