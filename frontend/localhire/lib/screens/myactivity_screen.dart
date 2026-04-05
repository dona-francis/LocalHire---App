import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'job_details_screen.dart';
import 'worker_profile_screen.dart';

class MyActivityScreen extends StatefulWidget {
  final String userId;
  const MyActivityScreen({super.key, required this.userId});

  @override
  State<MyActivityScreen> createState() => _MyActivityScreenState();
}

class _MyActivityScreenState extends State<MyActivityScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedTab = 0;

  final List<String> _tabs = ["Posted Jobs", "Applied Jobs", "Completed","Requests"];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      setState(() => _selectedTab = _tabController.index);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F0E8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F0E8),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFFB8860B)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "My Activity",
          style: TextStyle(
            color: Color(0xFFB8860B),
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 8),
          SizedBox(
            height: 48,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _tabs.length,
              itemBuilder: (context, index) {
                final selected = _selectedTab == index;
                return GestureDetector(
                  onTap: () => _tabController.animateTo(index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(right: 10),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: selected ? Colors.white : Colors.transparent,
                      border: Border.all(
                        color: selected
                            ? const Color(0xFFFFB544)
                            : Colors.grey.shade300,
                        width: selected ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: Text(
                      _tabs[index],
                      style: TextStyle(
                        fontWeight:
                            selected ? FontWeight.bold : FontWeight.normal,
                        color: selected ? Colors.black : Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _PostedJobsTab(userId: widget.userId, showCompleted: false),
                _AppliedJobsTab(userId: widget.userId),
                _PostedJobsTab(userId: widget.userId, showCompleted: true),
                _RequestsTab(userId: widget.userId),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
// ─────────────────────────────────────────────────────────
// Tab 4 — Requests (NEW)
// ─────────────────────────────────────────────────────────

class _RequestsTab extends StatefulWidget {
  final String userId;
  const _RequestsTab({required this.userId});

  @override
  State<_RequestsTab> createState() => _RequestsTabState();
}

class _RequestsTabState extends State<_RequestsTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection("applications")
          .where("employerId", isEqualTo: widget.userId)
          .where("status", isEqualTo: "pending")
          .snapshots(), // ✅ NO orderBy (stable)

      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFFFFB544)),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _emptyState(
            icon: Icons.notifications_none,
            message: "No requests at the moment.",
          );
        }

        final requests = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final data =
                requests[index].data() as Map<String, dynamic>;

            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection("jobs")
                  .doc(data["jobId"])
                  .get(),
              builder: (context, jobSnap) {
                String jobTitle = "Job";

                if (jobSnap.hasData && jobSnap.data!.exists) {
                  final jobData =
                      jobSnap.data!.data() as Map<String, dynamic>;
                  jobTitle = jobData["title"] ?? "Job";
                }

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 🧾 JOB TITLE
                        Text(
                          jobTitle,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),

                        const SizedBox(height: 6),

                        // 👤 WORKER NAME
                        FutureBuilder<DocumentSnapshot>(
                          future: FirebaseFirestore.instance
                              .collection("users")
                              .doc(data["workerId"])
                              .get(),
                          builder: (context, userSnap) {
                            String name = "Worker";

                            if (userSnap.hasData &&
                                userSnap.data!.exists) {
                              final userData = userSnap.data!.data()
                                  as Map<String, dynamic>;
                              name = userData["name"] ?? "Worker";
                            }

                            return Text(
                              name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: 6),

                        // 💬 ENQUIRY MESSAGE (FIXED)
                        Text(
                          (data["question"] ?? "").isNotEmpty
                              ? data["question"]
                              : "No message",
                        ),

                        const SizedBox(height: 10),

                        // 📅 DATE
                        if ((data["preferredDate"] ?? "").isNotEmpty)
                          Text("📅 Date: ${data["preferredDate"]}"),

                        // ⏰ TIME
                        if ((data["preferredTime"] ?? "").isNotEmpty)
                          Text("⏰ Time: ${data["preferredTime"]}"),

                        // 💰 RATE
                        if ((data["proposedRate"] ?? "").isNotEmpty)
                          Text("💰 Rate: ₹${data["proposedRate"]}"),

                        const SizedBox(height: 12),

                        // ✅ ACTION BUTTONS
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                ),
                                onPressed: () async {
  final workerId = data["workerId"];
  final jobId = data["jobId"];

  // 1. Accept this application
  await FirebaseFirestore.instance
      .collection("applications")
      .doc(requests[index].id)
      .update({"status": "accepted"});

  // 2. Add worker to job
  await FirebaseFirestore.instance
      .collection("jobs")
      .doc(jobId)
      .update({
    "acceptedBy": FieldValue.arrayUnion([workerId]),
    "status": "assigned"
  });

  // 3. Reject others
  final otherApps = await FirebaseFirestore.instance
      .collection("applications")
      .where("jobId", isEqualTo: jobId)
      .get();

  for (var doc in otherApps.docs) {
    if (doc.id != requests[index].id) {
      await doc.reference.update({"status": "denied"});
    }
  }
},
                                child: const Text("Accept"),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                ),
                                onPressed: () async {
                                  await FirebaseFirestore.instance
                                      .collection("applications")
                                      .doc(requests[index].id)
                                      .update({"status": "denied"});
                                },
                                child: const Text("Deny"),
                              ),
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
        );
      },
    );
  }
}
  
