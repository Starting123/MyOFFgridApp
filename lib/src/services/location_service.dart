import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

/// Service for handling location operations including GPS coordinates and address resolution
class LocationService {
  static final LocationService _instance = LocationService._internal();
  static LocationService get instance => _instance;
  LocationService._internal();

  Position? _lastKnownPosition;
  String? _lastKnownAddress;
  Timer? _locationUpdateTimer;

  /// Get current position with permission handling
  Future<Position?> getCurrentPosition() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('Location services are disabled');
        return null;
      }

      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('Location permissions are denied');
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('Location permissions are permanently denied');
        return null;
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      _lastKnownPosition = position;
      return position;
    } catch (e) {
      debugPrint('Error getting current position: $e');
      return _lastKnownPosition; // Return last known position if available
    }
  }

  /// Get address from coordinates
  Future<String?> getAddressFromCoordinates(double latitude, double longitude) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        String address = '';
        
        if (place.street != null && place.street!.isNotEmpty) {
          address += '${place.street}, ';
        }
        if (place.subLocality != null && place.subLocality!.isNotEmpty) {
          address += '${place.subLocality}, ';
        }
        if (place.locality != null && place.locality!.isNotEmpty) {
          address += '${place.locality}, ';
        }
        if (place.administrativeArea != null && place.administrativeArea!.isNotEmpty) {
          address += '${place.administrativeArea}, ';
        }
        if (place.country != null && place.country!.isNotEmpty) {
          address += place.country!;
        }

        // Remove trailing comma and space
        address = address.replaceAll(RegExp(r', $'), '');
        
        _lastKnownAddress = address;
        return address;
      }
    } catch (e) {
      debugPrint('Error getting address: $e');
    }
    return null;
  }

  /// Get formatted location string for emergency messages
  Future<String> getEmergencyLocationString() async {
    Position? position = await getCurrentPosition();
    if (position == null) {
      return _lastKnownPosition != null 
          ? 'Last known: ${_lastKnownPosition!.latitude.toStringAsFixed(6)}, ${_lastKnownPosition!.longitude.toStringAsFixed(6)}'
          : 'Location unavailable';
    }

    String locationStr = 'GPS: ${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}';
    
    // Add accuracy info
    locationStr += ' (±${position.accuracy.toStringAsFixed(0)}m)';
    
    // Try to get address
    String? address = await getAddressFromCoordinates(position.latitude, position.longitude);
    if (address != null && address.isNotEmpty) {
      locationStr += '\nAddress: $address';
    }

    // Add timestamp
    locationStr += '\nTime: ${DateTime.now().toLocal().toString().substring(0, 19)}';

    return locationStr;
  }

  /// Create location data for sharing
  Map<String, dynamic> createLocationData(Position position) {
    return {
      'latitude': position.latitude,
      'longitude': position.longitude,
      'accuracy': position.accuracy,
      'altitude': position.altitude,
      'heading': position.heading,
      'speed': position.speed,
      'timestamp': position.timestamp.toIso8601String(),
      'address': _lastKnownAddress,
    };
  }

  /// Parse location data from map
  LocationData? parseLocationData(Map<String, dynamic> data) {
    try {
      return LocationData(
        latitude: data['latitude']?.toDouble() ?? 0.0,
        longitude: data['longitude']?.toDouble() ?? 0.0,
        accuracy: data['accuracy']?.toDouble() ?? 0.0,
        altitude: data['altitude']?.toDouble() ?? 0.0,
        heading: data['heading']?.toDouble() ?? 0.0,
        speed: data['speed']?.toDouble() ?? 0.0,
        timestamp: data['timestamp'] != null 
            ? DateTime.parse(data['timestamp'])
            : DateTime.now(),
        address: data['address'],
      );
    } catch (e) {
      debugPrint('Error parsing location data: $e');
      return null;
    }
  }

  /// Start periodic location updates
  void startLocationUpdates({Duration interval = const Duration(minutes: 5)}) {
    _locationUpdateTimer?.cancel();
    _locationUpdateTimer = Timer.periodic(interval, (timer) {
      getCurrentPosition();
    });
  }

  /// Stop location updates
  void stopLocationUpdates() {
    _locationUpdateTimer?.cancel();
    _locationUpdateTimer = null;
  }

  /// Calculate distance between two positions
  double calculateDistance(double startLatitude, double startLongitude, double endLatitude, double endLongitude) {
    return Geolocator.distanceBetween(startLatitude, startLongitude, endLatitude, endLongitude);
  }

  /// Format distance for display
  String formatDistance(double distanceInMeters) {
    if (distanceInMeters < 1000) {
      return '${distanceInMeters.toStringAsFixed(0)} m';
    } else {
      return '${(distanceInMeters / 1000).toStringAsFixed(1)} km';
    }
  }

  /// Get last known position
  Position? get lastKnownPosition => _lastKnownPosition;

  /// Get last known address
  String? get lastKnownAddress => _lastKnownAddress;

  /// Dispose resources
  void dispose() {
    stopLocationUpdates();
  }
}

/// Location data model
class LocationData {
  final double latitude;
  final double longitude;
  final double accuracy;
  final double altitude;
  final double heading;
  final double speed;
  final DateTime timestamp;
  final String? address;

  LocationData({
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    required this.altitude,
    required this.heading,
    required this.speed,
    required this.timestamp,
    this.address,
  });

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'accuracy': accuracy,
      'altitude': altitude,
      'heading': heading,
      'speed': speed,
      'timestamp': timestamp.toIso8601String(),
      'address': address,
    };
  }

  factory LocationData.fromJson(Map<String, dynamic> json) {
    return LocationData(
      latitude: json['latitude']?.toDouble() ?? 0.0,
      longitude: json['longitude']?.toDouble() ?? 0.0,
      accuracy: json['accuracy']?.toDouble() ?? 0.0,
      altitude: json['altitude']?.toDouble() ?? 0.0,
      heading: json['heading']?.toDouble() ?? 0.0,
      speed: json['speed']?.toDouble() ?? 0.0,
      timestamp: json['timestamp'] != null 
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
      address: json['address'],
    );
  }

  @override
  String toString() {
    return 'LocationData(lat: ${latitude.toStringAsFixed(6)}, lng: ${longitude.toStringAsFixed(6)}, accuracy: ${accuracy.toStringAsFixed(0)}m)';
  }
}