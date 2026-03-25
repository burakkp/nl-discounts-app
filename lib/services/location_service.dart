// lib/services/location_service.dart
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:geolocator/geolocator.dart';

class LocationService {
  Future<Position> getCurrentLocation() async {

    // 🛡️ THE BYPASS: If running on Linux desktop, return a mock location immediately
    if (!kIsWeb && Platform.isLinux) {
      print('💻 Linux Desktop detected. Returning mock GPS for Tiel...');
      return Position(
        latitude: 51.88,
        longitude: 5.43,
        timestamp: DateTime.now(),
        accuracy: 100,
        altitude: 0,
        heading: 0,
        speed: 0,
        speedAccuracy: 0,
        altitudeAccuracy: 0,
        headingAccuracy: 0,
      );
    }

    // --- Normal Mobile Hardware Logic Below ---
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled. Please turn on GPS.');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are permanently denied.');
    }

    print('📍 Fetching real mobile GPS location...');
    return await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
  }
}