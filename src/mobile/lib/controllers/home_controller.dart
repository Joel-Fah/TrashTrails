import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../models/report.dart';
import '../models/user.dart';
import '../services/services.dart';
import 'map_controller.dart';
import 'report_controller.dart';

/// Controller for the Home page
/// Coordinates between MapController, ReportController, and other services
class HomeController extends GetxController with GetTickerProviderStateMixin {
  // ─── Controllers ─────────────────────────────────────────────────────────
  MapController get mapController => Get.find<MapController>();
  ReportController get reportController => Get.find<ReportController>();

  // ─── Services ────────────────────────────────────────────────────────────
  final AuthService _authService = Get.find<AuthService>();

  // ─── UI State ────────────────────────────────────────────────────────────
  final RxInt _currentReportIndex = 0.obs;
  final RxDouble _sheetPosition = 0.15.obs;
  final RxBool _isInitialized = false.obs;

  // ─── Draggable Sheet Controller ──────────────────────────────────────────
  final DraggableScrollableController sheetController =
      DraggableScrollableController();

  // ─── Animation Controllers ───────────────────────────────────────────────
  late AnimationController avatarAnimationController;
  late AnimationController actionsAnimationController;

  // ─── Getters (Proxies) ───────────────────────────────────────────────────
  LocationService get locationService => mapController.locationService;
  bool get showMyLocationButton => mapController.showMyLocationButton;

  // ─── User Getters ────────────────────────────────────────────────────────
  UserModel? get currentUser => _authService.currentUser;
  bool get isAuthenticated => _authService.isAuthenticated;
  bool get isGuest => !isAuthenticated || currentUser == null;

  // ─── State Getters ───────────────────────────────────────────────────────
  int get currentReportIndex => _currentReportIndex.value;
  double get sheetPosition => _sheetPosition.value;
  bool get isInitialized => _isInitialized.value;

  /// Get nearby reports from the controller
  List<ReportModel> get nearbyReports => reportController.nearbyReports;
  bool get hasNearbyReports => reportController.hasReports;

  ReportModel? get currentReport {
    if (!hasNearbyReports) return null;
    if (_currentReportIndex.value >= nearbyReports.length) {
      return null;
    }
    return nearbyReports[_currentReportIndex.value];
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
    if (!locationService.hasValidLocation) {
      await locationService.initLocation();
    }

    if (locationService.hasValidLocation) {
      // Load nearby reports
      await reportController.loadReports(refresh: true);

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

  // ─── Map Methods (Delegated to MapController) ────────────────────────────

  /// Called when the map is created
  Future<void> onMapCreated(dynamic mapboxMap) async {
    await mapController.onMapCreated(mapboxMap);

    // Update map pins when reports are loaded
    if (reportController.hasReports) {
      await mapController.updateReportPins(nearbyReports);
    }
  }

  /// Called when the user scrolls/moves the map
  void onCameraMove() {
    mapController.onCameraMove();
  }

  /// Center map on user's current location
  Future<void> centerOnUserLocation() async {
    await mapController.centerOnUserLocation();
  }

  // ─── Report Methods ──────────────────────────────────────────────────────

  /// Called when swiping to a new report card
  void onReportCardChanged(int index) {
    if (index >= 0 && index < nearbyReports.length) {
      _currentReportIndex.value = index;

      // Animate map to report location
      final report = nearbyReports[index];
      mapController.animateToReport(report);
    }
  }

  /// Calculate distance from user to a report
  String? getDistanceToReport(ReportModel report) {
    return mapController.getDistanceToReport(report);
  }

  /// Refresh nearby reports and update map pins
  Future<void> refreshReports() async {
    await reportController.refreshReports();
    _currentReportIndex.value = 0;

    // Update map pins
    await mapController.updateReportPins(nearbyReports);
  }

  // ─── Sheet Methods ───────────────────────────────────────────────────────

  /// Updates the sheet position
  void updateSheetPosition(double position) {
    _sheetPosition.value = position;
  }
}
