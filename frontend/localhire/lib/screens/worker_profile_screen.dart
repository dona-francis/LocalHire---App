import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:share_plus/share_plus.dart';
import 'message_screen.dart';
import '../services/chat_service.dart';

class WorkerProfileScreen extends StatefulWidget {
  final String userId;

  const WorkerProfileScreen({
    super.key,
    required this.userId,
  });

  @override
  State<WorkerProfileScreen> createState() => _WorkerProfileScreenState();
}

class _WorkerProfileScreenState extends State<WorkerProfileScreen> {
  final ChatService _chatService = ChatService();

  // ── Cached once in initState — never re-evaluated ──
  late final String _currentUid;
  late final DocumentReference _savedRef;

  @override
  void initState() {
    super.initState();
    // Resolve uid and ref exactly once — no race condition
    _currentUid = FirebaseAuth.instance.currentUser!.uid;
    _savedRef = FirebaseFirestore.instance
        .collection('users')
        .doc(_currentUid)
        .collection('saved_profiles')
        .doc(widget.userId);
  }

  // ── Toggle save/unsave ──
  Future<void> _toggleSave(
      String name, String image, bool currentlySaved) async {
    try {
      if (currentlySaved) {
        await _savedRef.delete();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text("Removed from saved profiles")),
          );
        }
      } else {
        //  Write to Firestore — StreamBuilder reacts instantly
        await _savedRef.set({
          'uid': widget.userId,
          'name': name,
          'profileImage': image,
          'savedAt': FieldValue.serverTimestamp(),
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Profile saved successfully")),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      }
    }
  }

  // ── Open chat ──
  Future<void> _startChat(String name, String image) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) =>
            const Center(child: CircularProgressIndicator()),
      );

      final chatId = await _chatService.getOrCreateChat(
        otherUserId: widget.userId,
        otherUserName: name,
        otherUserImage: image,
        createdFrom: "worker_profile",
        sourceId: widget.userId,
      );

      if (mounted) Navigator.pop(context);
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MessageScreen(
              chatId: chatId,
              otherUserId: widget.userId,
              userName: name,
              userProfileImage: image,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to open chat: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Worker Profile",
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.black),
            onPressed: () {},
          ),
        ],
      ),

      // ── Outer StreamBuilder: save state ──
      // _savedRef is stable (late final) — stream never recreated
      body: StreamBuilder<DocumentSnapshot>(
        stream: _savedRef.snapshots(),
        builder: (context, savedSnap) {
          // ✅ While Firestore hasn't responded yet keep false
          // — no flicker, no null crash
          final isSaved = savedSnap.data?.exists ?? false;

          return FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance
                .collection('users')
                .doc(widget.userId)
                .get(),
            builder: (context, profileSnap) {
              if (!profileSnap.hasData) {
                return const Center(
                    child: CircularProgressIndicator());
              }

              final data = profileSnap.data!.data()
                  as Map<String, dynamic>;
              final name = data['name'] ?? 'User';
              final location = data['location'] ?? 'Unknown';
              final about = data['about'] ?? '';
              final image = data['profileImage'] ??
                  'https://randomuser.me/api/portraits/men/32.jpg';

              return SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    const SizedBox(height: 10),

                    // ── Profile Image ──
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 60,
                          backgroundImage: NetworkImage(image),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFFEFB04C),
                            ),
                            child: const Icon(
                              Icons.verified,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 15),

                    // ── Name ──
                    Text(
                      name,
                      style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold),
                    ),

                    const SizedBox(height: 6),

                    // ── Location ──
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.location_on,
                            size: 18, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          location,
                          style: const TextStyle(
                              color: Colors.grey, fontSize: 14),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // ── Save + Message + Share ──
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [

                      
                        GestureDetector(
                          onTap: () =>
                              _toggleSave(name, image, isSaved),
                          child: AnimatedContainer(
                            duration:
                                const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 12),
                            decoration: BoxDecoration(
                              borderRadius:
                                  BorderRadius.circular(30),
                              border: Border.all(
                                color: Colors.green,
                                width: 2,
                              ),
                              color: isSaved
                                  ? Colors.green.withOpacity(0.10)
                                  : Colors.transparent,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // ✅ Filled when saved, outlined when not
                                Icon(
                                  isSaved
                                      ? Icons.bookmark
                                      : Icons.bookmark_border,
                                  color: Colors.green,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  isSaved ? "Saved" : "Save",
                                  style: const TextStyle(
                                      color: Colors.green,
                                      fontWeight:
                                          FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(width: 10),

                        // 💬 Message button
                        GestureDetector(
                          onTap: () => _startChat(name, image),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 12),
                            decoration: BoxDecoration(
                              borderRadius:
                                  BorderRadius.circular(30),
                              border: Border.all(
                                  color: const Color(0xFFEFB04C),
                                  width: 2),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.message,
                                    color: Color(0xFFEFB04C)),
                                SizedBox(width: 8),
                                Text(
                                  "Message",
                                  style: TextStyle(
                                      color: Color(0xFFEFB04C),
                                      fontWeight:
                                          FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(width: 10),

                        // 🔗 Share button
                        GestureDetector(
                          onTap: () {
                            Share.share(
                              "Check out this worker on LocalHire 👇\n\nlocalhire://profile/${widget.userId}",
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              borderRadius:
                                  BorderRadius.circular(30),
                              border: Border.all(
                                  color: Colors.grey.shade400,
                                  width: 2),
                            ),
                            child: Icon(Icons.share,
                                color: Colors.grey.shade500),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 30),

                    // ── About ──
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "About",
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        about,
                        style: const TextStyle(
                            color: Colors.black87, height: 1.6),
                      ),
                    ),

                    const SizedBox(height: 25),

                    // ── Stats ──
                    Row(
                      children: [
                        Expanded(
                            child: _statCard(
                                "156", "JOBS PROVIDED")),
                        const SizedBox(width: 15),
                        Expanded(
                            child: _statCard(
                                "142", "JOBS COMPLETED")),
                      ],
                    ),

                    const SizedBox(height: 25),

                    // ── Rating ──
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Rating",
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Row(
                      children: [
                        Icon(Icons.star, color: Color(0xFFEFB04C)),
                        Icon(Icons.star, color: Color(0xFFEFB04C)),
                        Icon(Icons.star, color: Color(0xFFEFB04C)),
                        Icon(Icons.star, color: Color(0xFFEFB04C)),
                        Icon(Icons.star_half,
                            color: Color(0xFFEFB04C)),
                        SizedBox(width: 10),
                        Text("4.8",
                            style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold)),
                        SizedBox(width: 6),
                        Text("(124 reviews)",
                            style: TextStyle(color: Colors.grey)),
                      ],
                    ),

                    const SizedBox(height: 30),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _statCard(String number, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: const Color(0xFFF5EFE6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(number,
              style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFEFB04C))),
          const SizedBox(height: 5),
          Text(label,
              style: const TextStyle(
                  fontSize: 12, letterSpacing: 1)),
        ],
      ),
    );
  }
}