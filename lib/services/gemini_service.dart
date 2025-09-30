import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

class GeminiService {
  final String apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final _user = FirebaseAuth.instance.currentUser;

  final _recorder = AudioRecorder();
  String? _recordingPath;

  // ---------------- TEXT CHAT ----------------
  Future<void> sendMessage(String text) async {
    if (_user == null) return;

    await _db.collection("users").doc(_user!.uid).collection("gemini_chats").add({
      "from": "user",
      "text": text,
      "createdAt": FieldValue.serverTimestamp(),
    });

    final response = await http.post(
      Uri.parse("https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$apiKey"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "contents": [
          {"parts": [{"text": text}]}
        ]
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final reply = data["candidates"]?[0]?["content"]?["parts"]?[0]?["text"] ?? "⚠️ No response";

      await _db.collection("users").doc(_user!.uid).collection("gemini_chats").add({
        "from": "gemini",
        "text": reply,
        "createdAt": FieldValue.serverTimestamp(),
      });
    } else {
      await _db.collection("users").doc(_user!.uid).collection("gemini_chats").add({
        "from": "gemini",
        "text": "⚠️ Error: ${response.body}",
        "createdAt": FieldValue.serverTimestamp(),
      });
    }
  }

  // ---------------- IMAGE GENERATION ----------------
  Future<String?> generateImage(String prompt) async {
    final response = await http.post(
      Uri.parse("https://generativelanguage.googleapis.com/v1beta/models/imagegeneration:generate?key=$apiKey"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "prompt": {"text": prompt},
        "imageGenerationConfig": {"numberOfImages": 1}
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final imageUri = data["images"]?[0]?["uri"];
      if (imageUri != null && _user != null) {
        await _db.collection("users").doc(_user!.uid).collection("gemini_chats").add({
          "from": "gemini",
          "type": "image",
          "imageUrl": imageUri,
          "prompt": prompt,
          "createdAt": FieldValue.serverTimestamp(),
        });
      }
      return imageUri;
    }
    return null;
  }

  // ---------------- AUDIO RECORDING ----------------
  Future<void> startRecording() async {
    final dir = await getApplicationDocumentsDirectory();
    final path = '${dir.path}/temp_recording.m4a';
    _recordingPath = path;

    if (await _recorder.hasPermission()) {
      await _recorder.start(const RecordConfig(), path: path);
    }
  }

  Future<void> stopRecording() async {
    final path = await _recorder.stop();
    if (path != null) {
      _recordingPath = path;
      await _sendAudioToGemini(File(path));
    }
  }

  // ---------------- AUDIO → GEMINI TRANSCRIPTION ----------------
  Future<void> _sendAudioToGemini(File audioFile) async {
    if (_user == null) return;

    // Save "user sent audio" in Firestore
    await _db.collection("users").doc(_user!.uid).collection("gemini_chats").add({
      "from": "user",
      "type": "audio",
      "audioPath": audioFile.path,
      "createdAt": FieldValue.serverTimestamp(),
    });

    final bytes = await audioFile.readAsBytes();
    final base64Audio = base64Encode(bytes);

    final response = await http.post(
      Uri.parse("https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$apiKey"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "contents": [
          {
            "parts": [
              {
                "inlineData": {
                  "mimeType": "audio/mp4",
                  "data": base64Audio,
                }
              }
            ]
          }
        ]
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final reply = data["candidates"]?[0]?["content"]?["parts"]?[0]?["text"] ?? "⚠️ No response";

      await _db.collection("users").doc(_user!.uid).collection("gemini_chats").add({
        "from": "gemini",
        "text": reply,
        "createdAt": FieldValue.serverTimestamp(),
      });
    } else {
      await _db.collection("users").doc(_user!.uid).collection("gemini_chats").add({
        "from": "gemini",
        "text": "⚠️ Error: ${response.body}",
        "createdAt": FieldValue.serverTimestamp(),
      });
    }
  }
}
