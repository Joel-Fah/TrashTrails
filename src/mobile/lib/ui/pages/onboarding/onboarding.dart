import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:trashtrails/ui/pages/home.dart';
import 'package:trashtrails/utils/utils.dart';

import '../../../controllers/onboarding_controller.dart';
import '../../../utils/constants.dart';
import '../../components/widgets/buttons/primary_button.dart';

class OnboardingPage extends StatelessWidget {
  const OnboardingPage({super.key});

  static const String routeName = '/onboarding';

  @override
  Widget build(BuildContext context) {
    final OnboardingController onboardingController =
        Get.find<OnboardingController>();

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        body: Stack(
          children: [
            // Background PageView with images
            _BackgroundPageView(controller: onboardingController),

            // Gradient overlay
            const _GradientOverlay(),

            // Bottom content card with fixed position
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _BottomContent(controller: onboardingController),
            ),
          ],
        ),
      ),
    );
  }
}

/// Background image with fade transition and invisible PageView for gestures
class _BackgroundPageView extends StatelessWidget {
  final OnboardingController controller;

  const _BackgroundPageView({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Animated background image with fade transition
        Positioned.fill(
          child: Obx(() {
            final currentPage = controller.currentPage;
            return AnimatedSwitcher(
              duration: const Duration(milliseconds: 600),
              switchInCurve: Curves.easeIn,
              switchOutCurve: Curves.easeOut,
              transitionBuilder: (child, animation) {
                return FadeTransition(opacity: animation, child: child);
              },
              child: Image.asset(
                currentPage.backgroundImage,
                key: ValueKey(currentPage.backgroundImage),
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
              ),
            );
          }),
        ),

        // Invisible PageView for swipe gesture detection
        Positioned.fill(
          child: PageView.builder(
            controller: controller.pageController,
            onPageChanged: controller.onPageChanged,
            itemCount: controller.totalPages,
            itemBuilder: (context, index) {
              return const SizedBox.expand();
            },
          ),
        ),
      ],
    );
  }
}

/// Gradient overlay from top to bottom
class _GradientOverlay extends StatelessWidget {
  const _GradientOverlay();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              seedColor.withValues(alpha: 0.3),
              seedPalette.shade700,
            ],
            stops: const [0.0, 0.5, 0.8],
          ),
        ),
      ),
    );
  }
}

/// Bottom content including progress indicator, card, and CTA button
class _BottomContent extends StatelessWidget {
  final OnboardingController controller;

  const _BottomContent({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Progress indicator
            _ProgressIndicator(controller: controller),
            const Gap(8.0),

            // Content Card
            _ContentCard(controller: controller),
            const Gap(16.0),

            // CTA Button
            _CTAButton(controller: controller),
            Gap(MediaQuery.of(context).padding.bottom + 32),
          ],
        )
        .animate()
        .fadeIn(duration: 600.ms, delay: 200.ms)
        .slideY(begin: 0.2, end: 0, duration: 500.ms, curve: Curves.easeOut);
  }
}

/// Progress indicator showing current page
class _ProgressIndicator extends StatelessWidget {
  final OnboardingController controller;

  const _ProgressIndicator({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return Padding(
        padding: const EdgeInsets.only(left: 36.0),
        child: Align(
          alignment: Alignment.centerLeft,
          child: IntrinsicWidth(
            child: Container(
              padding: EdgeInsets.all(3.0),
              decoration: BoxDecoration(
                color: lightColor,
                borderRadius: borderRadius * 0.9,
              ),
              child: Row(
                children: List.generate(
                  controller.totalPages,
                  (index) => AnimatedContainer(
                    duration: duration,
                    curve: Curves.easeInOut,
                    margin: const EdgeInsets.symmetric(horizontal: 1.0),
                    width: controller.currentIndex == index ? 32.0 : 12.0,
                    height: 12.0,
                    decoration: BoxDecoration(
                      color: controller.currentIndex == index
                          ? seedColor
                          : seedPalette.shade200,
                      borderRadius: borderRadius * 0.6,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    });
  }
}

/// Content card with logo, title, description, and foreground image
class _ContentCard extends StatelessWidget {
  final OnboardingController controller;

  const _ContentCard({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Main card
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Container(
            padding: const EdgeInsets.all(24.0),
            decoration: BoxDecoration(
              color: lightColor,
              borderRadius: borderRadius * 3,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.0),
                  blurRadius: 18.0,
                  offset: const Offset(0, 63),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 16.0,
                  offset: const Offset(0, 40),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 14.0,
                  offset: const Offset(0, 23),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.17),
                  blurRadius: 10.0,
                  offset: const Offset(0, 10),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.20),
                  blurRadius: 6.0,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Logo
                SvgPicture.asset(cyanLogo, width: 24.0, height: 24.0)
                    .animate()
                    .fadeIn(duration: 400.ms)
                    .scale(begin: const Offset(0.8, 0.8), duration: 400.ms),
                const Gap(24.0),

                // Animated content (title & description)
                _AnimatedCardContent(controller: controller),
              ],
            ),
          ),
        ),

        // Foreground image positioned at top right, slightly outside card
        Positioned(
          top: -50,
          right: 20,
          child: _AnimatedForegroundImage(controller: controller),
        ),
      ],
    );
  }
}

/// Animated card content (title and description) that fades in/out
class _AnimatedCardContent extends StatelessWidget {
  final OnboardingController controller;

