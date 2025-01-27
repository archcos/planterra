import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'firebase_options.dart';
import 'screens/dashboard.dart';
import 'screens/login.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Load environment variables
    await dotenv.load(fileName: ".env");

    // Initialize Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Initialize Supabase
    final supabaseUrl = dotenv.env['SUPABASE_URL'] ?? '';
    final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';

    if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
      throw Exception('Missing Supabase credentials in .env file.');
    }

    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );

    // Check if Firebase or Supabase is initialized
    final supabaseClient = Supabase.instance.client;
    if (supabaseClient == null) {
      throw Exception('Supabase failed to initialize.');
    }

    // Check if a user is already signed in with Firebase
    firebase_auth.User? user = firebase_auth.FirebaseAuth.instance.currentUser;
    runApp(MyApp(user: user)); // Pass the user to MyApp
  } catch (e) {
    runApp(MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Initialization Error')),
        body: Center(
          child: Text('Initialization Error: $e'),
        ),
      ),
    ));
  }
}

class MyApp extends StatelessWidget {
  final firebase_auth.User? user;

  const MyApp({Key? key, this.user}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Supabase Login Example',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: user == null ? LoginScreen() : DashboardScreen(), // Conditional navigation
    );
  }
}
