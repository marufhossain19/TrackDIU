// ====================================================
// services/location_service.dart — GPS + tracking
// ====================================================
import 'dart:async';
import 'package:geolocator/geolocator.dart';
import '../core/constants.dart';

class LocationService {
  // Singleton
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  StreamSubscription<Position>? _subscription;
  Position? _lastPosition;
  Timer? _updateTimer;

  // Callbacks
  void Function(Position)? onLocationUpdate;

  /// Request location permissions
  Future<bool> requestPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return false;
    }
    if (permission == LocationPermission.deniedForever) return false;
    return true;
  }

  /// Get current position once
  Future<Position?> getCurrentPosition() async {
    final hasPermission = await requestPermission();
    if (!hasPermission) return null;
    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      return null;
    }
  }

  /// Start continuous tracking (for driver mode)
  /// Updates only if moved > 10 metres, max every 30 seconds
  void startTracking({required void Function(Position) onUpdate}) {
    onLocationUpdate = onUpdate;

    _subscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // metres threshold
      ),
    ).listen((Position position) {
      final now = DateTime.now();

      // Also enforce time throttle (30s)
      if (_lastPosition != null) {
        final distance = Geolocator.distanceBetween(
          _lastPosition!.latitude,
          _lastPosition!.longitude,
          position.latitude,
          position.longitude,
        );
        if (distance < AppConstants.locationMinDistance) return;
      }

      _lastPosition = position;
      onLocationUpdate?.call(position);

      // Reset timer
      _updateTimer?.cancel();
      _updateTimer = Timer(
        Duration(seconds: AppConstants.locationIntervalSeconds),
        () {/* allow next update */},
      );
    });
  }

  /// Stop tracking
  void stopTracking() {
    _subscription?.cancel();
    _subscription = null;
    _updateTimer?.cancel();
    _updateTimer = null;
    _lastPosition = null;
  }

  /// Calculate distance between two points in km
  static double distanceKm(
    double lat1, double lng1,
    double lat2, double lng2,
  ) {
    return Geolocator.distanceBetween(lat1, lng1, lat2, lng2) / 1000;
  }

  /// Get ETA in minutes given speed (km/h) and distance (km)
  static int etaMinutes(double distanceKm, double speedKmh) {
    if (speedKmh <= 0) return 0;
    return ((distanceKm / speedKmh) * 60).round();
  }
}
