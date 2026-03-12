import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:share_plus/share_plus.dart';

class WorkerProfileScreen extends StatelessWidget {
  final String userId;

  const WorkerProfileScreen({
    super.key,
    required this.userId,
  });

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
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.black),
            onPressed: () {
              print("More options clicked");
            },
          )
        ],
      ),

      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection("users")
            .doc(userId)
            .get(),
        builder: (context, snapshot) {

          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          var data = snapshot.data!.data() as Map<String, dynamic>;

          String name = data["name"] ?? "User";
          String location = data["location"] ?? "Unknown";
          String about = data["about"] ?? "";
          String image = data["profileImage"] ??
              "https://randomuser.me/api/portraits/men/32.jpg";

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [

                const SizedBox(height: 10),

                /// PROFILE IMAGE
                GestureDetector(
                  onTap: () {
                    print("Profile image clicked");
                  },
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundImage: NetworkImage(image),
                      ),

                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: () {
                            print("Verified badge clicked");
                          },
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
                      )
                    ],
                  ),
                ),

                const SizedBox(height: 15),

                /// NAME
                GestureDetector(
                  onTap: () {
                    print("Name clicked");
                  },
                  child: Text(
                    name,
                    style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold),
                  ),
                ),

                const SizedBox(height: 6),

                /// LOCATION
                GestureDetector(
                  onTap: () {
                    print("Location clicked");
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.location_on,
                        size: 18,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        location,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                /// LIKE + SHARE
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [

                    GestureDetector(
                      onTap: () {
                        print("Liked profile");
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 25, vertical: 12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(30),
                          border:
                              Border.all(color: Colors.red, width: 2),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.favorite, color: Colors.red),
                            SizedBox(width: 8),
                            Text(
                              "Like",
                              style: TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.w600),
                            )
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(width: 15),

                    GestureDetector(
     onTap: () {
  final String profileLink =
      "localhire://profile/$userId";

  Share.share(
    "Check out this worker on LocalHire 👇\n\n$profileLink",
  );
},
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 25, vertical: 12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                              color: Color(0xFFEFB04C), width: 2),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.share,
                                color: Color(0xFFEFB04C)),
                            SizedBox(width: 8),
                            Text(
                              "Share",
                              style: TextStyle(
                                  color: Color(0xFFEFB04C),
                                  fontWeight: FontWeight.w600),
                            )
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 30),

                /// ABOUT
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

                GestureDetector(
                  onTap: () {
                    print("About clicked");
                  },
                  child: Text(
                    about,
                    style: const TextStyle(
                        color: Colors.black87,
                        height: 1.6),
                  ),
                ),

                const SizedBox(height: 25),

                /// STATS
                Row(
                  children: [

                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          print("Jobs provided clicked");
                        },
                        child: _statCard("156", "JOBS PROVIDED"),
                      ),
                    ),

                    const SizedBox(width: 15),

                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          print("Jobs completed clicked");
                        },
                        child: _statCard("142", "JOBS COMPLETED"),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 25),

                /// RATING
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
                    Icon(Icons.star_half, color: Color(0xFFEFB04C)),
                    SizedBox(width: 10),
                    Text(
                      "4.8",
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold),
                    ),
                    SizedBox(width: 6),
                    Text("(124 reviews)",
                        style: TextStyle(color: Colors.grey))
                  ],
                ),

                const SizedBox(height: 30),
              ],
            ),
          );
        },
      ),
    );
  }

  /// STAT CARD
  Widget _statCard(String number, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: const Color(0xFFF5EFE6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            number,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFFEFB04C),
            ),
          ),
          const SizedBox(height: 5),
          Text(label,
              style: const TextStyle(
                  fontSize: 12,
                  letterSpacing: 1)),
        ],
      ),
    );
  }
}

