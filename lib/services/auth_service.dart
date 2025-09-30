import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;

  Future<User> signInAnonymously() async {
    if (_auth.currentUser != null) return _auth.currentUser!;
    final cred = await _auth.signInAnonymously();
    return cred.user!;
  }
}
