import 'package:flutter/material.dart';
import '../../services/chat_service.dart';

class MessageBubble extends StatelessWidget {
  final ChatMessage msg;
  const MessageBubble({super.key, required this.msg});

  @override
  Widget build(BuildContext context) {
    final isAI = msg.fromUid == 'AceTime-AI';
    return Align(
      alignment: isAI ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.all(6),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isAI ? Colors.grey[300] : Colors.blue[200],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(msg.text),
      ),
    );
  }
}
