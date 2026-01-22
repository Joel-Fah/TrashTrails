import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:trashtrails/ui/components/default_snack_bar.dart';
import 'package:trashtrails/ui/components/widgets/buttons/primary_button.dart';
import 'package:trashtrails/utils/utils.dart';

import '../../../controllers/controllers.dart';
import '../../../models/models.dart';
import '../../../utils/constants.dart';
import 'report_points.dart';

/// Page for creating a new trash report
/// Streamlined flow: Take photo → Auto-transition to form → Submit
class NewReportPage extends StatefulWidget {
  const NewReportPage({super.key});

  static const String routeName = '/new-report';

  @override
  State<NewReportPage> createState() => _NewReportPageState();
}

class _NewReportPageState extends State<NewReportPage>
    with TickerProviderStateMixin {
  final NewReportController newReportController =
      Get.find<NewReportController>();
  late final AnimationController _phaseAnimationController;

  @override
  void initState() {
    super.initState();

    // Reset controller state for fresh start
    newReportController.reset();

    // Setup animations
    _phaseAnimationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    // Open camera immediately when page loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _openCamera();
    });
  }

  @override
  void dispose() {
    _phaseAnimationController.dispose();
    super.dispose();
  }

  Future<void> _openCamera() async {
    await newReportController.takePhoto();
  }

  void _onSubmit() async {
    final result = await newReportController.submitReport();
    if (result != null) {
      if (mounted) {
        // Set points in controller if available
        if (result.hasPoints && result.points != null) {
          final pointsController = Get.find<PointsController>();
          print('Points JSON: ${result.points?.toJson()}');
          pointsController.setPoints(result.points!, result.overallRank!);
          // Navigate to points page
          context.pushReplacementNamed(removeLeadingSlash(ReportPointsPage.routeName));
        } else {
          // No points data, just show success and go back
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              buildSnackBar(
                backgroundColor: successColor,
                prefixIcon: HugeIcon(icon: successIcon, color: lightColor),
                label: Text('Report submitted successfully!'),
              ),
            );
          context.pop(true);
        }
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            buildSnackBar(
              backgroundColor: errorColor,
              prefixIcon: HugeIcon(icon: errorIcon, color: lightColor),
              label: Text('Failed to submit report. Please try again.'),
            ),
          );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: GestureDetector(
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: Scaffold(
          backgroundColor: seedPalette.shade800,
          body: Obx(() {
            // Rebuild when phase changes
            final _ = newReportController.currentPhase.value;

            return Stack(
              children: [
                // Background - Images swiper (visible in form phase)
                if (newReportController.hasPhotos &&
                    newReportController.isInFormPhase)
                  _ImageSwiperBackground(controller: newReportController),

                // Camera placeholder (visible in camera phase)
                if (newReportController.isInCameraPhase)
                  _CameraPlaceholder(
                    controller: newReportController,
                    onTakePhoto: _openCamera,
                  ),

                // Top controls
                _TopControls(
                  controller: newReportController,
                  onClose: () => context.pop(),
                ),

                // Form sheet (when in form phase)
                if (newReportController.isInFormPhase)
                  _FormSheet(
                    controller: newReportController,
                    onSubmit: _onSubmit,
                  ),

                // Full screen image viewer
                if (newReportController.isInFullScreenPhase)
                  _FullScreenImageViewer(controller: newReportController),
              ],
            );
          }),
        ),
      ),
    );
  }
}

/// Background image swiper with hero support
class _ImageSwiperBackground extends StatelessWidget {
  const _ImageSwiperBackground({required this.controller});

  final NewReportController controller;

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.paddingOf(context).top;

