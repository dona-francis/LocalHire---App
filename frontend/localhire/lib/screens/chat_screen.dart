import 'package:flutter/material.dart';
import 'message_screen.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({Key? key}) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class ChatUser {
  final String name;
  final String message;
  final String time;
  final bool isUnread;
  final int unreadCount;
  bool isPinned; // Added pin state

  ChatUser({
    required this.name,
    required this.message,
    required this.time,
    required this.isUnread,
    required this.unreadCount,
    this.isPinned = false, // default not pinned
  });
}

class _ChatScreenState extends State<ChatScreen> {
  bool showUnreadOnly = false;
  String searchQuery = "";

  final List<ChatUser> users = [
    ChatUser(
        name: "Ranveer Singh",
        message: "When can you start?",
        time: "2m ago",
        isUnread: true,
        unreadCount: 1),
    ChatUser(
        name: "Priya Sharma",
        message: "The budget looks good.",
        time: "1h ago",
        isUnread: false,
        unreadCount: 0),
    ChatUser(
        name: "Kate Issac",
        message: "Please share your portfolio.",
        time: "3h ago",
        isUnread: false,
        unreadCount: 0),
    ChatUser(
        name: "Samuel Lee",
        message: "Interview scheduled for tomorrow.",
        time: "1d ago",
        isUnread: false,
        unreadCount: 0),
    ChatUser(
        name: "Peter Parker",
        message: "I've sent the contract details.",
        time: "2d ago",
        isUnread: false,
        unreadCount: 0),
  ];

  void togglePin(ChatUser user) {
    final pinnedCount = users.where((u) => u.isPinned).length;

    setState(() {
      if (user.isPinned) {
        // unpin
        user.isPinned = false;
      } else {
        if (pinnedCount >= 3) {
          // show info message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("You can only pin up to 3 chats."),
              duration: Duration(seconds: 2),
            ),
          );
        } else {
          user.isPinned = true;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Filtered based on search and unread
    List<ChatUser> filteredUsers = users.where((user) {
      final matchesSearch =
          user.name.toLowerCase().contains(searchQuery.toLowerCase());
      final matchesUnread = showUnreadOnly ? user.isUnread : true;
      return matchesSearch && matchesUnread;
    }).toList();

    // Sort pinned chats on top
    filteredUsers.sort((a, b) {
      if (a.isPinned && !b.isPinned) return -1;
      if (!a.isPinned && b.isPinned) return 1;
      return 0;
    });

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

          // 🔍 Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                });
              },
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

          // 🔘 Toggle All / Unread
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
                      onTap: () {
                        setState(() {
                          showUnreadOnly = false;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: showUnreadOnly
                              ? Colors.transparent
                              : const Color.fromARGB(255, 255, 255, 255),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Center(child: Text("All")),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          showUnreadOnly = true;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: showUnreadOnly
                              ? Colors.white
                              : Colors.transparent,
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

          // 💬 Chat List
          Expanded(
            child: ListView.builder(
              itemCount: filteredUsers.length,
              itemBuilder: (context, index) {
                final user = filteredUsers[index];

                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MessageScreen(userName: user.name),
                        fullscreenDialog: false,
                      ),
                    );
                  },
                  onLongPress: () => togglePin(user), // 🔥 pin/unpin on long press
                  child: Container(
                    margin:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFECE6D8),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: const Color.fromARGB(255, 244,168, 37),
                          child: Text(
                            user.name[0],
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20),
                          ),
                        ),
                        const SizedBox(width: 12),

                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                user.message,
                                style: const TextStyle(
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),

                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              user.time,
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey),
                            ),
                            const SizedBox(height: 6),
                            if (user.isUnread)
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: const BoxDecoration(
                                  color: Color.fromARGB(255, 244, 168, 37),
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  user.unreadCount.toString(),
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12),
                                ),
                              ),
                            if (user.isPinned)
                              const Padding(
                                padding: EdgeInsets.only(top: 6),
                                child: Icon(
                                  Icons.push_pin,
                                  size: 16,
                                  color: Colors.orange,
                                ),
                              ),
                          ],
                        )
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
