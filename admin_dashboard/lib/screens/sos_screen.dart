import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class SosScreen extends StatelessWidget {
  const SosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("SOS Alerts")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('sos_alerts')
            .snapshots(),
        builder: (context, snapshot) {

          // 🔴 Error case
          if (snapshot.hasError) {
            return const Center(
              child: Text("Error loading SOS alerts"),
            );
          }

          // ⏳ Loading
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          // 📭 No data
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text("No SOS alerts"),
            );
          }

          final alerts = snapshot.data!.docs;

          return ListView.builder(
            itemCount: alerts.length,
            itemBuilder: (context, index) {
              final data =
                  alerts[index].data() as Map<String, dynamic>;

              return Card(
                color: Colors.red.shade50,
                margin: const EdgeInsets.all(10),
                child: ListTile(
                  leading: const Icon(Icons.warning, color: Colors.red),

                  title: Text(
                    data['employeeName'] ?? 'Unknown',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),

                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Lat: ${data['latitude']}"),
                      Text("Lng: ${data['longitude']}"),
                      const SizedBox(height: 5),
                      Text(
                        "STATUS: ${data['status'] ?? 'pending'}",
                        style: const TextStyle(color: Colors.red),
                      ),
                    ],
                  ),

                 trailing: IconButton(
                    icon: const Icon(Icons.location_on, color: Colors.blue),
                    onPressed: () async {
                      final link = data['mapsLink'];

                      if (link != null) {
                        final uri = Uri.parse(link);

                        if (!await launchUrl(uri)) {
                          print("Could not open map");
                        }
                      }
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}