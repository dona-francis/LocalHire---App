import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationPickerScreen extends StatefulWidget {
  const LocationPickerScreen({super.key});

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  GoogleMapController? _mapController;
  LatLng _selectedPosition = const LatLng(10.8505, 76.2711); // Default: Kerala
  String _selectedAddress = "Move the map to select location";
  bool _isLoadingAddress = false;
  bool _isLoadingLocation = false;

  // This runs when user moves the map and lifts finger
  Future<void> _onCameraIdle() async {
    setState(() => _isLoadingAddress = true);
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        _selectedPosition.latitude,
        _selectedPosition.longitude,
      );
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        setState(() {
          _selectedAddress =
              "${place.subLocality ?? ''}, ${place.locality ?? ''}, ${place.administrativeArea ?? ''}".trim();
        });
      }
    } catch (e) {
      setState(() => _selectedAddress = "Could not get address");
    }
    setState(() => _isLoadingAddress = false);
  }

  // This gets the user's live GPS location
  Future<void> _goToMyLocation() async {
    setState(() => _isLoadingLocation = true);
    try {
      // Check permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Location permission denied")),
          );
          setState(() => _isLoadingLocation = false);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  "Location permission permanently denied. Enable it from settings.")),
        );
        setState(() => _isLoadingLocation = false);
        return;
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final newPos = LatLng(position.latitude, position.longitude);
      setState(() => _selectedPosition = newPos);

      // Move map camera to current location
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(newPos, 15),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error getting location: $e")),
      );
    }
    setState(() => _isLoadingLocation = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
        title: const Text("Pick Location",
            style: TextStyle(color: Colors.black)),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // ---------- MAP ----------
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _selectedPosition,
              zoom: 12,
            ),
            onMapCreated: (controller) => _mapController = controller,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            onCameraMove: (position) {
              // Update position as user drags map
              setState(() => _selectedPosition = position.target);
            },
            onCameraIdle: _onCameraIdle,
          ),

          // ---------- CENTER PIN (always stays in center) ----------
          const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.location_pin, size: 50, color: Color(0xFFF5B544)),
                SizedBox(height: 40), // offset so pin tip is at center
              ],
            ),
          ),

          // ---------- TOP ADDRESS CARD ----------
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                  )
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.location_on, color: Color(0xFFF5B544)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _isLoadingAddress
                        ? const Text("Getting address...",
                            style: TextStyle(color: Colors.grey))
                        : Text(
                            _selectedAddress,
                            style: const TextStyle(fontSize: 14),
                          ),
                  ),
                ],
              ),
            ),
          ),

          // ---------- MY LOCATION BUTTON ----------
          Positioned(
            bottom: 120,
            right: 16,
            child: FloatingActionButton(
              mini: true,
              backgroundColor: Colors.white,
              onPressed: _goToMyLocation,
              child: _isLoadingLocation
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.my_location, color: Color(0xFFF5B544)),
            ),
          ),

          // ---------- CONFIRM BUTTON ----------
          Positioned(
            bottom: 30,
            left: 16,
            right: 16,
            child: ElevatedButton(
              onPressed: () {
                // Send location data back to complete_profile screen
                Navigator.pop(context, {
                  "address": _selectedAddress,
                  "lat": _selectedPosition.latitude,
                  "lng": _selectedPosition.longitude,
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF5B544),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text(
                "Confirm Location",
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black),
              ),
            ),
          ),
        ],
      ),
    );
  }
}