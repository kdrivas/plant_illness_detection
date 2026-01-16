import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationService {
  /// Check and request location permissions
  Future<bool> checkAndRequestPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  /// Get current position
  Future<Position?> getCurrentPosition() async {
    final hasPermission = await checkAndRequestPermission();
    if (!hasPermission) return null;

    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );
    } catch (e) {
      return null;
    }
  }

  /// Determine if location is in Northern Hemisphere
  Future<bool> isNorthernHemisphere() async {
    final position = await getCurrentPosition();
    if (position == null) {
      // Default to Northern Hemisphere if can't determine
      return true;
    }
    return position.latitude >= 0;
  }

  /// Get location details (city, country)
  Future<LocationDetails?> getLocationDetails() async {
    final position = await getCurrentPosition();
    if (position == null) return null;

    try {
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        return LocationDetails(
          latitude: position.latitude,
          longitude: position.longitude,
          city: place.locality ?? place.subAdministrativeArea ?? 'Unknown',
          country: place.country ?? 'Unknown',
          isNorthernHemisphere: position.latitude >= 0,
          timezone: _estimateTimezone(position.longitude),
        );
      }
    } catch (e) {
      // Return basic info without geocoding
      return LocationDetails(
        latitude: position.latitude,
        longitude: position.longitude,
        city: 'Unknown',
        country: 'Unknown',
        isNorthernHemisphere: position.latitude >= 0,
        timezone: _estimateTimezone(position.longitude),
      );
    }

    return null;
  }

  /// Estimate timezone from longitude (rough approximation)
  String _estimateTimezone(double longitude) {
    final offset = (longitude / 15).round();
    if (offset >= 0) {
      return 'UTC+$offset';
    } else {
      return 'UTC$offset';
    }
  }

  /// Get hardiness zone estimate (simplified)
  String getHardinessZone(double latitude) {
    final absLat = latitude.abs();
    
    if (absLat < 10) return '13';
    if (absLat < 20) return '11-12';
    if (absLat < 30) return '9-10';
    if (absLat < 35) return '8-9';
    if (absLat < 40) return '7-8';
    if (absLat < 45) return '5-6';
    if (absLat < 50) return '4-5';
    if (absLat < 55) return '3-4';
    if (absLat < 60) return '2-3';
    return '1-2';
  }
}

class LocationDetails {
  final double latitude;
  final double longitude;
  final String city;
  final String country;
  final bool isNorthernHemisphere;
  final String timezone;

  LocationDetails({
    required this.latitude,
    required this.longitude,
    required this.city,
    required this.country,
    required this.isNorthernHemisphere,
    required this.timezone,
  });

  String get hemisphereLabel => isNorthernHemisphere ? 'Northern' : 'Southern';
  
  String get displayName => '$city, $country';
  
  String get coordinates => 
      '${latitude.toStringAsFixed(4)}°${latitude >= 0 ? "N" : "S"}, '
      '${longitude.toStringAsFixed(4)}°${longitude >= 0 ? "E" : "W"}';
}
