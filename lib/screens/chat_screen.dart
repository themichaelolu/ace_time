import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/chat_service.dart';
import '../services/auth_service.dart';
import '../services/voice_service.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;
  final String contactName;
  ChatScreen({required this.chatId, required this.contactName});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ChatService _chatService = ChatService();
  final AuthService _authService = AuthService();
  final VoiceService _voiceService = VoiceService();
  final FlutterSoundPlayer _player = FlutterSoundPlayer();

  final TextEditingController _controller = TextEditingController();
  bool _isRecording = false;
  String? _recordFilePath;

  @override
  void initState() {
    super.initState();
    _voiceService.init();
    _player.openPlayer();
  }

  @override
  void dispose() {
    _player.closePlayer();
    super.dispose();
  }

  Future<void> sendText() async {
    if (_controller.text.trim().isEmpty) return;
    await _chatService.sendTextMessage(widget.chatId, _controller.text.trim(), _authService.currentUser!.uid);
    _controller.clear();
  }

  Future<void> startRecording() async {
    final dir = await getTemporaryDirectory();
    _recordFilePath = '${dir.path}/${DateTime.now().millisecondsSinceEpoch}.aac';
    await _voiceService.startRecording(_recordFilePath!);
    setState(() => _isRecording = true);
  }

  Future<void> stopRecording() async {
    await _voiceService.stopRecording();
    setState(() => _isRecording = false);
    if (_recordFilePath != null) {
      await _chatService.sendAudioMessage(widget.chatId, _recordFilePath!, _authService.currentUser!.uid);
    }
  }

  Future<void> playAudio(String url) async {
    await _player.startPlayer(fromURI: url, codec: Codec.aacADTS);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.contactName)),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _chatService.getMessages(widget.chatId),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
                final messages = snapshot.data!.docs;
                return ListView.builder(
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final data = messages[index].data() as Map<String, dynamic>;
                    if (data['type'] == 'text') {
                      return ListTile(
                        title: Text(data['text'] ?? ''),
                        subtitle: Text(data['senderId']),
                      );
                    } else if (data['type'] == 'audio') {
                      return ListTile(
                        title: Text('Voice Message'),
                        subtitle: Text(data['senderId']),
                        trailing: IconButton(
                          icon: Icon(Icons.play_arrow),
                          onPressed: () => playAudio(data['audioUrl']),
                        ),
                      );
                    }
                    return SizedBox.shrink();
                  },
                );
              },
            ),
          ),
          Row(
            children: [
              IconButton(
                icon: Icon(_isRecording ? Icons.stop : Icons.mic),
                onPressed: _isRecording ? stopRecording : startRecording,
              ),
              Expanded(
                child: TextField(
                  controller: _controller,
                  decoration: InputDecoration(hintText: 'Type a message'),
                ),
              ),
              IconButton(icon: Icon(Icons.send), onPressed: sendText),
            ],
          )
        ],
      ),
    );
  }
}
