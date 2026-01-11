import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

import '../../controllers/home_controller.dart';
import '../../controllers/map_controller.dart';
import '../../models/location.dart';
import '../../utils/constants.dart';
import '../components/home_actions.dart';
import '../components/report_card.dart';
import '../components/report_card_shimmer.dart';
import '../components/report_details_modal.dart';
import '../components/user_avatar.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  static const String routeName = '/home';

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final HomeController controller = Get.find<HomeController>();
  final CardSwiperController swiperController = CardSwiperController();

  @override
  void initState() {
    super.initState();
    // Set up pin tap callback
    _setupPinTapCallback();
  }

  void _setupPinTapCallback() {
    final mapController = Get.find<MapController>();
    mapController.onReportPinTapped = (report) {
      ReportDetailsModal.show(
        context,
        report: report,
        distanceAway: controller.getDistanceToReport(report),
        onNavigate: () {
          // TODO: Open navigation app
          Navigator.pop(context);
        },
        onShare: () {
          // TODO: Share report
          Navigator.pop(context);
        },
      );
    };
  }

  @override
  void dispose() {
    swiperController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        body: Stack(
          clipBehavior: Clip.none,
          children: [
            // Map layer (bottom)
            _MapLayer(controller: controller),

            // Top left controls (avatar + location button)
            _TopLeftControls(controller: controller),

            // Top right actions (leaderboard, trash trails)
            _TopRightActions(controller: controller),

            // Bottom sheet with report cards and new report button
            _BottomSheet(
              controller: controller,
              swiperController: swiperController,
            ),
          ],
        ),
      ),
    );
  }
}

/// Map layer using Mapbox
/// Uses StatefulWidget to preserve map state and avoid rebuilds
class _MapLayer extends StatefulWidget {
  const _MapLayer({required this.controller});

  final HomeController controller;

  @override
  State<_MapLayer> createState() => _MapLayerState();
}

class _MapLayerState extends State<_MapLayer> {
  bool _mapInitialized = false;
  late final LocationModel _initialLocation;

  @override
  void initState() {
    super.initState();
    _checkInitialLocation();
  }

  void _checkInitialLocation() {
    final locationService = widget.controller.locationService;
    if (locationService.hasValidLocation) {
      _initialLocation = locationService.currentLocation;
      _mapInitialized = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Only use Obx for initial loading state, not after map is created
    if (!_mapInitialized) {
      return Obx(() {
        final locationService = widget.controller.locationService;

        if (locationService.isLoading) {
          return Container(
            color: seedPalette.shade50,
            child: const Center(child: CircularProgressIndicator()),
          );
        }

        if (locationService.error.isNotEmpty) {
          return Container(
            color: seedPalette.shade50,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.location_off,
                      size: 64,
                      color: seedPalette.shade300,
                    ),
                    const Gap(16),
                    Text(
                      locationService.error,
                      style: AppTextStyles.body.copyWith(color: greyColor),
                      textAlign: TextAlign.center,
                    ),
                    const Gap(16),
                    FilledButton(
                      onPressed: () async {
                        await locationService.initLocation();
                        if (locationService.hasValidLocation) {
                          setState(() {
                            _initialLocation = locationService.currentLocation;
                            _mapInitialized = true;
                          });
                        }
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        if (!locationService.hasValidLocation) {
          return Container(
            color: seedPalette.shade50,
            child: const Center(child: CircularProgressIndicator()),
          );
        }

        // Location is now valid, initialize the map
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && !_mapInitialized) {
            setState(() {
              _initialLocation = locationService.currentLocation;
              _mapInitialized = true;
            });
          }
        });

        return Container(
          color: seedPalette.shade50,
          child: const Center(child: CircularProgressIndicator()),
        );
      });
    }

    // Map is initialized - render it without Obx to avoid rebuilds
    return MapWidget(
      key: const ValueKey('mapbox_map'),
      cameraOptions: CameraOptions(
        center: Point(
          coordinates: Position(
            _initialLocation.longitude,
            _initialLocation.latitude,
          ),
        ),
        zoom: 14.0,
      ),
      styleUri: MapboxStyles.MAPBOX_STREETS,
      onMapCreated: widget.controller.onMapCreated,
      onCameraChangeListener: (cameraChangedEventData) {
        // Notify controller when user scrolls the map
        widget.controller.onCameraMove();
      },
    );
  }
}

/// Top left controls: User avatar and location button
class _TopLeftControls extends StatelessWidget {
  const _TopLeftControls({required this.controller});

  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.paddingOf(context).top;

