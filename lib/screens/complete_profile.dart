import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class CompleteProfileScreen extends StatefulWidget {
  const CompleteProfileScreen({super.key});

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

  final ImagePicker _picker = ImagePicker();

  // -------- IMAGE PICKER --------

  Future<void> _pickProfileImage() async {
    final picked =
        await _picker.pickImage(source: ImageSource.gallery);

    if (picked != null) {
      setState(() {
        _profileImage = File(picked.path);
      });
    }
  }

  Future<void> _pickIdImage() async {
    final picked =
        await _picker.pickImage(source: ImageSource.gallery);

    if (picked != null) {
      setState(() {
        _idImage = File(picked.path);
      });
    }
  }

  // -------- ADD SKILL --------

  void _addSkill() {
    String skill = _skillController.text.trim();

    if (skill.isNotEmpty) {
      setState(() {
        skills.add(skill);
        _skillController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading:
            const Icon(Icons.arrow_back, color: Colors.black),
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
            crossAxisAlignment:
                CrossAxisAlignment.start,
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
                            backgroundImage:
                                _profileImage != null
                                    ? FileImage(
                                        _profileImage!)
                                    : null,
                            child: _profileImage == null
                                ? const Icon(
                                    Icons.camera_alt_outlined,
                                    size: 40,
                                    color: Color(
                                        0xFFF5B544),
                                  )
                                : null,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: CircleAvatar(
                              radius: 16,
                              backgroundColor:
                                  const Color(
                                      0xFFF5B544),
                              child: const Icon(
                                Icons.edit,
                                size: 16,
                                color: Colors.white,
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Upload Photo",
                      style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              _label("Full Name"),
              _textField(
                controller: _nameController,
                hint: "Enter your full name",
                validator: (value) =>
                    value == null || value.isEmpty
                        ? "Required"
                        : null,
              ),

              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        _label("Age"),
                        _textField(
                          controller: _ageController,
                          hint: "Ex: 25",
                          keyboardType:
                              TextInputType.number,
                          validator: (value) =>
                              value == null ||
                                      value.isEmpty
                                  ? "Required"
                                  : null,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        _label("Gender"),
                        DropdownButtonFormField<String>(
                          value: _selectedGender,
                          decoration:
                              _inputDecoration(
                                  "Select"),
                          items: ["Male", "Female", "Other"]
                              .map(
                                (g) => DropdownMenuItem(
                                  value: g,
                                  child: Text(g),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedGender = value;
                            });
                          },
                          validator: (value) =>
                              value == null
                                  ? "Required"
                                  : null,
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              _label("Location"),
              _textField(
                controller: _locationController,
                hint: "Enter your city",
                validator: (value) =>
                    value == null || value.isEmpty
                        ? "Required"
                        : null,
              ),

              const SizedBox(height: 30),

              // ---------- ID UPLOAD ----------
              const Text(
                "ID VERIFICATION",
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color.fromARGB(255, 0, 0, 0)),
              ),

              const SizedBox(height: 10),

              GestureDetector(
  onTap: _pickIdImage,
  child: Container(
    width: double.infinity, // 🔥 increased width
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      border: Border.all(
        color: const Color(0xFFE0E0E0),
      ),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Stack(
      children: [

        // Main Content
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _idImage != null
                  ? Image.file(
                      _idImage!,
                      height: 120,
                      fit: BoxFit.cover,
                    )
                  : const Icon(
                      Icons.badge_outlined,
                      size: 40,
                      color: Colors.grey,
                    ),
              const SizedBox(height: 10),
              const Text(
                "Upload any government-issued ID",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),

        // ❌ Remove Button (Top Right)
        if (_idImage != null)
          Positioned(
            top: 0,
            right: 0,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _idImage = null;
                });
              },
              child: Container(
                decoration: const BoxDecoration(
                  color: Color.fromARGB(255, 0, 0, 0),
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
    ),
  ),
),

              const SizedBox(height: 30),

              // ---------- SKILLS ----------
              const Text(
                "ADD SKILLS",
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey),
              ),

              const SizedBox(height: 10),

              Wrap(
                spacing: 8,
                children: skills
                    .map(
                      (skill) => Chip(
                        label: Text(skill),
                        deleteIcon: const Icon(
                            Icons.close,
                            size: 18),
                        onDeleted: () {
                          setState(() {
                            skills.remove(skill);
                          });
                        },
                      ),
                    )
                    .toList(),
              ),

              const SizedBox(height: 10),

              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller:
                          _skillController,
                      decoration:
                          _inputDecoration(
                              "Type a skill"),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    radius: 22,
                    backgroundColor:
                        const Color(0xFFF5B544),
                    child: IconButton(
                      icon: const Icon(Icons.add,
                          color: Colors.white),
                      onPressed: _addSkill,
                    ),
                  )
                ],
              ),

              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    if (_formKey
                        .currentState!
                        .validate()) {

                      if (_profileImage ==
                              null ||
                          _idImage ==
                              null) {
                        ScaffoldMessenger.of(context)
                            .showSnackBar(
                          const SnackBar(
                              content: Text(
                                  "Photo and ID required")),
                        );
                        return;
                      }

                      // Save profile logic
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        const Color(0xFFF5B544),
                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    "Save & Continue",
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight:
                            FontWeight.w600,
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

  Widget _label(String text) {
    return Text(
      text,
      style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500),
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType =
        TextInputType.text,
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
      contentPadding:
          const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14),
      enabledBorder: OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(12),
        borderSide:
            const BorderSide(
                color:
                    Color(0xFFE0E0E0)),
      ),
      focusedBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(12),
        borderSide:
            const BorderSide(
                color:
                    Colors.orange),
      ),
    );
  }
}
