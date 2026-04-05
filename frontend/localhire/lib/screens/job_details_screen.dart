import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'apply_screen.dart';
import 'worker_profile_screen.dart';

class JobDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> job;
  final String? currentUserId; // pass the logged-in user's ID

  const JobDetailsScreen({
    super.key,
    required this.job,
    this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    final String jobId = job["jobId"] ?? "";
    final String employerId = job["postedBy"] ?? "";

    return Scaffold(
      appBar: AppBar(
        title: const Text("Job Details"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      backgroundColor: const Color(0xFFF5F5F5),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // JOB TITLE
                  Text(
                    job["title"] ?? "No Title",
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 15),

                  // POSTED BY
                  FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance
                        .collection("users")
                        .doc(employerId)
                        .get(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final user =
                          snapshot.data!.data() as Map<String, dynamic>;
                      final name = user["name"] ?? "User";
                      final image = user["profileImageUrl"] ??
                          user["profileImage"] ??
                          "";

                      return GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                WorkerProfileScreen(userId: employerId),
                          ),
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 25,
                                backgroundColor: Colors.grey.shade200,
                                backgroundImage: image.isNotEmpty
                                    ? NetworkImage(image)
                                    : null,
                                child: image.isEmpty
                                    ? const Icon(Icons.person,
                                        color: Colors.grey)
                                    : null,
                              ),
                              const SizedBox(width: 15),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text("POSTED BY",
                                      style: TextStyle(
                                          fontSize: 12, color: Colors.grey)),
                                  const SizedBox(height: 4),
                                  Text(name,
                                      style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold)),
                                ],
                              ),
                              const Spacer(),
                              const Icon(Icons.arrow_forward_ios, size: 16),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 15),

                  Text(
                    job["type"] ?? "",
                    style: TextStyle(
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500),
                  ),

                  const SizedBox(height: 20),

                  _buildCard("Location", job["location"] ?? "Not specified"),
                  _buildCard("Salary", "₹ ${job["salary"] ?? "0"}"),
                  _buildCard("Date", job["date"] ?? ""),
                  _buildCard(
                    "Posted",
                    job["createdAt"] != null && job["createdAt"] is Timestamp
                        ? _formatTimestamp(job["createdAt"])
                        : "Not available",
                  ),
                  _buildCard(
                      "Description", job["description"] ?? "Not provided"),
                ],
              ),
            ),
          ),

          // APPLY BUTTON — hidden if viewer is the poster
          if (currentUserId != null && currentUserId != employerId)
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFB54A),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  onPressed: () {
                    print("JOB ID:$jobId");
                    print("WORKER ID: $currentUserId");
                    print("EMPLOYER ID: $employerId");
                    if (jobId.isEmpty || currentUserId!.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text("Unable to apply. Missing job info.")),
                      );
                      return;
                    }
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ApplyScreen(
                          jobId: jobId,
                          workerId: currentUserId!,
                          employerId: employerId,
                        ),
                      ),
                    );
                  },
                  child: const Text("Apply",
                      style: TextStyle(fontSize: 18)),
                ),
              ),
            ),

          // If currentUserId is null, still show Apply (fallback, no Firestore write blocked)
          if (currentUserId == null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFB54A),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text("Please log in to apply.")),
                    );
                  },
                  child: const Text("Apply", style: TextStyle(fontSize: 18)),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCard(String title, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(width: 10),
          Flexible(child: Text(value, softWrap: true)),
        ],
      ),
    );
  }

  String _formatTimestamp(Timestamp timestamp) {
    final date = timestamp.toDate();
    return "${date.day.toString().padLeft(2, '0')}-"
        "${date.month.toString().padLeft(2, '0')}-"
        "${date.year}";
  }
}