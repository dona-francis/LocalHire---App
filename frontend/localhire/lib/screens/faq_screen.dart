import 'package:flutter/material.dart';

class FAQScreen extends StatelessWidget {
  const FAQScreen({super.key});

  static const _amber = Color(0xFFF5B544);
  static const _lightAmber = Color(0xFFFFF3DC);
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
          child: const Icon(Icons.arrow_back, color: Color.fromARGB(255, 0, 0, 0)),
        ),
        centerTitle: true,
        title: const Text(
          
          "FAQs",
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        children: [

          /// 🔹 Intro Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _lightAmber,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Row(
              children: [
                Icon(Icons.help_outline, color: _amber),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "Find answers to common questions about using LocalHire.",
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          /// 🔹 General Section
          _sectionTitle("GENERAL"),
          const SizedBox(height: 10),

          _faqCard([
            _faqTile("What is LocalHire?",
                "LocalHire connects nearby workers with people who need jobs done quickly."),

            _divider(),

            _faqTile("How does LocalHire work?",
                "Post a job → Workers nearby get notified → Accept job → Complete → Rate each other."),

            _divider(),

            _faqTile("Who can use LocalHire?",
                "Anyone looking for work or anyone who needs workers."),
          ]),

          const SizedBox(height: 20),

          /// 🔹 Jobs Section
          _sectionTitle("JOBS"),
          const SizedBox(height: 10),

          _faqCard([
            _faqTile("What types of jobs are available?",
                "Instant Jobs, Online Jobs, and Offline Jobs."),

            _divider(),

            _faqTile("How are jobs matched?",
                "Offline jobs are shown based on your location. Online jobs can be done from anywhere."),

            _divider(),

            _faqTile("How do I accept a job?",
                "Select a job and tap Accept."),
          ]),

          const SizedBox(height: 20),

          /// 🔹 Account Section
          _sectionTitle("ACCOUNT"),
          const SizedBox(height: 10),

          _faqCard([
            _faqTile("How do I create a profile?",
                "Sign up and add your name, skills, experience, and profile photo."),

            _divider(),

            _faqTile("Can I edit my profile?",
                "Yes, you can update your profile anytime."),

            _divider(),

            _faqTile("Is my data safe?",
                "Yes, your data is protected using secure authentication."),
          ]),

          const SizedBox(height: 20),

          /// 🔹 Safety Section
          _sectionTitle("SAFETY"),
          const SizedBox(height: 10),

          _faqCard([
            _faqTile("What is SOS feature?",
                "It allows you to send an emergency alert with your location."),

            _divider(),

            _faqTile("What if I face an issue?",
                "You can report problems directly through the app."),
          ]),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  /// 🔹 Section Title
  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: Colors.grey,
        letterSpacing: 1,
      ),
    );
  }

  /// 🔹 Card Container
  Widget _faqCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Column(children: children),
    );
  }

  /// 🔹 FAQ Tile
  Widget _faqTile(String question, String answer) {
    return Theme(
      data: ThemeData().copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16),
        childrenPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        iconColor: _amber,
        collapsedIconColor: Colors.grey,
        title: Text(
          question,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              answer,
              style: const TextStyle(
                color: Colors.grey,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() {
    return const Divider(
      height: 1,
      indent: 16,
      endIndent: 16,
      color: Color(0xFFF0F0F0),
    );
  }
}