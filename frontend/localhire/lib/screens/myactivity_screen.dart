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

  final List<String> _tabs = ["Posted Jobs", "Applied Jobs", "Completed"];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
                        fontWeight: selected
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: selected
                            ? Colors.black
                            : Colors.grey.shade600,
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
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Tab 1 & 3 — Posted Jobs: converted to StatefulWidget ✅
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

  // ✅ Cache — same pattern as ChatScreen's _lastKnownChats
  List<QueryDocumentSnapshot> _lastKnownDocs = [];

  @override
  bool get wantKeepAlive => true; // ✅ keeps tab alive when switching tabs

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

        // ✅ Update cache only when real data arrives
        if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
          _lastKnownDocs = snapshot.data!.docs;
        }

        // ✅ Show spinner ONLY on true first load (cache is empty)
        if (_lastKnownDocs.isEmpty &&
            snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: Color(0xFFFFB544)));
        }

        // Filter by status using cache
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
// Tab 2 — Applied Jobs: converted to StatefulWidget ✅
// ─────────────────────────────────────────────────────────
class _AppliedJobsTab extends StatefulWidget {
  final String userId;
  const _AppliedJobsTab({required this.userId});

  @override
  State<_AppliedJobsTab> createState() => _AppliedJobsTabState();
}

class _AppliedJobsTabState extends State<_AppliedJobsTab>
    with AutomaticKeepAliveClientMixin {

  // ✅ Cache — same pattern as ChatScreen's _lastKnownChats
  List<QueryDocumentSnapshot> _lastKnownDocs = [];

  @override
  bool get wantKeepAlive => true; // ✅ keeps tab alive when switching tabs

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection("jobs")
          .where("acceptedBy", arrayContains: widget.userId)
          .orderBy("createdAt", descending: true)
          .snapshots(),
      builder: (context, snapshot) {

        // ✅ Update cache only when real data arrives
        if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
          _lastKnownDocs = snapshot.data!.docs;
        }

        // ✅ Show spinner ONLY on true first load (cache is empty)
        if (_lastKnownDocs.isEmpty &&
            snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: Color(0xFFFFB544)));
        }

        if (_lastKnownDocs.isEmpty &&
            snapshot.connectionState == ConnectionState.active) {
          return _emptyState(
            icon: Icons.assignment_outlined,
            message: "You haven't applied to any jobs yet.",
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: _lastKnownDocs.length,
          itemBuilder: (context, index) {
            final data =
                _lastKnownDocs[index].data() as Map<String, dynamic>;
            return _AppliedJobCard(job: data, userId: widget.userId);
          },
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────
// Posted Job Card (unchanged)
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
    final List acceptedBy = job["acceptedBy"] ?? [];
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

    return Container(
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
            Row(
              children: [
                if (isCompleted) ...[
                  const Icon(Icons.star_rounded,
                      color: Color(0xFFFFB544), size: 22),
                  const SizedBox(width: 6),
                  Text(
                    job["review"] ?? "Excellent service!",
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              JobDetailsScreen(job: _prepareJob(job)),
                        ),
                      );
                    },
                    child: const Text(
                      "View Details",
                      style: TextStyle(
                          color: Color(0xFFB8860B),
                          fontWeight: FontWeight.w600,
                          fontSize: 14),
                    ),
                  ),
                ] else ...[
                  if (acceptedBy.isNotEmpty)
                    _ApplicantAvatarStack(applicantIds: acceptedBy),
                  if (acceptedBy.isEmpty)
                    Text(
                      "Awaiting more quotes...",
                      style: TextStyle(
                          fontStyle: FontStyle.italic,
                          color: Colors.grey.shade500,
                          fontSize: 13),
                    ),
                  const Spacer(),
                  if (acceptedBy.isNotEmpty)
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFB544),
                        foregroundColor: Colors.black,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 10),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () =>
                          _showApplicantsSheet(context, acceptedBy),
                      child: const Text("View Applicants",
                          style:
                              TextStyle(fontWeight: FontWeight.bold)),
                    )
                  else
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.black,
                        side: BorderSide(color: Colors.grey.shade300),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 10),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {},
                      child: const Text("Edit Post",
                          style:
                              TextStyle(fontWeight: FontWeight.w600)),
                    ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showApplicantsSheet(BuildContext context, List applicantIds) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) =>
          _ApplicantsBottomSheet(applicantIds: applicantIds),
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
      "Jan", "Feb", "Mar", "Apr", "May", "Jun",
      "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"
    ];
    return months[month];
  }
}

