import 'dart:math';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:hugeicons/styles/stroke_rounded.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:trashtrails/services/storage_service.dart';
import 'package:trashtrails/ui/components/default_snack_bar.dart';
import 'package:trashtrails/ui/pages/home.dart';
import 'package:trashtrails/utils/utils.dart';

import '../../../controllers/auth_controller.dart';
import '../../../utils/constants.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  static const String routeName = '/auth';

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final AuthController authController = Get.find<AuthController>();
  final StorageService storageService = Get.find<StorageService>();

  @override
  void initState() {
    super.initState();
    // Check if session expired and show message
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkSessionExpired();
    });
  }

  void _checkSessionExpired() {
    if (storageService.isSessionExpired) {
      // Clear the flag
      storageService.clearSessionExpired();

      // Show the session expired message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          buildSnackBar(
            prefixIcon: HugeIcon(
              icon: warningIcon,
              color: lightColor,
              size: 24.0,
            ),
            label: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Session Expired',
                  style: AppTextStyles.body.copyWith(
                    color: lightColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Your session has expired. Please sign in again.',
                  style: AppTextStyles.small.copyWith(color: lightColor),
                ),
              ],
            ),
            backgroundColor: warningColor,
            foregroundColor: lightColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        body: Stack(
          children: [
            // Background image
            const _BackgroundImage(),

            // Gradient overlay
            const _GradientOverlay(),

            // Bottom content card with fixed position
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _BottomContent(controller: authController),
            ),
          ],
        ),
      ),
    );
  }
}

/// Background image with animated fade in
class _BackgroundImage extends StatelessWidget {
  const _BackgroundImage();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Image.asset(
        authBg,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      ).animate().fadeIn(duration: 800.ms),
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

/// Bottom content including card and skip button
class _BottomContent extends StatelessWidget {
  final AuthController controller;

  const _BottomContent({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Content Card
            _ContentCard(controller: controller),
            const Gap(20.0),

            // Skip for now button
            _SkipButton(controller: controller),
            Gap(MediaQuery.of(context).padding.bottom + 32),
          ],
        )
        .animate()
        .fadeIn(duration: 600.ms, delay: 200.ms)
        .slideY(begin: 0.2, end: 0, duration: 500.ms, curve: Curves.easeOut);
  }
}

/// Helper function to show info snackbar
void _showInfoSnackBar(BuildContext context, String title, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    buildSnackBar(
      prefixIcon: HugeIcon(icon: infoIcon, color: lightColor, size: 24.0),
      label: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: AppTextStyles.body.copyWith(
              color: lightColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(message, style: AppTextStyles.small.copyWith(color: lightColor)),
        ],
      ),
      backgroundColor: infoColor,
      foregroundColor: lightColor,
    ),
  );
}

/// Content card with logo, title, description, Google auth button, and privacy text
class _ContentCard extends StatelessWidget {
  final AuthController controller;

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

                // Title
                Text(
                      'Your City Needs You. Log In and Start the Cleanup',
                      style: AppTextStyles.h1.copyWith(color: seedColor),
                    )
                    .animate()
                    .fadeIn(delay: 100.ms, duration: 400.ms)
                    .slideY(begin: 0.2, duration: 400.ms),
                const Gap(8),

                // Description
                Text(
                      "Ready to ditch the litter and finally use your street smarts for good? TrashTrails is where your biggest complaint becomes your greatest contribution. Sign up fast, because that illegal dump site on Elm Street isn't going to report itself!",
                      style: AppTextStyles.small.copyWith(color: seedColor),
                    )
                    .animate()
                    .fadeIn(delay: 200.ms, duration: 400.ms)
                    .slideY(begin: 0.2, duration: 400.ms),
                const Gap(24.0),

                // Google Auth Button
                _GoogleAuthButton(controller: controller),
                const Gap(16.0),

                // Privacy text
                Builder(
                  builder: (context) {
                    return Text.rich(
                      TextSpan(
                        text: 'By continuing, you agree to our ',
                        children: [
                          TextSpan(
                            text: "Terms of Service",
                            style: AppTextStyles.small.copyWith(
                              color: seedPalette.shade400,
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.underline,
                              fontVariations: [FontVariation('wght', 500)],
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () => _showInfoSnackBar(
                                context,
                                'Terms of Service',
                                'Terms of Service page coming soon!',
                              ),
                          ),
                          const TextSpan(text: " and "),
                          TextSpan(
                            text: "Privacy Policy",
                            style: AppTextStyles.small.copyWith(
                              color: seedPalette.shade400,
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.underline,
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () => _showInfoSnackBar(
                                context,
                                'Privacy Policy',
                                'Privacy Policy page coming soon!',
                              ),
                          ),
                          const TextSpan(text: "."),
                        ],
                      ),
                      style: AppTextStyles.small.copyWith(
                        color: greyColor.withValues(alpha: 0.8),
                        fontStyle: FontStyle.italic,
                      ),
                    ).animate().fadeIn(delay: 400.ms, duration: 400.ms);
                  },
                ),
              ],
            ),
          ),
        ),

        // Foreground avatar image positioned at top right, slightly outside card
        Positioned(top: -40, right: 30, child: _AvatarForegroundImage()),
      ],
    );
  }
}

