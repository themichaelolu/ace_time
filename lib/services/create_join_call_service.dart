import 'package:flutter/foundation.dart';
import 'signaling_service.dart';

class CallService extends ChangeNotifier {
  final SignalingService _signaling;

  String? _currentCallId;
  bool _inCall = false;
  bool _transcriptionEnabled = false;

  String? get currentCallId => _currentCallId;
  bool get inCall => _inCall;
  bool get transcriptionEnabled => _transcriptionEnabled;
  Stream<String> get transcriptionStream => _signaling.transcriptionStream;

  CallService(this._signaling);

  Future<String> createCall() async {
    final id = await _signaling.createCall();
    _currentCallId = id;
    _inCall = true;
    notifyListeners();
    return id;
  }

  Future<void> joinCall(String callId) async {
    if (callId.isEmpty) return;
    await _signaling.joinCall(callId);
    _currentCallId = callId;
    _inCall = true;
    notifyListeners();
  }

  Future<void> hangUp() async {
    if (_currentCallId != null) {
      await _signaling.hangUp(_currentCallId!);
    }
    await disableTranscription();
    _inCall = false;
    _currentCallId = null;
    notifyListeners();
  }

  Future<void> enableTranscription() async {
    _transcriptionEnabled = true;
    await _signaling.startTranscription();
    notifyListeners();
  }

  Future<void> disableTranscription() async {
    _transcriptionEnabled = false;
    await _signaling.stopTranscription();
    notifyListeners();
  }
}
