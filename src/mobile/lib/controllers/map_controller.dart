import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

import '../models/location.dart';
import '../models/report.dart';
import '../services/location_service.dart';
import '../services/map_service.dart';
import '../utils/constants.dart';

/// Controller for map-related state and operations
class MapController extends GetxController {
  // ─── Services ────────────────────────────────────────────────────────────
  final MapService _mapService = Get.find<MapService>();
  final LocationService _locationService = Get.find<LocationService>();

  // ─── State ───────────────────────────────────────────────────────────────
  final RxBool _isMapReady = false.obs;
  final RxBool _showMyLocationButton = false.obs;
  final RxList<ReportModel> _displayedReports = <ReportModel>[].obs;

  // ─── Point Annotation Manager ────────────────────────────────────────────
  PointAnnotationManager? _pointAnnotationManager;
  final Map<String, PointAnnotation> _reportAnnotations = {};
  final Map<String, ReportModel> _annotationToReport = {};

  // ─── Constants ───────────────────────────────────────────────────────────
  static const double _minDistanceToShowButton = 2.0;

  // Pin sizes based on severity (base sizes - will scale with zoom)
  static const Map<int, double> _severityPinSizes = {
    1: 0.75, // Low
    2: 0.8, // Medium
    3: 0.9, // High
    4: 1.0, // Critical
  };

  // ─── Callbacks ───────────────────────────────────────────────────────────
  void Function(ReportModel report)? onReportPinTapped;

  // ─── Getters ─────────────────────────────────────────────────────────────
  bool get isMapReady => _isMapReady.value;

  bool get showMyLocationButton => _showMyLocationButton.value;

  MapService get mapService => _mapService;

  LocationService get locationService => _locationService;

  // ─── Map Lifecycle ───────────────────────────────────────────────────────

  /// Called when the map is created
  Future<void> onMapCreated(MapboxMap mapboxMap) async {
    _mapService.onMapCreated(mapboxMap);
    _isMapReady.value = true;

    // Listen to camera changes
    _mapService.onCameraChanged = _onCameraChanged;

    // Initialize point annotation manager for report pins
    await _initAnnotationManager(mapboxMap);

    // Animate to user location after map is ready
    if (_locationService.hasValidLocation) {
      await _mapService.animateToLocation(
        _locationService.currentLocation,
        zoom: 15.0,
        pitch: 45.0,
        durationMs: 2000,
      );
    }

    debugPrint('MapController: Map created and ready');
  }

