import 'package:flutter/material.dart';
import "saved_screen.dart";
import "job_details_screen.dart";

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int currentIndex = 0;
  String selectedType = "All";
  String selectedSort = "None";
  String searchText = "";

  List<Map<String, dynamic>> jobs = [
    {
      "type": "FULL-TIME",
      "title": "Warehouse Assistant",
      "location": "Mumbai, Maharashtra",
      "salary": 1800,
      "date": "Nov 25, 2026",
      "time": "2h ago",
    },
    {
      "type": "CONTRACT",
      "title": "Gardener / Landscaper",
      "location": "Bangalore, Karnataka",
      "salary": 1200,
      "date": "Nov 25, 2026",
      "time": "5h ago",
    },
    {
      "type": "PART-TIME",
      "title": "Delivery Associate",
      "location": "New Delhi",
      "salary": 2250,
      "date": "Nov 25, 2026",
      "time": "1d ago",
    },
  ];

  @override
  Widget build(BuildContext context) {
    List filteredJobs = jobs.where((job) {
      final matchesSearch = job["title"].toLowerCase().contains(
        searchText.toLowerCase(),
      );

      final matchesType = selectedType == "All" || job["type"] == selectedType;

      return matchesSearch && matchesType;
    }).toList();

    if (selectedSort == "Salary: Low to High") {
      filteredJobs.sort((a, b) => a["salary"].compareTo(b["salary"]));
    } else if (selectedSort == "Salary: High to Low") {
      filteredJobs.sort((a, b) => b["salary"].compareTo(a["salary"]));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),

      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 10),

            // LOCATION + TITLE + NOTIFICATION
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Icon(Icons.location_on, color: Color(0xFFFFB544)),
                  const SizedBox(width: 5),
                  const Expanded(
                    child: Text(
                      "Mumbai, Maharashtra",
                      style: TextStyle(fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Text(
                    "LocalHire",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  Stack(
                    children: const [
                      Icon(Icons.notifications_none, size: 28),
                      Positioned(
                        right: 2,
                        top: 2,
                        child: CircleAvatar(
                          radius: 4,
                          backgroundColor: Colors.red,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 15),

            // SEARCH BAR
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                onChanged: (value) {
                  setState(() {
                    searchText = value;
                  });
                },
                decoration: InputDecoration(
                  hintText: "Search for jobs",
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.grey.shade200,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 15),

            // FILTER + SORT
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.shade200,
                      foregroundColor: Colors.black,
                      elevation: 0,
                    ),
                    onPressed: _showFilterDialog,
                    icon: const Icon(Icons.tune),
                    label: const Text("Filter"),
                  ),

                  const SizedBox(width: 10),

                  DropdownButton<String>(
                    value: selectedSort == "None" ? null : selectedSort,
                    hint: const Text("Sort By"),
                    items: const [
                      DropdownMenuItem(
                        value: "Salary: Low to High",
                        child: Text("Salary: Low to High"),
                      ),
                      DropdownMenuItem(
                        value: "Salary: High to Low",
                        child: Text("Salary: High to Low"),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        selectedSort = value!;
                      });
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 15),

            // JOB LIST
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: filteredJobs.length,
                itemBuilder: (context, index) {
                  return _jobCard(filteredJobs[index]);
                },
              ),
            ),
          ],
        ),
      ),

      // BOTTOM NAVIGATION
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFFFFB544),
        unselectedItemColor: Colors.grey,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
        showUnselectedLabels: true,
        onTap: (index) {
          if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => SavedScreen()),
            );
          } else {
            setState(() {
              currentIndex = index;
            });
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite_border),
            label: "Saved",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle, size: 35),
            label: "",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            label: "Chat",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: "Profile",
          ),
        ],
      ),
    );
  }

  Widget _jobCard(Map<String,dynamic> job) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFE7BF),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  job["type"],
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(job["time"]),
              const Spacer(),
              Text(
                "₹${job["salary"]}",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            job["title"],
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.location_on, size: 16, color: Colors.grey),
              const SizedBox(width: 4),
              Text(job["location"]),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(job["date"]),
              const Spacer(),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFB544),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => JobDetailsScreen(job:job),
                    ),
                  );
                },
                child: const Text("View"),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Filter by Type"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _filterOption("All"),
              _filterOption("FULL-TIME"),
              _filterOption("CONTRACT"),
              _filterOption("PART-TIME"),
            ],
          ),
        );
      },
    );
  }

  Widget _filterOption(String type) {
    return ListTile(
      title: Text(type),
      onTap: () {
        setState(() {
          selectedType = type;
        });
        Navigator.pop(context);
      },
    );
  }
}
