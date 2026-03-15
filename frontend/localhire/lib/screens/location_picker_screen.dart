import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_places_flutter/google_places_flutter.dart';
import 'package:google_places_flutter/model/prediction.dart';

const String kGoogleApiKey = "AIzaSyA00DjHyTf69bXd9e9MKbN3G8GZE00C0rQ";

class LocationPickerScreen extends StatefulWidget {
  const LocationPickerScreen({super.key});

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  // ── Map ────────────────────────────────────────────────────────────────────
  GoogleMapController? _mapController;
  LatLng _selectedPosition = const LatLng(10.8505, 76.2711); // Default: Kerala

  // ── Address / loading ──────────────────────────────────────────────────────
  String _selectedAddress = "Move the map or search a location";
  bool _isLoadingAddress = false;
  bool _isLoadingLocation = false;

  // ── Search ─────────────────────────────────────────────────────────────────
  final TextEditingController _searchController = TextEditingController();

  // ── Camera idle → reverse geocode ─────────────────────────────────────────

  Future<void> _onCameraIdle() async {
    setState(() => _isLoadingAddress = true);
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        _selectedPosition.latitude,
        _selectedPosition.longitude,
      );
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final address =
            "${place.subLocality ?? ''}, ${place.locality ?? ''}, ${place.administrativeArea ?? ''}"
                .trim()
                .replaceAll(RegExp(r'^,\s*|,\s*$'), '');
        setState(() {
          _selectedAddress = address.isEmpty ? "Unknown location" : address;
          _searchController.text = _selectedAddress;
        });
      }
    } catch (e) {
      setState(() => _selectedAddress = "Could not get address");
    }
    setState(() => _isLoadingAddress = false);
  }

  // ── My location ────────────────────────────────────────────────────────────

  Future<void> _goToMyLocation() async {
    setState(() => _isLoadingLocation = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showSnack("Location permission denied");
          setState(() => _isLoadingLocation = false);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _showSnack("Enable location from device settings");
        setState(() => _isLoadingLocation = false);
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final newPos = LatLng(position.latitude, position.longitude);
      setState(() => _selectedPosition = newPos);

      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(newPos, 15),
      );
    } catch (e) {
      _showSnack("Error getting location: $e");
    }
    setState(() => _isLoadingLocation = false);
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  // ── Build ──────────────────────────────────────────────────────────────────

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
          // ── MAP ────────────────────────────────────────────────────────────
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
              setState(() => _selectedPosition = position.target);
            },
            onCameraIdle: _onCameraIdle,
          ),

          // ── CENTER PIN ────────────────────────────────────────────────────
          const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.location_pin,
                    size: 50, color: Color(0xFFF5B544)),
                SizedBox(height: 40),
              ],
            ),
          ),

          // ── SEARCH BAR (google_places_flutter handles suggestions itself) ──
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: GooglePlaceAutoCompleteTextField(
              textEditingController: _searchController,
              googleAPIKey: kGoogleApiKey,
              inputDecoration: InputDecoration(
                hintText: "Search location...",
                hintStyle: const TextStyle(color: Colors.grey),
                prefixIcon:
                    const Icon(Icons.search, color: Color(0xFFF5B544)),
                suffixIcon: _isLoadingAddress
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFFF5B544)),
                        ),
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                    vertical: 14, horizontal: 4),
                filled: true,
                fillColor: Colors.white,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: Color(0xFFF5B544), width: 1.5),
                ),
              ),
              debounceTime: 400,
              countries: const [], // e.g. ['in'] to restrict to India
              isLatLngRequired: true,
              getPlaceDetailWithLatLng: (Prediction prediction) {
                final lat = double.tryParse(prediction.lat ?? '');
                final lng = double.tryParse(prediction.lng ?? '');
                if (lat != null && lng != null) {
                  final newPos = LatLng(lat, lng);
                  setState(() {
                    _selectedPosition = newPos;
                    _selectedAddress =
                        prediction.description ?? "Selected location";
                    _searchController.text = _selectedAddress;
                  });
                  _mapController?.animateCamera(
                    CameraUpdate.newLatLngZoom(newPos, 15),
                  );
                }
              },
              itemClick: (Prediction prediction) {
                _searchController.text = prediction.description ?? '';
                _searchController.selection = TextSelection.fromPosition(
                  TextPosition(
                      offset: _searchController.text.length),
                );
              },
              seperatedBuilder: const Divider(height: 1),
              containerHorizontalPadding: 0,
              itemBuilder: (context, index, Prediction prediction) {
                return ListTile(
                  dense: true,
                  leading: const Icon(Icons.location_on,
                      color: Color(0xFFF5B544), size: 20),
                  title: Text(
                    prediction.description ?? '',
                    style: const TextStyle(fontSize: 14),
                  ),
                );
              },
              isCrossBtnShown: true,
              boxDecoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                  )
                ],
              ),
            ),
          ),

          // ── MY LOCATION BUTTON ────────────────────────────────────────────
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
                  : const Icon(Icons.my_location,
                      color: Color(0xFFF5B544)),
            ),
          ),

          // ── CONFIRM BUTTON ────────────────────────────────────────────────
          Positioned(
            bottom: 30,
            left: 16,
            right: 16,
            child: ElevatedButton(
              onPressed: () {
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