  /// Initialize the point annotation manager
  Future<void> _initAnnotationManager(MapboxMap mapboxMap) async {
    try {
      _pointAnnotationManager = await mapboxMap.annotations
          .createPointAnnotationManager();

      // Set up tap listener for annotations
      // ignore: deprecated_member_use
      _pointAnnotationManager?.addOnPointAnnotationClickListener(
        _ReportPinClickListener(this),
      );

      debugPrint('MapController: Point annotation manager initialized');
    } catch (e) {
      debugPrint('MapController: Error initializing annotation manager - $e');
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
    _showMyLocationButton.value = distance >= _minDistanceToShowButton;
  }

  /// Called when user scrolls/moves the map
  void onCameraMove() {
    if (!_mapService.isMapReady) return;
    _mapService.notifyCameraChanged();
  }

  // ─── Location Methods ────────────────────────────────────────────────────

  /// Center map on user's current location
  Future<void> centerOnUserLocation() async {
    final location = await _locationService.getCurrentPosition();
    if (location != null && location.isValid) {
      await _mapService.animateToLocation(
        location,
        zoom: 15.0,
        pitch: 45.0,
        durationMs: 1500,
      );
      _showMyLocationButton.value = false;
    } else if (_locationService.hasValidLocation) {
      await _mapService.animateToLocation(
        _locationService.currentLocation,
        zoom: 15.0,
        pitch: 45.0,
        durationMs: 1500,
      );
      _showMyLocationButton.value = false;
    }
  }

  /// Animate to a specific report location
  Future<void> animateToReport(ReportModel report) async {
    if (report.location == null || !report.location!.isValid) return;

    await _mapService.animateToLocation(
      report.location!.toLocationModel(),
      zoom: 16.0,
      pitch: 45.0,
      durationMs: 1000,
    );
    debugPrint('MapController: Animated to report location');
  }

  // ─── Report Pin Methods ──────────────────────────────────────────────────

  /// Update report pins on the map
  Future<void> updateReportPins(List<ReportModel> reports) async {
    if (_pointAnnotationManager == null) {
      debugPrint('MapController: Annotation manager not ready');
      return;
    }

    // Clear existing annotations
    await clearReportPins();

    // Add new annotations
    for (final report in reports) {
      await _addReportPin(report);
    }

    _displayedReports.value = reports;
    debugPrint('MapController: Updated ${reports.length} report pins');
  }

  /// Add a single report pin to the map
  Future<void> _addReportPin(ReportModel report) async {
    if (_pointAnnotationManager == null) return;
    if (report.location == null || !report.location!.isValid) return;

    try {
      final pinImage = await _getPinImageForSeverity(report.severityLevel);
      final pinSize = _severityPinSizes[report.severityLevel] ?? 1.0;

      final options = PointAnnotationOptions(
        geometry: Point(
          coordinates: Position(
            report.location!.longitude,
            report.location!.latitude,
          ),
        ),
        image: pinImage,
        iconSize: pinSize,
        iconAnchor: IconAnchor.BOTTOM,
        // Add some offset so the pin points to exact location
        iconOffset: [0, 5],
      );

      final annotation = await _pointAnnotationManager!.create(options);
      _reportAnnotations[report.id] = annotation;
      _annotationToReport[annotation.id] = report;
    } catch (e) {
      debugPrint(
        'MapController: Error adding pin for report ${report.id} - $e',
      );
    }
  }

  /// Get pin image path based on severity level
  Future<Uint8List> _getPinImageForSeverity(int level) async {
    String assetPath;
    switch (level) {
      case 1:
        assetPath = trash4;
        break;
      case 2:
        assetPath = trash1;
        break;
      case 3:
        assetPath = trash2;
        break;
      case 4:
        assetPath = trash3;
        break;
      default:
        assetPath = trash1;
        break;
    }
    final byteData = await rootBundle.load(assetPath);
    return byteData.buffer.asUint8List();
  }

  /// Remove a specific report pin
  Future<void> removeReportPin(String reportId) async {
    if (_pointAnnotationManager == null) return;

    final annotation = _reportAnnotations[reportId];
    if (annotation != null) {
      await _pointAnnotationManager!.delete(annotation);
      _reportAnnotations.remove(reportId);

      // Also remove from reverse lookup
      _annotationToReport.removeWhere((key, value) => value.id == reportId);
    }
  }

  /// Clear all report pins from the map
  Future<void> clearReportPins() async {
    if (_pointAnnotationManager == null) return;

    try {
      await _pointAnnotationManager!.deleteAll();
      _reportAnnotations.clear();
      _annotationToReport.clear();
      debugPrint('MapController: Cleared all report pins');
    } catch (e) {
      debugPrint('MapController: Error clearing pins - $e');
    }
  }

  /// Handle pin tap - find the report and trigger callback
  void _handlePinTap(PointAnnotation annotation) {
    final report = _annotationToReport[annotation.id];
    if (report != null && onReportPinTapped != null) {
      onReportPinTapped!(report);
      debugPrint('MapController: Pin tapped for report ${report.id}');
    }
  }

  /// Calculate distance from user to a report
  String? getDistanceToReport(ReportModel report) {
    if (!_locationService.hasValidLocation) return null;
    if (report.location == null || !report.location!.isValid) return null;

    final userLocation = _locationService.currentLocation;
    final reportLocation = report.location!.toLocationModel();
    final distanceKm = userLocation.distanceTo(reportLocation);

    if (distanceKm < 1.0) {
      final meters = (distanceKm * 1000).round();
      return '$meters m';
    } else {
      return '${distanceKm.toStringAsFixed(1)} km';
    }
  }

  // ─── Cleanup ─────────────────────────────────────────────────────────────

  @override
  void onClose() {
    clearReportPins();
    _pointAnnotationManager = null;
    super.onClose();
  }
}

/// Click listener for report pins
// ignore: deprecated_member_use
class _ReportPinClickListener extends OnPointAnnotationClickListener {
  final MapController _controller;

  _ReportPinClickListener(this._controller);

  @override
  void onPointAnnotationClick(PointAnnotation annotation) {
    _controller._handlePinTap(annotation);
  }
}
