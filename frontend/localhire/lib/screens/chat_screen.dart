import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/chat_service.dart';
import '../models/chat_model.dart';
import 'message_screen.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ChatService _chatService = ChatService();
  bool showUnreadOnly = false;
  String searchQuery = "";
  final int maxPinned = 3;
  final Set<String> pinnedChats = {};

  // Get the other user's UID from participants
  String getOtherUserId(List<String> participants) {
    final currentUid = FirebaseAuth.instance.currentUser!.uid;
    return participants.firstWhere((id) => id != currentUid, orElse: () => '');
  }

  void togglePin(String chatId) {
    if (!pinnedChats.contains(chatId) && pinnedChats.length >= maxPinned) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You can only pin up to 3 chats.")),
      );
      return;
    }
    setState(() {
      if (pinnedChats.contains(chatId)) {
        pinnedChats.remove(chatId);
      } else {
        pinnedChats.add(chatId);
      }
    });
  }

  void showPinDialog(String chatId) {
    final isPinned = pinnedChats.contains(chatId);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isPinned ? "Unpin Chat" : "Pin Chat"),
        content: Text(isPinned
            ? "Do you want to unpin this chat?"
            : "Do you want to pin this chat?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              togglePin(chatId);
            },
            child: const Text("Confirm"),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime? time) {
    if (time == null) return '';
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F4F4),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "LocalHire",
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ),
      body: Column(
        children: [

          // 🔍 Search
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              onChanged: (value) => setState(() => searchQuery = value),
              decoration: InputDecoration(
                hintText: "Search messages...",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: const Color(0xFFE9E9E9),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // Toggle All / Unread
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFE0E0E0),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => showUnreadOnly = false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: showUnreadOnly ? Colors.transparent : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Center(child: Text("All")),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => showUnreadOnly = true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: showUnreadOnly ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Center(child: Text("Unread")),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // 💬 Chat List — now from Firebase
          Expanded(
            child: StreamBuilder<List<ChatModel>>(
              stream: _chatService.getUserChats(),
              builder: (context, snapshot) {

                // Loading state
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                // Empty state
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Text("No chats yet",
                        style: TextStyle(color: Colors.grey, fontSize: 16)),
                  );
                }

                List<ChatModel> chats = snapshot.data!;

                // Apply search filter
                if (searchQuery.isNotEmpty) {
                  chats = chats.where((chat) {
                    final otherId = getOtherUserId(chat.participants);
                    return otherId.toLowerCase().contains(searchQuery.toLowerCase());
                  }).toList();
                }

                // Apply unread filter — NOTE: unread count needs separate logic,
                // keeping showUnreadOnly as a UI toggle for now
                // (full unread count will work after message_screen is updated)

                // Sort: pinned first
                chats.sort((a, b) {
                  final aPinned = pinnedChats.contains(a.id);
                  final bPinned = pinnedChats.contains(b.id);
                  if (aPinned == bPinned) return 0;
                  return aPinned ? -1 : 1;
                });

                return ListView.builder(
                  itemCount: chats.length,
                  itemBuilder: (context, index) {
                    final chat = chats[index];
                    final otherUserId = getOtherUserId(chat.participants);
                    final isPinned = pinnedChats.contains(chat.id);

                    // Fetch other user's name from Firestore /users collection
                    return FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('users')
                          .doc(otherUserId)
                          .get(),
                      builder: (context, userSnapshot) {
                        // Use real name if available, fallback to UID initial
                        final userName = userSnapshot.hasData &&
                                userSnapshot.data!.exists
                            ? (userSnapshot.data!['name'] ??
                                userSnapshot.data!['displayName'] ??
                                otherUserId)
                            : otherUserId;

                        final userInitial =
                            userName.isNotEmpty ? userName[0].toUpperCase() : '?';

                        return GestureDetector(
                          onLongPress: () => showPinDialog(chat.id),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => MessageScreen(
                                  chatId: chat.id,
                                  otherUserId: otherUserId,
                                  userName: userName,
                                ),
                              ),
                            );
                          },
                          child: Container(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFECE6D8),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.03),
                                  blurRadius: 6,
                                  offset: const Offset(0, 3),
                                )
                              ],
                            ),
                            child: Row(
                              children: [

                                // Profile Picture (same as original)
                                CircleAvatar(
                                  radius: 28,
                                  backgroundColor: Colors.grey[300],
                                  child: Text(
                                    userInitial,
                                    style: const TextStyle(
                                        color: Colors.white, fontSize: 20),
                                  ),
                                ),

                                const SizedBox(width: 12),

                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        userName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        chat.lastMessage.isEmpty
                                            ? "No messages yet"
                                            : chat.lastMessage,
                                        style: const TextStyle(color: Colors.grey),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),

                                // Time + pin (same layout as original)
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Row(
                                      children: [
                                        if (isPinned)
                                          const Padding(
                                            padding: EdgeInsets.only(right: 6),
                                            child: Icon(Icons.push_pin,
                                                size: 16, color: Colors.grey),
                                          ),
                                        Text(
                                          _formatTime(chat.lastMessageTime),
                                          style: const TextStyle(
                                              fontSize: 12, color: Colors.grey),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