/// Animated avatar foreground image
class _AvatarForegroundImage extends StatelessWidget {
  const _AvatarForegroundImage();

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: 10.0 * pi / 180,
      child:
          Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFF4CE9B),
                  border: Border.all(color: lightColor, width: 4.0),
                ),
                child: ClipOval(
                  child: Image.asset(
                    avatar4,
                    width: 64.0,
                    height: 64.0,
                    fit: BoxFit.cover,
                  ),
                ),
              )
              .animate()
              .fadeIn(delay: 300.ms, duration: 500.ms)
              .scale(
                begin: const Offset(0.5, 0.5),
                duration: 500.ms,
                curve: Curves.elasticOut,
              ),
    );
  }
}

/// Google authentication button
class _GoogleAuthButton extends StatelessWidget {
  final AuthController controller;

  const _GoogleAuthButton({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isLoading = controller.isLoading;

      return SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isLoading ? null : () => _handleGoogleSignIn(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: seedPalette.shade100,
                foregroundColor: seedColor,
                elevation: 2.0,
                shadowColor: Colors.black.withValues(alpha: 0.1),
                padding: const EdgeInsets.symmetric(
                  vertical: 16.0,
                  horizontal: 24.0,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: borderRadius * 2.5,
                  side: BorderSide(color: seedPalette.shade200),
                ),
              ),
              child: isLoading
                  ? SizedBox(
                      height: 24.0,
                      width: 24.0,
                      child: LoadingAnimationWidget.staggeredDotsWave(
                        color: seedPalette.shade300,
                        size: 32.0,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SvgPicture.asset(
                          googleIconColor,
                          width: 24.0,
                          height: 24.0,
                        ),
                        const Gap(12.0),
                        Text(
                          'Continue with Google',
                          style: AppTextStyles.body.copyWith(
                            fontWeight: FontWeight.w600,
                            fontVariations: [FontVariation('wght', 600)],
                          ),
                        ),
                      ],
                    ),
            ),
          )
          .animate()
          .fadeIn(delay: 300.ms, duration: 400.ms)
          .slideY(begin: 0.2, duration: 400.ms);
    });
  }

  Future<void> _handleGoogleSignIn(BuildContext context) async {
    final success = await controller.signInWithGoogle();

    if (!context.mounted) return;

    if (success) {
      // Show success snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        buildSnackBar(
          prefixIcon: HugeIcon(
            icon: successIcon,
            color: lightColor,
            size: 24.0,
          ),
          label: Text(
            'Welcome! You\'re now signed in.',
            style: AppTextStyles.body.copyWith(color: lightColor),
          ),
          backgroundColor: successColor,
          foregroundColor: lightColor,
        ),
      );
      context.goNamed(removeLeadingSlash(HomePage.routeName));
    } else if (controller.hasError) {
      // Show error snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        buildSnackBar(
          prefixIcon: HugeIcon(icon: errorIcon, color: lightColor, size: 24.0),
          label: Text(
            controller.error.isNotEmpty
                ? controller.error
                : 'Sign in failed. Please try again.',
            style: AppTextStyles.body.copyWith(color: lightColor),
          ),
          backgroundColor: errorColor,
          foregroundColor: lightColor,
        ),
      );
      controller.clearError();
    }
  }
}

/// Skip for now button
class _SkipButton extends StatelessWidget {
  final AuthController controller;

  const _SkipButton({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: SizedBox(
        width: double.infinity,
        child: TextButton(
          onPressed: () => _handleSkip(context),
          style: TextButton.styleFrom(
            foregroundColor: lightColor.withValues(alpha: 0.8),
            padding: const EdgeInsets.all(16.0),
            shape: RoundedRectangleBorder(borderRadius: borderRadius * 2.5),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Skip for now',
                style: AppTextStyles.body.copyWith(
                  color: lightColor.withValues(alpha: 0.8),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Gap(4.0),
              HugeIcon(
                icon: HugeIconsStrokeRounded.arrowUpRight01,
                color: lightColor.withValues(alpha: 0.8),
                size: 20.0,
              ),
            ],
          ),
        ).animate().fadeIn(delay: 500.ms, duration: 400.ms),
      ),
    );
  }

  Future<void> _handleSkip(BuildContext context) async {
    await controller.skipAuth();
    if (context.mounted) {
      context.goNamed(removeLeadingSlash(HomePage.routeName));
    }
  }
}
