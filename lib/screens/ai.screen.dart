import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/gemini_service.dart';

class GeminiScreen extends StatefulWidget {
  const GeminiScreen({super.key});

  @override
  State<GeminiScreen> createState() => _GeminiScreenState();
}

class _GeminiScreenState extends State<GeminiScreen> {
  final _controller = TextEditingController();
  final _geminiService = GeminiService();
  final _user = FirebaseAuth.instance.currentUser;

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();

    if (text.toLowerCase().startsWith("image:")) {
      final prompt = text.replaceFirst("image:", "").trim();
      await _geminiService.generateImage(prompt);
    } else {
      await _geminiService.sendMessage(text);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_user == null) {
      return const Center(child: Text("Please sign in first."));
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Gemini AI")),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection("users")
                  .doc(_user!.uid)
                  .collection("gemini_chats")
                  .orderBy("createdAt", descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data!.docs;
                return ListView.builder(
                  reverse: true,
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final from = data["from"];
                    final text = data["text"];
                    final imageUrl = data["imageUrl"];

                    final isUser = from == "user";

                    return Align(
                      alignment: isUser
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(
                          vertical: 4,
                          horizontal: 8,
                        ),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isUser ? Colors.blue : Colors.grey[800],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: imageUrl != null
                            ? Image.network(imageUrl, height: 200)
                            : Text(
                                text ?? "",
                                style: const TextStyle(color: Colors.white),
                              ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  decoration: const InputDecoration(
                    hintText:
                        "Ask AceTime AI... (or type 'image: cat on moon')",
                  ),
                ),
              ),
              IconButton(icon: const Icon(Icons.send), onPressed: _sendMessage),
            ],
          ),
        ],
      ),
    );
  }
}
