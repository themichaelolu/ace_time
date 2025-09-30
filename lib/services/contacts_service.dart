import 'package:contacts_service/contacts_service.dart';
import 'package:permission_handler/permission_handler.dart';

class ContactService {
  Future<List<Contact>> getContacts() async {
    if (await Permission.contacts.request().isGranted) {
      return (await ContactsService.getContacts()).toList();
    }
    return [];
  }
}
