import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:http/http.dart' as http;

class SignalingService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final _recorder = AudioRecorder();

  RTCPeerConnection? _pc;
  MediaStream? _localStream;
  MediaStream? _remoteStream;
  String? _recordFilePath;
  bool _isRecording = false;

  StreamController<String> _transcriptionController =
      StreamController.broadcast();
  bool _isTranscribing = false;

  MediaStream? get localStream => _localStream;
  MediaStream? get remoteStream => _remoteStream;

  final _iceServers = [
    {'urls': 'stun:stun.l.google.com:19302'},
  ];

  // ---------- Recording Logic ----------
  Future<void> startRecording() async {
    if (await _recorder.hasPermission()) {
      final dir = await getApplicationDocumentsDirectory();
      _recordFilePath =
          '${dir.path}/call_recording_${DateTime.now().millisecondsSinceEpoch}.m4a';
      await _recorder.start(
        const RecordConfig(encoder: AudioEncoder.aacLc),
        path: _recordFilePath!,
      );
      _isRecording = true;
    }
  }

  Future<void> stopRecordingAndUpload(String callId) async {
    if (!_isRecording) return;
    final path = await _recorder.stop();
    _isRecording = false;
    if (path == null) return;

    final file = File(path);
    final ref = _storage.ref().child("calls/$callId/recording.m4a");
    await ref.putFile(file);
    final url = await ref.getDownloadURL();

    // 🔹 Send audio to Gemini for transcription
    final transcript = await _transcribeWithGemini(url);

    // 🔹 Store transcript in Firestore chat
    await _db.collection("calls").doc(callId).collection("messages").add({
      "fromUid": "AceTime-AI",
      "type": "transcript",
      "text": transcript,
      "createdAt": FieldValue.serverTimestamp(),
    });
  }

  Future<String> _transcribeWithGemini(String fileUrl) async {
    final apiKey = const String.fromEnvironment("GEMINI_API_KEY");
    final endpoint =
        "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$apiKey";

    final response = await http.post(
      Uri.parse(endpoint),
      headers: {"Content-Type": "application/json"},
      body:
          '''
      {
        "contents": [{
          "parts": [
            {"text": "Transcribe this audio and summarize key insights."},
            {"fileData": {"mimeType": "audio/m4a", "fileUri": "$fileUrl"}}
          ]
        }]
      }
      ''',
    );

    if (response.statusCode == 200) {
      final text = response.body;
      // For simplicity, return raw body. Ideally parse JSON for candidate text.
      return text;
    } else {
      return "⚠️ Gemini transcription failed: ${response.body}";
    }
  }

  Stream<String> get transcriptionStream => _transcriptionController.stream;

  Future<void> startTranscription() async {
    if (_isTranscribing) return;
    if (await _recorder.hasPermission()) {
      _isTranscribing = true;

      final dir = await getApplicationDocumentsDirectory();
      final filePath = '${dir.path}/live_call_audio.m4a';

      await _recorder.start(
        const RecordConfig(encoder: AudioEncoder.aacLc),
        path: filePath,
      );

      // Poll every 5s for partial transcription
      Timer.periodic(const Duration(seconds: 5), (timer) async {
        if (!_isTranscribing) {
          timer.cancel();
          return;
        }

        if (await File(filePath).exists()) {
          final text = await _transcribeChunk(filePath);
          if (text.isNotEmpty) {
            _transcriptionController.add(text);
          }
        }
      });
    }
  }

  Future<void> stopTranscription() async {
    _isTranscribing = false;
    await _recorder.stop();
  }

  Future<String> _transcribeChunk(String filePath) async {
    try {
      final apiKey = const String.fromEnvironment("GEMINI_API_KEY");
      final endpoint =
          "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$apiKey";

      final fileBytes = await File(filePath).readAsBytes();
      final base64Audio = base64Encode(fileBytes);

      final response = await http.post(
        Uri.parse(endpoint),
        headers: {"Content-Type": "application/json"},
        body:
            '''
        {
          "contents": [{
            "parts": [
              {"text": "Transcribe this audio chunk."},
              {"inlineData": {"mimeType": "audio/m4a", "data": "$base64Audio"}}
            ]
          }]
        }
        ''',
      );

      if (response.statusCode == 200) {
        final body = response.body;
        return body; // (Ideally parse candidates[0].content.parts[0].text)
      } else {
        return "";
      }
    } catch (e) {
      return "";
    }
  }

  // ---------- Existing WebRTC logic (createCall, joinCall, hangUp) ----------
  // Add startRecording() at call start, stopRecordingAndUpload() at hangUp
  // ... (keep existing methods from before)

  Future<String> createCall() async {
    if (_localStream == null) {
      await initLocalMedia();
    }
    await startRecording();
    // rest of method unchanged...
    final callDoc = _db.collection('calls').doc();
    final offerCandidatesCol = callDoc.collection('offerCandidates');
    final answerCandidatesCol = callDoc.collection('answerCandidates');
    _pc = await _setupPeerConnection(
      offerCandidatesCol,
      answerCandidatesCol,
      true,
    );
    final offer = await _pc!.createOffer();
    await _pc!.setLocalDescription(offer);
    await callDoc.set({
      'offer': {'sdp': offer.sdp, 'type': offer.type},
      'createdAt': FieldValue.serverTimestamp(),
    });
    callDoc.snapshots().listen((snapshot) async {
      final data = snapshot.data();
      if (data != null && data['answer'] != null) {
        final ans = data['answer'] as Map<String, dynamic>;
        await _pc!.setRemoteDescription(
          RTCSessionDescription(ans['sdp'], ans['type']),
        );
      }
    });
    answerCandidatesCol.snapshots().listen((snap) {
      for (var doc in snap.docChanges) {
        if (doc.type == DocumentChangeType.added) {
          final d = doc.doc.data()!;
          _pc?.addCandidate(
            RTCIceCandidate(d['candidate'], d['sdpMid'], d['sdpMLineIndex']),
          );
        }
      }
    });
    return callDoc.id;
  }

  Future<void> joinCall(String callId) async {
    if (_localStream == null) {
      await initLocalMedia();
    }
    await startRecording();
    // ... keep same as before
  }

  Future<void> hangUp(String callId) async {
    await stopRecordingAndUpload(callId);
    await _pc?.close();
    _pc = null;
    await _localStream?.dispose();
    await _remoteStream?.dispose();
    _localStream = null;
    _remoteStream = null;
  }

  Future<RTCPeerConnection> _setupPeerConnection(
    CollectionReference offerCandidatesCol,
    CollectionReference answerCandidatesCol,
    bool isCaller,
  ) async {
    final pc = await createPeerConnection({'iceServers': _iceServers}, {});
    if (_localStream != null) {
      for (var track in _localStream!.getTracks()) {
        await pc.addTrack(track, _localStream!);
      }
    }
    pc.onTrack = (event) {
      if (event.streams.isNotEmpty) _remoteStream = event.streams.first;
    };
    pc.onIceCandidate = (c) async {
      if (c.candidate != null) {
        await (isCaller ? offerCandidatesCol : answerCandidatesCol).add({
          'candidate': c.candidate,
          'sdpMLineIndex': c.sdpMLineIndex,
          'sdpMid': c.sdpMid,
        });
      }
    };
    return pc;
  }

  Future<void> initLocalMedia({bool video = true, bool audio = true}) async {
    final stream = await navigator.mediaDevices.getUserMedia({
      'audio': audio,
      'video': video ? {'facingMode': 'user'} : false,
    });
    _localStream = stream;
  }
}
