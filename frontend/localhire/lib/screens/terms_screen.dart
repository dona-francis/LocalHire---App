import 'package:flutter/material.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  static const _amber = Color(0xFFF5B544);
  static const _bg = Color(0xFFF7F7F7);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Icon(Icons.arrow_back, color: _amber),
        ),
        centerTitle: true,
        title: const Text(
          "Terms of Service",
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: RichText(
          text: const TextSpan(
            style: TextStyle(
              color: Colors.black87,
              fontSize: 14,
              height: 1.7,
            ),
            children: [

              TextSpan(
                text: "LocalHire Terms of Service\n\n",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              /// Introduction
              TextSpan(
                text: "Introduction\n",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              TextSpan(
                text:
                    "Welcome to LocalHire. By accessing or using our platform, you agree to be bound by these Terms of Service. "
                    "These terms govern your use of the application and its services. If you do not agree with any part of these terms, "
                    "you should not use the platform.\n\n",
              ),

              /// About
              TextSpan(
                text: "About LocalHire\n",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              TextSpan(
                text:
                    "LocalHire is a location-based platform that connects job providers with nearby workers for instant, online, "
                    "and offline jobs. The platform acts only as an intermediary and does not directly employ workers or guarantee job outcomes.\n\n",
              ),

              /// Accounts
              TextSpan(
                text: "User Accounts and Eligibility\n",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              TextSpan(
                text:
                    "Users must provide accurate, complete, and up-to-date information while creating an account. "
                    "You are responsible for maintaining the confidentiality of your login credentials. "
                    "Impersonation, false information, or misuse of another person’s identity is strictly prohibited.\n\n",
              ),

              /// Profile
              TextSpan(
                text: "Profile Verification Policy\n",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              TextSpan(
                text:
                    "To maintain trust and safety, users must upload a clear profile image of themselves. "
                    "Cartoon images, group photos, or images that do not clearly represent the user are not allowed. "
                    "If such images are detected, the account may be temporarily restricted. "
                    "Users will be notified and allowed to update their profile image to regain access.\n\n",
              ),

              /// ID
              TextSpan(
                text: "Identity (ID) Verification\n",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              TextSpan(
                text:
                    "Users may be required to upload a valid government-issued identity proof for verification purposes. "
                    "LocalHire verifies whether the uploaded image is a valid ID document. "
                    "These documents are securely stored and used only for verification and safety purposes. "
                    "Users must ensure that the submitted documents are genuine and belong to them.\n\n",
              ),

              /// Data
              TextSpan(
                text: "Data Usage and Legal Compliance\n",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              TextSpan(
                text:
                    "LocalHire is committed to protecting user data. Personal information, including ID proofs, is not shared publicly "
                    "or with unauthorized parties. However, in cases involving serious complaints, fraud, or safety concerns, "
                    "LocalHire may share relevant user information with law enforcement authorities when legally required.\n\n",
              ),

              /// Conduct
              TextSpan(
                text: "User Responsibilities and Conduct\n",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              TextSpan(
                text:
                    "Users agree to use the platform responsibly. This includes providing accurate job details, maintaining respectful communication, "
                    "and avoiding illegal, abusive, or harmful behavior. Any misuse of the platform may result in account suspension or termination.\n\n",
              ),

              /// Disclaimer
              TextSpan(
                text: "Job Disclaimer\n",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              TextSpan(
                text:
                    "LocalHire only facilitates connections between users and does not guarantee the quality of work, behavior of users, "
                    "or completion of jobs and payments. Users are advised to exercise their own judgment before accepting or offering any job.\n\n",
              ),

              /// Suspension
              TextSpan(
                text: "Account Suspension and Termination\n",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              TextSpan(
                text:
                    "LocalHire reserves the right to restrict, suspend, or permanently remove accounts that violate these terms. "
                    "This includes fake profiles, submission of invalid documents, or misuse of platform features. "
                    "Users may be notified before such actions are taken where applicable.\n\n",
              ),

              /// Liability
              TextSpan(
                text: "Limitation of Liability\n",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              TextSpan(
                text:
                    "LocalHire is not responsible for any disputes, damages, losses, or incidents arising from interactions between users. "
                    "All engagements are carried out at the users’ own risk.\n\n",
              ),

              /// Changes
              TextSpan(
                text: "Changes to Terms\n",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              TextSpan(
                text:
                    "These Terms of Service may be updated from time to time. Users will be notified of significant changes. "
                    "Continued use of the platform after updates constitutes acceptance of the revised terms.\n\n",
              ),

              /// Contact
              TextSpan(
                text: "Contact\n",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              TextSpan(
                text:
                    "If you have any questions or concerns regarding these Terms of Service, please contact us at:\n\nsupport@localhire.app",
              ),
            ],
          ),
        ),
      ),
    );
  }
}