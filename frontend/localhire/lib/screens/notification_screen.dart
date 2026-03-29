import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationScreen extends StatelessWidget {
  final String userId;
  const NotificationScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          "Notifications",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("notifications")
            .doc(userId)
            .collection("items")
            .orderBy("createdAt", descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_none,
                      size: 64, color: Colors.grey),
                  SizedBox(height: 12),
                  Text("No notifications yet",
                      style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          final docs = snapshot.data!.docs;
          final highPriority = docs
              .where((d) => (d.data() as Map)["priority"] == "high")
              .toList();
          final normal = docs
              .where((d) => (d.data() as Map)["priority"] != "high")
              .toList();

          return ListView(
            padding: const EdgeInsets.symmetric(vertical: 16),
            children: [
              // ── IMPORTANT SECTION ──
              if (highPriority.isNotEmpty) ...[
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text("Important",
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 10),
                ...highPriority.map((doc) =>
                    _NotificationCard(doc: doc, userId: userId)),
                const SizedBox(height: 20),
              ],

              // ── GENERAL SECTION ──
              if (normal.isNotEmpty) ...[
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text("General",
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 10),
                ...normal.map((doc) =>
                    _NotificationCard(doc: doc, userId: userId)),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final QueryDocumentSnapshot doc;
  final String userId;

  const _NotificationCard({required this.doc, required this.userId});

  IconData _iconForType(String type) {
    switch (type) {
      case "message_request":
        return Icons.message;
      case "request_accepted":
        return Icons.check_circle;
      case "instant_job":
        return Icons.flash_on;
      case "job_posted":
        return Icons.work_outline;
      default:
        return Icons.notifications;
    }
  }

  String _timeAgo(Timestamp? timestamp) {
    if (timestamp == null) return "";
    final diff = DateTime.now().difference(timestamp.toDate());
    if (diff.inMinutes < 60) return "${diff.inMinutes}m ago";
    if (diff.inHours < 24) return "${diff.inHours}h ago";
    return "${diff.inDays}d ago";
  }

  @override
  Widget build(BuildContext context) {
    final data = doc.data() as Map<String, dynamic>;
    final bool isHigh = data["priority"] == "high";
    final String type = data["type"] ?? "";
    final String title = data["title"] ?? "";
    final String subtitle = data["subtitle"] ?? "";
    final bool isRead = data["isRead"] ?? false;
    final Timestamp? createdAt = data["createdAt"];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: GestureDetector(
        onTap: () async {
          // Mark as read
          await FirebaseFirestore.instance
              .collection("notifications")
              .doc(userId)
              .collection("items")
              .doc(doc.id)
              .update({"isRead": true});
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isHigh ? const Color(0xFFF5A623) : Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
            border: !isHigh && !isRead
                ? Border.all(color: const Color(0xFFF5A623), width: 1.5)
                : null,
          ),
          child: Row(
            children: [
              // Icon circle
              CircleAvatar(
                radius: 24,
                backgroundColor: isHigh
                    ? Colors.white.withValues(alpha: 0.25)
                    : Colors.grey.shade100,
                child: Icon(
                  _iconForType(type),
                  color: isHigh ? Colors.white : const Color(0xFFF5A623),
                ),
              ),
              const SizedBox(width: 14),

              // Text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isHigh ? Colors.white : Colors.black,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: isHigh
                            ? Colors.white70
                            : Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),

              // Time or arrow
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _timeAgo(createdAt),
                    style: TextStyle(
                      fontSize: 11,
                      color: isHigh ? Colors.white70 : Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Icon(
                    Icons.chevron_right,
                    color: isHigh ? Colors.white70 : Colors.grey,
                    size: 20,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}