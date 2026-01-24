// lib/services/location_service.dart
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class LocationService {
  // Singleton pattern
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  Position? _currentPosition;
  String? _currentCity;

  Position? get currentPosition => _currentPosition;
  String? get currentCity => _currentCity;

  /// Check if location services are enabled
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// Check location permission status
  Future<bool> hasLocationPermission() async {
    final status = await Permission.location.status;
    return status.isGranted;
  }

  /// Request location permission
  Future<bool> requestLocationPermission() async {
    final status = await Permission.location.request();
    return status.isGranted;
  }

  /// Get current location with permission handling
  Future<Position?> getCurrentLocation({bool forceRefresh = false}) async {
    try {
      // Return cached position if available and not forcing refresh
      if (_currentPosition != null && !forceRefresh) {
        return _currentPosition;
      }

      // Check if location service is enabled
      bool serviceEnabled = await isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('⚠️ Location services are disabled');
        return null;
      }

      // Check permission
      bool hasPermission = await hasLocationPermission();
      if (!hasPermission) {
        hasPermission = await requestLocationPermission();
        if (!hasPermission) {
          print('⚠️ Location permission denied');
          return null;
        }
      }

      // Get current position
      print('📍 Getting current location...');
      _currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      print(
          '✅ Location obtained: ${_currentPosition?.latitude}, ${_currentPosition?.longitude}');

      // Optionally get city name from coordinates
      await _getCityFromCoordinates();

      return _currentPosition;
    } catch (e) {
      print('❌ Error getting location: $e');
      return null;
    }
  }

  /// Get city name from coordinates (reverse geocoding)
  /// Note: This requires a geocoding API - using a simple fallback for now
  Future<void> _getCityFromCoordinates() async {
    if (_currentPosition == null) return;

    // TODO: Integrate with a geocoding API like:
    // - Google Geocoding API
    // - OpenStreetMap Nominatim
    // - Mapbox Geocoding

    // For now, we'll use a fallback based on known coordinates
    _currentCity = _getCityFromKnownCoordinates(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
    );

    print('📍 Detected city: $_currentCity');
  }

  /// Fallback city detection based on coordinates
  String? _getCityFromKnownCoordinates(double lat, double lon) {
    // Major Indian cities with approximate coordinates
    final cities = {
      'Bangalore': {'lat': 12.9716, 'lon': 77.5946, 'radius': 0.5},
      'Mumbai': {'lat': 19.0760, 'lon': 72.8777, 'radius': 0.5},
      'Delhi': {'lat': 28.7041, 'lon': 77.1025, 'radius': 0.5},
      'Hyderabad': {'lat': 17.3850, 'lon': 78.4867, 'radius': 0.5},
      'Chennai': {'lat': 13.0827, 'lon': 80.2707, 'radius': 0.5},
      'Kolkata': {'lat': 22.5726, 'lon': 88.3639, 'radius': 0.5},
      'Pune': {'lat': 18.5204, 'lon': 73.8567, 'radius': 0.5},
      'Ahmedabad': {'lat': 23.0225, 'lon': 72.5714, 'radius': 0.5},
      'Jaipur': {'lat': 26.9124, 'lon': 75.7873, 'radius': 0.5},
      'Surat': {'lat': 21.1702, 'lon': 72.8311, 'radius': 0.5},
    };

    for (final entry in cities.entries) {
      final cityLat = entry.value['lat']!;
      final cityLon = entry.value['lon']!;
      final radius = entry.value['radius']!;

      final distance = _calculateDistance(lat, lon, cityLat, cityLon);

      if (distance <= radius * 111) {
        // Convert degrees to km
        return entry.key;
      }
    }

    return null; // City not detected
  }

  /// Calculate distance between two coordinates (Haversine formula)
  double calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    return _calculateDistance(lat1, lon1, lat2, lon2);
  }

  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2) / 1000; // km
  }

  /// Get distance to a restaurant
  double? getDistanceToRestaurant(Map restaurant) {
    if (_currentPosition == null) return null;

    final lat = restaurant['latitude'] ?? restaurant['lat'];
    final lon = restaurant['longitude'] ?? restaurant['lon'];

    if (lat == null || lon == null) return null;

    return calculateDistance(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      lat is String ? double.parse(lat) : lat.toDouble(),
      lon is String ? double.parse(lon) : lon.toDouble(),
    );
  }

  /// Update city manually
  void setCity(String city) {
    _currentCity = city;
  }

  /// Clear cached location
  void clearCache() {
    _currentPosition = null;
    _currentCity = null;
  }
}
