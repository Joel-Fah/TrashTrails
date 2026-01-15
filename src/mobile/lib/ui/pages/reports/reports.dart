import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:trashtrails/controllers/controllers.dart';
import 'package:trashtrails/ui/components/metadata_chip.dart';
import 'package:trashtrails/ui/components/user_avatar.dart';
import 'package:trashtrails/utils/constants.dart';
import 'package:trashtrails/utils/utils.dart';

import '../../components/read_more_text.dart';

class ReportsFeedPage extends StatefulWidget {
  const ReportsFeedPage({super.key});

  static const String routeName = '/reports';

  @override
  State<ReportsFeedPage> createState() => _ReportsFeedPageState();
}

class _ReportsFeedPageState extends State<ReportsFeedPage> {
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
    _pageControllers = List.generate(
      reportController.nearbyReports.length,
      (_) => PageController(),
    );
    _currentImageIndex = List.generate(
      reportController.nearbyReports.length,
      (_) => 0,
    );

    _scrollController.addListener(() {
      if (_scrollController.position.pixels ==
          _scrollController.position.maxScrollExtent) {
        _loadMore();
      }
    });
  }

  Future<void> _loadMore() async {
    await reportController.loadMoreReports().then((value) {
      setState(() {
        // Only add controllers for new items
        int oldLength = _pageControllers.length;
        int newLength = reportController.nearbyReports.length;
        if (newLength > oldLength) {
          _pageControllers.addAll(
            List.generate(newLength - oldLength, (_) => PageController()),
          );
          _currentImageIndex.addAll(
            List.generate(newLength - oldLength, (_) => 0),
          );
        }
      });
    });
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
      appBar: AppBar(
        title: SvgPicture.asset(cyanLogo, width: 100.0),
        centerTitle: true,
      ),
      body: Obx(() {
        // Loading state
        if (reportController.isLoadingReports.value &&
            reportController.nearbyReports.isEmpty) {
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
                  "Reports on the way, hang tight!",
                  style: AppTextStyles.body.copyWith(color: greyColor),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => reportController.refreshReports(),
          child:
              ListView.separated(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.symmetric(vertical: 16.0).copyWith(
                      bottom: MediaQuery.paddingOf(context).bottom + 16.0,
                    ),
                    itemCount: reportController.nearbyReports.length,
                    separatorBuilder: (context, index) => Gap(24.0),
                    itemBuilder: (context, index) {
                      // Show loading indicator
                      if (index >= _pageControllers.length) {
                        return SizedBox(
                          height: 50.0,
                          child: LoadingAnimationWidget.staggeredDotsWave(
                            color: seedPalette.shade300,
                            size: 32.0,
                          ),
                        );
                      }

                      final report = reportController.nearbyReports[index];

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
                                        imageUrl: authController
                                            .currentUser
                                            ?.avatarUrl,
                                        name: authController
                                            .currentUser
                                            ?.displayName,
                                      ),
                                      Text(
                                        authController.currentUser!.displayName,
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
                                      label: formatCount(Random().nextInt(999999)),
                                      onPressed: () {},
                                    ),
                                    FeedReportAction(
                                      tooltip: 'Share',
                                      icon: HugeIcons.strokeRoundedShare08,
                                      label: formatCount(Random().nextInt(10000)),
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
