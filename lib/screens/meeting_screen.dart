import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

class MeetingScreen extends StatefulWidget {
  final String meetingLink;

  const MeetingScreen({
    Key? key,
    required this.meetingLink,
  }) : super(key: key);

  @override
  _MeetingScreenState createState() => _MeetingScreenState();
}

class _MeetingScreenState extends State<MeetingScreen> {
  final _localRenderer = RTCVideoRenderer();
  final _remoteRenderer = RTCVideoRenderer();
  MediaStream? _localStream;
  RTCPeerConnection? _peerConnection;
  String? _meetingId;

  @override
  void initState() {
    super.initState();
    _meetingId = widget.meetingLink.split('/').last;
    initRenderers();
    _setupPeerConnection();
  }

  @override
  void dispose() {
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    _localStream?.dispose();
    _peerConnection?.close();
    super.dispose();
  }

  Future<void> initRenderers() async {
    await _localRenderer.initialize();
    await _remoteRenderer.initialize();
  }

  Future<void> _setupPeerConnection() async {
    final firestore = FirebaseFirestore.instance;
    final meetingRef = firestore.collection('meetings').doc(_meetingId);

    final configuration = <String, dynamic>{
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'},
      ],
    };

    _peerConnection = await createPeerConnection(configuration);

    await _getUserMedia();

    _localStream?.getTracks().forEach((track) {
      _peerConnection?.addTrack(track, _localStream!);
    });

    _peerConnection!.onTrack = (RTCTrackEvent event) {
      if (event.track.kind == 'video' && event.streams.isNotEmpty) {
        setState(() {
          _remoteRenderer.srcObject = event.streams[0];
        });
      }
    };

    final meetingDoc = await meetingRef.get();

    if (!meetingDoc.exists) {
      _peerConnection!.onIceCandidate = (RTCIceCandidate candidate) {
        meetingRef.collection('caller_candidates').add(candidate.toMap());
      };

      final offer = await _peerConnection!.createOffer();
      await _peerConnection!.setLocalDescription(offer);

      await meetingRef.set({
        'offer': offer.toMap(),
      });

      meetingRef.snapshots().listen((snapshot) async {
        final data = snapshot.data();
        if (data != null && data.containsKey('answer')) {
          final answer = RTCSessionDescription(
            data['answer']['sdp'],
            data['answer']['type'],
          );

          if (_peerConnection!.getRemoteDescription() == null) {
            await _peerConnection!.setRemoteDescription(answer);
          }
        }
      });

      meetingRef.collection('callee_candidates').snapshots().listen((snapshot) {
        for (var change in snapshot.docChanges) {
          if (change.type == DocumentChangeType.added) {
            final data = change.doc.data();
            if (data != null) {
              _peerConnection!.addCandidate(
                RTCIceCandidate(
                  data['candidate'],
                  data['sdpMid'],
                  data['sdpMLineIndex'],
                ),
              );
            }
          }
        }
      });
    } else {
      _peerConnection!.onIceCandidate = (RTCIceCandidate candidate) {
        meetingRef.collection('callee_candidates').add(candidate.toMap());
      };

      final offer = RTCSessionDescription(
        meetingDoc.data()!['offer']['sdp'],
        meetingDoc.data()!['offer']['type'],
      );

      await _peerConnection!.setRemoteDescription(offer);

      final answer = await _peerConnection!.createAnswer();
      await _peerConnection!.setLocalDescription(answer);

      await meetingRef.update({'answer': answer.toMap()});

      meetingRef.collection('caller_candidates').snapshots().listen((snapshot) {
        for (var change in snapshot.docChanges) {
          if (change.type == DocumentChangeType.added) {
            final data = change.doc.data();
            if (data != null) {
              _peerConnection!.addCandidate(
                RTCIceCandidate(
                  data['candidate'],
                  data['sdpMid'],
                  data['sdpMLineIndex'],
                ),
              );
            }
          }
        }
      });
    }
  }

  Future<void> _getUserMedia() async {
    final Map<String, dynamic> mediaConstraints = {
      'audio': true,
      'video': {
        'facingMode': 'user',
      },
    };

    try {
      final stream = await navigator.mediaDevices.getUserMedia(mediaConstraints);
      _localStream = stream;
      _localRenderer.srcObject = _localStream;
    } catch (e) {
      print(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Meeting: $_meetingId'),
      ),
      body: Column(
        children: [
          Expanded(child: RTCVideoView(_localRenderer, mirror: true)),
          Expanded(child: RTCVideoView(_remoteRenderer)),
        ],
      ),
    );
  }
}

extension on RTCSessionDescription {
  Map<String, dynamic> toMap() {
    return {
      'sdp': sdp,
      'type': type,
    };
  }
}

extension on RTCIceCandidate {
  Map<String, dynamic> toMap() {
    return {
      'candidate': candidate,
      'sdpMid': sdpMid,
      'sdpMLineIndex': sdpMLineIndex,
    };
  }
}
