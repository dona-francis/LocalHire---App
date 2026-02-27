import 'package:flutter/material.dart';
import 'add_job_screen.dart';

class Step6 extends StatelessWidget {
  final VoidCallback onNext; // kept but not used (to avoid breaking structure)
  final JobData jobData;

  const Step6({
    super.key,
    required this.onNext,
    required this.jobData,
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

                /// Progress Bar (All complete)
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

                /// SUMMARY CARD
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
              onPressed: () {
                Map<String, dynamic> newJob = {
                  "type": jobData.locationType.toUpperCase(),
                  "title": jobData.title,
                  "location": jobData.location,
                  "salary":jobData.budget,
                  "date": formatDate(jobData.date),
                  "time": "Just now",
                  "description": jobData.description,
                  "postedByName": "You",
                  "postedByImage":
                      "https://i.pravatar.cc/150?img=3",
                };

                Navigator.pop(context, newJob);
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