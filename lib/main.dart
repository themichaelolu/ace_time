import 'package:ace_time/screens/ai.screen.dart';
import 'package:ace_time/screens/contacts_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'firebase_options.dart';
import 'package:provider/provider.dart';
import 'services/auth_service.dart';
import 'screens/chat_screen.dart';
import 'screens/call_screen.dart';
import 'services/signaling_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // Ensure user is signed in (anonymous) before UI
  await AuthService().signInAnonymously();
  await dotenv.load(fileName: ".env");
  runApp(const AceTimeApp());
}

class AceTimeApp extends StatelessWidget {
  const AceTimeApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [Provider(create: (_) => SignalingService())],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'AceTime (WebRTC + Firebase)',
        theme: ThemeData(primarySwatch: Colors.deepPurple),
        home: const HomeTabs(),
      ),
    );
  }
}

class HomeTabs extends StatefulWidget {
  const HomeTabs({Key? key}) : super(key: key);

  @override
  State<HomeTabs> createState() => _HomeTabsState();
}

class _HomeTabsState extends State<HomeTabs> {
  int _idx = 0;
  final _pages = [ContactsScreen(), CallScreen(), GeminiScreen()];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AceTime — MVP')),
      body: _pages[_idx],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _idx,
        onTap: (i) => setState(() => _idx = i),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.contact_page),
            label: 'Contact',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.video_call), label: 'Call'),
          BottomNavigationBarItem(icon: Icon(Icons.info), label: 'AI'),
        ],
      ),
    );
  }
}