  const _AnimatedCardContent({required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller.animationController,
      builder: (context, child) {
        return Opacity(
          opacity: controller.animationController.value,
          child: Transform.translate(
            offset: Offset(0, 10 * (1 - controller.animationController.value)),
            child: Obx(() {
              final page = controller.currentPage;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    page.title,
                    style: AppTextStyles.h1.copyWith(color: seedColor),
                  ),
                  const Gap(8),

                  // Description
                  Text(
                    page.description,
                    style: AppTextStyles.body.copyWith(color: seedColor),
                  ),
                ],
              );
            }),
          ),
        );
      },
    );
  }
}

/// Animated foreground image that fades in/out with page changes
class _AnimatedForegroundImage extends StatelessWidget {
  final OnboardingController controller;

  const _AnimatedForegroundImage({required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller.animationController,
      builder: (context, child) {
        return Opacity(
          opacity: controller.animationController.value,
          child: Transform.scale(
            scale: 0.8 + (controller.animationController.value * 0.2),
            child: Obx(() {
              return Image.asset(
                controller.currentPage.foregroundImage,
                width: 120.0,
                height: 120.0,
                fit: BoxFit.contain,
              );
            }),
          ),
        );
      },
    );
  }
}

/// CTA Button that changes based on current page
class _CTAButton extends StatelessWidget {
  final OnboardingController controller;

  const _CTAButton({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isLastPage = controller.isLastPage;
      final isFirstPage = controller.currentIndex == 0;

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            // Back button (except on first page)
            if (!isFirstPage)
              IconButton.outlined(
                    tooltip: "Previous",
                    onPressed: controller.previousPage,
                    style: IconButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: borderRadius * 2.5,
                      ),
                      side: BorderSide(
                        color: lightColor.withValues(alpha: 0.5),
                      ),
                      padding: EdgeInsets.all(15.0),
                    ),
                    icon: HugeIcon(
                      icon: HugeIcons.strokeRoundedArrowLeft01,
                      color: lightColor.withValues(alpha: 0.7),
                    ),
                  )
                  .animate()
                  .fadeIn(duration: 300.ms)
                  .scale(begin: const Offset(0.8, 0.8), duration: 300.ms),

            if (!isFirstPage) const Gap(12),

            // Main CTA button (expanded to fill remaining space)
            AnimatedSwitcher(
              duration: duration,
              transitionBuilder: (child, animation) {
                return SizeTransition(
                  sizeFactor: animation,
                  axis: Axis.horizontal,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.2),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                );
              },
              child: isLastPage
                  ? _GetStartedButton(
                      key: const ValueKey('get_started'),
                      onPressed: () => _completeOnboarding(context),
                    )
                  : _NextButton(
                      key: const ValueKey('next'),
                      onPressed: controller.nextPage,
                    ),
            ),
          ],
        ),
      );
    });
  }

  void _completeOnboarding(BuildContext context) async {
    await controller.completeOnboarding();
    if (context.mounted) {
      context.goNamed(removeLeadingSlash(HomePage.routeName));
    }
  }
}

/// Next button (icon only) for first two pages
class _NextButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _NextButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return IconButton.filled(
          tooltip: "Next",
          onPressed: onPressed,
          style: IconButton.styleFrom(
            shape: RoundedRectangleBorder(borderRadius: borderRadius * 2.5),
            padding: EdgeInsets.all(16.0),
          ),
          icon: const HugeIcon(
            icon: HugeIcons.strokeRoundedArrowRight01,
            color: lightColor,
          ),
        )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .shimmer(duration: 1500.ms, delay: 500.ms);
  }
}

/// Get Started button for the last page
class _GetStartedButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _GetStartedButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return PrimaryButton.icon(
          onPressed: onPressed,
          icon: const HugeIcon(
            icon: HugeIcons.strokeRoundedArrowRight02,
            color: lightColor,
          ),
          label: const Text('Get Started'),
          iconAlignment: IconAlignment.end,
        )
        .animate()
        .fadeIn(duration: 400.ms)
        .scale(begin: const Offset(0.95, 0.95), duration: 300.ms);
  }
}
