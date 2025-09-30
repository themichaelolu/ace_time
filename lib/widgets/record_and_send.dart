// import 'package:flutter/material.dart';
// import 'package:uuid/uuid.dart';
// import '../services/chat_service.dart';
// import '../services/recording_service.dart';
// import '../services/gemini_service.dart';
// import '../services/auth_service.dart';

// class RecordAndSend extends StatefulWidget {
//   final String chatId;
//   const RecordAndSend({super.key, required this.chatId});

//   @override
//   State<RecordAndSend> createState() => _RecordAndSendState();
// }

// class _RecordAndSendState extends State<RecordAndSend> {
//   final recSvc = RecordingService();
//   final gemSvc = GeminiService();
//   bool loading = false;

//   Future<void> _toggleRecord() async {
//     final user = AuthService().currentUser!;
//     final chatSvc = ChatService();

//     if (!recSvc.isRecording) {
//       await recSvc.startRecording();
//       setState(() {});
//     } else {
//       setState(() => loading = true);
//       final audioUrl = await recSvc.stopAndUpload(user.uid);
//       if (audioUrl != null) {
//         final transcript = await gemSvc.re(audioUrl);
//         final msg = ChatMessage(
//           id: const Uuid().v4(),
//           fromUid: 'AceTime-AI',
//           fromName: 'AceTime AI',
//           text: transcript,
//         );
//         await chatSvc.sendMessage(widget.chatId, msg);
//       }
//       setState(() => loading = false);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Row(
//       children: [
//         IconButton(
//           icon: Icon(recSvc.isRecording ? Icons.stop : Icons.mic),
//           onPressed: loading ? null : _toggleRecord,
//         ),
//         if (loading) const CircularProgressIndicator(),
//       ],
//     );
//   }
// }
