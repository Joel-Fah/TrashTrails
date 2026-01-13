import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../models/models.dart';
import '../services/services.dart';
import '../utils/constants.dart';
import 'report_controller.dart';

/// Simple model for location search results
class LocationSearchResult {
  final String placeName;
  final double latitude;
  final double longitude;

  const LocationSearchResult({
    required this.placeName,
    required this.latitude,
    required this.longitude,
  });

  factory LocationSearchResult.fromMapboxFeature(Map<String, dynamic> feature) {
    final center = feature['center'] as List<dynamic>?;
    return LocationSearchResult(
      placeName: feature['place_name'] as String? ?? '',
      longitude: center?[0]?.toDouble() ?? 0.0,
      latitude: center?[1]?.toDouble() ?? 0.0,
    );
  }
}

/// Controller for the New Report page
/// Handles camera capture, form state, and report submission
/// Optimized for reduced friction flow
class NewReportController extends GetxController {
  // ─── Services ────────────────────────────────────────────────────────────
  final LocationService _locationService = Get.find<LocationService>();
  final ReportController _reportController = Get.find<ReportController>();
  final ImagePicker _imagePicker = ImagePicker();
  final Dio _dio = Dio();

  // ─── Mapbox Config ───────────────────────────────────────────────────────
  String _mapboxAccessToken = '';

  // ─── State ───────────────────────────────────────────────────────────────

  /// Current phase of the report creation
  final Rx<ReportCreationPhase> currentPhase = ReportCreationPhase.camera.obs;

  /// Captured images (max 3)
  final RxList<File> capturedImages = <File>[].obs;

  /// Whether submitting the report
  final RxBool isSubmitting = false.obs;

  /// Whether searching for location
  final RxBool isSearchingLocation = false.obs;

  /// Current image index in full screen viewer
  final RxInt currentImageIndex = 0.obs;

  /// Search results for location
  final RxList<LocationSearchResult> locationSearchResults = <LocationSearchResult>[].obs;

  /// Search query for location
  final RxString locationSearchQuery = ''.obs;

  /// Flag to prevent search trigger when programmatically setting text
  bool _isSelectingLocation = false;

  // ─── Form Fields ─────────────────────────────────────────────────────────

  /// Report title
  final RxString title = ''.obs;

  /// Report observation/description
  final RxString observation = ''.obs;

  /// Selected severity level (default: Medium = 2)
  final RxInt selectedSeverityLevel = 2.obs;

  /// Selected category
  final Rx<TrashCategoryModel?> selectedCategory = Rx<TrashCategoryModel?>(null);

  /// Current location (coordinates)
  final Rx<LocationModel?> currentLocation = Rx<LocationModel?>(null);

  /// Selected street name from search
  final RxString selectedStreetName = ''.obs;

  // ─── Form Controllers ────────────────────────────────────────────────────
  final TextEditingController titleController = TextEditingController();
  final TextEditingController observationController = TextEditingController();
  final TextEditingController locationSearchController = TextEditingController();

  // ─── Animation Controllers ───────────────────────────────────────────────
  AnimationController? phaseAnimationController;

  // ─── Constants ───────────────────────────────────────────────────────────
  static const int maxImages = 3;

  // ─── Severity Colors ─────────────────────────────────────────────────────
  static const Color lowColor = Color(0xFF4CAF50);
  static const Color mediumColor = Color(0xFFFFA726);
  static const Color highColor = Color(0xFFFF7043);
  static const Color criticalColor = Color(0xFFF44336);

  // ─── Getters ─────────────────────────────────────────────────────────────

  bool get canTakeMorePhotos => capturedImages.length < maxImages;
  bool get hasPhotos => capturedImages.isNotEmpty;
  int get remainingPhotos => maxImages - capturedImages.length;
  bool get isInCameraPhase => currentPhase.value == ReportCreationPhase.camera;
  bool get isInFormPhase => currentPhase.value == ReportCreationPhase.form;
  bool get isInFullScreenPhase => currentPhase.value == ReportCreationPhase.fullScreenImage;

  List<TrashCategoryModel> get availableCategories =>
      _reportController.categories;

  List<ReportSeverityModel> get availableSeverities =>
      _reportController.severities;

  bool get isLoadingData =>
      _reportController.isLoadingCategories.value ||
      _reportController.isLoadingSeverities.value;