    return Positioned(
      top: 20,
      left: 0,
      right: 0,
      height: mediaHeight(context) * 0.45,
      child: Obx(() {
        final images = controller.capturedImages;
        if (images.isEmpty) return const SizedBox.shrink();

        if (images.length == 1) {
          // Single image - full view
          return GestureDetector(
            onTap: () => controller.openFullScreenImage(0),
            child: Hero(
              tag: 'report_image_0',
              child: Container(
                margin: EdgeInsets.only(
                  top: topPadding + 56.0,
                  left: 16.0,
                  right: 16.0,
                  bottom: 16.0,
                ),
                decoration: BoxDecoration(
                  borderRadius: borderRadius * 2.0,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: borderRadius * 2.5,
                  child: Image.file(
                    images[0],
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                  ),
                ),
              ),
            ),
          );
        }

        // Multiple images - swiper
        return Container(
          margin: EdgeInsets.only(top: topPadding + 40.0),
          child: CardSwiper(
            cardsCount: images.length,
            numberOfCardsDisplayed: images.length.clamp(1, 2),
            scale: 0.9,
            cardBuilder:
                (context, index, percentThresholdX, percentThresholdY) {
                  return GestureDetector(
                    onTap: () => controller.openFullScreenImage(index),
                    child: Hero(
                      tag: 'report_image_$index',
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: borderRadius * 2.5,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: borderRadius * 2.5,
                          child: Image.file(
                            images[index],
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                          ),
                        ),
                      ),
                    ),
                  );
                },
          ),
        );
      }),
    ).animate().fadeIn(duration: 400.ms);
  }
}

/// Camera placeholder with streamlined capture flow
class _CameraPlaceholder extends StatelessWidget {
  const _CameraPlaceholder({
    required this.controller,
    required this.onTakePhoto,
  });

  final NewReportController controller;
  final VoidCallback onTakePhoto;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 32.0,
            vertical: 24.0,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Spacer(),

              // Camera icon
              Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: seedPalette.shade400.withValues(alpha: 0.1),
                          blurRadius: 60.0,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Image.asset(camera, width: 200),
                  )
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .scale(
                    begin: const Offset(1, 1),
                    end: const Offset(1.05, 1.05),
                    duration: 1500.ms,
                  ),

              const Gap(32.0),

              // Instructions
              Text(
                'Take a photo of a trash dump',
                style: AppTextStyles.h2.copyWith(color: lightColor),
                textAlign: TextAlign.center,
              ),

              const Gap(8),

              Text(
                'You can add up to ${NewReportController.maxImages} photos. So, get those angles right',
                style: AppTextStyles.body.copyWith(
                  color: seedPalette.shade200,
                ),
                textAlign: TextAlign.center,
              ),

              const Spacer(),

              // Capture button
              Material(
                color: Colors.transparent,
                type: MaterialType.transparency,
                child:
                    InkWell(
                          borderRadius: borderRadius * 10.0,
                          onTap: onTakePhoto,
                          child: Container(
                            width: 88.0,
                            height: 88.0,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: lightColor.withValues(alpha: 0.5),
                                width: 6.0,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: seedColor.withValues(alpha: 0.4),
                                  blurRadius: 20,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: Container(
                              alignment: Alignment.center,
                              decoration: const BoxDecoration(
                                color: lightColor,
                                shape: BoxShape.circle,
                              ),
                              child: HugeIcon(
                                icon: HugeIcons.strokeRoundedCamera03,
                                color: seedColor,
                                size: 36.0,
                                strokeWidth: 1.8,
                              ),
                            ),
                          ),
                        )
                        .animate()
                        .fadeIn(delay: 200.ms, duration: 400.ms)
                        .scale(
                          begin: const Offset(0.8, 0.8),
                          duration: 400.ms,
                        ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 300.ms);
  }
}

/// Top controls
class _TopControls extends StatelessWidget {
  const _TopControls({required this.controller, required this.onClose});

  final NewReportController controller;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.paddingOf(context).top;

    return Positioned(
      top: topPadding + 8,
      left: 16.0,
      right: 16.0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Close button
          _ControlButton(
            icon: HugeIcons.strokeRoundedCancel01,
            onPressed: onClose,
          ),

          // Photo count (in form phase)
          Obx(
            () => controller.isInFormPhase && controller.hasPhotos
                ? Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8.0,
                    ),
                    decoration: BoxDecoration(
                      color: seedColor,
                      borderRadius: borderRadius * 1.5,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const HugeIcon(
                          icon: HugeIcons.strokeRoundedAlbum02,
                          color: lightColor,
                          size: 16.0,
                        ),
                        const Gap(6.0),
                        Text(
                          '${controller.capturedImages.length} photo${controller.capturedImages.length > 1 ? 's' : ''} / ${NewReportController.maxImages}',
                          style: AppTextStyles.small.copyWith(
                            color: lightColor,
                            fontWeight: FontWeight.w500,
                            fontVariations: [FontVariation('wght', 500)],
                          ),
                        ),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.3, duration: 300.ms);
  }
}

