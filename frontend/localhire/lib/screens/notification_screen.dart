import 'package:flutter/material.dart';

class NotificationItem {
  final IconData? icon;
  final String title;
  final String subtitle;
  final String? time;
  final String? image;
  final bool isImportant;
  final Widget? navigateTo;
  final bool showViewButton;

  NotificationItem({
    this.icon,
    required this.title,
    required this.subtitle,
    this.time,
    this.image,
    this.isImportant = false,
    this.navigateTo,
    this.showViewButton = false,
  });
}

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  List<NotificationItem> notifications = [];

  @override
  void initState() {
    super.initState();

    notifications = [
      // IMPORTANT SECTION
      NotificationItem(
        icon: Icons.flash_on,
        title: "Instant Job Nearby!",
        subtitle: "Plumber needed now in Thodupuzha, Kottayam",
        isImportant: true,
        navigateTo: const DummyScreen(title: "Instant Job Details"),
      ),
      NotificationItem(
        icon: Icons.notifications,
        title: "Job Alerts",
        subtitle: "2 part-time jobs are available",
        isImportant: true,
        navigateTo: const DummyScreen(title: "Job Alerts"),
      ),
      NotificationItem(
        icon: Icons.access_time,
        title: "Reminder",
        subtitle: "Cleaning scheduled at 10:00 AM",
        isImportant: true,
        navigateTo: const DummyScreen(title: "Reminder Details"),
      ),

      // GENERAL SECTION
      NotificationItem(
        icon: Icons.message,
        title: "Message from Ramesh Singh",
        subtitle: "Please bring your Aadhar card copy...",
        time: "2m ago",
        navigateTo: const DummyScreen(title: "Chat Screen"),
      ),
      NotificationItem(
        icon: Icons.check_circle,
        title: "Application Accepted",
        subtitle: "Your application for 'Electrician' has been accepted.",
        time: "1h ago",
        navigateTo: const DummyScreen(title: "Application Details"),
      ),
      NotificationItem(
        image: "assets/profile.jpg", // replace with your asset
        title: "New Applicant",
        subtitle: "Rajesh Kumar applied for Plumber",
        time: "4h ago",
        showViewButton: true,
        navigateTo: const DummyScreen(title: "Applicant Details"),
      ),
      NotificationItem(
        image: "assets/profile.jpg",
        title: "Review and rate Rajesh Kumar",
        subtitle: "Share your experience about the work completed.",
        time: "6h ago",
        navigateTo: const DummyScreen(title: "Review Screen"),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final important =
        notifications.where((item) => item.isImportant).toList();
    final general =
        notifications.where((item) => !item.isImportant).toList();

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Notifications"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: ListView(
        children: [
          if (important.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                "Important",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            ...important.map((item) => buildCard(item)),
          ],
          if (general.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                "General",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            ...general.map((item) => buildCard(item)),
          ],
        ],
      ),
    );
  }

  Widget buildCard(NotificationItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          if (item.navigateTo != null) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => item.navigateTo!),
            );
          }
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: item.isImportant
                ? const Color(0xFFE7B34F)
                : Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              item.image != null
                  ? CircleAvatar(
                      radius: 24,
                      backgroundImage: AssetImage(item.image!),
                    )
                  : CircleAvatar(
                      radius: 24,
                      backgroundColor: item.isImportant
                          ? Colors.white.withOpacity(0.3)
                          : Colors.grey[200],
                      child: Icon(
                        item.icon,
                        color: item.isImportant
                            ? Colors.white
                            : Colors.black,
                      ),
                    ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: item.isImportant
                            ? Colors.white
                            : Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: item.isImportant
                            ? Colors.white70
                            : Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),
              if (item.showViewButton)
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => item.navigateTo!),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE7B34F),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Text("View"),
                )
              else if (item.time != null)
                Text(
                  item.time!,
                  style: TextStyle(
                    fontSize: 12,
                    color: item.isImportant
                        ? Colors.white70
                        : Colors.grey,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class DummyScreen extends StatelessWidget {
  final String title;

  const DummyScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Text(
          title,
          style: const TextStyle(fontSize: 22),
        ),
      ),
    );
  }
} 