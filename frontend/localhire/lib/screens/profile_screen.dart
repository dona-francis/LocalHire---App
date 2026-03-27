import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'login_screen.dart';
import '../services/auth_service.dart';

class ProfileScreen extends StatefulWidget {
  final String userId;

  const ProfileScreen({super.key, required this.userId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  bool isHiring = false;
  bool _sosLoading = false;

  final Color primaryGold = const Color(0xFFFFB544);
  final Color lightCream = const Color(0xFFFFE7BF);
  final Color localRed = const Color(0xFFE53935);

  List<Map<String, dynamic>> reviews = [];
  double averageRating = 0.0;
  bool reviewLoading = true;

  Map<String, dynamic>? userData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchUserData();
    fetchReviews();
  }

  // ── Data fetching ────────────────────────────────────────────────────────────

  Future<void> fetchUserData() async {
  final doc = await FirebaseFirestore.instance
      .collection("users")
      .doc(widget.userId)
      .get();

  setState(() {
    if (doc.exists) {
      userData = doc.data();
    } else {
      userData = {}; // empty instead of null
    }
    isLoading = false; // ✅ ALWAYS stop loading
  });
}

  Future<void> fetchReviews() async {
    final query = await FirebaseFirestore.instance
        .collection("reviews")
        .where("toUserId", isEqualTo: widget.userId)
        .orderBy("createdAt", descending: true)
        .limit(3)
        .get();

    double total = 0;
    reviews.clear();

    for (var doc in query.docs) {
      final data = doc.data();

      final userDoc = await FirebaseFirestore.instance
          .collection("users")
          .doc(data["fromUserId"])
          .get();

      final reviewerName = userDoc.data()?["name"] ?? "Anonymous";

      reviews.add({
        "comment": data["comment"],
        "rating": data["rating"],
        "reviewerName": reviewerName,
      });

      total += (data["rating"] ?? 0);
    }

    if (reviews.isNotEmpty) {
      averageRating = total / reviews.length;
    }

    setState(() {
      reviewLoading = false;
    });
  }

  // ── SOS logic ────────────────────────────────────────────────────────────────

  Future<void> _handleSOS() async {
    final prefs = await SharedPreferences.getInstance();
    final bool hasSeenSOSWarning =
        prefs.getBool('sos_warning_accepted') ?? false;

    if (!hasSeenSOSWarning) {
      // Show first-time warning dialog
      final accepted = await _showSOSWarningDialog();
      if (accepted == true) {
        await prefs.setBool('sos_warning_accepted', true);
        // Don't trigger SOS on first acceptance — just educate the user
        return;
      }
      return;
    }

    // Second tap onwards → trigger SOS
    await _triggerSOS();
  }

  Future<bool?> _showSOSWarningDialog() {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded,
                color: localRed, size: 28),
            const SizedBox(width: 8),
            const Text(
              "SOS Emergency",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: const SingleChildScrollView(
          child: Text(
            "🚨 The SOS button is for REAL emergencies only.\n\n"
            "When activated, it will:\n"
            "• Immediately send your live location to 2 emergency contacts via SMS\n"
            "• Include your name and current employer details\n"
            "• Notify the LocalHire admin team\n\n"
            "⚠️ Please do NOT press this button unless you are in genuine danger or distress.\n\n"
            "Tap OK to acknowledge this. The next time you press SOS, the alert will be sent immediately.",
            style: TextStyle(height: 1.6),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel",
                style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE53935),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("I Understand",
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _triggerSOS() async {
    // Show confirmation before actually sending
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.sos, color: localRed, size: 28),
            const SizedBox(width: 8),
            const Text("Send SOS?",
                style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          "This will send your live location and details to your emergency contacts RIGHT NOW.\n\nAre you sure?",
          style: TextStyle(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel",
                style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE53935),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("YES, SEND SOS",
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _sosLoading = true);

    try {
      // 1. Get live location
      final position = await _getLiveLocation();
      if (position == null) {
        _showSnack("Could not get location. Please enable location services.",
            isError: true);
        return;
      }

      // 2. Get employer name from active job
      final employerName = await _getActiveEmployerName();

      // 3. Build SMS message
      final employeeName = userData?["name"] ?? "Unknown User";
      final mapsLink =
          "https://maps.google.com/?q=${position.latitude},${position.longitude}";

      final smsBody = "🚨 SOS ALERT from LocalHire\n\n"
          "Employee: $employeeName\n"
          "Currently working for: $employerName\n"
          "Live Location: $mapsLink\n"
          "Coordinates: ${position.latitude.toStringAsFixed(5)}, "
          "${position.longitude.toStringAsFixed(5)}\n\n"
          "Please respond immediately!";

      // 4. Fetch emergency contacts from userData and send SMS
final emergencyContacts = List<Map<String, dynamic>>.from(
  userData?["emergencyContacts"] ?? [],
);

if (emergencyContacts.isEmpty) {
  _showSnack("No emergency contacts found. Please add them in your profile.", isError: true);
  return;
}

final numbers = emergencyContacts
    .map((c) => "+91${c["phone"]?.toString().trim() ?? ""}")
    .where((p) => p.length > 3)
    .join(";");

await _sendSMS(numbers, smsBody);
      // 5. Log SOS alert in Firestore for admin dashboard
      await _logSOSToFirestore(
        employeeName: employeeName,
        employerName: employerName,
        latitude: position.latitude,
        longitude: position.longitude,
        mapsLink: mapsLink,
      );

      _showSnack(" SOS sent to emergency contacts!");
    } catch (e) {
      _showSnack("Failed to send SOS: $e", isError: true);
    } finally {
      setState(() => _sosLoading = false);
    }
  }

  Future<Position?> _getLiveLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return null;
    }
    if (permission == LocationPermission.deniedForever) return null;

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  Future<String> _getActiveEmployerName() async {
    try {
      // Look for an active/ongoing job where this user is the worker
      final jobQuery = await FirebaseFirestore.instance
          .collection("jobs")
          .where("workerId", isEqualTo: widget.userId)
          .where("status", isEqualTo: "active")
          .limit(1)
          .get();

      if (jobQuery.docs.isNotEmpty) {
        final jobData = jobQuery.docs.first.data();
        final employerId = jobData["employerId"] as String?;

        if (employerId != null) {
          final employerDoc = await FirebaseFirestore.instance
              .collection("users")
              .doc(employerId)
              .get();
          return employerDoc.data()?["name"] ?? "Unknown Employer";
        }
      }
    } catch (_) {}
    return "Not currently on a job";
  }

  Future<void> _sendSMS(String phoneNumbers, String body) async {
  final uri = Uri(
    scheme: 'sms',
    path: phoneNumbers,
    queryParameters: {'body': body},
  );
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

  Future<void> _logSOSToFirestore({
    required String employeeName,
    required String employerName,
    required double latitude,
    required double longitude,
    required String mapsLink,
  }) async {
    await FirebaseFirestore.instance.collection("sos_alerts").add({
      "userId": widget.userId,
      "employeeName": employeeName,
      "employerName": employerName,
      "latitude": latitude,
      "longitude": longitude,
      "mapsLink": mapsLink,
      "status": "pending", // admin can mark as "resolved"
      "createdAt": FieldValue.serverTimestamp(),
    });
  }

  void _showSnack(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? localRed : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final name = userData?["name"] ?? "";
    final location = userData?["location"] ?? "";
    final profileImage = userData?["profileImage"];
    final skills = List<String>.from(userData?["skills"] ?? []);
    final createdAt = userData?["createdAt"];

    String memberSince = "";
    if (createdAt != null) {
      final date = createdAt.toDate();
      memberSince = "${date.month}/${date.year}";
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              const SizedBox(height: 10),

              /// HEADER
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Text(
                    "Profile",
                    style: TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const Icon(Icons.settings),
                ],
              ),

              const SizedBox(height: 20),

              /// PROFILE IMAGE
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      border: Border.all(color: primaryGold, width: 4),
                      shape: BoxShape.circle,
                    ),
                    child: CircleAvatar(
                      radius: 55,
                      backgroundImage: profileImage != null
                          ? NetworkImage(profileImage)
                          : null,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 15),

              Text(
                name,
                style: const TextStyle(
                    fontSize: 22, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 5),

              Text(
                "$location • Member since $memberSince",
                style:
                    const TextStyle(color: Colors.grey, fontSize: 13),
              ),

              const SizedBox(height: 25),

              /// ACTION BUTTONS
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryGold,
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {},
                      icon: const Icon(Icons.edit),
                      label: const Text("Edit Profile"),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: primaryGold),
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {},
                      icon: Icon(Icons.share, color: primaryGold),
                      label: Text(
                        "Share",
                        style: TextStyle(color: primaryGold),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 25),

              /// TOGGLE
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    _toggleButton("Hiring", true, Icons.search),
                    _toggleButton("Working", false, Icons.work),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              _sectionTitle("About"),
              const SizedBox(height: 8),
              Text(
                isHiring
                    ? "Regularly looking for reliable help with home maintenance and specialized tasks."
                    : "Experienced LocalHire worker with skills in ${skills.join(", ")}.",
                style: const TextStyle(height: 1.5),
              ),

              const SizedBox(height: 30),

              _sectionTitle(isHiring ? "Employer Stats" : "Worker Stats"),
              const SizedBox(height: 12),
              _statCard("—",
                  isHiring ? "Jobs Posted" : "Jobs Completed"),

              const SizedBox(height: 30),

              _sectionTitle(
                  isHiring ? "Employer Feedback" : "Reviews"),
              const SizedBox(height: 15),
              _reviewCard(),

              if (!isHiring) ...[
                const SizedBox(height: 30),
                _sectionTitle("Services Offered"),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children:
                      skills.map((skill) => _serviceChip(skill)).toList(),
                ),
              ],

              const SizedBox(height: 40),

              _sosButton(),
              const SizedBox(height: 12),
              _bigButton("LOGOUT", Colors.black),

              const SizedBox(height: 60),
            ],
          ),
        ),
      ),
    );
  }

  // ── Widgets ──────────────────────────────────────────────────────────────────

  Widget _sosButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: localRed,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
        ),
        onPressed: _sosLoading ? null : _handleSOS,
        child: _sosLoading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2),
              )
            : const Text(
                "SOS EMERGENCY",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }

  Widget _toggleButton(String text, bool value, IconData icon) {
    final selected = isHiring == value;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => isHiring = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: selected
                ? const [
                    BoxShadow(
                        blurRadius: 4,
                        color: Colors.black12,
                        offset: Offset(0, 2))
                  ]
                : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 16,
                  color: selected ? Colors.black : Colors.grey),
              const SizedBox(width: 6),
              Text(
                text,
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: selected ? Colors.black : Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.grey),
      ),
    );
  }

  Widget _statCard(String number, String label) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
              blurRadius: 6,
              color: Colors.black12,
              offset: Offset(0, 2))
        ],
        color: Colors.white,
      ),
      child: Column(
        children: [
          Text(number,
              style: const TextStyle(
                  fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 5),
          Text(label,
              style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _reviewCard() {
    if (reviewLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (reviews.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
                blurRadius: 6,
                color: Colors.black12,
                offset: Offset(0, 2))
          ],
          color: Colors.white,
        ),
        child: const Text("No reviews yet"),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
              blurRadius: 6,
              color: Colors.black12,
              offset: Offset(0, 2))
        ],
        color: Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            averageRating.toStringAsFixed(1),
            style: const TextStyle(
                fontSize: 40, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 5),
          Row(
            children: List.generate(5, (index) {
              return Icon(
                index < averageRating.round()
                    ? Icons.star
                    : Icons.star_border,
                color: const Color(0xFFFFB544),
              );
            }),
          ),
          const SizedBox(height: 5),
          Text(
            "${reviews.length} Reviews",
            style: const TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 15),
          ...reviews.map((review) {
            final message = review["comment"] ?? "";
            final rating = review["rating"] ?? 0;
            final reviewer = review["reviewerName"] ?? "Anonymous";

            return Container(
              margin: const EdgeInsets.only(top: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        reviewer,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      Row(
                        children: List.generate(5, (index) {
                          return Icon(
                            index < rating.round()
                                ? Icons.star
                                : Icons.star_border,
                            size: 16,
                            color: const Color(0xFFFFB544),
                          );
                        }),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    message,
                    style: const TextStyle(fontSize: 13),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _serviceChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: lightCream,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(text,
          style: const TextStyle(fontWeight: FontWeight.w600)),
    );
  }

  Widget _bigButton(String text, Color color) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
        ),
        onPressed: () async {
          if (text == "LOGOUT") {
            await FirebaseAuth.instance.signOut();
            await _authService.logout();
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder: (context) => const LoginScreen(),
              ),
              (route) => false,
            );
          }
        },
        child: Text(
          text,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}