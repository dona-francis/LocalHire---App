
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;

const String kGoogleApiKey = "AIzaSyA00DjHyTf69bXd9e9MKbN3G8GZE00C0rQ";

class LocationPickerScreen extends StatefulWidget {
  const LocationPickerScreen({super.key});

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  // ── Map ────────────────────────────────────────────────────────────────────
  GoogleMapController? _mapController;
  LatLng _selectedPosition = const LatLng(10.8505, 76.2711);

  // ── Address / loading ──────────────────────────────────────────────────────
  String _selectedAddress = "Move the map or search a location";
  bool _isLoadingAddress = false;
  bool _isLoadingLocation = false;

  // ── Search ─────────────────────────────────────────────────────────────────
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  List<Map<String, dynamic>> _predictions = [];
  bool _showSuggestions = false;
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  // ── Places Autocomplete via HTTP ───────────────────────────────────────────

  Future<void> _onSearchChanged(String value) async {
    if (value.trim().isEmpty) {
      setState(() {
        _predictions = [];
        _showSuggestions = false;
      });
      return;
    }

    setState(() => _isSearching = true);

    try {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/autocomplete/json'
        '?input=${Uri.encodeComponent(value)}'
        '&key=$kGoogleApiKey',
      );

      final response = await http.get(url);
      final data = json.decode(response.body);

      if (data['status'] == 'OK') {
        setState(() {
          _predictions = List<Map<String, dynamic>>.from(
            data['predictions'].map((p) => {
              'description': p['description'],
              'place_id': p['place_id'],
              'main_text': p['structured_formatting']?['main_text'] ?? p['description'],
              'secondary_text': p['structured_formatting']?['secondary_text'] ?? '',
            }),
          );
          _showSuggestions = _predictions.isNotEmpty;
        });
      } else {
        setState(() {
          _predictions = [];
          _showSuggestions = false;
        });
      }
    } catch (e) {
      setState(() => _showSuggestions = false);
    }

    setState(() => _isSearching = false);
  }

  Future<void> _onPredictionSelected(Map<String, dynamic> prediction) async {
    _searchFocus.unfocus();
    setState(() {
      _showSuggestions = false;
      _isLoadingAddress = true;
      _searchController.text = prediction['description'];
    });

    try {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/details/json'
        '?place_id=${prediction['place_id']}'
        '&fields=geometry,formatted_address'
        '&key=$kGoogleApiKey',
      );

      final response = await http.get(url);
      final data = json.decode(response.body);

      if (data['status'] == 'OK') {
        final location = data['result']['geometry']['location'];
        final address = data['result']['formatted_address'];
        final newPos = LatLng(location['lat'], location['lng']);

        setState(() {
          _selectedPosition = newPos;
          _selectedAddress = address;
          _searchController.text = address;
        });

        _mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(newPos, 15),
        );
      }
    } catch (e) {
      _showSnack("Could not load place: $e");
    }

    setState(() => _isLoadingAddress = false);
  }

  // ── Camera idle → reverse geocode ─────────────────────────────────────────

  Future<void> _onCameraIdle() async {
    if (_searchFocus.hasFocus) return;

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

          // ── SEARCH BAR + SUGGESTIONS ──────────────────────────────────────
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Column(
              children: [
                // Search input
                Container(
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
                  child: TextField(
                    controller: _searchController,
                    focusNode: _searchFocus,
                    onChanged: _onSearchChanged,
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText: "Search location...",
                      hintStyle: const TextStyle(color: Colors.grey),
                      prefixIcon: const Icon(Icons.search,
                          color: Color(0xFFF5B544)),
                      suffixIcon: _isSearching || _isLoadingAddress
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
                          : _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.close,
                                      color: Colors.grey, size: 20),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() {
                                      _predictions = [];
                                      _showSuggestions = false;
                                    });
                                    _searchFocus.unfocus();
                                  },
                                )
                              : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 14, horizontal: 4),
                    ),
                  ),
                ),

                // Suggestions dropdown
                if (_showSuggestions)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
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
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _predictions.length,
                      separatorBuilder: (_, __) => const Divider(
                          height: 1, indent: 48, endIndent: 16),
                      itemBuilder: (context, index) {
                        final prediction = _predictions[index];
                        return ListTile(
                          dense: true,
                          leading: const Icon(Icons.location_on,
                              color: Color(0xFFF5B544), size: 20),
                          title: Text(
                            prediction['main_text'],
                            style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14),
                          ),
                          subtitle: prediction['secondary_text'] != ''
                              ? Text(
                                  prediction['secondary_text'],
                                  style: const TextStyle(
                                      fontSize: 12, color: Colors.grey),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                )
                              : null,
                          onTap: () => _onPredictionSelected(prediction),
                        );
                      },
                    ),
                  ),
              ],
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