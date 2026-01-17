import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:trashtrails/utils/utils.dart';

import '../../../controllers/points_controller.dart';
import '../../../utils/constants.dart';
import '../../components/widgets/buttons/primary_button.dart';
import '../../components/widgets/buttons/tertiary_button.dart';
import '../home.dart';
import 'new_report.dart';

/// Page displaying the points earned from a report submission
/// Shows animated point counter, breakdown, and verification status
class ReportPointsPage extends StatefulWidget {
  const ReportPointsPage({super.key});

  static const String routeName = '/report-points';

  @override
  State<ReportPointsPage> createState() => _ReportPointsPageState();
}

class _ReportPointsPageState extends State<ReportPointsPage>
    with TickerProviderStateMixin {
  final PointsController _pointsController = Get.find<PointsController>();

  late AnimationController _countAnimationController;
  late AnimationController _entranceAnimationController;

  @override
  void initState() {
    super.initState();

    // Animation for the points counter (count up effect)
    _countAnimationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    // Animation for entrance effects
    _entranceAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // Start animations after frame is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startAnimations();
    });
  }

  void _startAnimations() {
    _entranceAnimationController.forward();

    // Delay the count animation slightly for better effect
    Future.delayed(const Duration(milliseconds: 400), () {
      // Ensure listener is added before starting the animation
      _countAnimationController.addListener(_updateProgress);
      _countAnimationController.forward();
    });
  }

  void _updateProgress() {
    _pointsController.setAnimationProgress(_countAnimationController.value);
  }

  @override
  void dispose() {
    _countAnimationController.removeListener(_updateProgress);
    _countAnimationController.dispose();
    _entranceAnimationController.dispose();
    super.dispose();
  }

  void _navigateToHome() {
    _pointsController.clearPoints();
    context.go(HomePage.routeName);
  }

  void _navigateToNewReport() {
    _pointsController.clearPoints();
    context.pushReplacement(NewReportPage.routeName);
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: seedPalette.shade50,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              // Header
              _buildHeader(),

              // Main content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      const Gap(32.0),

                      // Success icon
                      _buildSuccessIcon(),

                      const Gap(24.0),

                      // Points counter
                      _buildPointsCounter(),

                      const Gap(16.0),

                      // Rank badge
                      _buildRankBadge(),

                      const Gap(24.0),

                      // Verification notice
                      _buildVerificationNotice(),

                      const Gap(24.0),

                      // Points breakdown
                      _buildPointsBreakdown(),

                      const Gap(32.0),

                      // CTA Buttons
                      _buildCTAButtons(),

                      const Gap(24.0),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        children: [
          // Logo
          SvgPicture.asset(cyanLogo, height: 32),
          const Spacer(),
          // Close button
          IconButton(
            onPressed: _navigateToHome,
            icon: HugeIcon(
              icon: HugeIcons.strokeRoundedCancel01,
              color: seedColor,
              size: 24,
            ),
          ),
        ],
      )
          .animate(controller: _entranceAnimationController)
          .fadeIn(duration: 400.ms)
          .slideY(begin: -0.2, end: 0),
    );
  }

  Widget _buildSuccessIcon() {
    return Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: successColor.withValues(alpha: 0.1),
                blurRadius: 60.0,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Center(
            child: Stack(
              alignment: Alignment.bottomCenter,
              clipBehavior: Clip.none,
              children: [
                Image.asset(recycleImg, width: 220.0),
                Positioned(
                  right: -50,
                  child: Image.asset(recycle, width: 200.0),
                ),
                Positioned(
                  left: 20,
                  child: Transform.flip(
                    flipX: true,
                    child: Image.asset(recyclePaper, width: 120.0),
                  ),
                ),
              ],
            ),
          ),
        )
        .animate(controller: _entranceAnimationController)
        .scale(begin: const Offset(0.5, 0.5), end: const Offset(1, 1))
        .fadeIn(duration: 500.ms, delay: 200.ms);
  }

  Widget _buildPointsCounter() {
    return Column(
          children: [
            Text(
              'Points Earned',
              style: AppTextStyles.small.copyWith(
                color: seedColor,
                fontWeight: FontWeight.w500,
                fontVariations: [FontVariation('wght', 500)],
              ),
            ),
            const Gap(8),
            Obx(() {
              final animatedPoints = _pointsController.animatedPoints;
              return Text(
                '+$animatedPoints',
                style: AppTextStyles.title.copyWith(
                  fontSize: 72.0,
                  fontWeight: FontWeight.w200,
                  fontVariations: [FontVariation('wght', 300)],
                  color: successColor,
                  height: 1,
                ),
              );
            }),
          ],
        )
        .animate(controller: _entranceAnimationController)
        .fadeIn(duration: 400.ms, delay: 300.ms)
        .slideY(begin: 0.2, end: 0);
  }

  Widget _buildRankBadge() {
    return Obx(() {
          final rank = _pointsController.userRank.value;
          final totalPoints = _pointsController.totalUserPoints.value;

          return Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 10.0,
            ),
            decoration: BoxDecoration(
              color: seedPalette.shade100,
              borderRadius: borderRadius * 2.25,
              border: Border.all(color: seedColor.withValues(alpha: 0.2)),
            ),
            child: IntrinsicHeight(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  HugeIcon(
                    icon: HugeIcons.strokeRoundedRanking,
                    color: seedColor,
                    size: 20.0,
                  ),
                  const Gap(8),
                  Text(
                    'Rank #$rank',
                    style: AppTextStyles.body.copyWith(
                      color: seedColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: VerticalDivider(
                      color: seedColor.withValues(alpha: 0.3),
                    ),
                  ),
                  Text(
                    '${addThousandSeparator(totalPoints.toString())} pts total',
                    style: AppTextStyles.body.copyWith(
                      color: seedColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        })
        .animate(controller: _entranceAnimationController)
        .fadeIn(duration: 400.ms, delay: 400.ms)
        .scale(begin: const Offset(0.9, 0.9), end: const Offset(1, 1));
  }

  Widget _buildVerificationNotice() {
    return Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: infoColor.withValues(alpha: 0.1),
            borderRadius: borderRadius * 3.0,
            border: Border.all(color: infoColor.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: infoColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: HugeIcon(
                  icon: HugeIcons.strokeRoundedClock01,
                  color: infoColor,
                  size: 20,
                ),
              ),
              const Gap(12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Under Verification',
                      style: AppTextStyles.body.copyWith(
                        color: infoColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Your report is being reviewed. This usually takes 48-72 hours.',
                      style: AppTextStyles.small.copyWith(
                        color: Colors.grey.shade800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        )
        .animate(controller: _entranceAnimationController)
        .fadeIn(duration: 400.ms, delay: 500.ms)
        .slideX(begin: -0.1, end: 0);
  }

  Widget _buildPointsBreakdown() {
    return Obx(() {
          final breakdown = _pointsController.breakdown;
          final showDetails = _pointsController.showDetails.value;

          if (breakdown == null) {
            return const SizedBox.shrink();
          }

          return Column(
            children: [
              // Toggle button
              InkWell(
                onTap: _pointsController.toggleDetails,
                borderRadius: borderRadius * 2.5,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        showDetails ? 'Hide Details' : 'Show Details',
                        style: AppTextStyles.body.copyWith(
                          color: seedColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Gap(4.0),
                      AnimatedRotation(
                        turns: showDetails ? 0.5 : 0,
                        duration: const Duration(milliseconds: 200),
                        child: HugeIcon(
                          icon: HugeIcons.strokeRoundedArrowDown01,
                          color: seedColor,
                          size: 20.0,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const Gap(12.0),

              // Breakdown list
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: borderRadius * 3.0,
                  boxShadow: [
                    BoxShadow(
                      color: seedColor.withValues(alpha: 0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: breakdown.entries.asMap().entries.map((entry) {
                    final index = entry.key;
                    final item = entry.value;
                    final isLast = index == breakdown.entries.length - 1;

                    return _BreakdownRow(
                      label: item.key,
                      points: item.value.points,
                      reason: item.value.reason,
                      showReason: showDetails,
                      showDivider: !isLast,
                      index: index,
                    );
                  }).toList(),
                ),
              ),
            ],
          );
        })
        .animate(controller: _entranceAnimationController)
        .fadeIn(duration: 400.ms, delay: 600.ms)
        .slideY(begin: 0.1, end: 0);
  }

  Widget _buildCTAButtons() {
    return Column(
          children: [
            // New contribution button
            SizedBox(
              width: double.infinity,
              child: PrimaryButton.icon(
                onPressed: _navigateToNewReport,
                bgColor: seedColor,
                icon: HugeIcon(
                  icon: HugeIcons.strokeRoundedAddInvoice,
                  color: lightColor,
                  size: 20.0,
                ),
                label: Text(
                  'Submit a new report',
                  style: AppTextStyles.body.copyWith(
                    color: lightColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

            const Gap(12.0),

            // Back to map button
            SizedBox(
              width: double.infinity,
              child: TertiaryButton.icon(
                onPressed: _navigateToHome,
                icon: HugeIcon(
                  icon: HugeIcons.strokeRoundedMapsLocation02,
                  color: seedColor,
                ),
                label: Text(
                  'Back to trash Map',
                  style: AppTextStyles.body.copyWith(
                    color: seedColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        )
        .animate(controller: _entranceAnimationController)
        .fadeIn(duration: 400.ms, delay: 700.ms)
        .slideY(begin: 0.2, end: 0);
  }
}

/// Individual row in the points breakdown
class _BreakdownRow extends StatelessWidget {
  final String label;
  final int points;
  final String reason;
  final bool showReason;
  final bool showDivider;
  final int index;

  const _BreakdownRow({
    required this.label,
    required this.points,
    required this.reason,
    required this.showReason,
    required this.showDivider,
    required this.index,
  });

  List<List<dynamic>> _getIconForLabel(String label) {
    switch (label.toLowerCase()) {
      case 'title':
        return HugeIcons.strokeRoundedTextFont;
      case 'severity':
        return HugeIcons.strokeRoundedAlert02;
      case 'category':
        return HugeIcons.strokeRoundedTag01;
      case 'observation':
        return HugeIcons.strokeRoundedNote;
      case 'location':
        return HugeIcons.strokeRoundedLocation06;
      case 'images':
        return HugeIcons.strokeRoundedAlbum02;
      default:
        return HugeIcons.strokeRoundedCheckmarkCircle02;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 4.0,
              ),
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    color: seedPalette.shade100,
                    borderRadius: borderRadius * 1.25,
                  ),
                  child: HugeIcon(
                    icon: _getIconForLabel(label),
                    color: seedColor,
                    size: 18,
                  ),
                ),
                title: Text(
                  label,
                  style: AppTextStyles.body.copyWith(
                    color: seedColor,
                    fontWeight: FontWeight.w500,
                    fontVariations: [FontVariation('wght', 500)],
                  ),
                ),
                subtitle: showReason
                    ? Text(
                        reason,
                        style: AppTextStyles.small.copyWith(
                          fontStyle: FontStyle.italic,
                        ),
                      )
                    : null,
                trailing: Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Text(
                    '+$points',
                    style: AppTextStyles.body.copyWith(color: successColor),
                  ),
                ),
              ),
            ),
            if (showDivider)
              Divider(
                height: 1.0,
                color: seedPalette.shade100,
                indent: 16.0,
                endIndent: 16.0,
              ),
          ],
        )
        .animate()
        .fadeIn(duration: 300.ms, delay: (100 * index).ms)
        .slideX(begin: 0.05, end: 0);
  }
}
