import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'job_details_screen.dart';
import 'chat_screen.dart';
import 'message_screen.dart';

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
                  Icon(Icons.notifications_none, size: 64, color: Colors.grey),
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
              if (normal.isNotEmpty) ...[
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text("General",
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 10),
                ...normal.map(
                    (doc) => _NotificationCard(doc: doc, userId: userId)),
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

  Future<void> _markAsRead() async {
    await FirebaseFirestore.instance
        .collection("notifications")
        .doc(userId)
        .collection("items")
        .doc(doc.id)
        .update({"isRead": true});
  }

  Future<void> _deleteNotification() async {
    await FirebaseFirestore.instance
        .collection("notifications")
        .doc(userId)
        .collection("items")
        .doc(doc.id)
        .delete();
  }

  // ── Navigate to JobDetailsScreen ───────────────────────
  Future<void> _navigateToJob(BuildContext context, String jobId) async {
    try {
      final jobDoc = await FirebaseFirestore.instance
          .collection("jobs")
          .doc(jobId)
          .get();

      if (!jobDoc.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Job no longer available")),
        );
        return;
      }

      final jobData = jobDoc.data() as Map<String, dynamic>;
      jobData["id"] = jobDoc.id;
      await _markAsRead();

      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => JobDetailsScreen(job: jobData)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error loading job: $e")),
      );
    }
  }

  // ── Navigate to MessageScreen directly (request_accepted) ──
  // Opens the accepted chat immediately so sender can start messaging
  Future<void> _navigateToMessage(
    BuildContext context, {
    required String chatId,
    required String otherUserId,
    required String otherUserName,
  }) async {
    await _markAsRead();

    // Fetch the other person's profile image for the chat header
    String? profileImage;
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection("users")
          .doc(otherUserId)
          .get();
      profileImage = userDoc.data()?["profileImage"] as String?;
    } catch (_) {}

    if (!context.mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MessageScreen(
          chatId: chatId,
          otherUserId: otherUserId,
          userName: otherUserName,
          userProfileImage: profileImage,
          isRequest: false, // accepted — full chat mode
        ),
      ),
    );
  }

  // ── Navigate to ChatScreen → Requests tab (message_request) ──
  Future<void> _navigateToChatRequests(BuildContext context) async {
    await _markAsRead();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const ChatScreen(initialTab: 2),
      ),
    );
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

    final Map<String, dynamic> extraData =
        (data["data"] as Map<String, dynamic>?) ?? {};
    final String jobId = extraData["jobId"] ?? "";
    final String chatId = extraData["chatId"] ?? "";
    final String otherUserId = extraData["otherUserId"] ?? "";
    final String otherUserName =
        extraData["acceptedByName"] ?? extraData["senderName"] ?? "";

    final bool isJobNotification =
        type == "instant_job" || type == "job_posted";
    final bool isMessageRequest = type == "message_request";
    final bool isRequestAccepted = type == "request_accepted";

    // Show action buttons for job, message_request, and request_accepted
    final bool hasActions =
        isJobNotification || isMessageRequest || isRequestAccepted;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Top row: icon + text + time ──
            Row(
              children: [
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
                          color: isHigh ? Colors.white70 : Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  _timeAgo(createdAt),
                  style: TextStyle(
                    fontSize: 11,
                    color: isHigh ? Colors.white70 : Colors.grey,
                  ),
                ),
              ],
            ),

            // ── Action buttons ──
            if (hasActions) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Cancel — message_request only (dismisses the request)
                  if (isMessageRequest)
                    TextButton(
                      onPressed: () async => await _deleteNotification(),
                      style: TextButton.styleFrom(
                        foregroundColor:
                            isHigh ? Colors.white70 : Colors.grey[600],
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                            color: isHigh
                                ? Colors.white38
                                : Colors.grey.shade300,
                          ),
                        ),
                      ),
                      child: const Text("Cancel",
                          style: TextStyle(fontSize: 13)),
                    ),

                  if (isMessageRequest) const SizedBox(width: 8),

                  // Primary action button — label & destination differ by type
                  ElevatedButton(
                    onPressed: () async {
                      if (isMessageRequest) {
                        // → ChatScreen, Requests tab (receiver reviews the request)
                        await _navigateToChatRequests(context);
                      } else if (isRequestAccepted &&
                          chatId.isNotEmpty &&
                          otherUserId.isNotEmpty) {
                        // → MessageScreen directly (sender opens accepted chat)
                        await _navigateToMessage(
                          context,
                          chatId: chatId,
                          otherUserId: otherUserId,
                          otherUserName: otherUserName,
                        );
                      } else if (isJobNotification && jobId.isNotEmpty) {
                        // → JobDetailsScreen
                        await _navigateToJob(context, jobId);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          isHigh ? Colors.white : const Color(0xFFF5A623),
                      foregroundColor:
                          isHigh ? const Color(0xFFF5A623) : Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 6),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: Text(
                      isMessageRequest
                          ? "View Request"
                          : isRequestAccepted
                              ? "Open Chat"
                              : "View Details",
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
