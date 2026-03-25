import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:localhire/screens/terms_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'login_screen.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import 'faq_screen.dart';
import 'privacy_policy_screen.dart';
class SettingsScreen extends StatefulWidget {
  final String userId;

  const SettingsScreen({super.key, required this.userId});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // ── Colors ─────────────────────────────────────────────────────────────────
  static const _amber = Color(0xFFF5B544);
  static const _lightAmber = Color(0xFFFFF3DC);
  static const _bg = Color(0xFFF7F7F7);

  // ── Notification toggles ───────────────────────────────────────────────────
  bool _jobAlerts = true;
  bool _chatMessages = true;
  bool _reviewAlerts = true;
  bool _sosAlerts = true;
  bool _appUpdates = false;

  // ── Privacy toggles ───────────────────────────────────────────────────────
  bool _showPhone = false;
  bool _showLocation = true;
  bool _profileVisible = true;

  bool _isLoading = true;
  String _userName = "";
  String? _profileImage;
  String _userPhone = "";

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final doc = await FirebaseFirestore.instance
          .collection("users")
          .doc(widget.userId)
          .get();

      final data = doc.data() ?? {};

      setState(() {
        _userName = data["name"] ?? "";
        _profileImage = data["profileImage"];
        _userPhone = data["phone"] ?? "";

        // Load notification prefs (from SharedPreferences)
        _jobAlerts = prefs.getBool('notif_job_alerts') ?? true;
        _chatMessages = prefs.getBool('notif_chat_messages') ?? true;
        _reviewAlerts = prefs.getBool('notif_review_alerts') ?? true;
        _sosAlerts = prefs.getBool('notif_sos_alerts') ?? true;
        _appUpdates = prefs.getBool('notif_app_updates') ?? false;

        // Load privacy prefs (from Firestore)
        _showPhone = data["privacyShowPhone"] ?? false;
        _showLocation = data["privacyShowLocation"] ?? true;
        _profileVisible = data["privacyProfileVisible"] ?? true;

        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveNotifPref(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  Future<void> _savePrivacyPref(String field, bool value) async {
    await FirebaseFirestore.instance
        .collection("users")
        .doc(widget.userId)
        .update({field: value});
  }

  // ── Change Password ────────────────────────────────────────────────────────
  Future<void> _handleChangePassword() async {
    final emailController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Reset Password",
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
                "Enter your registered email and we'll send a reset link."),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                hintText: "Email address",
                filled: true,
                fillColor: const Color(0xFFF5F5F5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _amber,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Send Link",
                style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );

    if (confirmed == true && emailController.text.trim().isNotEmpty) {
      try {
        await FirebaseAuth.instance
            .sendPasswordResetEmail(email: emailController.text.trim());
        _showSnack("Password reset email sent!", success: true);
      } catch (e) {
        _showSnack("Error: $e");
      }
    }
  }

  // ── Block List ─────────────────────────────────────────────────────────────
  Future<void> _showBlockedUsers() async {
    final doc = await FirebaseFirestore.instance
        .collection("users")
        .doc(widget.userId)
        .get();
    final blocked = List<String>.from(doc.data()?["blockedUsers"] ?? []);

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => blocked.isEmpty
          ? const Padding(
              padding: EdgeInsets.all(30),
              child: Center(
                child: Text("No blocked users",
                    style: TextStyle(color: Colors.grey)),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: blocked.length,
              itemBuilder: (_, i) => ListTile(
                leading:
                    const CircleAvatar(child: Icon(Icons.person_off_outlined)),
                title: Text(blocked[i]),
                trailing: TextButton(
                  onPressed: () async {
                    await FirebaseFirestore.instance
                        .collection("users")
                        .doc(widget.userId)
                        .update({
                      "blockedUsers": FieldValue.arrayRemove([blocked[i]])
                    });
                    Navigator.pop(ctx);
                    _showSnack("User unblocked", success: true);
                  },
                  child: const Text("Unblock",
                      style: TextStyle(color: Colors.red)),
                ),
              ),
            ),
    );
  }

  // ── Delete Account ─────────────────────────────────────────────────────────
  Future<void> _handleDeleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Delete Account",
            style:
                TextStyle(fontWeight: FontWeight.w700, color: Colors.red)),
        content: const Text(
          "This action is permanent and cannot be undone.\n\n"
          "All your profile data, job history, and reviews will be deleted.",
          style: TextStyle(height: 1.6),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Delete",
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await FirebaseFirestore.instance
          .collection("users")
          .doc(widget.userId)
          .delete();
      await FirebaseAuth.instance.currentUser?.delete();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    } catch (e) {
      _showSnack("Error deleting account: $e");
    }
  }

