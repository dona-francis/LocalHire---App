import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as p;
import 'location_picker_screen.dart';

class EditProfileScreen extends StatefulWidget {
  final String userId;

  const EditProfileScreen({super.key, required this.userId});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _skillController = TextEditingController();

  // State
  String? _selectedGender;
  List<String> _skills = [];
  File? _profileImage;
  String? _existingProfileUrl;
  double? _selectedLat;
  double? _selectedLng;
  bool _isAvailable = true;
  bool _isLoading = false;
  bool _isFetching = true;

  // Emergency contacts
  final List<Map<String, TextEditingController>> _emergencyContacts = [];

  final ImagePicker _picker = ImagePicker();

  static const _amber = Color(0xFFF5B544);
  static const _lightAmber = Color(0xFFFFF3DC);
  static const _borderColor = Color(0xFFE0E0E0);

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _locationController.dispose();
    _skillController.dispose();
    for (final c in _emergencyContacts) {
      c["name"]!.dispose();
      c["phone"]!.dispose();
    }
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection("users")
          .doc(widget.userId)
          .get();

      if (!doc.exists) return;

      final data = doc.data()!;

      _nameController.text = data["name"] ?? "";
      _ageController.text = data["age"]?.toString() ?? "";
      _locationController.text = data["location"] ?? "";
      _selectedGender = data["gender"];
      _isAvailable = data["isAvailable"] ?? true;
      _existingProfileUrl = data["profileImage"];

      final geoPoint = data["locationGeoPoint"] as GeoPoint?;
      if (geoPoint != null) {
        _selectedLat = geoPoint.latitude;
        _selectedLng = geoPoint.longitude;
      }

      final rawSkills = data["skills"];
      if (rawSkills is List) {
        _skills = List<String>.from(rawSkills);
      }

      final rawContacts = data["emergencyContacts"];
      if (rawContacts is List) {
        for (final c in rawContacts) {
          _emergencyContacts.add({
            "name": TextEditingController(text: c["name"] ?? ""),
            "phone": TextEditingController(text: c["phone"] ?? ""),
          });
        }
      }