/// Control button
class _ControlButton extends StatelessWidget {
  const _ControlButton({required this.icon, required this.onPressed});

  final List<List<dynamic>> icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton.filled(
      tooltip: "Close",
      style: IconButton.styleFrom(
        padding: EdgeInsets.all(12.0),
        shape: CircleBorder(
          side: BorderSide(color: seedPalette.shade200.withValues(alpha: 0.3)),
        ),
        backgroundColor: seedPalette.shade900.withValues(alpha: 0.7),
      ),
      onPressed: onPressed,
      icon: HugeIcon(icon: icon, color: lightColor),
    );
  }
}

/// Form sheet
class _FormSheet extends StatelessWidget {
  const _FormSheet({required this.controller, required this.onSubmit});

  final NewReportController controller;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
          initialChildSize: 0.58,
          minChildSize: 0.3,
          maxChildSize: 0.92,
          snap: true,
          snapSizes: const [0.3, 0.58, 0.92],
          builder: (context, scrollController) {
            return Container(
              clipBehavior: Clip.hardEdge,
              decoration: BoxDecoration(
                color: lightColor,
                borderRadius: topRadius * 2.5,
                border: Border.all(width: 4.0, color: lightColor),
                boxShadow: [
                  BoxShadow(
                    color: darkColor.withValues(alpha: 0.25),
                    blurRadius: 30.0,
                    offset: const Offset(0, -8),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Gap(12),

                    // Drag handle
                    Center(
                      child: Container(
                        width: 72.0,
                        height: 6,
                        decoration: BoxDecoration(
                          color: greyColor.withValues(alpha: 0.3),
                          borderRadius: borderRadius * 2,
                        ),
                      ),
                    ),
                    const Gap(20),

                    // Header with add photo button
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Report Details', style: AppTextStyles.h1),
                              const Gap(4.0),
                              Text(
                                'Quickly fill in the fields below to add a new trail',
                                style: AppTextStyles.small.copyWith(
                                  fontStyle: FontStyle.italic,
                                  color: seedColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Add more photos button
                        Obx(
                          () => controller.canTakeMorePhotos
                              ? Tooltip(
                                  message: "Add photo",
                                  preferBelow: false,
                                  child: GestureDetector(
                                    onTap: controller.addMorePhotos,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12.0,
                                        vertical: 8.0,
                                      ),
                                      decoration: BoxDecoration(
                                        color: seedPalette.shade50,
                                        borderRadius: borderRadius * 2.0,
                                        border: Border.all(
                                          color: seedPalette.shade200,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          HugeIcon(
                                            icon:
                                                HugeIcons.strokeRoundedCamera03,
                                            color: seedColor,
                                            size: 20.0,
                                          ),
                                          const Gap(4.0),
                                          Text(
                                            '+${controller.remainingPhotos}',
                                            style: AppTextStyles.body.copyWith(
                                              color: seedColor,
                                              fontWeight: FontWeight.w500,
                                              fontVariations: [
                                                FontVariation('wght', 500),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                )
                              : const SizedBox.shrink(),
                        ),
                      ],
                    ),
                    const Gap(28.0),

                    // Severity selector
                    _SeveritySelector(controller: controller),
                    const Gap(24.0),

                    // Title field
                    _TitleField(controller: controller),
                    const Gap(20),

                    // Category dropdown
                    _CategoryDropdown(controller: controller),
                    const Gap(20),

                    // Location search
                    _LocationSearch(controller: controller),
                    const Gap(20),

                    // Observation field
                    _ObservationField(controller: controller),
                    const Gap(32),

                    // Submit button
                    _SubmitButton(controller: controller, onSubmit: onSubmit),

                    // Bottom padding
                    SizedBox(height: MediaQuery.paddingOf(context).bottom + 24),
                  ],
                ),
              ),
            );
          },
        )
        .animate()
        .slideY(begin: 0.3, duration: 500.ms, curve: Curves.easeOutCubic)
        .fadeIn(duration: 400.ms);
  }
}

/// Severity selector with uni-color chips until selected
class _SeveritySelector extends StatelessWidget {
  const _SeveritySelector({required this.controller});

  final NewReportController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            text: 'Severity',
            children: [
              TextSpan(
                text: ' *',
                style: AppTextStyles.body.copyWith(color: errorColor),
              ),
            ],
          ),
          style: AppTextStyles.h4,
        ),
        const Gap(8.0),

        // Loading state
        Obx(() {
          if (controller.isLoadingData) {
            return Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(4, (index) {
                  return Expanded(
                    flex: index % 2 == 0
                        ? 1
                        : index % 3 == 0
                        ? 2
                        : 3,
                    child:
                        Container(
                              height: 36.0,
                              margin: const EdgeInsets.symmetric(
                                horizontal: 4.0,
                              ),
                              decoration: BoxDecoration(
                                color: seedPalette.shade100,
                                borderRadius: BorderRadius.circular(16),
                              ),
                            )
                            .animate(
                              onPlay: (controller) => controller.repeat(),
                            )
                            .shimmer(
                              duration: 1200.ms,
                              color: seedPalette.shade50,
                            ),
                  );
                }),
              ),
            );
          }

          final severities = controller.availableSeverities;
          if (severities.isEmpty) {
            return Container(
              width: mediaWidth(context),
              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
              decoration: BoxDecoration(
                color: seedPalette.shade50,
                borderRadius: borderRadius * 1.75,
              ),
              child: Text(
                'No severities available',
                style: AppTextStyles.body.copyWith(
                  color: Colors.grey.shade500,
                  fontStyle: FontStyle.italic,
                ),
              ),
            );
          }

          return Stack(
            alignment: Alignment.bottomRight,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8.0,
                    runSpacing: 8.0,
                    children: severities.map((severity) {
                      final isSelected =
                          controller.selectedSeverityLevel.value ==
                          severity.level;
                      return _SeverityChip(
                        level: severity.level,
                        label: severity.name,
                        color: controller.getSeverityColor(severity.level),
                        isSelected: isSelected,
                        onTap: () => controller.setSeverity(severity.level),
                      );
                    }).toList(),
                  ),

                  // Description of selected severity
                  Obx(() {
                    final description = controller.selectedSeverityDescription;

                    List<List<dynamic>> getDescriptionIcon(int level) {
                      switch (level) {
                        case 1:
                          return HugeIcons.strokeRoundedLowSignal;
                        case 2:
                          return HugeIcons.strokeRoundedMediumSignal;
                        case 3:
                          return HugeIcons.strokeRoundedFullSignal;
                        case 4:
                          return HugeIcons.strokeRoundedGarbageTruck;
                        default:
                          return HugeIcons.strokeRoundedMediumSignal;
                      }
                    }

                    if (description == null || description.isEmpty) {
                      return const SizedBox.shrink();
                    }
                    return Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: controller.selectedSeverityColor.withValues(
                            alpha: 0.1,
                          ),
                          borderRadius: borderRadius * 2.0,
                          border: Border.all(
                            color: controller.selectedSeverityColor.withValues(
                              alpha: 0.3,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            HugeIcon(
                              icon: getDescriptionIcon(
                                controller.selectedSeverityLevel.value,
                              ),
                              color: controller.selectedSeverityColor,
                              size: 20.0,
                            ),
                            const Gap(8),
                            Expanded(
                              child: Text(
                                description,
                                style: AppTextStyles.small.copyWith(
                                  color: controller.selectedSeverityColor,
                                  fontWeight: FontWeight.w500,
                                  fontVariations: [FontVariation('wght', 500)],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
              // Trash image based on severity
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, animation) {
                  return ScaleTransition(
                    scale: animation,
                    child: FadeTransition(opacity: animation, child: child),
                  );
                },
                child: Image.asset(
                  controller.severityTrashImage,
                  key: ValueKey(controller.selectedSeverityLevel.value),
                  width: 88.0,
                  height: 88.0,
                  fit: BoxFit.contain,
                ),
              ),
            ],
          );
        }),
      ],
    );
  }
}

