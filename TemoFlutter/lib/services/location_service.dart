import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationService {
  static final LocationService _instance = LocationService._internal();

  factory LocationService() {
    return _instance;
  }

  LocationService._internal();

  final String _baseUrl = 'https://34tinhthanh.com/api';

  /// Get all provinces
  Future<List<Map<String, dynamic>>> getProvinces() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/provinces'));
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        return data.map((e) => e as Map<String, dynamic>).toList();
      }
    } catch (e) {
      print("Error fetching provinces: $e");
    }
    return [];
  }

  /// Get wards (combined districts/wards) by province code
  Future<List<Map<String, dynamic>>> getWards(String provinceCode) async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/wards?province_code=$provinceCode'));
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        return data.map((e) => e as Map<String, dynamic>).toList();
      }
    } catch (e) {
      print("Error fetching wards: $e");
    }
    return [];
  }

  /// Determine the current position of the device.
  Future<Position?> getCurrentPosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return null;
    }
    
    if (permission == LocationPermission.deniedForever) return null;

    return await Geolocator.getCurrentPosition();
  }

  /// Get the address from the current position.
  Future<String?> getCurrentAddress() async {
    try {
      Position? position = await getCurrentPosition();
      if (position == null) return null;

      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        String district = place.subAdministrativeArea ?? place.locality ?? '';
        String province = place.administrativeArea ?? '';
        
        List<String> parts = [district, province].where((s) => s.isNotEmpty).toList();
        if (parts.isEmpty) return null;
        return parts.join(', ');
      }
      return null;
    } catch (e) {
      print("Error getting address: $e");
      return null;
    }
  }
}
