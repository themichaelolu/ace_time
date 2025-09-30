import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

class RecordingService {
  final AudioRecorder _recorder = AudioRecorder();
  bool _isRecording = false;
  String? _localFilePath;

  bool get isRecording => _isRecording;

  Future<void> startRecording() async {
    if (!await _recorder.hasPermission()) throw Exception('No mic permission');
    final dir = await getTemporaryDirectory();
    _localFilePath = '${dir.path}/rec_${const Uuid().v4()}.m4a';
    await _recorder.start(RecordConfig(), path: _localFilePath!);
    _isRecording = true;
  }

  Future<String?> stopAndUpload(String userId) async {
    if (!_isRecording) return null;
    await _recorder.stop();
    _isRecording = false;

    final file = File(_localFilePath!);
    final ref = FirebaseStorage.instance.ref(
      'recordings/$userId/${const Uuid().v4()}.m4a',
    );
    await ref.putFile(file);
    return ref.getDownloadURL();
  }
}