      // Ensure minimum 2 contacts
      while (_emergencyContacts.length < 2) {
        _emergencyContacts.add({
          "name": TextEditingController(),
          "phone": TextEditingController(),
        });
      }
    } catch (e) {
      _showSnack("Failed to load profile: $e");
    } finally {
      setState(() => _isFetching = false);
    }
  }

  Future<void> _pickProfileImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) setState(() => _profileImage = File(picked.path));
  }

  void _addSkill() {
    final skill = _skillController.text.trim();
    if (skill.isNotEmpty && !_skills.contains(skill)) {
      setState(() {
        _skills.add(skill);
        _skillController.clear();
      });
    }
  }

  void _removeSkill(String skill) => setState(() => _skills.remove(skill));

  void _addEmergencyContact() {
    if (_emergencyContacts.length >= 5) return;
    setState(() {
      _emergencyContacts.add({
        "name": TextEditingController(),
        "phone": TextEditingController(),
      });
    });
  }

  void _removeEmergencyContact(int index) {
    if (_emergencyContacts.length <= 2) return;
    _emergencyContacts[index]["name"]!.dispose();
    _emergencyContacts[index]["phone"]!.dispose();
    setState(() => _emergencyContacts.removeAt(index));
  }

  bool _validateEmergencyContacts() {
    for (final c in _emergencyContacts) {
      final name = c["name"]!.text.trim();
      final phone = c["phone"]!.text.trim();
      if (name.isEmpty || phone.isEmpty || phone.length < 10) return false;
    }
    return true;
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedLat == null || _selectedLng == null) {
      _showSnack("Please pick your location");
      return;
    }
    if (!_validateEmergencyContacts()) {
      _showSnack("Fill all emergency contacts with valid 10-digit numbers");
      return;
    }

    setState(() => _isLoading = true);

    try {
      String profileUrl = _existingProfileUrl ?? "";

      // Upload new profile image if changed
      if (_profileImage != null) {
        final ref = FirebaseStorage.instance
            .ref()
            .child("profile_images")
            .child(widget.userId)
            .child(p.basename(_profileImage!.path));
        await ref.putFile(_profileImage!);
        profileUrl = await ref.getDownloadURL();
      }

      final emergencyList = _emergencyContacts
          .map((c) => {
                "name": c["name"]!.text.trim(),
                "phone": c["phone"]!.text.trim(),
              })
          .toList();

      await FirebaseFirestore.instance
          .collection("users")
          .doc(widget.userId)
          .update({
        "name": _nameController.text.trim(),
        "age": int.tryParse(_ageController.text.trim()) ?? 0,
        "gender": _selectedGender,
        "location": _locationController.text.trim(),
        "locationGeoPoint": GeoPoint(_selectedLat!, _selectedLng!),
        "skills": _skills,
        "profileImage": profileUrl,
        "emergencyContacts": emergencyList,
        "isAvailable": _isAvailable,
      });

      if (mounted) {
        _showSnack("Profile updated successfully!", success: true);
        Navigator.pop(context, true); // return true to signal refresh
      }
    } catch (e) {
      _showSnack("Error saving profile: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnack(String msg, {bool success = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: success ? Colors.green : Colors.redAccent,
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  BUILD
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Icon(Icons.arrow_back, color: Color.fromARGB(255, 0, 0, 0)),
        ),
        centerTitle: true,
        title: const Text(
          "Edit Profile",
          style: TextStyle(
            color: Color.fromARGB(255, 0, 0, 0),
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
      ),
      body: _isFetching
          ? const Center(child: CircularProgressIndicator(color: _amber))
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 24),
                children: [
                  _buildProfilePhoto(),
                  const SizedBox(height: 24),
                  _buildWorkStatus(),
                  const SizedBox(height: 20),
                  _buildInfoCard(),
                  const SizedBox(height: 20),
                  _buildEmergencySection(),
                  const SizedBox(height: 30),
                  _buildSaveButton(),
                  const SizedBox(height: 30),
                ],
              ),
            ),
    );
  }

  // ── Profile Photo ──────────────────────────────────────────────────────────

  Widget _buildProfilePhoto() {
    return Center(
      child: GestureDetector(
        onTap: _pickProfileImage,
        child: Stack(
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: _lightAmber,
                image: _profileImage != null
                    ? DecorationImage(
                        image: FileImage(_profileImage!),
                        fit: BoxFit.cover,
                      )
                    : _existingProfileUrl != null
                        ? DecorationImage(
                            image: NetworkImage(_existingProfileUrl!),
                            fit: BoxFit.cover,
                          )
                        : null,
              ),
              child: (_profileImage == null && _existingProfileUrl == null)
                  ? const Icon(Icons.person, size: 50, color: _amber)
                  : null,
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: 30,
                height: 30,
                decoration: const BoxDecoration(
                  color: _amber,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.edit, size: 16, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Work Status ────────────────────────────────────────────────────────────

  Widget _buildWorkStatus() {
    return _card(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "WORK STATUS",
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _isAvailable ? "Available for work" : "Not available",
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: _isAvailable ? _amber : Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _isAvailable,
            onChanged: (v) => setState(() => _isAvailable = v),
            activeColor: Colors.white,
            activeTrackColor: _amber,
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: Colors.grey.shade300,
          ),
        ],
      ),
    );
  }

  // ── Info Card (name, age, gender, location, skills) ────────────────────────

  Widget _buildInfoCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _fieldLabel("FULL NAME"),
          _underlineField(
            controller: _nameController,
            hint: "Enter your full name",
            validator: (v) =>
                v == null || v.isEmpty ? "Name is required" : null,
          ),
          const SizedBox(height: 18),
          _fieldLabel("AGE"),
          _underlineField(
            controller: _ageController,
            hint: "Enter your age",
            keyboardType: TextInputType.number,
            validator: (v) =>
                v == null || v.isEmpty ? "Age is required" : null,
          ),
          const SizedBox(height: 18),
          _fieldLabel("GENDER"),
          DropdownButtonFormField<String>(
            value: _selectedGender,
            decoration: InputDecoration(
              hintText: "Select gender",
              hintStyle: const TextStyle(color: Colors.grey),
              enabledBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: _borderColor),
              ),
              focusedBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: _amber),
              ),
            ),
            items: ["Male", "Female", "Other"]
                .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                .toList(),
            onChanged: (v) => setState(() => _selectedGender = v),
            validator: (v) => v == null ? "Required" : null,
          ),
          const SizedBox(height: 18),
          _fieldLabel("LOCATION"),
          GestureDetector(
            onTap: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const LocationPickerScreen(),
                ),
              );
              if (result != null) {
                setState(() {
                  _locationController.text = result["address"];
                  _selectedLat = result["lat"];
                  _selectedLng = result["lng"];
                });
              }
            },
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _locationController.text.isEmpty
                        ? "Tap to pick location"
                        : _locationController.text,
                    style: TextStyle(
                      fontSize: 15,
                      color: _locationController.text.isEmpty
                          ? Colors.grey
                          : Colors.black87,
                    ),
                  ),
                ),
                const Icon(Icons.location_on, color: _amber, size: 20),
              ],
            ),
          ),
          const Divider(color: _borderColor, height: 24),
          const SizedBox(height: 4),
          _fieldLabel("SKILLS & EXPERTISE"),
          const SizedBox(height: 10),
          if (_skills.isNotEmpty) ...[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _skills.map(_skillChip).toList(),
            ),
            const SizedBox(height: 12),
          ],
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _skillController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    hintText: "Add new skill...",
                    hintStyle: TextStyle(color: Colors.grey),
                    border: InputBorder.none,
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: _borderColor),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: _amber),
                    ),
                  ),
                  onSubmitted: (_) => _addSkill(),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: _addSkill,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    color: _amber,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.add, color: Colors.white, size: 18),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            "Type a skill and tap the icon to add it.",
            style: TextStyle(fontSize: 11, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  // ── Emergency Contacts ─────────────────────────────────────────────────────

  Widget _buildEmergencySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              "Emergency Contacts",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFFFE0E0),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                "MINIMUM 2",
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.red,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        ...List.generate(
            _emergencyContacts.length, (i) => _contactCard(i)),
        if (_emergencyContacts.length < 5)
          GestureDetector(
            onTap: _addEmergencyContact,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                border: Border.all(
                  color: _amber.withOpacity(0.5),
                  style: BorderStyle.solid,
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add, color: _amber, size: 18),
                  SizedBox(width: 6),
                  Text(
                    "Add More Contact",
                    style: TextStyle(
                      color: _amber,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _contactCard(int index) {
    final label = index == 0
        ? "PRIMARY CONTACT"
        : index == 1
            ? "SECONDARY CONTACT"
            : "CONTACT ${index + 1}";
    final isRemovable = _emergencyContacts.length > 2;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.contacts_rounded, color: _amber, size: 16),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey,
                  letterSpacing: 0.8,
                ),
              ),
              const Spacer(),
              if (isRemovable)
                GestureDetector(
                  onTap: () => _removeEmergencyContact(index),
                  child: const Icon(Icons.remove_circle_outline,
                      color: Colors.red, size: 18),
                ),
            ],
          ),
          const SizedBox(height: 12),
          _contactField(
            controller: _emergencyContacts[index]["name"]!,
            hint: "Full name",
          ),
          const SizedBox(height: 8),
          _contactField(
            controller: _emergencyContacts[index]["phone"]!,
            hint: "Phone number",
            keyboardType: TextInputType.phone,
            prefixText: "+91 ",
            maxLength: 10,
          ),
        ],
      ),
    );
  }

  // ── Save Button ────────────────────────────────────────────────────────────

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: _isLoading ? null : _saveChanges,
        icon: _isLoading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                    color: Colors.black, strokeWidth: 2),
              )
            : const Icon(Icons.save_rounded, color: Colors.black, size: 20),
        label: Text(
          _isLoading ? "Saving..." : "Save Changes",
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: _amber,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
        ),
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _fieldLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: Colors.grey,
        letterSpacing: 0.8,
      ),
    );
  }

  Widget _underlineField({
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(fontSize: 15, color: Colors.black87),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.grey),
        border: InputBorder.none,
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: _borderColor),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: _amber),
        ),
        errorBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.red),
        ),
      ),
    );
  }

  Widget _contactField({
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    String? prefixText,
    int? maxLength,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLength: maxLength,
      inputFormatters: keyboardType == TextInputType.phone
          ? [FilteringTextInputFormatter.digitsOnly]
          : null,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.grey),
        prefixText: prefixText,
        counterText: "",
        filled: true,
        fillColor: const Color(0xFFF5F5F5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }

  Widget _skillChip(String skill) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _lightAmber,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _amber.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            skill,
            style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w500),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: () => _removeSkill(skill),
            child: const Icon(Icons.close, size: 14, color: Colors.black54),
          ),
        ],
      ),
    );
  }
}