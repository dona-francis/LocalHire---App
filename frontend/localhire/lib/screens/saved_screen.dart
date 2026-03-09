import 'package:flutter/material.dart';
import '../services/chat_service.dart';
import 'message_screen.dart';

class SavedScreen extends StatefulWidget {
  const SavedScreen({super.key});

  @override
  State<SavedScreen> createState() => _SavedScreenState();
}

class _SavedScreenState extends State<SavedScreen> {
  final ChatService _chatService = ChatService();
  TextEditingController searchController = TextEditingController();

  List<Map<String, String>> savedProfiles = [
    {
      "name": "Arun Kumar",
      "location": "Mumbai, Maharashtra",
      "image": "https://randomuser.me/api/portraits/men/32.jpg",
      "uid": "PASTE_ARUN_UID_HERE",        // ← replace with real UID from Firebase Auth
    },
    {
      "name": "Priya Sharma",
      "location": "Pune, Maharashtra",
      "image": "https://randomuser.me/api/portraits/women/44.jpg",
      "uid": "fAmiOclF3VTKSpg47y2bLzaLMTR2",
    },
    {
      "name": "Rajesh Singh",
      "location": "Bengaluru, Karnataka",
      "image": "https://randomuser.me/api/portraits/men/45.jpg",
      "uid": "PASTE_RAJESH_UID_HERE",
    },
    {
      "name": "Ananya Rao",
      "location": "Hyderabad, Telangana",
      "image": "https://randomuser.me/api/portraits/women/68.jpg",
      "uid": "PASTE_ANANYA_UID_HERE",
    },
    {
      "name": "Suresh G.",
      "location": "Chennai, Tamil Nadu",
      "image": "https://randomuser.me/api/portraits/men/75.jpg",
      "uid": "PASTE_SURESH_UID_HERE",
    },
  ];

  // Start or open existing chat with this profile
  Future<void> startChat(Map<String, String> profile) async {
    final uid = profile["uid"] ?? "";

    if (uid.isEmpty || uid.startsWith("PASTE_")) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("User ID not set for this profile yet")),
      );
      return;
    }

    try {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) =>
            const Center(child: CircularProgressIndicator()),
      );

      final chatId = await _chatService.getOrCreateChat(
        otherUserId: uid,
        createdFrom: "saved_profile",   // ← integration hook for later
        sourceId: uid,
      );

      Navigator.pop(context); // close loading

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => MessageScreen(
            chatId: chatId,
            otherUserId: uid,
            userName: profile["name"] ?? "User",
          ),
        ),
      );
    } catch (e) {
      Navigator.pop(context); // close loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to open chat: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, String>> filteredList = savedProfiles.where((profile) {
      return profile["name"]!
          .toLowerCase()
          .contains(searchController.text.toLowerCase());
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          "My Saved Profiles",
          style: TextStyle(color: Colors.black),
        ),
        centerTitle: true,
      ),

      body: Column(
        children: [

          // 🔍 Search Bar (unchanged)
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: searchController,
              onChanged: (value) => setState(() {}),
              decoration: InputDecoration(
                hintText: "Search profiles...",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // Profile List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: filteredList.length,
              itemBuilder: (context, index) {
                var profile = filteredList[index];

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFE8DD),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [

                      // Profile image (unchanged)
                      CircleAvatar(
                        radius: 30,
                        backgroundImage:
                            NetworkImage(profile["image"]!),
                      ),
                      const SizedBox(width: 16),

                      // Name + location (unchanged)
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              profile["name"]!,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(Icons.location_on,
                                    size: 16, color: Colors.grey),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    profile["location"]!,
                                    style: const TextStyle(color: Colors.grey),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // ✅ NEW: Message button
                      GestureDetector(
                        onTap: () => startChat(profile),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          margin: const EdgeInsets.only(right: 8),
                          decoration: const BoxDecoration(
                            color: Color(0xFFF4A825),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.message,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),

                      // ❤️ Remove button (unchanged)
                      GestureDetector(
                        onTap: () {
                          setState(() => savedProfiles.remove(profile));
                        },
                        child: const Icon(
                          Icons.favorite,
                          color: Colors.red,
                          size: 28,
                        ),
                      ),
                    ],
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