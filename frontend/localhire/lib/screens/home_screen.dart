import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'saved_screen.dart';
import 'job_details_screen.dart';
import 'add_job/add_job_screen.dart';
import 'chat_screen.dart';
import 'notification_screen.dart';
import 'profile_screen.dart';
import 'location_picker_screen.dart';
import 'package:geolocator/geolocator.dart';

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
  String userLocation = "Loading...";

  double userLat = 0;
  double userLng = 0;

  /// FILTER VARIABLES
  double minPrice = 5;
  double maxPrice = 500000;
  double distance = 100;
  String selectedMode = "All";

  @override
  void initState() {
    super.initState();
    _loadUserLocation();
  }

  /// LOAD USER LOCATION + COORDINATES
  Future<void> _loadUserLocation() async {
    try {

      final doc = await FirebaseFirestore.instance
          .collection("users")
          .doc(widget.userId)
          .get();

      if (doc.exists) {

        final data = doc.data();

        setState(() {

          userLocation = data?["location"] ?? "Unknown";

          GeoPoint geo = data?["locationGeoPoint"];
          if (geo != null) {
            userLat = geo.latitude;
            userLng = geo.longitude;
          }

        });
      }

    } catch (e) {

      setState(() => userLocation = "Unknown");

    }
  }

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
                    return doc.data() as Map<String, dynamic>;
                  }).toList();

                  /// SEARCH + FILTER
                  List<Map<String, dynamic>> filteredJobs =
                  jobs.where((job) {

                    final matchesSearch = job["title"]
                        .toString()
                        .toLowerCase()
                        .contains(searchText.toLowerCase());

                    final isInstant = job["isInstantJob"] ?? false;
                    final type = job["type"] ?? "";

                    final matchesType =
                        selectedType == "All" ||
                            (selectedType == "ONLINE" && type == "ONLINE") ||
                            (selectedType == "OFFLINE" && type == "OFFLINE") ||
                            (selectedType == "INSTANT ONLINE" &&
                                isInstant &&
                                type == "ONLINE") ||
                            (selectedType == "INSTANT OFFLINE" &&
                                isInstant &&
                                type == "OFFLINE");

                    final salary = job["salary"] ?? 0;

                    final matchesPrice =
                        salary >= minPrice && salary <= maxPrice;

                    /// DISTANCE FILTER
                    bool matchesDistance = true;

                    if (job["locationGeoPoint"] != null &&
                        userLat != 0) {

                      GeoPoint geo = job["locationGeoPoint"];

                      double meters =
                      Geolocator.distanceBetween(
                        userLat,
                        userLng,
                        geo.latitude,
                        geo.longitude,
                      );

                      double km = meters / 1000;

                      matchesDistance = km <= distance;
                    }

                    return matchesSearch &&
                        matchesType &&
                        matchesPrice &&
                        matchesDistance;

                  }).toList();

                  /// SORT
                  if (selectedSort == "Salary: Low to High") {

                    filteredJobs.sort((a, b) =>
                        a["salary"].compareTo(b["salary"]));

                  }

                  else if (selectedSort == "Salary: High to Low") {

                    filteredJobs.sort((a, b) =>
                        b["salary"].compareTo(a["salary"]));

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

  /// HEADER
  Widget _header() {

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),

      child: Row(
        children: [

          GestureDetector(
            onTap: () async {

              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                  const LocationPickerScreen(),
                ),
              );

              if (result != null) {

                await FirebaseFirestore.instance
                    .collection("users")
                    .doc(widget.userId)
                    .update({
                  "location": result["address"],
                  "locationGeoPoint": GeoPoint(
                    result["lat"],
                    result["lng"],
                  ),
                });

                setState(() {
                  userLocation = result["address"];
                  userLat = result["lat"];
                  userLng = result["lng"];
                });
              }
            },

            child: Row(
              children: [

                const Icon(Icons.location_on,
                    color: Color(0xFFFFB544)),

                const SizedBox(width: 5),

                Text(
                  userLocation,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),

                const Icon(Icons.arrow_drop_down,
                    color: Colors.grey),

              ],
            ),
          ),

          const Spacer(),

          const Text(
            "LocalHire",
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold),
          ),

          const Spacer(),

          const Icon(Icons.notifications_none,
              size: 28),

        ],
      ),
    );
  }

  /// SEARCH BAR
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

  /// FILTER + SORT
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
            value: selectedSort == "None"
                ? null
                : selectedSort,
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
    );
  }
