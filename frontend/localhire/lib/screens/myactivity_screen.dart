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

  final List<String> _tabs = ["Posted Jobs", "Applied Jobs", "Completed", "Requests"];

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
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: selected ? Colors.white : Colors.transparent,
                      border: Border.all(
                        color: selected ? const Color(0xFFFFB544) : Colors.grey.shade300,
                        width: selected ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: Text(
                      _tabs[index],
                      style: TextStyle(
                        fontWeight: selected ? FontWeight.bold : FontWeight.normal,
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
// Shared user + job cache (process-level, like chat_screen)
// ─────────────────────────────────────────────────────────
class _Cache {
  static final Map<String, Map<String, dynamic>> users = {};
  static final Map<String, Map<String, dynamic>> jobs = {};
}

// ─────────────────────────────────────────────────────────
// Tab 4 — Requests
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
          .snapshots(),
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
            final data = requests[index].data() as Map<String, dynamic>;
            return _RequestCard(
              key: ValueKey(requests[index].id),
              appDocId: requests[index].id,
              appData: data,
            );
          },
        );
      },
    );
  }
}

class _RequestCard extends StatefulWidget {
  final String appDocId;
  final Map<String, dynamic> appData;
  const _RequestCard({super.key, required this.appDocId, required this.appData});

  @override
  State<_RequestCard> createState() => _RequestCardState();
}

class _RequestCardState extends State<_RequestCard> {
  String _jobTitle = "";
  String _workerName = "";
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final jobId = widget.appData["jobId"] as String? ?? "";
    final workerId = widget.appData["workerId"] as String? ?? "";

    if (_Cache.jobs.containsKey(jobId)) {
      _jobTitle = _Cache.jobs[jobId]!["title"] ?? "Job";
    } else if (jobId.isNotEmpty) {
      final doc = await FirebaseFirestore.instance.collection("jobs").doc(jobId).get();
      if (doc.exists) {
        final d = doc.data() as Map<String, dynamic>;
        _Cache.jobs[jobId] = d;
        _jobTitle = d["title"] ?? "Job";
      }
    }

    if (_Cache.users.containsKey(workerId)) {
      _workerName = _Cache.users[workerId]!["name"] ?? "Worker";
    } else if (workerId.isNotEmpty) {
      final doc = await FirebaseFirestore.instance.collection("users").doc(workerId).get();
      if (doc.exists) {
        final d = doc.data() as Map<String, dynamic>;
        _Cache.users[workerId] = d;
        _workerName = d["name"] ?? "Worker";
      }
    }

