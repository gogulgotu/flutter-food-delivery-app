import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart';

/// Location Service
/// 
/// Handles location-related operations including getting current position
/// and reverse geocoding to get address from coordinates
class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  /// Check and request location permissions
  Future<bool> requestLocationPermission() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('📍 Location services are disabled');
        return false;
      }

      // Check permission status
      LocationPermission permission = await Geolocator.checkPermission();
      
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('📍 Location permissions are denied');
          return false;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('📍 Location permissions are permanently denied');
        // Open app settings
        await openAppSettings();
        return false;
      }

      debugPrint('✅ Location permissions granted');
      return true;
    } catch (e) {
      debugPrint('❌ Error requesting location permission: $e');
      return false;
    }
  }

  /// Get current location
  /// Returns Position with latitude and longitude, or null if error
  Future<Position?> getCurrentLocation() async {
    try {
      // Request permission first
      final hasPermission = await requestLocationPermission();
      if (!hasPermission) {
        debugPrint('📍 Location permission not granted');
        return null;
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      debugPrint('📍 Current location: ${position.latitude}, ${position.longitude}');
      return position;
    } catch (e) {
      debugPrint('❌ Error getting current location: $e');
      return null;
    }
  }

  /// Get address from coordinates (reverse geocoding)
  /// Returns formatted address string
  Future<String?> getAddressFromCoordinates({
    required double latitude,
    required double longitude,
  }) async {
    try {
      // Validate coordinates
      if (latitude.isNaN || longitude.isNaN || 
          latitude < -90 || latitude > 90 || 
          longitude < -180 || longitude > 180) {
        debugPrint('❌ Invalid coordinates: $latitude, $longitude');
        return 'Invalid location coordinates';
      }

      List<Placemark> placemarks;
      try {
        placemarks = await placemarkFromCoordinates(
          latitude,
          longitude,
        );
      } catch (e, stackTrace) {
        debugPrint('❌ Error calling placemarkFromCoordinates: $e');
        debugPrint('❌ Stack trace: $stackTrace');
        // Return fallback address
        return 'Near ${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}';
      }

      if (placemarks.isEmpty) {
        debugPrint('⚠️ No placemarks found for coordinates: $latitude, $longitude');
        return 'Near ${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}';
      }

      // Get first placemark
      final place = placemarks[0];
      
      // Build address string with safe null checks
      final addressParts = <String>[];
      
      // Helper function to safely get placemark property
      String? safeGetProperty(dynamic Function() getter) {
        try {
          final value = getter();
          // Handle null values safely
          if (value == null) {
            return null;
          }
          // Convert to string safely
          final stringValue = value.toString();
          return stringValue.isNotEmpty ? stringValue : null;
        } catch (e, stackTrace) {
          // Catch any null check errors or unexpected errors
          debugPrint('⚠️ Error accessing placemark property: $e');
          debugPrint('⚠️ Stack trace: $stackTrace');
          return null;
        }
      }

      // Try to get street
      final street = safeGetProperty(() => place.street);
      if (street != null) {
        addressParts.add(street);
      }

      // Try to get sublocality
      final subLocality = safeGetProperty(() => place.subLocality);
      if (subLocality != null && subLocality != street) {
        addressParts.add(subLocality);
      }

      // Try to get locality (city)
      final locality = safeGetProperty(() => place.locality);
      if (locality != null) {
        addressParts.add(locality);
      }

      // Try to get postal code
      final postalCode = safeGetProperty(() => place.postalCode);
      if (postalCode != null) {
        // Add postal code to last part or as separate
        if (addressParts.isNotEmpty) {
          final lastPart = addressParts.removeLast();
          addressParts.add('$lastPart - $postalCode');
        } else {
          addressParts.add(postalCode);
        }
      }

      // Try to get administrative area (state)
      final adminArea = safeGetProperty(() => place.administrativeArea);
      if (adminArea != null) {
        addressParts.add(adminArea);
      }

      // Try to get country
      final country = safeGetProperty(() => place.country);
      if (country != null) {
        addressParts.add(country);
      }

      // Build the final address string
      final address = addressParts.join(', ');

      // If we couldn't build a proper address, use a fallback
      if (address.isEmpty || address.trim().isEmpty) {
        // Try to use at least the locality or country if available
        final fallback = locality ?? country ?? postalCode ?? adminArea;
        if (fallback != null && fallback.isNotEmpty) {
          debugPrint('📍 Address (partial): $fallback');
          return fallback;
        }
        
        // Last resort: use coordinates in a user-friendly format
        debugPrint('⚠️ Could not build address, using fallback format');
        return 'Near ${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}';
      }

      debugPrint('📍 Address: $address');
      return address;
    } catch (e, stackTrace) {
      debugPrint('❌ Error getting address from coordinates: $e');
      debugPrint('❌ Stack trace: $stackTrace');
      // Return a fallback address with coordinates
      return 'Near ${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}';
    }
  }

  /// Get coordinates from address (geocoding)
  /// Returns Position with latitude and longitude, or null if error
  Future<Position?> getCoordinatesFromAddress(String address) async {
    try {
      List<Location> locations = await locationFromAddress(address);
      
      if (locations.isNotEmpty) {
        Location location = locations[0];
        return Position(
          latitude: location.latitude,
          longitude: location.longitude,
          timestamp: DateTime.now(),
          accuracy: 0,
          altitude: 0,
          heading: 0,
          speed: 0,
          speedAccuracy: 0,
          altitudeAccuracy: 0,
          headingAccuracy: 0,
        );
      }

      return null;
    } catch (e) {
      debugPrint('❌ Error getting coordinates from address: $e');
      return null;
    }
  }

  /// Check if user has location permission
  Future<bool> hasLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    return permission == LocationPermission.whileInUse || 
           permission == LocationPermission.always;
  }
}

