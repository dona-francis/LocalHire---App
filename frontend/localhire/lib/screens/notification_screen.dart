import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'chat_screen.dart';
import 'message_screen.dart';
class NotificationScreen extends StatelessWidget {
  final String userId;
  const NotificationScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    //  Capture the Scaffold/route context BEFORE StreamBuilder
    // This is the context that owns the Navigator route for this screen
    final BuildContext routeContext = context;

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
            padding: const EdgeInsets.symmetric(vertical: 10),
            children: [
              if (highPriority.isNotEmpty) ...[
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text("Important",
                      style: TextStyle(
                          fontSize: 17, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 6),
                ...highPriority.map((doc) => _NotificationCard(
                      doc: doc,
                      userId: userId,
                      screenContext: routeContext, // ✅ route-level context
                    )),
              ],
              if (normal.isNotEmpty) ...[
                const SizedBox(height: 10),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text("General",
                      style: TextStyle(
                          fontSize: 17, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 6),
                ...normal.map((doc) => _NotificationCard(
                      doc: doc,
                      userId: userId,
                      screenContext: routeContext, // ✅ route-level context
                    )),
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
  final BuildContext screenContext;

  const _NotificationCard({
    required this.doc,
    required this.userId,
    required this.screenContext,
  });

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
      case "new_message":                      
        return Icons.chat_bubble_outline; 
       case "application_accepted":
        return Icons.workspace_premium_rounded;
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
  try {
    await FirebaseFirestore.instance
        .collection("notifications")
        .doc(userId)
        .collection("items")
        .doc(doc.id)
        .update({"isRead": true});
  } catch (e) {
    debugPrint("⚠️ _markAsRead failed (ignored): $e");
  }
}

  Future<void> _deleteNotification() async {
    await FirebaseFirestore.instance
        .collection("notifications")
        .doc(userId)
        .collection("items")
        .doc(doc.id)
        .delete();
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Cancel notification"),
        content: const Text("Are you sure you want to remove this?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("No"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Yes"),
          ),
        ],
      ),
    );
    if (confirm == true) await _deleteNotification();
  }

  Future<void> _navigateToJob(String jobId) async {
    if (jobId.isEmpty) return;
    await _markAsRead();

    debugPrint("Popping NotificationScreen with jobId=$jobId");

    //  Use Navigator.of(screenContext) — this correctly targets the
    // NotificationScreen route, not a nested StreamBuilder/ListView context
    Navigator.of(screenContext).pop({'scrollToJobId': jobId});
  }

  Future<void> _navigateToMessage(
    BuildContext context, {
    required String chatId,
    required String otherUserId,
    required String otherUserName,
  }) async {
    await _markAsRead();

    String? profileImage;
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection("users")
          .doc(otherUserId)
          .get();
      profileImage = userDoc.data()?["profileImage"];
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
          isRequest: false,
        ),
      ),
    );
  }

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
         extraData["acceptedByName"] ??
        extraData["senderName"] ??
        extraData["employerName"] ??  
        "";

    debugPrint("🔔 Notification type=$type | jobId=$jobId | extraData=$extraData");

    final bool isJobNotification =
        type == "instant_job" || type == "job_posted";
    final bool isMessageRequest = type == "message_request";
    final bool isRequestAccepted = type == "request_accepted";
    final bool isNewMessage = type == "new_message";  
    final bool isApplicationAccepted = type == "application_accepted";

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isHigh ? const Color.fromARGB(255, 255, 171, 37) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: !isHigh && !isRead
              ? Border.all(color: const Color(0xFFF5A623), width: 1)
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _iconForType(type),
                  size: 20,
                  color: isHigh ? Colors.white : const Color(0xFFF5A623),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isHigh ? Colors.white : Colors.black,
                      fontSize: 13,
                    ),
                  ),
                ),
                Text(
                  _timeAgo(createdAt),
                  style: TextStyle(
                    fontSize: 10,
                    color: isHigh ? Colors.white70 : Colors.grey,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: isHigh ? Colors.white70 : Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (isMessageRequest || isJobNotification ||isNewMessage)
                  GestureDetector(
                    onTap: () => _confirmDelete(context),
                    child: Text(
                      "Cancel",
                      style: TextStyle(
                        fontSize: 12,
                        color: isHigh ? Colors.white70 : Colors.grey.shade600,
                      ),
                    ),
                  ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: () async {
                    if (isMessageRequest) {
                      await _navigateToChatRequests(context);
                    } else if (isRequestAccepted || isNewMessage) { // ← CHANGE: add isNewMessage
                      await _navigateToMessage(
                        context,
                        chatId: chatId,
                        otherUserId: otherUserId,
                        otherUserName: otherUserName,
                      );
                    } else if (isJobNotification || isApplicationAccepted) {
                      await _navigateToJob(jobId); 
                    }
                  },
                  child: Text(
                    isMessageRequest
                        ? "View"
                        :( isRequestAccepted || isNewMessage)
                            ? "Open Chat"
                            : "View Details",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isHigh ? Colors.white : const Color(0xFFF5A623),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}