// ─────────────────────────────────────────────────────────
// Applied Job Card (unchanged)
// ─────────────────────────────────────────────────────────
class _AppliedJobCard extends StatelessWidget {
  final Map<String, dynamic> job;
  final String userId;
  const _AppliedJobCard({required this.job, required this.userId});

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
    final String postedBy = job["postedBy"] ?? "";

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(18)),
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
                isCompleted ? "COMPLETED" : "APPLIED",
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                  color: isCompleted
                      ? Colors.grey.shade600
                      : const Color(0xFFB8860B),
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
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFB544),
                    foregroundColor: Colors.black,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    final jobForDetails = {
                      ...job,
                      "date": job["date"] is Timestamp
                          ? (job["date"] as Timestamp)
                              .toDate()
                              .toLocal()
                              .toString()
                              .split(' ')[0]
                          : (job["date"] ?? ""),
                    };
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            JobDetailsScreen(job: jobForDetails),
                      ),
                    );
                  },
                  child: const Text("View Details",
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _monthName(int month) {
    const months = [
      "",
      "Jan", "Feb", "Mar", "Apr", "May", "Jun",
      "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"
    ];
    return months[month];
  }
}

// ─────────────────────────────────────────────────────────
// Applicant avatar stack (unchanged)
// ─────────────────────────────────────────────────────────
class _ApplicantAvatarStack extends StatelessWidget {
  final List applicantIds;
  const _ApplicantAvatarStack({required this.applicantIds});

  @override
  Widget build(BuildContext context) {
    final displayCount =
        applicantIds.length > 3 ? 3 : applicantIds.length;
    final extra = applicantIds.length - displayCount;

    return SizedBox(
      height: 36,
      width: displayCount * 24.0 + (extra > 0 ? 36 : 0) + 12,
      child: Stack(
        children: [
          ...List.generate(displayCount, (i) {
            return Positioned(
              left: i * 24.0,
              child: _UserAvatar(
                  userId: applicantIds[i].toString(), size: 36),
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
// User avatar (unchanged)
// ─────────────────────────────────────────────────────────
class _UserAvatar extends StatelessWidget {
  final String userId;
  final double size;
  const _UserAvatar({required this.userId, this.size = 40});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection("users")
          .doc(userId)
          .get(),
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
                    child:
                        const Icon(Icons.person, color: Colors.white),
                  ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────
// Applicants bottom sheet (unchanged)
// ─────────────────────────────────────────────────────────
class _ApplicantsBottomSheet extends StatelessWidget {
  final List applicantIds;
  const _ApplicantsBottomSheet({required this.applicantIds});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text("Applicants",
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              const Spacer(),
              IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context)),
            ],
          ),
          const SizedBox(height: 10),
          ...applicantIds.map((uid) => _ApplicantTile(
                userId: uid.toString(),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          WorkerProfileScreen(userId: uid.toString()),
                    ),
                  );
                },
              )),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Applicant tile (unchanged)
// ─────────────────────────────────────────────────────────
class _ApplicantTile extends StatelessWidget {
  final String userId;
  final VoidCallback onTap;
  const _ApplicantTile({required this.userId, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection("users")
          .doc(userId)
          .get(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const ListTile(
            leading: CircleAvatar(child: Icon(Icons.person)),
            title: Text("Loading..."),
          );
        }
        final data =
            snap.data!.data() as Map<String, dynamic>? ?? {};
        final name =
            data["name"] ?? data["displayName"] ?? "Unknown";
        final photoUrl = data["profileImageUrl"] as String?;

        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: GestureDetector(
            onTap: onTap,
            child: CircleAvatar(
              radius: 22,
              backgroundColor: Colors.grey.shade200,
              backgroundImage:
                  (photoUrl != null && photoUrl.isNotEmpty)
                      ? NetworkImage(photoUrl)
                      : null,
              child: (photoUrl == null || photoUrl.isEmpty)
                  ? const Icon(Icons.person, color: Colors.grey)
                  : null,
            ),
          ),
          title: Text(name,
              style: const TextStyle(fontWeight: FontWeight.w600)),
          trailing: const Icon(Icons.arrow_forward_ios,
              size: 14, color: Colors.grey),
          onTap: onTap,
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────
// Employer profile row (unchanged)
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
        final data =
            snap.data!.data() as Map<String, dynamic>? ?? {};
        final name =
            data["name"] ?? data["displayName"] ?? "Employer";
        final photoUrl = data["profileImageUrl"] as String?;

        return GestureDetector(
          onTap: onTap,
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.grey.shade200,
                backgroundImage:
                    (photoUrl != null && photoUrl.isNotEmpty)
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
                      style:
                          TextStyle(fontSize: 11, color: Colors.grey)),
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
// Shared empty state (unchanged)
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
          style:
              TextStyle(fontSize: 15, color: Colors.grey.shade500),
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );
}