  bool get hasCategories => _reportController.hasCategories;
  bool get hasSeverities => _reportController.hasSeverities;

  bool get isFormValid =>
      title.value.isNotEmpty &&
      selectedCategory.value != null &&
      selectedSeverity != null &&
      hasPhotos;

  /// Get the currently selected severity model
  ReportSeverityModel? get selectedSeverity {
    if (availableSeverities.isEmpty) return null;
    return availableSeverities.firstWhereOrNull(
      (s) => s.level == selectedSeverityLevel.value,
    );
  }

  /// Get the description of the selected severity
  String? get selectedSeverityDescription => selectedSeverity?.description;

  /// Get the trash image based on severity level
  String get severityTrashImage {
    return switch (selectedSeverityLevel.value) {
      1 => trash4,  // Low
      2 => trash1,  // Medium
      3 => trash2,  // High
      4 => trash3,  // Critical
      _ => trash4,  // Default Medium
    };
  }

  /// Get severity color based on level
  Color getSeverityColor(int level) {
    return switch (level) {
      1 => lowColor,
      2 => mediumColor,
      3 => highColor,
      4 => criticalColor,
      _ => mediumColor,
    };
  }

  Color get selectedSeverityColor => getSeverityColor(selectedSeverityLevel.value);

  // ─── Lifecycle ───────────────────────────────────────────────────────────

  @override
  void onInit() {
    super.onInit();
    _initMapboxSearch();
    _initLocation();
    _loadFormData();

    // Sync text controllers with observables
    titleController.addListener(() => title.value = titleController.text);
    observationController.addListener(() => observation.value = observationController.text);
    locationSearchController.addListener(_onLocationSearchChanged);
  }

  @override
  void onClose() {
    titleController.dispose();
    observationController.dispose();
    locationSearchController.dispose();
    super.onClose();
  }

  // ─── Initialization ──────────────────────────────────────────────────────

  void _initMapboxSearch() {
    _mapboxAccessToken = dotenv.env['MAPBOX_ACCESS_TOKEN'] ?? '';
  }

  /// Load categories and severities if not already loaded
  Future<void> _loadFormData() async {
    // Load categories if empty
    if (!hasCategories) {
      await _reportController.loadCategories();
    }

    // Load severities if empty
    if (!hasSeverities) {
      await _reportController.loadSeverities();
    }

    // Set defaults after data is loaded
    _setDefaultCategory();
    _setDefaultSeverity();
  }

  void _setDefaultCategory() {
    if (availableCategories.isEmpty) return;
    if (selectedCategory.value != null) return;

    // Set default to "Mixed" or first available category
    final mixedCategory = availableCategories.firstWhereOrNull(
      (c) => c.code.toLowerCase() == 'mixed' || c.code.toLowerCase() == 'mix',
    );
    selectedCategory.value = mixedCategory ?? availableCategories.first;
    debugPrint('NewReportController: Default category set to ${selectedCategory.value?.name}');
  }

  void _setDefaultSeverity() {
    if (availableSeverities.isEmpty) return;

    // Set default to Medium (level 2) if available
    final mediumSeverity = availableSeverities.firstWhereOrNull(
      (s) => s.level == 2,
    );
    if (mediumSeverity != null) {
      selectedSeverityLevel.value = mediumSeverity.level;
    } else if (availableSeverities.isNotEmpty) {
      selectedSeverityLevel.value = availableSeverities.first.level;
    }
    debugPrint('NewReportController: Default severity set to level ${selectedSeverityLevel.value}');
  }

  Future<void> _initLocation() async {
    if (_locationService.hasValidLocation) {
      currentLocation.value = _locationService.currentLocation;
    } else {
      await _locationService.initLocation();
      if (_locationService.hasValidLocation) {
        currentLocation.value = _locationService.currentLocation;
      }
    }
    debugPrint('NewReportController: Location initialized - ${currentLocation.value}');
  }


  // ─── Phase Management ────────────────────────────────────────────────────

  /// Move to form phase (after taking at least one photo)
  void goToFormPhase() {
    if (!hasPhotos) {
      debugPrint('NewReportController: Cannot go to form without photos');
      return;
    }
    currentPhase.value = ReportCreationPhase.form;
    debugPrint('NewReportController: Moved to form phase');
  }

