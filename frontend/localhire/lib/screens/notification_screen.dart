import 'package:flutter/material.dart';

class NotificationItem {
  final IconData? icon;
  final String title;
  final String subtitle;
  final String? time;
  final String? imageUrl;
  final bool isImportant;
  final List<NotificationAction>? actions;
  final VoidCallback onTap;

  NotificationItem({
    this.icon,
    required this.title,
    required this.subtitle,
    this.time,
    this.imageUrl,
    this.isImportant = false,
    this.actions,
    required this.onTap,
  });
}

class NotificationAction {
  final String label;
  final VoidCallback onPressed;
  final Color? color;

  NotificationAction({
    required this.label,
    required this.onPressed,
    this.color,
  });
}

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({Key? key}) : super(key: key);

  // Sample notification data
  static List<NotificationItem> notifications = [
    NotificationItem(
      icon: Icons.flash_on,
      title: "Instant Job Nearby!",
      subtitle: "Plumber needed now in Thodupuzha, Kottayam",
      isImportant: true,
      onTap: () => print("Instant Job Clicked"),
      actions: [
        NotificationAction(
          label: "Apply",
          onPressed: () => print("Apply Clicked"),
          color: Colors.white,
        ),
        NotificationAction(
          label: "Details",
          onPressed: () => print("Details Clicked"),
          color: Colors.white70,
        ),
      ],
    ),
    NotificationItem(
      icon: Icons.message,
      title: "Message from Ramesh Singh",
      subtitle: "Please bring your Aadhar card copy...",
      time: "2m ago",
      onTap: () => print("Message Clicked"),
      actions: [
        NotificationAction(
          label: "Reply",
          onPressed: () => print("Reply Clicked"),
          color: Colors.green,
        ),
      ],
    ),
  ];

  Widget _buildNotificationCard(NotificationItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: item.onTap,
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: item.isImportant ? const Color(0xFFE7B34F) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  blurRadius: 6,
                  offset: const Offset(0, 3))
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  item.imageUrl != null
                      ? CircleAvatar(
                          backgroundImage: AssetImage(item.imageUrl!),
                        )
                      : CircleAvatar(
                          backgroundColor: item.isImportant
                              ? Colors.white.withOpacity(0.3)
                              : Colors.grey[300],
                          child: Icon(
                            item.icon,
                            color: item.isImportant ? Colors.white : Colors.black,
                          ),
                        ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: item.isImportant ? Colors.white : Colors.black),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.subtitle,
                          style: TextStyle(
                              color: item.isImportant ? Colors.white70 : Colors.grey[700]),
                        ),
                      ],
                    ),
                  ),
                  if (item.time != null)
                    Text(
                      item.time!,
                      style: TextStyle(
                          color: item.isImportant ? Colors.white70 : Colors.grey[500],
                          fontSize: 12),
                    ),
                ],
              ),
              if (item.actions != null && item.actions!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Row(
                    children: item.actions!
                        .map(
                          (action) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: action.color ?? Colors.blue,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                              onPressed: action.onPressed,
                              child: Text(action.label),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Notifications"),
      ),
      body: ListView.builder(
        itemCount: notifications.length,
        itemBuilder: (context, index) {
          return _buildNotificationCard(notifications[index]);
        },
      ),
    );
  }
}
