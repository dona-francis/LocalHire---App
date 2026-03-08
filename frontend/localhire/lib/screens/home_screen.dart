import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'saved_screen.dart';
import 'job_details_screen.dart';
import 'add_job/add_job_screen.dart';
import 'chat_screen.dart';
import 'notification_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  final String userId;

  const HomeScreen({super.key, required this.userId});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int currentIndex = 0;
  String selectedType = "All";
  String selectedSort = "None";
  String searchText = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 10),
            _header(),
            const SizedBox(height: 15),
            _searchBar(),
            const SizedBox(height: 15),
            _filterSortRow(),
            const SizedBox(height: 15),

            /// FIRESTORE JOB LIST
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection("jobs")
                    .orderBy("createdAt", descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(
                        child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData ||
                      snapshot.data!.docs.isEmpty) {
                    return const Center(
                        child: Text("No Jobs Available"));
                  }

                  List<Map<String, dynamic>> jobs =
                      snapshot.data!.docs.map((doc) {
                    return doc.data()
                        as Map<String, dynamic>;
                  }).toList();

                  /// SEARCH + FILTER
                  List<Map<String, dynamic>> filteredJobs =
                      jobs.where((job) {
                    final matchesSearch = job["title"]
                        .toString()
                        .toLowerCase()
                        .contains(searchText.toLowerCase());

                    final matchesType =
                        selectedType == "All" ||
                            job["jobMode"] == selectedType;

                    return matchesSearch && matchesType;
                  }).toList();

                  /// SORT
                  if (selectedSort ==
                      "Salary: Low to High") {
                    filteredJobs.sort((a, b) =>
                        a["salary"]
                            .compareTo(b["salary"]));
                  } else if (selectedSort ==
                      "Salary: High to Low") {
                    filteredJobs.sort((a, b) =>
                        b["salary"]
                            .compareTo(a["salary"]));
                  }

                  return ListView.builder(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filteredJobs.length,
                    itemBuilder: (context, index) {
                      return _jobCard(filteredJobs[index]);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _bottomNav(),
    );
  }

  Widget _header() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Icon(Icons.location_on, color: Color(0xFFFFB544)),
          SizedBox(width: 5),
          Expanded(
            child: Text(
              "Mumbai, Maharashtra",
              style:
                  TextStyle(fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            "LocalHire",
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold),
          ),
          Spacer(),
          Icon(Icons.notifications_none, size: 28),
        ],
      ),
    );
  }

  Widget _searchBar() {
    return Padding(
      padding:
          const EdgeInsets.symmetric(horizontal: 16),
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
            borderRadius:
                BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _filterSortRow() {
    return Padding(
      padding:
          const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  Colors.grey.shade200,
              foregroundColor: Colors.black,
              elevation: 0,
            ),
            onPressed: _showFilterDialog,
            icon: const Icon(Icons.tune),
            label: const Text("Filter"),
          ),
          const SizedBox(width: 10),
          DropdownButton<String>(
            value:
                selectedSort == "None" ? null : selectedSort,
            hint: const Text("Sort By"),
            items: const [
              DropdownMenuItem(
                value: "Salary: Low to High",
                child:
                    Text("Salary: Low to High"),
              ),
              DropdownMenuItem(
                value: "Salary: High to Low",
                child:
                    Text("Salary: High to Low"),
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
    );
  }

  Widget _bottomNav() {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      type: BottomNavigationBarType.fixed,
      selectedItemColor:
          const Color(0xFFFFB544),
      unselectedItemColor: Colors.grey,
      onTap: (index) {
        if (index == 1) {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) =>
                      const SavedScreen()));
        } else if (index == 2) {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) =>
                      AddJobScreen(
                          userId: widget.userId)));
        } else if (index == 3) {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) =>
                      const ChatScreen()));
        } else if (index == 4) {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) =>
                      ProfileScreen(
                          userId:
                              widget.userId)));
        }
      },
      items: const [
        BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: "Home"),
        BottomNavigationBarItem(
            icon: Icon(Icons.favorite_border),
            label: "Saved"),
        BottomNavigationBarItem(
            icon: Icon(Icons.add_circle, size: 35),
            label: ""),
        BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            label: "Chat"),
        BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: "Profile"),
      ],
    );
  }

 Widget _jobCard(Map<String, dynamic> job) {
  final String type = job["type"] ?? "N/A";
  final String title = job["title"] ?? "No Title";
  final String location = job["location"] ?? "No Location";
  final salary = job["salary"] ?? 0;
  final Timestamp? createdAt = job["createdAt"];

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
              padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(type),
            ),
            const SizedBox(width: 8),
            Text(
              createdAt != null ? _timeAgo(createdAt) : "",
              style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey),
            ),
            const Spacer(),
            Text(
              "₹$salary",
              style: const TextStyle(
                  fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(title,
            style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(Icons.location_on,
                size: 16, color: Colors.grey),
            const SizedBox(width: 4),
            Text(location),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Text(
              createdAt != null ? _formatDate(createdAt) : "",
              style: const TextStyle(
                  color: Colors.grey),
            ),
            const Spacer(),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor:
                      const Color(0xFFFFB544)),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        JobDetailsScreen(job: job),
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

  /// TIME AGO
  String _timeAgo(Timestamp timestamp) {
    final now = DateTime.now();
    final date = timestamp.toDate();
    final diff = now.difference(date);

    if (diff.inMinutes < 60) {
      return "${diff.inMinutes}m ago";
    } else if (diff.inHours < 24) {
      return "${diff.inHours}h ago";
    } else {
      return "${diff.inDays}d ago";
    }
  }

  /// DATE FORMAT
  String _formatDate(Timestamp timestamp) {
    final date = timestamp.toDate();
    return "${date.day} ${_monthName(date.month)}, ${date.year}";
  }

  String _monthName(int month) {
    const months = [
      "Jan",
      "Feb",
      "Mar",
      "Apr",
      "May",
      "Jun",
      "Jul",
      "Aug",
      "Sep",
      "Oct",
      "Nov",
      "Dec"
    ];
    return months[month - 1];
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Filter by Type"),
        content: Column(
          mainAxisSize:
              MainAxisSize.min,
          children: [
            _filterOption("All"),
            _filterOption("INSTANT"),
            _filterOption("OFFLINE"),
            _filterOption("ONLINE"),
          ],
        ),
      ),
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