/// Severity chip - uni-color when unselected, colored when selected
class _SeverityChip extends StatelessWidget {
  const _SeverityChip({
    required this.level,
    required this.label,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  final int level;
  final String label;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
        decoration: BoxDecoration(
          color: isSelected ? color : seedPalette.shade50,
          borderRadius: borderRadius * 2.0,
          border: Border.all(
            color: isSelected ? color : seedPalette.shade200,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: AppTextStyles.small.copyWith(
            color: isSelected ? lightColor : greyColor,
            fontWeight: FontWeight.w500,
            fontVariations: [FontVariation('wght', 500)],
          ),
        ),
      ),
    );
  }
}

/// Title field
class _TitleField extends StatelessWidget {
  const _TitleField({required this.controller});

  final NewReportController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            text: 'Title',
            children: [
              TextSpan(
                text: ' *',
                style: AppTextStyles.body.copyWith(color: errorColor),
              ),
            ],
          ),
          style: AppTextStyles.h4,
        ),
        const Gap(8.0),
        TextField(
          controller: controller.titleController,
          decoration: InputDecoration(
            hintText: 'e.g., Illegal dump near park entrance',
            hintStyle: AppTextStyles.body.copyWith(color: greyColor),
            filled: true,
            fillColor: seedPalette.shade50,
            border: OutlineInputBorder(
              borderRadius: borderRadius * 2.25,
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: borderRadius * 2.25,
              borderSide: BorderSide(color: seedPalette.shade100),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: borderRadius * 2.25,
              borderSide: BorderSide(color: seedColor, width: 2.0),
            ),
            contentPadding: const EdgeInsets.all(16.0),
          ),
          style: AppTextStyles.body,
          textCapitalization: TextCapitalization.sentences,
        ),
      ],
    );
  }
}