    return Positioned(
      top: topPadding + 16.0,
      left: 16.0,
      child: Column(
        children: [
          // User avatar - reactive to auth state changes
          Obx(() {
            final user = controller.currentUser;
            final isGuest = controller.isGuest;

            return Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 12.0,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: UserAvatar(
                    tag: 'user_avatar',
                    name: isGuest ? 'Guest' : user?.displayName ?? 'User',
                    imageUrl: user?.avatar,
                    onTap: () {
                      // TODO: Navigate to profile page
                    },
                    showBorder: true,
                    borderColor: lightColor,
                    borderWidth: 3.0,
                  ),
                )
                .animate(controller: controller.avatarAnimationController)
                .fadeIn(duration: 400.ms)
                .scale(begin: const Offset(0.5, 0.5), duration: 400.ms);
          }),

          // My location button - only shown when user has moved away
          Obx(() {
            if (!controller.showMyLocationButton) {
              return const SizedBox.shrink();
            }

            return Padding(
              padding: const EdgeInsets.only(top: 12.0),
              child: MyLocationButton(onTap: controller.centerOnUserLocation)
                  .animate()
                  .fadeIn(duration: 300.ms)
                  .scale(begin: const Offset(0.8, 0.8), duration: 300.ms),
            );
          }),
        ],
      ),
    );
  }
}

/// Top right actions: Leaderboard and Trash Trails
class _TopRightActions extends StatelessWidget {
  const _TopRightActions({required this.controller});

  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.paddingOf(context).top;

    return Positioned(
      top: topPadding + 16,
      right: 16,
      child: Column(
        spacing: 36.0,
        children: [
          // Leaderboard action
          LeaderboardActionWidget(
                onTap: () {
                  // TODO: Navigate to leaderboard page
                },
              )
              .animate(controller: controller.actionsAnimationController)
              .fadeIn(duration: 400.ms)
              .slideX(begin: 0.5, duration: 400.ms),

          // Trash Trails action
          TrashTrailsActionWidget(
                onTap: () {
                  // TODO: Navigate to trash trails page
                },
              )
              .animate(controller: controller.actionsAnimationController)
              .fadeIn(delay: 150.ms, duration: 400.ms)
              .slideX(begin: 0.5, duration: 400.ms),
        ],
      ),
    );
  }
}

/// Bottom draggable sheet with report cards and new report button
class _BottomSheet extends StatelessWidget {
  const _BottomSheet({
    required this.controller,
    required this.swiperController,
  });

  final HomeController controller;
  final CardSwiperController swiperController;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.22,
      minChildSize: 0.22,
      maxChildSize: 0.5,
      snap: true,
      snapSizes: const [0.22, 0.50],
      controller: controller.sheetController,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(color: Colors.transparent),
          child: SingleChildScrollView(
            controller: scrollController,
            physics: const ClampingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Top row: Drag handle + New Report button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Recent Trails",
                              style: AppTextStyles.h2.copyWith(
                                color: seedColor,
                              ),
                            ),
                            Text(
                              "From the community",
                              style: AppTextStyles.body.copyWith(
                                color: seedColor,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ),
                      NewReportActionWidget(
                            onTap: () {
                              // TODO: Navigate to new report page
                            },
                          )
                          .animate(
                            controller: controller.actionsAnimationController,
                          )
                          .fadeIn(delay: 300.ms, duration: 400.ms)
                          .slideX(begin: 0.5, duration: 400.ms),
                    ],
                  ),
                ),

                const Gap(8),

                // Report cards swiper
                Obx(() {
                  final reportController = controller.reportController;

                  if (reportController.isLoadingReports.value) {
                    return const SizedBox(
                      height: 300,
                      child: ReportCardsShimmerLoading(),
                    );
                  }

                  if (!reportController.hasReports) {
                    return const NoReportsNearby();
                  }

                  return SizedBox(
                    height: 300.0,
                    child: CardSwiper(
                      controller: swiperController,
                      cardsCount: reportController.nearbyReports.length,
                      numberOfCardsDisplayed: reportController
                          .nearbyReports
                          .length
                          .clamp(1, 3),
                      scale: 0.9,
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      allowedSwipeDirection:
                          const AllowedSwipeDirection.symmetric(
                            horizontal: true,
                          ),
                      onSwipe: (previousIndex, currentIndex, direction) {
                        if (currentIndex != null) {
                          controller.onReportCardChanged(currentIndex);
                        }
                        return true;
                      },
                      cardBuilder:
                          (
                            context,
                            index,
                            percentThresholdX,
                            percentThresholdY,
                          ) {
                            final report =
                                reportController.nearbyReports[index];
                            return ReportCard(
                              report: report,
                              distanceAway: controller.getDistanceToReport(
                                report,
                              ),
                              onTap: () {
                                // TODO: Navigate to report details
                              },
                            );
                          },
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }
}
