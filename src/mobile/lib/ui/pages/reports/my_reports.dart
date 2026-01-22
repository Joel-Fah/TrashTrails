import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:trashtrails/controllers/controllers.dart';
import 'package:trashtrails/ui/components/metadata_chip.dart';
import 'package:trashtrails/ui/components/states/error.dart';
import 'package:trashtrails/ui/components/user_avatar.dart';
import 'package:trashtrails/utils/constants.dart';
import 'package:trashtrails/utils/utils.dart';

import '../../components/read_more_text.dart';

class MyReportsFeedPage extends StatefulWidget {
  const MyReportsFeedPage({super.key});

  static const String routeName = '/my-reports';

  @override
  State<MyReportsFeedPage> createState() => _MyReportsFeedPageState();
}

class _MyReportsFeedPageState extends State<MyReportsFeedPage> {
  // GetX Controllers
  final ReportController reportController = Get.find<ReportController>();
  final AuthController authController = Get.find<AuthController>();
  final NewReportController newReportController =
      Get.find<NewReportController>();
  final HomeController homeController = Get.find<HomeController>();

  // Controllers
  final ScrollController _scrollController = ScrollController();
  late List<PageController> _pageControllers;

  // Variables
  late List<int> _currentImageIndex;

  @override
  void initState() {
    super.initState();
    _pageControllers = [];
    _currentImageIndex = [];
    _loadReports();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels ==
          _scrollController.position.maxScrollExtent) {
        _loadMore();
      }
    });
  }

  Future<void> _loadReports() async {
    await reportController.loadMyReports();
    _syncControllers();
  }

  void _syncControllers() {
    final len = reportController.userReports.length;
    // Ajuste la taille des listes
    if (_pageControllers.length < len) {
      _pageControllers.addAll(
        List.generate(len - _pageControllers.length, (_) => PageController()),
      );
      _currentImageIndex.addAll(
        List.generate(len - _currentImageIndex.length, (_) => 0),
      );
    } else if (_pageControllers.length > len) {
      _pageControllers = _pageControllers.sublist(0, len);
      _currentImageIndex = _currentImageIndex.sublist(0, len);
    }
    setState(() {});
  }

  Future<void> _loadMore() async {
    await reportController.loadMoreMyReports();
    _syncControllers();
  }


  @override
  void dispose() {
    _scrollController.dispose();
    for (var controller in _pageControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("My Reports")),
      body: Obx(() {
        WidgetsBinding.instance.addPostFrameCallback((_) => _syncControllers());

        // Loading state
        if (reportController.isLoadingMyReports.value &&
            reportController.userReports.isEmpty) {
          return Center(
            child: Column(
              spacing: 16.0,
              mainAxisSize: MainAxisSize.min,
              children: [
                LoadingAnimationWidget.staggeredDotsWave(
                  color: seedPalette.shade300,
                  size: 56.0,
                ),
                Text(
                  "Your reports are on the way, hang tight!",
                  style: AppTextStyles.body.copyWith(color: greyColor),
                ),
              ],
            ),
          );
        }

        // Empty State
        if (!reportController.hasUserReports) {
          return ErrorState(
            title: "No Reports Yet!",
            subtitle:
                "No worries, you'll definitely find some trash dump around one day. Then, report it here on TrashTrails",
            onPressed: () => reportController.refreshMyReports(),
            ctaLabel: "Refresh Though",
          );
        }

        return RefreshIndicator(
          onRefresh: () => reportController.refreshMyReports(),
          child:
              ListView.separated(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.symmetric(vertical: 16.0).copyWith(
                      bottom: MediaQuery.paddingOf(context).bottom + 16.0,
                    ),
                    itemCount: reportController.userReports.length,
                    separatorBuilder: (context, index) => Gap(24.0),
                    itemBuilder: (context, index) {
                      // Show loading indicator
                      if (index >= _pageControllers.length) {
                        return Center(
                          child: Column(
                            children: [
                              SizedBox(
                                height: 50.0,
                                child: LoadingAnimationWidget.staggeredDotsWave(
                                  color: seedPalette.shade300,
                                  size: 32.0,
                                ),
                              ),
                              Text(
                                "Loading more reports ...",
                                style: AppTextStyles.body.copyWith(
                                  fontSize: 14.0,
                                  fontStyle: FontStyle.italic,
                                  color: greyColor
                                ),
                              )
                            ],
                          ),
                        );
                      }

                      if (index >= reportController.userReports.length ||
                          index >= _pageControllers.length ||
                          index >= _currentImageIndex.length) {
                        return const SizedBox.shrink();
                      }


                      final report = reportController.userReports[index];

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Row(
                                    spacing: 4.0,
                                    children: [
                                      UserAvatar(
                                        radius: 12.0,
                                        imageUrl: report.authorAvatarUrl,
                                        name: report.authorDisplayName,
                                        initials: report.authorInitials,
                                      ),
                                      Text(
                                        report.authorDisplayName!,
                                        style: AppTextStyles.small.copyWith(
                                          fontWeight: FontWeight.w500,
                                          fontVariations: [
                                            FontVariation('wght', 500),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  formatRelativeDateTime(report.createdAt),
                                  style: AppTextStyles.small.copyWith(
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Gap(8.0),
                          ConstrainedBox(
                            constraints: BoxConstraints(
                              minHeight: 300.0,
                              maxHeight: 500.0,
                            ),
                            child: Stack(
                              children: [
                                PageView.builder(
                                  controller: _pageControllers[index],
                                  itemCount: report.images.length,
                                  padEnds: false,
                                  physics: const BouncingScrollPhysics(),
                                  scrollDirection: Axis.horizontal,
                                  onPageChanged: (imgIndex) {
                                    setState(() {
                                      _currentImageIndex[index] = imgIndex;
                                    });
                                  },
                                  itemBuilder: (context, imgIndex) {
                                    final reportImage = report.images[imgIndex];
                                    return CachedNetworkImage(
                                      imageUrl: reportImage.image,
                                      fit: BoxFit.cover,
                                      placeholder: (context, url) => Container(
                                        color: Colors.grey[300],
                                        child: Center(
                                          child:
                                              LoadingAnimationWidget.staggeredDotsWave(
                                                color: seedPalette.shade300,
                                                size: 32.0,
                                              ),
                                        ),
                                      ),
                                      errorWidget: (context, url, error) =>
                                          Container(
                                            color: seedPalette.shade50,
                                            child: Center(
                                              child: HugeIcon(
                                                icon: HugeIcons
                                                    .strokeRoundedImageDelete02,
                                                size: 64,
                                                color: seedPalette.shade200,
                                              ),
                                            ),
                                          ),
                                      imageBuilder: (context, imageProvider) {
                                        return Container(
                                          width: double.infinity,
                                          decoration: BoxDecoration(
                                            image: DecorationImage(
                                              image: imageProvider,
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                        );
                                      },
                                    );
                                  },
                                ),

                                // Image counter indicator
                                if (report.images.length > 1)
                                  Positioned(
                                    top: 12.0,
                                    right: 12.0,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10.0,
                                        vertical: 6.0,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withValues(
                                          alpha: 0.8,
                                        ),
                                        borderRadius: borderRadius * 1.5,
                                      ),
                                      child: IntrinsicHeight(
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              '${_currentImageIndex[index] + 1}',
                                              style: AppTextStyles.small
                                                  .copyWith(
                                                    color: lightColor,
                                                    fontWeight: FontWeight.w500,
                                                    fontVariations: [
                                                      FontVariation(
                                                        'wght',
                                                        500,
                                                      ),
                                                    ],
                                                  ),
                                            ),
                                            VerticalDivider(
                                              color: lightColor,
                                              indent: 1.0,
                                              endIndent: 1.0,
                                              width: 10.0,
                                            ),
                                            Text(
                                              report.images.length.toString(),
                                              style: AppTextStyles.small
                                                  .copyWith(
                                                    color: lightColor,
                                                    fontWeight: FontWeight.w500,
                                                    fontVariations: [
                                                      FontVariation(
                                                        'wght',
                                                        500,
                                                      ),
                                                    ],
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ).animate().fadeIn(duration: 200.ms),
                                  ),
                              ],
                            ),
                          ),
                          const Gap(8.0),
                          // Page indicators (dots)
                          if (report.images.length > 1)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(
                                report.images.length,
                                (dotIndex) => AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 2,
                                  ),
                                  width: dotIndex == _currentImageIndex[index]
                                      ? 16.0
                                      : 8.0,
                                  height: 8.0,
                                  decoration: BoxDecoration(
                                    borderRadius: borderRadius,
                                    color: dotIndex == _currentImageIndex[index]
                                        ? seedColor
                                        : seedPalette.shade100,
                                  ),
                                ),
                              ),
                            ),

                          // Actions
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                            ).copyWith(left: 8.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  spacing: 4.0,
                                  children: [
                                    FeedReportAction(
                                      tooltip: 'Endorse',
                                      icon: HugeIcons.strokeRoundedWavingHand02,
                                      label: formatCount(5775),
                                      onPressed: () {},
                                    ),
                                    FeedReportAction(
                                      tooltip: 'Share',
                                      icon: HugeIcons.strokeRoundedShare08,
                                      label: formatCount(1389),
                                      onPressed: () {},
                                    ),
                                    FeedReportAction(
                                      tooltip: 'Directions',
                                      icon:
                                          HugeIcons.strokeRoundedMapsLocation02,
                                      label:
                                          homeController.getDistanceToReport(
                                            report,
                                          ) ??
                                          '',
                                      onPressed: () {},
                                    ),
                                  ],
                                ),
                                Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 8.0,
                                        vertical: 4.0,
                                      ).copyWith(left: 36.0),
                                      decoration: BoxDecoration(
                                        color: newReportController
                                            .getSeverityColor(
                                              report.severityLevel,
                                            )
                                            .withValues(alpha: 0.1),
                                        borderRadius: borderRadius * 1.25,
                                      ),
                                      child: Text(
                                        report.severityDisplayName,
                                        style: AppTextStyles.small.copyWith(
                                          color: newReportController
                                              .getSeverityColor(
                                                report.severityLevel,
                                              ),
                                          fontSize: 14.0,
                                          fontWeight: FontWeight.w500,
                                          fontVariations: [
                                            FontVariation('wght', 500),
                                          ],
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      bottom: 4.0,
                                      left: 2.0,
                                      child: Image.asset(
                                        newReportController.getSeverityImage(
                                          report.severityLevel,
                                        ),
                                        width: 32,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            padding: EdgeInsetsGeometry.symmetric(
                              horizontal: 16.0,
                            ),
                            child: Row(
                              spacing: 4.0,
                              children: [
                                MetadataChip(
                                  icon: HugeIcons.strokeRoundedTag01,
                                  label: report.categoryDisplayName,
                                ),
                                if (report.location?.streetName != null &&
                                    report.location!.streetName!.isNotEmpty)
                                  MetadataChip(
                                    icon: HugeIcons.strokeRoundedLocation06,
                                    label: report.location!.streetName!,
                                  ),
                                MetadataChip(
                                  icon: HugeIcons.strokeRoundedCalendar03,
                                  label: dateFormatter(report.createdAt),
                                ),
                              ],
                            ),
                          ),

                          // Observation
                          if (report.observation != null &&
                              report.observation!.isNotEmpty) ...[
                            const Gap(8.0),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16.0,
                              ),
                              child: ReadMoreText(
                                stripHtmlTags(report.observation!),
                              ),
                            ),
                          ],
                        ],
                      );
                    },
                  )
                  .animate()
                  .fadeIn(delay: 300.ms, duration: 500.ms)
                  .slideY(begin: 0.1, duration: 800.ms),
        );
      }),
    );
  }
}

class FeedReportAction extends StatelessWidget {
  const FeedReportAction({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    required this.tooltip,
  });

  final List<List<dynamic>> icon;
  final String label, tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          tooltip: tooltip,
          onPressed: onPressed,
          icon: HugeIcon(icon: icon, strokeWidth: 1.8),
        ),
        Text(
          label,
          style: AppTextStyles.small.copyWith(
            fontSize: 14.0,
            fontWeight: FontWeight.w500,
            fontVariations: [FontVariation('wght', 500)],
          ),
        ),
      ],
    );
  }
}
