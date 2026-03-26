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

  late final String _currentUid;
  late final DocumentReference _savedRef;

  @override
  void initState() {
    super.initState();
    _currentUid = FirebaseAuth.instance.currentUser!.uid;
    _savedRef = FirebaseFirestore.instance
        .collection('users')
        .doc(_currentUid)
        .collection('saved_profiles')
        .doc(widget.userId);
  }

  Future<void> _toggleSave(
      String name, String image, bool currentlySaved) async {
    try {
      if (currentlySaved) {
        await _savedRef.delete();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Removed from saved profiles")),
          );
        }
      } else {
        await _savedRef.set({
          'uid': widget.userId,
          'name': name,
          'profileImage': image,
          'savedAt': FieldValue.serverTimestamp(),
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Profile saved ✅")),
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

  Future<void> _startChat(String name, String image) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
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

  // ── Fetch jobs provided (posted by this worker) ──
  Future<int> _fetchJobsProvided() async {
    final snap = await FirebaseFirestore.instance
        .collection('jobs')
        .where('postedBy', isEqualTo: widget.userId)
        .count()
        .get();
    return snap.count ?? 0;
  }

  // ── Fetch reviews and compute average rating ──
  Future<Map<String, dynamic>> _fetchReviewStats() async {
    final snap = await FirebaseFirestore.instance
        .collection('reviews')
        .where('toUserId', isEqualTo: widget.userId)
        .get();

    if (snap.docs.isEmpty) {
      return {'average': 0.0, 'count': 0};
    }

    final total = snap.docs
        .map((d) => (d['rating'] as num).toDouble())
        .reduce((a, b) => a + b);

    return {
      'average': total / snap.docs.length,
      'count': snap.docs.length,
    };
  }

  // ── Build star row from a double rating ──
  List<Widget> _buildStars(double rating) {
    List<Widget> stars = [];
    for (int i = 1; i <= 5; i++) {
      if (rating >= i) {
        stars.add(const Icon(Icons.star, color: Color(0xFFEFB04C)));
      } else if (rating >= i - 0.5) {
        stars.add(const Icon(Icons.star_half, color: Color(0xFFEFB04C)));
      } else {
        stars.add(const Icon(Icons.star_border, color: Color(0xFFEFB04C)));
      }
    }
    return stars;
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

      body: StreamBuilder<DocumentSnapshot>(
        stream: _savedRef.snapshots(),
        builder: (context, savedSnap) {
          final isSaved = savedSnap.data?.exists ?? false;

          return FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance
                .collection('users')
                .doc(widget.userId)
                .get(),
            builder: (context, profileSnap) {
              if (!profileSnap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final data =
                  profileSnap.data!.data() as Map<String, dynamic>;
              final name = data['name'] ?? 'User';
              final location = data['location'] ?? 'Unknown';
              final about = data['about'] ?? '';
              final image = data['profileImage'] ??
                  'https://randomuser.me/api/portraits/men/32.jpg';

              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
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

                    Text(
                      name,
                      style: const TextStyle(
                          fontSize: 24, fontWeight: FontWeight.bold),
                    ),

                    const SizedBox(height: 6),

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
                          onTap: () => _toggleSave(name, image, isSaved),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(
                                  color: Colors.green, width: 2),
                              color: isSaved
                                  ? Colors.green.withOpacity(0.10)
                                  : Colors.transparent,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
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
                                      fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(width: 10),

                        GestureDetector(
                          onTap: () => _startChat(name, image),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(30),
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
                                      fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(width: 10),

                        GestureDetector(
                          onTap: () {
                            Share.share(
                              "Check out this worker on LocalHire 👇\n\nlocalhire://profile/${widget.userId}",
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(
                                  color: Colors.grey.shade400, width: 2),
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
                            fontWeight: FontWeight.bold, fontSize: 18),
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

                    // ── Stats: Jobs Provided (live) ──
                    FutureBuilder<int>(
                      future: _fetchJobsProvided(),
                      builder: (context, jobsSnap) {
                        final jobsProvided =
                            jobsSnap.data?.toString() ?? '—';
                        return Row(
                          children: [
                            Expanded(
                              child: _statCard(jobsProvided, "JOBS PROVIDED"),
                            ),
                            const SizedBox(width: 15),
                            // Jobs completed — placeholder until you
                            // add a "status: completed" field to jobs
                            Expanded(
                              child: _statCard("—", "JOBS COMPLETED"),
                            ),
                          ],
                        );
                      },
                    ),

                    const SizedBox(height: 25),

                    // ── Rating (live) ──
                    FutureBuilder<Map<String, dynamic>>(
                      future: _fetchReviewStats(),
                      builder: (context, reviewSnap) {
                        if (!reviewSnap.hasData) {
                          return const Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              "Rating",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18),
                            ),
                          );
                        }

                        final avg =
                            (reviewSnap.data!['average'] as double);
                        final count =
                            reviewSnap.data!['count'] as int;
                        final avgDisplay =
                            avg == 0.0 ? "—" : avg.toStringAsFixed(1);

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Rating",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                ..._buildStars(avg),
                                const SizedBox(width: 10),
                                Text(
                                  avgDisplay,
                                  style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  "($count reviews)",
                                  style: const TextStyle(
                                      color: Colors.grey),
                                ),
                              ],
                            ),
                          ],
                        );
                      },
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
              style:
                  const TextStyle(fontSize: 12, letterSpacing: 1)),
        ],
      ),
    );
  }
}