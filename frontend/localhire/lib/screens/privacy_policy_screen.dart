import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

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
          "Privacy Policy",
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

              /// Title
              TextSpan(
                text: "LocalHire Privacy Policy\n\n",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              TextSpan(
                text:
                    "Last Updated: March 2026\n\n"
                    "LocalHire is committed to protecting your privacy and ensuring the security of your personal information. "
                    "This Privacy Policy explains how we collect, use, store, and protect your data when you use our platform.\n\n",
              ),

              /// 1
              TextSpan(
                text: "1. Information We Collect\n",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              TextSpan(
                text:
                    "We may collect personal information such as your name, phone number, email address, and profile photo. "
                    "We may also collect verification information including government-issued ID proof when required. "
                    "Additionally, we collect usage data such as your activity within the app and location data to enable nearby job matching.\n\n",
              ),

              /// 2
              TextSpan(
                text: "2. How We Use Your Information\n",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              TextSpan(
                text:
                    "Your information is used to create and manage your account, match you with relevant jobs or workers, "
                    "improve our services, and ensure the safety and reliability of the platform. "
                    "We may also use your data to communicate important updates and notifications.\n\n",
              ),

              /// 3
              TextSpan(
                text: "3. Profile and Identity Verification\n",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              TextSpan(
                text:
                    "To maintain trust and authenticity, we verify whether your profile image represents a real individual. "
                    "We also verify whether uploaded documents are valid identity proofs. "
                    "These steps help prevent misuse and improve safety for all users on the platform.\n\n",
              ),

              /// 4
              TextSpan(
                text: "4. Data Sharing\n",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              TextSpan(
                text:
                    "LocalHire does not sell or share your personal data with third parties for marketing purposes. "
                    "However, in cases involving fraud, safety concerns, or legal obligations, "
                    "we may share necessary user information with law enforcement authorities when legally required.\n\n",
              ),

              /// 5
              TextSpan(
                text: "5. Data Security\n",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              TextSpan(
                text:
                    "We use secure technologies and best practices to protect your data from unauthorized access, loss, or misuse. "
                    "While we strive to protect your information, no system is completely secure, and users are encouraged to protect their account credentials.\n\n",
              ),

              /// 6
              TextSpan(
                text: "6. User Controls and Rights\n",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              TextSpan(
                text:
                    "You have the right to update or modify your personal information at any time. "
                    "You can control certain privacy settings such as profile visibility and phone number sharing. "
                    "You may also request account deletion if you no longer wish to use the platform.\n\n",
              ),

              /// 7
              TextSpan(
                text: "7. Data Retention\n",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              TextSpan(
                text:
                    "We retain your data for as long as your account remains active. "
                    "After account deletion, your data may be removed or retained as required for legal, safety, or compliance purposes.\n\n",
              ),

              /// 8
              TextSpan(
                text: "8. Children's Privacy\n",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              TextSpan(
                text:
                    "LocalHire is not intended for users under the age of 18. "
                    "We do not knowingly collect personal information from children.\n\n",
              ),

              /// 9
              TextSpan(
                text: "9. Changes to This Policy\n",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              TextSpan(
                text:
                    "We may update this Privacy Policy from time to time. "
                    "Users will be notified of significant changes. Continued use of the app after updates indicates acceptance of the revised policy.\n\n",
              ),

              /// 10
              TextSpan(
                text: "10. Contact\n",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              TextSpan(
                text:
                    "If you have any questions or concerns regarding this Privacy Policy, please contact us at:\n\nsupport@localhire.app",
              ),
            ],
          ),
        ),
      ),
    );
  }
}