// ─────────────────────────────────────────────────────────
// Tab 1 & 3 — Posted Jobs
// ─────────────────────────────────────────────────────────
class _PostedJobsTab extends StatefulWidget {
  final String userId;
  final bool showCompleted;
  const _PostedJobsTab({required this.userId, required this.showCompleted});

  @override
  State<_PostedJobsTab> createState() => _PostedJobsTabState();
}

class _PostedJobsTabState extends State<_PostedJobsTab>
    with AutomaticKeepAliveClientMixin {
  List<QueryDocumentSnapshot> _lastKnownDocs = [];

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection("jobs")
          .where("postedBy", isEqualTo: widget.userId)
          .orderBy("createdAt", descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
          _lastKnownDocs = snapshot.data!.docs;
        }

        if (_lastKnownDocs.isEmpty &&
            snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: Color(0xFFFFB544)));
        }

        final docs = _lastKnownDocs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final status =
              (data["status"] ?? "active").toString().toLowerCase();
          if (widget.showCompleted) return status == "completed";
          return status != "completed";
        }).toList();

        if (docs.isEmpty &&
            snapshot.connectionState == ConnectionState.active) {
          return _emptyState(
            icon: widget.showCompleted
                ? Icons.check_circle_outline
                : Icons.work_outline,
            message: widget.showCompleted
                ? "No completed jobs yet."
                : "You haven't posted any jobs yet.",
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final docId = docs[index].id;
            return _PostedJobCard(
                job: data, docId: docId, userId: widget.userId);
          },
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────
// Tab 2 — Applied Jobs (streams from applications collection)
// ─────────────────────────────────────────────────────────

class _AppliedJobsTab extends StatefulWidget {
  final String userId;
  const _AppliedJobsTab({required this.userId});

  @override
  State<_AppliedJobsTab> createState() => _AppliedJobsTabState();
}

class _AppliedJobsTabState extends State<_AppliedJobsTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection("applications")
          .where("workerId", isEqualTo: widget.userId)
          .orderBy("createdAt", descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: Color(0xFFFFB544)));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _emptyState(
            icon: Icons.assignment_outlined,
            message: "You haven't applied to any jobs yet.",
          );
        }

        final applications = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: applications.length,
          itemBuilder: (context, index) {
            final appData =
                applications[index].data() as Map<String, dynamic>;
            final appId = applications[index].id;
            return _AppliedJobCard(
              appId: appId,
              appData: appData,
              userId: widget.userId,
            );
          },
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────
// Posted Job Card
// ─────────────────────────────────────────────────────────
class _PostedJobCard extends StatelessWidget {
  final Map<String, dynamic> job;
  final String docId;
  final String userId;

