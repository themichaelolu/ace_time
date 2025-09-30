import 'package:ace_time/services/create_join_call_service.dart';
import 'package:ace_time/services/transcription_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:provider/provider.dart';

class CallScreen extends StatefulWidget {
  const CallScreen({super.key});

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();
  final TextEditingController _callIdController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initRenderers();
  }

  Future<void> _initRenderers() async {
    await _localRenderer.initialize();
    await _remoteRenderer.initialize();
  }

  @override
  void dispose() {
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final callService = Provider.of<CallService>(context);
    final transcriptionService = Provider.of<TranscriptionService>(context);

    return Stack(
      children: [
        Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  RTCVideoView(
                    _remoteRenderer,
                    objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    width: 120,
                    height: 180,
                    child: RTCVideoView(_localRenderer, mirror: true),
                  ),
                ],
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: callService.inCall
                      ? null
                      : () async {
                          final id = await callService.createCall();
                          _callIdController.text = id;
                        },
                  child: const Text("Create"),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: callService.inCall
                      ? null
                      : () =>
                            callService.joinCall(_callIdController.text.trim()),
                  child: const Text("Join"),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: !callService.inCall
                      ? null
                      : () => callService.hangUp(),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: const Text("Hang Up"),
                ),
                const SizedBox(width: 8),
                if (callService.currentCallId != null)
                  IconButton(
                    icon: const Icon(Icons.subtitles),
                    onPressed: transcriptionService.transcripts.isEmpty
                        ? () => transcriptionService.startTranscription()
                        : () => transcriptionService.stopTranscription(),
                  ),
              ],
            ),
          ],
        ),

        // Transcription Overlay
        if (transcriptionService.transcripts.isNotEmpty)
          Positioned(
            bottom: 100,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                transcriptionService.transcripts.last,
                style: const TextStyle(color: Colors.white, fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}