/// Category dropdown
class _CategoryDropdown extends StatelessWidget {
  const _CategoryDropdown({required this.controller});

  final NewReportController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Category', style: AppTextStyles.h4),
        const Gap(8.0),
        Obx(() {
          // Show loading state
          if (controller.isLoadingData) {
            return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: seedPalette.shade50,
                    borderRadius: borderRadius * 2.5,
                    border: Border.all(color: seedPalette.shade100),
                  ),
                  child: Text(
                    "Loading trash categories...",
                    style: AppTextStyles.body.copyWith(
                      color: greyColor.withValues(alpha: 0.5),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                )
                .animate(onPlay: (controller) => controller.repeat())
                .shimmer(duration: 1200.ms, color: seedPalette.shade50);
          }

          final categories = controller.availableCategories;
          final selected = controller.selectedCategory.value;

          // Show empty state if no categories
          if (categories.isEmpty) {
            return Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: warningColor.withValues(alpha: 0.1),
                borderRadius: borderRadius * 2.25,
                border: Border.all(color: warningColor.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  HugeIcon(
                    icon: HugeIcons.strokeRoundedAlert02,
                    color: warningColor,
                  ),
                  const Gap(12),
                  Text(
                    'No categories available',
                    style: AppTextStyles.body.copyWith(color: warningColor),
                  ),
                ],
              ),
            );
          }

          return Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            decoration: BoxDecoration(
              color: seedPalette.shade50,
              borderRadius: borderRadius * 2.25,
              border: Border.all(color: seedPalette.shade100),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<TrashCategoryModel>(
                value: selected,
                isExpanded: true,
                hint: Text(
                  'Select a category',
                  style: AppTextStyles.body.copyWith(color: greyColor),
                ),
                icon: HugeIcon(
                  icon: HugeIcons.strokeRoundedArrowDown01,
                  color: seedColor,
                  size: 20,
                ),
                dropdownColor: seedPalette.shade100,
                borderRadius: borderRadius * 3.0,
                items: categories.map((category) {
                  return DropdownMenuItem<TrashCategoryModel>(
                    value: category,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(category.name, style: AppTextStyles.body),
                        if (category.description != null &&
                            category.description!.isNotEmpty)
                          Text(
                            category.description!,
                            style: AppTextStyles.small.copyWith(
                              color: greyColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (category) {
                  if (category != null) {
                    controller.setCategory(category);
                  }
                },
              ),
            ),
          );
        }),
      ],
    );
  }
}

/// Location search with Mapbox
class _LocationSearch extends StatelessWidget {
  const _LocationSearch({required this.controller});

  final NewReportController controller;

