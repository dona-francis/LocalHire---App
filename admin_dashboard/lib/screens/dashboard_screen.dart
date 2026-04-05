import 'package:flutter/material.dart';
import 'users_screen.dart';
import 'verification_screen.dart';
import 'sos_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int selectedIndex = 0;

  final List<Widget> pages = [
  const UsersScreen(),
  const VerificationScreen(),
  const SosScreen(),
];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [

          // Sidebar
          Container(
            width: 200,
            color: Colors.black,
            child: Column(
              children: [
                const SizedBox(height: 40),
                const Text(
                  "ADMIN",
                  style: TextStyle(color: Colors.white, fontSize: 20),
                ),
                const SizedBox(height: 30),

                _menuItem("Users", 0),
                _menuItem("Verification", 1),
                _menuItem("SOS Alerts", 2),
              ],
            ),
          ),

          // Main content
          Expanded(
            child: pages[selectedIndex],
          ),
        ],
      ),
    );
  }

  Widget _menuItem(String title, int index) {
    return ListTile(
      title: Text(title, style: const TextStyle(color: Colors.white)),
      onTap: () {
        setState(() {
          selectedIndex = index;
        });
      },
    );
  }
}