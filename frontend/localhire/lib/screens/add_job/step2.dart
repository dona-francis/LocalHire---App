import 'package:flutter/material.dart';
import 'add_job_screen.dart';

class Step2 extends StatefulWidget {
  final VoidCallback onNext;
  final JobData jobData;

  const Step2({
    super.key,
    required this.onNext,
    required this.jobData,
  });

  @override
  State<Step2> createState() => _Step2State();
}

class _Step2State extends State<Step2> {
  final TextEditingController _descriptionController =
      TextEditingController();

  int wordCount = 0;

  void _updateWordCount(String text) {
    setState(() {
      wordCount = text.trim().isEmpty
          ? 0
          : text.trim().split(RegExp(r'\s+')).length;
      widget.jobData.description = text;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              /// Progress Bar
              Row(
                children: List.generate(
                  6,
                  (index) => Expanded(
                    child: Container(
                      margin:
                          const EdgeInsets.symmetric(horizontal: 2),
                      height: 6,
                      decoration: BoxDecoration(
                        color: index < 2
                            ? const Color(0xFFF2B84B)
                            : Colors.grey.shade300,
                        borderRadius:
                            BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              /// Title
              const Text(
                "Describe your task in detail",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4A4A4A),
                ),
              ),

              const SizedBox(height: 4),

              const Text(
                "Include specific requirements and expectations",
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF757575),
                ),
              ),

              const SizedBox(height: 16),

              /// Description Box
              Stack(
                children: [
                  TextField(
                    controller: _descriptionController,
                    maxLines: 7,
                    onChanged: _updateWordCount,
                    decoration: InputDecoration(
                      hintText:
                          "Describe your task in detail (max 250 words)...",
                      hintStyle:
                          const TextStyle(color: Colors.grey),
                      contentPadding:
                          const EdgeInsets.all(16),
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(20),
                        borderSide: BorderSide(
                            color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(20),
                        borderSide: const BorderSide(
                            color: Color(0xFFF2B84B),
                            width: 2),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 12,
                    right: 16,
                    child: Text(
                      "$wordCount / 250 words",
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF757575),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              /// ✅ Instant Job Toggle
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius:
                      BorderRadius.circular(16),
                  border: Border.all(
                      color: Colors.grey.shade200),
                ),
                child: Row(
                  mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: const [
                        Text(
                          "Instant Job",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF4A4A4A),
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          "Workers can apply immediately",
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF757575),
                          ),
                        ),
                      ],
                    ),
                    Switch(
                      value:
                          widget.jobData.isInstantJob,
                      activeColor:
                          const Color(0xFFF2B84B),
                      onChanged: (value) {
                        setState(() {
                          widget.jobData.isInstantJob =
                              value;
                        });
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              /// Pro Tip Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color:
                      const Color(0xFFF6E7C9)
                          .withOpacity(0.3),
                  borderRadius:
                      BorderRadius.circular(16),
                  border: Border.all(
                    color:
                        const Color(0xFFF6E7C9),
                  ),
                ),
                child: Row(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: const [
                    Icon(Icons.lightbulb,
                        color:
                            Color(0xFFF2B84B)),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "Pro Tip: Mention the tools needed, details about the workplace, and how many hours it may take.",
                        style: TextStyle(
                          fontSize: 13,
                          color:
                              Color(0xFF4A4A4A),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              /// Save & Continue Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        const Color(0xFFF2B84B),
                    foregroundColor:
                        const Color(0xFF4A4A4A),
                    padding:
                        const EdgeInsets.symmetric(
                            vertical: 18),
                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(
                              20),
                    ),
                    elevation: 8,
                  ),
                  onPressed: widget.onNext,
                  child: const Text(
                    "Save & Continue",
                    style: TextStyle(
                        fontWeight:
                            FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}