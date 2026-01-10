import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

import '../models/location.dart';

/// Service for handling Mapbox map functionality
class MapService extends GetxService {
  // ─── Map Instance ────────────────────────────────────────────────────────
  MapboxMap? _mapboxMap;

  // ─── State ───────────────────────────────────────────────────────────────
  final RxBool _isMapReady = false.obs;
  final Rx<CameraOptions?> _currentCamera = Rx<CameraOptions?>(null);

  // ─── Callbacks ───────────────────────────────────────────────────────────
  /// Callback when camera position changes (latitude, longitude)
  void Function(double latitude, double longitude)? onCameraChanged;

  // ─── Getters ─────────────────────────────────────────────────────────────
  MapboxMap? get mapboxMap => _mapboxMap;
  bool get isMapReady => _isMapReady.value;
  CameraOptions? get currentCamera => _currentCamera.value;

  /// Mapbox access token from environment
  static String get accessToken => dotenv.env['MAPBOX_ACCESS_TOKEN'] ?? '';

  /// Check if Mapbox is configured
  static bool get isConfigured => accessToken.isNotEmpty;

  // ─── Map Lifecycle ───────────────────────────────────────────────────────

  /// Called when the map is created
  void onMapCreated(MapboxMap map) {
    _mapboxMap = map;
    _isMapReady.value = true;
    _configureMapStyle();
    debugPrint('MapService: Map created and configured');
  }

  /// Notify camera changed callback with current camera center
  Future<void> notifyCameraChanged() async {
    if (_mapboxMap == null || onCameraChanged == null) return;

    try {
      final cameraState = await _mapboxMap!.getCameraState();
      final center = cameraState.center;
      onCameraChanged!(
        center.coordinates.lat.toDouble(),
        center.coordinates.lng.toDouble(),
      );
    } catch (e) {
      debugPrint('MapService: Error getting camera state - $e');
    }
  }

  /// Configure map style and hide default UI elements
  void _configureMapStyle() {
    if (_mapboxMap == null) return;

    // Hide UI elements by applying large margins instead of disabling
    _mapboxMap!.logo.updateSettings(LogoSettings(
      marginLeft: 10000,
      marginBottom: 10000,
    ));
    _mapboxMap!.attribution.updateSettings(AttributionSettings(
      marginLeft: 10000,
      marginBottom: 10000,
    ));
    _mapboxMap!.scaleBar.updateSettings(ScaleBarSettings(
      enabled: false,
    ));
    _mapboxMap!.compass.updateSettings(CompassSettings(
      enabled: false,
    ));
    _mapboxMap!.location.updateSettings(LocationComponentSettings(
      enabled: true,
      showAccuracyRing: true,
      pulsingEnabled: true,
      puckBearingEnabled: true,
    ));
  }

  /// Dispose map resources
  void disposeMap() {
    _mapboxMap = null;
    _isMapReady.value = false;
  }

  // ─── Camera Methods ──────────────────────────────────────────────────────

  /// Animate camera to a specific location
  Future<void> animateToLocation(
    LocationModel location, {
    double zoom = 15.0,
    double pitch = 45.0,
    double bearing = 0,
    int durationMs = 2000,
  }) async {
    if (!_isMapReady.value || _mapboxMap == null) return;
    if (!location.isValid) return;

    final cameraOptions = CameraOptions(
      center: Point(
        coordinates: Position(
          location.longitude,
          location.latitude,
        ),
      ),
      zoom: zoom,
      pitch: pitch,
      bearing: bearing,
    );

    await _mapboxMap!.flyTo(
      cameraOptions,
      MapAnimationOptions(duration: durationMs),
    );

    _currentCamera.value = cameraOptions;

    // Notify camera changed after animation
    await notifyCameraChanged();
  }

  /// Animate camera to coordinates
  Future<void> animateToCoordinates(
    double latitude,
    double longitude, {
    double zoom = 15.0,
    double pitch = 45.0,
    double bearing = 0,
    int durationMs = 2000,
  }) async {
    await animateToLocation(
      LocationModel(latitude: latitude, longitude: longitude),
      zoom: zoom,
      pitch: pitch,
      bearing: bearing,
      durationMs: durationMs,
    );
  }

  /// Zoom in
  Future<void> zoomIn({int durationMs = 300}) async {
    if (!_isMapReady.value || _mapboxMap == null) return;

    final currentZoom = await _mapboxMap!.getCameraState();
    await _mapboxMap!.flyTo(
      CameraOptions(zoom: currentZoom.zoom + 1),
      MapAnimationOptions(duration: durationMs),
    );
  }

  /// Zoom out
  Future<void> zoomOut({int durationMs = 300}) async {
    if (!_isMapReady.value || _mapboxMap == null) return;

    final currentZoom = await _mapboxMap!.getCameraState();
    await _mapboxMap!.flyTo(
      CameraOptions(zoom: currentZoom.zoom - 1),
      MapAnimationOptions(duration: durationMs),
    );
  }

  /// Set camera zoom level
  Future<void> setZoom(double zoom, {int durationMs = 300}) async {
    if (!_isMapReady.value || _mapboxMap == null) return;

    await _mapboxMap!.flyTo(
      CameraOptions(zoom: zoom),
      MapAnimationOptions(duration: durationMs),
    );
  }

  /// Get current camera state
  Future<CameraState?> getCameraState() async {
    if (!_isMapReady.value || _mapboxMap == null) return null;
    return await _mapboxMap!.getCameraState();
  }

  // ─── Map Style ───────────────────────────────────────────────────────────

  /// Change map style
  Future<void> setStyle(String styleUri) async {
    if (!_isMapReady.value || _mapboxMap == null) return;
    await _mapboxMap!.loadStyleURI(styleUri);
  }

  /// Use streets style
  Future<void> useStreetsStyle() async {
    await setStyle(MapboxStyles.MAPBOX_STREETS);
  }

  /// Use satellite style
  Future<void> useSatelliteStyle() async {
    await setStyle(MapboxStyles.SATELLITE);
  }

  /// Use dark style
  Future<void> useDarkStyle() async {
    await setStyle(MapboxStyles.DARK);
  }

  /// Use light style
  Future<void> useLightStyle() async {
    await setStyle(MapboxStyles.LIGHT);
  }
}