  const _PostedJobCard(
      {required this.job, required this.docId, required this.userId});

  @override
  Widget build(BuildContext context) {
    final String title = job["title"] ?? "No Title";
    final String location = job["location"] ?? "No Location";
    final String status =
        (job["status"] ?? "active").toString().toUpperCase();
    final bool isCompleted = status == "COMPLETED";
    final dynamic dateValue = job["date"];
    String formattedDate = "";
    if (dateValue != null) {
      if (dateValue is Timestamp) {
        final d = dateValue.toDate();
        formattedDate = "${_monthName(d.month)} ${d.day}, ${d.year}";
      } else if (dateValue is String) {
        formattedDate = dateValue;
      }
    }

    return GestureDetector(

  onTap: () {
     final acceptedBy = job["acceptedBy"] ?? [];
     final docId = job["jobId"] ?? "";
  if (isCompleted) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => JobDetailsScreen(
          job: {
            ..._prepareJob(job),
            "jobId": docId, // needed for details
          },
          currentUserId: userId,
        ),
      ),
    );
  } else {
    _showApplicantsSheet(context, docId);
  }
},
  
    

      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F0E8),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isCompleted
                        ? Colors.grey.shade600
                        : const Color(0xFFB8860B),
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(title,
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.location_on_outlined,
                      size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(location,
                        style: const TextStyle(
                            fontSize: 14, color: Colors.black87),
                        overflow: TextOverflow.ellipsis),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              if (formattedDate.isNotEmpty)
                Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined,
                        size: 15, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(formattedDate,
                        style: const TextStyle(
                            fontSize: 14, color: Colors.black87)),
                  ],
                ),
              const SizedBox(height: 14),
              const Divider(height: 1),
              const SizedBox(height: 14),
              if (isCompleted) ...[
                Row(
                  children: [
                    const Icon(Icons.star_rounded,
                        color: Color(0xFFFFB544), size: 22),
                    const SizedBox(width: 6),
                    Text(
                      job["review"] ?? "Excellent service!",
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                    const Spacer(),
                    const Text(
                      "View Details",
                      style: TextStyle(
                          color: Color(0xFFB8860B),
                          fontWeight: FontWeight.w600,
                          fontSize: 14),
                    ),
                  ],
                ),
              ] else ...[
                _LiveApplicantFooter(jobDocId: docId),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showApplicantsSheet(BuildContext context, String docId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _ApplicantsBottomSheet(jobDocId: docId),
    );
  }

  Map<String, dynamic> _prepareJob(Map<String, dynamic> job) {
    return {
      ...job,
      "date": job["date"] is Timestamp
          ? (job["date"] as Timestamp)
              .toDate()
              .toLocal()
              .toString()
              .split(' ')[0]
          : (job["date"] ?? ""),
    };
  }

  String _monthName(int month) {
    const months = [
      "",
      "Jan",
      "Feb",
      "Mar",
      "Apr",
      "May",
      "Jun",
      "Jul",
      "Aug",
      "Sep",
      "Oct",
      "Nov",
      "Dec"
    ];
    return months[month];
  }
}

