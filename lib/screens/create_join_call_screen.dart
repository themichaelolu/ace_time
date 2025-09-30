import 'package:ace_time/services/create_join_call_service.dart';
import 'package:ace_time/services/signaling_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

class CreateJoinCallScreen extends StatefulWidget {
  const CreateJoinCallScreen({super.key});

  @override
  State<CreateJoinCallScreen> createState() => _CreateJoinCallScreenState();
}

class _CreateJoinCallScreenState extends State<CreateJoinCallScreen> {
  final TextEditingController _callIdController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final callService = Provider.of<CallService>(context);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 20, horizontal: 15),
          child: Column(
            children: [
              TextField(
                controller: _callIdController,
                decoration: const InputDecoration(
                  hintText: "Call ID",
                  labelText: 'Call ID',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(15)),
                  ),
                ),
              ),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: callService.inCall
                        ? null
                        : () async {
                            final id = await callService.createCall();
                            _callIdController.text = id;
                          },
                    child: const Text("Create"),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: callService.inCall
                        ? null
                        : () => callService.joinCall(
                            _callIdController.text.trim(),
                          ),
                    child: const Text("Join"),
                  ),
                  const SizedBox(width: 8),
                 
                  const SizedBox(width: 8),
                  if (callService.currentCallId != null)
                    IconButton(
                      icon: const Icon(Icons.share),
                      onPressed: () => Share.share(
                        "Join my AceTime call: ${callService.currentCallId}",
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
