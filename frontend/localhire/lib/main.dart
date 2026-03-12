import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/signup_screen.dart';
import 'screens/home_screen.dart';
import 'screens/worker_profile_screen.dart';
import 'services/auth_service.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const LocalHireApp());
}

class LocalHireApp extends StatelessWidget {
  const LocalHireApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'LocalHire',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFFB544),
        ),
        useMaterial3: true,
      ),
      home: const AuthGate(), // ✅ CHECK SESSION FIRST
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final AuthService _authService = AuthService();
  
  

@override
void initState() {
  super.initState();

  _checkSession();
}

  


  void _checkSession() async {
    final userId = await _authService.getSession();

    if (!mounted) return;

    if (userId != null) {
      // ✅ Session found — go straight to Home
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => HomeScreen(userId: userId),
        ),
      );
    } else {
      // ❌ No session — go to Signup
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const SignUpScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Shows spinner while checking session (less than 1 second)
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}