  /// Go back to camera phase
  void goToCameraPhase() {
    currentPhase.value = ReportCreationPhase.camera;
    debugPrint('NewReportController: Moved to camera phase');
  }

  /// Open full screen image viewer
  void openFullScreenImage(int index) {
    currentImageIndex.value = index;
    currentPhase.value = ReportCreationPhase.fullScreenImage;
    debugPrint('NewReportController: Opened full screen image at index $index');
  }

  /// Close full screen image viewer
  void closeFullScreenImage() {
    currentPhase.value = ReportCreationPhase.form;
    debugPrint('NewReportController: Closed full screen image');
  }

  // ─── Camera Methods ──────────────────────────────────────────────────────

  /// Take a photo using the camera - streamlined flow
  Future<void> takePhoto() async {
    if (!canTakeMorePhotos) {
      debugPrint('NewReportController: Maximum photos reached');
      return;
    }

    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1080,
      );

      if (image != null) {
        capturedImages.add(File(image.path));
        debugPrint('NewReportController: Photo captured (${capturedImages.length}/$maxImages)');

        // Auto-transition to form after first photo for reduced friction
        // User can still add more photos from the form
        if (capturedImages.length == 1) {
          // Small delay for smooth transition
          await Future.delayed(const Duration(milliseconds: 300));
          goToFormPhase();
        }
      }
    } catch (e) {
      debugPrint('NewReportController: Error taking photo - $e');
    }
  }

  /// Add more photos from form phase
  Future<void> addMorePhotos() async {
    if (!canTakeMorePhotos) return;

    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1080,
      );

      if (image != null) {
        capturedImages.add(File(image.path));
        debugPrint('NewReportController: Added photo (${capturedImages.length}/$maxImages)');
      }
    } catch (e) {
      debugPrint('NewReportController: Error adding photo - $e');
    }
  }

  /// Remove a captured image
  void removeImage(int index) {
    if (index >= 0 && index < capturedImages.length) {
      capturedImages.removeAt(index);
      debugPrint('NewReportController: Image removed, ${capturedImages.length} remaining');

      // If no photos left, go back to camera
      if (capturedImages.isEmpty && isInFormPhase) {
        goToCameraPhase();
      }
    }
  }

  // ─── Location Search ─────────────────────────────────────────────────────

  void _onLocationSearchChanged() {
    // Ignore changes when programmatically setting text after selection
    if (_isSelectingLocation) return;

    final query = locationSearchController.text;
    locationSearchQuery.value = query;

    if (query.length >= 3) {
      _searchLocation(query);
    } else {
      locationSearchResults.clear();
    }
  }

  /// Dismiss location search results (e.g., when tapping outside)
  void dismissLocationResults() {
    locationSearchResults.clear();
    locationSearchQuery.value = '';
  }

  Future<void> _searchLocation(String query) async {
    if (_mapboxAccessToken.isEmpty) return;

    isSearchingLocation.value = true;

    try {
      final encodedQuery = Uri.encodeComponent(query);

      // Build proximity parameter from current location
      String proximityParam = '';
      if (currentLocation.value != null) {
        proximityParam = '&proximity=${currentLocation.value!.longitude},${currentLocation.value!.latitude}';
      }

      // Cameroon bounding box: [lon_min, lat_min, lon_max, lat_max]
      const cameroonBbox = '8.4,1.6,16.2,13.1';

      final url = 'https://api.mapbox.com/geocoding/v5/mapbox.places/$encodedQuery.json'
          '?access_token=$_mapboxAccessToken'
          '&limit=5'
          '&types=address,poi,place,locality,neighborhood'
          '&country=CM'  // Restrict to Cameroon
          '&bbox=$cameroonBbox'  // Cameroon bounding box
          '$proximityParam';  // Favor results near user's location

      final response = await _dio.get(url);

      if (response.statusCode == 200 && response.data != null) {
        final features = response.data['features'] as List<dynamic>?;
        if (features != null && features.isNotEmpty) {
          locationSearchResults.value = features
              .map((f) => LocationSearchResult.fromMapboxFeature(f as Map<String, dynamic>))
              .toList();
        } else {
          locationSearchResults.clear();
        }
      } else {
        locationSearchResults.clear();
      }
    } catch (e) {
      debugPrint('NewReportController: Location search error - $e');
      locationSearchResults.clear();
    } finally {
      isSearchingLocation.value = false;
    }
  }

  /// Select a location from search results
  void selectLocation(LocationSearchResult place) {
    _isSelectingLocation = true;

    selectedStreetName.value = place.placeName;
    locationSearchController.text = place.placeName;
    locationSearchResults.clear();
    locationSearchQuery.value = ''; // Clear query to hide results

    // Update coordinates
    currentLocation.value = LocationModel(
      latitude: place.latitude,
      longitude: place.longitude,
      address: place.placeName,
    );

    debugPrint('NewReportController: Location selected - ${place.placeName}');

    // Reset flag after a short delay to allow listener to be skipped
    Future.delayed(const Duration(milliseconds: 100), () {
      _isSelectingLocation = false;
    });
  }

  /// Use custom street name (when user doesn't find what they're looking for)
  void useCustomStreetName() {
    final customName = locationSearchController.text.trim();
    if (customName.isEmpty) return;

    _isSelectingLocation = true;

    selectedStreetName.value = customName;
    locationSearchResults.clear();
    locationSearchQuery.value = ''; // Clear query to hide results

    debugPrint('NewReportController: Custom street name set - $customName');

    // Reset flag after a short delay
    Future.delayed(const Duration(milliseconds: 100), () {
      _isSelectingLocation = false;
    });
  }

  /// Clear location search
  void clearLocationSearch() {
    locationSearchController.clear();
    locationSearchResults.clear();
    selectedStreetName.value = '';
  }

  // ─── Form Methods ────────────────────────────────────────────────────────

  /// Set the selected severity level
  void setSeverity(int level) {
    selectedSeverityLevel.value = level.clamp(1, 4);
    debugPrint('NewReportController: Severity set to $level');
  }

  /// Set the selected category
  void setCategory(TrashCategoryModel category) {
    selectedCategory.value = category;
    debugPrint('NewReportController: Category set to ${category.name}');
  }

  /// Get severity model by level
  ReportSeverityModel? getSeverityByLevel(int level) {
    return availableSeverities.firstWhereOrNull((s) => s.level == level);
  }

  // ─── Submission ──────────────────────────────────────────────────────────

  /// Submit the report and return the creation result with points
  Future<ReportCreationResult?> submitReport() async {
    if (!isFormValid) {
      debugPrint('NewReportController: Form is not valid');
      return null;
    }

    isSubmitting.value = true;

    try {
      // Get severity model
      final severity = getSeverityByLevel(selectedSeverityLevel.value);
      if (severity == null) {
        debugPrint('NewReportController: Severity not found');
        return null;
      }

      // Get image paths for upload
      final imagePaths = capturedImages.map((file) => file.path).toList();

      // Create report via controller with points
      final result = await _reportController.createReportWithPoints(
        title: title.value,
        observation: observation.value.isNotEmpty ? observation.value : null,
        severityId: severity.id,
        categoryId: selectedCategory.value!.id,
        location: currentLocation.value,
        imagePaths: imagePaths,
      );

      if (result != null) {
        debugPrint('NewReportController: Report created successfully - ${result.report.id}, Points: ${result.points?.pointsAwarded ?? 0}');
        return result;
      } else {
        debugPrint('NewReportController: Failed to create report');
        return null;
      }
    } catch (e) {
      debugPrint('NewReportController: Error submitting report - $e');
      return null;
    } finally {
      isSubmitting.value = false;
    }
  }

  /// Reset the controller state
  void reset() {
    capturedImages.clear();
    currentPhase.value = ReportCreationPhase.camera;
    isSubmitting.value = false;
    title.value = '';
    observation.value = '';
    selectedSeverityLevel.value = 2;
    selectedStreetName.value = '';
    selectedCategory.value = null;
    titleController.clear();
    observationController.clear();
    locationSearchController.clear();
    locationSearchResults.clear();

    // Reload form data (categories and severities)
    _loadFormData();

    debugPrint('NewReportController: State reset');
  }
}

/// Phases of report creation
enum ReportCreationPhase {
  camera,
  form,
  fullScreenImage,
}

/// Flash mode enum for camera
enum FlashMode {
  off,
  auto,
  always,
  torch,
}

