import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'home_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:path/path.dart' as p;
import '../services/auth_service.dart';

class CompleteProfileScreen extends StatefulWidget {
  final String username;
  final String password;
  final String phone;

  const CompleteProfileScreen({
    super.key,
    required this.username,
    required this.password,
    required this.phone,
  });

  @override
  State<CompleteProfileScreen> createState() =>
      _CompleteProfileScreenState();
}

class _CompleteProfileScreenState
    extends State<CompleteProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController =
      TextEditingController();
  final TextEditingController _ageController =
      TextEditingController();
  final TextEditingController _locationController =
      TextEditingController();
  final TextEditingController _skillController =
      TextEditingController();

  String? _selectedGender;
  List<String> skills = [];

  File? _profileImage;
  File? _idImage;

  bool _isLoading = false;

  final ImagePicker _picker = ImagePicker();

  // 🔐 Encryption Key
  final _key =
      encrypt.Key.fromUtf8('12345678901234567890123456789012');
  final _iv = encrypt.IV.fromLength(16);

  String encryptData(String data) {
    final encrypter = encrypt.Encrypter(encrypt.AES(_key));
    final encrypted = encrypter.encrypt(data, iv: _iv);
    return encrypted.base64;
  }

  Future<void> _pickProfileImage() async {
    final picked =
        await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _profileImage = File(picked.path));
    }
  }

  Future<void> _pickIdImage() async {
    final picked =
        await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _idImage = File(picked.path));
    }
  }

  Future<void> _saveProfile() async {
    setState(() => _isLoading = true);

    try {
      final authService = AuthService();
      final hashedPassword =
          authService.hashPassword(widget.password);

      final userDoc = FirebaseFirestore.instance
          .collection("users")
          .doc();
      final userId = userDoc.id;

      // Upload Profile Image
      final profileRef = FirebaseStorage.instance
          .ref()
          .child("profile_images")
          .child(userId)
          .child(p.basename(_profileImage!.path));
      await profileRef.putFile(_profileImage!);
      final profileUrl = await profileRef.getDownloadURL();

      // Upload ID Image
      final idRef = FirebaseStorage.instance
          .ref()
          .child("id_proofs")
          .child(userId)
          .child(p.basename(_idImage!.path));
      await idRef.putFile(_idImage!);
      final idUrl = await idRef.getDownloadURL();

      // Encrypt ID URL
      final encryptedId = encryptData(idUrl);

      // Save to Firestore
      await userDoc.set({
        "username": widget.username,
        "password": hashedPassword,
        "phone": widget.phone,
        "name": _nameController.text.trim(),
        "age": int.parse(_ageController.text.trim()),
        "gender": _selectedGender,
        "location": _locationController.text.trim(),
        "skills": skills,
        "profileImage": profileUrl,
        "idProof": encryptedId,
        "verificationStatus": "pending",
        "createdAt": Timestamp.now(),
      });

      await authService.saveSession(userId);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => HomeScreen(userId: userId),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }

    setState(() => _isLoading = false);
  }

  void _addSkill() {
    final skill = _skillController.text.trim();
    if (skill.isNotEmpty && !skills.contains(skill)) {
      setState(() {
        skills.add(skill);
        _skillController.clear();
      });
    }
  }

  void _removeSkill(String skill) {
    setState(() => skills.remove(skill));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: const Icon(Icons.arrow_back, color: Colors.black),
        centerTitle: true,
        title: const Text(
          "Complete your profile",
          style: TextStyle(color: Colors.black),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),

              // ---------- PROFILE PHOTO ----------
              Center(
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: _pickProfileImage,
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundColor:
                                const Color(0xFFFFF3DC),
                            backgroundImage: _profileImage != null
                                ? FileImage(_profileImage!)
                                : null,
                            child: _profileImage == null
                                ? const Icon(
                                    Icons.camera_alt_outlined,
                                    size: 40,
                                    color: Color(0xFFF5B544),
                                  )
                                : null,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: CircleAvatar(
                              radius: 16,
                              backgroundColor:
                                  const Color(0xFFF5B544),
                              child: const Icon(
                                Icons.edit,
                                size: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Upload Photo",
                      style:
                          TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // ---------- FULL NAME ----------
              _label("Full Name"),
              _textField(
                controller: _nameController,
                hint: "Enter your full name",
                validator: (value) =>
                    value == null || value.isEmpty ? "Required" : null,
              ),

              const SizedBox(height: 20),

              // ---------- AGE & GENDER ----------
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _label("Age"),
                        _textField(
                          controller: _ageController,
                          hint: "Ex: 25",
                          keyboardType: TextInputType.number,
                          validator: (value) =>
                              value == null || value.isEmpty
                                  ? "Required"
                                  : null,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _label("Gender"),
                        DropdownButtonFormField<String>(
                          initialValue: _selectedGender,
                          decoration: _inputDecoration("Select"),
                          items: ["Male", "Female", "Other"]
                              .map((g) => DropdownMenuItem(
                                    value: g,
                                    child: Text(g),
                                  ))
                              .toList(),
                          onChanged: (value) =>
                              setState(() => _selectedGender = value),
                          validator: (value) =>
                              value == null ? "Required" : null,
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // ---------- LOCATION ----------
              _label("Location"),
              _textField(
                controller: _locationController,
                hint: "Enter your city",
                validator: (value) =>
                    value == null || value.isEmpty ? "Required" : null,
              ),

              const SizedBox(height: 30),

              // ---------- ID VERIFICATION ----------
              const Text(
                "ID VERIFICATION",
                style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600),
              ),

              const SizedBox(height: 10),

              GestureDetector(
                onTap: _pickIdImage,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: _idImage != null
                          ? const Color(0xFFF5B544)
                          : const Color(0xFFE0E0E0),
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: _idImage != null
                      ? Stack(
                          children: [
                            Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ClipRRect(
                                    borderRadius:
                                        BorderRadius.circular(8),
                                    child: Image.file(
                                      _idImage!,
                                      height: 120,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    "Tap to change",
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                            Positioned(
                              top: 0,
                              right: 0,
                              child: GestureDetector(
                                onTap: () =>
                                    setState(() => _idImage = null),
                                child: Container(
                                  decoration: const BoxDecoration(
                                    color: Colors.black,
                                    shape: BoxShape.circle,
                                  ),
                                  padding: const EdgeInsets.all(4),
                                  child: const Icon(
                                    Icons.close,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        )
                      : Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.badge_outlined,
                                size: 36, color: Colors.grey),
                            const SizedBox(height: 8),
                            const Text(
                              "Upload any government ID for verification",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: 13, color: Colors.grey),
                            ),
                            const SizedBox(height: 10),
                            OutlinedButton.icon(
                              onPressed: _pickIdImage,
                              icon: const Icon(Icons.upload,
                                  size: 16,
                                  color: Color(0xFFF5B544)),
                              label: const Text(
                                "Upload ID",
                                style: TextStyle(
                                    color: Color(0xFFF5B544)),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(
                                    color: Color(0xFFF5B544)),
                                shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(8)),
                              ),
                            ),
                          ],
                        ),
                ),
              ),

              const SizedBox(height: 30),

              // ---------- ADD SKILLS ----------
              const Text(
                "ADD SKILLS",
                style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600),
              ),

              const SizedBox(height: 10),

              // Skill chips
              if (skills.isNotEmpty) ...[
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: skills
                      .map((skill) => _skillChip(skill))
                      .toList(),
                ),
                const SizedBox(height: 12),
              ],

              // Skill input row
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _skillController,
                      textCapitalization:
                          TextCapitalization.words,
                      decoration: _inputDecoration(
                          "Type a skill and press enter"),
                      onFieldSubmitted: (_) => _addSkill(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: _addSkill,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF5B544),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.add,
                          color: Colors.white),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              const Text(
                "e.g. Plumbing, Electrician, Painting, Carpentry",
                style:
                    TextStyle(fontSize: 12, color: Colors.grey),
              ),

              const SizedBox(height: 30),

              // ---------- SAVE BUTTON ----------
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading
                      ? null
                      : () {
                          if (_formKey.currentState!.validate()) {
                            if (_profileImage == null ||
                                _idImage == null) {
                              ScaffoldMessenger.of(context)
                                  .showSnackBar(
                                const SnackBar(
                                    content: Text(
                                        "Photo and ID required")),
                              );
                              return;
                            }
                            _saveProfile();
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF5B544),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(
                          color: Colors.black)
                      : const Text(
                          "Save & Continue",
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black),
                        ),
                ),
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  // Skill chip with remove button
  Widget _skillChip(String skill) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3DC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF5B544)),
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
            child: const Icon(Icons.close,
                size: 14, color: Colors.black54),
          ),
        ],
      ),
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
            fontSize: 14, fontWeight: FontWeight.w500),
      ),
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      decoration: _inputDecoration(hint),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      contentPadding: const EdgeInsets.symmetric(
          horizontal: 16, vertical: 14),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.orange),
      ),
    );
  }
}
