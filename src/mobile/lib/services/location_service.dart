import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:get/get.dart';

import '../models/location.dart';

/// Service for handling location-related functionality
class LocationService extends GetxService {
  // ─── State ───────────────────────────────────────────────────────────────
  final Rx<LocationModel> _currentLocation = LocationModel.empty().obs;
  final RxBool _isLoading = false.obs;
  final RxBool _hasPermission = false.obs;
  final RxString _error = ''.obs;

  StreamSubscription<geo.Position>? _positionSubscription;

  // ─── Getters ─────────────────────────────────────────────────────────────
  LocationModel get currentLocation => _currentLocation.value;
  bool get isLoading => _isLoading.value;
  bool get hasPermission => _hasPermission.value;
  String get error => _error.value;
  bool get hasValidLocation => _currentLocation.value.isValid;

  // ─── Lifecycle ───────────────────────────────────────────────────────────

  @override
  void onInit() {
    super.onInit();
    initLocation();
  }

  @override
  void onClose() {
    _positionSubscription?.cancel();
    super.onClose();
  }

  // ─── Public Methods ──────────────────────────────────────────────────────

  /// Initialize location services and get current position
  Future<bool> initLocation() async {
    _isLoading.value = true;
    _error.value = '';

    try {
      // Check if location services are enabled
      final serviceEnabled = await geo.Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _error.value = 'Location services are disabled';
        _isLoading.value = false;
        return false;
      }

      // Check and request permission
      var permission = await geo.Geolocator.checkPermission();
      if (permission == geo.LocationPermission.denied) {
        permission = await geo.Geolocator.requestPermission();
        if (permission == geo.LocationPermission.denied) {
          _error.value = 'Location permission denied';
          _isLoading.value = false;
          return false;
        }
      }

      if (permission == geo.LocationPermission.deniedForever) {
        _error.value = 'Location permission permanently denied';
        _isLoading.value = false;
        return false;
      }

      _hasPermission.value = true;
      await getCurrentPosition();
      return true;
    } catch (e) {
      _error.value = 'Failed to initialize location: $e';
      debugPrint('LocationService error: $e');
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  /// Get the current position
  Future<LocationModel?> getCurrentPosition() async {
    try {
      final position = await geo.Geolocator.getCurrentPosition(
        locationSettings: const geo.LocationSettings(
          accuracy: geo.LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );

      _currentLocation.value = LocationModel(
        latitude: position.latitude,
        longitude: position.longitude,
      );

      _error.value = '';
      return _currentLocation.value;
    } catch (e) {
      _error.value = 'Failed to get current position';
      debugPrint('LocationService getCurrentPosition error: $e');
      return null;
    }
  }

  /// Start listening to position updates
  void startPositionStream({
    int distanceFilter = 10,
    void Function(LocationModel)? onPositionUpdate,
  }) {
    _positionSubscription?.cancel();

    _positionSubscription = geo.Geolocator.getPositionStream(
      locationSettings: geo.LocationSettings(
        accuracy: geo.LocationAccuracy.high,
        distanceFilter: distanceFilter,
      ),
    ).listen(
      (position) {
        _currentLocation.value = LocationModel(
          latitude: position.latitude,
          longitude: position.longitude,
        );
        onPositionUpdate?.call(_currentLocation.value);
      },
      onError: (e) {
        debugPrint('Position stream error: $e');
      },
    );
  }

  /// Stop listening to position updates
  void stopPositionStream() {
    _positionSubscription?.cancel();
    _positionSubscription = null;
  }

  /// Calculate distance between current location and another location
  double? distanceTo(LocationModel other) {
    if (!hasValidLocation || !other.isValid) return null;
    return _currentLocation.value.distanceTo(other);
  }

  /// Open device location settings
  Future<bool> openLocationSettings() async {
    return await geo.Geolocator.openLocationSettings();
  }

  /// Open app settings for permissions
  Future<bool> openAppSettings() async {
    return await geo.Geolocator.openAppSettings();
  }

  /// Refresh current location
  Future<void> refresh() async {
    _isLoading.value = true;
    await getCurrentPosition();
    _isLoading.value = false;
  }
}