// ─────────────────────────────────────────────────────────
// Live applicant count footer
// ─────────────────────────────────────────────────────────
class _LiveApplicantFooter extends StatelessWidget {
  final String jobDocId;
  const _LiveApplicantFooter({required this.jobDocId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection("applications")
          .where("jobId", isEqualTo: jobDocId)
          .snapshots(),
      builder: (context, snapshot) {
        final count = snapshot.data?.docs.length ?? 0;
        final workerIds = snapshot.data?.docs
                .map((d) =>
                    (d.data() as Map<String, dynamic>)["workerId"]
                        ?.toString() ??
                    "")
                .where((id) => id.isNotEmpty)
                .toList() ??
            [];

        return Row(
          children: [
            if (count > 0) ...[
              _ApplicantAvatarStack(applicantIds: workerIds),
              const SizedBox(width: 10),
              Text(
                "$count applicant${count == 1 ? '' : 's'}",
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
            ] else ...[
              const Icon(Icons.hourglass_empty, size: 16, color: Colors.grey),
              const SizedBox(width: 6),
              Text(
                "No applicants yet",
                style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
              ),
            ],
            const Spacer(),
            if (count > 0)
              Row(
                children: [
                  Text(
                    "View",
                    style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(width: 2),
                  Icon(Icons.arrow_forward_ios,
                      size: 12, color: Colors.grey.shade500),
                ],
              ),
          ],
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────
// Applied Job Card
// The parent StreamBuilder in _AppliedJobsTab already streams
// real-time application docs, so appData here is always fresh.
// We only FutureBuilder the job doc (rarely changes).
// ─────────────────────────────────────────────────────────
class _AppliedJobCard extends StatelessWidget {
  final String appId;
  final Map<String, dynamic> appData;
  final String userId;

  const _AppliedJobCard({
    super.key, 
    required this.appId,
    required this.appData,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    final String jobId = appData["jobId"] ?? "";
    // Status comes from the live-streamed appData — always up to date
    final String appStatus = (appData["status"] ?? "pending").toString();
    final bool isAccepted = appStatus.toLowerCase() == "accepted";
    final bool isDenied = appStatus.toLowerCase() == "denied";

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection("jobs").doc(jobId).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Color(0xFFFFB544))),
          );
        }

        if (!snapshot.data!.exists) return const SizedBox.shrink();

        final job = snapshot.data!.data() as Map<String, dynamic>;
        final String title = job["title"] ?? "No Title";
        final String location = job["location"] ?? "No Location";
        final String postedBy = job["postedBy"] ?? "";
        final dynamic dateValue = job["date"];
        String formattedDate = "";
        if (dateValue != null) {
          if (dateValue is Timestamp) {
            final d = dateValue.toDate();
            formattedDate = "${_monthName(d.month)} ${d.day}, ${d.year}";
          } else if (dateValue is String) {
            formattedDate = dateValue;
          }
        }

        final jobForDetails = {
          ...job,
          "jobId": jobId,
          "date": job["date"] is Timestamp
              ? (job["date"] as Timestamp)
                  .toDate()
                  .toLocal()
                  .toString()
                  .split(' ')[0]
              : (job["date"] ?? ""),
        };

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            // Subtle border indicating final status
            border: isAccepted
                ? Border.all(
                    color: const Color(0xFF27AE60).withOpacity(0.4),
                    width: 1.5)
                : isDenied
                    ? Border.all(color: Colors.grey.shade300, width: 1.5)
                    : null,
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Status badge ──
                Row(
                  children: [_ApplicationStatusBadge(status: appStatus)],
                ),
                const SizedBox(height: 12),

                Text(title,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),

                Row(
                  children: [
                    const Icon(Icons.location_on_outlined,
                        size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(location,
                          style: const TextStyle(
                              fontSize: 14, color: Colors.black87),
                          overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),

                if (formattedDate.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined,
                          size: 15, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(formattedDate,
                          style: const TextStyle(
                              fontSize: 14, color: Colors.black87)),
                    ],
                  ),
                ],

                const SizedBox(height: 14),
                const Divider(height: 1),
                const SizedBox(height: 14),

                // ── Bottom row: employer + Details button ──
                Row(
                  children: [
                    if (postedBy.isNotEmpty)
                      _EmployerProfileRow(
                        employerId: postedBy,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                WorkerProfileScreen(userId: postedBy),
                          ),
                        ),
                      ),
                    const Spacer(),
                    // "Details" button — only shown when employer has decided
                    if (isAccepted || isDenied)
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isAccepted
                              ? const Color(0xFF27AE60)
                              : Colors.grey.shade600,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 10),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => JobDetailsScreen(
                              job: jobForDetails,
                              currentUserId: userId,
                            ),
                          ),
                        ),
                        child: const Text("Details",
                            style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                  ],
                ),

                // ── Accepted congratulations banner ──
                if (isAccepted) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F8EF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.celebration_rounded,
                            size: 16, color: Color(0xFF27AE60)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "Congratulations! Your application was accepted.",
                            style: TextStyle(
                                fontSize: 12,
                                color: Colors.green.shade700,
                                height: 1.4,
                                fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // ── Denied info banner ──
                if (isDenied) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline,
                            size: 16, color: Colors.grey.shade500),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "Sorry, someone else has already been chosen for this spot.",
                            style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                                height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  String _monthName(int month) {
    const months = [
      "",
      "Jan",
      "Feb",
      "Mar",
      "Apr",
      "May",
      "Jun",
      "Jul",
      "Aug",
      "Sep",
      "Oct",
      "Nov",
      "Dec"
    ];
    return months[month];
  }
}

// ─────────────────────────────────────────────────────────
// Application status badge
// ─────────────────────────────────────────────────────────
class _ApplicationStatusBadge extends StatelessWidget {
  final String status;
  const _ApplicationStatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color textColor;
    Color borderColor;
    IconData icon;
    String label;

    switch (status.toLowerCase()) {
      case "accepted":
        bgColor = const Color(0xFFE8F8EF);
        textColor = const Color(0xFF27AE60);
        borderColor = const Color(0xFF27AE60);
        icon = Icons.check_circle_rounded;
        label = "Accepted";
        break;
      case "denied":
        bgColor = Colors.grey.shade100;
        textColor = Colors.grey.shade600;
        borderColor = Colors.grey.shade400;
        icon = Icons.cancel_outlined;
        label = "Not Selected";
        break;
      default: // pending
        bgColor = const Color(0xFFFFF8EC);
        textColor = const Color(0xFFB8860B);
        borderColor = const Color(0xFFFFB544);
        icon = Icons.hourglass_top_rounded;
        label = "Pending Review";
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor.withOpacity(0.5), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: textColor,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Applicant avatar stack
// ─────────────────────────────────────────────────────────
class _ApplicantAvatarStack extends StatelessWidget {
  final List applicantIds;
  const _ApplicantAvatarStack({required this.applicantIds});

  @override
  Widget build(BuildContext context) {
    final displayCount = applicantIds.length > 3 ? 3 : applicantIds.length;
    final extra = applicantIds.length - displayCount;

    return SizedBox(
      height: 36,
      width: displayCount * 24.0 + (extra > 0 ? 36 : 0) + 12,
      child: Stack(
        children: [
          ...List.generate(displayCount, (i) {
            return Positioned(
              left: i * 24.0,
              child:
                  _UserAvatar(userId: applicantIds[i].toString(), size: 36),
            );
          }),
          if (extra > 0)
            Positioned(
              left: displayCount * 24.0,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFB544),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Center(
                  child: Text(
                    "+$extra",
                    style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// User avatar
// ─────────────────────────────────────────────────────────
class _UserAvatar extends StatelessWidget {
  final String userId;
  final double size;
  const _UserAvatar({required this.userId, this.size = 40});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future:
          FirebaseFirestore.instance.collection("users").doc(userId).get(),
      builder: (context, snap) {
        String? photoUrl;
        if (snap.hasData && snap.data!.exists) {
          final data = snap.data!.data() as Map<String, dynamic>;
          photoUrl = data["profileImageUrl"] as String?;
        }
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
          ),
          child: ClipOval(
            child: photoUrl != null && photoUrl.isNotEmpty
                ? Image.network(photoUrl, fit: BoxFit.cover)
                : Container(
                    color: Colors.grey.shade300,
                    child: const Icon(Icons.person, color: Colors.white),
                  ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────
// Applicants bottom sheet
// ─────────────────────────────────────────────────────────
class _ApplicantsBottomSheet extends StatelessWidget {
  final String jobDocId;
  const _ApplicantsBottomSheet({required this.jobDocId});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      expand: false,
      builder: (_, scrollController) {
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection("applications")
              .where("jobId", isEqualTo: jobDocId)
              .orderBy("createdAt", descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            final docs = snapshot.data?.docs ?? [];

            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Drag handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Header
                  Row(
                    children: [
                      const Text(
                        "Applicants",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFB544).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          "${docs.length}",
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFB8860B)),
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  if (snapshot.connectionState == ConnectionState.waiting)
                    const Expanded(
                      child: Center(
                        child: CircularProgressIndicator(
                            color: Color(0xFFFFB544)),
                      ),
                    )
                  else if (docs.isEmpty)
                    const Expanded(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.people_outline,
                                size: 56, color: Colors.grey),
                            SizedBox(height: 12),
                            Text(
                              "No applicants yet.",
                              style:
                                  TextStyle(color: Colors.grey, fontSize: 15),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    Expanded(
                      child: ListView.separated(
                        controller: scrollController,
                        itemCount: docs.length,
                        separatorBuilder: (_, __) =>
                            const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final appDoc = docs[index];
                          final appData =
                              appDoc.data() as Map<String, dynamic>;
                          final workerId =
                              appData["workerId"]?.toString() ?? "";
                          final currentStatus =
                              (appData["status"] ?? "pending").toString();

                          return _ApplicantActionTile(
                            userId: workerId,
                            jobDocId: jobDocId,
                            currentStatus: currentStatus,
                            onViewProfile: () {
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      WorkerProfileScreen(userId: workerId),
                                ),
                              );
                            },
                            onAccept: () => _confirmAction(
                              context: context,
                              title: "Accept Application",
                              message:
                                  "Are you sure you want to accept this applicant?",
                              confirmLabel: "Accept",
                              confirmColor: const Color(0xFF27AE60),
                              onConfirmed: () => _updateStatus(
                                  context, appDoc.reference, "accepted"),
                            ),
                            onDeny: () => _confirmAction(
                              context: context,
                              title: "Deny Application",
                              message:
                                  "Are you sure you want to mark this applicant as not selected?",
                              confirmLabel: "Deny",
                              confirmColor: Colors.redAccent,
                              onConfirmed: () => _updateStatus(
                                  context, appDoc.reference, "denied"),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// Stylish confirmation dialog overlay
  void _confirmAction({
    required BuildContext context,
    required String title,
    required String message,
    required String confirmLabel,
    required Color confirmColor,
    required VoidCallback onConfirmed,
  }) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => Dialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon circle
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: confirmColor.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  confirmLabel == "Accept"
                      ? Icons.check_circle_outline_rounded
                      : Icons.cancel_outlined,
                  color: confirmColor,
                  size: 34,
                ),
              ),
              const SizedBox(height: 16),

              Text(
                title,
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),

              Text(
                message,
                style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                    height: 1.5),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding:
                            const EdgeInsets.symmetric(vertical: 13),
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () => Navigator.pop(dialogContext),
                      child: Text(
                        "Cancel",
                        style: TextStyle(
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: confirmColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding:
                            const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () {
                        Navigator.pop(dialogContext);
                        onConfirmed();
                      },
                      child: Text(
                        confirmLabel,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _updateStatus(
    BuildContext context,
    DocumentReference ref,
    String newStatus,
  ) async {
    try {
      await ref.update({"status": newStatus});
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(newStatus == "accepted"
                ? "Application accepted!"
                : "Marked as not selected."),
            backgroundColor: newStatus == "accepted"
                ? Colors.green
                : Colors.grey.shade700,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to update: $e"),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }
}

// ─────────────────────────────────────────────────────────
// Applicant action tile
// ─────────────────────────────────────────────────────────
class _ApplicantActionTile extends StatelessWidget {
  final String userId;
  final String jobDocId;
  final String currentStatus;
  final VoidCallback onViewProfile;
  final VoidCallback onAccept;
  final VoidCallback onDeny;

  const _ApplicantActionTile({
    required this.userId,
    required this.jobDocId,
    required this.currentStatus,
    required this.onViewProfile,
    required this.onAccept,
    required this.onDeny,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection("users")
          .doc(userId)
          .get(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Color(0xFFFFB544))),
          );
        }

        final data = snap.data!.data() as Map<String, dynamic>? ?? {};
        final name = data["name"] ?? data["displayName"] ?? "Unknown";
        final photoUrl = data["profileImageUrl"] as String?;
        final String profession =
            data["profession"] ?? data["jobTitle"] ?? "";

        Color statusColor;
        String statusLabel;
        switch (currentStatus.toLowerCase()) {
          case "accepted":
            statusColor = const Color(0xFF27AE60);
            statusLabel = "Accepted";
            break;
          case "denied":
            statusColor = Colors.grey;
            statusLabel = "Not Selected";
            break;
          default:
            statusColor = const Color(0xFFB8860B);
            statusLabel = "Pending";
        }

        // Lock buttons once a decision has been made
        final bool isDecided = currentStatus.toLowerCase() == "accepted" ||
            currentStatus.toLowerCase() == "denied";

        return InkWell(
          onTap: onViewProfile,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Avatar
                GestureDetector(
                  onTap: onViewProfile,
                  child: CircleAvatar(
                    radius: 26,
                    backgroundColor: Colors.grey.shade200,
                    backgroundImage:
                        (photoUrl != null && photoUrl.isNotEmpty)
                            ? NetworkImage(photoUrl)
                            : null,
                    child: (photoUrl == null || photoUrl.isEmpty)
                        ? const Icon(Icons.person,
                            color: Colors.grey, size: 26)
                        : null,
                  ),
                ),
                const SizedBox(width: 12),

                // Name + profession + status pill
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 15)),
                      if (profession.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(profession,
                            style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600)),
                      ],
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: statusColor.withOpacity(0.4),
                              width: 1),
                        ),
                        child: Text(
                          statusLabel,
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: statusColor),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // Action buttons — replaced by status icon once decided
                if (!isDecided) ...[
                  _ActionButton(
                    label: "Accept",
                    icon: Icons.check_rounded,
                    color: const Color(0xFF2ECC71),
                    onTap: onAccept,
                  ),
                  const SizedBox(width: 6),
                  _ActionButton(
                    label: "Deny",
                    icon: Icons.close_rounded,
                    color: Colors.redAccent,
                    onTap: onDeny,
                  ),
                ] else ...[
                  Icon(
                    currentStatus.toLowerCase() == "accepted"
                        ? Icons.check_circle_rounded
                        : Icons.cancel_rounded,
                    color: currentStatus.toLowerCase() == "accepted"
                        ? const Color(0xFF27AE60)
                        : Colors.grey,
                    size: 28,
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────
// Small action button
// ─────────────────────────────────────────────────────────
class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.4), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(label,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: color)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Employer profile row
// ─────────────────────────────────────────────────────────
class _EmployerProfileRow extends StatelessWidget {
  final String employerId;
  final VoidCallback onTap;
  const _EmployerProfileRow(
      {required this.employerId, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection("users")
          .doc(employerId)
          .get(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const SizedBox(
            height: 36,
            width: 36,
            child: CircularProgressIndicator(
                strokeWidth: 2, color: Color(0xFFFFB544)),
          );
        }
        final data = snap.data!.data() as Map<String, dynamic>? ?? {};
        final name = data["name"] ?? data["displayName"] ?? "Employer";
        final photoUrl = data["profileImageUrl"] as String?;

        return GestureDetector(
          onTap: onTap,
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.grey.shade200,
                backgroundImage: (photoUrl != null && photoUrl.isNotEmpty)
                    ? NetworkImage(photoUrl)
                    : null,
                child: (photoUrl == null || photoUrl.isEmpty)
                    ? const Icon(Icons.person,
                        color: Colors.grey, size: 20)
                    : null,
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Posted by",
                      style: TextStyle(fontSize: 11, color: Colors.grey)),
                  Text(name,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────
// Shared empty state
// ─────────────────────────────────────────────────────────
Widget _emptyState({required IconData icon, required String message}) {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 70, color: Colors.grey.shade300),
        const SizedBox(height: 16),
        Text(
          message,
          style: TextStyle(fontSize: 15, color: Colors.grey.shade500),
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );
}
