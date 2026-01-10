import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../models/location.dart';
import '../models/report.dart';
import '../models/user.dart';
import '../services/services.dart';

/// Controller for the Home page
/// Uses LocationService, MapService, and ReportService for functionality
class HomeController extends GetxController with GetTickerProviderStateMixin {
  // ─── Services ────────────────────────────────────────────────────────────
  final LocationService _locationService = Get.find<LocationService>();
  final MapService _mapService = Get.find<MapService>();
  final ReportService _reportService = Get.find<ReportService>();
  final AuthService _authService = Get.find<AuthService>();

  // ─── UI State ────────────────────────────────────────────────────────────
  final RxInt _currentReportIndex = 0.obs;
  final RxDouble _sheetPosition = 0.15.obs;
  final RxBool _isInitialized = false.obs;
  final RxBool _showMyLocationButton = false.obs;

  // ─── Constants ───────────────────────────────────────────────────────────
  /// Minimum distance (in meters) to show the "My Location" button
  static const double _minDistanceToShowButton = 2.0;

  // ─── Draggable Sheet Controller ──────────────────────────────────────────
  final DraggableScrollableController sheetController =
      DraggableScrollableController();

  // ─── Animation Controllers ───────────────────────────────────────────────
  late AnimationController avatarAnimationController;
  late AnimationController actionsAnimationController;

  // ─── Service Getters (proxy) ─────────────────────────────────────────────
  LocationService get locationService => _locationService;
  MapService get mapService => _mapService;
  ReportService get reportService => _reportService;
  AuthService get authService => _authService;

  // ─── User Getters ────────────────────────────────────────────────────────
  UserModel? get currentUser => _authService.currentUser;
  bool get isAuthenticated => _authService.isAuthenticated;
  bool get isGuest => !isAuthenticated || currentUser == null;

  // ─── State Getters ───────────────────────────────────────────────────────
  int get currentReportIndex => _currentReportIndex.value;
  double get sheetPosition => _sheetPosition.value;
  bool get isInitialized => _isInitialized.value;
  bool get showMyLocationButton => _showMyLocationButton.value;

  ReportModel? get currentReport {
    if (!_reportService.hasNearbyReports) return null;
    if (_currentReportIndex.value >= _reportService.nearbyReports.length) {
      return null;
    }
    return _reportService.nearbyReports[_currentReportIndex.value];
  }

  @override
  void onInit() {
    super.onInit();
    _initAnimationControllers();
    _initialize();
  }

  @override
  void onClose() {
    avatarAnimationController.dispose();
    actionsAnimationController.dispose();
    sheetController.dispose();
    super.onClose();
  }

  // ─── Initialization ──────────────────────────────────────────────────────

  void _initAnimationControllers() {
    avatarAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    actionsAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
  }

  Future<void> _initialize() async {
    // Wait for location to be ready
    if (!_locationService.hasValidLocation) {
      await _locationService.initLocation();
    }

    if (_locationService.hasValidLocation) {
      // Load nearby reports
      await _reportService.loadNearbyReports(_locationService.currentLocation);

      // Start animations
      _startAnimations();
    }

    _isInitialized.value = true;
  }

  void _startAnimations() {
    avatarAnimationController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      actionsAnimationController.forward();
    });
  }

  // ─── Map Methods ─────────────────────────────────────────────────────────

  /// Called when the map is created
  void onMapCreated(mapboxMap) {
    _mapService.onMapCreated(mapboxMap);

    // Listen to camera changes to show/hide My Location button
    _mapService.onCameraChanged = _onCameraChanged;

    // Animate to user location after map is ready
    if (_locationService.hasValidLocation) {
      _mapService.animateToLocation(
        _locationService.currentLocation,
        zoom: 15.0,
        pitch: 45.0,
        durationMs: 2000,
      );
    }
  }

  /// Called when the camera position changes
  void _onCameraChanged(double latitude, double longitude) {
    if (!_locationService.hasValidLocation) return;

    final userLocation = _locationService.currentLocation;
    final cameraLocation = LocationModel(
      latitude: latitude,
      longitude: longitude,
    );

    final distance = userLocation.distanceTo(cameraLocation);

    // Show button if camera is far enough from user location
    _showMyLocationButton.value = distance >= _minDistanceToShowButton;
  }

  /// Called when the user scrolls/moves the map
  void onCameraMove() {
    // Debounce: Only check after the map has been created
    if (!_mapService.isMapReady) return;

    // Notify camera changed to check distance
    _mapService.notifyCameraChanged();
  }

  /// Center map on user's current location
  Future<void> centerOnUserLocation() async {
    // Don't use refresh() as it sets isLoading=true which rebuilds the map
    // Just get the current position silently and animate to it
    final location = await _locationService.getCurrentPosition();
    if (location != null && location.isValid) {
      await _mapService.animateToLocation(
        location,
        zoom: 15.0,
        pitch: 45.0,
        durationMs: 1500,
      );
      // Hide the button after centering
      _showMyLocationButton.value = false;
    } else if (_locationService.hasValidLocation) {
      // Use cached location if getCurrentPosition fails
      await _mapService.animateToLocation(
        _locationService.currentLocation,
        zoom: 15.0,
        pitch: 45.0,
        durationMs: 1500,
      );
      // Hide the button after centering
      _showMyLocationButton.value = false;
    }
  }

  // ─── Report Methods ──────────────────────────────────────────────────────

  /// Called when swiping to a new report card
  void onReportCardChanged(int index) {
    if (index >= 0 && index < _reportService.nearbyReports.length) {
      _currentReportIndex.value = index;

      // Animate map to the new report's location
      final report = _reportService.nearbyReports[index];
      _mapService.animateToLocation(
        report.location,
        zoom: 16.0,
        pitch: 60.0,
        durationMs: 1500,
      );
    }
  }

  /// Refresh nearby reports
  Future<void> refreshReports() async {
    if (_locationService.hasValidLocation) {
      await _reportService.loadNearbyReports(_locationService.currentLocation);
      _currentReportIndex.value = 0;
    }
  }

  // ─── Sheet Methods ───────────────────────────────────────────────────────

  /// Updates the sheet position
  void updateSheetPosition(double position) {
    _sheetPosition.value = position;
  }
}
