import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';

class UsersScreen extends StatelessWidget {
  const UsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Users")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (context, snapshot) {

          if (snapshot.hasError) {
            return const Center(child: Text("Error loading users"));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No users found"));
          }

          final users = snapshot.data!.docs;

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final doc = users[index];
              final data = doc.data() as Map<String, dynamic>;

              return Card(
                margin: const EdgeInsets.all(10),
                elevation: 3,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      // 👤 NAME + PHONE
                      Text(
                        data['name'] ?? 'No Name',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(data['phone'] ?? ''),

                      const SizedBox(height: 12),

                      // 🖼 PROFILE IMAGE (NO CROPPING)
                      if (data['profileImage'] != null && data['profileImage'] != "")
                        Container(
                          height: 160,
                          width: double.infinity,
                          color: Colors.grey[200],
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: CachedNetworkImage(
                              imageUrl: data['profileImage'],
                              fit: BoxFit.contain, // ✅ FIXED
                              placeholder: (context, url) =>
                                  const Center(child: CircularProgressIndicator()),
                              errorWidget: (context, url, error) =>
                                  const Center(
                                    child: Text(
                                      "❌ Failed to load profile image",
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ),
                            ),
                          ),
                        ),

                      const SizedBox(height: 12),

                      // 🪪 ID PROOF (FULL VISIBLE)
                      if (data['idProof'] != null && data['idProof'] != "")
                        Container(
                          height: 220,
                          width: double.infinity,
                          color: Colors.grey[200],
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: CachedNetworkImage(
                              imageUrl: data['idProof'],
                              fit: BoxFit.contain, // ✅ FIXED
                              placeholder: (context, url) =>
                                  const Center(child: CircularProgressIndicator()),
                              errorWidget: (context, url, error) =>
                                  const Center(
                                    child: Text(
                                      "❌ Failed to load ID proof",
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ),
                            ),
                          ),
                        ),

                      const SizedBox(height: 12),

                      // 🚨 BAN STATUS
                      Text(
                        data['isBanned'] == true
                            ? "🚫 BANNED"
                            : "✅ ACTIVE",
                        style: TextStyle(
                          color: data['isBanned'] == true
                              ? Colors.red
                              : Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 10),

                      // 🚫 BAN / UNBAN
                      Row(
                        children: [
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                            ),
                            onPressed: () async {
                              await FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(doc.id)
                                  .update({'isBanned': true});

                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("User Banned 🚫")),
                              );
                            },
                            child: const Text("Ban User"),
                          ),

                          const SizedBox(width: 10),

                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                            ),
                            onPressed: () async {
                              await FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(doc.id)
                                  .update({'isBanned': false});

                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("User Unbanned ✅")),
                              );
                            },
                            child: const Text("Unban"),
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
      ),
    );
  }
}