  // ── Report a Problem ──────────────────────────────────────────────────────
  Future<void> _reportProblem() async {
    final controller = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Report a Problem",
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: TextField(
          controller: controller,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: "Describe the issue...",
            filled: true,
            fillColor: const Color(0xFFF5F5F5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _amber,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Submit",
                style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );

    if (confirmed == true && controller.text.trim().isNotEmpty) {
      await FirebaseFirestore.instance.collection("reports").add({
        "userId": widget.userId,
        "message": controller.text.trim(),
        "createdAt": FieldValue.serverTimestamp(),
      });
      _showSnack("Report submitted. Thank you!", success: true);
    }
  }

  void _showSnack(String msg, {bool success = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: success ? Colors.green : Colors.redAccent,
      behavior: SnackBarBehavior.floating,
    ));
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  // ── BUILD ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Icon(Icons.arrow_back, color: Color.fromARGB(255, 0, 0, 0)),
        ),
        centerTitle: true,
        title: const Text(
          "Settings",
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _amber))
          : ListView(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              children: [
                // ── Profile Summary ──────────────────────────────────────
                _profileSummary(),
                const SizedBox(height: 28),

                // ── Notifications ────────────────────────────────────────
                _sectionHeader(
                    Icons.notifications_outlined, "Notifications"),
                const SizedBox(height: 10),
                _settingsCard(children: [
                  _toggleTile(
                    icon: Icons.work_outline,
                    iconColor: const Color(0xFF4CAF50),
                    title: "Job Alerts",
                    subtitle: "New job requests and matches",
                    value: _jobAlerts,
                    onChanged: (v) {
                      setState(() => _jobAlerts = v);
                      _saveNotifPref('notif_job_alerts', v);
                    },
                  ),
                  _divider(),
                  _toggleTile(
                    icon: Icons.chat_bubble_outline,
                    iconColor: const Color(0xFF2196F3),
                    title: "Chat Messages",
                    subtitle: "New messages from hirers or workers",
                    value: _chatMessages,
                    onChanged: (v) {
                      setState(() => _chatMessages = v);
                      _saveNotifPref('notif_chat_messages', v);
                    },
                  ),
                  _divider(),
                  _toggleTile(
                    icon: Icons.star_outline,
                    iconColor: _amber,
                    title: "Reviews & Ratings",
                    subtitle: "When someone reviews you",
                    value: _reviewAlerts,
                    onChanged: (v) {
                      setState(() => _reviewAlerts = v);
                      _saveNotifPref('notif_review_alerts', v);
                    },
                  ),
                  _divider(),
                  _toggleTile(
                    icon: Icons.sos,
                    iconColor: Colors.red,
                    title: "SOS Alerts",
                    subtitle: "Emergency alerts from your contacts",
                    value: _sosAlerts,
                    onChanged: (v) {
                      setState(() => _sosAlerts = v);
                      _saveNotifPref('notif_sos_alerts', v);
                    },
                  ),
                  _divider(),
                  _toggleTile(
                    icon: Icons.system_update_outlined,
                    iconColor: Colors.grey,
                    title: "App Updates",
                    subtitle: "News and feature announcements",
                    value: _appUpdates,
                    onChanged: (v) {
                      setState(() => _appUpdates = v);
                      _saveNotifPref('notif_app_updates', v);
                    },
                  ),
                ]),

                const SizedBox(height: 28),

                // ── Privacy & Security ───────────────────────────────────
                _sectionHeader(Icons.lock_outline, "Privacy & Security"),
                const SizedBox(height: 10),
                _settingsCard(children: [
                  _toggleTile(
                    icon: Icons.phone_outlined,
                    iconColor: const Color(0xFF4CAF50),
                    title: "Show Phone Number",
                    subtitle: "Visible to hirers on your profile",
                    value: _showPhone,
                    onChanged: (v) {
                      setState(() => _showPhone = v);
                      _savePrivacyPref('privacyShowPhone', v);
                    },
                  ),
                  
                  _divider(),
                  _toggleTile(
                    icon: Icons.visibility_outlined,
                    iconColor: const Color(0xFF9C27B0),
                    title: "Profile Visible",
                    subtitle: "Show your profile in search results",
                    value: _profileVisible,
                    onChanged: (v) {
                      setState(() => _profileVisible = v);
                      _savePrivacyPref('privacyProfileVisible', v);
                    },
                  ),
                  _divider(),
                  _arrowTile(
                    icon: Icons.key_outlined,
                    iconColor: _amber,
                    title: "Change Password",
                    subtitle: "Send a reset link to your email",
                    onTap: _handleChangePassword,
                  ),
                  _divider(),
                  _arrowTile(
                    icon: Icons.block_outlined,
                    iconColor: Colors.grey,
                    title: "Blocked Users",
                    subtitle: "Manage users you've blocked",
                    onTap: _showBlockedUsers,
                  ),
                ]),

                const SizedBox(height: 28),

                // ── Help & Support ───────────────────────────────────────
                _sectionHeader(
                    Icons.help_outline_rounded, "Help & Support"),
                const SizedBox(height: 10),
                _settingsCard(children: [
                  _arrowTile(
                    icon: Icons.menu_book_outlined,
                    iconColor: const Color(0xFF2196F3),
                    title: "How LocalHire Works",
                    subtitle: "Guide for workers and hirers",
                    onTap: () => _launchUrl("https://localhire.app/guide"),
                  ),
                  _divider(),
                  _arrowTile(
                    icon: Icons.quiz_outlined,
                    iconColor: _amber,
                    title: "FAQs",
                    subtitle: "Answers to common questions",
                    onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const FAQScreen()),
    );
                    }
                  ),
                  _divider(),
                  _arrowTile(
                    icon: Icons.bug_report_outlined,
                    iconColor: Colors.orange,
                    title: "Report a Problem",
                    subtitle: "Tell us what went wrong",
                    onTap: _reportProblem,
                  ),
                  _divider(),
                  _arrowTile(
                    icon: Icons.headset_mic_outlined,
                    iconColor: const Color(0xFF4CAF50),
                    title: "Contact Support",
                    subtitle: "support@localhire.app",
                    onTap: () => _launchUrl(
                        "mailto:support@localhire.app?subject=Support Request"),
                  ),
                ]),

                const SizedBox(height: 28),

                // ── About ────────────────────────────────────────────────
                _sectionHeader(Icons.info_outline, "About"),
                const SizedBox(height: 10),
                _settingsCard(children: [
                  _arrowTile(
                    icon: Icons.description_outlined,
                    iconColor: Colors.grey,
                    title: "Terms of Service",
                    onTap: () {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => const TermsScreen(),
    ),
  );
},
                  ),
                  _divider(),
                  _arrowTile(
                    icon: Icons.privacy_tip_outlined,
                    iconColor: Colors.grey,
                    title: "Privacy Policy",
                    onTap: () {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => const PrivacyPolicyScreen(),
    ),
  );
},
                  ),
                  _divider(),
                  _infoTile(
                    icon: Icons.tag,
                    iconColor: Colors.grey,
                    title: "App Version",
                    trailing: "1.0.0",
                  ),
                ]),

                const SizedBox(height: 28),

                // ── Danger Zone ──────────────────────────────────────────
                _sectionHeader(Icons.warning_amber_outlined, "Account",
                    color: Colors.red),
                const SizedBox(height: 10),
                _settingsCard(children: [
                  _arrowTile(
                    icon: Icons.delete_outline,
                    iconColor: Colors.red,
                    title: "Delete Account",
                    subtitle: "Permanently remove all your data",
                    titleColor: Colors.red,
                    onTap: _handleDeleteAccount,
                  ),
                ]),

                const SizedBox(height: 40),
              ],
            ),
    );
  }

  // ── Reusable Widgets ───────────────────────────────────────────────────────

  Widget _profileSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 2))
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: _lightAmber,
              image: _profileImage != null
                  ? DecorationImage(
                      image: NetworkImage(_profileImage!),
                      fit: BoxFit.cover)
                  : null,
            ),
            child: _profileImage == null
                ? const Icon(Icons.person, color: _amber, size: 28)
                : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _userName,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 16),
                ),
                const SizedBox(height: 3),
                Text(
                  _userPhone.isNotEmpty ? "+91 $_userPhone" : "LocalHire User",
                  style:
                      const TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: _lightAmber,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              "Active",
              style: TextStyle(
                  color: _amber,
                  fontSize: 12,
                  fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(IconData icon, String title,
      {Color color = const Color(0xFF888888)}) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Text(
          title.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: color,
            letterSpacing: 0.9,
          ),
        ),
      ],
    );
  }

  Widget _settingsCard({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _toggleTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          _iconBox(icon, iconColor),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14)),
                if (subtitle != null)
                  Text(subtitle,
                      style: const TextStyle(
                          color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
          CupertinoSwitch(
            value: value,
            onChanged: onChanged,
            activeColor: _amber,
          ),
        ],
      ),
    );
  }

  Widget _arrowTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
    Color titleColor = Colors.black87,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            _iconBox(icon, iconColor),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: titleColor)),
                  if (subtitle != null)
                    Text(subtitle,
                        style: const TextStyle(
                            color: Colors.grey, fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _infoTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String trailing,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          _iconBox(icon, iconColor),
          const SizedBox(width: 14),
          Expanded(
            child: Text(title,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 14)),
          ),
          Text(trailing,
              style: const TextStyle(color: Colors.grey, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _iconBox(IconData icon, Color color) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: color, size: 18),
    );
  }

  Widget _divider() => const Divider(
      height: 1, indent: 66, endIndent: 16, color: Color(0xFFF0F0F0));
}