  @override
  Widget build(BuildContext context) {
    return TapRegion(
      onTapOutside: (_) => controller.dismissLocationResults(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Street name', style: AppTextStyles.h4),
              const Spacer(),
              // Current location indicator
              Obx(() {
                final location = controller.currentLocation.value;
                if (location != null) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8.0,
                      vertical: 6.0,
                    ),
                    decoration: BoxDecoration(
                      color: successColor.withValues(alpha: 0.1),
                      borderRadius: borderRadius * 1.5,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        HugeIcon(
                          icon: HugeIcons.strokeRoundedGps01,
                          color: successColor,
                          size: 16.0,
                          strokeWidth: 1.8,
                        ),
                        const Gap(4.0),
                        Text(
                          'GPS OK',
                          style: AppTextStyles.small.copyWith(
                            color: successColor,
                            fontWeight: FontWeight.w500,
                            fontVariations: [FontVariation('wght', 500)],
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return const SizedBox.shrink();
              }),
            ],
          ),
          const Gap(8),

          // Search field
          TextField(
            controller: controller.locationSearchController,
            decoration: InputDecoration(
              hintText: 'Search for street name...',
              hintStyle: AppTextStyles.body.copyWith(color: greyColor),
              filled: true,
            fillColor: seedPalette.shade50,
            prefixIcon: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: HugeIcon(
                icon: HugeIcons.strokeRoundedSearch01,
                color: seedColor,
              ),
            ),
            suffixIcon: Obx(() {
              if (controller.isSearchingLocation.value) {
                return Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: LoadingAnimationWidget.staggeredDotsWave(
                    color: seedPalette.shade200,
                    size: 24.0,
                  ),
                );
              }
              if (controller.locationSearchQuery.value.isNotEmpty) {
                return IconButton(
                  tooltip: "Clear search",
                  onPressed: controller.clearLocationSearch,
                  icon: const HugeIcon(
                    icon: HugeIcons.strokeRoundedCancel01,
                    size: 20.0,
                  ),
                );
              }
              return const SizedBox.shrink();
            }),
            border: OutlineInputBorder(
              borderRadius: borderRadius * 2.25,
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: borderRadius * 2.25,
              borderSide: BorderSide(color: seedPalette.shade100),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: borderRadius * 2.25,
              borderSide: BorderSide(color: seedColor, width: 2),
            ),
            contentPadding: const EdgeInsets.all(16.0),
          ),
          style: AppTextStyles.body.copyWith(color: darkColor),
        ),

        // Search results
        Obx(() {
          final results = controller.locationSearchResults;
          final query = controller.locationSearchQuery.value;

          // Only show if we have results OR if query is long enough (for custom option)
          if (results.isEmpty && query.length < 3) return const SizedBox.shrink();

          return Container(
                margin: const EdgeInsets.only(top: 8),
                decoration: BoxDecoration(
                  color: lightColor,
                  borderRadius: borderRadius * 2.5,
                  border: Border.all(color: seedPalette.shade100),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10.0,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: results.length + 1, // +1 for custom option
                  separatorBuilder: (_, __) =>
                      Divider(height: 1, color: seedPalette.shade100),
                  itemBuilder: (context, index) {
                    // Last item is the "Use custom name" option
                    if (index == results.length) {
                      return ListTile(
                        dense: true,
                        leading: HugeIcon(
                          icon: HugeIcons.strokeRoundedEdit02,
                          color: greyColor,
                          size: 20,
                        ),
                        title: Text(
                          'Use "$query" as street name',
                          style: AppTextStyles.body.copyWith(
                            color: greyColor,
                            fontStyle: FontStyle.italic,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onTap: () => controller.useCustomStreetName(),
                      );
                    }

                    final place = results[index];
                    return ListTile(
                      dense: true,
                      leading: HugeIcon(
                        icon: HugeIcons.strokeRoundedLocation01,
                        color: seedColor,
                        size: 20,
                      ),
                      title: Text(
                        place.placeName,
                        style: AppTextStyles.body.copyWith(color: darkColor),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onTap: () => controller.selectLocation(place),
                    );
                  },
                ),
              )
              .animate()
              .fadeIn(duration: 200.ms)
              .slideY(begin: -0.1, duration: 200.ms);
        }),
        ],
      ),
    );
  }
}