void _showFilterDialog() {

    showModalBottomSheet(

      context: context,
      isScrollControlled: true,

      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
            top: Radius.circular(25)),
      ),

      builder: (context) {

        return StatefulBuilder(

          builder: (context, setModalState) {

            return Padding(
              padding: const EdgeInsets.all(20),

              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment:
                CrossAxisAlignment.start,

                children: [

                  Row(
                    children: [

                      const Text(
                        "Filters",
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold),
                      ),

                      const Spacer(),

                      IconButton(
                        icon:
                        const Icon(Icons.close),
                        onPressed: () =>
                            Navigator.pop(context),
                      )

                    ],
                  ),

                  const SizedBox(height: 20),

                  const Text(
                    "Mode",
                    style: TextStyle(
                        fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 10),

                  Wrap(
                    spacing: 8,
                    children: [

                      _modeChip("All", setModalState),
                      _modeChip("ONLINE", setModalState),
                      _modeChip("OFFLINE", setModalState),
                      _modeChip("INSTANT ONLINE",
                          setModalState),
                      _modeChip("INSTANT OFFLINE",
                          setModalState),

                    ],
                  ),

                  const SizedBox(height: 25),

                  const Text(
                    "Location",
                    style: TextStyle(
                        fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 10),

                  Container(
                    padding:
                    const EdgeInsets.symmetric(
                        horizontal: 15,
                        vertical: 12),

                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius:
                      BorderRadius.circular(12),
                    ),

                    child: Row(
                      children: [

                        const Icon(Icons.location_on,
                            color:
                            Color(0xFFFFB544)),

                        const SizedBox(width: 10),

                        Expanded(
                            child:
                            Text(userLocation)),

                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  Row(
                    mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,

                    children: [

                      const Text("Distance",
                          style: TextStyle(
                              fontWeight:
                              FontWeight.bold)),

                      Text("${distance.round()} km"),

                    ],
                  ),

                  Slider(
                    min: 1,
                    max: 300,
                    value: distance,

                    activeColor:
                    const Color(0xFFFFB544),

                    onChanged: (value) {

                      setModalState(() {
                        distance = value;
                      });

                    },
                  ),

                  const SizedBox(height: 10),

                  Row(
                    mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,

                    children: [

                      const Text("Price",
                          style: TextStyle(
                              fontWeight:
                              FontWeight.bold)),

                      Text(
                          "₹${minPrice.round()} - ₹${maxPrice.round()}"),

                    ],
                  ),

                  RangeSlider(
                    min: 5,
                    max: 500000,

                    activeColor:
                    const Color(0xFFFFB544),

                    values:
                    RangeValues(minPrice, maxPrice),

                    onChanged: (values) {

                      setModalState(() {

                        minPrice = values.start;
                        maxPrice = values.end;

                      });

                    },
                  ),

                  const SizedBox(height: 20),

                  Row(
                    children: [

                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {

                            setModalState(() {

                              selectedMode = "All";
                              minPrice = 5;
                              maxPrice = 500000;
                              distance = 100;

                            });

                          },

                          child:
                          const Text("Reset"),
                        ),
                      ),

                      const SizedBox(width: 10),

                      Expanded(
                        child: ElevatedButton(
                          style:
                          ElevatedButton.styleFrom(
                            backgroundColor:
                            const Color(
                                0xFFFFB544),
                          ),

                          onPressed: () {

                            setState(() {
                              selectedType =
                                  selectedMode;
                            });

                            Navigator.pop(context);
                          },

                          child:
                          const Text("Apply"),
                        ),
                      ),

                    ],
                  ),

                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _modeChip(
      String label, Function setModalState) {

    final bool selected =
        selectedMode == label;

    return ChoiceChip(
      label: Text(label),
      selected: selected,
      selectedColor:
      const Color(0xFFFFB544),

      onSelected: (_) {

        setModalState(() {
          selectedMode = label;
        });

      },
    );
  }

  /// JOB CARD
  Widget _jobCard(Map<String, dynamic> job) {

    final String type = job["type"] ?? "N/A";
    final bool isInstant =
        job["isInstantJob"] ?? false;

    final String title =
        job["title"] ?? "No Title";

    final String location =
        job["location"] ?? "No Location";

    final salary = job["salary"] ?? 0;

    final Timestamp? createdAt =
    job["createdAt"];

    final String preferredDate =
        job["date"]?.toString() ?? "";

    return Container(

      margin:
      const EdgeInsets.only(bottom: 16),

      padding:
      const EdgeInsets.all(16),

      decoration: BoxDecoration(
        color: const Color(0xFFFFE7BF),
        borderRadius:
        BorderRadius.circular(18),
      ),

      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,

        children: [

          Row(
            children: [

              Container(
                padding:
                const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4),

                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                  BorderRadius.circular(8),
                ),

                child: Text(
                    isInstant
                        ? "INSTANT $type"
                        : type),
              ),

              const SizedBox(width: 8),

              Text(
                createdAt != null
                    ? _timeAgo(createdAt)
                    : "",
                style: const TextStyle(
                    color: Colors.grey),
              ),

              const Spacer(),

              Text(
                "₹$salary",
                style: const TextStyle(
                    fontWeight:
                    FontWeight.bold),
              ),

            ],
          ),

          const SizedBox(height: 10),

          Text(title,
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight:
                  FontWeight.bold)),

          const SizedBox(height: 8),

          Row(
            children: [

              const Icon(Icons.location_on,
                  size: 16,
                  color: Colors.grey),

              const SizedBox(width: 4),

              Text(location),

            ],
          ),

          const SizedBox(height: 10),

          Row(
            children: [

              Text(
                "Preferred: $preferredDate",
                style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey),
              ),

              const Spacer(),

              ElevatedButton(

                style: ElevatedButton.styleFrom(
                    backgroundColor:
                    const Color(
                        0xFFFFB544)),

                onPressed: () {

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          JobDetailsScreen(
                              job: job),
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

        }

        else if (index == 2) {

          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) =>
                      AddJobScreen(
                          userId: widget.userId)));

        }

        else if (index == 3) {

          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) =>
                  const ChatScreen()));

        }

        else if (index == 4) {

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
            icon: Icon(Icons.add_circle,
                size: 35),
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
}