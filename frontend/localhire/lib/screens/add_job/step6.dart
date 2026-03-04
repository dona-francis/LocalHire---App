import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'add_job_screen.dart';

class Step6 extends StatelessWidget {
  final VoidCallback onNext;
  final JobData jobData;
  final String userId;

  const Step6({
    super.key,
    required this.onNext,
    required this.jobData,
    required this.userId,
  });

  String formatDate(DateTime? date) {
    if (date == null) return "Not Selected";
    return "${date.day}/${date.month}/${date.year}";
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: List.generate(
                    6,
                    (index) => Expanded(
                      child: Container(
                        margin:
                            const EdgeInsets.symmetric(horizontal: 2),
                        height: 6,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF2B84B),
                          borderRadius:
                              BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                const Text(
                  "Review Task Summary",
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                const Text(
                  "Please check all details before posting.",
                  style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey),
                ),
                const SizedBox(height: 30),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius:
                        BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      summaryItem(
                        "Job Title",
                        jobData.title.isEmpty
                            ? "Not Provided"
                            : jobData.title,
                      ),
                      summaryItem(
                        "Description",
                        jobData.description.isEmpty
                            ? "Not Provided"
                            : jobData.description,
                      ),
                      summaryItem(
                        "Location",
                        "${jobData.locationType.toUpperCase()} - ${jobData.location}",
                      ),
                      summaryItem(
                        "Date",
                        formatDate(jobData.date),
                      ),
                      summaryItem(
                        "Budget",
                        "₹${jobData.budget}",
                        isBold: true,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        /// POST BUTTON
        Padding(
          padding: const EdgeInsets.all(20),
          child: SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              onPressed: () async {
           try{
  

                  await FirebaseFirestore.instance
                      .collection("jobs")
                      .add({
                    "type": jobData.locationType.toUpperCase(),
                    "title": jobData.title,
                    "location": jobData.location,
                    "salary": jobData.budget,
                    "date": formatDate(jobData.date),
                    "description": jobData.description,
                    "postedBy": userId,
                    "createdAt": FieldValue.serverTimestamp(),
                  });

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Job Posted Successfully"),
                    ),
                  );

                  Navigator.pop(context); // Go back
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Error: $e"),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF2B84B),
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(20),
                ),
              ),
              child: const Text(
                "Post Task",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget summaryItem(String title, String value,
      {bool isBold = false}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.white,
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontSize: 11,
              fontWeight:
                  FontWeight.w600,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize:
                  isBold ? 20 : 14,
              fontWeight: isBold
                  ? FontWeight.bold
                  : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}