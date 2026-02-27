import 'package:flutter/material.dart';
import 'message_screen.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class ChatUser {
  final String name;
  final String message;
  String time;
  final bool isUnread;
  final int unreadCount;
  final String? profileImage; // 🔥 Added
  bool isPinned;

  ChatUser({
    required this.name,
    required this.message,
    required this.time,
    required this.isUnread,
    required this.unreadCount,
    this.profileImage,
    this.isPinned = false,
  });
}

class _ChatScreenState extends State<ChatScreen> {
  bool showUnreadOnly = false;
  String searchQuery = "";
  final int maxPinned = 3;

  final List<ChatUser> users = [
    ChatUser(
      name: "Ranveer Singh",
      message: "When can you start?",
      time: "2m ago",
      isUnread: true,
      unreadCount: 1,
      profileImage: null, // can add network URL later
    ),
    ChatUser(
      name: "Priya Sharma",
      message: "The budget looks good.",
      time: "1h ago",
      isUnread: false,
      unreadCount: 0,
      profileImage: null,
    ),
    ChatUser(
      name: "Ananya Singh",
      message: "Please share your portfolio.",
      time: "3h ago",
      isUnread: false,
      unreadCount: 0,
      profileImage: null,
    ),
    ChatUser(
      name: "Vikram Sai",
      message: "Interview scheduled for tomorrow.",
      time: "1d ago",
      isUnread: false,
      unreadCount: 0,
      profileImage: null,
    ),
    ChatUser(
      name: "Rahul Verma",
      message: "I've sent the contract details.",
      time: "2d ago",
      isUnread: false,
      unreadCount: 0,
      profileImage: null,
    ),
  ];

  void togglePin(ChatUser user) {
    int pinnedCount =
        users.where((element) => element.isPinned).length;

    if (!user.isPinned && pinnedCount >= maxPinned) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("You can only pin up to 3 chats."),
        ),
      );
      return;
    }

    setState(() {
      user.isPinned = !user.isPinned;
    });
  }

  void showPinDialog(ChatUser user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(user.isPinned ? "Unpin Chat" : "Pin Chat"),
        content: Text(user.isPinned
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
              togglePin(user);
            },
            child: const Text("Confirm"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    List<ChatUser> filteredUsers = users.where((user) {
      final matchesSearch =
          user.name.toLowerCase().contains(searchQuery.toLowerCase());
      final matchesUnread = showUnreadOnly ? user.isUnread : true;
      return matchesSearch && matchesUnread;
    }).toList();

    filteredUsers.sort((a, b) {
      if (a.isPinned == b.isPinned) return 0;
      return a.isPinned ? -1 : 1;
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

          // 🔍 Search
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

          // Toggle
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
                        padding:
                            const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: showUnreadOnly
                              ? Colors.transparent
                              : Colors.white,
                          borderRadius:
                              BorderRadius.circular(20),
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
                        padding:
                            const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: showUnreadOnly
                              ? Colors.white
                              : Colors.transparent,
                          borderRadius:
                              BorderRadius.circular(20),
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
                  onLongPress: () => showPinDialog(user),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            MessageScreen(userName: user.name),
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

                        // 🔥 Profile Picture
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: Colors.grey[300],
                          backgroundImage: user.profileImage != null
                              ? NetworkImage(user.profileImage!)
                              : null,
                          child: user.profileImage == null
                              ? Text(
                                  user.name[0],
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 20),
                                )
                              : null,
                        ),

                        const SizedBox(width: 12),

                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
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
                          crossAxisAlignment:
                              CrossAxisAlignment.end,
                          children: [
                            Row(
                              children: [
                                if (user.isPinned)
                                  const Padding(
                                    padding:
                                        EdgeInsets.only(right: 6),
                                    child: Icon(
                                      Icons.push_pin,
                                      size: 16,
                                      color: Colors.grey,
                                    ),
                                  ),
                                Text(
                                  user.time,
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            if (user.isUnread)
                              Container(
                                padding:
                                    const EdgeInsets.all(6),
                                decoration:
                                    const BoxDecoration(
                                  color:
                                      Color(0xFFF4A825),
                                  shape:
                                      BoxShape.circle,
                                ),
                                child: Text(
                                  user.unreadCount
                                      .toString(),
                                  style:
                                      const TextStyle(
                                    color:
                                        Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                              )
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
