import 'package:ace_time/services/contacts_service.dart';
import 'package:flutter/material.dart';
import 'package:contacts_service/contacts_service.dart';

import '../services/auth_service.dart';
import 'chat_screen.dart';
import 'package:uuid/uuid.dart';

class ContactsScreen extends StatefulWidget {
  @override
  _ContactsScreenState createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  final ContactService _contactService = ContactService();
  final AuthService _authService = AuthService();
  List<Contact> _contacts = [];

  @override
  void initState() {
    super.initState();
    loadContacts();
  }

  Future<void> loadContacts() async {
    List<Contact> contacts = await _contactService.getContacts();
    setState(() {
      _contacts = contacts;
    });
  }

  String generateChatId(String uid1, String uid2) {
    return uid1.compareTo(uid2) > 0 ? '$uid1-$uid2' : '$uid2-$uid1';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Contacts')),
      body: ListView.builder(
        itemCount: _contacts.length,
        itemBuilder: (context, index) {
          final contact = _contacts[index];
          return ListTile(
            title: Text(contact.displayName ?? ''),
            subtitle: Text(contact.phones!.isNotEmpty ? contact.phones!.first.value! : ''),
            trailing: IconButton(
              icon: Icon(Icons.video_call),
              onPressed: () {
                // Placeholder for your WebRTC call snippet
               
              },
            ),
            onTap: () {
              final currentUser = _authService.currentUser;
              if (currentUser == null) return;

              final chatId = generateChatId(currentUser.uid, contact.phones!.first.value ?? Uuid().v4());

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChatScreen(chatId: chatId, contactName: contact.displayName ?? 'Chat'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