    if (mounted) setState(() => _loaded = true);
  }

  Future<void> _accept(BuildContext ctx) async {
    final workerId = widget.appData["workerId"] as String? ?? "";
    final jobId = widget.appData["jobId"] as String? ?? "";

    await FirebaseFirestore.instance
        .collection("applications")
        .doc(widget.appDocId)
        .update({"status": "accepted"});

    await FirebaseFirestore.instance.collection("jobs").doc(jobId).update({
      "acceptedBy": FieldValue.arrayUnion([workerId]),
      "status": "assigned",
    });

    final others = await FirebaseFirestore.instance
        .collection("applications")
        .where("jobId", isEqualTo: jobId)
        .get();
    for (final doc in others.docs) {
      if (doc.id != widget.appDocId) {
        await doc.reference.update({"status": "denied"});
      }
    }
  }

  Future<void> _deny() async {
    await FirebaseFirestore.instance
        .collection("applications")
        .doc(widget.appDocId)
        .update({"status": "denied"});
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.appData;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 0,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Job title
            Text(
              _loaded ? _jobTitle : (data["jobId"] ?? ""),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),

            const SizedBox(height: 6),

            // 🔥 UPDATED: Clickable worker name (bigger)
            GestureDetector(
              onTap: () {
                final workerId = widget.appData["workerId"] as String? ?? "";
                if (workerId.isNotEmpty) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => WorkerProfileScreen(userId: workerId),
                    ),
                  );
                }
              },
              child: Text(
                _loaded ? _workerName : "",
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ),

            if ((data["enquiry"] ?? data["question"] ?? "").toString().isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                data["enquiry"] ?? data["question"] ?? "",
                style: const TextStyle(fontSize: 14),
              ),
            ],

            const SizedBox(height: 8),

            if ((data["preferredDate"] ?? "").toString().isNotEmpty)
              Text("📅  Date: ${data["preferredDate"]}",
                  style: const TextStyle(fontSize: 13)),

            if ((data["preferredTime"] ?? "").toString().isNotEmpty)
              Text("⏰  Time: ${data["preferredTime"]}",
                  style: const TextStyle(fontSize: 13)),

            if ((data["proposedRate"] ?? "").toString().isNotEmpty)
              Text("💰  Rate: ₹${data["proposedRate"]}",
                  style: const TextStyle(fontSize: 13)),

            const SizedBox(height: 14),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.black87,
                      side: const BorderSide(color: Color(0xFF4CAF50), width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16), // 🔥 more oval
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () => _accept(context),
                    child: const Text("Accept",
                        style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.black87,
                      side: BorderSide(color: Colors.red.shade300, width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16), // 🔥 more oval
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: _deny,
                    child: const Text("Deny",
                        style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
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
          final status = (data["status"] ?? "active").toString().toLowerCase();
          if (widget.showCompleted) return status == "completed";
          return status != "completed";
        }).toList();

        if (docs.isEmpty && snapshot.connectionState == ConnectionState.active) {
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
              key: ValueKey(docId),
              job: data,
              docId: docId,
              userId: widget.userId,
            );
          },
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────
// Tab 2 — Applied Jobs
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

  // ── Same pattern as _PostedJobsTab — never wipe the list ──
  List<QueryDocumentSnapshot> _lastKnownDocs = [];

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
        // Only update when real data arrives — never reset on waiting/error
        if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
          _lastKnownDocs = snapshot.data!.docs;
        }

        // Show spinner only on the very first load (no cached docs yet)
        if (_lastKnownDocs.isEmpty &&
            snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: Color(0xFFFFB544)));
        }

        // Show empty state only when stream is active AND confirmed empty
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
            final appData =
                _lastKnownDocs[index].data() as Map<String, dynamic>;
            final appId = _lastKnownDocs[index].id;
            return _AppliedJobCard(
              key: ValueKey(appId),
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
      {super.key, required this.job, required this.docId, required this.userId});

  @override
  Widget build(BuildContext context) {
    final String title = job["title"] ?? "No Title";
    final String location = job["location"] ?? "No Location";
    final String status = (job["status"] ?? "active").toString().toUpperCase();
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
        if (isCompleted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => JobDetailsScreen(
                job: {
                  ..._prepareJob(job),
                  "jobId": docId,
                },
                currentUserId: userId,
              ),
            ),
          );
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
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.location_on_outlined, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(location,
                        style: const TextStyle(fontSize: 14, color: Colors.black87),
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
                        style: const TextStyle(fontSize: 14, color: Colors.black87)),
                  ],
                ),
              const SizedBox(height: 14),
              const Divider(height: 1),
              const SizedBox(height: 14),
              if (isCompleted) ...[
                Row(
                  children: [
                    const Icon(Icons.star_rounded, color: Color(0xFFFFB544), size: 22),
                    const SizedBox(width: 6),
                    Text(
                      job["review"] ?? "Excellent service!",
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
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
      "", "Jan", "Feb", "Mar", "Apr", "May", "Jun",
      "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"
    ];
    return months[month];
  }
}

// ─────────────────────────────────────────────────────────
// Live applicant count footer — no flicker
// Keeps last-known count/ids; never resets to 0 on reconnect
// ─────────────────────────────────────────────────────────
class _LiveApplicantFooter extends StatefulWidget {
  final String jobDocId;
  const _LiveApplicantFooter({required this.jobDocId});

  @override
  State<_LiveApplicantFooter> createState() => _LiveApplicantFooterState();
}

class _LiveApplicantFooterState extends State<_LiveApplicantFooter>
    with AutomaticKeepAliveClientMixin {
  // ── Class-level cache so count survives tab switches ──
  static final Map<String, int> _countCache = {};
  static final Map<String, List<String>> _idsCache = {};

  int _count = 0;
  List<String> _workerIds = [];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    // Seed from cache immediately — zero flicker on rebuild
    _count = _countCache[widget.jobDocId] ?? 0;
    _workerIds = _idsCache[widget.jobDocId] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection("applications")
          .where("jobId", isEqualTo: widget.jobDocId)
          .snapshots(),
      builder: (context, snapshot) {
        // Only update when real data arrives — never reset on waiting/error
        if (snapshot.hasData) {
          final newCount = snapshot.data!.docs.length;
          final newIds = snapshot.data!.docs
              .map((d) =>
                  (d.data() as Map<String, dynamic>)["workerId"]?.toString() ?? "")
              .where((id) => id.isNotEmpty)
              .toList();
          // Write through to class-level cache
          _countCache[widget.jobDocId] = newCount;
          _idsCache[widget.jobDocId] = newIds;
          // Only call setState if values actually changed
          if (newCount != _count || newIds.length != _workerIds.length) {
            // Schedule after build to avoid calling setState during build
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() {
                  _count = newCount;
                  _workerIds = newIds;
                });
              }
            });
          }
        }
        return Row(
          children: [
            if (_count > 0) ...[
              const Icon(Icons.people, size: 16, color: Colors.grey),
              const SizedBox(width: 6),
              Text(
                "$_count applicant${_count == 1 ? '' : 's'}",
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
          ],
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────
// Applied Job Card — static cache, resolves synchronously
// ─────────────────────────────────────────────────────────
class _AppliedJobCard extends StatefulWidget {
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
  State<_AppliedJobCard> createState() => _AppliedJobCardState();
}

class _AppliedJobCardState extends State<_AppliedJobCard>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  // ── Static caches — survive tab switches & widget rebuilds ──
  static final Map<String, Map<String, dynamic>> _jobCache = {};
  static final Map<String, Map<String, dynamic>> _userCache = {};

  Map<String, dynamic>? _jobData;
  Map<String, dynamic>? _employerData;
  // _loaded starts true if cache already has both — zero flicker
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  void _resolve() {
    final jobId = widget.appData["jobId"] as String? ?? "";
    final employerId = widget.appData["employerId"] as String? ?? "";

    // Read synchronously from cache — no setState needed
    if (_jobCache.containsKey(jobId)) _jobData = _jobCache[jobId];
    if (_userCache.containsKey(employerId)) _employerData = _userCache[employerId];

    if (_jobData != null && _employerData != null) {
      // Both cached — paint immediately without any async gap
      _loaded = true;
      return;
    }

    // Partial or full cache miss — fetch what's missing
    _fetch(jobId, employerId);
  }

  Future<void> _fetch(String jobId, String employerId) async {
    bool changed = false;

    if (_jobData == null && jobId.isNotEmpty) {
      // Check shared _Cache first (written by other cards)
      if (_Cache.jobs.containsKey(jobId)) {
        _jobData = _Cache.jobs[jobId];
        _jobCache[jobId] = _jobData!;
        changed = true;
      } else {
        final doc = await FirebaseFirestore.instance
            .collection("jobs")
            .doc(jobId)
            .get();
        if (doc.exists) {
          _jobData = doc.data() as Map<String, dynamic>;
          _jobCache[jobId] = _jobData!;
          _Cache.jobs[jobId] = _jobData!;
          changed = true;
        }
      }
    }

    if (_employerData == null && employerId.isNotEmpty) {
      if (_Cache.users.containsKey(employerId)) {
        _employerData = _Cache.users[employerId];
        _userCache[employerId] = _employerData!;
        changed = true;
      } else {
        final doc = await FirebaseFirestore.instance
            .collection("users")
            .doc(employerId)
            .get();
        if (doc.exists) {
          _employerData = doc.data() as Map<String, dynamic>;
          _userCache[employerId] = _employerData!;
          _Cache.users[employerId] = _employerData!;
          changed = true;
        }
      }
    }

    if (changed && mounted) setState(() => _loaded = true);
  }

  String _monthName(int month) {
    const months = [
      "", "Jan", "Feb", "Mar", "Apr", "May", "Jun",
      "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"
    ];
    return months[month];
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final String appStatus =
        (widget.appData["status"] ?? "pending").toString();
    final bool isAccepted = appStatus.toLowerCase() == "accepted";
    final bool isDenied = appStatus.toLowerCase() == "denied";

    final String title = _jobData?["title"] ?? "Loading...";
    final String location = _jobData?["location"] ?? "";
    final String jobId = widget.appData["jobId"] ?? "";

    String formattedDate = "";
    final dynamic dateValue = _jobData?["date"];
    if (dateValue != null) {
      if (dateValue is Timestamp) {
        final d = dateValue.toDate();
        formattedDate = "${_monthName(d.month)} ${d.day}, ${d.year}";
      } else if (dateValue is String) {
        formattedDate = dateValue;
      }
    }

    final String employerName =
        _employerData?["name"] ?? _employerData?["displayName"] ?? "Employer";
    final String? employerPhoto = _employerData?["profileImageUrl"] as String?;
    final String employerId = widget.appData["employerId"] ?? "";

    final jobForDetails = _jobData == null
        ? null
        : {
            ..._jobData!,
            "jobId": jobId,
            "date": _jobData!["date"] is Timestamp
                ? (_jobData!["date"] as Timestamp)
                    .toDate()
                    .toLocal()
                    .toString()
                    .split(' ')[0]
                : (_jobData!["date"] ?? ""),
          };

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: isAccepted
            ? Border.all(color: const Color(0xFF27AE60).withOpacity(0.4), width: 1.5)
            : isDenied
                ? Border.all(color: Colors.grey.shade300, width: 1.5)
                : null,
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [_ApplicationStatusBadge(status: appStatus)]),
            const SizedBox(height: 12),
            Text(title,
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            if (location.isNotEmpty)
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
                      style:
                          const TextStyle(fontSize: 14, color: Colors.black87)),
                ],
              ),
            ],
            const SizedBox(height: 14),
            const Divider(height: 1),
            const SizedBox(height: 14),
            Row(
              children: [
                if (_loaded && employerId.isNotEmpty)
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => WorkerProfileScreen(userId: employerId),
                      ),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: Colors.grey.shade200,
                          backgroundImage: (employerPhoto != null &&
                                  employerPhoto.isNotEmpty)
                              ? NetworkImage(employerPhoto)
                              : null,
                          child: (employerPhoto == null || employerPhoto.isEmpty)
                              ? const Icon(Icons.person,
                                  color: Colors.grey, size: 20)
                              : null,
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Posted by",
                                style: TextStyle(
                                    fontSize: 11, color: Colors.grey)),
                            Text(employerName,
                                style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ],
                    ),
                  ),
                const Spacer(),
                if ((isAccepted || isDenied) && jobForDetails != null)
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
                          currentUserId: widget.userId,
                        ),
                      ),
                    ),
                    child: const Text("Details",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
            if (isAccepted) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
            if (isDenied) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 16, color: Colors.grey.shade500),
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
      default:
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
  final List<String> applicantIds;
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
              child: _CachedAvatar(userId: applicantIds[i], size: 36),
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
// Cached avatar — static cache, resolves synchronously
// ─────────────────────────────────────────────────────────
class _CachedAvatar extends StatefulWidget {
  final String userId;
  final double size;
  const _CachedAvatar({required this.userId, this.size = 40});

