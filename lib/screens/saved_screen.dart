import 'package:flutter/material.dart';

class SavedScreen extends StatefulWidget {
  const SavedScreen({super.key});

  @override
  State<SavedScreen> createState() => _SavedScreenState();
}

class _SavedScreenState extends State<SavedScreen> {

  TextEditingController searchController = TextEditingController();

  List<Map<String, String>> savedProfiles = [
    {
      "name": "Arun Kumar",
      "location": "Mumbai, Maharashtra",
      "image": "https://randomuser.me/api/portraits/men/32.jpg"
    },
    {
      "name": "Priya Sharma",
      "location": "Pune, Maharashtra",
      "image": "https://randomuser.me/api/portraits/women/44.jpg"
    },
    {
      "name": "Rajesh Singh",
      "location": "Bengaluru, Karnataka",
      "image": "https://randomuser.me/api/portraits/men/45.jpg"
    },
    {
      "name": "Ananya Rao",
      "location": "Hyderabad, Telangana",
      "image": "https://randomuser.me/api/portraits/women/68.jpg"
    },
    {
      "name": "Suresh G.",
      "location": "Chennai, Tamil Nadu",
      "image": "https://randomuser.me/api/portraits/men/75.jpg"
    },
  ];

  @override
  Widget build(BuildContext context) {

    List<Map<String, String>> filteredList = savedProfiles.where((profile) {
      return profile["name"]!
          .toLowerCase()
          .contains(searchController.text.toLowerCase());
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          "My Saved Profiles",
          style: TextStyle(color: Colors.black),
        ),
        centerTitle: true,
      ),

      body: Column(
        children: [

          // 🔍 SEARCH BAR
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: searchController,
              onChanged: (value) {
                setState(() {});
              },
              decoration: InputDecoration(
                hintText: "Search profiles...",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // PROFILE LIST
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: filteredList.length,
              itemBuilder: (context, index) {

                var profile = filteredList[index];

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFE8DD),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundImage:
                            NetworkImage(profile["image"]!),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              profile["name"]!,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(Icons.location_on,
                                    size: 16,
                                    color: Colors.grey),
                                const SizedBox(width: 4),
                                Text(
                                  profile["location"]!,
                                  style: const TextStyle(
                                      color: Colors.grey),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // ❤️ REMOVE BUTTON
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            savedProfiles.remove(profile);
                          });
                        },
                        child: const Icon(
                          Icons.favorite,
                          color: Colors.red,
                          size: 28,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