/// Observation field
class _ObservationField extends StatelessWidget {
  const _ObservationField({required this.controller});

  final NewReportController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Observation', style: AppTextStyles.h4),
        const Gap(8),
        TextField(
          controller: controller.observationController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Describe what you see...',
            hintStyle: AppTextStyles.body.copyWith(color: greyColor),
            filled: true,
            fillColor: seedPalette.shade50,
            border: OutlineInputBorder(
              borderRadius: borderRadius * 2.25,
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: borderRadius * 2.25,
              borderSide: BorderSide(color: seedPalette.shade100),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: borderRadius * 2.25,
              borderSide: BorderSide(color: seedColor, width: 2.0),
            ),
            contentPadding: const EdgeInsets.all(16.0),
          ),
          style: AppTextStyles.body.copyWith(color: darkColor),
          textCapitalization: TextCapitalization.sentences,
          keyboardType: TextInputType.multiline,
        ),
      ],
    );
  }
}

/// Submit button
class _SubmitButton extends StatelessWidget {
  const _SubmitButton({required this.controller, required this.onSubmit});

  final NewReportController controller;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isLoading = controller.isSubmitting.value;
      final isValid = controller.isFormValid;

      return SizedBox(
        width: double.infinity,
        child: PrimaryButton.child(
          onPressed: isValid && !isLoading ? onSubmit : null,
          child: isLoading
              ? SizedBox(
                  width: 24.0,
                  height: 24.0,
                  child: LoadingAnimationWidget.staggeredDotsWave(
                    color: seedPalette.shade200,
                    size: 24.0,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Submit Report',
                      style: AppTextStyles.h4.copyWith(color: lightColor),
                    ),
                    const Gap(8),
                    HugeIcon(
                      icon: HugeIcons.strokeRoundedSent,
                      color: lightColor,
                    ),
                  ],
                ),
        ),
      );
    });
  }
}

/// Full screen image viewer with zoom
class _FullScreenImageViewer extends StatelessWidget {
  const _FullScreenImageViewer({required this.controller});

  final NewReportController controller;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: controller.closeFullScreenImage,
      child: Container(
        color: Colors.black.withValues(alpha: 0.95),
        child: SafeArea(
          child: Stack(
            children: [
              // Image with zoom
              Center(
                child: Obx(() {
                  final index = controller.currentImageIndex.value;
                  if (index >= controller.capturedImages.length) {
                    return const SizedBox.shrink();
                  }

                  return Hero(
                    tag: 'report_image_$index',
                    child: InteractiveViewer(
                      minScale: 0.5,
                      maxScale: 4.0,
                      child: Image.file(
                        controller.capturedImages[index],
                        fit: BoxFit.contain,
                      ),
                    ),
                  );
                }),
              ),

              // Close button
              Positioned(
                top: 16.0,
                right: 16.0,
                child: _ControlButton(
                  icon: HugeIcons.strokeRoundedCancel01,
                  onPressed: controller.closeFullScreenImage,
                ),
              ),

              // Delete button
              Positioned(
                bottom: 32.0,
                left: 0.0,
                right: 0.0,
                child: Center(
                  child: GestureDetector(
                    onTap: () {
                      controller.removeImage(
                        controller.currentImageIndex.value,
                      );
                      if (controller.capturedImages.isEmpty) {
                        controller.goToCameraPhase();
                      } else {
                        controller.closeFullScreenImage();
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24.0,
                        vertical: 12.0,
                      ),
                      decoration: BoxDecoration(
                        color: errorColor,
                        borderRadius: borderRadius * 3,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.delete, color: lightColor, size: 20),
                          const Gap(8),
                          Text(
                            'Delete Photo',
                            style: AppTextStyles.body.copyWith(
                              color: lightColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Image counter
              Obx(
                () => Positioned(
                  bottom: 32.0,
                  right: 16.0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12.0,
                      vertical: 6.0,
                    ),
                    decoration: BoxDecoration(
                      color: darkColor.withValues(alpha: 0.7),
                      borderRadius: borderRadius,
                    ),
                    child: Text(
                      '${controller.currentImageIndex.value + 1}/${controller.capturedImages.length}',
                      style: AppTextStyles.small.copyWith(color: lightColor),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 300.ms);
  }
}