  @override
  State<_CachedAvatar> createState() => _CachedAvatarState();
}

class _CachedAvatarState extends State<_CachedAvatar> {
  // Static cache — survives across all avatar instances
  static final Map<String, String?> _photoCache = {};

  String? _photoUrl;
  bool _fetched = false;

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  void _resolve() {
    if (_photoCache.containsKey(widget.userId)) {
      // Synchronous hit — no setState, no flicker
      _photoUrl = _photoCache[widget.userId];
      _fetched = true;
      return;
    }
    // Also check shared _Cache
    if (_Cache.users.containsKey(widget.userId)) {
      _photoUrl = _Cache.users[widget.userId]!["profileImageUrl"] as String?;
      _photoCache[widget.userId] = _photoUrl;
      _fetched = true;
      return;
    }
    _fetch();
  }

  Future<void> _fetch() async {
    final doc = await FirebaseFirestore.instance
        .collection("users")
        .doc(widget.userId)
        .get();
    if (doc.exists) {
      final data = doc.data() as Map<String, dynamic>;
      _Cache.users[widget.userId] = data;
      final url = data["profileImageUrl"] as String?;
      _photoCache[widget.userId] = url;
      if (mounted) setState(() {
        _photoUrl = url;
        _fetched = true;
      });
    } else {
      _photoCache[widget.userId] = null;
      if (mounted) setState(() => _fetched = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: ClipOval(
        child: _photoUrl != null && _photoUrl!.isNotEmpty
            ? Image.network(_photoUrl!, fit: BoxFit.cover)
            : Container(
                color: Colors.grey.shade300,
                child: const Icon(Icons.person, color: Colors.white),
              ),
      ),
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
                  Row(
                    children: [
                      const Text("Applicants",
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
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
                          child:
                              CircularProgressIndicator(color: Color(0xFFFFB544))),
                    )
                  else if (docs.isEmpty)
                    const Expanded(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.people_outline, size: 56, color: Colors.grey),
                            SizedBox(height: 12),
                            Text("No applicants yet.",
                                style: TextStyle(color: Colors.grey, fontSize: 15)),
                          ],
                        ),
                      ),
                    )
                  else
                    Expanded(
                      child: ListView.separated(
                        controller: scrollController,
                        itemCount: docs.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final appData =
                              docs[index].data() as Map<String, dynamic>;
                          final workerId =
                              appData["workerId"]?.toString() ?? "";
                          return _ApplicantProfileTile(
                            key: ValueKey(workerId),
                            userId: workerId,
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
}

// ─────────────────────────────────────────────────────────
// Applicant profile tile
// ─────────────────────────────────────────────────────────
class _ApplicantProfileTile extends StatefulWidget {
  final String userId;
  final VoidCallback onViewProfile;

  const _ApplicantProfileTile({
    super.key,
    required this.userId,
    required this.onViewProfile,
  });

  @override
  State<_ApplicantProfileTile> createState() => _ApplicantProfileTileState();
}

class _ApplicantProfileTileState extends State<_ApplicantProfileTile>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  String _name = "";
  String? _photoUrl;
  String _profession = "";
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  void _resolve() {
    if (_Cache.users.containsKey(widget.userId)) {
      final d = _Cache.users[widget.userId]!;
      _name = d["name"] ?? d["displayName"] ?? "Unknown";
      _photoUrl = d["profileImageUrl"] as String?;
      _profession = d["profession"] ?? d["jobTitle"] ?? "";
      _loaded = true;
      return;
    }
    _fetch();
  }

  Future<void> _fetch() async {
    if (widget.userId.isEmpty) return;
    final doc = await FirebaseFirestore.instance
        .collection("users")
        .doc(widget.userId)
        .get();
    if (doc.exists) {
      final d = doc.data() as Map<String, dynamic>;
      _Cache.users[widget.userId] = d;
      if (mounted) {
        setState(() {
          _name = d["name"] ?? d["displayName"] ?? "Unknown";
          _photoUrl = d["profileImageUrl"] as String?;
          _profession = d["profession"] ?? d["jobTitle"] ?? "";
          _loaded = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return InkWell(
      onTap: widget.onViewProfile,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: Colors.grey.shade200,
              backgroundImage:
                  (_photoUrl != null && _photoUrl!.isNotEmpty)
                      ? NetworkImage(_photoUrl!)
                      : null,
              child: (_photoUrl == null || _photoUrl!.isEmpty)
                  ? const Icon(Icons.person, color: Colors.grey, size: 26)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _loaded ? _name : "",
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                  if (_profession.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(_profession,
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade600)),
                  ],
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios,
                size: 14, color: Colors.grey.shade400),
          ],
        ),
      ),
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