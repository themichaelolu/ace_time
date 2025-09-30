import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';

class ChatMessage {
  final String id;
  final String fromUid;
  final String fromName;
  final String text;
  final DateTime ts;

  ChatMessage({
    required this.id,
    required this.fromUid,
    required this.fromName,
    required this.text,
    DateTime? ts,
  }) : ts = ts ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'fromUid': fromUid,
        'fromName': fromName,
        'text': text,
        'ts': ts.toUtc(),
      };

  factory ChatMessage.fromJson(Map<String, dynamic> j) => ChatMessage(
        id: j['id'],
        fromUid: j['fromUid'],
        fromName: j['fromName'],
        text: j['text'],
        ts: (j['ts'] as Timestamp).toDate(),
      );
}


class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<void> sendTextMessage(String chatId, String text, String senderId) async {
    final messageId = Uuid().v4();
    await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc(messageId)
        .set({
      'senderId': senderId,
      'text': text,
      'timestamp': FieldValue.serverTimestamp(),
      'type': 'text',
    });
  }

  Future<void> sendAudioMessage(String chatId, String filePath, String senderId) async {
    final fileName = Uuid().v4();
    final ref = _storage.ref().child('voice_messages/$fileName.aac');
    await ref.putFile(File(filePath));
    final url = await ref.getDownloadURL();

    final messageId = Uuid().v4();
    await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc(messageId)
        .set({
      'senderId': senderId,
      'audioUrl': url,
      'timestamp': FieldValue.serverTimestamp(),
      'type': 'audio',
    });
  }

  Stream<QuerySnapshot> getMessages(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }
}
