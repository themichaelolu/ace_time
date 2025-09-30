import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:record/record.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class TranscriptionService extends ChangeNotifier {
  final String apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
  final _recorder = AudioRecorder();
  WebSocketChannel? _channel;
  bool _isStreaming = false;

  final List<String> _transcripts = [];
  List<String> get transcripts => List.unmodifiable(_transcripts);

  Future<void> startTranscription() async {
    if (_isStreaming) return;

    // Connect to Gemini Realtime WS API
    final uri = Uri.parse(
      "wss://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:streamGenerateContent?key=$apiKey",
    );
    _channel = WebSocketChannel.connect(uri);

    _channel!.stream.listen((event) {
      final data = jsonDecode(event);
      final text = data["candidates"]?[0]?["content"]?["parts"]?[0]?["text"];
      if (text != null) {
        _transcripts.add(text);
        notifyListeners();
      }
    });

    // Start mic recording in PCM chunks
    if (await _recorder.hasPermission()) {
      final stream = await _recorder.startStream(
        const RecordConfig(encoder: AudioEncoder.pcm16bits, sampleRate: 16000),
      );

      stream.listen((buffer) {
        if (_channel != null && _isStreaming) {
          final base64Data = base64Encode(buffer);
          _channel!.sink.add(
            jsonEncode({
              "inlineData": {"mimeType": "audio/pcm", "data": base64Data},
            }),
          );
        }
      });
    }

    _isStreaming = true;
  }

  Future<void> stopTranscription() async {
    _isStreaming = false;
    await _recorder.stop();
    await _channel?.sink.close();
    _channel = null;
  }

  void clearTranscripts() {
    _transcripts.clear();
    notifyListeners();
  }
}
