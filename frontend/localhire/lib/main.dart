import 'package:flutter/material.dart';
import 'screens/signup_screen.dart';

void main() {
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
          seedColor: const Color(0xFFF5B544),
        ),
        useMaterial3: true,
      ),
      home: const SignUpScreen(), 
    );
  }
}
