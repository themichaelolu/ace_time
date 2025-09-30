import 'package:flutter_sound/flutter_sound.dart';

class VoiceService {
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();

  Future<void> init() async {
    await _recorder.openRecorder();
  }

  Future<void> startRecording(String path) async {
    await _recorder.startRecorder(toFile: path);
  }

  Future<String?> stopRecording() async {
    return await _recorder.stopRecorder();
  }
}
